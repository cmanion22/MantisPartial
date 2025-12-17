public abstract class Retry implements Queueable, Database.AllowsCallouts {
    public enum Status {
        MAX_RETRIES, FAILED_RETRY, SUCCEEDED, UNAUTHORISED, INTERNAL_SERVER_ERROR, BAD_REQUEST, FORBIDDEN,
        NOT_FOUND, SERVICE_UNAVAILABLE
    }
    
    protected abstract JobResult startJob();

    protected Datetime firstExecution;
    protected Integer retryCount = 0;
    private Datetime nextRetry;
    
    public void execute(QueueableContext context) 
    {        
        firstExecution = System.now();
        JobResult result = startJob();
        System.debug('Retry-->execute-->result-->'+ result);        
        
        if(result.status != Retry.Status.SUCCEEDED) 
        { 
            if(Constants.jobRetryEnabled)
            {
                System.debug('Retry-->execute-->jobRetryEnabled' + Constants.jobRetryEnabled);     
                System.debug('Retry-->execute-->Constants.retryScheduleInMinutes[retryCount]--> ' + Constants.retryScheduleInMinutes[retryCount]);               
                RetryScheduler.schedule(Constants.retryScheduleInMinutes[retryCount], result.event);
                insertJob(result);  
            }
            else
            {
                System.debug('Retry-->execute-->jobRetryEnabled' + Constants.jobRetryEnabled);            
            }         
        }
    }

    public JobResult retry(String event, Integer responseCode) {
        retryCount++;
        System.debug('Retry-->retry-->retryCount-->'+ retryCount);
        nextRetry = isLastTry() ? null : firstExecution.addMinutes(Constants.retryScheduleInMinutes.get(retryCount));                
        return isLastTry() ? JobResult.maximumRetries(startJob().message, event, responseCode) : startJob();    
    }
        
    public void insertJob(JobResult result) {
        System.debug('Retry-->insertJob-->result-->' + result);
        insert new RetryableJob__c(
            serializedJob__c = JSON.serialize(this),
            className__c = String.valueOf(this).split(':')[0],
            firstTry__c = System.now(),
            lastTry__c = System.now(),
            count__c = 1,
            nextTry__c = result.status == Retry.Status.FAILED_RETRY
                    ? System.now().addMinutes(Constants.retryScheduleInMinutes.get(0))
                    : null,
            message__c = result.message.abbreviate(255),
            status__c = result.status.name(),
            event__c = result.event,
            httpResponseCode__c = result.responseCode
        );
    }    

    public Datetime getNextTry() {
        System.debug('Retry-->getNextTry-->nextRetry-->' + nextRetry);
        return nextRetry;
    }

    public Boolean isLastTry() {
        Boolean isLast = (retryCount >= Constants.retryScheduleInMinutes.size()); 
        System.debug('Retry-->isLastTry-->isLast-->' + isLast);       
        return isLast;
    }
}