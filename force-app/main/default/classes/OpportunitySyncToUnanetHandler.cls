public with sharing class OpportunitySyncToUnanetHandler {

    @InvocableMethod(label='Sync Opportunity to Unanet' description='Enqueues Unanet Account Sync for the given Opportunity ID')
    public static void handleServiceOpportunity(List<Id> opportunityIds) {
        if (opportunityIds == null || opportunityIds.isEmpty()) {
            return;
        }

        // Expecting only one record, but handle gracefully in case of more
        Opportunity opp = [
            SELECT Id, AccountId
            FROM Opportunity
            WHERE Id = :opportunityIds[0]
            LIMIT 1
        ];

        if (opp.AccountId != null) {
            System.debug('Enqueuing job for UnanetAccountSyncQueueable (' + opp.Id + ')');
            System.enqueueJob(new UnanetAccountSyncQueueable(opp.Id));
        }
    }
}