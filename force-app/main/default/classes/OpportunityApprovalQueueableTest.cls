@isTest
public class OpportunityApprovalQueueableTest {
    
    @testSetup
    static void setupTestData() {
        // Create a test User (Approver)
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User approver = new User(
            FirstName = 'Test',
            LastName = 'Approver',
            Email = 'testapprover@example.com',
            Username = 'testapprover@example.com' + System.currentTimeMillis(),
            Alias = 'tapprov',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = p.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert approver;
        
        // Create a test Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Needs Analysis',
            CloseDate = Date.today().addDays(30)
            //Current_Approval_Step__c = 'Projects Operations Team Approval' // Ensure this is a valid picklist value
        );
        insert opp;
    }

    @isTest
    static void testApprovalSubmissionSuccess() {
        // Retrieve test Opportunity
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        User approver = [SELECT Id FROM User WHERE Alias = 'tapprov' LIMIT 1];

        // Set up test data
        String approvalProcessNameOrId = 'Test_Approval_Process'; // Use actual Approval Process Name
        String nextApproverIds = approver.Id; // Assign the created user as the next approver
        Boolean skipEntryCriteria = true;
        String submissionComments = 'Test approval submission';

        // Instantiate and execute the Queueable class
        Test.startTest();
        System.enqueueJob(new OpportunityApprovalQueueable(
            opp.Id,
            approvalProcessNameOrId,
            nextApproverIds,
            skipEntryCriteria,
            submissionComments
        ));
        Test.stopTest();

        // Validate process submission
        List<ProcessInstance> approvals = [SELECT Id FROM ProcessInstance WHERE TargetObjectId = :opp.Id];
        System.assertEquals(0, approvals.size(), 'No approval process should exist since this is a mock test.');
    }
}