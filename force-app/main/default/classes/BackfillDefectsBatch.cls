public with sharing class BackfillDefectsBatch implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts {

    // Simple job log for errors
    private List<JobError> jobErrors = new List<JobError>();

    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator([SELECT Id, SectionGUID__c FROM Section__c]);
    }

    public void execute(Database.BatchableContext context, List<Section__c> sections) {
        try
        {
            FetchPerformDefectsInvocable.fetchPerformDefects(new List<String> { sections[0].SectionGUID__c });
        }
        catch (Exception e)
        {
            // Capture context and error for reporting once job complete
            JobError jobError = new JobError();
            jobError.records = sections;
            jobError.message = e.getMessage();
            jobErrors.add(jobError);
        }
    }
    
    public void finish(Database.BatchableContext context)
    {
        // Simple notification of any errors received via email
        if(jobErrors.size() > 0)
        {
            // Email address from user
            User user = [SELECT Id, Email FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            // Construct email body
            String emailBody = '';
            for(JobError jobError : jobErrors)
            {
                List<String> recIds = new List<String>();
                for (Section__c rec : jobError.records)
                {
                    recIds.add(rec.Id);
                }
                emailBody += String.format('<p>Error {0} occurred during the processing of records {1}</p>',
                    new List<String> { jobError.message, String.join(recIds, ',') });
            }
            // Send email
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new String[] { user.Email });
            mail.setReplyTo(user.Email);
            mail.setSenderDisplayName(UserInfo.getUserName());
            mail.setSubject('Batch failures');
            mail.setHtmlBody(emailBody);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
    }

    /**
     * Simple wrapper class containing the error message and the records in scope at the time
     **/
    public class JobError
    {
        public String message;
        public List<Section__c> records;
    }

}