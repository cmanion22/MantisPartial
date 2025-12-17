@isTest
public class FetchPerformSectionsInvocableTest {
    // Helper method to create mock custom setting data
    private static void createMockCustomSetting(Boolean isSandbox) {
        Perform_Integration_Settings__c settings = new Perform_Integration_Settings__c();
        settings.Name = isSandbox ? 'Companies Staging' : 'Companies Production';
        settings.Bearer_Token__c = 'mockBearerToken';
        insert settings;
    }

    // Mock data to be passed into the queueable job
    private static List<ApiResponseSectionWrapper> getMockApiResponseSections() {
        List<ApiResponseSectionWrapper> sections = new List<ApiResponseSectionWrapper>();

        ApiResponseSectionWrapper sec1 = new ApiResponseSectionWrapper();
        sec1.id = '123456';
        sec1.name = 'Section 1';
        sec1.company_id = '1234';
        sec1.property_id = '12345'; // This matches the property_uuid__c field in Property__c
        sec1.code = '10A';
        sec1.total_area = '840.0';
        sec1.asset_type = 'Roof';
        sec1.classification_name = 'Vinyl';
        sec1.deleted_at = null;
        sections.add(sec1);

        ApiResponseSectionWrapper sec2 = new ApiResponseSectionWrapper();
        sec2.id = '213';
        sec2.name = 'Section 2';
        sec2.company_id = '1234';
        sec2.property_id = '12345'; // This also matches
        sec2.code = '10A';
        sec2.total_area = '840.0';
        sec2.asset_type = 'Roof';
        sec2.classification_name = 'Vinyl';
        sec2.deleted_at = null;
        sections.add(sec2);

        return sections;
    }

    @isTest
    public static void testFetchPerformSectionsInvocableSandbox() {
        // Set the environment to sandbox by setting Utils.isSandbox to true
        Utils.isSandbox = true;

        // Create Test Account
        Account testAcc1 = new Account(
            Name = 'Test123',
            company_uuid__c = '1234',
            Industry  = 'Finance',
            Work_Orders_Enabled__c = true
        );
        insert testAcc1;

        // Create Test Property Record (Make sure property_uuid__c matches property_id)
        Property__c prop1 = new Property__c(
            property_uuid__c = '12345',  // This value must match the property_id in ApiResponseSectionWrapper
            company_uuid__c  = '1234',
            Name = 'testProperty'
        );
        insert prop1;

        // Create Test Section Record
        Section__c sec1 = new Section__c(
            company_uuid__c = '1234',
            property_uuid__c = '12345',
            section_uuid__c = '123456'
        );
        insert sec1;

        // Setup mock data (custom settings) before Test.startTest()
        createMockCustomSetting(true); // Set up for sandbox environment

        // Set the mock response body for the HTTP callout (simulating a successful callout)
        MockHttpResponseGenerator.mockResponseBody = '{"data":[{"id":"123","name":"Section 1","company_id":"1234","property_id":"12345","code":"10A","total_area":"80.4","asset_type":"Roof","classification_name":"Single-Ply","deleted_at":null}],"pagination":{"next_url":null,"count":1,"pages":1,"page":1,"recordLimit":1000,"itemsIn":1}}';

        // Mock the HTTP callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Create a list of property UUIDs to be passed to the invocable method
        List<String> propertyUuids = new List<String>{'12345'};  // Ensure property UUID matches here

        // Start test context (isolating the test execution)
        Test.startTest();

        // Call the invocable method (this will simulate the callout)
        FetchPerformSectionsInvocable.fetchPerformSections(propertyUuids);

        // Stop test context (marks the end of the test)
        Test.stopTest();

        // Now pass the mock sections data to the queueable job
        List<ApiResponseSectionWrapper> mockSections = getMockApiResponseSections();

        // Create the queueable job
        ProcessSectionsQueueable queueableJob = new ProcessSectionsQueueable(mockSections);

        // Enqueue the job for processing
        Id jobId = System.enqueueJob(queueableJob);

        // Optional: Add some assertions to verify job execution, record updates, etc.
        // System.assertNotEquals(jobId, null, 'Job should be queued successfully');
    }

    @isTest
    public static void testFetchPerformSectionsInvocableProduction() {
        // Set the environment to production by setting Utils.isSandbox to false
        Utils.isSandbox = false;

        // Create Test Account
        Account testAcc1 = new Account(
            Name = 'Test123',
            company_uuid__c = '1234',
            Industry  = 'Finance',
            Work_Orders_Enabled__c = true
        );
        insert testAcc1;

        // Create Test Property Record (Make sure property_uuid__c matches property_id)
        Property__c prop1 = new Property__c(
            property_uuid__c = '12345',  // This value must match the property_id in ApiResponseSectionWrapper
            company_uuid__c  = '1234',
            Name = 'testProperty'
        );
        insert prop1;

        // Create Test Section Record
        Section__c sec1 = new Section__c(
            company_uuid__c = '1234',
            property_uuid__c = '12345',
            section_uuid__c = '123456'
        );
        insert sec1;

        // Setup mock data (custom settings) before Test.startTest()
        createMockCustomSetting(false); // Set up for production environment

        // Set the mock response body for the HTTP callout (simulating a successful callout)
        MockHttpResponseGenerator.mockResponseBody = '{"data":[{"id":"123","name":"Section 1","company_id":"1234","property_id":"12345","code":"10A","total_area":"80.4","asset_type":"Roof","classification_name":"Single-Ply","deleted_at":null}],"pagination":{"next_url":null,"count":1,"pages":1,"page":1,"recordLimit":1000,"itemsIn":1}}';

        // Mock the HTTP callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Create a list of property UUIDs to be passed to the invocable method
        List<String> propertyUuids = new List<String>{'12345'};  // Ensure property UUID matches here

        // Start test context (isolating the test execution)
        Test.startTest();

        // Call the invocable method (this will simulate the callout)
        FetchPerformSectionsInvocable.fetchPerformSections(propertyUuids);

        // Stop test context (marks the end of the test)
        Test.stopTest();

        // Now pass the mock sections data to the queueable job
        List<ApiResponseSectionWrapper> mockSections = getMockApiResponseSections();

        // Create the queueable job
        ProcessSectionsQueueable queueableJob = new ProcessSectionsQueueable(mockSections);

        // Enqueue the job for processing
        Id jobId = System.enqueueJob(queueableJob);

        // Optional: Add some assertions to verify job execution, record updates, etc.
        // System.assertNotEquals(jobId, null, 'Job should be queued successfully');
    }
}