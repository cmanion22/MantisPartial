@isTest 
public with sharing class WorkOrderStatusUpdateTest {

    @isTest
    private static User createUser() {
        User newUser = new User(
            Username = 'testUser12223459@example.com',
            Email = 'testuser@example.com',
            LastName = 'Test',
            Alias = 'tuser',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            IsActive = true
        );
        insert newUser;
        return newUser;
    }

    private static Group createGroup() {
        Group newGroup = new Group(Name = 'Field Agents', Type = 'Regular');
        insert newGroup;
        return newGroup;
    }

    private static void createGroupMember(Id groupId, Id userId) {
        GroupMember groupMember = new GroupMember(GroupId = groupId, UserOrGroupId = userId);
        insert groupMember;
    }
    
    private static void createEmailCustomSetting() {
        // Create a custom setting record for RLR
        Email_Approved_Status__c emailSettingRLR = new Email_Approved_Status__c();
        emailSettingRLR.Name = 'Email'; // Set the name for the instance
        emailSettingRLR.Email__c = 'test@example.com'; // Set the email value
        insert emailSettingRLR;
        
        // Create a custom setting record for BMS
        Email_Approved_Status__c emailSettingBMS = new Email_Approved_Status__c();
        emailSettingBMS.Name = 'BMS_Email'; // Set the name for the instance
        emailSettingBMS.Email__c = 'test@example.com'; // Set the email value
        insert emailSettingBMS;
    }

    @isTest
    public static void WorkOrderStatusAfterInsertTest() {
        // Create test data
        Work_Template__c wt = new Work_Template__c(Name = 'test');
        insert wt;

        MaintenancePlan mp = new MaintenancePlan(
            StartDate = System.today(),
            Frequency = 10,
            FrequencyType = 'Days',
            GenerationTimeframe = 5,
            GenerationTimeframeType = 'Days',
            NextSuggestedMaintenanceDate = System.today(),
            Work_Template__c = wt.Id
        );
        insert mp;

        WorkOrder testWO = new WorkOrder(
            Subject = 'Test Test',
            Description = 'Testing Description',
            Sections_Name__c = 'Test',
            NTE__c = 500,
            SuggestedMaintenanceDate = System.today(),
            MaintenancePlanId = mp.Id
        );

        Test.startTest();
        insert testWO;
        CreateWorkOrderLineItems.createLineItems(mp.Work_Template__c, testWO.Id, testWO.MaintenancePlanId, testWO.SuggestedMaintenanceDate);
        Test.stopTest();
    }

    @isTest
    public static void WorkOrderStatusInProgressTest() {
        // Create Test Data
        Work_Template__c wt = new Work_Template__c(Name = 'test');
        insert wt;
    
        MaintenancePlan mp = new MaintenancePlan(
            StartDate = System.today(),
            Frequency = 10,
            FrequencyType = 'Days',
            GenerationTimeframe = 5,
            GenerationTimeframeType = 'Days',
            NextSuggestedMaintenanceDate = System.today(),
            Work_Template__c = wt.Id
        );
        insert mp;
    
        // Create the WorkOrder
        WorkOrder testWO = new WorkOrder(
            Subject = 'Test Test',
            Description = 'Testing Description',
            Sections_Name__c = 'Test',
            NTE__c = 500,
            SuggestedMaintenanceDate = System.today(),
            MaintenancePlanId = mp.Id,
            Status = 'Exceed NTE'
        );
        insert testWO;
    
        // Create and insert a Service Appointment
        ServiceAppointment serviceAppointment = new ServiceAppointment(
            ParentRecordId = testWO.Id,
            Status = 'Scheduled',
            DueDate = System.today().addDays(1),
            EarliestStartTime = System.today(),
            ActualStartTime = System.today()
        );
        insert serviceAppointment;
    
        // Start the test
        Test.startTest();
        
        // Retrieve the WorkOrder records before updating
        List<WorkOrder> oldWOList = [SELECT Id, Status FROM WorkOrder WHERE Id = :testWO.Id];
        
        // Update the status of the WorkOrder
        testWO.Status = 'In Progress';
        update testWO;  // This should trigger the logic in your trigger that calls WorkOrderStatusAfterUpdate
    
        // Retrieve the updated WorkOrder (after the status change)
        List<WorkOrder> newWOList = [SELECT Id, Status FROM WorkOrder WHERE Id = :testWO.Id];
    
        // Create the oldWosMap by mapping the old WorkOrder records by their Id
        Map<Id, WorkOrder> oldWosMap = new Map<Id, WorkOrder>();
        for (WorkOrder oldWO : oldWOList) {
            oldWosMap.put(oldWO.Id, oldWO);
        }
    
        // Call the WorkOrderStatusAfterUpdate method with the new and old WorkOrders
        WorkOrderStatusHandler.WorkOrderStatusAfterUpdate(newWOList, oldWosMap);
        
        // Add assertions to verify that the logic worked as expected
        ServiceAppointment updatedSA = [SELECT Status FROM ServiceAppointment WHERE ParentRecordId = :testWO.Id LIMIT 1];
        System.assertEquals('Dispatched', updatedSA.Status, 'The Service Appointment should have been updated to Dispatched.');
    
        Test.stopTest();
    }


    @isTest
    public static void workOrderStatusExceedNTETest() {
   
        
        // Create Test Data for Work_Template__c and MaintenancePlan
        Work_Template__c wt = new Work_Template__c(Name = 'test');
        insert wt;

        MaintenancePlan mp = new MaintenancePlan(
            StartDate = System.today(),
            Frequency = 10,
            FrequencyType = 'Days',
            GenerationTimeframe = 5,
            GenerationTimeframeType = 'Days',
            NextSuggestedMaintenanceDate = System.today(),
            Work_Template__c = wt.Id
        );
        insert mp;

        // Create the Work Order
        WorkOrder testWO = new WorkOrder(
            Subject = 'Test Test',
            Description = 'Testing Description',
            Sections_Name__c = 'Test',
            NTE__c = 500,
            SuggestedMaintenanceDate = System.today(),
            MaintenancePlanId = mp.Id,
            Status = 'New'
        );

        insert testWO;

        // Create and insert a Service Appointment
        ServiceAppointment serviceAppointment = new ServiceAppointment(
            ParentRecordId = testWO.Id,
            Status = 'Exceed NTE',
            DueDate = System.today().addDays(1), 
            EarliestStartTime = System.today(),  
            ActualStartTime = System.now()  
        );

        insert serviceAppointment;
        
        // Start the test
        Test.startTest();
        
        // Retrieve the WorkOrder records before updating
        List<WorkOrder> oldWOList = [SELECT Id, Status FROM WorkOrder WHERE Id = :testWO.Id];
        
        // Update the status of the WorkOrder
        testWO.Status = 'Exceed NTE';
        update testWO;  // This should trigger the logic in your trigger that calls WorkOrderStatusAfterUpdate
    
        // Retrieve the updated WorkOrder (after the status change)
        List<WorkOrder> newWOList = [SELECT Id, Status FROM WorkOrder WHERE Id = :testWO.Id];
    
        // Create the oldWosMap by mapping the old WorkOrder records by their Id
        Map<Id, WorkOrder> oldWosMap = new Map<Id, WorkOrder>();
        for (WorkOrder oldWO : oldWOList) {
            oldWosMap.put(oldWO.Id, oldWO);
        }
    
        // Call the WorkOrderStatusAfterUpdate method with the new and old WorkOrders
        WorkOrderStatusHandler.WorkOrderStatusAfterUpdate(newWOList, oldWosMap);
        
        // Add assertions to verify that the logic worked as expected
        ServiceAppointment updatedSA = [SELECT Status FROM ServiceAppointment WHERE ParentRecordId = :testWO.Id LIMIT 1];
        System.assertEquals('Exceed NTE', updatedSA.Status, 'The Service Appointment should have been updated to Exceed NTE.');
    
        Test.stopTest();
    }

    @isTest public static void workOrderStatusCompletedTest() {
        // Create Test Data for Work_Template__c and MaintenancePlan
        Work_Template__c wt = new Work_Template__c(Name = 'test');
        insert wt;

        MaintenancePlan mp = new MaintenancePlan(
            StartDate = System.today(),
            Frequency = 10,
            FrequencyType = 'Days',
            GenerationTimeframe = 5,
            GenerationTimeframeType = 'Days',
            NextSuggestedMaintenanceDate = System.today(),
            Work_Template__c = wt.Id
        );
        insert mp;

        // Create the Work Order
        WorkOrder testWO = new WorkOrder(
            Subject = 'Test Test',
            Description = 'Testing Description',
            Sections_Name__c = 'Test',
            NTE__c = 500,
            SuggestedMaintenanceDate = System.today(),
            MaintenancePlanId = mp.Id,
            Status = 'New'
        );

        insert testWO;

        // Create and insert a Service Appointment
        ServiceAppointment serviceAppointment = new ServiceAppointment(
            ParentRecordId = testWO.Id,
            Status = 'Exceed NTE',
            DueDate = System.today().addDays(1), 
            EarliestStartTime = System.today(),  
            ActualStartTime = System.now()  
        );

        insert serviceAppointment;

        Cost_Type__c costType = new Cost_Type__c();
        costType.Cost__c = 150;
        costType.Work_Order__c = testWO.Id;
        insert costType;

        // Start the test
        Test.startTest();
        
        // Retrieve the WorkOrder records before updating
        List<WorkOrder> oldWOList = [SELECT Id, Status, Work_Order_Number_2__c FROM WorkOrder WHERE Id = :testWO.Id];
        
        // Update the status of the WorkOrder
        testWO.Status = 'Completed';
        testWo.Cause_Of_Leak__c  = 'HVAC';
        update testWO;  // This should trigger the logic in your trigger that calls WorkOrderStatusAfterUpdate
    
        // Retrieve the updated WorkOrder (after the status change)
        List<WorkOrder> newWOList = [SELECT Id, Status, Work_Order_Number_2__c FROM WorkOrder WHERE Id = :testWO.Id];
    
        // Create the oldWosMap by mapping the old WorkOrder records by their Id
        Map<Id, WorkOrder> oldWosMap = new Map<Id, WorkOrder>();
        for (WorkOrder oldWO : oldWOList) {
            oldWosMap.put(oldWO.Id, oldWO);
        }
    
        // Call the WorkOrderStatusAfterUpdate method with the new and old WorkOrders
        WorkOrderStatusHandler.WorkOrderStatusAfterUpdate(newWOList, oldWosMap);
        
        Test.stopTest();

    }

    @isTest public static void workOrderStatusApprovedRLRTest() {
        // Create Test Data for Work_Template__c and MaintenancePlan
        createEmailCustomSetting();
        Work_Template__c wt = new Work_Template__c(Name = 'test');
        insert wt;

        MaintenancePlan mp = new MaintenancePlan(
            StartDate = System.today(),
            Frequency = 10,
            FrequencyType = 'Days',
            GenerationTimeframe = 5,
            GenerationTimeframeType = 'Days',
            NextSuggestedMaintenanceDate = System.today(),
            Work_Template__c = wt.Id
        );
        insert mp;
        
        // Create an Account
        Account account = new Account();
        account.Name = 'Testing222';
        account.Industry = 'Real Estate';
        insert account;

        // Create a Contact for Site Contact
        Contact siteContact = new Contact();
        siteContact.LastName = 'testtesttest';
        siteContact.LeadSource = 'BD';
        siteContact.AccountId = account.Id;
        insert siteContact;

        // Create a Work Type
        WorkType workType = new WorkType();
        workType.Name = 'Test';
        workType.EstimatedDuration = 10;
        workType.DurationType = 'Hours';
        insert workType;
        
        // Create the Work Order
        WorkOrder testWO = new WorkOrder(
            Subject = 'Test Test',
            Description = 'Testing Description',
            Sections_Name__c = 'Test',
            NTE__c = 500,
            SuggestedMaintenanceDate = System.today(),
            MaintenancePlanId = mp.Id,
            Status = 'New',
            Contractor__c = siteContact.Id,
            AccountId = account.Id,
            Contact__c  = siteContact.Id,
            WorkTypeId = workType.Id,
            Cost__c = 300
        );

        insert testWO;

        // Create and insert a Service Appointment
        ServiceAppointment serviceAppointment = new ServiceAppointment(
            ParentRecordId = testWO.Id,
            Status = 'Exceed NTE',
            DueDate = System.today().addDays(1), 
            EarliestStartTime = System.today(),  
            ActualStartTime = System.now()  
        );

        insert serviceAppointment;
		
        Cost_Type__c costType = new Cost_Type__c();
        costType.Cost__c = 150;
        costType.Work_Order__c = testWO.Id;
        insert costType;
        
         // Start the test
        Test.startTest();
        
        // Retrieve the WorkOrder records before updating
        List<WorkOrder> oldWOList = [SELECT Id,
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
                                               Service_Line__c,
                                               CreatedDate
                                        FROM WorkOrder
                                     	WHERE Id = :testWO.Id];
        
        // Update the status of the WorkOrder
        testWO.Status = 'Approved';
        testWo.Cause_Of_Leak__c  = 'HVAC';
        testWo.Service_Line__c = 'RLR';
        update testWO;  // This should trigger the logic in your trigger that calls WorkOrderStatusAfterUpdate
    
        // Retrieve the updated WorkOrder (after the status change)
        List<WorkOrder> newWOList = [SELECT Id,
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
                                     		   Service_Line__c,
                                               CreatedDate
                                        FROM WorkOrder
                                     	WHERE Id = :testWO.Id];
    
        // Create the oldWosMap by mapping the old WorkOrder records by their Id
        Map<Id, WorkOrder> oldWosMap = new Map<Id, WorkOrder>();
        for (WorkOrder oldWO : oldWOList) {
            oldWosMap.put(oldWO.Id, oldWO);
        }
    
        // Call the WorkOrderStatusAfterUpdate method with the new and old WorkOrders
        WorkOrderStatusHandler.WorkOrderStatusAfterUpdate(newWOList, oldWosMap);
        
        Test.stopTest();
    }
    
    @isTest public static void workOrderStatusApprovedBMSTest() {
        // Create Test Data for Work_Template__c and MaintenancePlan
        createEmailCustomSetting();
        Work_Template__c wt = new Work_Template__c(Name = 'test');
        insert wt;

        MaintenancePlan mp = new MaintenancePlan(
            StartDate = System.today(),
            Frequency = 10,
            FrequencyType = 'Days',
            GenerationTimeframe = 5,
            GenerationTimeframeType = 'Days',
            NextSuggestedMaintenanceDate = System.today(),
            Work_Template__c = wt.Id
        );
        insert mp;
        
        // Create an Account
        Account account = new Account();
        account.Name = 'Testing222';
        account.Industry = 'Real Estate';
        insert account;

        // Create a Contact for Site Contact
        Contact siteContact = new Contact();
        siteContact.LastName = 'testtesttest';
        siteContact.LeadSource = 'BD';
        siteContact.AccountId = account.Id;
        insert siteContact;

        // Create a Work Type
        WorkType workType = new WorkType();
        workType.Name = 'Test';
        workType.EstimatedDuration = 10;
        workType.DurationType = 'Hours';
        insert workType;
        
        // Create the Work Order
        WorkOrder testWO = new WorkOrder(
            Subject = 'Test Test',
            Description = 'Testing Description',
            Sections_Name__c = 'Test',
            NTE__c = 500,
            SuggestedMaintenanceDate = System.today(),
            MaintenancePlanId = mp.Id,
            Status = 'New',
            Contractor__c = siteContact.Id,
            AccountId = account.Id,
            Contact__c  = siteContact.Id,
            WorkTypeId = workType.Id,
            Cost__c = 300
        );

        insert testWO;

        // Create and insert a Service Appointment
        ServiceAppointment serviceAppointment = new ServiceAppointment(
            ParentRecordId = testWO.Id,
            Status = 'Exceed NTE',
            DueDate = System.today().addDays(1), 
            EarliestStartTime = System.today(),  
            ActualStartTime = System.now()  
        );

        insert serviceAppointment;
		
        Cost_Type__c costType = new Cost_Type__c();
        costType.Cost__c = 150;
        costType.Work_Order__c = testWO.Id;
        insert costType;
        
         // Start the test
        Test.startTest();
        
        // Retrieve the WorkOrder records before updating
        List<WorkOrder> oldWOList = [SELECT Id,
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
                                               Service_Line__c,
                                               CreatedDate
                                        FROM WorkOrder
                                     	WHERE Id = :testWO.Id];
        
        // Update the status of the WorkOrder
        testWO.Status = 'Approved';
        testWo.Cause_Of_Leak__c  = 'HVAC';
        testWo.Service_Line__c = 'BMS Service';
        update testWO;  // This should trigger the logic in your trigger that calls WorkOrderStatusAfterUpdate
    
        // Retrieve the updated WorkOrder (after the status change)
        List<WorkOrder> newWOList = [SELECT Id,
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
                                     		   Service_Line__c,
                                               CreatedDate
                                        FROM WorkOrder
                                     	WHERE Id = :testWO.Id];
    
        // Create the oldWosMap by mapping the old WorkOrder records by their Id
        Map<Id, WorkOrder> oldWosMap = new Map<Id, WorkOrder>();
        for (WorkOrder oldWO : oldWOList) {
            oldWosMap.put(oldWO.Id, oldWO);
        }
    
        // Call the WorkOrderStatusAfterUpdate method with the new and old WorkOrders
        WorkOrderStatusHandler.WorkOrderStatusAfterUpdate(newWOList, oldWosMap);
        
        Test.stopTest();
    }
}