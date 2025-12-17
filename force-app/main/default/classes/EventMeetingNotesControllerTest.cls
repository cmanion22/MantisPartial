@isTest
public class EventMeetingNotesControllerTest {

    @isTest
    public static void createMeetingNotes() {
        
        // Insert configuration and custom settings records
        insert new Configuration__c(Name = 'ESBURL');
        insert new Back_Office_Integration_Settings__c(Name = 'Staging', Endpoint_URL__c = 'https://www.example.com');
        insert new Back_Office_Integration_Settings__c(Name = 'Production', Endpoint_URL__c = 'https://www.example.com');
        
        // Create and insert test Entity
        Entity__c testEntity = new Entity__c();
        testEntity.Name = 'Funny1 Entity';
        testEntity.Brand__c = 'Funny1 Brand';
        testEntity.Source_ID__c = null;
        testEntity.Source_Database__c = null;      
        insert testEntity;
        
        // Create and insert test User
        Profile testProfile = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User testUser = new User(
            Alias = 'stand', 
            Email = 'testuser125@emex.com', 
            EmailEncodingKey = 'UTF-8', 
            FirstName = 'Funny',
            LastName = 'Usey',
            LanguageLocaleKey = 'en_US', 
            LocaleSidKey = 'en_US', 
            ProfileId = testProfile.Id, 
            TimeZoneSidKey = 'America/Los_Angeles', 
            UserName = 'emextestuserfunny@emex.com',
            Entity_ID__c = testEntity.Id, 
            Entity_Name__c = testEntity.Name, 
            API_Token__c = 'funny'
        );
        insert testUser;
       
        // Create and insert test Account
        Account acc = new Account();
        acc.Name = 'Funny Account';
        acc.Legal_Entity_Name__c = 'Sample Account';
        acc.Phone = '111111128';
        acc.Entity__c = testEntity.Id;
        acc.OwnerId = testUser.Id; 
        acc.BackOfficeId__c = 'UniqueBO12345';
        insert acc;
        
        // Create and insert test Event
        Event myEvent = new Event();
        myEvent.Subject = 'testing1243';
        myEvent.Type = 'BD Meeting';
        myEvent.StartDateTime = DateTime.now();
        myEvent.EndDateTime = DateTime.now().addHours(1); // Ensure EndDateTime is after StartDateTime
        myEvent.WhatId = acc.Id;
        insert myEvent;
        
        // Create Pre & Post Meeting Notes Title
        String preMeetingNotesTitle = 'Winterfell - 8/23/24 - Pre-Meeting Notes';
        String postMeetingNotesTitle = 'Winterfell - 8/23/24 - Post-Meeting Notes';
        
        // Set the mock response class
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        Test.startTest();
        
        // Initialize wrapper class
        EventMeetingNotesWrapper wrapper = new EventMeetingNotesWrapper();
        wrapper.eventIds = new List<Id>(); // Initialize the list to avoid NullPointerException
        wrapper.eventIds.add(myEvent.Id);
        wrapper.preTitle = preMeetingNotesTitle;
        wrapper.postTitle = postMeetingNotesTitle;
        
        // Call the method to test
        EventMeetingNotesController.createBDMeetingNotes(new List<EventMeetingNotesWrapper> { wrapper });
        
        Test.stopTest();
        
        // Assertions for ContentNotes
        List<ContentNote> notes = [SELECT Id, Title FROM ContentNote WHERE Title IN :new List<String>{preMeetingNotesTitle, postMeetingNotesTitle}];
        System.assertEquals(2, notes.size(), 'ContentNotes were not created correctly.');

       
    }

    @isTest
    public static void testCreateBDMeetingNotes_NoRequests() {
        try {
            EventMeetingNotesController.createBDMeetingNotes(new List<EventMeetingNotesWrapper>());
            System.assert(false, 'Expected IllegalArgumentException was not thrown.');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('No requests provided'), 'Unexpected exception message: ' + e.getMessage());
        }
    }

    @isTest
    public static void testCreateBDMeetingNotes_NoEventIds() {
        EventMeetingNotesWrapper wrapper = new EventMeetingNotesWrapper();
        wrapper.eventIds = new List<Id>(); // Empty eventIds list

        try {
            EventMeetingNotesController.createBDMeetingNotes(new List<EventMeetingNotesWrapper> { wrapper });
            System.assert(false, 'Expected IllegalArgumentException was not thrown.');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('No event Ids provided'), 'Unexpected exception message: ' + e.getMessage());
        }
    }
}