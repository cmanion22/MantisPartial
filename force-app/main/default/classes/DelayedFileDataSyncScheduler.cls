global class DelayedFileDataSyncScheduler implements Schedulable {
    public Id contentDocumentLinkId;
    public Id contentDocumentId;
    public Id opportunityId;

    public DelayedFileDataSyncScheduler(Id contentDocumentLinkId, Id contentDocumentId, Id opportunityId) {
        this.contentDocumentLinkId = contentDocumentLinkId;
        this.contentDocumentId = contentDocumentId;
        this.opportunityId = opportunityId;
    }

    global void execute(SchedulableContext sc) {
        FileCalloutClass.uploadFile(contentDocumentLinkId, contentDocumentId, opportunityId);
    }
}