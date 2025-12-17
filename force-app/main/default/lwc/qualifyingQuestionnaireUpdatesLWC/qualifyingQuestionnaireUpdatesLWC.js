import { LightningElement, api, track } from 'lwc';
import getResponsesForForm from '@salesforce/apex/QualifyingQuestionnaireController.getResponsesForForm';
import saveResponses from '@salesforce/apex/QualifyingQuestionnaireController.saveResponses';
import { FlowNavigationFinishEvent } from 'lightning/flowSupport';
import { NavigationMixin } from 'lightning/navigation';

export default class QualifyingQuestionnaireViewerLWC extends NavigationMixin(LightningElement) {
    // Works on Form record page automatically
    @api recordId;          // <-- page provides this
    @api formId;            // optional explicit input (Flow/App Builder)

    // Optional navigation/flow controls
    @api autoAdvance = false;
    @api navigateTo = 'form';
    @api projectId;
    @api opportunityId;

    // Output
    @api saved = false;

    // State
    @track rows = [];
    @track isLoading = true;
    @track hasError = false;
    @track submissionSuccess = false;

    connectedCallback() {
        // Default formId from page record if not supplied
        if (!this.formId && this.recordId) {
            this.formId = this.recordId;
        }
        console.log('[Viewer] connected. formId=', this.formId, 'recordId=', this.recordId);
        this.load();
    }

    load() {
        if (!this.formId) {
            console.warn('[Viewer] No formId available. Nothing to load.');
            this.isLoading = false;
            return;
        }

        this.isLoading = true;
        this.hasError = false;

        getResponsesForForm({ formId: this.formId })
            .then(result => {
                this.rows = (result || []).map(r => {
                    const type = (r.fieldType || '').trim().toLowerCase();
                    const isTextType =
                        type === 'text' || type === 'text area' || type === 'long text area';
                    const isNumberType =
                        type === 'number' || type === 'percent' || type === 'currency';
                    const isDateType = type === 'date';
                    const isPicklistType = type === 'picklist';

                    let picklistOptions = [];
                    if (isPicklistType && r.picklistValues) {
                        picklistOptions = r.picklistValues.split(';').map(val => ({
                            label: val.trim(),
                            value: val.trim()
                        }));
                        console.log(`[Viewer] QuestionId=${r.questionId}, Name=${r.questionName}, isRequired=${r.isRequired}, fieldType=${r.fieldType}, response=${r.responseText}`)
                    }

                    return {
                        ...r,
                        isTextType,
                        isNumberType,
                        isDateType,
                        isPicklistType,
                        picklistOptions,
                        isRequired: r.isRequired,
                        currentValue: r.responseText || ''
                    };
                });

                console.log('[Viewer] Loaded rows:', this.rows.length);
                this.isLoading = false;
            })
            .catch(err => {
                console.error('[Viewer] load error', err);
                this.hasError = true;
                this.isLoading = false;
            });
    }

    handleInputChange(event) {
        const qId = event.target.dataset.questionId;
        const val = event.target.value;
        const ix = this.rows.findIndex(r => r.questionId === qId);
        if (ix !== -1) {
            this.rows[ix].currentValue = val;
        }
    }

    handleSave() {
        if (!this.formId) return;

        console.log('[Viewer] Save clicked');
        this.submissionSuccess = false;
        this.saved = false;

        const payload = this.rows.map(r => ({
            qualifyingQuestionId: r.questionId,
            responseText: r.currentValue
        }));

        const responsesJson = JSON.stringify(payload);
        console.log('[Viewer] responsesJson length:', responsesJson.length);

        this.isLoading = true;

        saveResponses({ formId: this.formId, responsesJson })
            .then(ok => {
                console.log('[Viewer] Save complete:', ok);
                this.submissionSuccess = true;
                this.saved = true;
                this.isLoading = false;

                // Optional navigate (usually you’ll stay on the same form page)
                this.navigateAfterSave(this.formId);

                // Optional: finish Flow if embedded
                if (this.autoAdvance) {
                    try {
                        this.dispatchEvent(new FlowNavigationFinishEvent());
                    } catch (e) {
                        console.warn('[Viewer] Flow finish failed (likely not in Flow):', e);
                    }
                }
            })
            .catch(err => {
                console.error('[Viewer] save error', err);
                this.hasError = true;
                this.isLoading = false;
            });
    }

    navigateAfterSave(formId) {
        const mode = (this.navigateTo || 'form').toLowerCase();
        let recordIdToOpen = formId;

        if (mode === 'project' && this.projectId) recordIdToOpen = this.projectId;
        else if (mode === 'opportunity' && this.opportunityId) recordIdToOpen = this.opportunityId;

        if (!recordIdToOpen) return;

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: { recordId: recordIdToOpen, actionName: 'view' }
        });
    }
}