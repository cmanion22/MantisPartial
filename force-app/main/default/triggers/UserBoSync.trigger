trigger UserBoSync on User_BO_Sync__e (after insert) {
    for (User_BO_Sync__e event : Trigger.New) {
        UserCalloutClass.createUser(event.User_ID__c, event.Sync_User_ID__c);
    }
}