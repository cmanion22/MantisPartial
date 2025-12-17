trigger FileDeletionBoSync on File_Deletion_BO_Sync__e (after insert) {
    for (File_Deletion_BO_Sync__e event : Trigger.New) {
        //OpportunityCalloutClass.updateOpportunity(event.Opportunity_ID__c);
    }
}