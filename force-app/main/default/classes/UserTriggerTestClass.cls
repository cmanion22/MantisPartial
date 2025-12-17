@isTest
public class UserTriggerTestClass {
    @isTest(SeeAllData=true) static void userTriggerTest() {
        Test.setMock(HttpCalloutMock.class, new HttpEmexCalloutMock(200, 'OK', '{success:true}'));  
                
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
            Entity_ID__c=testEntity.Id, Entity_Name__c=testEntity.Name);
        
        Test.startTest();
        insert thisUser;
        Test.stopTest();
        
        List<User> lst = [SELECT Id, CreatedDate FROM User WHERE Id = :thisUser.Id];
        System.assertEquals(1, lst.size());
    }

    @isTest(SeeAllData=true) static void userTriggerTest_Active() {
        Test.setMock(HttpCalloutMock.class, new HttpEmexCalloutMock(200, 'OK', '{success:true}')); 
        
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
            Entity_ID__c=testEntity.Id, Entity_Name__c=testEntity.Name);

        Turn_off_Processes__c processSettings = Turn_off_Processes__c.getValues('migration in progress');
        processSettings.Is_Active__c = true;    
        
        Test.startTest();
        insert thisUser;
        Test.stopTest();
        
        List<User> lst = [SELECT Id, CreatedDate FROM User WHERE Id = :thisUser.Id];
        System.assertEquals(1, lst.size());
    }

    @isTest(SeeAllData=true) static void userTriggerTest_apiupdate() {
        Test.setMock(HttpCalloutMock.class, new HttpEmexCalloutMock(200, 'OK', '{success:true}')); 
        
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
            Entity_ID__c=testEntity.Id, Entity_Name__c=testEntity.Name);

        insert thisUser;

        Test.startTest();    // Starts the scope of test
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        req.addHeader('httpMethod', 'PATCH');
        req.requestUri = '/services/data/v48.0/sobjects/User/' + thisUser.Id;       
        
        req.requestBody = Blob.valueof('{ "MiddleName" : "" }');
        RestContext.request = req; 
        RestContext.response = res;
        Test.stopTest();    // Ends the scope of test
        
        List<User> lst = [SELECT Id, CreatedDate FROM User WHERE Id = :thisUser.Id];
        System.assertEquals(1, lst.size());
    }
}