public class OpportunityApprovalQueueable implements Queueable {
    private Id opportunityId;
    private String approvalProcessNameOrId;
    private String nextApproverIds;
    private Boolean skipEntryCriteria;
    private String submissionComments;

    // Constructor
    public OpportunityApprovalQueueable(
        Id opportunityId, 
        String approvalProcessNameOrId, 
        String nextApproverIds, 
        Boolean skipEntryCriteria, 
        String submissionComments
    ) {
        this.opportunityId = opportunityId;
        this.approvalProcessNameOrId = approvalProcessNameOrId;
        this.nextApproverIds = nextApproverIds;
        this.skipEntryCriteria = skipEntryCriteria;
        this.submissionComments = submissionComments;
    }

    public void execute(QueueableContext context) {
        try {
            // Ensure the record is not in another approval process
            List<ProcessInstance> currentApprovalProcesses = [
                SELECT Id 
                FROM ProcessInstance 
                WHERE TargetObjectId = :opportunityId AND Status = 'Pending'
            ];

            if (currentApprovalProcesses.isEmpty()) {
                // Submit for Approval
                Approval.ProcessSubmitRequest submitRequest = new Approval.ProcessSubmitRequest();
                submitRequest.setObjectId(opportunityId); // Record ID
                submitRequest.setProcessDefinitionNameOrId(approvalProcessNameOrId); // Approval Process Name/ID
                submitRequest.setNextApproverIds(nextApproverIds.split(',')); // Approver IDs
                submitRequest.setSkipEntryCriteria(skipEntryCriteria); // Skip entry criteria
                submitRequest.setComments(submissionComments); // Comments

                Approval.ProcessResult result = Approval.process(submitRequest);

                if (!result.isSuccess()) {
                    System.debug('Approval submission failed: ' + result.getInstanceStatus());
                } else {
                    System.debug('Approval submission successful: ' + result.getInstanceStatus());
                }
            } else {
                System.debug('Record is still in an approval process.');
            }
        } catch (Exception ex) {
            System.debug('Error during approval submission: ' + ex.getMessage());
        }
    }
}