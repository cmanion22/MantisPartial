public with sharing class UnanetUserIntegrationScheduledJob implements Schedulable {
    public void execute(SchedulableContext sc) {
        // The logic that should run when the job is scheduled
        System.enqueueJob(new UnanetUserIntegrationQueueable());
    }
}