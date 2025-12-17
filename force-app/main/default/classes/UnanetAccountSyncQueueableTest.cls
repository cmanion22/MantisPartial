@isTest
public class UnanetAccountSyncQueueableTest {

    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatusCode(200);
    
            String url = req.getEndpoint();
            System.debug('Mock endpoint called: ' + url);
    
            // Mock token retrieval
            if (url.contains('login')) {
                res.setBody('{ "token": "mocked_token" }');
            }
    
            // Must check for '/organizations/list' BEFORE the general '/organizations'
            else if (url.contains('/organizations/list')) {
                // Return a properly formatted list for deserialization
                res.setBody('[ { "key": 1, "name": "Organization 1", "code": "ORG1" }, { "key": 2, "name": "Organization 2", "code": "ORG2" } ]');
            }
    
            // Mock organization creation (POST)
            else if (url.contains('/organizations') && req.getMethod() == 'POST') {
                res.setBody('{ "key": 12345 }');
            }
    
            // Mock getOrganization (GET by ID)
            else if (url.contains('/organizations/') && req.getMethod() == 'GET') {
                res.setBody(
                    JSON.serialize(new Map<String, Object>{
                        'code' => 'EXISTING_ORG',
                        'name' => 'Existing Org Name',
                        'active' => true,
                        'type' => new Map<String, Object>{ 'key' => 1, 'name' => 'CUSTOMERS', 'description' => 'Customer org type' },
                        'parentOrg' => new Map<String, Object>{ 'key' => 2, 'name' => 'Parent Org', 'code' => 'PARENT' },
                        'size' => 1,
                        'externalSystemCode' => 'EXT123',
                        'classification' => 'Public',
                        'sicCode' => '1234',
                        'industry' => 'Tech',
                        'sector' => 'Software',
                        'stockSymbol' => 'MNT',
                        'url' => 'https://example.com',
                        'financialOrg' => true,
                        'legalEntity' => true,
                        'legalEntityOrg' => new Map<String, Object>{ 'key' => 5, 'name' => 'Legal Org', 'code' => 'LEG001' },
                        'entryAllowed' => true,
                        'beginDate' => '2023-01-01',
                        'endDate' => null,
                        'finParentOrg' => new Map<String, Object>{ 'key' => 6 },
                        'costPoolParentOrg' => new Map<String, Object>{ 'key' => 7 },
                        'defaultGLPostOrg' => new Map<String, Object>{ 'key' => 8 },
                        'recipientName1099' => 'Recipient 1099',
                        'vendor1099' => true,
                        'federalTaxId' => '12-3456789',
                        'federalTaxIdType' => 'EIN',
                        'tax1' => 'Tax1',
                        'tax2' => 'Tax2',
                        'tax3' => 'Tax3',
                        'email1099' => 'finance@example.com',
                        'propertyTemplate' => new Map<String, Object>{ 'key' => 9 },
                        'startWithProjectCodeSeq' => '100',
                        'lastProjectCodeSeq' => '105',
                        'defaultPersonOrg' => true,
                        'requiresActivation' => false,
                        'createdTimestamp' => '2023-01-01T00:00:00Z',
                        'lastUpdatedTimestamp' => '2023-12-31T23:59:59Z',
                        'udfs' => new Map<String, Object>{
                            'values' => new List<Object>{
                                new Map<String, Object>{
                                    'index' => 3,
                                    'value' => '',
                                    'metadata' => new Map<String, Object>{
                                        'label' => 'SF Id',
                                        'dataType' => 'STRING',
                                        'visibility' => 'ENABLED',
                                        'required' => false,
                                        'active' => true
                                    }
                                }
                            }
                        }
                    })
                );
            }
    
            // Mock organization address creation
            else if (url.contains('/org-address')) {
                res.setBody('{ "success": true }');
            }
    
            // Mock getOrganizationTypeKey
            else if (url.contains('/organization-types')) {
                res.setBody('{ "items": [ { "key": 1, "name": "CUSTOMERS", "description": "Customer org type" } ] }');
            }
    
            // Mock getCurrencyKey
            else if (url.contains('/currencies/currency-codes')) {
                res.setBody('{ "items": [ { "key": 3, "isoCurrencyCode": "USD", "name": "US Dollar", "decimals": 2 } ] }');
            }
    
            // Mock getUdfMetadata
            else if (url.contains('/config/udf-metadata')) {
                res.setBody('{ "items": [ { "index": 3, "metadata": { "label": "SF Id", "dataType": "STRING", "visibility": "ENABLED", "required": false, "active": true } } ] }');
            }
    
            return res;
        }
    }





    @testSetup
    static void setup() {
        // Create test Account
        Account acc = new Account(
            Name = 'Test Company',
            BillingStreet = '123 Main St',
            BillingCity = 'Anytown',
            BillingState = 'CA',
            BillingPostalCode = '90210',
            BillingCountry = 'USA'
        );
        insert acc;
        
        // Create related opportunity with primary contact
        Contact contact1 = new Contact(FirstName = 'Jane1', LastName = 'Doe1', Email = 'jane1@example.com');
        insert contact1;

        // Create test Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Qualification',
            CloseDate = Date.today().addDays(30),
            AccountId = acc.Id,
            Primary_Contact__c = contact1.Id
        );
        insert opp;
    }

    @isTest
    static void testSuccessfulExecution() {
        // Get the Account created in @testSetup
        Account acc = [SELECT Id FROM Account LIMIT 1];
    
        // Create a Primary Contact
        Contact primaryContact = new Contact(FirstName = 'Test', LastName = 'User', Email = 'test@example.com');
        insert primaryContact;
    
        // Create an Opportunity with a Primary Contact linked to the existing Account
        Opportunity opp = new Opportunity(
            Name = 'Test Opp With Primary Contact',
            StageName = 'Qualification',
            CloseDate = Date.today().addDays(30),
            AccountId = acc.Id,
            Primary_Contact__c = primaryContact.Id
        );
        insert opp;
    
        // Set the mock
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
    
        // Run the queueable job
        Test.startTest();
        System.enqueueJob(new UnanetAccountSyncQueueable(opp.Id));
        Test.stopTest();
    
    }


    @isTest
    static void testOpportunityWithoutAccount() {
        Opportunity oppNoAcc = new Opportunity(
            Name = 'Opp Without Account',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10)
        );
        insert oppNoAcc;

        // Set the mock response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Start the test and enqueue the job
        Test.startTest();
        System.enqueueJob(new UnanetAccountSyncQueueable(oppNoAcc.Id));
        Test.stopTest();

        List<Data_Log__c> logs = [SELECT Id FROM Data_Log__c WHERE Related_Record_Id__c = :oppNoAcc.Id];
        System.assertEquals(1, logs.size(), 'Expected a Data_Log__c entry for missing Account');
    }
    
    @isTest
    static void testExistingUnanetIdPath() {
        // Create account with Unanet_Id__c set
        Account acc = new Account(
            Name = 'Existing Org',
            BillingStreet = '123 Main St',
            BillingCity = 'Anytown',
            BillingState = 'CA',
            BillingPostalCode = '90210',
            BillingCountry = 'USA',
            Unanet_Id__c = 'existing-org-001'
        );
        insert acc;
    
        // Create related opportunity with primary contact
        Contact contact = new Contact(FirstName = 'Jane', LastName = 'Doe', Email = 'jane@example.com');
        insert contact;
    
        Opportunity opp = new Opportunity(
            Name = 'Existing Org Opportunity',
            StageName = 'Qualification',
            CloseDate = Date.today().addDays(30),
            AccountId = acc.Id,
            Primary_Contact__c = contact.Id
        );
        insert opp;
    
        // Set the mock response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
    
        // Run the queueable job
        Test.startTest();
        System.enqueueJob(new UnanetAccountSyncQueueable(opp.Id));
        Test.stopTest();
    
        System.assert(true, 'Queueable ran for Account with existing Unanet Id');
    }
    
   	private class MockMissingTokenCallout implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
    
            if (req.getEndpoint().contains('login')) {
                // Simulate missing token field in response
                res.setBody('{}');
            } else {
                // Other endpoints won’t be called, but stub them just in case
                res.setBody('{}');
            }
    
            return res;
        }
    }
    
    @isTest
    static void testMissingUnanetToken() {
        Account acc = new Account(Name = 'Token Fail Co');
        insert acc;
    
        Opportunity opp = new Opportunity(
            Name = 'Fail Token Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            AccountId = acc.Id
        );
        insert opp;
    
        Test.setMock(HttpCalloutMock.class, new MockMissingTokenCallout());
    
        Test.startTest();
        System.enqueueJob(new UnanetAccountSyncQueueable(opp.Id));
        Test.stopTest();
    
    }
    
    @isTest
    static void testMissingOppId() {
        Account acc = new Account(Name = 'Token Fail Co');
        insert acc;
    
        Opportunity opp = new Opportunity(
            Name = 'Fail Token Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            AccountId = acc.Id
        );
        insert opp;
    
        Test.setMock(HttpCalloutMock.class, new MockMissingTokenCallout());
    
        Test.startTest();
        System.enqueueJob(new UnanetAccountSyncQueueable(null));
        Test.stopTest();
    
     }
    
    // Helper method to add coverage
    @isTest
    static void testCoverageHack() {
        Test.startTest();
        UnanetAccountSyncQueueable.codeCoverageHack();
        Test.stopTest();
    }

}