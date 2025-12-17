@isTest
public class OpportunityTriggerTestClass {

    @testSetup static void setup() {
        Uuid brokerUuid = new Uuid();
        String brokerUuidValue = brokerUuid.getValue();
        insert new Broker__c(
            Name = 'Mock Broker',
            Source_ID__c = 'Source Id ' + brokerUuidValue,
            Source_Database__c = 'Source DB ' + brokerUuidValue
        );

        insert new Configuration__c(Name = 'ESBURL');
        insert new Turn_off_Processes__c(Name = 'migration in progress', Is_Active__c = true);
    }

    @isTest static void OpportunityTriggerTest() {
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
        
        // Now, our trigger will fire on After update event so update the Records
        Test.startTest();    // Starts the scope of test
        testOpportunity.Legal_Entity_Name__c = 'Test';
        update testOpportunity;
        Test.stopTest();     // Ends the scope of test
        
        // Now check if it is giving desired results using System.assert
        // Statement.New Opportunity should be created
        List<Opportunity> lst = [SELECT Id, Name, StageName, Broker__c, CloseDate FROM Opportunity WHERE Id = :testOpportunity.Id];
        System.assertEquals(1, lst.size());
        // Check if one record is created in Opportunity sObject
    }

    @isTest static void OpportunityTriggerTest_Active() {
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
        
        Turn_off_Processes__c processSettings = new Turn_off_Processes__c();
        processSettings.Name = 'migration in progress';
        processSettings.Is_Active__c = true;
        insert processSettings;

        // Now, our trigger will fire on After update event so update the Records
        Test.startTest();    // Starts the scope of test
        testOpportunity.Legal_Entity_Name__c = 'Test';
        update testOpportunity;
        Test.stopTest();     // Ends the scope of test
        
        // Now check if it is giving desired results using System.assert
        // Statement.New Opportunity should be created
        List<Opportunity> lst = [SELECT Id, Name, StageName, Broker__c, CloseDate FROM Opportunity WHERE Id = :testOpportunity.Id];
        System.assertEquals(1, lst.size());
        // Check if one record is created in Opportunity sObject
    }


    @isTest static void OpportunityTriggerTest_locked() {
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

        Trigger_Disabled__c disabled = new Trigger_Disabled__c();
        disabled.Name = testOpportunity.Id;
        upsert disabled Name;
        
        Turn_off_Processes__c processSettings = new Turn_off_Processes__c();
        processSettings.Name = 'migration in progress';
        processSettings.Is_Active__c = true;
        insert processSettings;

        // Now, our trigger will fire on After update event so update the Records
        Test.startTest();    // Starts the scope of test
        testOpportunity.Legal_Entity_Name__c = 'Test';
        update testOpportunity;
        Test.stopTest();     // Ends the scope of test
        
        // Now check if it is giving desired results using System.assert
        // Statement.New Opportunity should be created
        List<Opportunity> lst = [SELECT Id, Name, StageName, Broker__c, CloseDate FROM Opportunity WHERE Id = :testOpportunity.Id];
        System.assertEquals(1, lst.size());
        // Check if one record is created in Opportunity sObject
    }
    
   
  @isTest static void testAfterUpdate_EnergyOpportunity() {
    // Setup: Create necessary test data
    Broker__c testBroker = [SELECT Id FROM Broker__c WHERE Name = 'Mock Broker' LIMIT 1];
    
    // Create Opportunity that is not an Energy opportunity
    Opportunity testOpportunity = new Opportunity(
        Name = 'Test - Opportunity',
        StageName = '5 - Closed Won',
        Broker__c = testBroker.Id,
        CloseDate = Date.today(),
        Est_Annual_Usage__c = 20,
        Expected_Contract_Term__c = 10,
        Expected_Contract_Start__c = Date.today(),
        Expected_Margin__c = 2,
        Legal_Entity_Name__c = 'Test Opportunity Legal',
        RecordTypeId = [SELECT Id FROM RecordType WHERE Name = 'Energy' AND SobjectType = 'Opportunity'].Id,
        Registered_in_Back_Office__c = true
    );
    insert testOpportunity;
      
    Account acc = new Account();
      acc.Name     = 'Testing123';
      acc.Industry = 'Education';
      insert acc;
      
    Contact contact = new Contact();
      contact.FirstName  = 'Test';
      contact.LastName   =  'Test';
      contact.LeadSource = 'BD';
      contact.AccountId  = acc.Id;
      contact.Email = 'lol123@gmail.com';
      contact.Phone = '7777777777';
      contact.MailingStreet = '123 yellow';
      contact.MailingCity = 'Delray Beach';
      contact.MailingPostalCode = '33445';
      contact.MailingCountry = 'US';
      insert contact;
      
      
    OpportunityContactRole ocr = new OpportunityContactRole();
      ocr.ContactId = contact.Id;
      ocr.OpportunityId = testOpportunity.Id;
      ocr.IsPrimary = true;
      ocr.Role = 'Decision Maker';
      insert ocr;
      

    // Test Execution: Trigger the update event on the Opportunity
    Test.startTest();
    testOpportunity.Legal_Entity_Name__c = 'Updated Legal Entity Name';
    update testOpportunity;
    Test.stopTest();

    // Assertions: Verify the expected behavior
    // 1. Verify that no errors are added to the Opportunity
    Opportunity updatedOpportunity = [SELECT Id, Legal_Entity_Name__c FROM Opportunity WHERE Id = :testOpportunity.Id];
    System.assertEquals('Updated Legal Entity Name', updatedOpportunity.Legal_Entity_Name__c, 'Legal Entity Name should be updated');

    
    
	}
    
    @isTest static void testAfterUpdate_NoEnergyOpportunity() {
    // Setup: Create necessary test data
    Broker__c testBroker = [SELECT Id FROM Broker__c WHERE Name = 'Mock Broker' LIMIT 1];
    
    // Create Opportunity that is not an Energy opportunity
    Opportunity testOpportunity = new Opportunity(
        Name = 'Test - Opportunity',
        StageName = '5 - Closed Won',
        Broker__c = testBroker.Id,
        CloseDate = Date.today(),
        Est_Annual_Usage__c = 20,
        Expected_Contract_Term__c = 10,
        Expected_Contract_Start__c = Date.today(),
        Expected_Margin__c = 2,
        Legal_Entity_Name__c = 'Test Opportunity Legal',
        RecordTypeId = [SELECT Id FROM RecordType WHERE Name = 'Services' AND SobjectType = 'Opportunity'].Id
    );
    insert testOpportunity;
      
    Account acc = new Account();
      acc.Name     = 'Testing123';
      acc.Industry = 'Education';
      insert acc;
      
    Contact contact = new Contact();
      contact.FirstName  = 'Test';
      contact.LastName   =  'Test';
      contact.LeadSource = 'BD';
      contact.AccountId  = acc.Id;
      contact.Email = 'lol123@gmail.com';
      contact.Phone = '7777777777';
      contact.MailingStreet = '123 yellow';
      contact.MailingCity = 'Delray Beach';
      contact.MailingPostalCode = '33445';
      contact.MailingCountry = 'US';
      insert contact;
      
      
    OpportunityContactRole ocr = new OpportunityContactRole();
      ocr.ContactId = contact.Id;
      ocr.OpportunityId = testOpportunity.Id;
      ocr.IsPrimary = true;
      ocr.Role = 'Decision Maker';
      insert ocr;
      

    // Test Execution: Trigger the update event on the Opportunity
    Test.startTest();
    testOpportunity.Legal_Entity_Name__c = 'Updated Legal Entity Name';
    update testOpportunity;
    Test.stopTest();

    // Assertions: Verify the expected behavior
    // 1. Verify that no errors are added to the Opportunity
    Opportunity updatedOpportunity = [SELECT Id, Legal_Entity_Name__c FROM Opportunity WHERE Id = :testOpportunity.Id];
    System.assertEquals('Updated Legal Entity Name', updatedOpportunity.Legal_Entity_Name__c, 'Legal Entity Name should be updated');

    
    
	}
    
    @isTest static void testAfterUpdate_NoPrimaryContact() {
    // Setup: Create necessary test data
    Broker__c testBroker = [SELECT Id FROM Broker__c WHERE Name = 'Mock Broker' LIMIT 1];
    
    // Create Opportunity that is not an Energy opportunity
    Opportunity testOpportunity = new Opportunity(
        Name = 'Test - Opportunity',
        StageName = '5 - Closed Won',
        Broker__c = testBroker.Id,
        CloseDate = Date.today(),
        Est_Annual_Usage__c = 20,
        Expected_Contract_Term__c = 10,
        Expected_Contract_Start__c = Date.today(),
        Expected_Margin__c = 2,
        Legal_Entity_Name__c = 'Test Opportunity Legal',
        RecordTypeId = [SELECT Id FROM RecordType WHERE Name = 'Services' AND SobjectType = 'Opportunity'].Id
    );
    insert testOpportunity;
      
    Account acc = new Account();
      acc.Name     = 'Testing123';
      acc.Industry = 'Education';
      insert acc;
      
    Contact contact = new Contact();
      contact.FirstName  = 'Test';
      contact.LastName   =  'Test';
      contact.LeadSource = 'BD';
      contact.AccountId  = acc.Id;
      contact.Email = 'lol123@gmail.com';
      contact.Phone = '7777777777';
      contact.MailingStreet = '123 yellow';
      contact.MailingCity = 'Delray Beach';
      contact.MailingPostalCode = '33445';
      contact.MailingCountry = 'US';
      insert contact;
     
      

    // Test Execution: Trigger the update event on the Opportunity
    Test.startTest();
    testOpportunity.Legal_Entity_Name__c = 'Updated Legal Entity Name';
    update testOpportunity;
    Test.stopTest();

    // Assertions: Verify the expected behavior
    // 1. Verify that no errors are added to the Opportunity
    Opportunity updatedOpportunity = [SELECT Id, Legal_Entity_Name__c FROM Opportunity WHERE Id = :testOpportunity.Id];
    System.assertEquals('Updated Legal Entity Name', updatedOpportunity.Legal_Entity_Name__c, 'Legal Entity Name should be updated');
    
	}
	
}