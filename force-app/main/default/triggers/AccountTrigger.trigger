trigger AccountTrigger on Account (before insert, before update, after insert, after update, before delete) {
    try {
        new AccountTriggerHandler().run();
    } catch (TriggerHandler.TriggerHandlerException e) {
        System.debug(e.getMessage());
    }
}