@isTest
private class ContentVersionHandlerTest {
    
    @testSetup
    static void setupData() {
        // Create a test user that matches the custom metadata Username__c
        // Make sure the username here matches the one in the DefaultWorkflowUser__mdt record
        User testUser = new User(
            Username = 'workflowuser@example.com', // must match Username__c in metadata
            Alias = 'wfuser',
            Email = 'workflowuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'WorkflowUser',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            TimeZoneSidKey = 'America/New_York'
        );
        insert testUser;
    }

    @isTest
    static void testCreateCollaboratorAccess() {
        // Create and insert a ContentVersion (simulates a file upload)
        ContentVersion cv = new ContentVersion(
            Title = 'TestFile',
            PathOnClient = 'TestFile.txt',
            VersionData = Blob.valueOf('Sample file content')
        );
        insert cv;

        // Reload to get ContentDocumentId
        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];

        Test.startTest();
        ContentVersionHandler.createCollaboratorAccess(new List<ContentVersion>{ cv });
        Test.stopTest();

        // Verify the ContentDocumentLink was created for the workflow user
        List<ContentDocumentLink> links = [
            SELECT Id, ContentDocumentId, LinkedEntityId, ShareType 
            FROM ContentDocumentLink 
            WHERE ContentDocumentId = :cv.ContentDocumentId
        ];
        System.assertEquals('C', links[0].ShareType);
        System.assertNotEquals(null, links[0].LinkedEntityId, 'LinkedEntityId should not be null');
    }
}