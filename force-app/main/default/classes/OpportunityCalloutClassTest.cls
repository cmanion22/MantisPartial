@isTest
public class OpportunityCalloutClassTest { 

    @testSetup static void setup() {
        Uuid brokerUuid = new Uuid();
        String brokerUuidValue = brokerUuid.getValue();
        insert new Broker__c(
            Name = 'Mock Broker',
            Source_ID__c = 'Source Id ' + brokerUuidValue,
            Source_Database__c = 'Source DB ' + brokerUuidValue
        );

        insert new Configuration__c(Name = 'ESBURL');
        insert new Back_Office_Integration_Settings__c(Name = 'Staging', Endpoint_URL__c = 'https://www.example.com');
        insert new Back_Office_Integration_Settings__c(Name = 'Production', Endpoint_URL__c = 'https://www.example.com');
    }

    @isTest(SeeAllData=false) public static void createOpportunityTest() 
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

        Profile testProfile = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
        //User testUser = [SELECT Id FROM USER WHERE IsActive = true and ProfileId =: testProfile.Id LIMIT 1];
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
        
        List<ID> ids = new List<ID>();                
        ids.add(testOpportunity.Id);
        Savepoint sp = Database.setSavepoint();

        Test.setMock(HttpCalloutMock.class, new HttpEmexCalloutMock(200, 'OK', '{success:true}'));   
        //Temporary Comment. Uncommenting below line throws : System.CalloutException: You have uncommitted work pending. Please commit or rollback before calling out     
        OpportunityCalloutClass.createOpportunity(ids); 
        
        Database.rollback(sp);
        Test.stopTest();    
    }

    /*@isTest(SeeAllData=true) public static void createOpportunityTest2() 
    { 
        Test.startTest();
               
        Opportunity testOpportunity = [SELECT ID FROM Opportunity WHERE Broker__c != null
                        and Entity__c != null and AccountId != null and ContactId != null  and 
                        Market__c != null and OwnerId != null LIMIT 1];
         
        List<ID> ids = new List<ID>();                
        ids.add(testOpportunity.Id);

        Test.setMock(HttpCalloutMock.class, new HttpEmexCalloutMock(200, 'OK', '{success:true}'));   
        OpportunityCalloutClass.createOpportunity(ids); 
        
        Test.stopTest();    
    }

    @isTest(SeeAllData=true) public static void createOpportunityTest2_Fail() 
    { 
        Test.startTest();
               
        Opportunity testOpportunity = [SELECT ID FROM Opportunity WHERE Broker__c != null
                        and Entity__c != null and AccountId != null and ContactId != null  and 
                        Market__c != null and OwnerId != null LIMIT 1];
         
        List<ID> ids = new List<ID>();                
        ids.add(testOpportunity.Id);

        Test.setMock(HttpCalloutMock.class, new HttpEmexCalloutMock(404, 'Not Found', '{"error":"Does not exist"}'));   
        OpportunityCalloutClass.createOpportunity(ids); 
        
        Test.stopTest();    
    }*/
    
    @isTest(SeeAllData=false) public static void updateOpportunityTest() 
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
            Entity_ID__c=testEntity.Id, Entity_Name__c=testEntity.Name, API_Token__c = 'test');
            
        insert testUser;
         
        Opportunity testOpportunity = new Opportunity();
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
        String json  = OpportunityCalloutClass.updateOpportunity(testOpportunity.Id, testUser.Id);
        Database.rollback(sp);
        Test.stopTest();
        System.assertNotEquals(null, json);
    }   
}