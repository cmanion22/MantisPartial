trigger ContentVersionTrigger on ContentVersion (after insert) {
	System.debug('Entering ContentVersionTrigger');
    ContentVersionHandler.createCollaboratorAccess(Trigger.new);
}