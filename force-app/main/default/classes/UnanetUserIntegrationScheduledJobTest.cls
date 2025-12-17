@isTest
private class UnanetUserIntegrationScheduledJobTest {

    @isTest
    static void testScheduledJobExecution() {
        // Define the cron expression for scheduling the job (midnight every day)
        String cronExp = '0 0 0 * * ?';

        // Start the test context
        Test.startTest();

        // Create an instance of the scheduled class
        UnanetUserIntegrationScheduledJob scheduler = new UnanetUserIntegrationScheduledJob();

        // Schedule the job using the instance
        String jobId = System.schedule('Test Unanet User Integration Scheduled Job', cronExp, scheduler);

        // Stop the test context
        Test.stopTest();

        // Query the CronTrigger to verify that the job has been scheduled
        CronTrigger[] jobs = [SELECT Id, CronExpression, TimesTriggered, NextFireTime 
                              FROM CronTrigger WHERE CronJobDetail.Name = 'Test Unanet User Integration Scheduled Job'];

        // Assert that the job is scheduled
        System.assertNotEquals(0, jobs.size(), 'Job should be scheduled');
        System.assertEquals(cronExp, jobs[0].CronExpression, 'Cron expression should match');
        System.assertEquals(0, jobs[0].TimesTriggered, 'Job should not have run yet');
    }
}