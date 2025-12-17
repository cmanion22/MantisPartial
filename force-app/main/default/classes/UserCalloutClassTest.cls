@isTest
public class UserCalloutClassTest { 

    @TestSetup
    static void makeData() {
        insert new Configuration__c(Name = 'ESBURL');
        insert new Back_Office_Integration_Settings__c(Name = 'Staging', Endpoint_URL__c = 'https://www.example.com');
        insert new Back_Office_Integration_Settings__c(Name = 'Production', Endpoint_URL__c = 'https://www.example.com');
    }

    @isTest
    static void createUserTest() {
        Test.startTest();

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

        Savepoint sp = Database.setSavepoint();

        Test.setMock(HttpCalloutMock.class, new HttpEmexCalloutMock(200, 'OK', '{success:true}'));
        String json = UserCalloutClass.createUser(thisUser.Id, thisUser.Id);

        Database.rollback(sp);
        Test.stopTest();

        System.assertNotEquals(null, json);
    }

}