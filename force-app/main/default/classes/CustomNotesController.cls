public class CustomNotesController {
    public ContentNote[] NotesList { get; set; }
    public Integer notesCount { get; set; }
    public Map<ID, string> notesDescription {get; set;}
    
    public CustomNotesController(ApexPages.StandardController controller) {
        NotesList = new ContentNote[]{};
        GetNotes();
    }
    
    public void GetNotes(){
        System.debug('CustomNotesController-->GetNotes()');
        
        string taskID = ApexPages.currentPage().getParameters().get('id');
        System.debug('CustomNotesController-->GetNotes()-->taskID -->' + taskID);
        if(taskID==NULL){
            System.debug('No Id available');
        }
        else{
            List<ContentDocumentLink> lstContentDocumentLink = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId =: taskID ORDER BY Id DESC];
            String contentDocumentIDs = '';
            for (ContentDocumentLink cdl : lstContentDocumentLink) {
                String id_in_quotes = '\'' + cdl.ContentDocumentId + '\'';
                if (contentDocumentIDs != '') { contentDocumentIDs += ',' ; }  //  add a comma if this isn't the first one
                contentDocumentIDs += id_in_quotes;
            }
            
            System.debug('CustomNotesController-->GetNotes()-->lstContentDocumentLink-->' + lstContentDocumentLink);
            
            List<ContentNote> lstNote = new List<ContentNote>();
            if(!String.isEmpty(contentDocumentIDs)) {
                String soqlGetContentNotes = '  SELECT Id, TextPreview, Title, CreatedBy.Name, CreatedDate, Content FROM ContentNote WHERE Id IN (' + contentDocumentIDs + ') ORDER BY Id DESC';
                lstNote = database.query(soqlGetContentNotes);  
            }
            
            System.debug('CustomNotesController-->GetNotes()-->lstNote-->' + lstNote);
            
            this.notesDescription = new Map<ID, string>();

            for(ContentNote note : lstNote) {                
                System.debug('CustomNotesController-->GetNotes()-->note-->' + note);
                this.notesDescription.put(note.Id, note.Content.toString().replace('<p>', '').replace('</p>', ''));
                NotesList.add(note);
            }
        }
        this.notesCount = NotesList.size();
        System.debug('CustomNotesController-->GetNotes()-->noteValue-->' + this.notesDescription);
    }
}