public with sharing class UpdatePartnerOppRollupsBatch implements Database.Batchable<SObject>, Database.Stateful {

    // Simple job log for errors
    private List<JobError> jobErrors = new List<JobError>();

    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator([select id from opportunity where Temp_Backfill_Partner_Rollups__c = true order by closedate asc]);
    }

    public void execute(Database.BatchableContext context, List<Opportunity> opportunities) {
        try
        {
            for (Opportunity opportunity : opportunities) {
                Map<String, Object> inputs = new Map<String, Object>();
                inputs.put('recordId', opportunity.Id);

                Flow.Interview.Partner_Opp_Account_Updates partnerOppAccountUpdatesFlow = new Flow.Interview.Partner_Opp_Account_Updates(inputs);
                partnerOppAccountUpdatesFlow.start();
            }
        }
        catch (Exception e)
        {
            // Capture context and error for reporting once job complete
            JobError jobError = new JobError();
            jobError.records = opportunities;
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
                List<String> failedOpps = new List<String>();
                for (Opportunity opp : jobError.records)
                {
                    failedOpps.add(opp.Name);
                }
                emailBody += String.format('<p>Error {0} occurred during the processing of Opportunities {1}</p>',
                    new List<String> { jobError.message, String.join(failedOpps, ',') });
            }
            // Send email
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new String[] { user.Email });
            mail.setReplyTo(user.Email);
            mail.setSenderDisplayName(UserInfo.getUserName());
            mail.setSubject('Update Partner Opp Rollups failures');
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
        public List<Opportunity> records;
    }

}