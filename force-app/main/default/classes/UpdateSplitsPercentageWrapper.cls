public class UpdateSplitsPercentageWrapper {
    @invocableVariable(label='Opportunity Ids')
    public List <Id> opportunityIds;

    @invocableVariable(label='Sales Referrer Id')
    public Id salesReferrerId;

    @invocableVariable(label='Split Type Id')
    public Id splitTypeId;
    
    @invocableVariable(label='Record Type Name')
    public String recTypeName;

    @invocableVariable(label='Upon Opportunity Creation')
    public Boolean uponOpportunityCreation;

    @invocableVariable(label='Account Id')
    public Id accountId;
}