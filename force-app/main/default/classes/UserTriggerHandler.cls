public class UserTriggerHandler extends TriggerHandler {

    private List<User> newList;
    private Map<Id, User> newMap;

    public UserTriggerHandler() {
        this.newList = (List<User>) Trigger.new;
        this.newMap = (Map<Id, User>) Trigger.newMap;
    }

    public override void afterInsert() {
        if (updateMadeViaCustomOrNativeEndpoint()) {
            return;
        }

        List<User_BO_Sync__e> userBoSyncEvents = new List<User_BO_Sync__e>();

        for(User user : this.newList) {
            // Generate platform event
            User_BO_Sync__e newUserBoSyncEvent = new User_BO_Sync__e();
            newUserBoSyncEvent.User_ID__c = user.Id;
            newUserBoSyncEvent.Sync_User_ID__c = UserInfo.getUserId();

            userBoSyncEvents.add(newUserBoSyncEvent);
        }

        publishUserBoSyncEvents(userBoSyncEvents);
    }

    private void publishUserBoSyncEvents(List<User_BO_Sync__e> userBoSyncEvents) {
        // Call method to publish events
        List<Database.SaveResult> results = EventBus.publish(userBoSyncEvents);

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

    private Boolean updateMadeViaCustomOrNativeEndpoint() {
        String callingURL = System.URL.getCurrentRequestUrl().getPath();
        return callingURL.contains('/services/apexrest/') || callingURL.contains('/services/data');
    }

}