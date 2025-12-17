trigger OpportunityBoSync on Opportunity_BO_Sync__e (after insert) {
    
    List<Automation_Kill_Switch__mdt> settings = [SELECT DeveloperName, Deactivate_Automation__c 
    											  FROM Automation_Kill_Switch__mdt
                                                  WHERE DeveloperName = 'Trigger_Deactivation'
                                                  LIMIT 1];

    If(settings[0].Deactivate_Automation__c  == false){
        
    for (Opportunity_BO_Sync__e event : Trigger.New) {
        OpportunityCalloutClass.updateOpportunity(event.Opportunity_ID__c, event.Sync_User_ID__c);
        
    	}
    }
}