@isTest
public class FetchPerformPropertiesInvocableTest {

    // Helper method to create mock custom setting data
    private static void createMockCustomSetting(Boolean isSandbox) {
        Perform_Integration_Settings__c settings = new Perform_Integration_Settings__c();
        settings.Name = isSandbox ? 'Companies Staging' : 'Companies Production';
        settings.Bearer_Token__c = 'mockBearerToken';
        insert settings;
    }

    // Mock data to be passed into the queueable job
    private static List<ApiResponsePropertyWrapper> getMockApiResponseProperties() {
        List<ApiResponsePropertyWrapper> properties = new List<ApiResponsePropertyWrapper>();

        ApiResponsePropertyWrapper property1 = new ApiResponsePropertyWrapper();
        property1.id = '1234';
        property1.name = 'Property 1';
        property1.company_id = '123';
        property1.active = true;
        properties.add(property1);

        ApiResponsePropertyWrapper property2 = new ApiResponsePropertyWrapper();
        property2.id = '213';
        property2.company_id = '123';
        property2.name = 'Property 2';
        property2.active = true;
        properties.add(property2);

        return properties;
    }

    @isTest
    public static void testFetchPerformPropertiesInvocableSandbox() {
        // Set the environment to sandbox by setting Utils.isSandbox to true
        Utils.isSandbox = true;

        // Create Test Account
        Account testAcc1 = new Account(
            Name = 'Test123',
            company_uuid__c = '123',
            Industry  = 'Finance',
            Work_Orders_Enabled__c = true
        );
        insert testAcc1;
        
        // Create Test Property Record
        Property__c prop1 = new Property__c(
            property_uuid__c = '1234',
            company_uuid__c  = '123',
            Name = 'testProperty'
        );
        insert prop1;

        // Setup mock data (custom settings) before Test.startTest()
        createMockCustomSetting(true); // Set up for sandbox environment

        // Set the mock response body for the HTTP callout (simulating a successful callout)
        MockHttpResponseGenerator.mockResponseBody = '{"data":[{"id":"1234","name":"Property 1","company_id":"123","active":true}],"pagination":{"next_url":null,"count":1,"pages":1,"page":1,"recordLimit":1000,"itemsIn":1}}';

        // Mock the HTTP callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Create a list of company UUIDs to be passed to the invocable method
        List<String> companyUuids = new List<String>{'123'};

        // Start test context (isolating the test execution)
        Test.startTest();

        // Call the invocable method (this will simulate the callout)
        FetchPerformPropertiesInvocable.fetchPerformProperties(companyUuids);

        // Stop test context (marks the end of the test)
        Test.stopTest();

        // Now pass the mock properties data to the queueable job
        List<ApiResponsePropertyWrapper> mockProperties = getMockApiResponseProperties();

        // Create the queueable job
        ProcessPropertiesQueueable queueableJob = new ProcessPropertiesQueueable(mockProperties, companyUuids[0]);

        // Enqueue the job for processing
        Id jobId = System.enqueueJob(queueableJob);

        // Optional: Add assertions to verify job execution, record updates, etc.
        System.assertNotEquals(jobId, null, 'Job should be queued successfully');
    }

    @isTest
    public static void testFetchPerformPropertiesInvocableProduction() {
        // Set the environment to production by setting Utils.isSandbox to false
        Utils.isSandbox = false;

        // Create Test Account
        Account testAcc1 = new Account(
            Name = 'Test123',
            company_uuid__c = '123',
            Industry  = 'Finance',
            Work_Orders_Enabled__c = true
        );
        insert testAcc1;
        
        // Create Test Property Record
        Property__c prop1 = new Property__c(
            property_uuid__c = '1234',
            company_uuid__c  = '123',
            Name = 'testProperty'
        );
        insert prop1;

        // Setup mock data (custom settings) before Test.startTest()
        createMockCustomSetting(false); // Set up for production environment

        // Set the mock response body for the HTTP callout (simulating a successful callout)
        MockHttpResponseGenerator.mockResponseBody = '{"data":[{"id":"1234","name":"Property 1","company_id":"123","active":true}],"pagination":{"next_url":null,"count":1,"pages":1,"page":1,"recordLimit":1000,"itemsIn":1}}';

        // Mock the HTTP callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Create a list of company UUIDs to be passed to the invocable method
        List<String> companyUuids = new List<String>{'123'};

        // Start test context (isolating the test execution)
        Test.startTest();

        // Call the invocable method (this will simulate the callout)
        FetchPerformPropertiesInvocable.fetchPerformProperties(companyUuids);

        // Stop test context (marks the end of the test)
        Test.stopTest();

        // Now pass the mock properties data to the queueable job
        List<ApiResponsePropertyWrapper> mockProperties = getMockApiResponseProperties();

        // Create the queueable job
        ProcessPropertiesQueueable queueableJob = new ProcessPropertiesQueueable(mockProperties, companyUuids[0]);

        // Enqueue the job for processing
        Id jobId = System.enqueueJob(queueableJob);

        // Optional: Add assertions to verify job execution, record updates, etc.
        // System.assertNotEquals(jobId, null, 'Job should be queued successfully');
    }
}