public with sharing class EventMeetingNotesController {
    @InvocableMethod(label='Create BD Meeting Notes')
    public static void createBDMeetingNotes(List<EventMeetingNotesWrapper> requests) {
        if (requests == null || requests.isEmpty()) {
            throw new IllegalArgumentException('No requests provided');
        }

        EventMeetingNotesWrapper request = requests.get(0);

        if (request.eventIds == null || request.eventIds.isEmpty()) {
            throw new IllegalArgumentException('No event Ids provided');
        }

        // Query Events based on the list of Ids
        List<Event> events = [SELECT Id, OwnerId, WhatId FROM Event WHERE Id IN :request.eventIds];

        // Validate that we have at least one event
        if (events.isEmpty()) {
            throw new IllegalArgumentException('No events found for the provided Ids');
        }

        // Create ContentNote List
        List<ContentNote> notesToInsert = new List<ContentNote>();

        ContentNote preNote = new ContentNote();
        preNote.Title = request.preTitle;
        notesToInsert.add(preNote);

        ContentNote postNote = new ContentNote();
        postNote.Title = request.postTitle;
        notesToInsert.add(postNote);

        // Insert the notes
        insert notesToInsert;

        // Since ContentNote Ids are the same as ContentDocument Ids
        Set<Id> contentNoteIds = new Set<Id>();
        for (ContentNote note : notesToInsert) {
            contentNoteIds.add(note.Id);
        }

        // Query ContentDocument records using the ContentNote Ids
        List<ContentDocument> meetingDocuments = [SELECT Id FROM ContentDocument WHERE Id IN :contentNoteIds];

        // Link notes to events and associated accounts
        linkMeetingNotes(meetingDocuments, events);
    }

    private static void linkMeetingNotes(List<ContentDocument> meetingDocuments, List<Event> events) {
        // Initialize lists for ContentDocumentLink records
        List<ContentDocumentLink> cdlEvents = new List<ContentDocumentLink>();
        List<ContentDocumentLink> cdlAccounts = new List<ContentDocumentLink>();
    
        // Iterate over events and documents to create ContentDocumentLinks
        for (Event eventRecord : events) {
            for (ContentDocument doc : meetingDocuments) {
                // Link documents to events
                ContentDocumentLink cdlEvent = new ContentDocumentLink();
                cdlEvent.ContentDocumentId = doc.Id;
                cdlEvent.LinkedEntityId = eventRecord.Id;
                cdlEvent.ShareType = 'V'; // Viewer access
                cdlEvents.add(cdlEvent);
    
                // Link documents to accounts if WhatId is an Account
                if (eventRecord.WhatId != null && eventRecord.WhatId.getSObjectType() == Account.SObjectType) {
                    ContentDocumentLink cdlAccount = new ContentDocumentLink();
                    cdlAccount.ContentDocumentId = doc.Id;
                    cdlAccount.LinkedEntityId = eventRecord.WhatId; // Directly use WhatId
                    cdlAccount.ShareType = 'V'; // Viewer access
                    cdlAccounts.add(cdlAccount);
                }
            }
        }
    
        // Insert Content Document Link Records
        if (!cdlEvents.isEmpty()) {
            try {
                insert cdlEvents;
            } catch (DmlException e) {
                // Handle DML exception (log error, rethrow, etc.)
                System.debug('Failed to insert ContentDocumentLinks for events: ' + e.getMessage());
            }
        }
        if (!cdlAccounts.isEmpty()) {
            try {
                insert cdlAccounts;
            } catch (DmlException e) {
                // Handle DML exception (log error, rethrow, etc.)
                System.debug('Failed to insert ContentDocumentLinks for accounts: ' + e.getMessage());
            }
        }
    }
}