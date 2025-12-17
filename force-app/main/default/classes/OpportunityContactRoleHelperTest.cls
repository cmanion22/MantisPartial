@isTest
public class OpportunityContactRoleHelperTest {

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

    @isTest(SeeAllData=false) static void upsertOpportunityContactRoleTest() 
    {  
        Test.startTest();
       
        Broker__c testBroker = [SELECT Id, Name, Source_ID__c, Source_Database__c FROM Broker__c WHERE Name='Mock Broker'];
        
        Entity__c testEntity = new Entity__c();
        testEntity.Name = 'Test Entity';
        testEntity.Brand__c = 'Test Brand';
        testEntity.Source_ID__c = 'Test Source Id Entity';
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
         
        Opportunity testOpportunity = new Opportunity();
        testOpportunity.AccountId = testAccount.Id;
        testOpportunity.Name = 'Test - Opportunity';
        testOpportunity.StageName = '5 - Closed Won';
        testOpportunity.Broker__c = testBroker.Id;
        testOpportunity.Entity__c = testEntity.Id;
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

        Savepoint sp = Database.setSavepoint();

        Test.setMock(HttpCalloutMock.class, new HttpEmexCalloutMock(200, 'OK', '{success:true}'));
        OpportunityContactRole testOpportunityContactRole = OpportunityContactRoleHelper.upsertOpportunityContactRole(testOpportunity.Id, testContact.Id);
        List<OpportunityContactRole> lst = [SELECT Id, OpportunityId FROM OpportunityContactRole WHERE Id = :testOpportunityContactRole.Id];
        Database.rollback(sp);
        Test.stopTest();

        System.assertEquals(1, lst.size());     
    }
}