@isTest
public class UnanetProjectHelperTest {

    // Mock for HTTP callouts in the tests
    private class HttpMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');

            String endpoint = req.getEndpoint();
            System.debug('>>> MOCKED ENDPOINT: ' + endpoint);

            // Simulating cost structure data
            if (endpoint.contains('/platform/rest/cost-structures')) {
                res.setBody('{"items":[{"key":123,"name":"Standard","description":"Standard Cost Structure"}],"pageCount":1}');
            }
            // Simulating posting group data
            else if (endpoint.contains('/platform/rest/posting-groups')) {
                res.setBody('{"items":[{"key":456,"name":"Admin","description":"Admin Posting Group"}],"pageCount":1}');
            }
            // Simulating pay-code data
            else if (endpoint.contains('pay-codes')) {
                res.setBody(
                    '{"items":[{"key":567,"name":"Regular"}],' +
                    '"page":1,"pageSize":100,"pageCount":1,"resultCount":1}'
                );
            }
            // Simulate other API responses
            else {
                res.setBody('{}');
            }

            return res;
        }
    }

    // Test for getCostStructureKey method
    @isTest
    static void testGetCostStructureKey() {
        // Insert mock data for the test
        Test.setMock(HttpCalloutMock.class, new HttpMock());

        // Test the method
        Test.startTest();
        Integer costStructureKey = UnanetProjectHelper.getCostStructureKey('Standard', 'mockToken123');
        Test.stopTest();

        // Assert that the method correctly returns the key for 'Standard' cost structure
        System.assertNotEquals(null, costStructureKey, 'Cost structure key should not be null');
        System.assertEquals(123, costStructureKey, 'Cost structure key should be 123');
    }
    
    // Test for getPayCodeKey method
    @isTest
    static void testGetPayCodeKey() {
        // Insert mock data for the test
        Test.setMock(HttpCalloutMock.class, new HttpMock());

        // Test the method
        Test.startTest();
        Integer payCodeKey = UnanetProjectHelper.getPayCodeKey('Regular', 'mockToken123');
        Test.stopTest();

        // Assert that the method correctly returns the key for 'Regular' Pay-Code
        System.assertNotEquals(null, payCodeKey, 'Pay-Code key should not be null');
        System.assertEquals(567, payCodeKey, 'Pay-Code key should be 567');
    }

    // Test for getPostingGroupKey method
    @isTest
    static void testGetPostingGroupKey() {
        // Insert mock data for the test
        Test.setMock(HttpCalloutMock.class, new HttpMock());

        // Test the method
        Test.startTest();
        Integer postingGroupKey = UnanetProjectHelper.getPostingGroupKey('Admin', 'mockToken123');
        Test.stopTest();

        // Assert that the method correctly returns the key for 'Admin' posting group
        System.assertNotEquals(null, postingGroupKey, 'Posting group key should not be null');
        System.assertEquals(456, postingGroupKey, 'Posting group key should be 456');
    }

    // Test for getFirstOfMonth method
    @isTest
    static void testGetFirstOfMonth() {
        Date startDate = Date.newInstance(2025, 5, 15);  // May 15, 2025

        String firstOfMonth = UnanetProjectHelper.getFirstOfMonth(startDate);

        System.assertEquals('2025-05-01', firstOfMonth, 'The first of the month should be May 1, 2025');
    }

    // Test for getLastOfMonth method
    @isTest
    static void testGetLastOfMonth() {
        Date startDate = Date.newInstance(2025, 5, 15);  // May 15, 2025

        Date lastOfMonth = UnanetProjectHelper.getLastOfMonth(startDate);

        System.assertEquals(Date.newInstance(2025, 5, 31), lastOfMonth, 'The last of the month should be May 31, 2025');
    }

    // Test for buildStandardFixedPriceItemPayload method
    @isTest
    static void testBuildStandardFixedPriceItemPayload() {
        // Insert a test Account
        Account acc = new Account(
            Name = 'Test Client',
            CurrencyIsoCode = 'USD',
            BillingStreet = '123 Test St',
            BillingCity = 'Testville',
            BillingState = 'TS',
            BillingPostalCode = '12345',
            BillingCountry = 'USA',
            Unanet_Id__c = '123'
        );
        insert acc;
        
        // Insert Opportunity
        Opportunity opp = new Opportunity();
        opp.Name = 'Testing - Opp - 1';
        opp.Service_Area__c = 'FMS';
        opp.Type_of_Service__c = 'Bid';
        opp.CloseDate = Date.today().addDays(30);
        opp.Project_State__c = 'Florida';
        opp.Mantis_Division__c = 'FMS';
        opp.StageName = '5 - Closed Won';
        insert opp;
                                
        // Insert mock project data
        Project__c proj = new Project__c(
            Name = 'Test Project',
            Account__c = acc.Id,
            Opportunity__c = opp.Id,
            Project_Number__c = 'PRJ-001',
            End_Date__c = Date.newInstance(2025, 5, 31),
            Type__c = 'Standard Project',
            Total_Contract_Value__c = 10000,
            Service_Area__c = 'FMS',
            Type_of_Service__c = 'Bid',
            Unanet_Project_Type__c = 'BID',
            Start_Date__c = Date.today()
            
        );
        insert proj;
        
        proj = [
            SELECT Name, Project_Number__c, Account__r.Name, End_Date__c, Type__c, Project_Amount__c
            FROM Project__c
            WHERE Id = :proj.Id
        ];

        // Test the method
        String payload = UnanetProjectHelper.buildStandardFixedPriceItemPayload(proj, '123');
        System.debug('Payload Description: ' + payload);

        // Assert that the payload contains the expected values
        System.assert(payload.contains('"projectKey":123'), 'Payload should contain the project key');
        System.assert(payload.contains('"amount":10000'), 'Payload should contain the correct amount');
    }
    
        
        @isTest
        public static void testBuildUnanetProjectPayload() {
            Test.setMock(HttpCalloutMock.class, new HttpMockExpanded());
        
            // Setup test Account
            Account acc = new Account(Name='Test Account', CurrencyIsoCode='USD', Unanet_Id__c='1');
            insert acc;
        
            // Setup test Opportunity
            Opportunity opp = new Opportunity(
                Name='Test Opp',
                StageName='5 - Closed Won',
                CloseDate=Date.today().addDays(30),
                CurrencyIsoCode='USD',
                Mantis_Division__c='FMS',
                Project_State__c='Florida',
                AccountId=acc.Id
            );
            insert opp;
            
            
            // Setup Second Split
            Opportunity_Split__c split = new Opportunity_Split__c(
            Split_Percentage__c = 100,
            Current_Percentage__c = 100,
            Opportunity__c = opp.Id
            );
            insert split;
        
            // Setup test Project
            Project__c proj = new Project__c(
                Name='Test Project',
                Account__c=acc.Id,
                Opportunity__c=opp.Id,
                Project_Number__c='PRJ-001',
                Start_Date__c=Date.today(),
                End_Date__c=Date.today().addMonths(1),
                Total_Contract_Value__c=50000,
                Unanet_Project_Type__c='BID',
                Service_Area__c = 'FMS',
                Type_of_Service__c = 'Bid',
                Service_Street__c='123 Main St',
                Service_City__c='Orlando',
                Project_State__c = 'Florida',
                Project_Requires_TASKS__c='Yes',
                Project_Amount__c = 0,
                Type__c = 'Standard Project'
            );
            insert proj;
        
            // Start Test
            Test.startTest();
            
            // Trigger the method

            String payload = UnanetProjectHelper.buildUnanetProjectPayload(proj, acc, opp, 'mockToken');
            
            // Stop Test
            Test.stopTest();
            
            // Verify generated payload contains the expected values
            System.debug('Generated Payload: ' + payload);
            
            System.assert(payload.contains('"title":"Test Project"'));
            System.assert(payload.contains('"code":"PRJ-001"'));
            System.assert(payload.contains('"projectCurrencyKey":1'));
            System.assert(payload.contains('"locationKey":1'));
            System.assert(!payload.contains('"Primary Salesperson"'), 'Label should not appear in raw JSON');
            System.assert(payload.contains('"value":"123 Main St"'), 'Street UDF should be present');
            System.assert(payload.contains('"value":"Orlando"'), 'City UDF should be present');
        
            // Ensure no more than 50 jobs are queued up during this test
            Integer jobCount = [SELECT COUNT() FROM AsyncApexJob WHERE Status = 'Queued'];
            System.debug('Number of queued jobs: ' + jobCount);
            
            // Assert that we don't exceed the 50-job limit
            System.assert(jobCount <= 50, 'Too many queueable jobs were enqueued! Number of jobs: ' + jobCount);
        }

    
        private class HttpMockExpanded implements HttpCalloutMock {
            public HTTPResponse respond(HTTPRequest req) {
                HttpResponse res = new HttpResponse();
                res.setStatusCode(200);
                res.setHeader('Content-Type', 'application/json');
    
                String endpoint = req.getEndpoint();
    
                if (endpoint.contains('/cost-structures')) {
                    res.setBody('{"items":[{"key":1,"name":"Standard","description":"Standard","active":true,"costPoolGroupKey":1}]}');
                } else if (endpoint.contains('/posting-groups')) {
                    res.setBody('{"items":[{"key":1,"name":"Default","description":"Default","active":true,"type":"DEFAULT"}]}');
                } else if (endpoint.contains('/currencies/currency-codes')) {
                    res.setBody('{"items":[{"key":1,"isoCurrencyCode":"USD","name":"US Dollar"}]}');
                } else if (endpoint.contains('/project-types')) {
                    res.setBody('{"items":[{"key":1,"name":"BID","description":"Bid Project"}]}');
                } else if (endpoint.contains('/organizations/list')) {
                    res.setBody('[{"key":1,"name":"FMS","code":"FMS"}]');
                } else if (endpoint.contains('/billing-types')) {
                    res.setBody('{"items":[{"key":1,"type":"FIXED_PRICE","description":"Lump Sum/Fixed Price"}]}');
                } else if (endpoint.contains('/locations')) {
                    res.setBody('{"items":[{"key":1,"name":"Florida","active":true}]}');
                } else if (endpoint.contains('/udf-metadata/PROJECT')) {
                    res.setBody('{"items":[' +
                        '{"index":1,"metadata":{"label":"Primary Salesperson","dataType":"STRING","visibility":"ENABLED","active":true}},' +
                        '{"index":2,"metadata":{"label":"Secondary Salesperson","dataType":"STRING","visibility":"ENABLED","active":true}},' +
                        '{"index":13,"metadata":{"label":"Street Address","dataType":"STRING","visibility":"ENABLED","active":true}},' +
                        '{"index":14,"metadata":{"label":"City","dataType":"STRING","visibility":"ENABLED","active":true}},' +
                        '{"index":15,"metadata":{"label":"SF Id","dataType":"STRING","visibility":"ENABLED","active":true}}' +
                    ']}');
                } else if (endpoint.contains('/project-statuses')) {
                        res.setBody('{"items":[{"key":1,"name":"Active","open":true}]}');
                }// Simulating pay-code data
            else if (endpoint.contains('pay-codes')) {
                res.setBody(
                    '{"items":[{"key":567,"name":"Regular"}],' +
                    '"page":1,"pageSize":100,"pageCount":1,"resultCount":1}'
                );
            }else {
                    res.setBody('{}');
                }
    
                return res;
            }
        }
    	
}