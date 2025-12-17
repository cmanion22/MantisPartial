/**
 * @author Gustavo Pupo
 */
public virtual class OpportunityContactRoleRepository {

    virtual
    public List<OpportunityContactRole> findPrimaryContactForOpportunityIds(Set<Id> opportunityIds) {
        return [SELECT Id, IsPrimary, ContactId, OpportunityId FROM OpportunityContactRole WHERE IsPrimary = true AND OpportunityId IN :opportunityIds];
    }

}