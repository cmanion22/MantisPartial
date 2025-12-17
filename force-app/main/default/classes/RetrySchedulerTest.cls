@isTest
public class RetrySchedulerTest {
    @isTest(SeeAllData=true) static void scheduleTest() {
        Integer minutesFromNow = 5;
        String event = 'unit test event';
        String result = RetryScheduler.schedule(minutesFromNow, event);  
        System.assert(result != null); 
    }
}