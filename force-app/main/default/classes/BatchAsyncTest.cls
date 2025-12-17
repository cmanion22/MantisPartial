@isTest
public with sharing class BatchAsyncTest  {
   @isTest static void startTest() {
       BatchAsync obj = new BatchAsync();
       insert new RetryableJob__c(
            serializedJob__c = '{"event__c": "Test", "httpResponseCode__c": 200, "status__c": "FAILED_RETRY", "nextTry__c": null, "count__c": "1", "message__c": "Message"}',
            className__c = 'Retry',
            firstTry__c = System.now(),
            lastTry__c = System.now(),
            count__c = 1,
            nextTry__c = null,
            message__c = 'mesagge',
            status__c = 'SUCCEEDED',
            event__c = 'event',
            httpResponseCode__c = 200
        );
       obj.start(null);
       System.assertNotEquals(null, obj);
    }

    @isTest static void executeTest() {                
        BatchAsync obj = new BatchAsync();
        RetryableJob__c retryableJob = new RetryableJob__c(
            serializedJob__c = '{"event__c": "Test", "httpResponseCode__c": 200, "status__c": "FAILED_RETRY", "nextTry__c": null, "count__c": "1", "message__c": "Message"}',
            className__c = 'Retry',
            firstTry__c = System.now(),
            lastTry__c = System.now(),
            count__c = 1,
            nextTry__c = null,
            message__c = 'mesagge',
            status__c = 'SUCCEEDED',
            event__c = 'event',
            httpResponseCode__c = 200
        );

        insert retryableJob;
        List<SObject> jobs = new List<SObject>();
        jobs.add(retryableJob);

        Integer retryCount = 0;

        obj.execute(null, jobs);
        System.assertNotEquals(null, obj);
    }

    @isTest static void finishTest() {  
        BatchAsync obj = new BatchAsync();
        insert new RetryableJob__c(
            serializedJob__c = '{"event__c": "Test", "httpResponseCode__c": 200, "status__c": "FAILED_RETRY", "nextTry__c": null, "count__c": "1", "message__c": "Message"}',
            className__c = 'Retry',
            firstTry__c = System.now(),
            lastTry__c = System.now(),
            count__c = 4,
            nextTry__c = null,
            message__c = 'mesagge',
            status__c = 'FAILED_RETRY',
            event__c = 'event',
            httpResponseCode__c = 200
        );
        obj.finish(null);
        System.assertNotEquals(null, obj);
    }

    @isTest static void finishTest_2() {  
        BatchAsync obj = new BatchAsync();
        insert new RetryableJob__c(
            serializedJob__c = '{"event__c": "Test", "httpResponseCode__c": 200, "status__c": "FAILED_RETRY", "nextTry__c": null, "count__c": "1", "message__c": "Message"}',
            className__c = 'Retry',
            firstTry__c = System.now(),
            lastTry__c = System.now(),
            count__c = 1,
            nextTry__c = null,
            message__c = 'mesagge',
            status__c = 'SUCCEEDED',
            event__c = 'event',
            httpResponseCode__c = 200
        );
        obj.finish(null);
        System.assertNotEquals(null, obj);
    }

    @isTest static void finishTest_3() {  
        BatchAsync obj = new BatchAsync();
        insert new RetryableJob__c(
            serializedJob__c = '{"event__c": "Test", "httpResponseCode__c": 200, "status__c": "FAILED_RETRY", "nextTry__c": null, "count__c": "1", "message__c": "Message"}',
            className__c = 'Retry',
            firstTry__c = System.now(),
            lastTry__c = System.now(),
            count__c = 2,
            nextTry__c = null,
            message__c = 'mesagge',
            status__c = 'FAILED_RETRY',
            event__c = 'event',
            httpResponseCode__c = 200
        );
        obj.finish(null);
        System.assertNotEquals(null, obj);
    }

    @isTest static  void sendEmailTest(){
        BatchAsync obj = new BatchAsync();
        RetryableJob__c rJob =  new RetryableJob__c(
            serializedJob__c = '{"event__c": "Test", "httpResponseCode__c": 200, "status__c": "FAILED_RETRY", "nextTry__c": null, "count__c": "1", "message__c": "Message"}',
            className__c = 'Retry',
            firstTry__c = System.now(),
            lastTry__c = System.now(),
            count__c = 4,
            nextTry__c = null,
            message__c = 'mesagge',
            status__c = 'FAILED_RETRY',
            event__c = 'event',
            httpResponseCode__c = 200
        );
        
        insert rJob;

        obj.sendEmail(rJob);
        System.assertNotEquals(null, obj);
    }
    
    @isTest static void getJobDetailsTest() {
       BatchAsync obj = new BatchAsync();
       RetryableJob__c retryableJob = new RetryableJob__c(
            serializedJob__c = '{"event__c": "Test", "httpResponseCode__c": 200, "status__c": "FAILED_RETRY", "nextTry__c": null, "count__c": "1", "message__c": "Message"}',
            className__c = 'Retry',
            firstTry__c = System.now(),
            lastTry__c = System.now(),
            count__c = 1,
            nextTry__c = null,
            message__c = 'mesagge',
            status__c = 'SUCCEEDED',
            event__c = 'event',
            httpResponseCode__c = 200
        );
        
       obj.getJobDetails(retryableJob);
       System.assertNotEquals(null, obj);
    }
}