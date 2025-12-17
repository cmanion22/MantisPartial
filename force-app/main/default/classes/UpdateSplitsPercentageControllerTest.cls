@isTest 
public with sharing class UpdateSplitsPercentageControllerTest {

    /*@testSetup static void setup() {
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

    @isTest public static void createServicesSplits() {
        
        Broker__c testBroker = [SELECT Id, Name, Source_ID__c, Source_Database__c FROM Broker__c WHERE Name='Mock Broker'];

        // Create and insert test Entity
        Entity__c testEntity = new Entity__c();
        testEntity.Name = 'Test Entity';
        testEntity.Brand__c = 'Test Brand';
        testEntity.Source_ID__c = 'Test Source Id Entity';
        testEntity.Source_Database__c = 'Test Source DB Entity';       
        insert testEntity;

        // Create Test Market 
        Market__c testMarket = new Market__c();
        testMarket.Name = 'Test Market';
        testMarket.Commodity__c = 'Electricity';
        testMarket.Region__c = 'US';    
        testMarket.Country__c = 'US';
        testMarket.Source_ID__c = 'Test Source Id Market';
        testMarket.Source_Database__c = 'Test Source DB Market';    
        insert testMarket;

        
        // Create and insert test User
        Profile testProfile = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User testUser1 = new User(
            Alias = 'stand', 
            Email = 'testuser125@emex.com', 
            EmailEncodingKey = 'UTF-8', 
            FirstName = 'Funny',
            LastName = 'Usey',
            LanguageLocaleKey = 'en_US', 
            LocaleSidKey = 'en_US', 
            ProfileId = testProfile.Id, 
            TimeZoneSidKey = 'America/Los_Angeles', 
            UserName = 'emextestuserfunny3223@emex.com',
            Entity_ID__c = testEntity.Id, 
            Entity_Name__c = testEntity.Name, 
            API_Token__c = 'funny32'
        );
        insert testUser1;

        User testUser2 = new User(
            Alias = 'stand', 
            Email = 'testuser125@emex.com', 
            EmailEncodingKey = 'UTF-8', 
            FirstName = 'Funny',
            LastName = 'Usey',
            LanguageLocaleKey = 'en_US', 
            LocaleSidKey = 'en_US', 
            ProfileId = testProfile.Id, 
            TimeZoneSidKey = 'America/Los_Angeles', 
            UserName = 'emextestuserfunny322@emex.com',
            Entity_ID__c = testEntity.Id, 
            Entity_Name__c = testEntity.Name, 
            API_Token__c = 'funny32'
        );
        insert testUser2;
       
        // Create and insert test Account
        Account acc = new Account();
        acc.Name = 'Funny Account32';
        acc.Legal_Entity_Name__c = 'Funny Account32';
        acc.Phone = '111111125';
        acc.Entity__c = testEntity.Id;
        acc.OwnerId = testUser1.Id; 
        acc.BackOfficeId__c = 'UniqueBO54321';
        insert acc;

        Opportunity testOpportunity = new Opportunity();
        testOpportunity.Name = 'Test - Opportunity34';
        testOpportunity.StageName = '1 - Discovery';
        testOpportunity.Broker__c = testBroker.Id;
        testOpportunity.Entity__c = testEntity.Id;
        testOpportunity.AccountId = acc.Id;
        testOpportunity.Commodity__c = 'Electricity';
        testOpportunity.Market__c = testMarket.Id;
        testOpportunity.CloseDate = Date.today(); 
        testOpportunity.Est_Annual_Usage__c = 20;
        testOpportunity.Expected_Contract_Term__c = 10;
        testOpportunity.Expected_Contract_Start__c = Date.today();
        testOpportunity.Expected_Margin__c = 2;
        testOpportunity.Legal_Entity_Name__c = 'Test Opportunity34 Legal';
        testOpportunity.OwnerId = testUser1.Id;
        testOpportunity.Account_Team_Referrer__c = testUser2.Id;
          
        insert testOpportunity;

        
        // Set the mock response class
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        
        // Initialize wrapper class
        UpdateSplitsPercentageWrapper wrapper = new UpdateSplitsPercentageWrapper();
        wrapper.opportunityIds = new List<Id>();
        wrapper.opportunityIds.add(testOpportunity.Id);
        wrapper.recTypeName = 'Services';
        wrapper.accountId = acc.Id;
        wrapper.salesReferrerId = testUser2.Id;
        wrapper.splitTypeId = [SELECT Id FROM OpportunitySplitType WHERE IsActive = true][0].Id;
        wrapper.uponOpportunityCreation = false;

        // Call the method to test
        UpdateSplitsPercentageController.updateSplitsPercentage(new List<UpdateSplitsPercentageWrapper> { wrapper });

        Test.stopTest();
        
    }
    
    @isTest public static void updateEnergySplitsPercentageTest() {
        Broker__c testBroker = [SELECT Id, Name, Source_ID__c, Source_Database__c FROM Broker__c WHERE Name='Mock Broker'];

        // Create and insert test Entity
        Entity__c testEntity = new Entity__c();
        testEntity.Name = 'Test Entity';
        testEntity.Brand__c = 'Test Brand';
        testEntity.Source_ID__c = 'Test Source Id Entity';
        testEntity.Source_Database__c = 'Test Source DB Entity';       
        insert testEntity;

        // Create Test Market 
        Market__c testMarket = new Market__c();
        testMarket.Name = 'Test Market';
        testMarket.Commodity__c = 'Electricity';
        testMarket.Region__c = 'US';    
        testMarket.Country__c = 'US';
        testMarket.Source_ID__c = 'Test Source Id Market';
        testMarket.Source_Database__c = 'Test Source DB Market';    
        insert testMarket;

        
        // Create and insert test User
        Profile testProfile = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User testUser1 = new User(
            Alias = 'stand', 
            Email = 'testuser125@emex.com', 
            EmailEncodingKey = 'UTF-8', 
            FirstName = 'Funny',
            LastName = 'Usey',
            LanguageLocaleKey = 'en_US', 
            LocaleSidKey = 'en_US', 
            ProfileId = testProfile.Id, 
            TimeZoneSidKey = 'America/Los_Angeles', 
            UserName = 'emextestuserfunny3223@emex.com',
            Entity_ID__c = testEntity.Id, 
            Entity_Name__c = testEntity.Name, 
            API_Token__c = 'funny32'
        );
        insert testUser1;

        User testUser2 = new User(
            Alias = 'stand', 
            Email = 'testuser125@emex.com', 
            EmailEncodingKey = 'UTF-8', 
            FirstName = 'Funny',
            LastName = 'Usey',
            LanguageLocaleKey = 'en_US', 
            LocaleSidKey = 'en_US', 
            ProfileId = testProfile.Id, 
            TimeZoneSidKey = 'America/Los_Angeles', 
            UserName = 'emextestuserfunny322@emex.com',
            Entity_ID__c = testEntity.Id, 
            Entity_Name__c = testEntity.Name, 
            API_Token__c = 'funny32'
        );
        insert testUser2;
       
        // Create and insert test Account
        Account acc = new Account();
        acc.Name = 'Funny Account32';
        acc.Legal_Entity_Name__c = 'Funny Account32';
        acc.Phone = '111111125';
        acc.Entity__c = testEntity.Id;
        acc.OwnerId = testUser1.Id; 
        acc.BackOfficeId__c = 'UniqueBO54321';
        acc.Account_Team_Referrer__c = testUser2.Id;
        insert acc;

        Opportunity testOpportunity1 = new Opportunity();
        testOpportunity1.Name = 'Test - Opportunity34';
        testOpportunity1.StageName = '1 - Discovery';
        testOpportunity1.Broker__c = testBroker.Id;
        testOpportunity1.Entity__c = testEntity.Id;
        testOpportunity1.AccountId = acc.Id;
        testOpportunity1.Commodity__c = 'Electricity';
        testOpportunity1.Market__c = testMarket.Id;
        testOpportunity1.CloseDate = Date.today(); 
        testOpportunity1.Est_Annual_Usage__c = 20;
        testOpportunity1.Expected_Contract_Term__c = 10;
        testOpportunity1.Expected_Contract_Start__c = Date.today();
        testOpportunity1.Expected_Margin__c = 2;
        testOpportunity1.Legal_Entity_Name__c = 'Test Opportunity34 Legal';
        testOpportunity1.OwnerId = testUser1.Id;
        testOpportunity1.Account_Team_Referrer__c = testUser2.Id;
          
        insert testOpportunity1;

        Opportunity testOpportunity2 = new Opportunity();
        testOpportunity2.Name = 'Test - Opportunity35';
        testOpportunity2.StageName = '1 - Discovery';
        testOpportunity2.Broker__c = testBroker.Id;
        testOpportunity2.Entity__c = testEntity.Id;
        testOpportunity2.AccountId = acc.Id;
        testOpportunity2.Commodity__c = 'Electricity';
        testOpportunity2.Market__c = testMarket.Id;
        testOpportunity2.CloseDate = Date.today(); 
        testOpportunity2.Est_Annual_Usage__c = 20;
        testOpportunity2.Expected_Contract_Term__c = 10;
        testOpportunity2.Expected_Contract_Start__c = Date.today();
        testOpportunity2.Expected_Margin__c = 2;
        testOpportunity2.Legal_Entity_Name__c = 'Test Opportunity35 Legal';
        testOpportunity2.OwnerId = testUser2.Id;
        testOpportunity2.Account_Team_Referrer__c = testUser2.Id;

        insert testOpportunity2;

        // Set the mock response class
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        
        // Initialize wrapper class
        UpdateSplitsPercentageWrapper wrapper = new UpdateSplitsPercentageWrapper();
        wrapper.opportunityIds = new List<Id>();
        wrapper.opportunityIds.add(testOpportunity1.Id);
        wrapper.opportunityIds.add(testOpportunity2.Id);
        wrapper.recTypeName = 'Energy';
        wrapper.accountId = acc.Id;
        wrapper.salesReferrerId = testUser2.Id;
        wrapper.splitTypeId = [SELECT Id FROM OpportunitySplitType WHERE IsActive = true][0].Id;
        wrapper.uponOpportunityCreation = false;

        // Call the method to test
        UpdateSplitsPercentageController.updateSplitsPercentage(new List<UpdateSplitsPercentageWrapper> { wrapper });

        Test.stopTest();

    }

    @isTest public static void createEnergySplitsUponCreationTest() {
        Broker__c testBroker = [SELECT Id, Name, Source_ID__c, Source_Database__c FROM Broker__c WHERE Name='Mock Broker'];

        // Create and insert test Entity
        Entity__c testEntity = new Entity__c();
        testEntity.Name = 'Test Entity';
        testEntity.Brand__c = 'Test Brand';
        testEntity.Source_ID__c = 'Test Source Id Entity';
        testEntity.Source_Database__c = 'Test Source DB Entity';       
        insert testEntity;

        // Create Test Market 
        Market__c testMarket = new Market__c();
        testMarket.Name = 'Test Market';
        testMarket.Commodity__c = 'Electricity';
        testMarket.Region__c = 'US';    
        testMarket.Country__c = 'US';
        testMarket.Source_ID__c = 'Test Source Id Market';
        testMarket.Source_Database__c = 'Test Source DB Market';    
        insert testMarket;

        
        // Create and insert test User
        Profile testProfile = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User testUser1 = new User(
            Alias = 'stand', 
            Email = 'testuser125@emex.com', 
            EmailEncodingKey = 'UTF-8', 
            FirstName = 'Funny',
            LastName = 'Usey',
            LanguageLocaleKey = 'en_US', 
            LocaleSidKey = 'en_US', 
            ProfileId = testProfile.Id, 
            TimeZoneSidKey = 'America/Los_Angeles', 
            UserName = 'emextestuserfunny3223@emex.com',
            Entity_ID__c = testEntity.Id, 
            Entity_Name__c = testEntity.Name, 
            API_Token__c = 'funny32'
        );
        insert testUser1;

        User testUser2 = new User(
            Alias = 'stand', 
            Email = 'testuser125@emex.com', 
            EmailEncodingKey = 'UTF-8', 
            FirstName = 'Funny',
            LastName = 'Usey',
            LanguageLocaleKey = 'en_US', 
            LocaleSidKey = 'en_US', 
            ProfileId = testProfile.Id, 
            TimeZoneSidKey = 'America/Los_Angeles', 
            UserName = 'emextestuserfunny322@emex.com',
            Entity_ID__c = testEntity.Id, 
            Entity_Name__c = testEntity.Name, 
            API_Token__c = 'funny32'
        );
        insert testUser2;
       
        // Create and insert test Account
        Account acc = new Account();
        acc.Name = 'Funny Account32';
        acc.Legal_Entity_Name__c = 'Funny Account32';
        acc.Phone = '111111125';
        acc.Entity__c = testEntity.Id;
        acc.OwnerId = testUser1.Id; 
        acc.BackOfficeId__c = 'UniqueBO54321';
        acc.Account_Team_Referrer__c = testUser2.Id;
        insert acc;

        Opportunity testOpportunity1 = new Opportunity();
        testOpportunity1.Name = 'Test - Opportunity34';
        testOpportunity1.StageName = '1 - Discovery';
        testOpportunity1.Broker__c = testBroker.Id;
        testOpportunity1.Entity__c = testEntity.Id;
        testOpportunity1.AccountId = acc.Id;
        testOpportunity1.Commodity__c = 'Electricity';
        testOpportunity1.Market__c = testMarket.Id;
        testOpportunity1.CloseDate = Date.today(); 
        testOpportunity1.Est_Annual_Usage__c = 20;
        testOpportunity1.Expected_Contract_Term__c = 10;
        testOpportunity1.Expected_Contract_Start__c = Date.today();
        testOpportunity1.Expected_Margin__c = 2;
        testOpportunity1.Legal_Entity_Name__c = 'Test Opportunity34 Legal';
        testOpportunity1.OwnerId = testUser1.Id;
        testOpportunity1.Account_Team_Referrer__c = testUser2.Id;
          
        insert testOpportunity1;

        // Set the mock response class
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        
        // Initialize wrapper class
        UpdateSplitsPercentageWrapper wrapper = new UpdateSplitsPercentageWrapper();
        wrapper.opportunityIds = new List<Id>();
        wrapper.opportunityIds.add(testOpportunity1.Id);
        wrapper.recTypeName = 'Energy';
        wrapper.accountId = acc.Id;
        wrapper.salesReferrerId = testUser2.Id;
        wrapper.splitTypeId = [SELECT Id FROM OpportunitySplitType WHERE IsActive = true][0].Id;
        wrapper.uponOpportunityCreation = true;

        // Call the method to test
        UpdateSplitsPercentageController.updateSplitsPercentage(new List<UpdateSplitsPercentageWrapper> { wrapper });

        Test.stopTest();

    }*/

}