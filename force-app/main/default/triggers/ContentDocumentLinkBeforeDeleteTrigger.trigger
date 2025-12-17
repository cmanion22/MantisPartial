trigger ContentDocumentLinkBeforeDeleteTrigger on ContentDocumentLink (before delete) {
    ContentDocumentLinkClass.beforeDeleteCDL(Trigger.old);

}