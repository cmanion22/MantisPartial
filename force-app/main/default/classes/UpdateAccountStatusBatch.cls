public with sharing class UpdateAccountStatusBatch implements Database.Batchable<SObject>, Database.Stateful {

    // Simple job log for errors
    private List<JobError> jobErrors = new List<JobError>();

    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator([SELECT Id, Name, Mantis_Division__c, Contract_End_Date__c, StageName, Flow_Status__c, Lost_Reason__c, AccountId, Account.Account_Status__c, Account.Contract_End_Date__c, Account.Last_Won_Opportunity_Date__c FROM Opportunity WHERE AccountId != null AND Contract_End_Date__c != null AND Account.Account_Status__c = null]);
    }

    public void execute(Database.BatchableContext context, List<Opportunity> opportunities) {
        try
        {
            List<Opportunity> oppsToBeUpdated = new List<Opportunity>();

            List<Id> accountIds = new List<Id>();
            for (Opportunity opportunity : opportunities) {
                accountIds.add(opportunity.AccountId);
            }

            Map<Id, Account> accountsById = new Map<Id, Account>([SELECT Id, Account_Status__c, Contract_End_Date__c, Last_Won_Opportunity_Date__c FROM Account WHERE Id IN :accountIds]);

            for (Opportunity opportunity : opportunities) {
                Account account = accountsById.get(opportunity.AccountId);

                if (!String.isEmpty(account.Account_Status__c)) continue;

                Map<String, Object> inputs = new Map<String, Object>();
                inputs.put('varAccountId', account);
                inputs.put('varOppId', opportunity);

                Flow.Interview.Account_Status_Sub_Flow accountStatusSubFlow = new Flow.Interview.Account_Status_Sub_Flow(inputs);
                accountStatusSubFlow.start();
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
            mail.setSubject('Update Account Status failures');
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