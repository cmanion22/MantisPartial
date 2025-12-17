public with sharing class RetryScheduler {
    public static String schedule(Integer minutesFromNow, String event) {
        System.debug('RetryScheduler-->scheduleNewBatch-->minutesFromNow-->' + minutesFromNow + '| event-->' + event);        
        BatchAsync batchJob = new BatchAsync();
        String jobDescription = Constants.jobPrefix + event + '@' + System.now() + '#' + Utils.generateRandomString(8);
        return System.scheduleBatch(batchJob, jobDescription, minutesFromNow);
    }
}