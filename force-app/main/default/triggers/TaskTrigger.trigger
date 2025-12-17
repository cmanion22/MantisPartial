trigger TaskTrigger on Task (after insert, after update) {
    try {
        new TaskTriggerHandler().run();
    } catch (TriggerHandler.TriggerHandlerException e) {
        System.debug(e.getMessage());
    }
}