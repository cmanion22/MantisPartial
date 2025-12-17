@isTest
private class ProjectNumberHandlerTest {

    @isTest
    static void testAssignNumbersForOpportunity() {
        // Insert sequence record
        AutoNumber_Sequence__c seq = new AutoNumber_Sequence__c(
            Name = 'Project',
            Current_AutoNumber__c = '1000'
        );
        insert seq;

        // Create parent Opp for CO
        Opportunity parentOpp = new Opportunity(
            Name = 'Parent Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            Service_Area__c = 'FMS',
            Type_of_Service__c = 'Bid'
        );
        insert parentOpp;

        // Create child Opp that will run ProjectNumberHandler
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            Service_Area__c = 'FMS',
            Type_of_Service__c = 'Bid',
            Parent_Opportunity__c = parentOpp.Id
        );
        insert opp;

        // Create Standard Project linked to opp
        Project__c standardProject = new Project__c(
            Name = 'Standard 1',
            Type__c = 'Standard Project',
            Opportunity__c = opp.Id,
            Service_Area__c = 'FMS',
            Type_of_Service__c = 'Bid'
        );
        insert standardProject;

        // Create PT and EXP Projects linked to standard
        Project__c ptProject = new Project__c(
            Name = 'PT Child',
            Type__c = 'PT',
            Service_Area__c = 'FMS',
            Type_of_Service__c = 'Bid',
            Parent_Project__c = standardProject.Id,
            Opportunity__c = opp.Id
        );

        Project__c expProject = new Project__c(
            Name = 'EXP Child',
            Type__c = 'EXP',
            Parent_Project__c = standardProject.Id,
            Opportunity__c = opp.Id,
            Service_Area__c = 'FMS',
            Type_of_Service__c = 'Bid'
        );
        insert new List<Project__c>{ ptProject, expProject };

        // Create Standard Project under parentOpp for COs to link to
        Project__c coParentProject = new Project__c(
            Name = 'CO Parent Project',
            Type__c = 'Standard Project',
            Opportunity__c = parentOpp.Id,
            Service_Area__c = 'FMS',
            Type_of_Service__c = 'Bid'
        );
        insert coParentProject;

        // Create Change Order project linked to opp but parented to parentOpp's standard project
        Project__c changeOrder = new Project__c(
            Name = 'Change Order 1',
            Type__c = 'Change Order',
            Parent_Project__c = coParentProject.Id,
            Opportunity__c = opp.Id,
            Service_Area__c = 'FMS',
            Type_of_Service__c = 'Bid'
        );
        insert changeOrder;

        // Create PT/EXP under CO
        Project__c coPt = new Project__c(
            Name = 'CO PT',
            Type__c = 'PT',
            Parent_Project__c = changeOrder.Id,
            Opportunity__c = opp.Id,
            Service_Area__c = 'FMS',
            Type_of_Service__c = 'Bid'
        );

        Project__c coExp = new Project__c(
            Name = 'CO EXP',
            Type__c = 'EXP',
            Parent_Project__c = changeOrder.Id,
            Opportunity__c = opp.Id,
            Service_Area__c = 'FMS',
            Type_of_Service__c = 'Bid'
        );

        insert new List<Project__c>{ coPt, coExp };

        // Run the method
        Test.startTest();
        ProjectNumberHandler.assignNumbersForOpportunity(opp, parentOpp.Id);
        Test.stopTest();
    }
    
    @isTest
    static void testUpdateOpportunityToClosed() {
        // Insert sequence record
        AutoNumber_Sequence__c seq = new AutoNumber_Sequence__c(
            Name = 'Project',
            Current_AutoNumber__c = '1000'
        );
        insert seq;

        // Create parent Opp for CO
        Opportunity parentOpp = new Opportunity(
            Name = 'Parent Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            Service_Area__c = 'FMS',
            Type_of_Service__c = 'Bid',
            Agreement_Type__c = 'Standard Agreement'
        );
        insert parentOpp;

        // Create child Opp that will run ProjectNumberHandler
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            Service_Area__c = 'FMS',
            Type_of_Service__c = 'Bid',
            Agreement_Type__c = 'Standard Agreement',
            Parent_Opportunity__c = parentOpp.Id
        );
        insert opp;

        // Create Standard Project linked to opp
        Project__c standardProject = new Project__c(
            Name = 'Standard 1',
            Type__c = 'Standard Project',
            Opportunity__c = opp.Id,
            Service_Area__c = 'FMS',
            Type_of_Service__c = 'Bid'
        );
        insert standardProject;

        // Create PT and EXP Projects linked to standard
        Project__c ptProject = new Project__c(
            Name = 'PT Child',
            Type__c = 'PT',
            Service_Area__c = 'FMS',
            Type_of_Service__c = 'Bid',
            Parent_Project__c = standardProject.Id,
            Opportunity__c = opp.Id
        );

        Project__c expProject = new Project__c(
            Name = 'EXP Child',
            Type__c = 'EXP',
            Parent_Project__c = standardProject.Id,
            Opportunity__c = opp.Id,
            Service_Area__c = 'FMS',
            Type_of_Service__c = 'Bid'
        );
        insert new List<Project__c>{ ptProject, expProject };

        // Create Standard Project under parentOpp for COs to link to
        Project__c coParentProject = new Project__c(
            Name = 'CO Parent Project',
            Type__c = 'Standard Project',
            Opportunity__c = parentOpp.Id,
            Service_Area__c = 'FMS',
            Type_of_Service__c = 'Bid'
        );
        insert coParentProject;

        // Create Change Order project linked to opp but parented to parentOpp's standard project
        Project__c changeOrder = new Project__c(
            Name = 'Change Order 1',
            Type__c = 'Change Order',
            Parent_Project__c = coParentProject.Id,
            Opportunity__c = opp.Id,
            Service_Area__c = 'FMS',
            Type_of_Service__c = 'Bid'
        );
        insert changeOrder;

        // Create PT/EXP under CO
        Project__c coPt = new Project__c(
            Name = 'CO PT',
            Type__c = 'PT',
            Parent_Project__c = changeOrder.Id,
            Opportunity__c = opp.Id,
            Service_Area__c = 'FMS',
            Type_of_Service__c = 'Bid'
        );

        Project__c coExp = new Project__c(
            Name = 'CO EXP',
            Type__c = 'EXP',
            Parent_Project__c = changeOrder.Id,
            Opportunity__c = opp.Id,
            Service_Area__c = 'FMS',
            Type_of_Service__c = 'Bid'
        );

        insert new List<Project__c>{ coPt, coExp };

        // Run the method
        Test.startTest();
        
        Opportunity testOpp = [SELECT Id, StageName FROM Opportunity WHERE Id = :opp.Id];
        testOpp.StageName = '5 - Closed Won';
        Update testOpp;
        
        Test.stopTest();
    }
    
    @isTest
    static void testChangeOrderWithPTParent() {
        AutoNumber_Sequence__c seq = new AutoNumber_Sequence__c(
            Name = 'Project',
            Current_AutoNumber__c = '1000'
        );
        insert seq;
    
        Opportunity grandParentOpp = new Opportunity(
            Name = 'Grandparent Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            Service_Area__c = 'FMS',
            Type_of_Service__c = 'Bid'
        );
        insert grandParentOpp;
    
        // Grandparent: Standard Project (Type = 'Standard Project')
        Project__c stdProject = new Project__c(
            Name = 'Standard Project',
            Type__c = 'Standard Project',
            Opportunity__c = grandParentOpp.Id,
            Service_Area__c = 'FMS',
            Type_of_Service__c = 'Bid'
        );
        insert stdProject;
    
        Opportunity parentOpp = new Opportunity(
            Name = 'Parent Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            Service_Area__c = 'FMS',
            Type_of_Service__c = 'Bid',
            Parent_Opportunity__c = grandParentOpp.Id
        );
        insert parentOpp;
    
        // Parent: PT Project (Type = 'PT', Parent_Project__c = stdProject.Id)
        Project__c ptProject = new Project__c(
            Name = 'PT Project',
            Type__c = 'PT',
            Parent_Project__c = stdProject.Id,
            Opportunity__c = parentOpp.Id,
            Service_Area__c = 'FMS',
            Type_of_Service__c = 'Bid'
        );
        insert ptProject;
    
        Opportunity opp = new Opportunity(
            Name = 'Child Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            Service_Area__c = 'FMS',
            Type_of_Service__c = 'Bid',
            Parent_Opportunity__c = parentOpp.Id
        );
        insert opp;
    
        // Change Order: child of PT project
        Project__c coProject = new Project__c(
            Name = 'Change Order',
            Type__c = 'Change Order',
            Parent_Project__c = ptProject.Id,
            Opportunity__c = opp.Id,
            Service_Area__c = 'FMS',
            Type_of_Service__c = 'Bid'
        );
        insert coProject;
    
        // Child projects under Change Order (required by the code for coChildProjects)
        Project__c coChildPT = new Project__c(
            Name = 'CO Child PT',
            Type__c = 'PT',
            Parent_Project__c = coProject.Id,
            Opportunity__c = opp.Id,
            Service_Area__c = 'FMS',
            Type_of_Service__c = 'Bid'
        );
    
        Project__c coChildEXP = new Project__c(
            Name = 'CO Child EXP',
            Type__c = 'EXP',
            Parent_Project__c = coProject.Id,
            Opportunity__c = opp.Id,
            Service_Area__c = 'FMS',
            Type_of_Service__c = 'Bid'
        );
    
        insert new List<Project__c>{ coChildPT, coChildEXP };
    
        Test.startTest();
        ProjectNumberHandler.assignNumbersForOpportunity(opp, null);
        Test.stopTest();
    }

}