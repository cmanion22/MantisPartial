trigger ContactTrigger on Contact (before insert, before update, after insert, after update, before delete) {
    try {
        new ContactTriggerHandler().run();
    } catch (TriggerHandler.TriggerHandlerException e) {
        System.debug(e.getMessage());
    }
}