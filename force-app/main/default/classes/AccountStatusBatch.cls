public class AccountStatusBatch implements Database.Batchable<SObject>, Schedulable, Database.Stateful {

    // Simple job log for errors
    private List<JobError> jobErrors = new List<JobError>();

    public static void scheduleDaily() {
        String sch = '0 0 1 * * ?'; // Every day at 1 AM
        System.schedule('Account Status', sch, new AccountStatusBatch());
    }

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new AccountStatusBatch(), 10);
    }

    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator([
            SELECT
                Id,
                Account_Status__c,
                Contract_End_Date__c,
                Last_Won_Opportunity_Date__c,
                Total_Number_of_Opportunities__c,
                Mantis_Division__c,
                (SELECT Id, StageName, IsWon, IsClosed, Lost_Reason__c FROM Opportunities ORDER BY CloseDate DESC)
            FROM Account
            WHERE
                RecordType.Name = 'Client Account'
                AND Mantis_Division__c != null
            ]);
    }

    public void execute(Database.BatchableContext context, List<SObject> scope) {
        List<Account> accsToUpdate = new List<Account>();

        for (SObject scopeRecord : scope) {
            Account account = (Account) scopeRecord;

            if (account.Account_Status__c != 'Prospect' && account.Last_Won_Opportunity_Date__c == null) {
                account.Account_Status__c = 'Prospect';
                accsToUpdate.add(account);
                continue;
            }

            if (
                account.Account_Status__c != 'Client' &&
                (account.Mantis_Division__c == 'Energy' || account.Mantis_Division__c == 'Efficiency') &&
                (account.Contract_End_Date__c >= Date.today() || account.Last_Won_Opportunity_Date__c >= Date.today().addMonths(-12))
            ) {
                account.Account_Status__c = 'Client';
                accsToUpdate.add(account);
                continue;
            }

            if (
                account.Account_Status__c != 'Former Client' &&
                (account.Mantis_Division__c == 'Energy' || account.Mantis_Division__c == 'Efficiency') &&
                (account.Contract_End_Date__c < Date.today() && account.Last_Won_Opportunity_Date__c < Date.today().addMonths(-12))
            ) {
                account.Account_Status__c = 'Former Client';
                accsToUpdate.add(account);
                continue;
            }

            if (
                account.Account_Status__c != 'Client' &&
                (account.Mantis_Division__c == 'FMS' || account.Mantis_Division__c == 'SSG') &&
                (account.Contract_End_Date__c >= Date.today() || account.Last_Won_Opportunity_Date__c >= Date.today().addMonths(-24))
            ) {
                account.Account_Status__c = 'Client';
                accsToUpdate.add(account);
                continue;
            }

            if (
                account.Account_Status__c != 'Former Client' &&
                (account.Mantis_Division__c == 'FMS' || account.Mantis_Division__c == 'SSG') &&
                (account.Contract_End_Date__c < Date.today() && account.Last_Won_Opportunity_Date__c < Date.today().addMonths(-24))
            ) {
                account.Account_Status__c = 'Former Client';
                accsToUpdate.add(account);
                continue;
            }
        }

        List<Database.SaveResult> srs = Database.update(accsToUpdate, false);

        for (Database.SaveResult sr : srs) {
            if (!sr.isSuccess()) {
                for(Database.Error err : sr.getErrors()) {
                    JobError jobError = new JobError();
                    jobError.records = accsToUpdate;
                    jobError.message = err.getStatusCode() + ': ' + err.getMessage();
                    jobErrors.add(jobError);
                }
            }
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
                List<String> failedRecords = new List<String>();
                for (Account record : jobError.records)
                {
                    failedRecords.add(record.Id);
                }
                emailBody += String.format('<p>Error {0} occurred during the processing of batch job with records {1}</p>',
                    new List<String> { jobError.message, String.join(failedRecords, ',') });
            }
            // Send email
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new String[] { user.Email });
            mail.setReplyTo(user.Email);
            mail.setSenderDisplayName(UserInfo.getUserName());
            mail.setSubject('Update Account Status errors');
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
        public List<Account> records;
    }

}