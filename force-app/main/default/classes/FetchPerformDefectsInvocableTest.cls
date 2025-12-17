@isTest
public class FetchPerformDefectsInvocableTest {
    // Helper method to create mock custom setting data
    private static void createMockCustomSetting(Boolean isSandbox) {
        Perform_Integration_Settings__c settings = new Perform_Integration_Settings__c();
        settings.Name = isSandbox ? 'Companies Staging' : 'Companies Production';
        settings.Bearer_Token__c = 'mockBearerToken';
        insert settings;
    }
    
    // Mock data to be passed into the queueable job
    private static List<ApiResponseDefectWrapper> getMockApiResponseDefects() {
        List<ApiResponseDefectWrapper> defects = new List<ApiResponseDefectWrapper>();
        
        ApiResponseDefectWrapper def1 = new ApiResponseDefectWrapper();
        def1.id = '1234567';
        def1.company_id = '1234';
        def1.property_id = '12345'; // This matches the property_uuid__c field in Property__c
        def1.section_id = '123456';
        def1.survey_id = 'e6aa4f04';
        def1.asset_type = 'Roof';
        def1.asset_material_type = 'Single-Ply';
        def1.building_name = 'bld';
        def1.section_code = '1A';
        def1.label = 'test defect';
        def1.uom = 'EA';
        def1.severity_title = 'See notes';
        def1.quantity = 1;
        def1.status = 'proposed';
        def1.recommendation = 'Reinstall loose access panel';
        def1.deleted_at = null;
        def1.name = 'defect 1';
        defects.add(def1);

        return defects;
    }
    
    @isTest
    public static void testFetchPerformDefectsInvocableSandbox() {
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
            property_uuid__c = '12345',  // This value must match the property_id in ApiResponseDefectWrapper
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

        // Create Test Defect Record
        Defect__c def1 = new Defect__c(
            Name = 'Test Defect',
            company_uuid__c = '1234',
            property_uuid__c  = '12345',
            section_uuid__c = '123456',
            defect_uuid__c = '1234567'
        );
        insert def1;

        // Setup mock data (custom settings) before Test.startTest()
        createMockCustomSetting(true); // Set up for sandbox environment

        // Set the mock response body for the HTTP callout (simulating a successful callout)
        MockHttpResponseGenerator.mockResponseBody = '{"data":[{"id":"123","name":"Defect 1","company_id":"1234","property_id":"12345","section_id":"123456","survey_id":"e6aa4f04","asset_type":"Roof","asset_material_type":"Single-Ply","building_name":"bld","section_code":"1A","label":"test defect","uom":"EA","severity_title":"See notes","quantity":1,"status":"proposed","recommendation":"Reinstall loose access panel","deleted_at":null}],"pagination":{"next_url":null,"count":1,"pages":1,"page":1,"recordLimit":1000,"itemsIn":1}}';

        // Mock the HTTP callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Create a list of defect UUIDs to be passed to the invocable method
        List<String> defectUuids = new List<String>{'1234567'};  // Ensure defect UUID matches here

        // Start test context (isolating the test execution)
        Test.startTest();

        // Call the invocable method (this will simulate the callout)
        FetchPerformDefectsInvocable.fetchPerformDefects(defectUuids);

        // Stop test context (marks the end of the test)
        Test.stopTest();

        // Now pass the mock defects data to the queueable job
        List<ApiResponseDefectWrapper> mockDefects = getMockApiResponseDefects();

        // Create the queueable job
        ProcessDefectsQueueable queueableJob = new ProcessDefectsQueueable(mockDefects);

        // Enqueue the job for processing
        Id jobId = System.enqueueJob(queueableJob);

        // Optional: Add some assertions to verify job execution, record updates, etc.
        // System.assertNotEquals(jobId, null, 'Job should be queued successfully');
    }

    @isTest
    public static void testFetchPerformDefectsInvocableProduction() {
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
            property_uuid__c = '12345',  // This value must match the property_id in ApiResponseDefectWrapper
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

        // Create Test Defect Record
        Defect__c def1 = new Defect__c(
            Name = 'Test Defect',
            company_uuid__c = '1234',
            property_uuid__c  = '12345',
            section_uuid__c = '123456',
            defect_uuid__c = '1234567'
        );
        insert def1;

        // Setup mock data (custom settings) before Test.startTest()
        createMockCustomSetting(false); // Set up for production environment

        // Set the mock response body for the HTTP callout (simulating a successful callout)
        MockHttpResponseGenerator.mockResponseBody = '{"data":[{"id":"123","name":"Defect 1","company_id":"1234","property_id":"12345","section_id":"123456","survey_id":"e6aa4f04","asset_type":"Roof","asset_material_type":"Single-Ply","building_name":"bld","section_code":"1A","label":"test defect","uom":"EA","severity_title":"See notes","quantity":1,"status":"proposed","recommendation":"Reinstall loose access panel","deleted_at":null}],"pagination":{"next_url":null,"count":1,"pages":1,"page":1,"recordLimit":1000,"itemsIn":1}}';

        // Mock the HTTP callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Create a list of defect UUIDs to be passed to the invocable method
        List<String> defectUuids = new List<String>{'1234567'};  // Ensure defect UUID matches here

        // Start test context (isolating the test execution)
        Test.startTest();

        // Call the invocable method (this will simulate the callout)
        FetchPerformDefectsInvocable.fetchPerformDefects(defectUuids);

        // Stop test context (marks the end of the test)
        Test.stopTest();

        // Now pass the mock defects data to the queueable job
        List<ApiResponseDefectWrapper> mockDefects = getMockApiResponseDefects();

        // Create the queueable job
        ProcessDefectsQueueable queueableJob = new ProcessDefectsQueueable(mockDefects);

        // Enqueue the job for processing
        Id jobId = System.enqueueJob(queueableJob);

        // Optional: Add some assertions to verify job execution, record updates, etc.
        // System.assertNotEquals(jobId, null, 'Job should be queued successfully');
    }
}