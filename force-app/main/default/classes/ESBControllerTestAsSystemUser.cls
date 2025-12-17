@isTest
public class ESBControllerTestAsSystemUser {

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

    /* @isTest static void getESBUrlTest() {
        User useMe=[SELECT id from User WHERE name = 'B2BMA Integration' LIMIT 1];
        System.runas(useMe){
        string esbUrl = ESBController.getESBUrl();

        Configuration__c config = Configuration__c.getValues('ESBURL');
        //System.debug('ESBController -->getESBUrl-->ESBUrlconfig.ESBBaseURL__c-->' + config.ESBBaseURL__c);

            string currentUserApiToken = UserInfo.getUserName().tolowercase().indexof(UserInfo.getOrganizationId().toLowerCase())!= -1?
            [Select API_Token__c from User where name = 'Mantis Back Office'].API_Token__c:
            [Select API_Token__c from User where Id = :UserInfo.getUserId()].API_Token__c;
            
        string expectedUrl = config.ESBBaseURL__c + '/salesforce/esb' +  '?api_token=' + currentUserApiToken;

        System.debug('ESBController -->getESBUrl-->ESBUrlconfig.ESBURL-->' + esbUrl);
        System.debug('TestClass -->CurrentUser-->ExpectedURL-->' + expectedUrl);
        System.assertEquals(esbUrl, expectedUrl);
        }
    } */
    
    @isTest(SeeAllData=false) static void getOpportunityESBUrlTest() {
        Broker__c testBroker = [SELECT Id, Name, Source_ID__c, Source_Database__c FROM Broker__c WHERE Name='Mock Broker'];
        
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
        testContact.Email='test@testURL.com';
        testContact.Tax_id__c='0';
        testContact.MailingStreet='123 St';
        testContact.MailingCity='city';
        testContact.MailingState='TX';
        testContact.MailingPostalCode='00000';
        insert testContact;
        
        Market__c testMarket = new Market__c();
        testMarket.Name = 'Test Market';
        testMarket.Commodity__c = 'Electricity';
        testMarket.Region__c = 'US';
        testMarket.Country__c = 'US';
        testMarket.Source_ID__c = 'Test Source Id Market';
        testMarket.Source_Database__c = 'Test Source DB Market';
        insert testMarket;
        
        Opportunity testOpportunity = new Opportunity();
        testOpportunity.Name = 'Test - Opportunity';
        testOpportunity.StageName = '5 - Closed Won';
        testOpportunity.Broker__c = testBroker.Id;
        testOpportunity.Entity__c = testEntity.Id;
        testOpportunity.AccountId = testAccount.Id;
        testOpportunity.ContactId = testContact.Id;
        testOpportunity.Commodity__c = 'Electricity';
        testOpportunity.Market__c = testMarket.Id;
        testOpportunity.CloseDate = Date.today(); 
        testOpportunity.Est_Annual_Usage__c = 20;
        testOpportunity.Expected_Contract_Term__c = 10;
        testOpportunity.Expected_Contract_Start__c = Date.today();
        testOpportunity.Expected_Margin__c = 2;
        testOpportunity.Legal_Entity_Name__c = 'Test Opportunity Legal';
        testOpportunity.OwnerId = testUser.Id;
        insert testOpportunity;

        string opportunityESBUrl = ESBController.getOpportunityESBUrl(testOpportunity.Id);

        Configuration__c config = Configuration__c.getValues('ESBURL');
        System.debug('ESBController -->getESBUrl-->ESBUrlconfig.ESBBaseURL__c-->' + config.ESBBaseURL__c);

        string currentUserApiToken = [Select API_Token__c from User where Id = :UserInfo.getUserId()].API_Token__c;
        string expectedUrl = config.ESBBaseURL__c + '/salesforce/deals/' + testOpportunity.Id + '?api_token=' + currentUserApiToken;
        
        System.assertEquals(opportunityESBUrl, expectedUrl); 
    }
}