trigger TaskCommentBoSync on Task_Comment_BO_Sync__e (after insert) {
    for (Task_Comment_BO_Sync__e event : Trigger.New) {
        //OpportunityCalloutClass.updateOpportunity(event.Opportunity_ID__c);
    }
}