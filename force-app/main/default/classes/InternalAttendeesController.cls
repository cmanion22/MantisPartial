public with sharing class InternalAttendeesController {
    @AuraEnabled(cacheable=true)
    public static List<Internal_Attendees__c> getInternalAttendees(Id eventId) {
        return [SELECT Id, Name, Event_Id__c, Event_Name__c, Attendee__c, Attendee__r.Name, Attendee_Role__c, Sales_Role__c 
                FROM Internal_Attendees__c 
                WHERE Event_Id__c = :eventId];
    }

    @AuraEnabled
    public static Internal_Attendees__c createInternalAttendee(Id eventId, String eventName, Id attendeeId) {

        List<RecordType> recordTypeList = [SELECT Id, RecordType.Name 
                                        FROM RecordType 
                                        WHERE SObjectType = 'Internal_Attendees__c' 
                                        AND Name = 'Meeting Attendee'
                                        LIMIT 1];

        Id recordTypeId = recordTypeList[0].Id;
        String recordTypeName = recordTypeList[0].Name;

        Internal_Attendees__c newAttendee = new Internal_Attendees__c(
            Event_Id__c = eventId,
            //Event_Name__c = eventName,
            Attendee__c = attendeeId,
            RecordTypeId = recordTypeId
        );
        //System.debug('RecordTypeId for Meeting Attendee: ' + recordTypeId);
        //System.debug('RecordTypeName for Meeting Attendee: ' + recordTypeName);

        insert newAttendee;
        return newAttendee;
    }

    // New method to delete an attendee
    @AuraEnabled
    public static void deleteInternalAttendee(Id attendeeId) {
        try {
            Internal_Attendees__c attendeeToDelete = [SELECT Id FROM Internal_Attendees__c WHERE Id = :attendeeId LIMIT 1];
            delete attendeeToDelete;
            System.debug('Attendee deleted successfully: ' + attendeeId);
        } catch (Exception e) {
            System.debug('Error deleting attendee: ' + e.getMessage());
            throw new AuraHandledException('Unable to delete attendee: ' + e.getMessage());
        }
    }
}