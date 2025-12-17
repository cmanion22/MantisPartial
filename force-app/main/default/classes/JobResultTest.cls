@isTest
public class JobResultTest {
     @isTest static void maximumRetries(){
        String message = 'Retry Message Test';
        String event = 'Retry Event';
        Integer responseCode = 900;
        JobResult result = JobResult.maximumRetries(message, event, responseCode);
    
        System.assertEquals(Retry.Status.MAX_RETRIES, result.status); 
    }
}