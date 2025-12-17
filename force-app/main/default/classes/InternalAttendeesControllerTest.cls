@isTest
public class InternalAttendeesControllerTest {
	
    @isTest public static void createEventWithAttendee() {
        
        // Create User
        Profile testProfile = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User testUser = new User(Alias = 'standt', Email='testuser@emex.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = testProfile.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='emextestuser@emex.com'
            );
            
        insert testUser;
        
        // Create Event
        Event newEvent = new Event();
        newEvent.Subject = 'TestingSubject';
        newEvent.StartDateTime = System.now();
        newEvent.EndDateTime = System.now();
        insert newEvent;
        
        
		
		// Create Internal Attendee
		Internal_Attendees__c newAttendee = new Internal_Attendees__c();
        newAttendee.Event_Id__c = newEvent.Id;
        newAttendee.Attendee__c = testUser.Id;
        
        insert newAttendee;
        
        Test.startTest();    
        
        Event testEvent = [SELECT Id FROM Event WHERE Id = :newEvent.Id LIMIT 1];
        Id eventId = testEvent.Id;
        InternalAttendeesController.getInternalAttendees(eventId);
                
        Test.stopTest();


    }
    
    @isTest public static void createInternalAttendeeTest() {
        
        // Create User
        Profile testProfile = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User testUser = new User(Alias = 'standt', Email='testuser@emex.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = testProfile.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='emextestuser@emex.com'
            );
            
        insert testUser;
        
        // Create Event
        Event newEvent = new Event();
        newEvent.Subject = 'TestingSubject';
        newEvent.StartDateTime = System.now();
        newEvent.EndDateTime = System.now();
        insert newEvent;
        
        
		
		// Create Internal Attendee
		Internal_Attendees__c newAttendee = new Internal_Attendees__c();
        newAttendee.Event_Id__c = newEvent.Id;
        newAttendee.Attendee__c = testUser.Id;
        
        insert newAttendee;
        
        Test.startTest();    
        
        Event testEvent = [SELECT Id, Subject FROM Event WHERE Id = :newEvent.Id LIMIT 1];
        Id eventId = testEvent.Id;
        
        String eventName = testEvent.Subject;
        
        User attendeeUser = [SELECT Id FROM User WHERE Id = :testUser.Id];
        Id attendeeId = attendeeUser.Id;
        
        InternalAttendeesController.createInternalAttendee(eventId, eventName, attendeeId);
        
        Test.stopTest();
    }

    @isTest public static void deleteInternalAttendeeTest() {
         // Create User
         Profile testProfile = [SELECT Id FROM Profile WHERE Name='Standard User']; 
         User testUser = new User(Alias = 'standt', Email='testuser@emex.com', 
             EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
             LocaleSidKey='en_US', ProfileId = testProfile.Id, 
             TimeZoneSidKey='America/Los_Angeles', UserName='emextestuser@emex.com'
             );
             
         insert testUser;
         
         // Create Event
         Event newEvent = new Event();
         newEvent.Subject = 'TestingSubject';
         newEvent.StartDateTime = System.now();
         newEvent.EndDateTime = System.now();
         insert newEvent;
         
         
         
         // Create Internal Attendee
         Internal_Attendees__c newAttendee = new Internal_Attendees__c();
         newAttendee.Event_Id__c = newEvent.Id;
         newAttendee.Attendee__c = testUser.Id;
         
         insert newAttendee;
         
         Test.startTest();    
         
         Event testEvent = [SELECT Id, Subject FROM Event WHERE Id = :newEvent.Id LIMIT 1];
         Id eventId = testEvent.Id;
         
         String eventName = testEvent.Subject;
         
         Internal_Attendees__c attendeeUser = [SELECT Id FROM Internal_Attendees__c WHERE Id = :newAttendee.Id];
         Id attendeeId = attendeeUser.Id;
         
         InternalAttendeesController.deleteInternalAttendee(attendeeId);
         
         Test.stopTest();
    }
}