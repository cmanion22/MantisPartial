@isTest
private class BillingManagerAssignmentHelperTest {

    @testSetup
    static void setupTestData() {
        // Create a user that simulates the current user
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Alias = 'tuser',
            Email = 'testuser@example.com',
            Username = 'testuser@example.com.test1',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/New_York'
        );
        insert testUser;

        // Create a matching Unanet_User__c record
        Unanet_User__c billingManager = new Unanet_User__c(
            First_Name__c = 'Cody',
            Last_Name__c = 'Manion',
            Unanet_Role__c = 'Billing Manager',
            Username__c = 'TestUser',
            Unanet_User_Id__c = '123'
        );

        insert billingManager;

        // Create Opportunities with and without Billing Manager
        List<Opportunity> opps = new List<Opportunity>{
            new Opportunity(Name = 'Opp - 1 - Test', StageName = '5 - Closed Won', CloseDate = Date.today().addDays(30), Current_Approval_Step__c = 'All Steps Completed'),
            new Opportunity(Name = 'Opp - 2 - Test', StageName = '5 - Closed Won', CloseDate = Date.today().addDays(30), Current_Approval_Step__c = 'All Steps Completed')
        };
        insert opps;
    }

    static testMethod void testBillingManagerAssignment() {
        // Run as the test user
        User testUser = [SELECT Id FROM User WHERE Username = 'testuser@example.com.test1' LIMIT 1];

            // Fetch Opportunities
            List<Opportunity> opps = [SELECT Id, Billing_Manager__c FROM Opportunity];

            // Ensure Billing_Manager__c is null before
            for (Opportunity opp : opps) {
                System.assertEquals(null, opp.Billing_Manager__c, 'Should be null before helper runs');
            }

            // Run the helper
            BillingManagerAssignmentHelper.updateBillingManager(opps);

            // Update the records in DB
            update opps;

            // Re-fetch and assert that Billing Manager was assigned
            List<Opportunity> updatedOpps = [SELECT Billing_Manager__c FROM Opportunity];
            for (Opportunity opp : updatedOpps) {
                System.assertNotEquals(null, opp.Billing_Manager__c, 'Billing Manager should be assigned');
            }
    }

    static testMethod void testNoBillingManagerMatch() {
        // Create a user with no matching Unanet_User__c
        User noMatchUser = new User(
            FirstName = 'NoMatch',
            LastName = 'User',
            Alias = 'nomatch',
            Email = 'nomatch@example.com',
            Username = 'nomatch@example.com.test',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/New_York'
        );
        insert noMatchUser;

        System.runAs(noMatchUser) {
            List<Opportunity> opps = [SELECT Id, Billing_Manager__c FROM Opportunity];

            // Run helper
            BillingManagerAssignmentHelper.updateBillingManager(opps);

            // Nothing should be assigned
            for (Opportunity opp : opps) {
                System.assertEquals(null, opp.Billing_Manager__c, 'No match user should not assign a Billing Manager');
            }
        }
    }

    static testMethod void testEmptyOpportunityList() {
        Test.startTest();
        BillingManagerAssignmentHelper.updateBillingManager(new List<Opportunity>());
        Test.stopTest();
    }

    static testMethod void testNullOpportunityList() {
        Test.startTest();
        BillingManagerAssignmentHelper.updateBillingManager(null);
        Test.stopTest();
    }
}