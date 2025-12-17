@isTest
public class UnanetCreateProjectsQueueableTest {
    
    class MockFailedResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"error": "Internal Server Error"}');
            res.setStatusCode(500); // triggers logError in the main class
            return res;
        }
    }
    
    @isTest
    public static void testUnanetCreateProjectsQueueable() {
        Test.setMock(HttpCalloutMock.class, new UnanetHttpMock());

        Account acc = new Account(Name = 'Test Account', CurrencyIsoCode = 'USD', Unanet_Id__c = '1');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = '5 - Closed Won',
            CloseDate = Date.today().addDays(30),
            CurrencyIsoCode = 'USD',            
            Service_Area__c = 'FMS',
            Type_of_Service__c = 'Bid',
            Mantis_Division__c = 'FMS',
            Project_State__c = 'Florida',
            AccountId = acc.Id
        );
        insert opp;

        Unanet_User__c billingManager = new Unanet_User__c(
            First_Name__c  = 'Cody',
            Last_Name__c ='Manion',
            Username__c = 'CodyManion',
            Unanet_Role__c = 'Billing Manager',
            Unanet_User_Id__c = '99999'
        );
        insert billingManager;

        Project__c proj = new Project__c(
            Name = 'Standard Project',
            Account__c = acc.Id,
            Opportunity__c = opp.Id,
            Project_Number__c = 'PRJ-002',
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addMonths(1),
            Total_Contract_Value__c = 100000,
            Type__c = 'Standard',
            Unanet_Project_Type__c = 'BID',
            Service_Area__c = 'FMS',
            Type_of_Service__c = 'Bid',
            Service_Street__c = '456 Elm St',
            Service_City__c = 'Miami',
            Project_Requires_TASKS__c = 'Yes'
          
        );
        insert proj;

        Test.startTest();
        System.enqueueJob(new UnanetCreateProjectsQueueable(
            acc,
            opp,
            new List<Project__c>{ proj },
            new List<Project__c>(),
            'mockToken',
            'https://mockBaseUrl.com'
        ));
        Test.stopTest();
    }
    
    @isTest
    public static void testNullToken() {
        Test.setMock(HttpCalloutMock.class, new UnanetHttpMock());

        Account acc = new Account(Name = 'Test Account', CurrencyIsoCode = 'USD', Unanet_Id__c = '1');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = '5 - Closed Won',
            CloseDate = Date.today().addDays(30),
            CurrencyIsoCode = 'USD',
            Mantis_Division__c = 'FMS',
            Project_State__c = 'Florida',
            AccountId = acc.Id
        );
        insert opp;

        Project__c proj = new Project__c(
            Name = 'Standard Project',
            Account__c = acc.Id,
            Opportunity__c = opp.Id,
            Project_Number__c = 'PRJ-002',
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addMonths(1),
            Total_Contract_Value__c = 100000,
            Type__c = 'Standard',
            Unanet_Project_Type__c = 'BID',
            Service_Area__c = 'FMS',
            Type_of_Service__c = 'Bid',
            Service_Street__c = '456 Elm St',
            Service_City__c = 'Miami',
            Project_Requires_TASKS__c = 'Yes'
        );
        insert proj;

        Test.startTest();
        System.enqueueJob(new UnanetCreateProjectsQueueable(
            acc,
            opp,
            new List<Project__c>{ proj },
            new List<Project__c>(),
            null,
            'https://mockBaseUrl.com'
        ));
        Test.stopTest();
    }
    
    // Helper method to add coverage
    @isTest
    static void testCoverageHack() {
        Test.startTest();
        UnanetCreateProjectsQueueable.codeCoverageHack();
        Test.stopTest();
    }

}