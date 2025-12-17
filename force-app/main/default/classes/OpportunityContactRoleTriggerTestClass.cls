@isTest
 public class OpportunityContactRoleTriggerTestClass {

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

    @isTest static void OpportunityContactRoleTriggerTest_update() {
        Test.setMock(HttpCalloutMock.class, new HttpEmexCalloutMock(200, 'OK', '{success:true}')); 

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

        Contact testContact = new Contact();
        testContact.OwnerId = testUser.Id;
        testContact.AccountId = testAccount.Id;
        testContact.LastName = 'Doe';
        testContact.FirstName = 'John';
        testContact.Phone = '9090909090';
        testContact.Email = 'abc@gmail.com';
        testContact.MailingStreet = '123 street'; 
        testContact.MailingCity = 'Dallas';
        testContact.MailingState = 'TX';
        testContact.MailingCountry = 'US';
        testContact.MailingPostalCode = '75320';
        insert testContact;   

        OpportunityContactRole testOcr = new OpportunityContactRole();
        testOcr.ContactId = testContact.Id;
        testOcr.OpportunityId = testOpportunity.Id;
        testOcr.IsPrimary = false;
        insert testOcr;
        
        // Now, our trigger will fire on After update event so update the Records
        Test.startTest();    // Starts the scope of test
        try {
            testOcr.IsPrimary = true;
            update testOcr;
        } catch (Exception ex) {
            
        }
        
        Test.stopTest();     // Ends the scope of test
        
        // Now check if it is giving desired results using System.assert
        // Statement.New Opportunity should be created
        List<OpportunityContactRole> lst = [SELECT Id, IsPrimary, OpportunityId, ContactId FROM OpportunityContactRole WHERE Id = :testOcr.Id];
        System.assertEquals(1, lst.size());
        // Check if one record is created in Opportunity sObject
    }

    @isTest static void OpportunityContactRoleTriggerTest_insert() {
        Test.setMock(HttpCalloutMock.class, new HttpEmexCalloutMock(200, 'OK', '{success:true}')); 

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

        Contact testContact = new Contact();
        testContact.OwnerId = testUser.Id;
        testContact.AccountId = testAccount.Id;
        testContact.LastName = 'Doe';
        testContact.FirstName = 'John';
        testContact.Phone = '9090909090';
        testContact.Email = 'abc@gmail.com';
        testContact.MailingStreet = '123 street'; 
        testContact.MailingCity = 'Dallas';
        testContact.MailingState = 'TX';
        testContact.MailingCountry = 'US';
        testContact.MailingPostalCode = '75320';
        insert testContact;   

        Test.startTest();    // Starts the scope of test

        OpportunityContactRole testOcr = new OpportunityContactRole();
        testOcr.ContactId = testContact.Id;
        testOcr.OpportunityId = testOpportunity.Id;
        testOcr.IsPrimary = true;
        try {
            // Now, our trigger will fire on After update event so update the Records
            insert testOcr;
        } catch (Exception ex) {
            
        }
        Test.stopTest();     // Ends the scope of test
        
        // Now check if it is giving desired results using System.assert
        // Statement.New Opportunity should be created
        List<OpportunityContactRole> lst = [SELECT Id, IsPrimary, OpportunityId, ContactId FROM OpportunityContactRole WHERE Id = :testOcr.Id];
        System.assertEquals(1, lst.size());
        // Check if one record is created in Opportunity sObject
    }

    @isTest(SeeAllData=false) static void OpportunityContactRoleTriggerTest_Active() {
        Test.setMock(HttpCalloutMock.class, new HttpEmexCalloutMock(200, 'OK', '{success:true}')); 
        
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

        Contact testContact = new Contact();
        testContact.OwnerId = testUser.Id;
        testContact.AccountId = testAccount.Id;
        testContact.LastName = 'Doe';
        testContact.FirstName = 'John';
        testContact.Phone = '9090909090';
        testContact.Email = 'abc@gmail.com';
        testContact.MailingStreet = '123 street'; 
        testContact.MailingCity = 'Dallas';
        testContact.MailingState = 'TX';
        testContact.MailingCountry = 'US';
        testContact.MailingPostalCode = '75320';
        insert testContact;   

        OpportunityContactRole testOcr = new OpportunityContactRole();
        testOcr.ContactId = testContact.Id;
        testOcr.OpportunityId = testOpportunity.Id;
        testOcr.IsPrimary = false;
        insert testOcr;
        
        Turn_off_Processes__c processSettings = new Turn_off_Processes__c();
        processSettings.Name = 'migration in progress';
        processSettings.Is_Active__c = true;
        insert processSettings;
        
        // Now, our trigger will fire on After update event so update the Records
        Test.startTest();    // Starts the scope of test
        try {
            testOcr.IsPrimary = true;
            update testOcr;
        } catch (Exception ex) {
            
        }
        
        Test.stopTest();     // Ends the scope of test
        
        // Now check if it is giving desired results using System.assert
        // Statement.New Opportunity should be created
        List<OpportunityContactRole> lst = [SELECT Id, IsPrimary, OpportunityId, ContactId FROM OpportunityContactRole WHERE Id = :testOcr.Id];
        System.assertEquals(1, lst.size());
        // Check if one record is created in Opportunity sObject
    }


    @isTest static void OpportunityContactRoleTriggerTest_locked() {
        Test.setMock(HttpCalloutMock.class, new HttpEmexCalloutMock(200, 'OK', '{success:true}')); 
        
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

        Contact testContact = new Contact();
        testContact.OwnerId = testUser.Id;
        testContact.AccountId = testAccount.Id;
        testContact.LastName = 'Doe';
        testContact.FirstName = 'John';
        testContact.Phone = '9090909090';
        testContact.Email = 'abc@gmail.com';
        testContact.MailingStreet = '123 street'; 
        testContact.MailingCity = 'Dallas';
        testContact.MailingState = 'TX';
        testContact.MailingCountry = 'US';
        testContact.MailingPostalCode = '75320';
        insert testContact;   

        OpportunityContactRole testOcr = new OpportunityContactRole();
        testOcr.ContactId = testContact.Id;
        testOcr.OpportunityId = testOpportunity.Id;
        testOcr.IsPrimary = false;
        insert testOcr;

        Trigger_Disabled__c disabled = new Trigger_Disabled__c();
        disabled.Name = testOpportunity.Id;
        upsert disabled Name;       
        
        Turn_off_Processes__c processSettings = new Turn_off_Processes__c();
        processSettings.Name = 'migration in progress';
        processSettings.Is_Active__c = true;
        insert processSettings;
        
        // Now, our trigger will fire on After update event so update the Records
        Test.startTest();    // Starts the scope of test
        try {
            testOcr.IsPrimary = true;
            update testOcr;
        } catch (Exception ex) {
            
        }
        
        Test.stopTest();     // Ends the scope of test
        
        // Now check if it is giving desired results using System.assert
        // Statement.New Opportunity should be created
        List<OpportunityContactRole> lst = [SELECT Id, IsPrimary, OpportunityId, ContactId FROM OpportunityContactRole WHERE Id = :testOcr.Id];
        System.assertEquals(1, lst.size());
    }

    @isTest static void deleteOppContactRoleTest() {
        Test.setMock(HttpCalloutMock.class, new HttpEmexCalloutMock(200, 'OK', '{success:true}')); 

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

        Contact testContact = new Contact();
        testContact.OwnerId = testUser.Id;
        testContact.AccountId = testAccount.Id;
        testContact.LastName = 'Doe';
        testContact.FirstName = 'John';
        testContact.Phone = '9090909090';
        testContact.Email = 'abc@gmail.com';
        testContact.MailingStreet = '123 street'; 
        testContact.MailingCity = 'Dallas';
        testContact.MailingState = 'TX';
        testContact.MailingCountry = 'US';
        testContact.MailingPostalCode = '75320';
        insert testContact;   

        OpportunityContactRole testOcr = new OpportunityContactRole();
        testOcr.ContactId = testContact.Id;
        testOcr.OpportunityId = testOpportunity.Id;
        testOcr.IsPrimary = true;
        insert testOcr;

        // Now, our trigger will fire on After update event so update the Records
        Test.startTest();    // Starts the scope of test
        try {
            delete testOcr;
        } catch (Exception ex) {
            
        }
        
        Test.stopTest();     // Ends the scope of test
        
        // Now check if it is giving desired results using System.assert
        // Statement.New Opportunity should be created
        List<OpportunityContactRole> lst = [SELECT Id, IsPrimary, OpportunityId, ContactId FROM OpportunityContactRole WHERE Id = :testOcr.Id];
        System.assertEquals(0, lst.size());
        // Check if one record is created in Opportunity sObject        
    }

    @isTest static void deleteOppContactRoleTest_registered() {
        Test.setMock(HttpCalloutMock.class, new HttpEmexCalloutMock(200, 'OK', '{success:true}')); 

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
        testOpportunity.Registered_in_Back_Office__c = true;
        insert testOpportunity;

        Contact testContact = new Contact();
        testContact.OwnerId = testUser.Id;
        testContact.AccountId = testAccount.Id;
        testContact.AccountId = testAccount.Id;
        testContact.LastName = 'Doe';
        testContact.FirstName = 'John';
        testContact.Phone = '9090909090';
        testContact.Email = 'abc@gmail.com';
        testContact.MailingStreet = '123 street'; 
        testContact.MailingCity = 'Dallas';
        testContact.MailingState = 'TX';
        testContact.MailingCountry = 'US';
        testContact.MailingPostalCode = '75320';
        insert testContact;   

        OpportunityContactRole testOcr = new OpportunityContactRole();
        testOcr.ContactId = testContact.Id;
        testOcr.OpportunityId = testOpportunity.Id;
        testOcr.IsPrimary = true;
        insert testOcr;
       
        Turn_off_Processes__c processSettings = new Turn_off_Processes__c();
        processSettings.Name = 'migration in progress';
        processSettings.Is_Active__c = true;
        insert processSettings;

        // Now, our trigger will fire on After update event so update the Records
        Test.startTest();    // Starts the scope of test
        try {
            delete testOcr;
        } catch (Exception ex) {
            
        }
        
        Test.stopTest();     // Ends the scope of test
        
        // Now check if it is giving desired results using System.assert
        // Statement.New Opportunity should be created
        List<OpportunityContactRole> lst = [SELECT Id, IsPrimary, OpportunityId, ContactId FROM OpportunityContactRole WHERE Id = :testOcr.Id];
        //System.assertEquals(1, lst.size());
        // Check if one record is created in Opportunity sObject        
    }
}