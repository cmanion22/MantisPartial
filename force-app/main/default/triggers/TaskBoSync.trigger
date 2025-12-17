trigger TaskBoSync on Task_BO_Sync__e (after insert) {
    for (Task_BO_Sync__e event : Trigger.New) {
        TaskCalloutClass.updateTask(event.Task_ID__c, event.Sync_User_ID__c);
    }
}