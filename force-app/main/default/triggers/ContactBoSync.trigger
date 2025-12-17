trigger ContactBoSync on Contact_BO_Sync__e (after insert) {
    for (Contact_BO_Sync__e event : Trigger.New) {
        ContactCalloutClass.updateContact(event.Contact_ID__c, event.Sync_User_ID__c);
    }
}