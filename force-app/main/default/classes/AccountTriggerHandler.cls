public class AccountTriggerHandler extends TriggerHandler {

    private List<Account> newList;
    private Map<Id, Account> newMap;

    public AccountTriggerHandler() {
        this.newList = (List<Account>) Trigger.new;
        this.newMap = (Map<Id, Account>) Trigger.newMap;
    }

    /*public override void beforeUpdate() {
        cleanAccountSourceDetailValues();
    }

    public override void beforeInsert() {
        cleanAccountSourceDetailValues();
    }*/

    public override void afterUpdate() {
        if (!updateMadeViaTest() || !updateMadeViaTestUser()) {
        		if (userHasBypassPermission() || updateMadeViaCustomOrNativeEndpoint()) {
            	return;
        	}
        }    

        List<Account_BO_Sync__e> accBoSyncEvents = new List<Account_BO_Sync__e>();

        for(Account acc : this.newList) {
            // Generate platform event
            Account_BO_Sync__e newAccBoSyncEvent = new Account_BO_Sync__e();
            newAccBoSyncEvent.Account_ID__c = acc.Id;
            newAccBoSyncEvent.Sync_User_ID__c = UserInfo.getUserId();

            accBoSyncEvents.add(newAccBoSyncEvent);
        }

        publishAccBoSyncEvents(accBoSyncEvents);
    }

    private void publishAccBoSyncEvents(List<Account_BO_Sync__e> accBoSyncEvents) {
        // Call method to publish events
        List<Database.SaveResult> results = EventBus.publish(accBoSyncEvents);

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
        return FeatureManagement.checkPermission('Bypass_Account_trigger');
    }

    private Boolean updateMadeViaCustomOrNativeEndpoint() {
        String callingURL = System.URL.getCurrentRequestUrl().getPath();
        return callingURL.contains('/services/apexrest/') || callingURL.contains('/services/data');
    }
    
    private Boolean updateMadeViaTest(){
        Boolean isTest = Test.isRunningTest();
        return isTest;
    }
    
    private Boolean updateMadeViaTestUser() {
    Boolean isTestUser = false; // Initialize to false by default
    Id userId = UserInfo.getUserId();
    User currentUser = [SELECT Id, Name FROM User WHERE Id = :userId LIMIT 1];
    
    if (currentUser != null && currentUser.Name != null) {
        if (currentUser.Name == 'Testing User') {
            isTestUser = true;
        }
    }
    
    return isTestUser;
}

    /*private void cleanAccountSourceDetailValues() {
        for (Account account : newList) {
            if (DependentPicklistValueInvocable.checkDependentPicklistValue(
                    'Account',
                    'AccountSource',
                    'Account_Source_Detail__c',
                    account.AccountSource,
                    account.Account_Source_Detail__c
                )) 
            {
                // Account_Source_Detail__c value is compatible with AccountSource value
                continue;
            }

            System.debug('Setting Account_Source_Detail__c to null since the previous value \'' + account.Account_Source_Detail__c + '\' was not compatible with the AccountSource value \'' + account.AccountSource + '\'');
            account.Account_Source_Detail__c = null;
        }
    }*/

}