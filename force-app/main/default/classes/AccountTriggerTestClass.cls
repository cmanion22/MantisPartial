@isTest
public class AccountTriggerTestClass {
     @isTest(SeeAllData=true) static void accountTriggerTest() {
        Test.setMock(HttpCalloutMock.class, new HttpEmexCalloutMock(200, 'OK', '{success:true}'));  
        //Create Data for Account object
        Entity__c testEntity = new Entity__c();
        testEntity.Name = 'Test Entity';
        testEntity.Brand__c = 'Test Brand';
        testEntity.Source_ID__c = 'Test Source Id Entity';
        testEntity.Source_Database__c = 'Test Source DB Entity';      
        insert testEntity;
        
        Profile testProfile = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User testUser = new User(Alias = 'standt', Email='testuser@emex.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = testProfile.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='emextestuser@emex.com',
            Entity_ID__c=testEntity.Id, Entity_Name__c=testEntity.Name, API_Token__c = 'test');
            
        insert testUser;

        Account testAccount = new Account();
        testAccount.Name = 'Test Account';
        testAccount.Legal_Entity_Name__c = 'Sample Account';
        testAccount.Phone = '9090909090';
        testAccount.Entity__c = testEntity.Id;
        testAccount.OwnerId = testUser.Id;
       

        testAccount.SyncMessageDisplay__c = false;
        
        
        insert testAccount;
        
        // Now, our trigger will fire on After update event so update the Records
        Test.startTest();    // Starts the scope of test
        testAccount.Legal_Entity_Name__c = 'New Sample';
        

        //testAccount.SyncMessageDisplay__c = false;
      
        
        update testAccount;
        Test.stopTest();     // Ends the scope of test
        
        // Now check if it is giving desired results using System.assert
        // Statement.New Account should be created
        List<Account> lst = [SELECT Id, Name, Legal_Entity_Name__c FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals(1, lst.size());
        // Check if one record is created in Account sObject
    }

    @isTest(SeeAllData=true) static void accountTriggerTest_OutOfSync() {
        Test.setMock(HttpCalloutMock.class, new HttpEmexCalloutMock(200, 'OK', '{success:true}'));  
        //Create Data for Account object
        Entity__c testEntity = new Entity__c();
        testEntity.Name = 'Test Entity';
        testEntity.Brand__c = 'Test Brand';
        testEntity.Source_ID__c = 'Test Source Id Entity';
        testEntity.Source_Database__c = 'Test Source DB Entity';      
        insert testEntity;
        
        Profile testProfile = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User testUser = new User(Alias = 'standt', Email='testuser@emex.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = testProfile.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='emextestuser@emex.com',
            Entity_ID__c=testEntity.Id, Entity_Name__c=testEntity.Name, API_Token__c = 'test');
            
        insert testUser;

        Account testAccount = new Account();
        testAccount.Name = 'Test Account';
        testAccount.Legal_Entity_Name__c = 'Sample Account';
        testAccount.Phone = '9090909090';
        testAccount.Entity__c = testEntity.Id;
        testAccount.OwnerId = testUser.Id;           
       
        
        testAccount.SyncMessageDisplay__c = false;
        

        insert testAccount;
        
        // Now, our trigger will fire on After update event so update the Records
        Test.startTest();    // Starts the scope of test
        testAccount.Legal_Entity_Name__c = 'New Sample';
        
        
        testAccount.SyncMessageDisplay__c = false;


        update testAccount;
        Test.stopTest();     // Ends the scope of test
        
        // Now check if it is giving desired results using System.assert
        // Statement.New Account should be created
        List<Account> lst = [SELECT Id, Name, Legal_Entity_Name__c FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals(1, lst.size());
        // Check if one record is created in Account sObject
    }


    @isTest(SeeAllData=true) static void accountTriggerTest_Active() {
        Test.setMock(HttpCalloutMock.class, new HttpEmexCalloutMock(200, 'OK', '{success:true}'));  
        //Create Data for Account object
        Entity__c testEntity = new Entity__c();
        testEntity.Name = 'Test Entity';
        testEntity.Brand__c = 'Test Brand';
        testEntity.Source_ID__c = 'Test Source Id Entity';
        testEntity.Source_Database__c = 'Test Source DB Entity';      
        insert testEntity;
        
        Profile testProfile = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User testUser = new User(Alias = 'standt', Email='testuser@emex.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = testProfile.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='emextestuser@emex.com',
            Entity_ID__c=testEntity.Id, Entity_Name__c=testEntity.Name, API_Token__c = 'test');
            
        insert testUser;

        Account testAccount = new Account();
        testAccount.Name = 'Test Account';
        testAccount.Legal_Entity_Name__c = 'Sample Account';
        testAccount.Phone = '9090909090';
        testAccount.Entity__c = testEntity.Id;
        testAccount.OwnerId = testUser.Id;           
        

        testAccount.SyncMessageDisplay__c = false;
        
        
        insert testAccount;
        
        Turn_off_Processes__c processSettings = Turn_off_Processes__c.getValues('migration in progress');
        processSettings.Is_Active__c = true;

        // Now, our trigger will fire on After update event so update the Records
        Test.startTest();    // Starts the scope of test
        
        testAccount.Legal_Entity_Name__c = 'New Sample';
      
        testAccount.SyncMessageDisplay__c = false;

        

        update testAccount;
        Test.stopTest();     // Ends the scope of test
        
        // Now check if it is giving desired results using System.assert
        // Statement.New Account should be created
        List<Account> lst = [SELECT Id, Name, Legal_Entity_Name__c FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals(1, lst.size());
        // Check if one record is created in Account sObject
    }

    @isTest(SeeAllData=true) static void accountTriggerTest_apiupdate() {
        Test.setMock(HttpCalloutMock.class, new HttpEmexCalloutMock(200, 'OK', '{success:true}'));  
        //Create Data for Account object
        Entity__c testEntity = new Entity__c();
        testEntity.Name = 'Test Entity';
        testEntity.Brand__c = 'Test Brand';
        testEntity.Source_ID__c = 'Test Source Id Entity';
        testEntity.Source_Database__c = 'Test Source DB Entity';      
        insert testEntity;
        
        Profile testProfile = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User testUser = new User(Alias = 'standt', Email='testuser@emex.com', 
            EmailEncodingKey='UTF-8', FirstName = 'Testing', LastName='User', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = testProfile.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='emextestuser@emex.com',
            Entity_ID__c=testEntity.Id, Entity_Name__c=testEntity.Name, API_Token__c = 'test');
            
        insert testUser;

        Account testAccount = new Account();
        testAccount.Name = 'Test Account';
        testAccount.Legal_Entity_Name__c = 'Sample Account';
        testAccount.Phone = '9090909090';
        testAccount.Entity__c = testEntity.Id;
        testAccount.OwnerId = testUser.Id;           
     

        testAccount.SyncMessageDisplay__c = false;
       

        insert testAccount;
        
        Turn_off_Processes__c processSettings = Turn_off_Processes__c.getValues('migration in progress');
        processSettings.Is_Active__c = true;

        // Now, our trigger will fire on After update event so update the Records
        Test.startTest();    // Starts the scope of test
        
        
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        req.addHeader('httpMethod', 'PATCH');
        req.requestUri = '/services/data/v48.0/sobjects/Account/' + testAccount.Id;       
        
        req.requestBody = Blob.valueof('{ "Name" : "New Name" }');
        RestContext.request = req; 
        RestContext.response = res;
            
             
        Test.stopTest();     // Ends the scope of test
        
        // Now check if it is giving desired results using System.assert
        // Statement.New Account should be created
        List<Account> lst = [SELECT Id, Name, Legal_Entity_Name__c FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals(1, lst.size());
        // Check if one record is created in Account sObject
    } 
    
    @isTest static void runAsTestingUser() {
        
        Profile testProfile = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User testUser = new User(Alias = 'standt', Email='testuser@emex.com', 
            EmailEncodingKey='UTF-8', FirstName = 'Testing', LastName='User', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = testProfile.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='emextestuser@emex.com');
            
            
        insert testUser;
        
        Account testAccount = new Account();
        testAccount.Name = 'Test Account';
        testAccount.Phone = '9090909090';
        
        
        Test.startTest();
        System.runAs(testUser) {
           
            
            insert testAccount;
        }
        
        Test.stopTest();
        
        List <Account> updatedAccount = [SELECT Id, Phone FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals(1, updatedAccount.size());
    }
}