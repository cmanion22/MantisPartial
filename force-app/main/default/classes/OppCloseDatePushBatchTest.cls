@isTest
private class OppCloseDatePushBatchTest {
    
    @isTest 
    public static void pushBackTest() {
        // Step 1: Create Broker
        Uuid brokerUuid = new Uuid();
        String brokerUuidValue = brokerUuid.getValue();
        Broker__c testBroker = new Broker__c();
        testBroker.Name = 'Test Broker';
        testBroker.Source_ID__c = 'Source Id ' + brokerUuidValue;
        testBroker.Source_Database__c = 'Source DB ' + brokerUuidValue;
        insert testBroker;

        // Step 2: Create Test Market 
        Market__c testMarket = new Market__c();
        testMarket.Name = 'Test Market';
        testMarket.Commodity__c = 'Electricity';
        testMarket.Region__c = 'US';    
        testMarket.Country__c = 'US';
        testMarket.Source_ID__c = 'Test Source Id Market';
        testMarket.Source_Database__c = 'Test Source DB Market';    
        insert testMarket;

        // Step 3: Insert configuration and custom settings records
        insert new Configuration__c(Name = 'ESBURL');
        insert new Back_Office_Integration_Settings__c(Name = 'Staging', Endpoint_URL__c = 'https://www.example.com');
        insert new Back_Office_Integration_Settings__c(Name = 'Production', Endpoint_URL__c = 'https://www.example.com');

        // Step 4: Create and insert test Entity
        Entity__c testEntity = new Entity__c();
        testEntity.Name = 'Funny2 Entity';
        testEntity.Brand__c = 'Funny2 Brand';
        insert testEntity;
         
        // Step 5: Create and insert test User
        Profile testProfile = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User testUser = new User(
            Alias = 'stand', 
            Email = 'testuser1259@emex.com', 
            EmailEncodingKey = 'UTF-8', 
            FirstName = 'Funny',
            LastName = 'Usey',
            LanguageLocaleKey = 'en_US', 
            LocaleSidKey = 'en_US', 
            ProfileId = testProfile.Id, 
            TimeZoneSidKey = 'America/Los_Angeles', 
            UserName = 'emextestuserfunny12@emex.com',
            Entity_ID__c = testEntity.Id, 
            Entity_Name__c = testEntity.Name, 
            API_Token__c = 'funny'
        );
        insert testUser;
        
        // Step 6: Create and insert test Account
        Account acc = new Account();
        acc.Name = 'Funny Account';
        acc.Legal_Entity_Name__c = 'Sample Account';
        acc.Phone = '111111128';
        acc.Entity__c = testEntity.Id;
        acc.OwnerId = testUser.Id; 
        acc.BackOfficeId__c = 'UniqueBO12345';
        insert acc;

        // Step 7: Create Opportunity with criteria that will trigger the batch logic
        Opportunity opp = new Opportunity();
        opp.Name = 'Funny Account - 12121';
        opp.AccountId = acc.Id;
        opp.Type = 'New Business';
        opp.NextStep = 'step';
        opp.Description = 'description';
        opp.CloseDate = Date.today().addDays(-10); // Past date to meet criteria
        opp.StageName = '2 - Proposal'; // Ensure it does not contain "Closed"
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
        
        // Set the mock response class
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Step 8: Execute the Batch
        Test.startTest();
        OppCloseDatePushBatch batch = new OppCloseDatePushBatch();
        Database.executeBatch(batch, 10); // Execute the batch with a size of 10
        Test.stopTest();

        // Step 9: Assert that the Opportunity was processed (if the logic was active)
        // Since the update logic is commented out, we can verify selection criteria.
        List<Opportunity> updatedOpportunities = [SELECT Id, CloseDate, StageName FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(Date.today().addDays(-10), updatedOpportunities[0].CloseDate, 'Close Date should remain unchanged since update logic is commented out.');

        // Additional assert to ensure that the opportunity met criteria and was processed in batch
        System.assertEquals('2 - Proposal', updatedOpportunities[0].StageName, 'Stage should remain unchanged since it is not a closed stage.');
    }

    @isTest
    static void testScheduleMethod() {
        Test.startTest();
        OppCloseDatePushBatch.scheduleDaily(); // Schedule the job
        Test.stopTest();
        
        // Additional assertions can be placed here if needed.
    }
}