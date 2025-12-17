public class OpportunityContactRoleHelper {
    public static OpportunityContactRole upsertOpportunityContactRole(ID opportunityId, ID contactId) {   
        OpportunityContactRole thisOpportunityContactRole = new OpportunityContactRole();
        thisOpportunityContactRole.put('OpportunityId', opportunityId);
        thisOpportunityContactRole.put('ContactId', contactId);
        thisOpportunityContactRole.put('IsPrimary', true);
        
        System.debug('OpportunityContactRoleHelper-->upsertOpportunityContactRole-->thisOpportunityContactRole -->' + thisOpportunityContactRole);
        upsert thisOpportunityContactRole;
        
        System.debug('OpportunityContactRoleHelper-->upsertOpportunityContactRole-->thisOpportunityContactRole.Id -->' + thisOpportunityContactRole.Id);               
        return thisOpportunityContactRole;
    } 
}