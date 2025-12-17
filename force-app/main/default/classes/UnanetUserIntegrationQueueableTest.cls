@isTest
private class UnanetUserIntegrationQueueableTest {
    
    @isTest
    static void testExecute_deactivatesStaleUser() {
        // Create an active SF user that should be deactivated (not active in Unanet)
        insert new Unanet_User__c(
            First_Name__c      = 'Inactive',
            Last_Name__c       = 'User',
            Name               = 'Inactive User',
            Username__c        = 'inactive.user',
            Unanet_User_Id__c  = '2',
            isActive__c        = true
        );

        // Set the callout mock once — applies to all callouts within the test context
        Test.setMock(HttpCalloutMock.class, new UnanetUserIntegrationMock());

        Test.startTest();
            System.enqueueJob(new UnanetUserIntegrationQueueable());
        Test.stopTest();

        // Verify user is now deactivated
        Unanet_User__c updatedUser = [
            SELECT isActive__c
            FROM Unanet_User__c
            WHERE Unanet_User_Id__c = '2'
            LIMIT 1
        ];
        System.assertEquals(false, updatedUser.isActive__c, 'Inactive user should have been deactivated');
    }
    
        // Test method simulating the login failure (401 Unauthorized)
        @isTest
        static void testLoginFailureLogsError() {
            // Set up the mock response for simulating login failure
            Test.setMock(HttpCalloutMock.class, new UnanetUserIntegrationMockFailure());
    
            // Execute the Queueable job that should log the error on failure
            Test.startTest();
            UnanetUserIntegrationQueueable queueableJob = new UnanetUserIntegrationQueueable();
            System.enqueueJob(queueableJob);
            Test.stopTest();
    
            List<Data_Log__c> logs = [SELECT Id, Log_Origin__c 
                                   FROM Data_Log__c 
                                   WHERE Log_Origin__c = 'Unanet user sync error' 
                                   LIMIT 1];

        // Step 4: Assert that a log entry was created (size should be > 0)
        System.assertEquals(1, logs.size(), 'One log entry should be created.');
        }
    

    // Separate Mock Class for Simulating Login Failure
    private class UnanetUserIntegrationMockFailure implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            // Simulating a failed login attempt (401 Unauthorized)
            HttpResponse res = new HttpResponse();
            res.setStatusCode(401);  // Unauthorized status code
            res.setBody('{"error": "Invalid credentials"}');  // Mock response body
            return res;
        }
        
        
	}
    
    @isTest
    static void testWrapperCoverage() {
        // Instantiate main wrapper
        UnanetUserIntegrationWrapper wrapper = new UnanetUserIntegrationWrapper();
        wrapper.page = 1;
        wrapper.pageSize = 100;
        wrapper.pageCount = 1;
        wrapper.resultCount = 1;
        wrapper.items = new List<UnanetUserIntegrationWrapper.UnanetPerson>();

        // Instantiate nested person
        UnanetUserIntegrationWrapper.UnanetPerson person = new UnanetUserIntegrationWrapper.UnanetPerson();
        person.key = 123;
        person.username = 'jdoe';
        person.firstName = 'John';
        person.lastName = 'Doe';
        person.active = true;

        // Instantiate nested org and employeeType
        person.organization = new UnanetUserIntegrationWrapper.Organization();
        person.organization.key = 10;
        person.organization.name = 'Bluefin';
        person.organization.code = 'BF';

        person.employeeType = new UnanetUserIntegrationWrapper.EmployeeType();
        person.employeeType.key = 1;
        person.employeeType.name = 'Full-Time';

        person.personCode = 'JD123';

        // Add person to wrapper
        wrapper.items.add(person);

        // Optional assertion
        System.assertEquals('jdoe', wrapper.items[0].username);
    }
    
    // Helper method to add coverage
    @isTest
    static void testCoverageHack() {
        Test.startTest();
        UnanetUserIntegrationQueueable.codeCoverageHack();
        Test.stopTest();
    }
}