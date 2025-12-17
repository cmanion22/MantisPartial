@isTest
public class AddNoteCollaboratorOnActivityClassTest {
    
    @isTest
    public static void testAddCollaboratorToNotes() {
        // Step 1: Create test data
        
        try {
            // Generate unique username suffix to avoid the duplicate username error
            String uniqueUsername = 'testuser' + Math.abs(Crypto.getRandomInteger()) + '@test.com';
            
            // Create a test User who will be the old owner
            Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
            User oldOwner = new User(
                Alias = 'olduser', 
                Email = 'olduser@test.com', 
                EmailEncodingKey = 'UTF-8', 
                LastName = 'OldUser', 
                LanguageLocaleKey = 'en_US', 
                LocaleSidKey = 'en_US', 
                ProfileId = p.Id, 
                TimeZoneSidKey = 'America/Los_Angeles', 
                UserName = uniqueUsername
            );
            insert oldOwner;
            System.debug('Old Owner created: ' + oldOwner.Id);
            
            // Generate unique username for the new owner
            String newUniqueUsername = 'newuser' + Math.abs(Crypto.getRandomInteger()) + '@test.com';
            
            // Create a test User who will be the new owner
            User newOwner = new User(
                Alias = 'newuser', 
                Email = 'newuser@test.com', 
                EmailEncodingKey = 'UTF-8', 
                LastName = 'NewUser', 
                LanguageLocaleKey = 'en_US', 
                LocaleSidKey = 'en_US', 
                ProfileId = p.Id, 
                TimeZoneSidKey = 'America/Los_Angeles', 
                UserName = newUniqueUsername
            );
            insert newOwner;
            System.debug('New Owner created: ' + newOwner.Id);
    
            // Step 2: Create an Event (Activity)
            Event testEvent = new Event(
                Subject = 'Test Event',
                StartDateTime = System.now(),
                EndDateTime = System.now().addHours(1),
                OwnerId = oldOwner.Id
            );
            insert testEvent;
            System.debug('Test Event created: ' + testEvent.Id);

            // Step 3: Create a ContentNote (associated with Event)
            ContentNote testNote = new ContentNote();
            testNote.Title = 'Test Note';
            testNote.Content = Blob.valueOf('Test Content');
            insert testNote;
            System.debug('Test Note created: ' + testNote.Id);
            
            // Link the note to the event using ContentDocumentLink
            ContentDocumentLink docLink = new ContentDocumentLink();
            docLink.ContentDocumentId = testNote.Id;
            docLink.LinkedEntityId = testEvent.Id; // Linking note to event
            docLink.ShareType = 'V';
            docLink.Visibility = 'AllUsers';
            insert docLink;
            System.debug('Note linked to Event via ContentDocumentLink: ' + docLink.Id);
    
            // Step 4: Set up test data for OwnerChangeRequest
            AddNoteCollaboratorOnActivityClass.OwnerChangeRequest changeRequest = new AddNoteCollaboratorOnActivityClass.OwnerChangeRequest();
            changeRequest.eventId = testEvent.Id;
            changeRequest.newOwnerId = newOwner.Id;
            
            List<AddNoteCollaboratorOnActivityClass.OwnerChangeRequest> requestList = new List<AddNoteCollaboratorOnActivityClass.OwnerChangeRequest>{changeRequest};
    
            // Step 5: Call the invocable method in test context
            Test.startTest();
            AddNoteCollaboratorOnActivityClass.addCollaboratorToNotes(requestList);
            Test.stopTest();
    
            // Step 6: Verify that the new ContentDocumentLink was created for the new owner
            List<ContentDocumentLink> collaborators = [SELECT Id, LinkedEntityId, ContentDocumentId 
                                                      FROM ContentDocumentLink 
                                                      WHERE LinkedEntityId = :newOwner.Id 
                                                      AND ContentDocumentId = :testNote.Id];
            
            System.assertEquals(1, collaborators.size(), 'The new owner should be added as a collaborator to the note.');
            System.debug('Test successful. Collaborator added: ' + collaborators[0].Id);
            
        } catch (Exception e) {
            System.debug('Test failed: ' + e.getMessage());
            throw e; // Re-throwing to ensure the test still fails if there is an error
        }
    }
}