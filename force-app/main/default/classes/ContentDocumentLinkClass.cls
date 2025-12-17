public with sharing class ContentDocumentLinkClass {
    // Static set to store processed ContentDocumentIds
    private static Set<Id> processedContentDocumentIds = new Set<Id>();

    public static void beforeDeleteCDL(List<ContentDocumentLink> cdls) {
        if (cdls.isEmpty()) {
            return; // Exit early if no ContentDocumentLinks are provided
        }

        try {
            Map<Id, List<ContentDocumentLink>> otherCDLsById = getOtherCDLs(cdls);

            List<Id> contentDocumentIdsToDelete = new List<Id>();

            // Get the ID of the current user performing the delete operation
            Id currentUserId = UserInfo.getUserId();

            User mantisBackOffice = [SELECT Id 
                                        FROM User 
                                        WHERE Name = 'Mantis Back Office' 
                                        LIMIT 1];

            for (ContentDocumentLink cdl : cdls) {
                if (cdl == null) {
                    continue; // Skip to the next iteration if the current ContentDocumentLink is null
                }

                // Check if mantisBackOffice is not null before accessing its Id field and if the record was deleted by the Mantis Back Office User
                if (mantisBackOffice != null && currentUserId == mantisBackOffice.Id) {
                    // Check if the ContentDocumentId has already been processed to avoid recursion
                    if (processedContentDocumentIds.contains(cdl.ContentDocumentId)) {
                        continue;
                    }
                    
                    // Add the ContentDocumentId to the set of processed records
                    processedContentDocumentIds.add(cdl.ContentDocumentId);

                    // Query for other ContentDocumentLinks related to the same ContentDocument
                    Id cdId = cdl.ContentDocumentId;
                    List<ContentDocumentLink> otherCDLs = otherCDLsById.get(cdl.Id);

                    Boolean deleteCD = true; // Assume we can delete the ContentDocument

                    // Check if there are any other ContentDocumentLinks
                    if (!otherCDLs.isEmpty()) {
                        // Check if there are any other ContentDocumentLinks not related to a user
                        for (ContentDocumentLink otherCDL : otherCDLs) {
                            String linkedEntityId = otherCDL.LinkedEntityId;
                            if (!linkedEntityId.startsWith('005')) {
                                deleteCD = false; // If we find a ContentDocumentLink not related to a user, we cannot delete the ContentDocument
                                break; // No need to continue checking, we found a non-user ContentDocumentLink
                            }
                        }
                    }

                    // If deleteCD is still true, add the ContentDocumentId to the list for deletion
                    if (deleteCD) {
                        contentDocumentIdsToDelete.add(cdId);
                    }
                }
            }

            // Perform bulkified delete outside of the loop
            if (!contentDocumentIdsToDelete.isEmpty()) {
                Database.delete(contentDocumentIdsToDelete, true);
            }
        } catch (Exception e) {
            // Add appropriate error handling/logging here
            System.debug('An error occurred: ' + e.getMessage());
        }
    }

    private static Map<Id, List<ContentDocumentLink>> getOtherCDLs(List<ContentDocumentLink> cdls) {
        Map<Id, List<ContentDocumentLink>> otherCDLsById = new Map<Id, List<ContentDocumentLink>>();

        String query = 'SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE ';

        for (ContentDocumentLink cdl : cdls) {
            if (cdl != null && cdl.Id != null && cdl.ContentDocumentId != null) {
                query += '(Id != \'' + cdl.Id + '\' AND ContentDocumentId = \'' + cdl.ContentDocumentId + '\') OR ';
            }
        }

        query = query.removeEnd(' OR ');

        if (!String.isEmpty(query)) {
            List<ContentDocumentLink> otherCDLs = Database.query(query);

            for (ContentDocumentLink cdl : cdls) {
                if (!otherCDLsById.containsKey(cdl.Id)) {
                    otherCDLsById.put(cdl.Id, new List<ContentDocumentLink>());
                }

                for (ContentDocumentLink otherCDL : otherCDLs) {
                    if (otherCDL.ContentDocumentId == cdl.ContentDocumentId) {
                        otherCDLsById.get(cdl.Id).add(otherCDL);
                    }
                }
            }
        }

        return otherCDLsById;
    }
    
    public static void updateContentVersionAttachmentType(List <ContentDocumentLink> insertedCDLS) {
        
        // Collect ContentDocumentIds from ContentDocumentLinks being inserted
        Set<Id> contentDocumentIds = new Set<Id>();
        for (ContentDocumentLink cdl : insertedCDLS) {
            contentDocumentIds.add(cdl.ContentDocumentId);
        }
  		
        // Query related ContentVersion records
        List <ContentVersion> contentVersions = [SELECT Id, ContentDocumentId
                                                    FROM ContentVersion
                                                    WHERE ContentDocumentId IN :contentDocumentIds];
       
         // Mapping Content DocumentIds to Content Version Ids
        Map <Id,Id> contentDocToVersionMap = new Map <Id, Id>(); 
        for (ContentVersion cv : contentVersions) {
            contentDocToVersionMap.put(cv.ContentDocumentId, cv.Id);
        }
        
        // Querying DocuSign Envelopes
        Map <Id, String> contentVersionToAttType = new Map <Id, String>();
        for (ContentDocumentLink cdl : insertedCDLS) {
            // Querying Envelope based on LinkedEntityId (Opportunity)
            List <dfsle__Envelope__c> envelopes = [SELECT Id, Attachment_Type__c,dfsle__DocuSignId__c
                                                    FROM dfsle__Envelope__c
                                                    WHERE dfsle__SourceId__c = :cdl.linkedEntityId];
            System.debug('Envelopes List: ' + envelopes);
            
           
            // Map Attachment Type for each Content Version
            for (dfsle__Envelope__c envelope : envelopes) {
                contentVersionToAttType.put(contentDocToVersionMap.get(cdl.ContentDocumentId), envelope.Attachment_Type__c);
                System.debug(contentDocToVersionMap.get(cdl.ContentDocumentId));
            }
        }
        
        //Updating Content Version Attachment Type
        List <ContentVersion> versionsToUpdate = new List <ContentVersion>();
        for (Id versionId : contentVersionToAttType.keySet()) {
            ContentVersion cv = new ContentVersion();
            cv.Id = versionId;
            cv.Attachment_Type__c = contentVersionToAttType.get(versionId);
            versionsToUpdate.add(cv);
        }

        // Attempting to update the ContentVersion Attachment Types
        try {
            if (!versionsToUpdate.isEmpty()) {
           
                update versionsToUpdate;
            }
        } catch (Exception e) {
            // Getting the exception message
            System.debug('Error updating ContentVersion records: ' + e.getMessage());
            
        }
        
            
    }
}