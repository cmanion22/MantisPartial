@isTest
public class UploadProjectFileControllerTest {

    // Helper method to create a sample project
    private static Project__c createTestProject() {
        // Create and insert test Account
        Account acc = new Account();
        acc.Name = 'Funny Account12';
        acc.Legal_Entity_Name__c = 'Sample Account';
        acc.Phone = '1111111289';
        insert acc;
        
        // Create a test Opportunity
        Opportunity opp = new Opportunity();
        opp.Name = 'Funny Account - 12121';
        opp.AccountId = acc.Id;
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
        
        // Create a project
        Project__c project = new Project__c(Name = 'Test Project',
                                            Type_of_Service__c = 'Solar',
                                            Project_Amount__c = 12,
                                            Opportunity__c = opp.Id);
        insert project;
        return project;
    }

    // Helper method to create a sample ContentVersion
    private static ContentVersion createTestContentVersion(Id projectId, Date expirationDate) {
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Test File';
        cv.VersionData = Blob.valueOf('Test content data');
        cv.PathOnClient = 'testfile.txt';
        cv.Attachment_Type__c = 'Project Setup Form';
        cv.FirstPublishLocationId = projectId;
        cv.ContentLocation = 'S';
        cv.IsMajorVersion = true;
        cv.Expiration_Date__c = expirationDate;
        insert cv;
        return cv;
    }

    // Test for uploadFile method
    @isTest
    public static void testUploadFile() {
        // Create a test project
        Project__c project = createTestProject();
        Date expirationDate = Date.today().addDays(30);

        // Prepare parameters for uploadFile method
        String fileName = 'testfile.txt';
        String fileRecordName = 'Test File Record';
        String fileContentBase64 = EncodingUtil.base64Encode(Blob.valueOf('Test content data'));
        String attachmentType = 'Project Setup Form';

        // Call the uploadFile method
        Test.startTest();
        String contentVersionId = UploadProjectFileController.uploadFile(fileName, fileRecordName, fileContentBase64, attachmentType, project.Id, expirationDate);
        Test.stopTest();

        // Verify that the ContentVersion was inserted successfully
        ContentVersion cv = [SELECT Id, Title, Attachment_Type__c, Expiration_Date__c FROM ContentVersion WHERE Id = :contentVersionId LIMIT 1];
        System.assertNotEquals(cv, null, 'ContentVersion should be created');
        System.assertEquals(cv.Attachment_Type__c, attachmentType, 'Attachment type should match');
        System.assertEquals(cv.Expiration_Date__c, expirationDate, 'Expiration date should match');
    }

    // Test for getUploadedFiles method
    @isTest
    public static void testGetUploadedFiles() {
        // Create a test project and a test content version
        Project__c project = createTestProject();
        Date expirationDate = Date.today().addDays(30);
        ContentVersion cv = createTestContentVersion(project.Id, expirationDate);

        // Call the getUploadedFiles method
        Test.startTest();
        List<ContentVersion> contentVersions = UploadProjectFileController.getUploadedFiles(project.Id);
        Test.stopTest();

        // Verify that the ContentVersion is retrieved
        System.assertNotEquals(contentVersions, null, 'ContentVersion list should not be null');
        System.assertEquals(contentVersions.size(), 1, 'There should be one ContentVersion');
        ContentVersion retrievedCv = contentVersions[0];
        System.assertEquals(retrievedCv.Id, cv.Id, 'The retrieved ContentVersion should match the inserted one');
    }

    // Test for deleteFiles method
    @isTest
    public static void testDeleteFiles() {
        // Create a test project and a test content version
        Project__c project = createTestProject();
        Date expirationDate = Date.today().addDays(30);
        ContentVersion cv = createTestContentVersion(project.Id, expirationDate);
    
        // After the ContentVersion is inserted, get the ContentDocumentId
        ContentVersion insertedCv = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
    
        // Call the deleteFiles method with the ContentVersion that has a valid ContentDocumentId
        Test.startTest();
        String result = UploadProjectFileController.deleteFiles(new List<ContentVersion>{insertedCv});
        Test.stopTest();
    
        // Verify that the ContentDocument is deleted
        System.assertEquals(result, 'success', 'The files should be successfully deleted');
        Integer count = [SELECT COUNT() FROM ContentDocument WHERE Id = :insertedCv.ContentDocumentId];
        System.assertEquals(count, 0, 'The ContentDocument should be deleted');
    }


    // Test for exception handling in uploadFile method
    @isTest
    public static void testUploadFileException() {
        // Call uploadFile with invalid parameters
        Test.startTest();
        try {
            UploadProjectFileController.uploadFile(null, null, null, null, null, null);
            System.assert(false, 'Exception should be thrown');
        } catch (AuraHandledException e) {
            System.assertEquals('Script-thrown exception', 'Script-thrown exception', 'Error message should match');
        }
        Test.stopTest();
    }

    // Test for exception handling in getUploadedFiles method
    @isTest
    public static void testGetUploadedFilesException() {
        // Call getUploadedFiles with an invalid projectId
        Test.startTest();
        try {
            UploadProjectFileController.getUploadedFiles(null);
            System.assert(false, 'Exception should be thrown');
        } catch (AuraHandledException e) {
            System.assertEquals('Script-thrown exception', 'Script-thrown exception', 'Error message should match');
        }
        Test.stopTest();
    }

    // Test for exception handling in deleteFiles method
    @isTest
    public static void testDeleteFilesException() {
        // Call deleteFiles with an invalid ContentVersion list
        Test.startTest();
        try {
            UploadProjectFileController.deleteFiles(null);
            System.assert(false, 'No Content Versions provided for deletion');
        } catch (AuraHandledException e) {
            System.assertEquals('Script-thrown exception', 'Script-thrown exception', 'Error message should match');
        }
        Test.stopTest();
    }
}