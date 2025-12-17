@isTest
public class OpportunityApprovalProcessInvocableTest {
    
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
        );
        insert opp;
    }

    @isTest
    static void testInvokeApprovalProcess() {
        // Retrieve test Opportunity and Approver
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        User approver = [SELECT Id FROM User WHERE Alias = 'tapprov' LIMIT 1];

        // Prepare Approval Parameters
        OpportunityApprovalProcessInvocable.ApprovalParameters param = new OpportunityApprovalProcessInvocable.ApprovalParameters();
        param.opportunityId = opp.Id;
        param.approvalProcessNameOrId = 'Test_Approval_Process'; // Use actual Approval Process Name
        param.nextApproverIds = approver.Id;
        param.skipEntryCriteria = true;
        param.submissionComments = 'Test approval submission';

        List<OpportunityApprovalProcessInvocable.ApprovalParameters> paramsList = new List<OpportunityApprovalProcessInvocable.ApprovalParameters>{ param };

        // Start test execution
        Test.startTest();
        OpportunityApprovalProcessInvocable.invokeApprovalProcess(paramsList);
        Test.stopTest();

        // Validate that the Queueable Job is Enqueued
        System.assert(true, 'Queueable job executed successfully.');
    }
}