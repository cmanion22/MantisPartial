@isTest
public class HttpHelperAsyncTest {
    @isTest(SeeAllData=true) static void testQueueable() {
        // query for test data to pass to queueable class
        //Id parentId = [select Id from account where name = 'Parent'][0].Id;
        //List<Account> accounts = [select Id, name from account where name like 'Test Account%'];
        // Create our Queueable instance
        Test.setMock(HttpCalloutMock.class, new HttpEmexCalloutMock(200, 'OK', '{success:true}'));
        HttpHelperAsync asyncHttpCall = new HttpHelperAsync(ESBController.getESBUrl(), 'POST', '{"example":"test"}');
        // startTest/stopTest block to force async processes to run
        Test.startTest();        
        System.enqueueJob(asyncHttpCall);
        Test.stopTest();        
        // Validate the job ran. Check if record have correct parentId now
        //System.assertEquals(100, [select count() from account where parentId = :parentId]);
    }
    
}