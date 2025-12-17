trigger FileUploadBoSync on File_Upload_BO_Sync__e (after insert) {
    for (File_Upload_BO_Sync__e event : Trigger.New) {
        //OpportunityCalloutClass.updateOpportunity(event.Opportunity_ID__c);
    }
}