import { LightningElement, api, wire, track } from 'lwc';
import TITLE_FIELD from '@salesforce/schema/ContentVersion.Title';
import CREATEDDATE_FIELD from '@salesforce/schema/ContentVersion.CreatedDate';
import ATTACHMENT_TYPE_FIELD from '@salesforce/schema/ContentVersion.Attachment_Type__c';
import EXPIRATION_DATE_FIELD from '@salesforce/schema/ContentVersion.Expiration_Date__c';
import { NavigationMixin } from 'lightning/navigation';
import getUploadedFiles from '@salesforce/apex/UploadProjectFileController.getUploadedFiles'; // Update Apex method
import deleteFiles from '@salesforce/apex/UploadProjectFileController.deleteFiles'; // Update Apex method
import projectFiles from '@salesforce/messageChannel/projectFiles__c'; // Update message channel
import {
    publish,
    subscribe,
    unsubscribe,
    APPLICATION_SCOPE,
    MessageContext,
} from 'lightning/messageService';

const COLUMNS = [
    {
        label: 'Title', fieldName: TITLE_FIELD.fieldApiName, type: 'button', sortable: true, typeAttributes: {
            label: { fieldName: TITLE_FIELD.fieldApiName },
            name: TITLE_FIELD.fieldApiName,
            disabled: false,
            variant: 'base',
            value: TITLE_FIELD.fieldApiName,
        }
    },
    { label: 'Attachment Type', fieldName: ATTACHMENT_TYPE_FIELD.fieldApiName },
    { label: 'Created Date', fieldName: CREATEDDATE_FIELD.fieldApiName, type: 'date' },
    { label: 'Expiration Date', fieldName: EXPIRATION_DATE_FIELD.fieldApiName, type: 'date' },
];

export default class RelatedListProjectFiles extends NavigationMixin(LightningElement) {
    @api recordId; // This will hold the Project__c record ID
    columns = COLUMNS;
    @track files;
    spin = true;
    subscription = null;
    disableDeleteFilesButton = true;
    selectedRows = [];

    @wire(MessageContext)
    messageContext;

    subscribeToMessageChannel() {
        if (!this.subscription) {
            this.subscription = subscribe(
                this.messageContext,
                projectFiles,
                (message) => this.handleMessage(message),
                { scope: APPLICATION_SCOPE },
            );
        }
    }

    handleMessage(message) {
        console.log("Received message:", message);  // Log received message
        
        if (this.recordId === message.projectId) {
            console.log("Before update:", this.files); // Log current files
    
            this.spin = true;
            this.getFiles();
    
            console.log("After update:", this.files); // Log updated files
        }
    }

    getFiles() {
        console.log('Getting Uploaded Files...');

        getUploadedFiles({ projectId: this.recordId })
            .then(result => {
                console.log('Files retrieved:', result);  
                this.files = result;
                this.spin = false;
            })
            .catch(error => {
                console.error('Error retrieving files:', error);  
                this.spin = false;
            });
    }
    

    handleRowSelection() {
        this.disableDeleteFilesButton = this.refs.filesDatatable.getSelectedRows().length === 0;
    }

    handleClickDeleteFiles() {
        this.spin = true;
        deleteFiles({ cvs: this.refs.filesDatatable.getSelectedRows() }) // Update method to delete files
            .then(result => {
                console.log(result);
                publish(this.messageContext, projectFiles, { projectId: this.recordId }); // Publish with projectId
                this.selectedRows = [];
                this.disableDeleteFilesButton = true;
                this.spin = false;
            })
            .catch(error => {
                console.error(error);
                this.spin = false;
            });
    }

    unsubscribeToMessageChannel() {
        unsubscribe(this.subscription);
        this.subscription = null;
    }

    connectedCallback() {
        this.subscribeToMessageChannel();
        this.getFiles();
    }

    disconnectedCallback() {
        this.unsubscribeToMessageChannel();
    }

    handleRowAction(event) {
        if (event.detail.action.name == TITLE_FIELD.fieldApiName) {
            this[NavigationMixin.Navigate]({
                type: 'standard__namedPage',
                attributes: {
                    pageName: 'filePreview',
                },
                state: {
                    recordIds: event.detail.row.ContentDocumentId,
                },
            });
        }
    }
}