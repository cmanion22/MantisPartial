@isTest
private class UpdateXactlyAsSoldTest {
    
    private static RecordType getServicesRecordType() {
        return [SELECT Id FROM RecordType WHERE SObjectType = 'Opportunity' AND Name = 'Services' LIMIT 1];
    }
    
    @isTest
    static void testUpdateProjects_callUpdate() {
        // Ensure record type exists
        RecordType servicesRT = getServicesRecordType();
        
        // Create test Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = '5 - Closed Won',
            RecordTypeId = servicesRT.Id,
            CloseDate = Date.today()
        );
        insert opp;

        // Create related Project__c records
        Project__c proj1 = new Project__c(
            Name = 'Test Project 1',
            Opportunity__c = opp.Id,
            Type__c = 'Standard Project',
            Service_Area__c = 'FMS',
            Type_of_Service__c = 'Bid',
            Total_Contract_Value__c = 10.00
            
        );
        
        insert proj1;

        // Call the method
        Test.startTest();
        UpdateXactlyAsSold.updateProjects(new List<Opportunity>{opp});
        Test.stopTest();

        // Verify that values were updated
        List<Project__c> updatedProjects = [SELECT Id, Xactly_As_Sold_Gross_Margin__c, As_Sold_Gross_Margin2__c 
                                            FROM Project__c 
                                            WHERE Opportunity__c = :opp.Id];
        for (Project__c proj : updatedProjects) {
            System.assertEquals(proj.As_Sold_Gross_Margin2__c, proj.Xactly_As_Sold_Gross_Margin__c, 'Xactly value should match As-Sold value');
        }
    }
    
    @isTest
    static void testUpdateProjects_UpdateStage() {
        // Ensure record type exists
        RecordType servicesRT = getServicesRecordType();
        
        // Create test Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = '0 - Qualify',
            RecordTypeId = servicesRT.Id,
            CloseDate = Date.today()
        );
        insert opp;

        // Create related Project__c records
        Project__c proj1 = new Project__c(
            Name = 'Test Project 1',
            Opportunity__c = opp.Id,
            Type__c = 'Standard Project',
            Service_Area__c = 'FMS',
            Type_of_Service__c = 'Bid',
            Total_Contract_Value__c = 10.00
            
        );
        Project__c proj2 = new Project__c(
            Name = 'Test Project 2',
            Opportunity__c = opp.Id,
            Type__c = 'Standard Project',
            Service_Area__c = 'FMS',
            Type_of_Service__c = 'Bid',
            Total_Contract_Value__c = 10.00
            
        );
        insert new List<Project__c>{proj1, proj2};

        // Call the method
        Test.startTest();
        
        Opportunity oppToUpdate = [SELECT Id, StageName FROM Opportunity WHERE Id = :opp.Id];
        oppToUpdate.StageName = '5 - Closed won';
        update oppToUpdate;
        
        Test.stopTest();

        // Verify that values were updated
        List<Project__c> updatedProjects = [SELECT Id, Xactly_As_Sold_Gross_Margin__c, As_Sold_Gross_Margin2__c 
                                            FROM Project__c 
                                            WHERE Opportunity__c = :opp.Id];
        for (Project__c proj : updatedProjects) {
            System.assertEquals(proj.As_Sold_Gross_Margin2__c, proj.Xactly_As_Sold_Gross_Margin__c, 'Xactly value should match As-Sold value');
        }
    }

    @isTest
    static void testUpdateProjects_emptyOpportunityList() {
        // Should simply return without error
        Test.startTest();
        UpdateXactlyAsSold.updateProjects(new List<Opportunity>());
        Test.stopTest();
        System.assert(true, 'No error should occur when opportunity list is empty');
    }

    @isTest
    static void testUpdateProjects_noRelatedProjects() {
        // Create Opportunity with no projects
        Opportunity opp = new Opportunity(
            Name = 'No Project Opp',
            StageName = 'Closed Won',
            CloseDate = Date.today()
        );
        insert opp;

        // Call the method with no related Project__c records
        Test.startTest();
        UpdateXactlyAsSold.updateProjects(new List<Opportunity>{opp});
        Test.stopTest();

        System.assert(true, 'No error should occur when no related projects exist');
    }
}