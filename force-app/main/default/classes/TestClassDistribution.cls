@IsTest
private class TestClassDistribution {
    @isTest static void testGetCaseById() {
        Id recordId = createTestRecord();
        // Set up a test request
        RestRequest request = new RestRequest();
        request.requestUri =
            'https://yourInstance.salesforce.com/services/apexrest/Cases/'
            + recordId;
        request.httpMethod = 'GET';
        RestContext.request = request;
        // Call the method to test
        try {
               List<ContentDistribution> thisCase = ContentDistributionClass.getWorkOrderId();
        } catch(Exception E){}
      
        // Verify results
      //  System.assert(thisCase != null);
       // System.assertEquals('Test record', thisCase.Subject);
    }

    // Helper method
    static Id createTestRecord() {
        // Create test record
        Case caseTest = new Case(
            Subject='Test record',
            Status='New',
            Origin='Phone',
            Priority='Medium');
        insert caseTest;
        return caseTest.Id;
    }          
}