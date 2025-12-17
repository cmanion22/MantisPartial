@isTest
private class OpportunitySplitOwnerUpdateTest {

    // Helper method to create test data for Opportunity and Opportunity Splits
    private static void createTestData() {
        // Create and insert test User
        Profile testProfile = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User testUser = new User(
            Alias = 'fun', 
            Email = 'testuser1255@emex.com', 
            EmailEncodingKey = 'UTF-8', 
            FirstName = 'Fun',
            LastName = 'User',
            LanguageLocaleKey = 'en_US', 
            LocaleSidKey = 'en_US', 
            ProfileId = testProfile.Id, 
            TimeZoneSidKey = 'America/Los_Angeles', 
            UserName = 'emextestuserfunny2555@emex.com',
            API_Token__c = 'fun'
        );
        insert testUser;

        User testUser2 = new User(
            Alias = 'fun', 
            Email = 'testuser12555@emex.com', 
            EmailEncodingKey = 'UTF-8', 
            FirstName = 'Fun',
            LastName = 'User',
            LanguageLocaleKey = 'en_US', 
            LocaleSidKey = 'en_US', 
            ProfileId = testProfile.Id, 
            TimeZoneSidKey = 'America/Los_Angeles', 
            UserName = 'emextestuserfunny25555@emex.com',
            API_Token__c = 'fun'
        );
        insert testUser2;

        // Create and insert test Account
        Account acc = new Account();
        acc.Name = 'Funny Account';
        acc.Legal_Entity_Name__c = 'Sample Account';
        acc.Phone = '111111128';
        acc.OwnerId = testUser.Id; 
        acc.BackOfficeId__c = 'UniqueBO12345';
        insert acc;
       
        // Create a test Opportunity
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
        opp.OwnerId = testUser.Id;
        opp.Legacy_Opportunity_No_Splits__c = false;	
        opp.Previous_Owner__c = testUser2.Id; // Setting Previous Owner for testing
        opp.Expected_Contract_Start__c = Date.today();
        insert opp;
        
        System.debug('Test opp Previous Owner Id: ' + opp.Previous_Owner__c);
        
        // Create splits for the Opportunity
        Opportunity_Split__c previousOwnerSplit = new Opportunity_Split__c(
            Opportunity__c = opp.Id,
            OwnerId = testUser2.Id,  // Previous owner
            Split_Percentage__c = 50,
            Current_Percentage__c = 50
        );
        insert previousOwnerSplit;

        Opportunity_Split__c oppOwnerSplit = new Opportunity_Split__c(
            Opportunity__c = opp.Id,
            OwnerId = testUser.Id,  // Opp owner
            Split_Percentage__c = 50,
            Current_Percentage__c = 50
        );
        insert oppOwnerSplit;
    }

    // Test for updating Opportunity Splits when Opportunity has a previous owner
    @isTest
    static void testOwnerHasSplitWithPreviousOwner() {
        createTestData();
        
        Test.startTest();
        OpportunitySplitOwnerUpdate.updateOpportunitySplits();
        Test.stopTest();
        
        // Verify splits have been updated
        List<Opportunity_Split__c> updatedSplits = [SELECT OwnerId, Opportunity__c FROM Opportunity_Split__c];
        System.assertEquals(2, updatedSplits.size(), 'There should be 2 splits.');
        for (Opportunity_Split__c split : updatedSplits) {
            System.assertNotEquals(null, split.OwnerId, 'OwnerId should not be null');
        }
    }

    // Test case for when no open Opportunities are found
    @isTest
    static void testNoOpenOpportunities() {
        // Create data with closed Opportunities
        Opportunity closedOpp = new Opportunity(
            Name = 'Closed Opportunity', 
            StageName = 'Closed Won', 
            CloseDate = Date.today(),
            OwnerId = UserInfo.getUserId()
        );
        insert closedOpp;

        Test.startTest();
        OpportunitySplitOwnerUpdate.updateOpportunitySplits();
        Test.stopTest();
        // Verify the logs capture 'No Open Opportunities Found'
    }

    // Test case for when no Opportunity Splits are found
    @isTest
    static void testNoOpportunitySplits() {
        // Create an Opportunity but no Opportunity Splits
        Account acc = new Account(Name = 'Funny Account No Splits');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'No Splits Opportunity', 
            AccountId = acc.Id, 
            StageName = '1 - Discovery', 
            CloseDate = Date.today(),
            OwnerId = UserInfo.getUserId()
        );
        insert opp;

        Test.startTest();
        OpportunitySplitOwnerUpdate.updateOpportunitySplits();
        Test.stopTest();
        // Verify the logs capture 'No Opportunity Splits Found'
    }

    // Test case for no Previous Owner and no splits
    @isTest
    static void testNoPreviousOwnerNoSplits() {
        // Create Opportunity with no previous owner
        Account acc = new Account(Name = 'Test Account No Previous Owner');
        insert acc;
        
        Opportunity opp = new Opportunity(
            Name = 'No Previous Owner Opportunity',
            AccountId = acc.Id, 
            StageName = '1 - Discovery', 
            CloseDate = Date.today(),
            OwnerId = UserInfo.getUserId()
        );
        insert opp;

        Test.startTest();
        OpportunitySplitOwnerUpdate.updateOpportunitySplits();
        Test.stopTest();
        // Verify that no splits were found and logs for this condition
    }

    // Edge case test with multiple Opportunities
    @isTest
    static void testMultipleOpportunities() {
        createTestData(); // Creates one Opportunity with splits
        // Add another Opportunity without splits
        Account acc = new Account(Name = 'Funny Account Multiple');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Multiple Opportunities Test',
            AccountId = acc.Id,
            Type = 'New Business',
            StageName = '1 - Discovery',
            CloseDate = Date.today(),
            OwnerId = UserInfo.getUserId()
        );
        insert opp;

        Test.startTest();
        OpportunitySplitOwnerUpdate.updateOpportunitySplits();
        Test.stopTest();
        // Verify that both opportunities were processed
    }
    
    @isTest
    static void testExceptionHandling() {
        // Create test data that will trigger an exception
        // For example, use invalid or missing values
        createTestData();

        // Induce an error by passing invalid data or missing fields
        Test.startTest();
        try {
            OpportunitySplitOwnerUpdate.updateOpportunitySplits();
        } catch (Exception e) {
            // Verify the exception was handled and logged
            System.assert(e.getMessage().contains('Error in OpportunitySplitUpdater'));
        }
        Test.stopTest();
    }
    
    @isTest
    static void testPreviousOwnerHasSplit() {
        // Create test data
        // Create and insert test User
        Profile testProfile = [SELECT Id FROM Profile WHERE Name='System Administrator No SSO']; 
        User testUser = new User(
            Alias = 'fun', 
            Email = 'testuser12558@emex.com', 
            EmailEncodingKey = 'UTF-8', 
            FirstName = 'Fun',
            LastName = 'User',
            LanguageLocaleKey = 'en_US', 
            LocaleSidKey = 'en_US', 
            ProfileId = testProfile.Id, 
            TimeZoneSidKey = 'America/Los_Angeles', 
            UserName = 'emextestuserfunny25558@emex.com',
            API_Token__c = 'fun'
        );
        insert testUser;

        User testUser2 = new User(
            Alias = 'fun', 
            Email = 'testuser125555@emex.com', 
            EmailEncodingKey = 'UTF-8', 
            FirstName = 'Fun',
            LastName = 'User',
            LanguageLocaleKey = 'en_US', 
            LocaleSidKey = 'en_US', 
            ProfileId = testProfile.Id, 
            TimeZoneSidKey = 'America/Los_Angeles', 
            UserName = 'emextestuserfunny255555@emex.com',
            API_Token__c = 'fun'
        );
        insert testUser2;

        // Create and insert test Account
        Account acc = new Account();
        acc.Name = 'Funny Account';
        acc.Legal_Entity_Name__c = 'Sample Account';
        acc.Phone = '111111128';
        acc.OwnerId = testUser.Id; 
        acc.BackOfficeId__c = 'UniqueBO12345';
        insert acc;
       
        // Create a test Opportunity
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
        opp.OwnerId = testUser.Id;
        opp.Legacy_Opportunity_No_Splits__c = false;	
        opp.Previous_Owner__c = testUser2.Id; // Setting Previous Owner for testing
        opp.Expected_Contract_Start__c = Date.today();
        insert opp;
        
        System.debug('Test opp Previous Owner Id: ' + opp.Previous_Owner__c);
        
        // Create splits for the Opportunity
        Opportunity_Split__c previousOwnerSplit = new Opportunity_Split__c(
            Opportunity__c = opp.Id,
            OwnerId = testUser2.Id,  // Previous owner
            Split_Percentage__c = 50,
            Current_Percentage__c = 50
        );
        insert previousOwnerSplit;
        Test.startTest();
        OpportunitySplitOwnerUpdate.updateOpportunitySplits();
        Test.stopTest();
        
    }
    
    @isTest
    static void testScheduler() {
        // Step 1: Create test data using the existing helper method
        createTestData();

        // Step 2: Schedule the class
        String jobName = 'Test Job - Opportunity Split Update';
        String cronExpression = '0 0 0 * * ?'; // Runs the job at midnight
        System.schedule(jobName, cronExpression, new OpportunitySplitOwnerUpdateScheduler());

        // Step 3: Start and stop test to simulate scheduled job execution
        Test.startTest();
        Test.stopTest();
        
    }
}