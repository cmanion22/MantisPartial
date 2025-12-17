trigger AccountBoSync on Account_BO_Sync__e (after insert) {
    for (Account_BO_Sync__e event : Trigger.New) {
        AccountCalloutClass.updateAccount(event.Account_ID__c, event.Sync_User_ID__c);
    }
}