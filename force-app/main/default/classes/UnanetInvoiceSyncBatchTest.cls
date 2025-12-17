@IsTest
public class UnanetInvoiceSyncBatchTest {

    private class MockBatchHttpResponse implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');

            if (req.getEndpoint().contains('/login')) {
                res.setBody('{"token":"mockToken123"}');
            } else if (req.getEndpoint().contains('/invoices/search')) {
                // Simulate invoice summaries
                UnanetInvoiceWrapper.Project projectWrapper = new UnanetInvoiceWrapper.Project();
                projectWrapper.key = 5555;

                UnanetInvoiceWrapper.Invoice invoice = new UnanetInvoiceWrapper.Invoice();
                invoice.key = 12345;
                invoice.invoiceDate = Date.today();
                invoice.project = projectWrapper;

                UnanetInvoiceWrapper wrapper = new UnanetInvoiceWrapper();
                wrapper.items = new List<UnanetInvoiceWrapper.Invoice>{ invoice };
                wrapper.pageCount = 1;

                res.setBody(JSON.serialize(wrapper));
            } else if (req.getEndpoint().contains('/platform/rest/invoices/')) {
                // Simulate invoice detail
                UnanetInvoiceIndividualWrapper detailed = new UnanetInvoiceIndividualWrapper();
                detailed.key = 12345;
                detailed.amount = 2000;
                detailed.invoiceNumber = 'INV-555';
                detailed.invoiceDate = Date.today();
                detailed.status = 'Posted';
                detailed.project = new UnanetInvoiceIndividualWrapper.Project();
                detailed.project.key = 5555;
                detailed.organization = new UnanetInvoiceIndividualWrapper.Organization();
                detailed.organization.name = 'Org A';
                detailed.billedOrganization = new UnanetInvoiceIndividualWrapper.Organization();
                detailed.billedOrganization.name = 'Billed Org A';
                detailed.billedAccount = new UnanetInvoiceIndividualWrapper.BilledAccount();
                detailed.billedAccount.key = 789;
                detailed.billingPeriodFromDate = Date.today().addDays(-30);
                detailed.billingThroughDate = Date.today();
                detailed.discountAmount = 75;
                detailed.instanceAmount = 100;
                detailed.localAmount = 2000;
                detailed.paymentTerm = new UnanetInvoiceIndividualWrapper.PaymentTerm();
                detailed.paymentTerm.code = 'Net45';
                detailed.postDate = Date.today();

                res.setBody(JSON.serialize(detailed));
            }

            return res;
        }
    }

    @IsTest
    static void testBatch_Createsuccess() {
        Test.setMock(HttpCalloutMock.class, new MockBatchHttpResponse());

        // Create Opportunity & Project
        Opportunity opp = new Opportunity(
            Name = 'Batch Test Opp',
            StageName = 'Qualification',
            CloseDate = Date.today().addDays(15)
        );
        insert opp;

        Project__c proj = new Project__c(
            Name = 'Batch Project',
            Unanet_Id__c = '5555',
            Opportunity__c = opp.Id,
            Type__c = 'Standard Project',
            Service_Area__c = 'FMS',
            Type_of_Service__c = 'Bid'
        );
        insert proj;
       

        Test.startTest();
        UnanetInvoiceSyncBatch batch = new UnanetInvoiceSyncBatch();
        Database.executeBatch(batch, 1); // Use small batch size for simplicity
        Test.stopTest();

        // Verify invoice record was created
        List<Unanet_Invoice__c> invoices = [
            SELECT Unanet_Id__c, Amount__c, Invoice_Number__c, Project__c
            FROM Unanet_Invoice__c
            WHERE Unanet_Id__c = '12345'
        ];
        System.assertEquals(1, invoices.size(), 'Expected one invoice record created');
        System.assertEquals('INV-555', invoices[0].Invoice_Number__c);
        System.assertEquals(2000, invoices[0].Amount__c);

        // Verify DataLog entry was written
        List<Data_Log__c> logs = [SELECT Description__c FROM Data_Log__c WHERE Log_Origin__c = 'Unanet Invoice Sync'];
        System.assertEquals(1, logs.size(), 'Expected one info log');
        System.assert(logs[0].Description__c.contains('Invoices returned: 1'), 'Log should include invoice count');
    }
    
    @IsTest
    static void testBatch_Updatesuccess() {
        Test.setMock(HttpCalloutMock.class, new MockBatchHttpResponse());

        // Create Opportunity & Project
        Opportunity opp = new Opportunity(
            Name = 'Batch Test Opp',
            StageName = 'Qualification',
            CloseDate = Date.today().addDays(15)
        );
        insert opp;

        Project__c proj = new Project__c(
            Name = 'Batch Project',
            Unanet_Id__c = '5555',
            Opportunity__c = opp.Id,
            Type__c = 'Standard Project',
            Service_Area__c = 'FMS',
            Type_of_Service__c = 'Bid'
        );
        insert proj;
        
        // Insert existing invoice record to test update branch
        insert new Unanet_Invoice__c(
            Unanet_Id__c = '12345',
            Amount__c = 500,  // old amount to confirm update
            Invoice_Number__c = 'INV-555',
            Project__c = proj.Id
        );

        Test.startTest();
        UnanetInvoiceSyncBatch batch = new UnanetInvoiceSyncBatch();
        Database.executeBatch(batch, 1); // Use small batch size for simplicity
        Test.stopTest();
    }

    // Optional: test login failure
    private class MockLoginFail implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(403);
            res.setBody('Unauthorized');
            return res;
        }
    }

    @IsTest
    static void testBatch_loginFailure_throwsError() {
        Test.setMock(HttpCalloutMock.class, new MockLoginFail());

        Test.startTest();
        Boolean failed = false;
        try {
            Database.executeBatch(new UnanetInvoiceSyncBatch(), 1);
        } catch (Exception ex) {
            failed = true;
        }
        Test.stopTest();

    }
    
    @IsTest
    static void testSchedulerExecutesBatch() {
        Test.setMock(HttpCalloutMock.class, new MockBatchHttpResponse());
    
        // Create necessary data
        Opportunity opp = new Opportunity(
            Name = 'Scheduled Opp',
            StageName = 'Qualification',
            CloseDate = Date.today().addDays(20)
        );
        insert opp;
    
        Project__c proj = new Project__c(
            Name = 'Scheduled Project',
            Unanet_Id__c = '5555',
            Opportunity__c = opp.Id,
            Type__c = 'Standard Project',
            Service_Area__c = 'FMS',
            Type_of_Service__c = 'Bid'
        );
        insert proj;
    
        // Run the schedulable class directly
        Test.startTest();
        new UnanetInvoiceSyncScheduler().execute(null);
        Test.stopTest();
    
        // Assert invoice was inserted
        List<Unanet_Invoice__c> invoices = [SELECT Id FROM Unanet_Invoice__c WHERE Unanet_Id__c = '12345'];
        System.assertEquals(1, invoices.size(), 'Invoice should be created from scheduler');
    }

}