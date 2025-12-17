import { LightningElement, api, track, wire } from 'lwc';
import { publish, MessageContext } from 'lightning/messageService';
import projectFiles from '@salesforce/messageChannel/projectFiles__c';

export default class UploadFile extends LightningElement {
    @api recordId;
    @track contentDocumentIds = []; // Array to store ContentDocumentIds
    showAttachmentTypeSelection = false;
    
    @wire(MessageContext)
    messageContext;

    handleUploadFinished(event) {
        const uploadedFiles = event.detail.files;
        if (uploadedFiles.length > 0) {
            // Populate the contentDocumentIds array with all the document IDs
            this.contentDocumentIds = uploadedFiles.map(file => file.documentId);
            console.log('contentDocumentIds:', this.contentDocumentIds);
    
            // Check if there are files to process
            if (this.contentDocumentIds.length > 0) {
                this.showAttachmentTypeSelection = true;
                console.log('showAttachmentTypeSelection:', this.showAttachmentTypeSelection);
    
                // Publish the message to notify that files were uploaded
                publish(this.messageContext, projectFiles, { projectId: this.recordId });
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