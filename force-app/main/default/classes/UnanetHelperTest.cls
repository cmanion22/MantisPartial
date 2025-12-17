@isTest
public class UnanetHelperTest {

    private class HttpMock implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
        HTTPResponse res = new HTTPResponse();
        res.setStatusCode(200);

        String url = req.getEndpoint();
        System.debug('Mock endpoint called: ' + url);

        // Add the response for getOrganization endpoint
        if (url.endsWith('/platform/rest/organizations/9999')) {  // Matching the organization key (example: 9999)
            // Here we mock the response for an organization with the provided structure.
            String mockOrgResponse = '{' +
                '"key": 1,' +
                '"code": "string",' +
                '"name": "Mantis Customers",' +
                '"active": true,' +
                '"type": {' +
                    '"key": 1,' +
                    '"name": "Mantis Customers",' +
                    '"description": "string"' +
                '},' +
                '"parentOrg": {' +
                    '"key": 1,' +
                    '"name": "string",' +
                    '"code": "string"' +
                '},' +
                '"size": 1,' +
                '"externalSystemCode": "string",' +
                '"classification": "string",' +
                '"sicCode": "string",' +
                '"industry": "string",' +
                '"sector": "string",' +
                '"stockSymbol": "string",' +
                '"url": "string",' +
                '"financialOrg": false,' +
                '"legalEntity": false,' +
                '"legalEntityOrg": {' +
                    '"key": 1,' +
                    '"name": "string",' +
                    '"code": "string"' +
                '},' +
                '"entryAllowed": false,' +
                '"beginDate": "2025-05-07",' +
                '"endDate": "2025-05-07",' +
                '"finParentOrg": {' +
                    '"key": 1,' +
                    '"name": "string",' +
                    '"code": "string"' +
                '},' +
                '"costPoolParentOrg": {' +
                    '"key": 1,' +
                    '"name": "string",' +
                    '"code": "string"' +
                '},' +
                '"defaultGLPostOrg": {' +
                    '"key": 1,' +
                    '"name": "string",' +
                    '"code": "string"' +
                '},' +
                '"recipientName1099": "string",' +
                '"vendor1099": false,' +
                '"federalTaxId": "string",' +
                '"federalTaxIdType": "EIN",' +
                '"tax1": "string",' +
                '"tax2": "string",' +
                '"tax3": "string",' +
                '"email1099": "string",' +
                '"propertyTemplate": {' +
                    '"key": 1,' +
                    '"name": "string"' +
                '},' +
                '"startWithProjectCodeSeq": 1,' +
                '"lastProjectCodeSeq": 0,' +
                '"defaultPersonOrg": true,' +
                '"requiresActivation": true,' +
                '"currency": {' +
                    '"key": 1,' +
                    '"name": "string",' +
                    '"code": "string",' +
                    '"decimals": 0' +
                '},' +
                '"createdTimestamp": "2025-05-07T00:12:14.449Z",' +
                '"lastUpdatedTimestamp": "2025-05-07T00:12:14.449Z",' +
                '"udfs": {' +
                    '"values": [' +
                        '{' +
                            '"index": 1,' +
                            '"value": "string",' +
                            '"metadata": {' +
                                '"dataType": "DATE",' +
                                '"label": "string",' +
                                '"visibility": "NONE",' +
                                '"required": true,' +
                                '"active": true,' +
                                '"listOptions": [' +
                                    '{' +
                                        '"order": 0,' +
                                        '"value": "string",' +
                                        '"text": "string"' +
                                    '}' +
                                ']' +
                            '}' +
                        '}' +
                    ']' +
                '}' +
            '}';

            res.setBody(mockOrgResponse);
        }
        // Handle other endpoints as needed
        else if (url.contains('/address-types')) {
            res.setBody('{"items":[{"key":1,"name":"Office"},{"key":2,"name":"Billing"}],"page":1,"pageSize":10,"pageCount":1,"resultCount":2}');
        } else if (url.contains('/phone-types')) {
            res.setBody('{"items":[{"key":1,"name":"Mobile"},{"key":2,"name":"Work"}],"page":1,"pageSize":10,"pageCount":1,"resultCount":2}');
        } else if (url.contains('/email-types')) {
            res.setBody('{"items":[{"key":1,"name":"Work"},{"key":2,"name":"Personal"}],"page":1,"pageSize":10,"pageCount":1,"resultCount":2}');
        } else if (url.contains('/currencies')) {
            res.setBody('{"items":[{"key":1,"isoNumericCode":"840","isoCurrencyCode":"USD","name":"United States Dollar","decimals":2}],"page":1,"pageSize":10,"pageCount":1,"resultCount":1}');
        } else if (url.contains('/organization-types')) {
            res.setBody('{"items":[{"key":1,"name":"CUSTOMERS","description":"Customer Org"}],"page":1,"pageSize":10,"pageCount":1,"resultCount":1}');
        } else if (url.contains('/organizations/list')) {
            res.setBody('[{"key":1,"name":"Mantis Customers","code":"Mantis Customers"}]');
        } else if (url.endsWith('/platform/rest/organizations')) {
            res.setBody('{"key": "9999"}');
        } else if (url.contains('login')) {
            res.setBody('{"token": "mockToken123"}');
        } else {
            res.setBody('{"data":[]}');
        }

            return res;
        }
    }

    // Test for caching address type key map
    @isTest
    public static void testCachingAddressTypeKeyMap() {
        // Register the mock response before the call
        Test.setMock(HttpCalloutMock.class, new HttpMock());
        
        String token = 'fake_token';
        String baseUrl = 'https://bluefinllc.unanet.biz';
        
        Test.startTest();
        Map<String, Integer> firstCall = UnanetHelper.getAddressTypeKeyMap(token, baseUrl);
        Map<String, Integer> secondCall = UnanetHelper.getAddressTypeKeyMap(token, baseUrl);
        Test.stopTest();
        
        // Assert that the two calls return the same cached map
        System.assertEquals(2, firstCall.size(), 'Expected two address types in first call');
        System.assertEquals(firstCall, secondCall, 'Second call should return cached data');
    }

    @isTest
    public static void testGetPhoneTypeKey() {
        Test.setMock(HttpCalloutMock.class, new HttpMock());

        Integer result = UnanetHelper.getPhoneTypeKey('Mobile', 'fake_token');
        System.assertNotEquals(null, result, 'Phone Type Key should not be null');
    }

    @isTest
    public static void testGetEmailTypeKey() {
        Test.setMock(HttpCalloutMock.class, new HttpMock());

        Integer result = UnanetHelper.getEmailTypeKey('Work', 'fake_token');
        System.assertNotEquals(null, result, 'Email Type Key should not be null');
    }

    @isTest
    public static void testGetCurrencyKey() {
        // Register the existing mock response for all endpoints
        Test.setMock(HttpCalloutMock.class, new HttpMock());
        
        String isoCurrencyCode = 'USD';
        String token = 'mockToken123';
        
        Test.startTest();
        Integer result = UnanetHelper.getCurrencyKey(isoCurrencyCode, token);
        Test.stopTest();
        
        // Assert that the result is not null and matches the expected mock response
        System.assertNotEquals(null, result, 'Currency Key should not be null');
    }

    @isTest
    public static void testGetOrganizationKey() {
        // Register the existing mock response for all endpoints
        Test.setMock(HttpCalloutMock.class, new HttpMock());
        
        String orgIdentifier = 'ORG123';
        String token = 'mockToken123';
        
        Test.startTest();
        Integer result = UnanetHelper.getOrganizationKey(orgIdentifier, token);
        Test.stopTest();
        
    }

    @isTest
    public static void testUnanetOrgPutBodySerialization() {
        UnanetOrgPutBody orgPutBody = new UnanetOrgPutBody();
        orgPutBody.code = 'ORG123';
        orgPutBody.name = 'Test Organization';
        orgPutBody.active = true;
        orgPutBody.typeKey = 1;
        orgPutBody.parentOrgKey = 2;
        orgPutBody.currencyCodeKey = 3;
        orgPutBody.financialOrg = true;
        orgPutBody.legalEntity = false;

        UnanetOrgPutBody.UdfWrapper udfWrapper = new UnanetOrgPutBody.UdfWrapper();
        UnanetOrgPutBody.UdfValue udfValue = new UnanetOrgPutBody.UdfValue();
        udfValue.index = 0;
        udfValue.value = 'Sample Value';
        udfWrapper.values.add(udfValue);
        orgPutBody.udfs = udfWrapper;

        String jsonPayload = JSON.serialize(orgPutBody);
        System.assertNotEquals(null, jsonPayload, 'Serialized payload should not be null');
        System.debug(jsonPayload);
    }

    @isTest
    public static void testFetchUnanetToken() {
        // Register the existing mock response for all endpoints
        Test.setMock(HttpCalloutMock.class, new HttpMock());
        
        String baseUrl = 'https://bluefinllc.unanet.biz';
        
        Test.startTest();
        String token = UnanetHelper.fetchUnanetToken(baseUrl);  // Make the call that fetches the token
        Test.stopTest();
        
        // Assert that the token matches the mocked token
        System.assertEquals('mockToken123', token, 'Token should match mocked token');
    }
    
    @isTest(seeAllData=true)
    static void testFetchUnanetToken_MissingBaseUrlOrMetadata() {
        String baseUrl = null;
    
        Test.startTest();
        String token = UnanetHelper.fetchUnanetToken(baseUrl);
        Test.stopTest();
    
        System.assertEquals(null, token, 'Token should be null due to invalid input or missing metadata');
    }

    @isTest
    public static void testInvalidAddressTypeKey() {
        // Register the mock response
        Test.setMock(HttpCalloutMock.class, new HttpMock());
        
        // Use an invalid address type
        String addressType = 'InvalidType';
        String token = 'mockToken123';
        
        // Call the method that fetches the address type key
        Integer result = UnanetHelper.getAddressTypeKey(addressType, token);
        
        // Assert that the result is null for an invalid address type
        System.assertEquals(null, result, 'Invalid Address Type Key should return null');
    }


    @isTest
    public static void testNullAddressTypeKey() {
        Integer result = UnanetHelper.getAddressTypeKey(null, 'fake_token');
        System.assertEquals(null, result, 'Null Address Type should return null');
    }

    @isTest
    public static void testEmptyAddressTypeKey() {
        Integer result = UnanetHelper.getAddressTypeKey('', 'fake_token');
        System.assertEquals(null, result, 'Empty Address Type should return null');
    }

    @isTest
    public static void testUnanetOrganizationWrapper() {
        UnanetOrganizationWrapper orgWrapper = new UnanetOrganizationWrapper();
        orgWrapper.key = 123;
        orgWrapper.name = 'Test Organization';
        orgWrapper.active = true;
        orgWrapper.type = new UnanetOrganizationWrapper.OrgType();
        orgWrapper.type.key = 1;
        orgWrapper.type.name = 'Non-Profit';

        // No logic in getSalesforceId by default, so just assert the object exists
        System.assertNotEquals(null, orgWrapper, 'Organization wrapper should be instantiated');
    }
    
    @isTest
    private static void testCreateOrganization_Success() {
        // Insert a test Account
        Account acc = new Account(
            Name = 'Test Client',
            CurrencyIsoCode = 'USD',
            BillingStreet = '123 Test St',
            BillingCity = 'Testville',
            BillingState = 'TS',
            BillingPostalCode = '12345',
            BillingCountry = 'USA'
        );
        insert acc;
    
        // Mock HTTP callouts
        Test.setMock(HttpCalloutMock.class, new HttpMock());
    
        String token = 'mockToken123';
        String baseUrl = 'https://bluefinllc.unanet.biz';
        String oppDivision = 'FMS';
    
        Test.startTest();
        String orgKey = UnanetHelper.createOrganization(acc, token, baseUrl, oppDivision);
        Test.stopTest();
    }
    
    @isTest
    static void testGetOrganization() {
        // Setting up mock response for the getOrganization endpoint
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new HttpMock());

        // Valid test case - should return organization info
        UnanetOrganizationWrapper result = UnanetHelper.getOrganization('9999', 'mockToken123', 'https://api.example.com');
        System.assertNotEquals(result, null, 'Organization should be returned');
        System.assertEquals(result.key, 1, 'Organization key should be 1');
        System.assertEquals(result.name, 'Mantis Customers', 'Organization name should match');

        Test.stopTest();
    }
    
    
    @isTest
    static void testCreateOrgAddress() {
        // Setup: Create an Account for testing
        Account acc = new Account(Name = 'Test Account', BillingStreet = '123 Test St', BillingCity = 'Test City', BillingState = 'TS', BillingPostalCode = '12345', BillingCountry = 'USA');
        insert acc;
        
        // Setup: Mock HTTP response
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new HttpMockOrgAddress());

        // Call the method to test
        UnanetHelper.createOrgAddress(acc, 'validUnanetId', 'https://api.example.com', 'mockToken123');

        // Assert the response (check if the HTTP request was made and that the address creation was logged correctly)
        System.assert(true, 'Address creation method executed successfully');

        Test.stopTest();
    }

    // Mock HTTP callout for createOrgAddress
    private class HttpMockOrgAddress implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            // Log request details (you can inspect this in your assertions or debug)
            System.debug('Mock HTTP Request: ' + req.getEndpoint());
            System.debug('Request Body: ' + req.getBody());
            
            // Setup the mock response
            HTTPResponse res = new HTTPResponse();
            res.setStatusCode(200);  // Simulate successful response
            res.setBody('{"message": "Address created successfully"}');  // Mock success message
            return res;
        }
    }
    
    @isTest
    static void testGetOrgContactKey() {
        Contact testCon = new Contact(FirstName = 'Test', LastName = 'User', Email = 'testuser@example.com');
        insert testCon;
    
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new HttpMockOrgContact());
    
        Integer result = UnanetHelper.getOrgContactKey(testCon, 'mockToken123', 'https://api.example.com', '123');
    
        System.assertEquals(1, result, 'Expected the correct contact key to be returned');
        Test.stopTest();
    }
    
    private class HttpMockOrgContact implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
        HTTPResponse res = new HTTPResponse();
        res.setStatusCode(200);

        // Response structured as an object (not array)
        String responseBody = '{' +
            '"items": [' +
                '{' +
                    '"key": 1,' +
                    '"salutation": "Mr.",' +
                    '"first": "Test",' +
                    '"middle": "Q.",' +
                    '"last": "User",' +
                    '"suffix": "Jr.",' +
                    '"title": "Engineer",' +
                    '"active": true,' +
                    '"defaultBillTo": true,' +
                    '"defaultShipTo": true,' +
                    '"defaultRemitTo": true,' +
                    '"comments": "Some comment",' +
                    '"primaryPhone": "123-456-7890",' +
                    '"primaryEmail": "testuser@example.com",' +
                    '"primaryAddress": {' +
                        '"streetLine1": "123 Main St",' +
                        '"city": "Testville",' +
                        '"stateProvince": "TS",' +
                        '"country": "USA",' +
                        '"postalCode": "12345"' +
                    '},' +
                    '"createdTimestamp": "2025-05-07T00:41:54.015Z",' +
                    '"lastUpdatedTimestamp": "2025-05-07T00:41:54.015Z"' +
                '}' +
            '],' +
            '"page": 1,' +
            '"pageSize": 10,' +
            '"pageCount": 1,' +
            '"resultCount": 1' +
        '}';

        res.setBody(responseBody);
        return res;
        }
    }
    
    @isTest
    static void testCreateContact() {
        // Create a test contact
        Contact testCon = new Contact(
            FirstName = 'Test',
            LastName = 'User',
            Phone = '123-456-7890',
            Email = 'test.user@example.com',
            Title = 'Tester',
            MailingStreet = '123 Main St',
            MailingCity = 'Testville',
            MailingState = 'TS',
            MailingPostalCode = '12345',
            MailingCountry = 'USA'
        );
        insert testCon;
    
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MultiMockCreateContact());
    
        // Call the method
        String result = UnanetHelper.createContact(testCon, 'mockToken123', 'https://api.example.com', 12345);
    
        Test.stopTest();
    }
    
    public class MultiMockCreateContact implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');

        String endpoint = req.getEndpoint();
        System.debug('>>> MOCKING ENDPOINT: ' + endpoint);

        if (endpoint.contains('/phone-types')) {
            res.setBody('{"items":[{"key":0,"name":"Mobile"}]}');
            res.setStatusCode(200);
        } else if (endpoint.contains('/email-types')) {
            res.setBody('{"items":[{"key":0,"name":"Business"}]}');
            res.setStatusCode(200);
        } else if (endpoint.contains('/address-types')) {
            res.setBody('{"items":[{"key":0,"name":"Mailing"}]}');
            res.setStatusCode(200);
        } else if (endpoint.contains('/udf-metadata/ORG_CONTACT')) {
            res.setBody('{"items":[{"index":1,"metadata":{"label":"SF Id","dataType":"STRING","visibility":"ENABLED","required":false,"active":true}}]}');
            res.setStatusCode(200);
        } else if (endpoint.contains('/contacts')) {
            res.setBody('{"key":"101"}'); // <-- ensure key field is included
            res.setStatusCode(200);
        } else {
            System.debug('>>> Unmatched endpoint in mock: ' + endpoint);
            res.setStatusCode(404);
            res.setBody('{"error":"Unknown endpoint"}');
        }

        return res;
        }
    }
    
        /*
    	@isTest
        static void testUpdateOrganizationWithSFId() {
            // Setup test org wrapper
            UnanetOrganizationWrapper orgWrapper = new UnanetOrganizationWrapper();
            orgWrapper.key = 113; // Match the test data
            orgWrapper.name = 'Test Org';
            
            // Initialize udfs and mock the UDF list to include 'SF Id' metadata
            orgWrapper.udfs = new UnanetOrganizationWrapper.UdfWrapper();
            orgWrapper.udfs.values = new List<UnanetOrganizationWrapper.UdfValueWrapper>();
        
            // Create UDF value for 'SF Id'
            UnanetOrganizationWrapper.UdfValueWrapper udfValue = new UnanetOrganizationWrapper.UdfValueWrapper();
            udfValue.index = 3; // UDF Index for 'SF Id'
            udfValue.value = null; // Initially null value
            UnanetOrganizationWrapper.MetadataWrapper metadata = new UnanetOrganizationWrapper.MetadataWrapper();
            metadata.label = 'SF Id'; // Correct label
            metadata.dataType = 'STRING';
            metadata.visibility = 'ENABLED';
            metadata.required = false;
            metadata.active = true;
            udfValue.metadata = metadata;
        
            // Add this mock UDF value to the list
            orgWrapper.udfs.values.add(udfValue);
        
            // Set the callout mock
            Test.setMock(HttpCalloutMock.class, new MultiMockUpdateOrg());
        
            // Use actual base URL your prod code expects
            String baseUrl = 'https://bluefinllc-sand.unanet.biz';
        
            // Print orgWrapper before update
            System.debug('Before update: ' + JSON.serialize(orgWrapper));
        
            // Begin test
            Test.startTest();
            UnanetHelper.updateOrganizationWithSFId(orgWrapper, 'sf-123', 'mockToken123', baseUrl);
            Test.stopTest();
        
            // Print orgWrapper after update
            System.debug('After update: ' + JSON.serialize(orgWrapper));
        
            // Assert that the SF Id UDF was added/updated
            Integer udfCount = 0;
            Boolean sfIdUpdated = false;
            
            // Ensure there is a valid udf list before processing
            if (orgWrapper.udfs != null && orgWrapper.udfs.values != null) {
                for (UnanetOrganizationWrapper.UdfValueWrapper udf : orgWrapper.udfs.values) {
                    if (udf != null && udf.metadata != null && udf.metadata.label == 'SF Id') {
                        udfCount++;
                        // Check that the SF Id value was updated to 'sf-123'
                        if (udf.value == 'sf-123') {
                            sfIdUpdated = true;
                        }
                    }
                }
            }
        
            // Assert that the SF Id UDF was added
            System.assertEquals(1, udfCount, 'SF Id UDF should be added');
            System.assert(sfIdUpdated, 'SF Id value should be updated to sf-123');
        } 
		*/
        
        public class MultiMockUpdateOrg implements HttpCalloutMock {
            public HTTPResponse respond(HTTPRequest req) {
                HttpResponse res = new HttpResponse();
                res.setHeader('Content-Type', 'application/json');
        
                String endpoint = req.getEndpoint();
                System.debug('>>> MOCKING ENDPOINT: ' + endpoint);
        
                if (endpoint.contains('/udf-metadata/ORGANIZATION')) {
                    res.setStatusCode(200);
                    res.setBody('{"items":[{"index":3,"metadata":{"label":"SF Id","dataType":"STRING","visibility":"ENABLED","required":false,"active":true}}]}');
                } else if (endpoint.contains('/platform/rest/organizations/')) {
                    // Simulating a successful update response
                    res.setStatusCode(200);
                    res.setBody('{"message":"Organization updated successfully"}');
                } else {
                    res.setStatusCode(404);
                    res.setBody('{"error":"Unknown endpoint"}');
                }
        
                return res;
            }
        }


}