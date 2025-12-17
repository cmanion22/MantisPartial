public with sharing class OpportunityRegistrationResultController
{
    public ApexPages.StandardController controller {get; set;}
    public String pageMessage {get; set;}
    public boolean isSuccess {get; set;}
    public boolean isError{get; set;}
    
    public OpportunityRegistrationResultController(ApexPages.StandardController controller){
        this.controller = controller;  
        ID oppId = controller.getRecord().get('id').tostring();
        
        Opportunity opp = OpportunityHelper.getOpportunity(oppId);
        
        this.pageMessage = opp.Sync_Error__c;
        if(this.pageMessage.contains('html'))
        {
            System.debug('true');
            this.pageMessage = 'Error in registering Opportunity to Backoffice';
        }
        
        if(this.pageMessage.contains('success'))
        {
            isSuccess= true;
        }
        else
        {
            isError = true;
        }
    }
}