@isTest
public class UnanetCreateFixedPriceItemsQueueableTest {
    @isTest
    public static void testUnanetCreateFixedPriceItemsQueueable() {
        Test.setMock(HttpCalloutMock.class, new UnanetHttpMock());

        Account acc = new Account(Name='Test Account', CurrencyIsoCode='USD', Unanet_Id__c='1');
        insert acc;

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

        // Parent project
        Project__c parentProj = new Project__c(
            Name='Parent Project',
            Account__c=acc.Id,
            Opportunity__c=opp.Id,
            Project_Number__c='PRJ-100',
            Start_Date__c=Date.today(),
            End_Date__c=Date.today().addMonths(1),
            Total_Contract_Value__c=100000,
            Type__c='Standard Project',
            Unanet_Project_Type__c='BID',
            Service_Area__c='FMS',
            Type_of_Service__c='Bid',
            Service_Street__c='111 Parent St',
            Service_City__c='Jacksonville',
            Project_Requires_TASKS__c='Yes',
            Unanet_Id__c='123'
        );
        insert parentProj;
        
        // Change Order project (child)
        Project__c coProj = new Project__c(
            Name='Change Order Project',
            Account__c=acc.Id,
            Opportunity__c=opp.Id,
            Parent_Project__c=parentProj.Id,
            Project_Number__c='PRJ-101',
            Start_Date__c=Date.today(),
            End_Date__c=Date.today().addMonths(1),
            Total_Contract_Value__c=30000,
            Type__c='Change Order',
            Unanet_Project_Type__c='BID',
            Service_Area__c='FMS',
            Type_of_Service__c='Change',
            Service_Street__c='222 Child St',
            Service_City__c='Tampa',
            Project_Requires_TASKS__c='No'
        );
        insert coProj;
        

        Test.startTest();
        System.enqueueJob(new UnanetCreateFixedPriceItemsQueueable(new List<Project__c>{coProj},'mockToken', 'mockBaseUrl'));
        Test.stopTest();
    }
    
    @isTest
    public static void testNoParentUnanetId() {
        Test.setMock(HttpCalloutMock.class, new UnanetHttpMock());

        Account acc = new Account(Name='Test Account', CurrencyIsoCode='USD', Unanet_Id__c='1');
        insert acc;

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

        // Parent project
        Project__c parentProj = new Project__c(
            Name='Parent Project',
            Account__c=acc.Id,
            Opportunity__c=opp.Id,
            Project_Number__c='PRJ-100',
            Start_Date__c=Date.today(),
            End_Date__c=Date.today().addMonths(1),
            Total_Contract_Value__c=100000,
            Type__c='Standard Project',
            Unanet_Project_Type__c='BID',
            Service_Area__c='FMS',
            Type_of_Service__c='Bid',
            Service_Street__c='111 Parent St',
            Service_City__c='Jacksonville',
            Project_Requires_TASKS__c='Yes'
        );
        insert parentProj;
        
        // Change Order project (child)
        Project__c coProj = new Project__c(
            Name='Change Order Project',
            Account__c=acc.Id,
            Opportunity__c=opp.Id,
            Parent_Project__c=parentProj.Id,
            Project_Number__c='PRJ-101',
            Start_Date__c=Date.today(),
            End_Date__c=Date.today().addMonths(1),
            Total_Contract_Value__c=30000,
            Type__c='Change Order',
            Unanet_Project_Type__c='BID',
            Service_Area__c='FMS',
            Type_of_Service__c='Change',
            Service_Street__c='222 Child St',
            Service_City__c='Tampa',
            Project_Requires_TASKS__c='No'
        );
        insert coProj;
        

        Test.startTest();
        System.enqueueJob(new UnanetCreateFixedPriceItemsQueueable(new List<Project__c>{coProj},'mockToken', 'mockBaseUrl'));
        Test.stopTest();
    }
    
    @isTest
    public static void testNoParentId() {
        Test.setMock(HttpCalloutMock.class, new UnanetHttpMock());

        Account acc = new Account(Name='Test Account', CurrencyIsoCode='USD', Unanet_Id__c='1');
        insert acc;

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

        // Parent project
        Project__c parentProj = new Project__c(
            Name='Parent Project',
            Account__c=acc.Id,
            Opportunity__c=opp.Id,
            Project_Number__c='PRJ-100',
            Start_Date__c=Date.today(),
            End_Date__c=Date.today().addMonths(1),
            Total_Contract_Value__c=100000,
            Type__c='Standard Project',
            Unanet_Project_Type__c='BID',
            Service_Area__c='FMS',
            Type_of_Service__c='Bid',
            Service_Street__c='111 Parent St',
            Service_City__c='Jacksonville',
            Project_Requires_TASKS__c='Yes'
        );
        insert parentProj;
        
        // Change Order project (child)
        Project__c coProj = new Project__c(
            Name='Change Order Project',
            Account__c=acc.Id,
            Opportunity__c=opp.Id,
            Project_Number__c='PRJ-101',
            Start_Date__c=Date.today(),
            End_Date__c=Date.today().addMonths(1),
            Total_Contract_Value__c=30000,
            Type__c='Change Order',
            Unanet_Project_Type__c='BID',
            Service_Area__c='FMS',
            Type_of_Service__c='Change',
            Service_Street__c='222 Child St',
            Service_City__c='Tampa',
            Project_Requires_TASKS__c='No'
        );
        insert coProj;
        

        Test.startTest();
        System.enqueueJob(new UnanetCreateFixedPriceItemsQueueable(new List<Project__c>{coProj}, 'mockToken', 'mockBaseUrl'));
        Test.stopTest();
    }

}