@isTest
public class OpportunityExistingSolControllerTest {

    // Helper method to create a test Account
    private static Account createTestAccount() {
        Account acc = new Account();
        acc.Name = 'Funny Account12';
        acc.Legal_Entity_Name__c = 'Sample Account';
        acc.Phone = '1111111289';
        insert acc;
        return acc;
    }

    // Helper method to create a test Opportunity
    private static Opportunity createTestOpportunity(Id accountId, String typeOfService, String stageName, Date closeDate) {
        Opportunity opp = new Opportunity();
        opp.Name = 'Funny Account - 12121';
        opp.AccountId = accountId;
        opp.Type_of_Service__c = typeOfService;
        opp.StageName = stageName;
        opp.CloseDate = closeDate;
        opp.Green_Energy__c = '0%';
        opp.Primary_Client_KPI__c = 'Other';
        opp.LeadSource = 'BD';
        opp.Expected_Contract_Start__c = Date.today();
        insert opp;
        return opp;
    }

    // Test for getOpportunities method
    @isTest
    public static void testGetOpportunities() {
        // Create a test Account
        Account acc = createTestAccount();

        // Create a couple of Opportunities related to the Account
        Opportunity opp1 = createTestOpportunity(acc.Id, 'Solar', '5 - Closed Won', Date.today().addDays(-10));
        Opportunity opp2 = createTestOpportunity(acc.Id, 'Solar', '5 - Closed Won', Date.today().addDays(-5));
        Opportunity opp3 = createTestOpportunity(acc.Id, 'Solar', '5 - Closed Won', Date.today().addDays(-3));

        // Set the opportunityId of the first opportunity (to pass into the method)
        String opportunityId = opp1.Id;

        // Call the getOpportunities method
        Test.startTest();
        List<OpportunityExistingSolutionController.OpportunityChartWrapper> result = OpportunityExistingSolutionController.getOpportunities(opportunityId);
        Test.stopTest();

        // Verify the size of the returned list
        System.assertEquals(result.size(), 2, 'There should be 2 related opportunities');

        // Verify the properties of the wrapper objects
        System.assertEquals(result[0].closeDateYear, String.valueOf(opp2.CloseDate.year()), 'The close date year should match');
        System.assertEquals(result[0].typeOfService, opp2.Type_of_Service__c, 'The type of service should match');
        
        System.assertEquals(result[1].closeDateYear, String.valueOf(opp3.CloseDate.year()), 'The close date year should match');
        System.assertEquals(result[1].typeOfService, opp3.Type_of_Service__c, 'The type of service should match');
    }

    // Test for exception handling in getOpportunities method (invalid Opportunity ID)
    @isTest
    public static void testGetOpportunitiesExceptionInvalidId() {
        // Call getOpportunities with an invalid Opportunity ID
        Test.startTest();
        try {
            OpportunityExistingSolutionController.getOpportunities('invalidId');
            System.assert(false, 'Exception should be thrown for invalid Opportunity ID');
        } catch (AuraHandledException e) {
            System.assertEquals('Script-thrown exception', 'Script-thrown exception', 'Error message should match');
        }
        Test.stopTest();
    }

    // Test for exception handling in getOpportunities method (Opportunity does not exist)
    @isTest
    public static void testGetOpportunitiesExceptionNotFound() {
        // Call getOpportunities with a non-existing Opportunity ID
        Test.startTest();
        try {
            OpportunityExistingSolutionController.getOpportunities('000000000000000');
            System.assert(false, 'Exception should be thrown for Opportunity not found');
        } catch (AuraHandledException e) {
            System.assertEquals('Script-thrown exception', 'Script-thrown exception', 'Error message should match');
        }
        Test.stopTest();
    }
}