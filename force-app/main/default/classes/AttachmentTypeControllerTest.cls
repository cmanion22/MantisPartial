@isTest
public class AttachmentTypeControllerTest {

    // Helper method to create a test Account
    private static Account createTestAccount() {
        Account acc = new Account();
        acc.Name = 'Funny Account12';
        acc.Legal_Entity_Name__c = 'Sample Account';
        acc.Phone = '1111111289';
        insert acc;
        return acc;
    }

    // Helper method to create a test Opportunity
    private static Opportunity createTestOpportunity(Id accountId) {
        Opportunity opp = new Opportunity();
        opp.Name = 'Funny Account - 12121';
        opp.AccountId = accountId;
        opp.Type = 'New Business';
        opp.NextStep = 'step';
        opp.Description = 'description';
        opp.CloseDate = Date.today();
        opp.StageName = '1 - Discovery';
        opp.Green_Energy__c = '0%';
        opp.Primary_Client_KPI__c = 'Other';
        opp.LeadSource = 'BD';
        opp.Legacy_Opportunity_No_Splits__c = false;    
        opp.Expected_Contract_Start__c = Date.today();
        insert opp;
        return opp;
    }

    // Helper method to create a test Project related to Opportunity
    private static Project__c createTestProject(Id opportunityId) {
        Project__c project = new Project__c(Name = 'Test Project', Opportunity__c = opportunityId);
        insert project;
        return project;
    }

    // Helper method to create a test ContentVersion and fetch ContentDocumentId
    private static ContentVersion createTestContentVersion(Id projectId) {
        
        Id servicesCVRTId = [SELECT Id
                             FROM RecordType
                             WHERE developerName = 'Services'
                             AND SobjectType = 'ContentVersion'].Id;
        
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Test File';
        cv.VersionData = Blob.valueOf('Test content data');
        cv.PathOnClient = 'testfile.txt';
        cv.Attachment_Type__c = 'Project Setup Form';
        cv.FirstPublishLocationId = projectId;
        cv.ContentLocation = 'S';
        cv.IsMajorVersion = true;
        cv.recordTypeId = servicesCVRTId;
        insert cv;

        // Now query for the ContentDocumentId
        ContentVersion insertedCv = [SELECT ContentDocumentId, RecordTypeId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
        return insertedCv;
    }

    // Test for updateAttachmentTypes method
    @isTest
    public static void testUpdateAttachmentTypesFromProject() {
        // Create Account, Opportunity, and Project
        Account acc = createTestAccount();
        Opportunity opp = createTestOpportunity(acc.Id);
        Project__c project = createTestProject(opp.Id);

        // Create ContentVersion linked to the project and fetch ContentDocumentId
        ContentVersion cv = createTestContentVersion(project.Id);

        // Prepare parameters for updateAttachmentTypes method
        String attachmentType = 'Vendor Quote';
        Date expirationDate = Date.today().addDays(30);

        // Call the updateAttachmentTypes method
        Test.startTest();
        AttachmentTypeController.updateAttachmentTypesFromProject(new List<Id>{cv.ContentDocumentId}, project.Id, attachmentType, expirationDate);
        Test.stopTest();

        // Verify that the ContentVersion is updated correctly
        ContentVersion updatedCv = [SELECT Id, Attachment_Type__c, Expiration_Date__c FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
      
    }
    
    // Test for updateAttachmentTypes method
    @isTest
    public static void testUpdateAttachmentTypesFromOpportunity() {
        // Create Account, Opportunity, and Project
        Account acc = createTestAccount();
        Opportunity opp = createTestOpportunity(acc.Id);
        Project__c project = createTestProject(opp.Id);

        // Create ContentVersion linked to the project and fetch ContentDocumentId
        ContentVersion cv = createTestContentVersion(project.Id);
        
        Id cvRTId = cv.RecordTypeId;

        // Prepare parameters for updateAttachmentTypes method
        String attachmentType = 'Vendor Quote';
        Date expirationDate = Date.today().addDays(30);

        // Call the updateAttachmentTypes method
        Test.startTest();
        AttachmentTypeController.updateAttachmentTypesFromOpportunity(new List<Id>{cv.ContentDocumentId}, attachmentType, expirationDate, cvRTId);
        Test.stopTest();
      
    }

    // Test for relateFileToOpportunity method
    @isTest
    public static void testRelateFileToOpportunity() {
        // Create Account, Opportunity, and Project
        Account acc = createTestAccount();
        Opportunity opp = createTestOpportunity(acc.Id);
        Project__c project = createTestProject(opp.Id);

        // Create ContentVersion linked to the project and fetch ContentDocumentId
        ContentVersion cv = createTestContentVersion(project.Id);

        // Call the relateFileToOpportunity method
        Test.startTest();
        AttachmentTypeController.relateFileToOpportunity(project.Id, new List<Id>{cv.ContentDocumentId});
        Test.stopTest();

        // Verify that the ContentDocumentLink is created
        List<ContentDocumentLink> cdls = [SELECT Id, ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE ContentDocumentId = :cv.ContentDocumentId AND LinkedEntityId = :opp.Id];
        System.assertEquals(cdls.size(), 1, 'There should be one ContentDocumentLink created');
        ContentDocumentLink cdl = cdls[0];
        System.assertEquals(cdl.LinkedEntityId, opp.Id, 'ContentDocumentLink should be related to the Opportunity');
        System.assertEquals(cdl.ContentDocumentId, cv.ContentDocumentId, 'ContentDocumentLink should be related to the correct ContentDocument');
    }

    // Test for exception handling in updateAttachmentTypes method
    @isTest
    public static void testUpdateAttachmentTypesException() {
        // Call updateAttachmentTypes with invalid parameters (no ContentDocumentIds)
        Test.startTest();
        try {
            Account acc = createTestAccount();
            Opportunity opp = createTestOpportunity(acc.Id);
            Project__c project = createTestProject(opp.Id);

            AttachmentTypeController.updateAttachmentTypesFromProject(null, project.Id, 'Vendor Quote', Date.today());
            System.assert(false, 'Exception should be thrown');
        } catch (AuraHandledException e) {
            // Correct order: expected value first, actual value second
            System.assertEquals('Script-thrown exception', e.getMessage(), 'Error message should match');
        }
        Test.stopTest();
    }
    
    // Test for exception handling in relateFileToOpportunity method
    @isTest
    public static void testRelateFileToOpportunityException() {
        // Call relateFileToOpportunity with invalid parameters (no ProjectId or ContentDocumentIds)
        Test.startTest();
        try {
            AttachmentTypeController.relateFileToOpportunity(null, null);
            System.assert(false, 'Exception should be thrown');
        } catch (AuraHandledException e) {
            // Correct order: expected value first, actual value second
            System.assertEquals('Script-thrown exception', e.getMessage(), 'Error message should match');
        }
        Test.stopTest();
    }
    
    @isTest
    public static void testgetContentVersionRecordTypeId(){
        createTestAccount();
        // Query Account to pass to the createTestOpportunityMethod
        Id accountId = [SELECT Id FROM Account LIMIT 1].Id;
        
        createTestOpportunity(accountId);
        
        // Query Opportunity to pass to the createTestProjectMethod
        Id oppId = [SELECT Id FROM Opportunity LIMIT 1].Id;
        
        createTestProject(oppId);
        
        // Query ProjectId
        Id projectId = [SELECT Id FROM Project__C LIMIT 1].Id;
        
        // Create ContentVersion linked to the project and fetch ContentDocumentId
        ContentVersion cv = createTestContentVersion(projectId);
        
        Test.startTest();
        AttachmentTypeController.getContentVersionRecordTypeId(projectId, null);
        Test.stopTest();

        
    }
    
}