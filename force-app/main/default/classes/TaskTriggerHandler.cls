public class TaskTriggerHandler extends TriggerHandler {

    private List<Task> newList;
    private Map<Id, Task> newMap;
    private Map<Id, Task> oldMap;

    public TaskTriggerHandler() {
        this.newList = (List<Task>) Trigger.new;
        this.newMap = (Map<Id, Task>) Trigger.newMap;
        this.oldMap = (Map<Id, Task>) Trigger.oldMap;
    }

    public override void afterInsert() {
        if (userHasBypassPermission() || updateMadeViaCustomOrNativeEndpoint()) {
            return;
        }

        List<Task> tasksForBoSync = new List<Task>();
        for (Task task : newList) {
            // Condition migrated from legacy code: skip if Task is deleted or archived (not updatable)
            if (task.IsArchived || task.IsDeleted) {
                continue;
            }

            // Condition migrated from legacy code: skip if updating a Lead task or converting a Lead to Contact
            if (task.WhoId != null && task.WhoId.to15().startsWith('00Q')) {
                continue;
            }

             // Condition migrated from legacy code: fire BO callout only for Completed tasks
            if (task.Status != 'Completed') {
                continue;
            }

            tasksForBoSync.add(task);
        }

        generateBoSyncEvents(tasksForBoSync);
    }

    public override void afterUpdate() {
        if (userHasBypassPermission() || updateMadeViaCustomOrNativeEndpoint()) {
            return;
        }

        List<Task> tasksForBoSync = new List<Task>();
        for (Task task : newList) {
            // Condition migrated from legacy code: skip if Task is deleted or archived (not updatable)
            if (task.IsArchived || task.IsDeleted) {
                continue;
            }

            // Condition migrated from legacy code: skip if updating a Lead task or converting a Lead to Contact
            if (this.oldMap.get(task.Id).WhoId != null && this.oldMap.get(task.Id).WhoId.to15().startsWith('00Q')) {
                continue;
            }

             // Condition migrated from legacy code: fire BO callout only for Completed tasks
            if (task.Status != 'Completed') {
                continue;
            }

            tasksForBoSync.add(task);
        }

        generateBoSyncEvents(tasksForBoSync);
    }

    private void generateBoSyncEvents(List<Task> tasks) {
        List<Task_BO_Sync__e> taskBoSyncEvents = new List<Task_BO_Sync__e>();

        for(Task task : tasks) {
            // Generate platform event
            Task_BO_Sync__e newTaskBoSyncEvent = new Task_BO_Sync__e();
            newTaskBoSyncEvent.Task_ID__c = task.Id;
            newTaskBoSyncEvent.Sync_User_ID__c = UserInfo.getUserId();

            taskBoSyncEvents.add(newTaskBoSyncEvent);
        }

        publishTaskBoSyncEvents(taskBoSyncEvents);
    }

    private void publishTaskBoSyncEvents(List<Task_BO_Sync__e> taskBoSyncEvents) {
        // Call method to publish events
        List<Database.SaveResult> results = EventBus.publish(taskBoSyncEvents);

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
        return FeatureManagement.checkPermission('Bypass_Task_trigger');
    }

    private Boolean updateMadeViaCustomOrNativeEndpoint() {
        String callingURL = System.URL.getCurrentRequestUrl().getPath();
        return callingURL.contains('/services/apexrest/') || callingURL.contains('/services/data');
    }

}