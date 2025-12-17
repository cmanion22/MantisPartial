@isTest 
public class CustomNotesControllerTest
{
     static testMethod void GetNotesTest() 
     {        
        Task testTask = new Task();
        testTask.Subject = 'TestTask';  
        testTask.Priority = 'Normal';
        testTask.Status = 'Open';       
        insert testTask;

        List<ContentNote> NotesList = new List<ContentNote>();
        Integer notesCount;
        
        ContentNote testContentNote = new ContentNote(Title = 'Test Note', Content = Blob.valueOf('Test Content')); 
        insert testContentNote;  
                          
        ContentDocumentLink testContentDocumentLink = new ContentDocumentLink();
        testContentDocumentLink.LinkedEntityId = testTask.Id;
        testContentDocumentLink.ContentDocumentId = testContentNote.Id;        
        testContentDocumentLink.ShareType = 'V';
        insert testContentDocumentLink;
        
        NotesList.add(testContentNote);
        notesCount = NotesList.size();
              
        Test.StartTest(); 
            PageReference pageRef = Page.Notes;             
            pageRef.getParameters().put('id', String.valueOf(testTask.Id));
            Test.setCurrentPage(pageRef);
            
            ApexPages.StandardController thisStandardController = new ApexPages.StandardController(testTask);
            CustomNotesController controller = new CustomNotesController(thisStandardController);
            controller.GetNotes();    
        Test.StopTest();
     }
     
     static testMethod void GetNotesWithoutIdTest() 
     {        
        Task testTask = new Task();
        testTask.Subject = 'TestTask';  
        testTask.Priority = 'Normal';
        testTask.Status = 'Open';       
        insert testTask;

        List<ContentNote> NotesList = new List<ContentNote>();
        Integer notesCount;
        
        ContentNote testContentNote = new ContentNote(Title = 'Test Note', Content = Blob.valueOf('Test Content')); 
        insert testContentNote;  
                          
        ContentDocumentLink testContentDocumentLink = new ContentDocumentLink();
        testContentDocumentLink.LinkedEntityId = testTask.Id;
        testContentDocumentLink.ContentDocumentId = testContentNote.Id;        
        testContentDocumentLink.ShareType = 'V';
        insert testContentDocumentLink;
        
        NotesList.add(testContentNote);
        notesCount = NotesList.size();
        
        Test.StartTest(); 
            PageReference pageRef = Page.Notes; 
            
            Test.setCurrentPage(pageRef);
            
            ApexPages.StandardController thisStandardController = new ApexPages.StandardController(testTask);
            CustomNotesController controller = new CustomNotesController(thisStandardController);
            controller.GetNotes();    
        Test.StopTest();
     }
}