import { LightningElement, api, wire, track } from 'lwc';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import ATTACHMENT_TYPE_FIELD from '@salesforce/schema/ContentVersion.Attachment_Type__c';
import updateAttachmentType from '@salesforce/apex/AttachmentTypeController.updateAttachmentTypesFromOpportunity';
import getContentVersionRecordTypeId from '@salesforce/apex/AttachmentTypeController.getContentVersionRecordTypeId';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { publish, MessageContext } from 'lightning/messageService';
import opportunityFiles from '@salesforce/messageChannel/opportunityFiles__c';

export default class AttachmentTypeSelection extends LightningElement {
    @api recordId; 
    @api contentDocumentIds = [];
    @api opportunityid; 
    attachmentType = '';
    attachmentTypeOptions = [];
    @track recordTypeId; 

    // Wire the method to get the recordTypeId dynamically
        @wire(getContentVersionRecordTypeId, { projectId: null, opportunityId: '$opportunityid' })
        wiredRecordTypeId({ error, data }) {
            if (data) {
                this.recordTypeId = data;
                console.log('Record Type Id retrieved: ', this.recordTypeId);
            } else if (error) {
                console.error('Error fetching Record Type Id: ', error);
            }
        }

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
    }

    //Updated Handle submit code updated to call the Attachment Type apex controller
    handleSubmit(event) {
        event.preventDefault();
        console.log(event);
        console.log('attachmentTypeSelection: Entering Update Attachment Types');
        updateAttachmentType({ contentDocumentIds: this.contentDocumentIds, attachmentType: this.attachmentType, contentVersionRTId: this.recordTypeId })
            .then(() => {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Success',
                    message: 'Attachment Type updated successfully',
                    variant: 'success'
                }));

                // Publish the message to notify that the attachment type was updated
                publish(this.messageContext, opportunityFiles, { opportunityId: this.opportunityid });

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