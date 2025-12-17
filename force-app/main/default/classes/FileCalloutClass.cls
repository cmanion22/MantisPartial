public with sharing class FileCalloutClass {
 
    public static string uploadFile(Id contentDocumentLinkId, ID contentDocumentId, ID opportunityId) {
        System.debug('FileHelper-->uploadFile-->contentDocumentId-->' +  contentDocumentId + ' | opportunityId-->' + opportunityId);
        return FileHelper.postFileUploadedJson(contentDocumentLinkId, contentDocumentId, opportunityId);               
    }    

    public static string deleteFile(ID contentDocumentId, ID opportunityId) {
        System.debug('FileHelper-->deleteFile-->contentDocumentId-->' +  contentDocumentId + ' | opportunityId-->' + opportunityId);
        return FileHelper.postDeleteFileJson(contentDocumentId, opportunityId);          
    }      
}