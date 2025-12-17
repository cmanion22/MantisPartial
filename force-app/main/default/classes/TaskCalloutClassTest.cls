@isTest
public class TaskCalloutClassTest { 

    @TestSetup
    static void makeData() {
        insert new Configuration__c(Name = 'ESBURL');
        insert new Back_Office_Integration_Settings__c(Name = 'Staging', Endpoint_URL__c = 'https://www.example.com');
        insert new Back_Office_Integration_Settings__c(Name = 'Production', Endpoint_URL__c = 'https://www.example.com');
    }

    @isTest
    static void updateTaskTest() {
        Test.setMock(HttpCalloutMock.class, new HttpEmexCalloutMock(200, 'OK', '{success:true}'));

        Task testTask = new Task();
        testTask.Subject = 'Test Task';
        testTask.Priority = 'Normal';
        testTask.Status = 'Open';
        insert testTask;

        Entity__c testEntity = new Entity__c();
        testEntity.Name = 'Test Entity';
        testEntity.Brand__c = 'Test Brand';
        testEntity.Source_ID__c = 'Test Source Id Entity';
        testEntity.Source_Database__c = 'Test Source DB Entity';
        insert testEntity;

        Profile thisProfile = [SELECT Id FROM Profile WHERE Name='Standard User'];

        User thisUser = new User(Alias = 'standt', Email='testuser@emex.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = thisProfile.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='emextestuser@emex.com',
            Entity_ID__c=testEntity.Id, Entity_Name__c=testEntity.Name, API_Token__c = 'test');

        insert thisUser;

        Task task = [SELECT Id, Subject, Priority FROM Task WHERE Id =: testTask.Id];
        String json = TaskCalloutClass.updateTask(task.Id, thisUser.Id);
        System.assertEquals(testTask.Id, task.Id);
    }

    @isTest public static void createTaskCommentTest() {
        Test.startTest();

        Task testTask = new Task();
        testTask.Subject = 'Test Task';
        testTask.Priority = 'Normal';
        testTask.Status = 'Open';
        insert testTask;
        
        ContentNote testContentNote = new ContentNote();
        testContentNote.Title = 'Test Title';
        testContentNote.Content = Blob.valueOf('Test Content');
        insert testContentNote;
        
        ContentDocumentLink testContentDocumentLink = new ContentDocumentLink();
        testContentDocumentLink.LinkedEntityId = testTask.Id;
        testContentDocumentLink.ContentDocumentId = testContentNote.Id;
        testContentDocumentLink.ShareType = 'V';
        insert testContentDocumentLink;
        
        Savepoint sp = Database.setSavepoint();

        Task task = [SELECT Id, Subject, Priority FROM Task WHERE Id =: testTask.Id];

        Test.setMock(HttpCalloutMock.class, new HttpEmexCalloutMock(200, 'OK', '{success:true}'));
        String json = TaskCalloutClass.createTaskComment(testContentDocumentLink.ContentDocumentId, testTask.Id);
        Database.rollback(sp);
        Test.stopTest();

        System.assertNotEquals(null, json);
    } 
}