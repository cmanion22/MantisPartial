public class ContactTriggerHandler extends TriggerHandler {

    private List<Contact> oldList;
    private List<Contact> newList;
    private Map<Id, Contact> newMap;

    public ContactTriggerHandler() {
        this.oldList = (List<Contact>) Trigger.old;
        this.newList = (List<Contact>) Trigger.new;
        this.newMap = (Map<Id, Contact>) Trigger.newMap;
    }

    /*public override void beforeUpdate() {
        cleanLeadSourceDetailValues();
    }

    public override void beforeInsert() {
        cleanLeadSourceDetailValues();
    }*/

    public override void afterUpdate() {
        if(!updateMadeViaTest() || !updateMadeViaTestUser()) {
            if (userHasBypassPermission() ||
            updateMadeViaCustomOrNativeEndpoint() ||
            UserInfo.getUsername().contains('b2bma')) // Do not fire trigger if user is Pardot Integration
        		{ 
            		return;
        	}
        }
        

        List<Contact_BO_Sync__e> contactBoSyncEvents = new List<Contact_BO_Sync__e>();

        for(Contact contact : this.newList) {
            // Generate platform event
            Contact_BO_Sync__e newContactBoSyncEvent = new Contact_BO_Sync__e();
            newContactBoSyncEvent.Contact_ID__c = contact.Id;
            newContactBoSyncEvent.Sync_User_ID__c = UserInfo.getUserId();

            contactBoSyncEvents.add(newContactBoSyncEvent);
        }

        publishContactBoSyncEvents(contactBoSyncEvents);
    }

    /**
     * TODO: Review legacy code
     */
    public override void beforeDelete() {
        Set<Id> accountIds = new Set<Id>();
        for(Contact cObj : this.oldList) {
            accountIds.add(cObj.AccountId);
        }
        Map<Id, Boolean> partnerAccountsIndexedById = AccountHelper.isPartnerAccount(accountIds);

        for(Contact cObj : this.oldList)
        { 
            System.debug('ContactTrigger->calling before delete');
            if (cObj.Primary_Contact__c && partnerAccountsIndexedById.get(cObj.AccountId)) {
                if (cObj.Account_Primary_Contact__c) {
                    cObj.addError('Cannot delete Partner Account Primary Contact.');   
                    continue;
                }
                cObj.addError('This Contact has been selected as the Primary Contact on at least one Opportunity. It cannot be deleted.'); 
                System.debug('ContactTrigger------>calling before delete');  
                continue;
            }

            //Cannot deactivate or delete any Account Primary Contact
            if (cObj.Account_Primary_Contact__c) {
                //Cannot deactivate or delete Partner Account Primary Contact
                if (partnerAccountsIndexedById.get(cObj.AccountId)) {
                    cObj.addError('Cannot delete Partner Account Primary Contact.');
                    continue;
                }

                cObj.addError('This Contact has been selected as Account Point of Contact. It cannot be deleted.');
                continue;
            }

            //Cannot delete Partner Account Contacts where Partner Agent is true and BackOfficeID field is populated
            if (partnerAccountsIndexedById.get(cObj.AccountId) && cobj.Partner_Agent__c && String.isNotEmpty(cobj.BackOfficeID__c)) {
                cobj.addError('Cannot delete Partner Account Contact is its a Partner Agent and has Back Office ID present');
                continue;
            }
        }
    }

    private void publishContactBoSyncEvents(List<Contact_BO_Sync__e> contactBoSyncEvents) {
        // Call method to publish events
        List<Database.SaveResult> results = EventBus.publish(contactBoSyncEvents);

        // Inspect publishing result for each event
        for (Database.SaveResult sr : results) {
            if (sr.isSuccess()) {
                System.debug('Successfully published event.');
            } else {
                for (Database.Error err : sr.getErrors()) {
                    System.debug('Error returned: ' + err.getStatusCode() + ' - ' + err.getMessage());
                }
            }
        }
    }

    private Boolean userHasBypassPermission() {
        return FeatureManagement.checkPermission('Bypass_Contact_trigger');
    }

    private Boolean updateMadeViaCustomOrNativeEndpoint() {
        String callingURL = System.URL.getCurrentRequestUrl().getPath();
        return callingURL.contains('/services/apexrest/') || callingURL.contains('/services/data');
    }
    
    private Boolean updateMadeViaTest() {
        Boolean isTest = Test.isRunningTest();
        return isTest;
    }
    
    private Boolean updateMadeViaTestUser() {
    Boolean isTestUser = false; // Initialize to false by default
    Id userId = UserInfo.getUserId();
    User currentUser = [SELECT Id, Name FROM User WHERE Id = :userId LIMIT 1];
    
    if (currentUser != null && currentUser.Name != null) {
        if (currentUser.Name.Contains('Testing User')) {
            isTestUser = true;
        }
    }
    system.debug('Current User: ' + currentUser.Name);
    return isTestUser;
}

    /*private void cleanLeadSourceDetailValues() {
        for (Contact contact : newList) {
            if (DependentPicklistValueInvocable.checkDependentPicklistValue(
                    'Contact',
                    'LeadSource',
                    'Lead_Source_Detail__c',
                    contact.LeadSource,
                    contact.Lead_Source_Detail__c
                )) 
            {
                // Lead_Source_Detail__c value is compatible with LeadSource value
                continue;
            }

            System.debug('Setting Lead_Source_Detail__c to null since the previous value \'' + contact.Lead_Source_Detail__c + '\' was not compatible with the LeadSource value \'' + contact.LeadSource + '\'');
            contact.Lead_Source_Detail__c = null;
        }
    }*/

}