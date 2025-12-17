import { LightningElement, api, wire, track } from 'lwc';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import ATTACHMENT_TYPE_FIELD from '@salesforce/schema/ContentVersion.Attachment_Type__c';
import updateAttachmentType from '@salesforce/apex/AttachmentTypeController.updateAttachmentTypesFromProject';
import relateFileToOpportunity from '@salesforce/apex/AttachmentTypeController.relateFileToOpportunity';
import getContentVersionRecordTypeId from '@salesforce/apex/AttachmentTypeController.getContentVersionRecordTypeId';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { publish, MessageContext } from 'lightning/messageService';
import projectFiles from '@salesforce/messageChannel/projectFiles__c';

export default class AttachmentTypeSelection extends LightningElement {
    @api recordId; 
    @api contentDocumentIds = [];
    @api projectid; 
    @track attachmentType = ''; 
    @track attachmentTypeOptions = []; 
    @track expirationDate = ''; 
    @track recordTypeId; 

    // Wire the method to get the recordTypeId dynamically
    @wire(getContentVersionRecordTypeId, { projectId: '$projectid', opportunityId: null })
    wiredRecordTypeId({ error, data }) {
        if (data) {
            this.recordTypeId = data;
            console.log('Record Type Id retrieved: ', this.recordTypeId);
        } else if (error) {
            console.error('Error fetching Record Type Id: ', error);
        }
    }

    // Wire getPicklistValues with dynamic recordTypeId
    @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: ATTACHMENT_TYPE_FIELD })
    wiredPicklistValues({ error, data }) {
        if (data) {
            console.log('Picklist values:', data.values);
            this.attachmentTypeOptions = data.values.map(picklistValue => ({
                label: picklistValue.label,
                value: picklistValue.value
            }));
        } else if (error) {
            console.error('Error fetching picklist values: ', error);
        }
    }

@wire(MessageContext)
messageContext;

    handleAttachmentTypeChange(event) {
        this.attachmentType = event.detail.value;
        console.log('Selected Attachment Type:', this.attachmentType);
    }

    handleExpirationDateChange(event) {
        // Grab the date from the input
        const selectedDate = event.target.value;
    
        // Log the raw date (should be in YYYY-MM-DD format)
        console.log('Selected Date (Raw):', selectedDate);
    
        // Assign the selected date directly to expirationDate
        this.expirationDate = selectedDate;
    
        // Log the date just before sending to Apex
        console.log('Expiration Date (Assigned):', this.expirationDate);
    }                
       
    //Updated Handle submit code updated to call the Attachment Type apex controller
    handleSubmit(event) {
        event.preventDefault();
        console.log('ContentDocumentIds:', this.contentDocumentIds); 
        console.log(event);
        
        // Validation: Check if expiration date is required
        if (this.attachmentType === 'Vendor Quote' && (!this.expirationDate || this.expirationDate.trim() === '')) {
        this.dispatchEvent(new ShowToastEvent({
        title: 'Validation Error',
        message: 'Expiration Date is required when Attachment Type is "Vendor Quote".',
        variant: 'error'
        }));
        return; // Stop submission if validation fails
            }

        updateAttachmentType({ contentDocumentIds: this.contentDocumentIds,  
                               attachmentType: this.attachmentType,
                               projectId: this.projectid, 
                               expirationDate: this.expirationDate || null
                            })
            .then(() => {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Success',
                    message: 'Attachment Type updated successfully',
                    variant: 'success'
                }));

                // Call relateFileToOpportunity Apex method next
                console.log('Calling relateFileToOpportunity with projectid:', this.projectid, ' and contentDocumentIds:', this.contentDocumentIds);
                relateFileToOpportunity({
                    projectId: this.projectid,
                    contentDocumentIds: this.contentDocumentIds  
                })
                .then(() => {
                    console.log('relateFileToOpportunity executed successfully');
                })
                .catch(error => {
                    console.error('Error in relateFileToOpportunity:', error);
                });


                // Publish the message to notify that the attachment type was updated
                console.log('Publishing from attachmentTypeSelectionProject');
                publish(this.messageContext, projectFiles, { projectId: this.projectid });

                this.closeModal();
            }) 
            .catch(error => {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error updating record',
                    message: error.body.message,
                    variant: 'error'
                }));
            });
    }

    closeModal() {
        const closeEvent = new CustomEvent('close');
        this.dispatchEvent(closeEvent);
    }
}