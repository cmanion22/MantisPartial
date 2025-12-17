public with sharing class UploadProjectFileController {

    @AuraEnabled
    public static string uploadFile(String fileName, String fileRecordName, String fileContentBase64, String attachmentType, Id projectId, Date expirationDate) {
        ContentVersion cv = new ContentVersion();
        try {

            cv.Title = fileRecordName.abbreviate(255);
            cv.VersionData = EncodingUtil.base64Decode(fileContentBase64);
            cv.PathOnClient = fileName;
            cv.Attachment_Type__c = attachmentType;
            cv.FirstPublishLocationId = projectId; 
            cv.ContentLocation = 'S';
            cv.IsMajorVersion = true;
            cv.Expiration_Date__c = expirationDate;

            insert cv;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

        return cv.Id;
    }

    @AuraEnabled
    public static List<ContentVersion> getUploadedFiles(Id projectId) {
        List<ContentVersion> cvs = new List<ContentVersion>();
        try {
            List<ContentDocumentLink> cdls = [SELECT Id, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityID = :projectId]; // Changed to projectId
            if (!cdls.isEmpty()) {
                Set<Id> cdIds = new Set<Id>();
                for (ContentDocumentLink cdl : cdls) {
                    cdIds.add(cdl.ContentDocumentId);
                }
                cvs = [SELECT Id, ContentDocumentId, Title, CreatedDate, Attachment_Type__c, Expiration_Date__c 
                       FROM ContentVersion 
                       WHERE ContentDocumentId IN :cdIds AND IsLatest = true];
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

        return cvs;
    }

    @AuraEnabled
    public static String deleteFiles(List<ContentVersion> cvs) {
        if (cvs == null || cvs.isEmpty()) {
        throw new AuraHandledException('No Content Versions provided for deletion');
    }
        List<ContentDocument> cdsToDelete = new List<ContentDocument>();
        System.debug('CVS: ' + cvs);
        for (ContentVersion cv : cvs) {
            cdsToDelete.add(new ContentDocument(Id = cv.ContentDocumentId));
        }

        try {
            delete cdsToDelete;
            return 'success';
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

}