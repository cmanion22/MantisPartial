import { LightningElement, api, wire, track } from 'lwc';
import TITLE_FIELD from '@salesforce/schema/ContentVersion.Title';
import CREATEDDATE_FIELD from '@salesforce/schema/ContentVersion.CreatedDate';
import ATTACHMENT_TYPE_FIELD from '@salesforce/schema/ContentVersion.Attachment_Type__c';
import EXPIRATION_DATE_FIELD from '@salesforce/schema/ContentVersion.Expiration_Date__c';
import PROJECT_NAME_FIELD from '@salesforce/schema/ContentVersion.Project_Name__c';
import PROJECT_ID_FIELD from '@salesforce/schema/ContentVersion.ProjectId__c'; 
import { NavigationMixin } from 'lightning/navigation';
import getUploadedFiles from '@salesforce/apex/UploadOpportunityFileController.getUploadedFiles';
import deleteFiles from '@salesforce/apex/UploadOpportunityFileController.deleteFiles';
import getOpportunityRecordType from '@salesforce/apex/UploadOpportunityFileController.getOpportunityRecordType';
import opportunityFiles from "@salesforce/messageChannel/opportunityFiles__c";
import {
    publish,
    subscribe,
    unsubscribe,
    APPLICATION_SCOPE,
    MessageContext,
  } from "lightning/messageService";

  const servCOLUMNS = [
    {
        label: 'Title', 
        fieldName: TITLE_FIELD.fieldApiName, 
        type: "button", 
        sortable: true, 
        typeAttributes: {
            label: { fieldName: TITLE_FIELD.fieldApiName },
            name: TITLE_FIELD.fieldApiName,
            disabled: false,
            variant: 'base',
            value: TITLE_FIELD.fieldApiName,
        }
    },
    { 
        label: 'Attachment Type', 
        fieldName: ATTACHMENT_TYPE_FIELD.fieldApiName 
    },
    { 
        label: 'Created Date', 
        fieldName: CREATEDDATE_FIELD.fieldApiName, 
        type: 'date' 
    },
    { 
        label: 'Expiration Date', 
        fieldName: EXPIRATION_DATE_FIELD.fieldApiName, 
        type: 'date' 
    },
    {
        label: 'Project Name',
        fieldName: 'projectUrl', // We'll use this to store the URL to the Project record
        type: 'url', // Render as a hyperlink
        typeAttributes: {
            label: { fieldName: PROJECT_NAME_FIELD.fieldApiName },
            target: '_self', 
        }
    },
];

const energyCOLUMNS = [
    {
        label: 'Title', 
        fieldName: TITLE_FIELD.fieldApiName, 
        type: "button", 
        sortable: true, 
        typeAttributes: {
            label: { fieldName: TITLE_FIELD.fieldApiName },
            name: TITLE_FIELD.fieldApiName,
            disabled: false,
            variant: 'base',
            value: TITLE_FIELD.fieldApiName,
        }
    },
    { 
        label: 'Attachment Type', 
        fieldName: ATTACHMENT_TYPE_FIELD.fieldApiName 
    },
    { 
        label: 'Created Date', 
        fieldName: CREATEDDATE_FIELD.fieldApiName, 
        type: 'date' 
    },
];


export default class RelatedListOpportunityFiles extends NavigationMixin(LightningElement) {
    @api recordId;
    @track columns;
    files;
    spin = true;
    subscription = null;
    disableDeleteFilesButton = true;
    selectedRows = [];
    @track recordType;// tracks the Opportunity Record Type

    @wire(MessageContext)
    messageContext;

    @wire(getOpportunityRecordType, { opportunityId: '$recordId' })
    wiredRecordTypeId({ error, data }) {
        if (data) {
            this.recordType = data;
            console.log('Record Type retrieved: ', this.recordType);

            if (this.recordType === 'Services') {
                this.columns = servCOLUMNS;
            } else {
                this.columns = energyCOLUMNS;
            }
        } else if (error) {
            console.error('Error fetching Record Type Id: ', error);
        }
    }


    subscribeToMessageChannel() {
        if (!this.subscription) {
            this.subscription = subscribe(
                this.messageContext,
                opportunityFiles,
                (message) => this.handleMessage(message),
                { scope: APPLICATION_SCOPE },
            );
        }
    }

    
    handleMessage(message) {
        console.log('relatedListOpportunityFiles received message: ', JSON.stringify(message));  // Log the full message object
        if (message && message.opportunityId) {
            console.log('Received message with opportunityId:', message.opportunityId);
            if (this.recordId === message.opportunityId) {
                this.spin = true;
                this.getFiles();
            }
        } else {
            console.log('Message is missing opportunityId:', message);  // Add this log to debug if the message doesn't have opportunityId
        }
    }
    

    getFiles() {
        getUploadedFiles({ opportunityId: this.recordId })
        .then(result => { 
            this.files = result.map(file => {
                return {
                    ...file,
                    projectUrl: file.ProjectId__c ? `/lightning/r/Project__c/${file.ProjectId__c}/view` : undefined, // Generate Project URL if ProjectId exists
                };
            });
            this.spin = false;
        })
        .catch(error => {
            console.error(error);
            this.spin = false;
        });
    }

    handleRowSelection() {
        this.disableDeleteFilesButton = this.refs.filesDatatable.getSelectedRows().length === 0;
    }

    handleClickDeleteFiles() {
        this.spin = true;
        deleteFiles({cvs: this.refs.filesDatatable.getSelectedRows()})
        .then(result => { 
            console.log(result);
            publish(this.messageContext, opportunityFiles, { opportunityId: this.recordId });
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
                    pageName: 'filePreview'
                },
                state : {
                    recordIds: event.detail.row.ContentDocumentId
                }
            });
        }
     }
}