@isTest
public class HttpRetryAsyncTest {

    @TestSetup
    static void makeData() {
        insert new Configuration__c(Name = 'ESBURL');
        insert new Back_Office_Integration_Settings__c(Name = 'Staging', Endpoint_URL__c = 'https://www.example.com');
        insert new Back_Office_Integration_Settings__c(Name = 'Production', Endpoint_URL__c = 'https://www.example.com');
    }

    @isTest static void startJobTest() {
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
        insert testAccount;

        String accountJson = Helper.getFormattedJson(AccountHelper.getAccount(testAccount.Id));

        String body = 
                  '{"event": "update_account"' +
                  ', "data": {' +                
                      '"account": ' + accountJson +                
                    '}' + 
                  '}';

        HttpRetryAsync sync = new HttpRetryAsync(ESBController.getESBUrl(), 'POST', body, 'UpdateAccount');

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new HttpEmexCalloutMock(200, 'OK', '{success:true}'));
        JobResult result = sync.startJob();
        Test.stopTest();
    }

    @isTest
    static void startJobTestWithSObjectId() {
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
        insert testAccount;

        String accountJson = Helper.getFormattedJson(AccountHelper.getAccount(testAccount.Id));

        String body = 
                  '{"event": "update_account"' +
                  ', "data": {' +                
                      '"account": ' + accountJson +                
                    '}' + 
                  '}';

        HttpRetryAsync sync = new HttpRetryAsync(ESBController.getESBUrl(), 'POST', body, 'UpdateAccount', testAccount.Id);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new HttpEmexCalloutMock(200, 'OK', '{success:true}'));
        JobResult result = sync.startJob();
        Test.stopTest();
    }

    @isTest static void startJobTest_Fail() {
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
        insert testAccount;

        String accountJson = Helper.getFormattedJson(AccountHelper.getAccount(testAccount.Id));

        String body = 
                  '{"event": "update_account"' +
                  ', "data": {' +                
                      '"account": ' + accountJson +                
                    '}' + 
                  '}';
    
        HttpRetryAsync sync = new HttpRetryAsync('http://urldoesnotexist.com', 'POST', body, 'UpdateAccount');

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new HttpEmexCalloutMock(404, 'Not Found', '{"error":"Does not exist"}'));
        JobResult result = sync.startJob();
        Test.stopTest();
    }

    @isTest static void startJobTestWithSObjectId_Fail() {
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
        insert testAccount;

        String accountJson = Helper.getFormattedJson(AccountHelper.getAccount(testAccount.Id));

        String body = 
                  '{"event": "update_account"' +
                  ', "data": {' +                
                      '"account": ' + accountJson +                
                    '}' + 
                  '}';
    
        HttpRetryAsync sync = new HttpRetryAsync('http://urldoesnotexist.com', 'POST', body, 'UpdateAccount', testAccount.Id);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new HttpEmexCalloutMock(404, 'Not Found', '{"error":"Does not exist"}'));
        JobResult result = sync.startJob();
        Test.stopTest();
    }

    @isTest static void startJobTest_jobRetryEnabled() {
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
        insert testAccount;

        String accountJson = Helper.getFormattedJson(AccountHelper.getAccount(testAccount.Id));

        String body = 
                  '{"event": "update_account"' +
                  ', "data": {' +                
                      '"account": ' + accountJson +                
                    '}' + 
                  '}';
                    
        Constants.jobRetryEnabled = true;
        HttpRetryAsync sync = new HttpRetryAsync('http://urldoesnotexist.com', 'POST', body, 'UpdateAccount', testAccount.Id);
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new HttpEmexCalloutMock(404, 'Not Found', '{"error":"Does not exist"}'));
        JobResult result = sync.startJob();
        Test.stopTest();
    }

}