@RestResource(urlMapping='/UploadOpportunityToSF/*')
global with sharing class OpportunityCallIn {
    
    global class CompositeOpportunity {
        public Account account;
        public Contact contact;
        public Opportunity opportunity;

        public CompositeOpportunity(Account account, Contact contact, Opportunity opportunity) {
            this.account = account;
            this.contact = contact;
            this.opportunity = opportunity;
        }
    }
    
    @HttpPost
    global static CompositeOpportunity createOpportunity() {
        RestRequest request = RestContext.request;                        
        Map<String, Object> compositeMapObjects = (Map<String, Object>) JSON.deserializeUntyped(request.requestbody.tostring());
        
        Account account = AccountHelper.upsertAccount(compositeMapObjects);        
        Contact contact = ContactHelper.upsertContact(compositeMapObjects, account.Id);                
        Opportunity opportunity = OpportunityHelper.upsertOpportunity(compositeMapObjects, account.Id, contact.Id);
        OpportunityContactRole opportunityContactRoleId = OpportunityContactRoleHelper.upsertOpportunityContactRole(opportunity.Id, contact.Id);

        CompositeOpportunity compositeOpportunity = new CompositeOpportunity(account, contact, opportunity);        
        return compositeOpportunity;
    }    
}