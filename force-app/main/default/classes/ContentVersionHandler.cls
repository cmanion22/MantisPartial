public class ContentVersionHandler {
    public static void createCollaboratorAccess(List<ContentVersion> contentVersions) {
        System.debug('Entering ContentVersionTrigger');
        if (contentVersions == null || contentVersions.isEmpty()) {
            System.debug('ContentVersionHandler.createCollaboratorAccess(): No ContentVersion records passed.');
            return;
        }

        // Get the Default Workflow User from Custom Metadata once
        List<Process_Automation__mdt> settings = [
            SELECT Username__c 
            FROM Process_Automation__mdt 
            WHERE DeveloperName = 'DefaultWorkflowUser' 
            LIMIT 1
        ];
        if (settings.isEmpty()) {
            System.debug('ContentVersionHandler.createCollaboratorAccess(): No DefaultWorkflowUser config found.');
            return;
        }

        List<User> users = [
            SELECT Id, Name 
            FROM User 
            WHERE Username = :settings[0].Username__c
            LIMIT 1
        ];
        if (users.isEmpty()) {
            System.debug('ContentVersionHandler.createCollaboratorAccess(): No User found with Username ' + settings[0].Username__c);
            return;
        }

        Id workflowUserId = users[0].Id;

        // Prepare ContentDocumentLinks to insert
        List<ContentDocumentLink> linksToInsert = new List<ContentDocumentLink>();

        for (ContentVersion cv : contentVersions) {
            if (cv == null || cv.ContentDocumentId == null) {
                System.debug('ContentVersionHandler.createCollaboratorAccess(): Skipping invalid ContentVersion record.');
                continue;
            }

            ContentDocumentLink cdl = new ContentDocumentLink(
                ContentDocumentId = cv.ContentDocumentId,
                LinkedEntityId = workflowUserId,
                ShareType = 'C',
                Visibility = 'AllUsers'
            );
            linksToInsert.add(cdl);
        }

        if (!linksToInsert.isEmpty()) {
            try {
                insert linksToInsert;
            } catch (DmlException e) {
                System.debug('Error inserting ContentDocumentLinks: ' + e.getMessage());
                for (ContentDocumentLink cdl : linksToInsert) {
                    DataLogService.logInfo('ContentVersionHandler.createCollaboratorAccess', e.getMessage(), cdl.ContentDocumentId);
                }
            }
        }
    }
}