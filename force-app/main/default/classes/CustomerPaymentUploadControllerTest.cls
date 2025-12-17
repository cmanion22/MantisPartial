@isTest
private class CustomerPaymentUploadControllerTest {

    @testSetup
    static void setupData() {
        // Create Opportunity & Project
        Opportunity opp = new Opportunity(
            Name = 'Batch Test Opp',
            StageName = 'Qualification',
            Service_Area__c = 'FMS',
            Type_of_Service__c = 'Bid',
            CloseDate = Date.today().addDays(15)
        );
        insert opp;

        Project__c proj = new Project__c(
            Name = 'Batch Project',
            Unanet_Id__c = '5555',
            Project_Number__c = '12345',
            Opportunity__c = opp.Id,
            Type__c = 'Standard Project',
            Service_Area__c = 'FMS',
            Type_of_Service__c = 'Bid'
        );
        insert proj;

        // Create Invoice
        Unanet_Invoice__c inv = new Unanet_Invoice__c(
            Invoice_Number__c = 'INV123',
        	Project__c = proj.Id
        	);
        	
        insert inv;
    }

    @isTest
    static void testSuccessfulUpload() {
        Project__c proj = [SELECT Id, Project_Number__c FROM Project__c LIMIT 1];
        Unanet_Invoice__c inv = [SELECT Id, Invoice_Number__c FROM Unanet_Invoice__c LIMIT 1];

        List<Map<String, Object>> inputRows = new List<Map<String, Object>> {
            new Map<String, Object>{
                'Document number' => 'DOC001',
                'Document date' => '01/15/2024',
                'Post date' => '01/16/2024',
                'Customer org code' => 'ORG123',
                'Project Number' => proj.Project_Number__c,
                'Project Name' => 'Energy Efficiency',
                'Paid payment amount' => '1000.00',
                'Paid Invoice number' => inv.Invoice_Number__c,
                'Paid Document Invoice POST Date' => '01/17/2024',
                'Paid Invoice - Amt of Invoice' => '2000.00',
                'Payment amount' => '1000.00',
                'Primary Salesperson' => 'Alice',
                'Secondary Sales Person' => 'Bob',
                'As-Sold Margin' => '15.5',
                'Commission Plan Year' => '2024',
                'Offering Status' => 'Active'
            }
        };

        Test.startTest();
        Map<String, Object> result = CustomerPaymentUploadController.uploadCustomerPayments(inputRows);
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals(1, ((List<Unanet_Customer_Payment__c>) result.get('insertedRecords')).size());
        System.assertEquals(0, (Integer) result.get('errorCount'));
    }

    @isTest
    static void testMissingProjectOrInvoice() {
        List<Map<String, Object>> inputRows = new List<Map<String, Object>> {
            new Map<String, Object>{
                'Document number' => 'DOC002',
                'Project Number' => 'INVALID_PROJECT',
                'Paid Invoice number' => 'INVALID_INVOICE'
            }
        };

        Test.startTest();
        Map<String, Object> result = CustomerPaymentUploadController.uploadCustomerPayments(inputRows);
        Test.stopTest();

        List<Map<String, String>> errors = (List<Map<String, String>>) result.get('errors');
        System.assertEquals(1, errors.size());
        System.assert(errors[0].get('error').contains('No matching Project'));
    }

    @isTest
    static void testSendErrorEmailWithAttachment() {
        // Sample base64-encoded string for a CSV file (e.g. "a,b,c\n1,2,3")
        String csvContent = 'Um93LERvY3VtZW50IE51bWJlcixFcnJvcg0KMSxEQzAwMSxObyBtYXRjaGluZyBQcm9qZWN0';
        String fileName = 'errors.csv';
        String mimeType = 'text/csv';

        Test.startTest();
        CustomerPaymentUploadController.sendErrorEmailWithAttachment(csvContent, fileName, mimeType);
        Test.stopTest();

        // Not much to assert directly, but this ensures no exception is thrown
        System.assert(true);
    }
}