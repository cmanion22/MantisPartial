public class BillingManagerAssignmentHelper {
    public static void updateBillingManager(List<Opportunity> opps) {
        System.debug('Entering BillingManagerAssignmentHelper.updateBillingManager');
        if (opps == null || opps.isEmpty()) {
            System.debug('BillingManagerAssignmentHelper.updateBillingManager(): No Opportunities passed.');
            return;
        }
    
        // Get current user's full name
        String currentUserFullName = (UserInfo.getFirstName() + ' ' + UserInfo.getLastName()).trim().toLowerCase();
    
        // Get all Billing Managers
        List<Unanet_User__c> billingManagers = [
            SELECT Id, First_Name__c, Last_Name__c, Unanet_Role__c
            FROM Unanet_User__c
            WHERE Unanet_Role__c INCLUDES ('Billing Manager')
        ];
    
        Map<String, Id> fullNameToBillingManagerId = new Map<String, Id>();
        for (Unanet_User__c bm : billingManagers) {
            String fullName = (bm.First_Name__c + ' ' + bm.Last_Name__c).trim().toLowerCase();
            fullNameToBillingManagerId.put(fullName, bm.Id);
        }
    
        Id matchedBillingManagerId = fullNameToBillingManagerId.get(currentUserFullName);
    
        if (matchedBillingManagerId == null) {
            System.debug('BillingManagerAssignmentHelper: No Billing Manager found for current user: ' + currentUserFullName);
            return;
        }
    
        for (Opportunity opp : opps) {
            if (opp.Billing_Manager__c == null) {
                opp.Billing_Manager__c = matchedBillingManagerId;
                System.debug('BillingManagerAssignmentHelper: Assigned Billing Manager for Opp ' + opp.Id);
            }
        }
    }

}