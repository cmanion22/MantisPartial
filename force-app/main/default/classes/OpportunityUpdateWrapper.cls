public with sharing class OpportunityUpdateWrapper 
{
    @InvocableMethod(label='update_opportunity_wrapper')
    public static void updateOpportunityWrapper(List<ID> opportunityIdList)
    {    
        ID opportunityId = opportunityIdList[0];
        Turn_off_Processes__c processSettings = Turn_off_Processes__c.getValues('migration in progress');
    
        if(processSettings != null) 
        {
            System.debug('OpportunityUpdateWrapper for trigger-->updateOpportunityWrapper-->processSettings.Is_Active__c-->' + processSettings.Is_Active__c);
            if(!processSettings.Is_Active__c) 
            {    
                //new trigger code
                Opportunity opp= (Opportunity)Helper.getSObject(opportunityId);
                Trigger_Disabled__c disabled = Trigger_Disabled__c.getValues(opp.ID);
                if (disabled != null) 
                { 
                  System.debug('OpportunityTrigger-->Trigger_Disabled__c-->' + disabled );
                  return; 
                }
                
                 disabled = new Trigger_Disabled__c();
                 disabled.Name = opp.id;
                 upsert disabled Name;
                                
                System.debug('OpportunityTrigger --> opp.ID -->' + opp.ID);
                System.debug('OpportunityTrigger --> opp -->' + opp);                
              
                System.debug('OpportunityTrigger->Update trigger running');
                
                if(Test.isRunningTest()) 
                {
                    System.debug('OpportunityTrigger-->Test.RunningTest()');                        
                    Test.setMock(HttpCalloutMock.class, new HttpEmexCalloutMock(200, 'OK', '{success:true}'));
                } 
                else 
                {                   
                    System.debug('OpportunityTrigger->calling OpportunityCalloutClass.updateOpportunity');
                    OpportunityCalloutClass.updateOpportunity(opp.ID, UserInfo.getUserId());                   
                }                                     
            }
        }        
    }
}