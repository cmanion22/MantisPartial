trigger UserTrigger on User (after insert) {
    try {
        new UserTriggerHandler().run();
    } catch (TriggerHandler.TriggerHandlerException e) {
        System.debug(e.getMessage());
    }
}