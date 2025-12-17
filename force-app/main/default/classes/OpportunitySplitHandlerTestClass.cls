@isTest
public class OpportunitySplitHandlerTestClass {

    // Test for Insert Operation
    @isTest
    static void testHandleSplitsOperation_Insert() {
        // Step 1: Create test data
        Uuid brokerUuid = new Uuid();
        String brokerUuidValue = brokerUuid.getValue();
        Broker__c testBroker = new Broker__c();
        testBroker.Name = 'Test Broker';
        testBroker.Source_ID__c = 'Source Id ' + brokerUuidValue;
        testBroker.Source_Database__c = 'Source DB ' + brokerUuidValue;
        insert testBroker;

        Market__c testMarket = new Market__c();
        testMarket.Name = 'Test Market';
        testMarket.Commodity__c = 'Electricity';
        testMarket.Region__c = 'US';    
        testMarket.Country__c = 'US';
        testMarket.Source_ID__c = 'Test Source Id Market';
        testMarket.Source_Database__c = 'Test Source DB Market';    
        insert testMarket;

        insert new Configuration__c(Name = 'ESBURL');
        insert new Back_Office_Integration_Settings__c(Name = 'Staging', Endpoint_URL__c = 'https://www.example.com');
        insert new Back_Office_Integration_Settings__c(Name = 'Production', Endpoint_URL__c = 'https://www.example.com');

        Entity__c testEntity = new Entity__c();
        testEntity.Name = 'Funny2 Entity';
        testEntity.Brand__c = 'Funny2 Brand';
        testEntity.Source_ID__c = null;
        testEntity.Source_Database__c = null;      
        insert testEntity;

        Profile testProfile = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User testUser = new User(
            Alias = 'stand', 
            Email = 'testuser125@emex.com', 
            EmailEncodingKey = 'UTF-8', 
            FirstName = 'Funny',
            LastName = 'Usey',
            LanguageLocaleKey = 'en_US', 
            LocaleSidKey = 'en_US', 
            ProfileId = testProfile.Id, 
            TimeZoneSidKey = 'America/Los_Angeles', 
            UserName = 'emextestuserfunny2@emex.com',
            Entity_ID__c = testEntity.Id, 
            Entity_Name__c = testEntity.Name, 
            API_Token__c = 'funny'
        );
        insert testUser;

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
            UserName = 'emextestuserfunny0@emex.com',
            Entity_ID__c = testEntity.Id, 
            Entity_Name__c = testEntity.Name, 
            API_Token__c = 'funny2'
        );
        insert testUser2;

        Account acc = new Account();
        acc.Name = 'Funny Account';
        acc.Legal_Entity_Name__c = 'Sample Account';
        acc.Phone = '111111128';
        acc.Entity__c = testEntity.Id;
        acc.OwnerId = testUser.Id; 
        acc.BackOfficeId__c = 'UniqueBO12345';
        insert acc;

        Opportunity opp = new Opportunity();
        opp.Name = 'Funny Account - 12121';
        opp.AccountId = acc.Id;
        opp.Type = 'New Business';
        opp.NextStep = 'step';
        opp.Description = 'description';
        opp.CloseDate = Date.today();
        opp.StageName = '1 - Discovery';
        opp.Green_Energy__c = '0%';
        opp.Primary_Client_KPI__c = 'Other';
        opp.LeadSource = 'BD';
        opp.Broker__c = testBroker.Id;
        opp.Commodity__c = 'Electricity';
        opp.Market__c = testMarket.Id;
        opp.OwnerId = testUser.Id;
        opp.Expected_Contract_Start__c = Date.today();
        opp.Registered_in_Back_Office__c = true;
        insert opp;

        OpportunityTeamMember oppTeamMember = new OpportunityTeamMember();
        oppTeamMember.OpportunityId = opp.Id;
        oppTeamMember.TeamMemberRole = 'Opportunity Owner';
        oppTeamMember.UserId = testUser2.Id;
        oppTeamMember.OpportunityAccessLevel = 'Read';
        insert oppTeamMember;

        Opportunity_Split__c oppSplit = new Opportunity_Split__c();
        oppSplit.Opportunity__c = opp.Id;
        oppSplit.OwnerId = testUser2.Id;
        oppSplit.Split_Percentage__c = 0.0;
        insert oppSplit;

        // Set the mock response class
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Prepare wrapper for 'insert' operation
        OpportunitySplitsHandlerWrapper wrapper = new OpportunitySplitsHandlerWrapper();
        wrapper.opportunitySplitIds = new List<Id>{oppSplit.Id};
        wrapper.operation = 'insert';

        // Invoke the handler (which might enqueue a queueable job)
        Test.startTest();
        OpportunitySplitHandler.handleSplitsOperation(new List<OpportunitySplitsHandlerWrapper>{wrapper});
        Test.stopTest();
    }

    // Test for Update Operation
    @isTest
    static void testHandleSplitsOperation_Update() {
        // Step 1: Create test data
        Uuid brokerUuid = new Uuid();
        String brokerUuidValue = brokerUuid.getValue();
        Broker__c testBroker = new Broker__c();
        testBroker.Name = 'Test Broker';
        testBroker.Source_ID__c = 'Source Id ' + brokerUuidValue;
        testBroker.Source_Database__c = 'Source DB ' + brokerUuidValue;
        insert testBroker;

        Market__c testMarket = new Market__c();
        testMarket.Name = 'Test Market';
        testMarket.Commodity__c = 'Electricity';
        testMarket.Region__c = 'US';    
        testMarket.Country__c = 'US';
        testMarket.Source_ID__c = 'Test Source Id Market';
        testMarket.Source_Database__c = 'Test Source DB Market';    
        insert testMarket;

        insert new Configuration__c(Name = 'ESBURL');
        insert new Back_Office_Integration_Settings__c(Name = 'Staging', Endpoint_URL__c = 'https://www.example.com');
        insert new Back_Office_Integration_Settings__c(Name = 'Production', Endpoint_URL__c = 'https://www.example.com');

        Entity__c testEntity = new Entity__c();
        testEntity.Name = 'Funny2 Entity';
        testEntity.Brand__c = 'Funny2 Brand';
        testEntity.Source_ID__c = null;
        testEntity.Source_Database__c = null;      
        insert testEntity;

        Profile testProfile = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User testUser = new User(
            Alias = 'stand', 
            Email = 'testuser125@emex.com', 
            EmailEncodingKey = 'UTF-8', 
            FirstName = 'Funny',
            LastName = 'Usey',
            LanguageLocaleKey = 'en_US', 
            LocaleSidKey = 'en_US', 
            ProfileId = testProfile.Id, 
            TimeZoneSidKey = 'America/Los_Angeles', 
            UserName = 'emextestuserfunny2@emex.com',
            Entity_ID__c = testEntity.Id, 
            Entity_Name__c = testEntity.Name, 
            API_Token__c = 'funny'
        );
        insert testUser;

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
            UserName = 'emextestuserfunny0@emex.com',
            Entity_ID__c = testEntity.Id, 
            Entity_Name__c = testEntity.Name, 
            API_Token__c = 'funny2'
        );
        insert testUser2;

        Account acc = new Account();
        acc.Name = 'Funny Account';
        acc.Legal_Entity_Name__c = 'Sample Account';
        acc.Phone = '111111128';
        acc.Entity__c = testEntity.Id;
        acc.OwnerId = testUser.Id; 
        acc.BackOfficeId__c = 'UniqueBO12345';
        insert acc;

        Opportunity opp = new Opportunity();
        opp.Name = 'Funny Account - 12121';
        opp.AccountId = acc.Id;
        opp.Type = 'New Business';
        opp.NextStep = 'step';
        opp.Description = 'description';
        opp.CloseDate = Date.today();
        opp.StageName = '1 - Discovery';
        opp.Green_Energy__c = '0%';
        opp.Primary_Client_KPI__c = 'Other';
        opp.LeadSource = 'BD';
        opp.Broker__c = testBroker.Id;
        opp.Commodity__c = 'Electricity';
        opp.Market__c = testMarket.Id;
        opp.OwnerId = testUser.Id;
        opp.Expected_Contract_Start__c = Date.today();
        opp.Registered_in_Back_Office__c = true;
        insert opp;

        OpportunityTeamMember oppTeamMember = new OpportunityTeamMember();
        oppTeamMember.OpportunityId = opp.Id;
        oppTeamMember.TeamMemberRole = 'Opportunity Owner';
        oppTeamMember.UserId = testUser2.Id;
        oppTeamMember.OpportunityAccessLevel = 'Read';
        insert oppTeamMember;

        Opportunity_Split__c oppSplit = new Opportunity_Split__c();
        oppSplit.Opportunity__c = opp.Id;
        oppSplit.OwnerId = testUser2.Id;
        oppSplit.Split_Percentage__c = 0.0;
        insert oppSplit;

        // Set the mock response class
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Opportunity_Split__c existingOppSplit = [SELECT Id, Split_Percentage__c FROM Opportunity_Split__c WHERE Opportunity__c = :opp.Id LIMIT 1];
        existingOppSplit.Split_Percentage__c = 0.5;
        update existingOppSplit;

        // Prepare wrapper for 'update' operation
        OpportunitySplitsHandlerWrapper wrapper = new OpportunitySplitsHandlerWrapper();
        wrapper.opportunitySplitIds = new List<Id>{existingOppSplit.Id};
        wrapper.operation = 'update';

        // Invoke the handler (which might enqueue a queueable job)
        Test.startTest();
        OpportunitySplitHandler.handleSplitsOperation(new List<OpportunitySplitsHandlerWrapper>{wrapper});
        Test.stopTest();
    }

    // Test for Delete Operation
    @isTest
    static void testHandleSplitsOperation_Delete() {
        // Step 1: Create test data
        Uuid brokerUuid = new Uuid();
        String brokerUuidValue = brokerUuid.getValue();
        Broker__c testBroker = new Broker__c();
        testBroker.Name = 'Test Broker';
        testBroker.Source_ID__c = 'Source Id ' + brokerUuidValue;
        testBroker.Source_Database__c = 'Source DB ' + brokerUuidValue;
        insert testBroker;

        Market__c testMarket = new Market__c();
        testMarket.Name = 'Test Market';
        testMarket.Commodity__c = 'Electricity';
        testMarket.Region__c = 'US';    
        testMarket.Country__c = 'US';
        testMarket.Source_ID__c = 'Test Source Id Market';
        testMarket.Source_Database__c = 'Test Source DB Market';    
        insert testMarket;

        insert new Configuration__c(Name = 'ESBURL');
        insert new Back_Office_Integration_Settings__c(Name = 'Staging', Endpoint_URL__c = 'https://www.example.com');
        insert new Back_Office_Integration_Settings__c(Name = 'Production', Endpoint_URL__c = 'https://www.example.com');

        Entity__c testEntity = new Entity__c();
        testEntity.Name = 'Funny2 Entity';
        testEntity.Brand__c = 'Funny2 Brand';
        testEntity.Source_ID__c = null;
        testEntity.Source_Database__c = null;      
        insert testEntity;

        Profile testProfile = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User testUser = new User(
            Alias = 'stand', 
            Email = 'testuser125@emex.com', 
            EmailEncodingKey = 'UTF-8', 
            FirstName = 'Funny',
            LastName = 'Usey',
            LanguageLocaleKey = 'en_US', 
            LocaleSidKey = 'en_US', 
            ProfileId = testProfile.Id, 
            TimeZoneSidKey = 'America/Los_Angeles', 
            UserName = 'emextestuserfunny2@emex.com',
            Entity_ID__c = testEntity.Id, 
            Entity_Name__c = testEntity.Name, 
            API_Token__c = 'funny'
        );
        insert testUser;

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
            UserName = 'emextestuserfunny0@emex.com',
            Entity_ID__c = testEntity.Id, 
            Entity_Name__c = testEntity.Name, 
            API_Token__c = 'funny2'
        );
        insert testUser2;

        Account acc = new Account();
        acc.Name = 'Funny Account';
        acc.Legal_Entity_Name__c = 'Sample Account';
        acc.Phone = '111111128';
        acc.Entity__c = testEntity.Id;
        acc.OwnerId = testUser.Id; 
        acc.BackOfficeId__c = 'UniqueBO12345';
        insert acc;

        Opportunity opp = new Opportunity();
        opp.Name = 'Funny Account - 12121';
        opp.AccountId = acc.Id;
        opp.Type = 'New Business';
        opp.NextStep = 'step';
        opp.Description = 'description';
        opp.CloseDate = Date.today();
        opp.StageName = '1 - Discovery';
        opp.Green_Energy__c = '0%';
        opp.Primary_Client_KPI__c = 'Other';
        opp.LeadSource = 'BD';
        opp.Broker__c = testBroker.Id;
        opp.Commodity__c = 'Electricity';
        opp.Market__c = testMarket.Id;
        opp.OwnerId = testUser.Id;
        opp.Expected_Contract_Start__c = Date.today();
        opp.Registered_in_Back_Office__c = true;
        insert opp;

        OpportunityTeamMember oppTeamMember = new OpportunityTeamMember();
        oppTeamMember.OpportunityId = opp.Id;
        oppTeamMember.TeamMemberRole = 'Opportunity Owner';
        oppTeamMember.UserId = testUser2.Id;
        oppTeamMember.OpportunityAccessLevel = 'Read';
        insert oppTeamMember;

        Opportunity_Split__c oppSplit = new Opportunity_Split__c();
        oppSplit.Opportunity__c = opp.Id;
        oppSplit.OwnerId = testUser2.Id;
        oppSplit.Split_Percentage__c = 0.0;
        insert oppSplit;

        // Set the mock response class
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Prepare wrapper for 'delete' operation
        OpportunitySplitsHandlerWrapper wrapper = new OpportunitySplitsHandlerWrapper();
        wrapper.opportunitySplitIds = new List<Id>{oppSplit.Id};
        wrapper.operation = 'delete';

        // Invoke the handler (which might enqueue a queueable job)
        Test.startTest();
        OpportunitySplitHandler.handleSplitsOperation(new List<OpportunitySplitsHandlerWrapper>{wrapper});
        Test.stopTest();

       
    }
}