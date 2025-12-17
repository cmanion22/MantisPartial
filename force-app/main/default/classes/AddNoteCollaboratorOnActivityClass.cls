public without sharing class AddNoteCollaboratorOnActivityClass {

    @InvocableMethod(label='Add Collaborator to Notes' description='Adds the new owner as a collaborator to all related notes of the Event')
    public static void addCollaboratorToNotes(List<OwnerChangeRequest> requests) {
        List<ContentDocumentLink> contentDocLinks = new List<ContentDocumentLink>();
        Set<Id> eventIds = new Set<Id>();
        Set<Id> newOwnerIds = new Set<Id>();

        // Collect all event and owner Ids to use in bulk queries
        for (OwnerChangeRequest request : requests) {
            eventIds.add(request.eventId);
            newOwnerIds.add(request.newOwnerId);
        }

        // Query all ContentDocumentLinks related to the events
        Map<Id, List<ContentDocumentLink>> relatedNotesMap = new Map<Id, List<ContentDocumentLink>>();
        List<ContentDocumentLink> relatedNotes = [
            SELECT ContentDocumentId, LinkedEntityId, ShareType, Visibility
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :eventIds
        ];

        for (ContentDocumentLink note : relatedNotes) {
            if (!relatedNotesMap.containsKey(note.LinkedEntityId)) {
                relatedNotesMap.put(note.LinkedEntityId, new List<ContentDocumentLink>());
            }
            relatedNotesMap.get(note.LinkedEntityId).add(note);
        }

        // Query all existing ContentDocumentLinks for the new owners
        List<ContentDocumentLink> existingCollaborators = [
            SELECT ContentDocumentId, LinkedEntityId
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :newOwnerIds
        ];

        // Create a map to track which ContentDocumentLinks already exist for each new owner
        Map<Id, Set<Id>> ownerCollaboratorsMap = new Map<Id, Set<Id>>();
        for (ContentDocumentLink collaborator : existingCollaborators) {
            if (!ownerCollaboratorsMap.containsKey(collaborator.LinkedEntityId)) {
                ownerCollaboratorsMap.put(collaborator.LinkedEntityId, new Set<Id>());
            }
            ownerCollaboratorsMap.get(collaborator.LinkedEntityId).add(collaborator.ContentDocumentId);
        }

        // Iterate through the requests and handle the collaborator addition
        for (OwnerChangeRequest request : requests) {
            List<ContentDocumentLink> notes = relatedNotesMap.get(request.eventId);
            if (notes != null) {
                Set<Id> existingCollaboratorIds = ownerCollaboratorsMap.get(request.newOwnerId) != null
                    ? ownerCollaboratorsMap.get(request.newOwnerId)
                    : new Set<Id>();

                for (ContentDocumentLink note : notes) {
                    // Only add the new owner as a collaborator if they are not already one
                    if (!existingCollaboratorIds.contains(note.ContentDocumentId)) {
                        ContentDocumentLink collaboratorLink = new ContentDocumentLink();
                        collaboratorLink.ContentDocumentId = note.ContentDocumentId;
                        collaboratorLink.LinkedEntityId = request.newOwnerId; // Add the new owner
                        collaboratorLink.ShareType = 'C'; // Collaborator access
                        collaboratorLink.Visibility = 'AllUsers'; // Visible to the new owner
                        contentDocLinks.add(collaboratorLink);
                    }
                }
            }
        }

        // Insert all new ContentDocumentLink records to assign collaborators
        if (!contentDocLinks.isEmpty()) {
            insert contentDocLinks;
        }
    }

    // Class to hold data passed in from Flow
    public class OwnerChangeRequest {
        @InvocableVariable(label='Event Record Id' description='Id of the Event (Activity) record' required=true)
        public Id eventId;

        @InvocableVariable(label='New Owner Id' description='Id of the new owner (User)' required=true)
        public Id newOwnerId;
    }
}