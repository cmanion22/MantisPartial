@isTest
public class TaskTriggerTestClass {
    @isTest(SeeAllData=true) static void taskTriggerInsertTest() {
        Test.setMock(HttpCalloutMock.class, new HttpEmexCalloutMock(200, 'OK', '{success:true}'));  
        //Create Data for Task object
        Task testTask = new Task();
        
        Test.startTest();
        testTask.Subject = 'Test Task';  
        testTask.Priority = 'Medium';
        testTask.Status = 'Open';       
        insert testTask;
        Test.stopTest(); 
        
        // Now check if it is giving desired results using System.assert
        // Statement.New Task should be created
        List<Task> lst = [SELECT Id, Subject, Priority, Status FROM Task WHERE Id = :testTask.Id];
        System.assertEquals(1, lst.size());
        // Check if one record is created in Task sObject
    }
    
    @isTest(SeeAllData=true)
    static void taskTriggerInsertCompletedTest() {
       Test.setMock(HttpCalloutMock.class, new HttpEmexCalloutMock(200, 'OK', '{success:true}'));
    
        Task testTask = new Task(
            Subject = 'Test Task',
            Priority = 'Medium',
            Status = 'Complete'
        );
    
        Test.startTest();
        insert testTask;
        Test.stopTest();
    
        // Verify task creation
        System.assertEquals(
            1,
            [SELECT COUNT() FROM Task WHERE Id = :testTask.Id]
        );
    
    }

    
    @isTest(SeeAllData=true) static void taskTriggerUpdateTest() {
        Test.setMock(HttpCalloutMock.class, new HttpEmexCalloutMock(200, 'OK', '{success:true}'));          

        Task testTask = new Task();
        testTask.Subject = 'Test Task';  
        testTask.Priority = 'Medium';
        testTask.Status = 'Not Started';
        

        testTask.SyncMessageDisplay__c = false;       
        insert testTask;     
           
        // Now, our trigger will fire on After update event so update the Records
        Test.startTest();    // Starts the scope of test
        testTask.Status = 'Complete';
        

        testTask.SyncMessageDisplay__c = false;
        update testTask;
        Test.stopTest();    // Ends the scope of test
        
        // Now check if it is giving desired results using System.assert
        // Statement.New Task should be created
        List<Task> lst = [SELECT Id, Subject, Priority, Status FROM Task WHERE Id = :testTask.Id];
        System.assertEquals(1, lst.size());
        // Check if one record is created in Task sObject
    }
    
    @isTest(SeeAllData=true) static void taskTriggerUpdateLeadTest() {
        Test.setMock(HttpCalloutMock.class, new HttpEmexCalloutMock(200, 'OK', '{success:true}'));          
		
        Lead testLead = new Lead(LastName='Test');
        testLead.company='Test 1234567890';
        insert testLead;
        
        Task testTask = new Task();
        testTask.Subject = 'Test Task';  
        testTask.Priority = 'Medium';
        testTask.Status = 'Not Started';
        testTask.WhoId=testLead.Id;
        

        testTask.SyncMessageDisplay__c = false;       
        insert testTask;     
           
        // Now, our trigger will fire on After update event so update the Records
        Test.startTest();    // Starts the scope of test
        testTask.Status = 'Complete';
     

        testTask.SyncMessageDisplay__c = false;
        update testTask;
        Test.stopTest();    // Ends the scope of test
        
        // Now check if it is giving desired results using System.assert
        // Statement.New Task should be created
        List<Task> lst = [SELECT Id, Subject, Priority, Status FROM Task WHERE Id = :testTask.Id];
        System.assertEquals(1, lst.size());
        // Check if one record is created in Task sObject
    }
    

    @isTest(SeeAllData=true) static void taskTriggerUpdateTest_Active() {
        Test.setMock(HttpCalloutMock.class, new HttpEmexCalloutMock(200, 'OK', '{success:true}'));  

        Turn_off_Processes__c processSettings = Turn_off_Processes__c.getValues('migration in progress');
        processSettings.Is_Active__c = true;

        Task testTask = new Task();
        testTask.Subject = 'Test Task';  
        testTask.Priority = 'Medium';
        testTask.Status = 'Not Started';
       

        testTask.SyncMessageDisplay__c = false;       
        insert testTask;     
           
        // Now, our trigger will fire on After update event so update the Records
        Test.startTest();    // Starts the scope of test
        testTask.Status = 'Complete';
        

        testTask.SyncMessageDisplay__c = false;
        update testTask;
        Test.stopTest();    // Ends the scope of test
        
        // Now check if it is giving desired results using System.assert
        // Statement.New Task should be created
        List<Task> lst = [SELECT Id, Subject, Priority, Status FROM Task WHERE Id = :testTask.Id];
        System.assertEquals(1, lst.size());
        // Check if one record is created in Task sObject
    }

    @isTest(SeeAllData=true) static void taskTriggerUpdateTest_OutOfSync() {
        Test.setMock(HttpCalloutMock.class, new HttpEmexCalloutMock(200, 'OK', '{success:true}'));  

        Task testTask = new Task();
        testTask.Subject = 'Test Task';  
        testTask.Priority = 'Medium';
        testTask.Status = 'Not Started'; 
        
       
        testTask.SyncMessageDisplay__c = false;      
        insert testTask;     
           
        // Now, our trigger will fire on After update event so update the Records
        Test.startTest();    // Starts the scope of test
        testTask.Status = 'Complete';
       
        
        testTask.SyncMessageDisplay__c = false;  
        update testTask;
        Test.stopTest();    // Ends the scope of test
        
        // Now check if it is giving desired results using System.assert
        // Statement.New Task should be created
        List<Task> lst = [SELECT Id, Subject, Priority, Status FROM Task WHERE Id = :testTask.Id];
        System.assertEquals(1, lst.size());
        // Check if one record is created in Task sObject
    }

    @isTest(SeeAllData=true) static void taskTriggerUpdateTest_apiupdate() {
        Test.setMock(HttpCalloutMock.class, new HttpEmexCalloutMock(200, 'OK', '{success:true}'));  

        Turn_off_Processes__c processSettings = Turn_off_Processes__c.getValues('migration in progress');
        processSettings.Is_Active__c = true;

        Task testTask = new Task();
        testTask.Subject = 'Test Task';  
        testTask.Priority = 'Medium';
        testTask.Status = 'Not Started';
        
       
        testTask.SyncMessageDisplay__c = false;       
        insert testTask;     
           
        // Now, our trigger will fire on After update event so update the Records
        Test.startTest();    // Starts the scope of test
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        req.addHeader('httpMethod', 'PATCH');
        req.requestUri = '/services/data/v48.0/sobjects/Task/' + testTask.Id;       
        
        req.requestBody = Blob.valueof('{ "Priority" : "High" }');
        RestContext.request = req; 
        RestContext.response = res;
        Test.stopTest();    // Ends the scope of test
        
        // Now check if it is giving desired results using System.assert
        // Statement.New Task should be created
        List<Task> lst = [SELECT Id, Subject, Priority, Status FROM Task WHERE Id = :testTask.Id];
        System.assertEquals(1, lst.size());
        // Check if one record is created in Task sObject
    }
    
}