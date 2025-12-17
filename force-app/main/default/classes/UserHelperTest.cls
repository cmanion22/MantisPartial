@isTest
public class UserHelperTest {

    @TestSetup
    static void makeData() {
        insert new Configuration__c(Name = 'ESBURL');
        insert new Back_Office_Integration_Settings__c(Name = 'Staging', Endpoint_URL__c = 'https://www.example.com');
        insert new Back_Office_Integration_Settings__c(Name = 'Production', Endpoint_URL__c = 'https://www.example.com');
    }

    @isTest static void postCreateUserJsonTest() {
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

        User user = [SELECT Id FROM USER WHERE Email='testuser@emex.com'];
        user = UserHelper.GetUser(user.Id);

        Test.setMock(HttpCalloutMock.class, new HttpEmexCalloutMock(200, 'OK', '{success:true}'));
        String json = UserHelper.postCreateUserJson(thisUser.Id, thisUser.Id);

        Database.rollback(sp);
        Test.stopTest();

        System.assertNotEquals(null, json);
    }

    @isTest
    static void GetUser() {
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
            Entity_ID__c=testEntity.Id, Entity_Name__c=testEntity.Name, API_Token__c = 'test');

        insert thisUser;

        User user = [SELECT Id FROM USER WHERE Email='testuser@emex.com'];
        user = UserHelper.GetUser(user.Id);

        System.assertNotEquals(null, user);
    }

}