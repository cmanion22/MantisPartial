@isTest
private class OppSplitRelatedListControllerTest {

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
            UserName = 'emextestuserfunny255@emex.com',
            API_Token__c = 'fun'
        );
        insert testUser;
        
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
        opp.Expected_Contract_Start__c = Date.today();
        insert opp;

        // Create Opportunity Splits for the Opportunity
        Opportunity_Split__c split1 = new Opportunity_Split__c(
            Opportunity__c = opp.Id,
            OwnerId = testUser.Id,
            Split_Percentage__c = 50,
            Current_Percentage__c = 50
        );
        Opportunity_Split__c split2 = new Opportunity_Split__c(
            Opportunity__c = opp.Id,
            OwnerId = testUser.Id,
            Split_Percentage__c = 50,
            Current_Percentage__c = 50
        );
        insert new List<Opportunity_Split__c>{split1, split2};
    }

    // Test for getOpportunitySplits method
    @isTest
    static void testGetOpportunitySplits() {
        createTestData();
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        List<Opportunity_Split__c> splits = OpportunitySplitRelatedListController.getOpportunitySplits(opp.Id);
        Test.stopTest();

        System.assertNotEquals(0, splits.size(), 'Opportunity Splits should be fetched successfully');
    }

    // Test for createOpportunitySplit method
    @isTest
    static void testCreateOpportunitySplit() {
        createTestData();
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        User u1 = [SELECT Id FROM User WHERE Username = 'emextestuserfunny255@emex.com' LIMIT 1];

        Test.startTest();
        Opportunity_Split__c newSplit = OpportunitySplitRelatedListController.createOpportunitySplit(opp.Id, u1.Id);
        Test.stopTest();

        System.assertNotEquals(null, newSplit, 'New Opportunity Split should be created');
        System.assertEquals(u1.Id, newSplit.OwnerId, 'Owner should be assigned correctly');
    }

    // Test for checkUserPermissions method
    @isTest
    static void testCheckUserPermissions() {
        createTestData();
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        Map<String, Boolean> permissions = OpportunitySplitRelatedListController.checkUserPermissions(opp.Id);
        Test.stopTest();
    }

    // Test for updateOpportunitySplits method
    @isTest
    static void testUpdateOpportunitySplits() {
        createTestData();
        Opportunity_Split__c split = [SELECT Id FROM Opportunity_Split__c LIMIT 1];

        split.Split_Percentage__c = 60;
        split.Current_Percentage__c = 60;

        Test.startTest();
        OpportunitySplitRelatedListController.updateOpportunitySplits(new List<Opportunity_Split__c>{split});
        Test.stopTest();

        // Re-query to verify the update
        Opportunity_Split__c updatedSplit = [SELECT Split_Percentage__c, Current_Percentage__c FROM Opportunity_Split__c WHERE Id = :split.Id];
        System.assertEquals(60, updatedSplit.Split_Percentage__c, 'Split Percentage should be updated');
        System.assertEquals(60, updatedSplit.Current_Percentage__c, 'Current Percentage should be updated');
    }

    // Test for isServicesRecordType method
    @isTest
    static void testIsServicesRecordType() {
        createTestData();
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        Boolean result = OpportunitySplitRelatedListController.isServicesRecordType(opp.Id);
        Test.stopTest();

        System.assertEquals(false, result, 'The record type should not be Services');
    }

    // Test for getUsers method
    @isTest
    static void testGetUsers() {
        createTestData();
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        List<User> users = OpportunitySplitRelatedListController.getUsers(opp.Id);
        Test.stopTest();

        System.assertNotEquals(0, users.size(), 'Users should be fetched successfully');
    }

    // Test for Permission Set Assignment (fixing MIXED_DML_OPERATION error)
    @isTest
    static void testGetOpportunity() {
        // Create test data
        createTestData();
    	Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        String oppId = Opp.Id;
        
        Test.startTest();
        OpportunitySplitRelatedListController.getRelatedOpportunity(oppId);
        Test.stopTest();
        
    }

}