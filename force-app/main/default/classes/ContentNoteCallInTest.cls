@isTest
public class ContentNoteCallInTest {
    
     @isTest static void createContentNoteTest() {
          Test.startTest();

          Entity__c testEntity = new Entity__c();
          testEntity.Name = 'Test Entity';
          testEntity.Brand__c = 'Test Brand';
          testEntity.Source_ID__c = 'Test Source Id Entity';
          testEntity.Source_Database__c = 'Test Source DB Entity';      
          insert testEntity;

          Profile testProfile = [SELECT Id FROM Profile WHERE Name='Standard User']; 
          User testUser = new User(Alias = 'standt', Email='testuser@emex.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = testProfile.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='emextestuser@emex.com',
            Entity_ID__c=testEntity.Id, Entity_Name__c=testEntity.Name);
            
          insert testUser;

          RestRequest req = new RestRequest(); 
          RestResponse res = new RestResponse();

          req.addHeader('httpMethod', 'POST');
          req.requestUri = '/services/apexrest/UploadTaskNoteToSF/';       

          Task testTask = new Task();
          testTask.Subject = 'Test Task';  
          testTask.Priority = 'Normal';
          testTask.Status = 'Open';       
          insert testTask;

          Savepoint sp = Database.setSavepoint();       

          req.requestBody = Blob.valueof('{ "Title":"Note Title1", "TextPreview":"This is note1", "ParentTaskId" : "' + testTask.Id  + '", "Content": "Sample", "OwnerId": "' + testUser.Id + '"}');
                    
          RestContext.request = req; 
          RestContext.response = res;
                    
          ContentNote cn = ContentNoteCallIn.createContentNote();
          List<ContentNote> lst = [SELECT Id, Title, TextPreview FROM ContentNote WHERE Id =: cn.Id];
          Database.rollback(sp);
          Test.stopTest();
          
          System.assertEquals(1, lst.size());     
     } 
}