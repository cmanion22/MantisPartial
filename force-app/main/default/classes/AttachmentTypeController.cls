public with sharing class AttachmentTypeController {
    @AuraEnabled
    public static void updateAttachmentTypesFromProject(List<Id> contentDocumentIds, Id projectId, String attachmentType, Date expirationDate) {
        if (contentDocumentIds == null || contentDocumentIds.isEmpty()) {
            throw new AuraHandledException('No ContentDocumentIds provided.');
        }

        if (projectId == null || attachmentType == null) {
            throw new AuraHandledException('Project or AttachmentType not provided.');
        }
        // Query the Project to get the associated Opportunity
        Project__c project = [SELECT Id, Name FROM Project__c WHERE Id = :projectId LIMIT 1];

        if (project.Name == null) {
            throw new AuraHandledException('Project not found.');
        }

        Id contentVersionRecordTypeId = getContentVersionRecordTypeId(project.Id, null);

            // If no RecordTypeId is found, throw an error
            if (contentVersionRecordTypeId == null) {
                throw new AuraHandledException('No RecordType found for the ContentVersion.');
            }

        // Query ContentVersion records for the provided ContentDocumentIds
        List<ContentVersion> contentVersions = [
            SELECT Id, Attachment_Type__c, Expiration_Date__c
            FROM ContentVersion
            WHERE ContentDocumentId IN :contentDocumentIds
        ];

        if (contentVersions.isEmpty()) {
            throw new AuraHandledException('No ContentVersion records found for the provided ContentDocumentIds.');
        }

        // Update Attachment_Type__c field and Expiration_Date__c
        for (ContentVersion version : contentVersions) {
            version.Attachment_Type__c = attachmentType;
            version.Project_Name__c = project.Name;
            version.RecordTypeId = contentVersionRecordTypeId;
            version.ProjectId__c = project.Id;
            System.debug('Apex Attachment Type: ' + version.Attachment_Type__c);

            if (expirationDate != null) {
                // Add a day to the expiration date to adjust for timezone difference
                Date adjustedExpirationDate = expirationDate.addDays(1);
                version.Expiration_Date__c = adjustedExpirationDate; 
                System.debug('Apex Expiration Date (Adjusted): ' + version.Expiration_Date__c);
            } else {
                version.Expiration_Date__c = null;
            }
        }
        update contentVersions;
    }

    @AuraEnabled
    public static void updateAttachmentTypesFromOpportunity(List<Id> contentDocumentIds, String attachmentType, Date expirationDate, Id contentVersionRTId) {
        if (contentDocumentIds == null || contentDocumentIds.isEmpty()) {
            throw new AuraHandledException('No ContentDocumentIds provided.');
        }

        if (attachmentType == null) {
            throw new AuraHandledException('AttachmentType not provided.');
        }

        if (contentVersionRTId == null) {
            throw new AuraHandledException('contentVersion RT Id not provided.');
        }

        // Query ContentVersion records for the provided ContentDocumentIds
        List<ContentVersion> contentVersions = [
            SELECT Id, Attachment_Type__c, Expiration_Date__c
            FROM ContentVersion
            WHERE ContentDocumentId IN :contentDocumentIds
        ];

        if (contentVersions.isEmpty()) {
            throw new AuraHandledException('No ContentVersion records found for the provided ContentDocumentIds.');
        }

        // Update Attachment_Type__c field and Expiration_Date__c
        for (ContentVersion version : contentVersions) {
            version.Attachment_Type__c = attachmentType;
            version.RecordTypeId = contentVersionRTId;
            System.debug('Apex Attachment Type: ' + version.Attachment_Type__c);

            if (expirationDate != null) {
                // Add a day to the expiration date to adjust for timezone difference
                Date adjustedExpirationDate = expirationDate.addDays(1);
                version.Expiration_Date__c = adjustedExpirationDate; 
                System.debug('Apex Expiration Date (Adjusted): ' + version.Expiration_Date__c);
            } else {
                version.Expiration_Date__c = null;
            }
        }
        update contentVersions;
    }


    @AuraEnabled
    public static void relateFileToOpportunity(Id projectId, List<Id> contentDocumentIds) {
        if (projectId == null || contentDocumentIds == null || contentDocumentIds.isEmpty()) {
            throw new AuraHandledException('Project or ContentDocumentIds not provided.');
        }
    
        // Query the Project to get the associated Opportunity
        Project__c project = [SELECT Id, Opportunity__c FROM Project__c WHERE Id = :projectId LIMIT 1];
        Id opportunityId = project.Opportunity__c;
        
        if (opportunityId == null) {
            throw new AuraHandledException('No Opportunity found for this Project.');
        }
    
        // Query for existing ContentDocumentLinks to avoid duplicates
        Set<Id> existingLinks = new Set<Id>();
        List<ContentDocumentLink> existingCdlRecords = [
            SELECT ContentDocumentId, LinkedEntityId 
            FROM ContentDocumentLink 
            WHERE LinkedEntityId = :opportunityId AND ContentDocumentId IN :contentDocumentIds
        ];
    
        // Log the existing links to debug
        System.debug('Existing CDL records: ' + existingCdlRecords);
    
        for (ContentDocumentLink cdl : existingCdlRecords) {
            existingLinks.add(cdl.ContentDocumentId);
        }
    
        // Create ContentDocumentLink records for the files, skipping those that already exist
        List<ContentDocumentLink> linksToInsert = new List<ContentDocumentLink>();
        for (Id contentDocumentId : contentDocumentIds) {
            if (!existingLinks.contains(contentDocumentId)) {
                ContentDocumentLink cdl = new ContentDocumentLink();
                cdl.ContentDocumentId = contentDocumentId;
                cdl.LinkedEntityId = opportunityId;
                cdl.ShareType = 'V'; // Viewer permissions
                cdl.Visibility = 'AllUsers';  // Adjust visibility as needed
    
                linksToInsert.add(cdl);
            } else {
                System.debug('ContentDocumentLink already exists for ContentDocumentId: ' + contentDocumentId);
            }
        }
    
        // Insert only the new ContentDocumentLinks
        if (!linksToInsert.isEmpty()) {
            try {
                insert linksToInsert;  // Insert only the new ContentDocumentLinks in a single DML operation
            } catch (Exception e) {
                // Log the full exception details for debugging
                System.debug('Error during insert: ' + e.getMessage());
                throw new AuraHandledException('Error inserting ContentDocumentLinks: ' + e.getMessage());
            }
        } else {
            System.debug('No new ContentDocumentLinks to insert.');
        }
    }    
    

    @AuraEnabled(cacheable=true)
    public static Id getContentVersionRecordTypeId(Id projectId, Id opportunityId) {
        try {
            // First, check if projectId is provided
            if (projectId != null) {
                // Query the Project record to get the related OpportunityId
                Project__c project = [SELECT Opportunity__c FROM Project__c WHERE Id = :projectId LIMIT 1];
                opportunityId = project.Opportunity__c; // Get the related OpportunityId from Project

                if (opportunityId == null) {
                    throw new AuraHandledException('No related Opportunity found for Project ID: ' + projectId);
                }
            }

            // If opportunityId is still null at this point, throw an error
            if (opportunityId == null) {
                throw new AuraHandledException('No OpportunityId provided or found for Project ID: ' + projectId);
            }

            // Query the Opportunity record to get its RecordTypeId
            Opportunity opp = [SELECT Id, RecordTypeId FROM Opportunity WHERE Id = :opportunityId LIMIT 1];
            System.debug('AttachmentTypeController - Opp RecordTypeId: ' + opp.RecordTypeId + ' -- ' + opp.Id);

            // Get the Opportunity RecordType DeveloperName
            String opportunityRecordType = [SELECT Id, DeveloperName FROM RecordType WHERE Id = :opp.RecordTypeId LIMIT 1].DeveloperName;
            System.debug('AttachmentTypeController - Opp RecordType: ' + opportunityRecordType); 

            // Query the ContentVersion RecordType based on the Opportunity RecordType DeveloperName
            RecordType contentVersionRecordType = [
                SELECT Id, DeveloperName 
                FROM RecordType 
                WHERE SObjectType = 'ContentVersion' 
                AND DeveloperName = :opportunityRecordType 
                LIMIT 1
            ];
            System.debug('AttachmentTypeController - ContentVersion RecordTypeId: ' + contentVersionRecordType.Id + ' -- ' + contentVersionRecordType.DeveloperName);

            // Return the ContentVersion RecordTypeId
            return contentVersionRecordType.Id;

        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving ContentVersion RecordTypeId: ' + e.getMessage());
        }
    }

}