@isTest
public class SobjectCallInTest {    
     @isTest static void clearSyncDataTest() {
     
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
            Entity_ID__c=testEntity.Id, Entity_Name__c=testEntity.Name);
            
        insert testUser;

        Account testAccount = new Account();
        testAccount.Name = 'Test Account';
        testAccount.Legal_Entity_Name__c = 'Sample Account';
        testAccount.Phone = '9090909090';
        testAccount.Entity__c = testEntity.Id;
        testAccount.OwnerId = testUser.Id;   
        insert testAccount;

        Contact testContact = new Contact();
        testContact.OwnerId = testUser.Id;
        testContact.AccountId = testAccount.Id;
        testContact.LastName = 'Doe';
        testContact.FirstName = 'John';
        testContact.Phone = '9090909090';
        testContact.Email = 'johndoe@example.com';
        testContact.MailingCity = 'Houston';
        testContact.MailingState = 'TX';
        testContact.MailingStreet = '123 Main St';
        testContact.MailingPostalCode = '77002';
        insert testContact;
        
        SObject record = Helper.getSObject(testContact.Id);
        record.put('Out_of_Sync__c', true);
        record.put('Sync_Error__c', '{"success":false,"errors":["Could not authenticate."]}');
        record.put('Sync_Payload__c', '{"key": "value"}');
        update record;
        
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        req.addHeader('httpMethod', 'POST');
        req.requestUri = '/services/apexrest/ClearSyncData/';   
        req.requestBody = Blob.valueof('{ "id": "' + testContact.Id + '" }');
        
        RestContext.request = req; 
        RestContext.response = res;
        
        Test.startTest();
        SObject obj = SobjectCallIn.clearSyncData();
        Test.stopTest();
                
        Contact c = [SELECT ID, Out_of_Sync__c FROM Contact WHERE Id =: record.Id];

        System.assertEquals(c.Out_of_Sync__c, false);        
    } 
}