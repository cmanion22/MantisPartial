public class EventMeetingNotesWrapper {
    @InvocableVariable(label='Event Ids')
    public List<Id> eventIds;

    @InvocableVariable(label='Pre-Meeting Note Title')
    public String preTitle;

    @InvocableVariable(label='Post-Meeting Note Title')
    public String postTitle;
}