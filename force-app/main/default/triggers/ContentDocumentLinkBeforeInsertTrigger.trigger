trigger ContentDocumentLinkBeforeInsertTrigger on ContentDocumentLink (before insert) {
    ContentDocumentLinkClass.updateContentVersionAttachmentType(Trigger.new);

}