public class JobResult {
    public Retry.Status status {get; set;}
    public String message {get; set;}
    public String event { get; set; }
    public integer responseCode { get; set; }
    
    public JobResult(Retry.Status status, String message, String event, Integer responseCode){
        System.debug('JobResultConstructor-->status-->' + status + '| message-->' + message + '| event -->' + event + '| responseCode-->' + responseCode);
        this.status = status;
        this.message = message;
        this.event = event;
        this.responseCode = responseCode;
    }
    
    public static JobResult maximumRetries(String message, String event, Integer responseCode){
        System.debug('JobResult-->maximumRetries-->message' + message);
        return new JobResult(Retry.Status.MAX_RETRIES, message.abbreviate(255), event, responseCode);
    }
}