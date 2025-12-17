trigger OpportunityTrigger on Opportunity (before insert, before update, after insert, after update, before delete) {
    try {
        new OpportunityTriggerHandler().run();
    } catch (TriggerHandler.TriggerHandlerException e) {
        System.debug(e.getMessage());
    }
}