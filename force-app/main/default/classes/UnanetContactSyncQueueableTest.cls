@isTest
private class UnanetContactSyncQueueableTest {
    @testSetup
    static void setup() {
        Contact con = new Contact(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'mock@example.com',
            Phone = '1234567890',
            MailingStreet = '123 Main St',
            MailingCity = 'City',
            MailingState = 'CA',
            MailingPostalCode = '90210',
            MailingCountry = 'USA'
        );
        insert con;

        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Qualification',
            CloseDate = Date.today().addDays(30)
        );
        insert opp;
    }

    @isTest
    static void testContactSync() {
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new UnanetContactHttpMock());

        Test.startTest();
        System.enqueueJob(new UnanetContactSyncQueueable(con.Id, opp.Id, '100', 'mocked_token'));
        Test.stopTest();

        con = [SELECT Unanet_Id__c FROM Contact WHERE Id = :con.Id];
        System.assertNotEquals(null, con.Unanet_Id__c, 'Contact should have Unanet_Id__c populated');
    }
    
    @isTest
    static void testNoContactFoundSync() {
        
        Contact con = new Contact(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'noMatch@example.com',
            Phone = '1234567890',
            MailingStreet = '123 Main St',
            MailingCity = 'City',
            MailingState = 'CA',
            MailingPostalCode = '90210',
            MailingCountry = 'USA'
        );
        insert con;
        
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new UnanetContactHttpMock());

        Test.startTest();
        System.enqueueJob(new UnanetContactSyncQueueable(con.Id, opp.Id, '100', 'mocked_token'));
        Test.stopTest();

    }
    
    @isTest
    static void testNoEmailFoundSync() {
        
        Contact con = new Contact(
            FirstName = 'Test',
            LastName = 'User',
            Email = null,
            Phone = '1234567890',
            MailingStreet = '123 Main St',
            MailingCity = 'City',
            MailingState = 'CA',
            MailingPostalCode = '90210',
            MailingCountry = 'USA'
        );
        insert con;
        
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new UnanetContactHttpMock());

        Test.startTest();
        System.enqueueJob(new UnanetContactSyncQueueable(con.Id, opp.Id, '100', 'mocked_token'));
        Test.stopTest();

    }
    
    @isTest
    static void testNoTokenFoundSync() {
        
        Contact con = new Contact(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'noMatch@example.com',
            Phone = '1234567890',
            MailingStreet = '123 Main St',
            MailingCity = 'City',
            MailingState = 'CA',
            MailingPostalCode = '90210',
            MailingCountry = 'USA'
        );
        insert con;
        
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new UnanetContactHttpMock());

        Test.startTest();
        System.enqueueJob(new UnanetContactSyncQueueable(con.Id, opp.Id, '100', null));
        Test.stopTest();

    }
}