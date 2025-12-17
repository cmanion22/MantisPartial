import { LightningElement, wire, api } from 'lwc';
import uploadFile from '@salesforce/apex/UploadOpportunityFileController.uploadFile';
import { getPicklistValues } from "lightning/uiObjectInfoApi";
import ATTACHMENT_TYPE_FIELD from "@salesforce/schema/ContentVersion.Attachment_Type__c";

import opportunityFiles from "@salesforce/messageChannel/opportunityFiles__c";
import { publish, MessageContext } from "lightning/messageService";

export default class UploadOpportunityFile extends LightningElement {
    @api recordId;
    response;
    spin = false;
    fileSelect = true;
    file;
    fileName;
    fileRecordName;
    attachmentType;
    attachmentTypePicklistValues;

    @wire(MessageContext)
    messageContext;

    @wire(getPicklistValues, { recordTypeId: "012000000000000AAA", fieldApiName: ATTACHMENT_TYPE_FIELD })
    getAttachmentTypePicklistValues({data, error}) {
        if (error) {
            console.error(error);
        } else if (data) {
            this.attachmentTypePicklistValues = [...data.values];
        }
    }

    handleRemoveFileClick(event) {
        this.fileSelect = true;
    }

    handleFilesChange(event) {
        this.file = event.detail.files[0];
        this.fileName = this.file.name;
        const dotIndex = this.fileName.split("").reverse().join("").indexOf(".");
        this.fileRecordName = dotIndex !== -1 ? this.fileName.substring(0, this.fileName.length - dotIndex - 1) : this.fileName;
        this.fileSelect = false;
    }

    handleFileRecordNameChange(event) {
        this.fileRecordName = event.detail.value;
    }

    handleAttachmentTypeChange(event) {
        this.attachmentType = event.detail.value;
    }

    @api get disableUploadButton() {
        return this.fileSelect || !this.attachmentType || this.attachmentType.length === 0;
    }

    handleUploadFileClick(event) {
        this.spin = true;
        
        const fileReader = new FileReader();
        fileReader.onloadend = (() => {
            const apexParams = {
                fileName: this.fileName,
                fileRecordName: this.fileRecordName,
                attachmentType: this.attachmentType,
                opportunityId: this.recordId
            };
            let result = fileReader.result;
            const base64 = 'base64,';
            const i = result.indexOf(base64) + base64.length;
            apexParams.fileContentBase64 = result.substring(i);
            uploadFile(apexParams)
                .then(result => { 
                    this.file = null;
                    this.fileName = null;
                    this.fileSelect = true;
                    this.attachmentType = '';
                    this.spin = false;
                    publish(this.messageContext, opportunityFiles, { opportunityId: this.recordId });
                })
                .catch(error => {
                    console.error(error);
                    this.spin = false;
                });
        });

        fileReader.readAsDataURL(this.file);
    }
}