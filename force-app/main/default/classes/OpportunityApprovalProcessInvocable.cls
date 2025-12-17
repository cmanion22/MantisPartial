public class OpportunityApprovalProcessInvocable {
@InvocableMethod(label='Submit Opportunity for Approval' description='Starts the approval process for an Opportunity')
    public static void invokeApprovalProcess(List<ApprovalParameters> parameters) {
        for (ApprovalParameters param : parameters) {
            System.enqueueJob(new OpportunityApprovalQueueable(
                param.opportunityId, 
                param.approvalProcessNameOrId, 
                param.nextApproverIds, 
                param.skipEntryCriteria, 
                param.submissionComments
            ));
        }
    }

    public class ApprovalParameters {
        @InvocableVariable(label='Opportunity ID' description='ID of the Opportunity record' required=true)
        public Id opportunityId;

        @InvocableVariable(label='Approval Process Name or ID' description='Name or ID of the Approval Process' required=true)
        public String approvalProcessNameOrId;

        @InvocableVariable(label='Next Approver IDs' description='Comma-separated User or Group IDs' required=true)
        public String nextApproverIds;

        @InvocableVariable(label='Skip Entry Criteria' description='Whether to skip entry criteria' required=true)
        public Boolean skipEntryCriteria;

        @InvocableVariable(label='Submission Comments' description='Comments for submission' required=false)
        public String submissionComments;
    }
}