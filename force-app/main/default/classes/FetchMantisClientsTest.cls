@isTest
public class FetchMantisClientsTest {

    // Helper method to create mock custom setting data
    private static void createMockCustomSetting(Boolean isSandbox) {
        Perform_Integration_Settings__c settings = new Perform_Integration_Settings__c();
        settings.Name = isSandbox ? 'Companies Staging' : 'Companies Production';
        settings.Bearer_Token__c = 'mockBearerToken';
        insert settings;
    }

    // Mock data to be passed into the queueable job
    private static Map<String, MantisCompany> getMockMantisCompanies() {
        Map<String, MantisCompany> companies = new Map<String, MantisCompany>();

        MantisCompany mc1 = new MantisCompany();
        mc1.id = '1';
        mc1.name = 'Company 1';
        mc1.work_orders_enabled = true;
        companies.put(mc1.id, mc1);

        MantisCompany mc2 = new MantisCompany();
        mc2.id = '2';
        mc2.name = 'Company 2';
        mc2.work_orders_enabled = false;
        companies.put(mc2.id, mc2);

        return companies;
    }

    @isTest
    public static void testProcessMantisClientsQueueable() {
        // Create Test Accounts
        Account testAcc1 = new Account(
            Name = 'Test123',
            company_uuid__c = '1',
            Industry  = 'Finance',
            Work_Orders_Enabled__c = true
        );
        insert testAcc1;
        
        Account testAcc2 = new Account(
            Name = 'Test1234',
            Industry  = 'Finance',
            Work_Orders_Enabled__c = true
        );
        insert testAcc2;
        
        // Setup mock data (custom settings) before Test.startTest()
        createMockCustomSetting(true); // Assuming we're testing the sandbox environment

        // Set the mock response body for the HTTP callout (use static variable)
        // Simulating the last page (currentPage >= totalPages)
        MockHttpResponseGenerator.mockResponseBody = '{"data":[{"id":"1","name":"Company 1","work_orders_enabled":false}],"pagination":{"next_url":null,"count":1,"pages":1,"page":1,"recordLimit":1000,"itemsIn":1}}';

        // Mock the HTTP callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Start test context (isolating the test execution)
        Test.startTest();

        // Call the future method (this will simulate the callout)
        FetchMantisClients.makeAccountGetCallout();  // The callout will be isolated

        // Stop test context (marks the end of the test)
        Test.stopTest();

        // Now pass the mock companies data to the queueable job
        Map<String, MantisCompany> mockCompanies = getMockMantisCompanies();
        
        // Create the queueable job
        ProcessMantisClientsQueueable queueableJob = new ProcessMantisClientsQueueable(mockCompanies);
        
        // Enqueue the job for processing
        Id jobId = System.enqueueJob(queueableJob);

        // Optional: Add some assertions to verify job execution, record updates, etc.
        // System.assertNotEquals(jobId, null, 'Job should be queued successfully');
    }

    @isTest
    public static void testFetchMantisClientsInProduction() {
        // Setup mock data for production environment
        createMockCustomSetting(false); // Setting up the production custom setting (isSandbox = false)

        // Mock response for the production environment
        String prodMockResponse = '{"data":[{"id":"1","name":"Company 1","work_orders_enabled":true}],"pagination":{"next_url":null,"count":1,"pages":1,"page":1,"recordLimit":1000,"itemsIn":1}}';

        // Set the mock response body for the HTTP callout (for production)
        MockHttpResponseGenerator.mockResponseBody = prodMockResponse;
        
        // Mock the HTTP callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Start test context (isolating the test execution)
        Test.startTest();

        // Call the future method for production environment
        FetchMantisClients.makeAccountGetCallout();  // The callout will be isolated

        // Stop test context (marks the end of the test)
        Test.stopTest();

        // Assert that the job was enqueued for production
        //List<AsyncApexJob> jobs = [SELECT Id FROM AsyncApexJob WHERE JobType = 'Queueable'];
        //System.assertEquals(1, jobs.size(), 'Job should be enqueued when in production environment');
    }
}