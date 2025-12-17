public class OpportunitySearchController {
    public String opportunityUrl {get; set;}
    public Boolean displayNoRecordSection {get; set;}

    public OpportunitySearchController(ApexPages.StandardController controller) {
        Id currentOpportunityId = controller.getRecord().get('id').toString();
        this.opportunityUrl = ESBController.getOpportunityESBUrl(currentOpportunityId);
        this.displayNoRecordSection = false;

        Opportunity currentRecord = [SELECT Id, Registered_in_Back_Office__c FROM Opportunity WHERE Id = :ApexPages.currentPage().getParameters().get('id')];

        if(currentRecord.Registered_in_Back_Office__c == false) {
            this.displayNoRecordSection = true;
        }
    }
}