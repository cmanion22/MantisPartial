@isTest
public class OpportunityCallInTest {  

    @testSetup static void setup() {
        Uuid brokerUuid = new Uuid();
        String brokerUuidValue = brokerUuid.getValue();
        insert new Broker__c(
            Name = 'Mock Broker',
            Source_ID__c = 'Source Id ' + brokerUuidValue,
            Source_Database__c = 'Source DB ' + brokerUuidValue
        );

        insert new Configuration__c(Name = 'ESBURL');
    }
 
    @isTest(SeeAllData=false) static void createOpportunityTest() {
        Broker__c testBroker = [SELECT Id, Name, Source_ID__c, Source_Database__c FROM Broker__c WHERE Name='Mock Broker'];
        
        Entity__c testEntity = new Entity__c();
        testEntity.Name = 'Entity xyz';
        testEntity.Brand__c = 'Test Brand';
        testEntity.Source_ID__c = 'xyz';
        testEntity.Source_Database__c = 'Test Source DB Entity';       
        insert testEntity;

        Market__c testMarket = new Market__c();
        testMarket.Name = 'Test Market';
        testMarket.Commodity__c = 'Electricity';
        testMarket.Region__c = 'US';    
        testMarket.Country__c = 'US';
        testMarket.Source_ID__c = 'Test Source Id Market';
        testMarket.Source_Database__c = 'Test Source DB Market';    
        insert testMarket;

        Profile testProfile = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User testUser = new User(Alias = 'standt', Email='testuser@emex.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = testProfile.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='emextestuser@emex.com',
            Entity_ID__c=testEntity.Id, Entity_Name__c=testEntity.Name);
            
        insert testUser;
                     
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        req.addHeader('httpMethod', 'POST');
        req.requestUri = '/services/apexrest/UploadOpportunityToSF/';

        req.requestBody = Blob.valueof('{ "event": "create_opportunity", ' + 
        ' "account": { "Name": "Sample Account", "Entity__c": "' + testEntity.Id + '", "OwnerId": "' + testUser.Id + '" }, ' + 
        ' "contact": { "LastName": "Test",  "FirstName": "AMY",  "Phone": "5555555555",  "Email": "johndoe@example.com",  "MailingCity": "Houston",  "MailingState": "TX",  "MailingStreet": "123 Main St",  "MailingPostalCode": "77002" }, ' + 
        ' "opportunity": { "Broker__c": "' + testBroker.Id + '", "Entity__c":"' + testEntity.Id + '", ' +
        ' "CloseDate": "2050-02-28",  "StageName": "5 - Closed Won",  "Name": "Test - Opportunity", "OwnerId": "' + testUser.Id + '", ' + 
        ' "Est_Annual_Usage__c": 20.0, "Expected_Contract_Term__c": 10.0, "Expected_Contract_Start__c": "2020-02-28", ' + 
        ' "Expected_Margin__c": 2.0, "Market__c": "' + testMarket.Id + '", "Commodity__c": "Electricity", "Legal_Entity_Name__c": "Test Opportunity Legal" }}');
        RestContext.request = req; 
        RestContext.response = res;
        
        Test.startTest();
        OpportunityCallIn.createOpportunity();
        Test.stopTest();
    } 
}