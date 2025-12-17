import { LightningElement, api, track } from 'lwc';
import getQuestionsBySolutionType from '@salesforce/apex/QualifyingQuestionnaireController.getQuestionsBySolutionType';
import getQuestionsBySolutionTypeWithSubtype from '@salesforce/apex/QualifyingQuestionnaireController.getQuestionsBySolutionTypeWithSubtype';
import createFormWithResponses from '@salesforce/apex/QualifyingQuestionnaireController.createFormWithResponses';
import { FlowNavigationFinishEvent } from 'lightning/flowSupport';
import { NavigationMixin } from 'lightning/navigation';

export default class QualifyingQuestionnaireLWC extends NavigationMixin(LightningElement) {
    // Inputs from Flow / App Builder
    @api projectId;
    @api solutionType;
    @api opportunityId;

    // NEW: pass your Flow variable here (e.g., varMechanicalType)
    @api mechanicalSubtype; // e.g., "Hydronic Systems", "Mechanical General", etc.

    // Flow navigation controls (boolean @api must default to false)
    @api autoAdvance = false;     // set true in Flow to finish after save
    @api navigateTo = 'form';     // 'form' | 'project' | 'opportunity'

    // OUTPUT back to Flow
    @api formId;                  // populated after a successful save

    // State
    @track questions = [];
    @track responses = {};        // { [questionId]: answer }
    @track isLoading = true;
    @track hasError = false;
    @track submissionSuccess = false;

    // ----- Lifecycle -----
    connectedCallback() {
        console.log('[LWC] connectedCallback');
        console.log('[LWC] Inputs -> projectId:', this.projectId, '| solutionType:', this.solutionType, '| opportunityId:', this.opportunityId);
        console.log('[LWC] Mechanical Subtype (if any):', this.mechanicalSubtype);
        console.log('[LWC] Nav prefs -> autoAdvance:', this.autoAdvance, '| navigateTo:', this.navigateTo);

        if (this.projectId && this.solutionType) {
            this.loadQuestions();
        } else {
            console.warn('[LWC] Missing required input(s): projectId or solutionType');
            this.hasError = true;
            this.isLoading = false;
        }
    }

    // ----- Data Load -----
    loadQuestions() {
        console.log('[LWC] Loading questions...');
        this.isLoading = true;

        const solLower = (this.solutionType || '').toLowerCase();
        const isMechanicalSolution =
            solLower === 'hvac/mechanical' ||
            solLower === 'mechanical' ||
            solLower.includes('mechanical');

        // When Mechanical/HVAC, call the subtype-aware Apex
        const fetchPromise = isMechanicalSolution
            ? getQuestionsBySolutionTypeWithSubtype({
                  solutionType: this.solutionType,
                  mechanicalSubtype: this.mechanicalSubtype
              })
            : getQuestionsBySolutionType({ solutionType: this.solutionType });

        fetchPromise
            .then(result => {
                console.log('[LWC] Questions from Apex:', result);

                this.questions = result.map(q => {
                    const type = (q.Field_Type__c || '').trim().toLowerCase();

                    const isTextType =
                        type === 'text' || type === 'text area' || type === 'long text area';
                    const isNumberType =
                        type === 'number' || type === 'percent' || type === 'currency';
                    const isDateType = type === 'date';
                    const isPicklistType = type === 'picklist';

                    let picklistOptions = [];
                    if (isPicklistType && q.Picklist_Values__c) {
                        picklistOptions = q.Picklist_Values__c.split(';').map(val => ({
                            label: val.trim(),
                            value: val.trim()
                        }));
                    }

                    // Log per-question typing for visibility
                    console.log(
                        `[LWC] Question: ${q.Question_Name__c} | Type: ${q.Field_Type__c} | Sub_Type__c: ${q.Sub_Type__c}`
                    );
                    console.log(
                        `[LWC] -> isTextType: ${isTextType}, isNumberType: ${isNumberType}, isDateType: ${isDateType}, isPicklistType: ${isPicklistType}`
                    );

                    return {
                        ...q,
                        isTextType,
                        isNumberType,
                        isDateType,
                        isPicklistType,
                        picklistOptions,
                        isRequired: q.Required_or_Optional__c === 'Required',
                        ßcurrentValue: this.responses[q.Id] || ''
                    };
                });

                console.log('[LWC] Processed questions:', this.questions);
                this.isLoading = false;
            })
            .catch(error => {
                console.error('[LWC] Error loading questions:', error);
                this.hasError = true;
                this.isLoading = false;
            });
    }

    // ----- Input Handling -----
    handleInputChange(event) {
        const questionId = event.target.dataset.questionId;
        const value = event.target.value;

        console.log('[LWC] handleInputChange -> questionId:', questionId, '| value:', value);

        if (!questionId) {
            console.error('[LWC] Missing questionId in dataset');
            return;
        }

        // Store response
        this.responses = { ...this.responses, [questionId]: value };

        // Keep UI in sync
        const ix = this.questions.findIndex(q => q.Id === questionId);
        if (ix !== -1) this.questions[ix].currentValue = value;
    }

    // ----- Submit / Save -----
    handleSubmit() {
        console.log('[LWC] Submit clicked');
        this.submissionSuccess = false;

        // Build JSON payload (include ALL questions; unanswered => null)
        const responseList = [];
        this.questions.forEach(q => {
            const questionId = q.Id;
            const responseText = (this.responses.hasOwnProperty(questionId))
                ? this.responses[questionId]
                : null;

            responseList.push({ qualifyingQuestionId: questionId, responseText });
            console.log(`[LWC] Add response -> ${questionId} = ${responseText}`);
        });

        const responsesJson = JSON.stringify(responseList);
        console.log('[LWC] Payload to Apex (responsesJson):', responsesJson);

        this.isLoading = true;

        createFormWithResponses({
            projectId: this.projectId,
            opportunityId: this.opportunityId,
            solutionType: this.solutionType,
            responsesJson
        })
            .then((newFormId) => {
                console.log('[LWC] Save successful, formId:', newFormId);
                this.formId = newFormId;          // expose to Flow
                this.submissionSuccess = true;
                this.isLoading = false;

                // 1) Navigate to the chosen record
                this.navigateAfterSave(newFormId);

                // 2) Finish the Flow (close modal/page) if configured
                if (this.autoAdvance) {
                    try {
                        this.dispatchEvent(new FlowNavigationFinishEvent());
                    } catch (e) {
                        console.warn('[LWC] Flow finish event failed (not running inside Flow?):', e);
                    }
                }
            })
            .catch(error => {
                console.error('[LWC] Submission error:', error);
                this.hasError = true;
                this.isLoading = false;
            });
    }

    // ----- Navigation -----
    navigateAfterSave(formId) {
        let recordIdToOpen = formId;

        const mode = (this.navigateTo || 'form').toLowerCase();
        if (mode === 'project' && this.projectId) {
            recordIdToOpen = this.projectId;
        } else if (mode === 'opportunity' && this.opportunityId) {
            recordIdToOpen = this.opportunityId;
        } // else 'form' by default

        if (!recordIdToOpen) {
            console.warn('[LWC] No recordId to navigate to.');
            return;
        }

        console.log('[LWC] Navigating to record:', recordIdToOpen, '| mode:', mode);

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordIdToOpen,
                actionName: 'view'
            }
        });
    }
}