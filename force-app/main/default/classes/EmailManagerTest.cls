@isTest
private class EmailManagerTest {

    // Test data setup
    private static void setupTestData() {
        // Create a test Account
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        // Create a test Contact
        Contact testContact = new Contact(FirstName = 'John', LastName = 'Doe', Email = 'john.doe@example.com', Phone = '123-456-7890', AccountId = testAccount.Id);
        insert testContact;

        // Create a test WorkOrder
        WorkOrder testWorkOrder = new WorkOrder(
            AccountId = testAccount.Id,
            ContactId = testContact.Id,
            Status = 'Approved',
            Subject = 'Test Subject',
            Description = 'Test Description',
            PropertyAddress__c = '123 Test St, Test City, TC',
            NTE__c = 500.0
        );
        insert testWorkOrder;
        
        // Create Work Order Line Item
        WorkOrderLineItem wl = new WorkOrderLineItem(
        WorkOrderId = testWorkOrder.Id);
        insert wl;
        
        // Create Section Records
        Section__c sec1 = new Section__c(
        Name = 'Test 1');
        insert sec1;
        
        Section__c sec2 = new Section__c(
        Name = 'Test2');
        insert sec2;
        
		// Create Work Order Section Junction Records
		Work_Order_Section_Junction__c woSec1 = new Work_Order_Section_Junction__c (
        Section2__c = sec1.Id,
        Work_Order__c = testWorkOrder.Id);
        insert woSec1;
        
        Work_Order_Section_Junction__c woSec2 = new Work_Order_Section_Junction__c (
        Section2__c = sec2.Id,
        Work_Order__c = testWorkOrder.Id);
        insert woSec2;

        // Create related FeedItems (as the method will check FeedItems)
        FeedItem feedItem1 = new FeedItem(ParentId = testWorkOrder.Id, Type = 'TextPost', Title = 'Test Title', Body = 'Test Body');
        insert feedItem1;

        FeedItem feedItem2 = new FeedItem(ParentId = testWorkOrder.Id, Type = 'TextPost', Title = 'Test Attachment', Body = 'Test Attachment Body');
        insert feedItem2;

        // Create related ContentVersion for the 'ContentPost' FeedItem
        ContentVersion contentVersion = new ContentVersion(
            Title = 'Test Attachment',
            PathOnClient = 'TestAttachment.pdf',
            VersionData = Blob.valueOf('Test PDF Content')
        );
        insert contentVersion;
        
        // Create and insert a Service Appointment
        ServiceAppointment serviceAppointment = new ServiceAppointment(
            ParentRecordId = testWorkOrder.Id,
            Status = 'Scheduled',
            DueDate = System.today().addDays(1),
            EarliestStartTime = System.today(),
            ActualStartTime = System.today()
        );
        insert serviceAppointment;

    }
    
    	

    @isTest
    static void testSendMail() {
        // Setup the test data
        setupTestData();

        // Fetch the WorkOrder we created in setupTestData()
        WorkOrder testWorkOrder = [SELECT Id,
                                               Status,
                                               Work_Order_Number_2__c,
                                               Project_No__c,
                                               PropertyName__c,
                                               PropertyAddress__c,
                                               Client_PO_Number__c,
                                               Contact.Email,
                                               WorkTypeId,
                                               AccountId,
                                               ContactId,
                                               Contractor__c,
                                               Contact__c,
                                               Cost_Type_Price__c,
                                               Cost__c,
                                               Work_Completed__c,
                                     		   OwnerId,
                                     		   StartDate,
                                     		   EndDate,
                                               WorkOrderNumber,
                                               NTE__c,
                                               Subject,
											   Description,
                                               Total_Price__c,
                                               WO_Line_Item_Price__c,
                                               CreatedDate
                                   FROM WorkOrder 
                                   WHERE Subject = 'Test Subject' LIMIT 1];

        // Define email parameters
        String[] emailAddresses = new String[] { 'test.email@example.com' };
        String subject = 'Test WorkOrder Email';
        String body = 'This is a test email body.';
        String fileName = 'TestReport';
        String fileID = '';  // File ID for an attachment, leave empty for this test case

        // Call the sendMail method from the EmailManager class
        Test.startTest();
        EmailManager.sendMail(emailAddresses, subject, body, fileName, fileID, testWorkOrder);
        Test.stopTest();

    }
}