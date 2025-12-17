import { LightningElement, api, wire, track } from 'lwc';
import { publish, MessageContext } from 'lightning/messageService';
import opportunityFiles from '@salesforce/messageChannel/opportunityFiles__c';

export default class UploadFile extends LightningElement {
    @api recordId;
    showAttachmentTypeSelection = false;
    @track contentDocumentIds = []; // Array to store ContentDocumentIds

    @wire(MessageContext)
    messageContext;

    handleUploadFinished(event) {
        console.log('recordId in parent:', this.recordId);
        // This method is triggered when the file upload is finished
        const uploadedFiles = event.detail.files;
        if (uploadedFiles.length > 0) {
            // Store the ContentDocumentIds of all uploaded files
            this.contentDocumentIds = uploadedFiles.map(file => file.documentId);
            console.log('contentDocumentIds:', this.contentDocumentIds);

            // Check if there are files to process
            if (this.contentDocumentIds.length > 0) {
                this.showAttachmentTypeSelection = true;
                console.log('showAttachmentTypeSelection:', this.showAttachmentTypeSelection);
    
                 // Publish the message to notify that files are uploaded
            publish(this.messageContext, opportunityFiles, { opportunityId: this.recordId });
            } else {
                console.error('No ContentDocumentIds found.');
            }
        } else {
            console.error('No files uploaded.');
        }
    }
           

    handleClose() {
        // Close the modal
        this.showAttachmentTypeSelection = false;
        this.contentDocumentIds = []; // Clear the array when modal is closed
    }
}