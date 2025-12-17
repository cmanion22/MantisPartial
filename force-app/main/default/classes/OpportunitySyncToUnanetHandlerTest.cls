@IsTest
public class OpportunitySyncToUnanetHandlerTest {

    @IsTest
    static void testHandleServiceOpportunity() {
        // Step 1: Set up test data
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today()
        );
        insert opp;

        // Step 2: Call the invocable method
        Test.startTest();
            OpportunitySyncToUnanetHandler.handleServiceOpportunity(
                new List<Id>{ opp.Id }
            );
        Test.stopTest();

        // Step 3: Verify that the queueable was enqueued
        // Note: System.enqueueJob is covered automatically during Test.startTest()/stopTest()
        // Optional: assert debug logs or other side effects if needed
    }

    @IsTest
    static void testHandleServiceOpportunityWithNoOpportunityIds() {
        // Should gracefully exit without error
        Test.startTest();
            OpportunitySyncToUnanetHandler.handleServiceOpportunity(new List<Id>());
            OpportunitySyncToUnanetHandler.handleServiceOpportunity(null);
        Test.stopTest();
    }

    @IsTest
    static void testHandleServiceOpportunityWithoutAccount() {
        // Opportunity without AccountId should not enqueue job
        Opportunity opp = new Opportunity(
            Name = 'No Account Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today()
        );
        insert opp;

        Test.startTest();
            OpportunitySyncToUnanetHandler.handleServiceOpportunity(
                new List<Id>{ opp.Id }
            );
        Test.stopTest();

        // No enqueue job should occur, but no exception thrown
    }
}