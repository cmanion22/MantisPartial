@isTest
public class UnanetProjectSyncQueueableTest {

    @isTest
    public static void testUnanetProjectSyncQueueable() {
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

        Project__c proj = new Project__c(
            Name='Standard Project',
            Account__c=acc.Id,
            Opportunity__c=opp.Id,
            Project_Number__c='PRJ-001',
            Start_Date__c=Date.today(),
            End_Date__c=Date.today().addMonths(1),
            Total_Contract_Value__c=50000,
            Type__c='Standard',
            Unanet_Project_Type__c='BID',
            Service_Area__c='FMS',
            Type_of_Service__c='Bid',
            Service_Street__c='123 Main St',
            Service_City__c='Orlando',
            Project_Requires_TASKS__c='Yes'
        );
        insert proj;

        Test.startTest();
        System.enqueueJob(new UnanetProjectSyncQueueable(opp.Id, 'mockToken'));
        Test.stopTest();

    }
    
    @isTest
    public static void testNoUnanetIdAcc() {
        Test.setMock(HttpCalloutMock.class, new UnanetHttpMock());

        Account acc = new Account(Name='Test Account', CurrencyIsoCode='USD');
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

        Project__c proj = new Project__c(
            Name='Standard Project',
            Account__c=acc.Id,
            Opportunity__c=opp.Id,
            Project_Number__c='PRJ-001',
            Start_Date__c=Date.today(),
            End_Date__c=Date.today().addMonths(1),
            Total_Contract_Value__c=50000,
            Type__c='Standard',
            Unanet_Project_Type__c='BID',
            Service_Area__c='FMS',
            Type_of_Service__c='Bid',
            Service_Street__c='123 Main St',
            Service_City__c='Orlando',
            Project_Requires_TASKS__c='Yes'
        );
        insert proj;

        Test.startTest();
        System.enqueueJob(new UnanetProjectSyncQueueable(opp.Id, 'mockToken'));
        Test.stopTest();
    }

}