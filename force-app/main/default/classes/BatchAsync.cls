public with sharing class BatchAsync implements Database.Batchable<SObject>, Database.AllowsCallouts 
{
    public Database.QueryLocator start(Database.BatchableContext context) 
    {    
        System.debug('BatchAsync-->start');
        return Database.getQueryLocator([
                SELECT className__c, count__c, serializedJob__c, nextTry__c, firstTry__c, event__c, httpResponseCode__c
                FROM RetryableJob__c
                WHERE nextTry__c < :System.now()
                AND status__c = :Retry.Status.FAILED_RETRY.name()
        ]);
    }

    public void execute(Database.BatchableContext context, List<SObject> jobs) 
    {                      
        List<RetryableJob__c> jobsToUpdate = new List<RetryableJob__c>();        
        for (Sobject job : jobs) {
            System.debug('BatchAsync-->execute-->job-->' + job);
            RetryableJob__c storedJob = (RetryableJob__c) job;
            Type jobType = Type.forName(storedJob.className__c);

            if(Test.isRunningTest()) 
            {
                return;
            }
            
            Retry currentJob = (Retry) JSON.deserialize(storedJob.serializedJob__c, jobType);
            JobResult jobResult = currentJob.retry(storedJob.event__c, (Integer)storedJob.httpResponseCode__c);
                        
            storedJob.lastTry__c = System.now();                        
            storedJob.status__c = jobResult.status.name();
            System.debug('BatchAsync-->execute-->storedJob.status__c-->' + storedJob.status__c);
            
            storedJob.nextTry__c = jobResult.status == Retry.Status.FAILED_RETRY? currentJob.getNextTry() : null;
            System.debug('BatchAsync-->execute-->storedJob.nextTry__c-->' + storedJob.nextTry__c);
            
            storedJob.serializedJob__c = JSON.serialize(currentJob);            
            storedJob.count__c = storedJob.count__c + 1;            
            System.debug('BatchAsync-->execute-->storedJob.count__c-->' + storedJob.count__c);
            
            storedJob.message__c = jobResult.message.abbreviate(255); 
            storedJob.event__c = jobResult.event;
            storedJob.httpResponseCode__c = jobResult.responseCode;
            jobsToUpdate.add(storedJob);
        }
        System.debug('BatchAsync-->execute-->jobsToUpdate-->'+ jobsToUpdate);
        update jobsToUpdate;        
    }

    public void finish(Database.BatchableContext BC) 
    {    
        List<RetryableJob__c> lstJobs = [
                                          SELECT   Id, count__c, status__c, event__c, httpResponseCode__c, serializedJob__c
                                          FROM RetryableJob__c
                                        ];
        System.debug('BatchAsync-->execute-->lstJobs-->' + lstJobs);
        for (RetryableJob__c job : lstJobs) {
            System.debug('BatchAsync-->execute-->job-->' + job);
            Integer count = (Integer)job.count__c;
            System.debug('BatchAsync-->execute-->count-->' + count);
            if (count <= Constants.retryScheduleInMinutes.size() && job.status__c != Retry.Status.SUCCEEDED.name()) {
                System.debug('BatchAsync-->execute-->RETRY');            
                RetryScheduler.schedule(Constants.retryScheduleInMinutes.get(count - 1), job.event__c);
            } 
            else if (count >= Constants.retryScheduleInMinutes.size() && job.status__c != Retry.Status.SUCCEEDED.name()) {
                System.debug('BatchAsync-->execute-->SEND EMAIL-->');
                sendEmail(job);
                delete job;
            }
            else { 
                System.debug('BatchAsync-->execute-->SUCCESS STOP-->');                            
                //SUCCESS -- Data posted to ESB successfully -- delete job
                delete job;
            }
        }
    }
    
    public void sendEmail(RetryableJob__c job)
    {    
        String subject = 'Failure Report';   
        String body = '<h2><u>Sending data to ESB failed. Details below</u>: </h2><br/>' ;
        
        // Send an email to the Apex job's submitter notifying of job completion.
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(Constants.toAddresses);
        mail.setSubject(subject);
        mail.setHTMLBody(body + getJobDetails(job));
        if(Test.isRunningTest()) 
        {
            return;
        }
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
    
    public String getJobDetails(RetryableJob__c job) 
    {
        String body = '<b><u>Event Name</u>: </b>' + job.event__c + '<br/><br/>';
        body += '<b><u>Final Status</u>: </b>' + job.status__c + '<br/><br/>';
        body += '<b><u>Http Response Code</u>: </b>' + String.valueOf(job.httpResponseCode__c) + '<br/><br/>';
        body += '<b><u>Number of Retries</u>: </b>' + String.valueOf(job.count__c) + '<br/><br/>';
        
        Object obj = JSON.deserializeUntyped(job.serializedJob__c);   
        body += '<b><u>Payload</u>: </b>' + String.valueOf(obj).substringBetween('=', ', event');     
        return body;
    }
}