@isTest
public class TaskHelperTest {

    @TestSetup
    static void makeData() {
        insert new Configuration__c(Name = 'ESBURL');
        insert new Back_Office_Integration_Settings__c(Name = 'Staging', Endpoint_URL__c = 'https://www.example.com');
        insert new Back_Office_Integration_Settings__c(Name = 'Production', Endpoint_URL__c = 'https://www.example.com');
    }

    @isTest static void postUpdateTaskJsonTest() {
        Task testTask = new Task();
        testTask.Subject = 'Test Task';
        testTask.Priority = 'Normal';
        testTask.Status = 'Open';
        insert testTask;

        Test.setMock(HttpCalloutMock.class, new HttpEmexCalloutMock(200, 'OK', '{success:true}'));
        Task task = [SELECT Id, Subject, Priority FROM Task WHERE Id =: testTask.Id];
        String json = TaskHelper.postUpdateTaskJson(task);

        System.assertNotEquals(null, json);
    }

    @isTest static void postCreateTaskCommentJsonTest() {
        Test.startTest();
        Task testTask = new Task();
        testTask.Subject = 'Test Task';
        testTask.Priority = 'Normal';
        testTask.Status = 'Open';
        testTask.Description = 'Test description';
        insert testTask;

        ContentNote testContentNote = new ContentNote();
        testContentNote.Title = 'Test title';
        testContentNote.Content = Blob.valueOf('Test content');
        insert testContentNote;

        ContentDocumentLink testContentDocumentLink = new ContentDocumentLink();
        testContentDocumentLink.LinkedEntityId = testTask.Id;
        testContentDocumentLink.ContentDocumentId = testContentNote.Id;
        testContentDocumentLink.ShareType = 'V';
        insert testContentDocumentLink;

        Savepoint sp = Database.setSavepoint();

        Test.setMock(HttpCalloutMock.class, new HttpEmexCalloutMock(200, 'OK', '{success:true}'));
        String json = TaskHelper.postCreateTaskCommentJson(testContentDocumentLink.ContentDocumentId, testTask.Id);
        Database.rollback(sp);
        Test.stopTest();

        System.assertNotEquals(null, json);
    } 

    @isTest static void getNotesDataTest() 
    {    
        ContentNote testContentNote = new ContentNote();
        testContentNote.Title = 'Test title';                     
        insert testContentNote;
        ContentNote note = TaskHelper.getNotesData(testContentNote.Id);
        List<ContentNote> lst = [SELECT Id, Title FROM ContentNote WHERE Id = :note.Id];
        System.assertEquals(1, lst.size());
    }
}