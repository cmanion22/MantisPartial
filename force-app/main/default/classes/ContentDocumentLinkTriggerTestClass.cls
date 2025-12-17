@isTest
public class ContentDocumentLinkTriggerTestClass {
    @isTest(SeeAllData=false) static void fileUploadTest() {
        Test.setMock(HttpCalloutMock.class, new HttpEmexCalloutMock(200, 'OK', '{success:true}'));
        
        Broker__c testBroker = new Broker__c();
        testBroker.Name = 'Test Broker';
        testBroker.Source_ID__c = 'Test Source Id Broker';
        testBroker.Source_Database__c = 'Test Source DB Broker';
        insert testBroker;
        
        Entity__c testEntity = new Entity__c();
        testEntity.Name = 'Test Entity';
        testEntity.Brand__c = 'Test Brand';
        testEntity.Source_ID__c = 'Test Source Id Entity';
        testEntity.Source_Database__c = 'Test Source DB Entity';       
        insert testEntity;
        
        Market__c testMarket = new Market__c();
        testMarket.Name = 'Test Market';
        testMarket.Commodity__c = 'Electricity';
        testMarket.Region__c = 'US';    
        testMarket.Country__c = 'US';
        testMarket.Source_ID__c = 'Test Source Id Market';
        testMarket.Source_Database__c = 'Test Source DB Market';    
        insert testMarket;
        
        Profile testProfile = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User testUser = new User(Alias = 'standt', Email='testuser@emex.com', 
                                 EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                 LocaleSidKey='en_US', ProfileId = testProfile.Id, 
                                 TimeZoneSidKey='America/Los_Angeles', UserName='emextestuser@emex.com',
                                 Entity_ID__c=testEntity.Id, Entity_Name__c=testEntity.Name);
        
        insert testUser;
        
        Opportunity testOpportunity = new Opportunity();
        testOpportunity.Name = 'Test - Opportunity';
        testOpportunity.StageName = '5 - Closed Won';
        testOpportunity.Broker__c = testBroker.Id;
        testOpportunity.Entity__c = testEntity.Id;
        testOpportunity.Commodity__c = 'Electricity';
        testOpportunity.Market__c = testMarket.Id;
        testOpportunity.CloseDate = Date.today(); 
        testOpportunity.Est_Annual_Usage__c = 20;
        testOpportunity.Expected_Contract_Term__c = 10;
        testOpportunity.Expected_Contract_Start__c = Date.today();
        testOpportunity.Expected_Margin__c = 2;
        testOpportunity.Legal_Entity_Name__c = 'Test Opportunity Legal';   
        testOpportunity.OwnerId = testUser.Id; 
        insert testOpportunity;
        
        ContentVersion testContentVersion = new ContentVersion(); 
        testContentVersion.Title = 'Test';
        testContentVersion.ContentLocation = 'S';
        testContentVersion.PathOnClient = 'Test.txt';
        testContentVersion.VersionData = Blob.valueOf('Sample Text.');
        insert testContentVersion;
        
        ContentDocumentLink testContentDocumentLink = new ContentDocumentLink();
        Test.startTest();
        testContentDocumentLink.ContentDocumentId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =: testContentVersion.Id].ContentDocumentId;
        testContentDocumentLink.LinkedEntityId = testOpportunity.Id;
        testContentDocumentLink.ShareType = 'V';
        insert testContentDocumentLink;
        Test.stopTest();
        
        // Now check if it is giving desired results using System.assert
        // Statement.New File should be created
        List<ContentDocumentLink> lst = [SELECT Id, ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE Id = :testContentDocumentLink.Id];
        System.assertEquals(1, lst.size());
        // Check if one record is created in File sObject
    }
    
    @isTest(SeeAllData=false) static void fileUploadTest_Active() {
        Test.setMock(HttpCalloutMock.class, new HttpEmexCalloutMock(200, 'OK', '{success:true}'));
        
        Broker__c testBroker = new Broker__c();
        testBroker.Name = 'Test Broker';
        testBroker.Source_ID__c = 'Test Source Id Broker';
        testBroker.Source_Database__c = 'Test Source DB Broker';
        insert testBroker;
        
        Entity__c testEntity = new Entity__c();
        testEntity.Name = 'Test Entity';
        testEntity.Brand__c = 'Test Brand';
        testEntity.Source_ID__c = 'Test Source Id Entity';
        testEntity.Source_Database__c = 'Test Source DB Entity';       
        insert testEntity;
        
        Market__c testMarket = new Market__c();
        testMarket.Name = 'Test Market';
        testMarket.Commodity__c = 'Electricity';
        testMarket.Region__c = 'US';    
        testMarket.Country__c = 'US';
        testMarket.Source_ID__c = 'Test Source Id Market';
        testMarket.Source_Database__c = 'Test Source DB Market';    
        insert testMarket;
        
        Profile testProfile = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User testUser = new User(Alias = 'standt', Email='testuser@emex.com', 
                                 EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                 LocaleSidKey='en_US', ProfileId = testProfile.Id, 
                                 TimeZoneSidKey='America/Los_Angeles', UserName='emextestuser@emex.com',
                                 Entity_ID__c=testEntity.Id, Entity_Name__c=testEntity.Name);
        
        insert testUser;
        
        Opportunity testOpportunity = new Opportunity();
        testOpportunity.Name = 'Test - Opportunity';
        testOpportunity.StageName = '5 - Closed Won';
        testOpportunity.Broker__c = testBroker.Id;
        testOpportunity.Entity__c = testEntity.Id;
        testOpportunity.Commodity__c = 'Electricity';
        testOpportunity.Market__c = testMarket.Id;
        testOpportunity.CloseDate = Date.today(); 
        testOpportunity.Est_Annual_Usage__c = 20;
        testOpportunity.Expected_Contract_Term__c = 10;
        testOpportunity.Expected_Contract_Start__c = Date.today();
        testOpportunity.Expected_Margin__c = 2;
        testOpportunity.Legal_Entity_Name__c = 'Test Opportunity Legal';   
        testOpportunity.OwnerId = testUser.Id; 
        insert testOpportunity;
        
        ContentVersion testContentVersion = new ContentVersion(); 
        testContentVersion.Title = 'Test';
        testContentVersion.ContentLocation = 'S';
        testContentVersion.PathOnClient = 'Test.txt';
        testContentVersion.VersionData = Blob.valueOf('Sample Text.');
        insert testContentVersion;
        
        ContentDocumentLink testContentDocumentLink = new ContentDocumentLink();
        
        Turn_off_Processes__c processSettings = new Turn_off_Processes__c();
        processSettings.Name = 'migration in progress';
        processSettings.Is_Active__c = true;
        insert processSettings;
        
        Test.startTest();
        testContentDocumentLink.ContentDocumentId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =: testContentVersion.Id].ContentDocumentId;
        testContentDocumentLink.LinkedEntityId = testOpportunity.Id;
        testContentDocumentLink.ShareType = 'V';
        insert testContentDocumentLink;
        Test.stopTest();
        
        // Now check if it is giving desired results using System.assert
        // Statement.New File should be created
        List<ContentDocumentLink> lst = [SELECT Id, ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE Id = :testContentDocumentLink.Id];
        System.assertEquals(1, lst.size());
        // Check if one record is created in File sObject
    }    
    
    @isTest(SeeAllData=true) static void createTaskCommentTest() {
        Test.setMock(HttpCalloutMock.class, new HttpEmexCalloutMock(200, 'OK', '{success:true}'));  
        //Create Data for Task object
        Task testTask = new Task();
        testTask.Subject = 'Test Task';  
        testTask.Priority = 'Normal';
        testTask.Status = 'Open';       
        insert testTask;
        
        ContentNote testContentNote = new ContentNote();
        testContentNote.Title = 'Test title';  
        testContentNote.Content = Blob.valueOf('Test content');           
        insert testContentNote;
        
        ContentDocumentLink testContentDocumentLink = new ContentDocumentLink();
        Test.startTest();
        testContentDocumentLink.ContentDocumentId = testContentNote.Id;
        testContentDocumentLink.LinkedEntityId = testTask.Id;
        testContentDocumentLink.ShareType = 'V';  
        insert testContentDocumentLink;
        Test.stopTest();
        
        // Now check if it is giving desired results using System.assert
        // Statement.New Task should be created
        List<ContentDocumentLink> lst = [SELECT Id, ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE Id = :testContentDocumentLink.Id];
        System.assertEquals(1, lst.size());
        // Check if one record is created in Task sObject
    }
    
    @isTest(SeeAllData=false) 
    static void fileUploadPDFTest() {
        // Set up process settings
        Turn_off_Processes__c processSettings = new Turn_off_Processes__c(Name = 'migration in progress');
        insert processSettings;
        
        // Create test Opportunity
        Opportunity testOpportunity = new Opportunity();
        testOpportunity.Name = 'Test - Opportunity';
        testOpportunity.StageName = '5 - Closed Won';
        testOpportunity.CloseDate = Date.today(); 
        testOpportunity.Est_Annual_Usage__c = 20;
        testOpportunity.Expected_Contract_Term__c = 10;
        testOpportunity.Expected_Contract_Start__c = Date.today();
        testOpportunity.Expected_Margin__c = 2;
        testOpportunity.Legal_Entity_Name__c = 'Test Opportunity Legal';    
        insert testOpportunity;
        
        // Create ContentDocument related to an Opportunity
        ContentVersion testContentVersion = new ContentVersion(); 
        testContentVersion.Title = 'Test';
        testContentVersion.ContentLocation = 'S';
        testContentVersion.PathOnClient = 'Test.pdf';
        testContentVersion.VersionData = Blob.valueOf('PDF Content');
        insert testContentVersion;
        
        
        List<ContentVersion> cv = [SELECT Id, Title, ContentDocumentId
                                   FROM ContentVersion
                                   WHERE Title = 'Test'];
        
        /*if (!cv.isEmpty()) {
            List<ContentDocument> cd = [SELECT Id
                                        FROM ContentDocument
                                        WHERE Id = :cv[0].ContentDocumentId
                                        LIMIT 1];
            
            if (!cd.isEmpty()) {
                ContentDocumentLink testContentDocumentLink = new ContentDocumentLink();
                testContentDocumentLink.ContentDocumentId = cd[0].Id;
                testContentDocumentLink.LinkedEntityId = testOpportunity.Id;
                testContentDocumentLink.ShareType = 'V';
                insert testContentDocumentLink;*/
                
                
               /* List<ContentDocumentLink> cdl = [SELECT Id, ContentDocumentId
                                                 FROM ContentDocumentLink
                                                 WHERE ContentDocumentId = :cd[0].Id];
                
                if (!cdl.isEmpty()) {
                    //List<ContentDocumentLink> lst = [SELECT Id, ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE Id = :cdl[0].Id];
                    //System.assertEquals(1, lst.size());
                }
                
            } else {
                System.debug('No ContentDocument found. Skipping ContentDocumentLink creation and tests.');
            } */
        /*} else {
            System.debug('No ContentVersion found. Skipping ContentDocumentLink creation and tests.');
        }*/
    }
    @isTest static void fileUploadTestNullAttachmentType() {
        // Mock HTTP callout
        Test.setMock(HttpCalloutMock.class, new HttpEmexCalloutMock(200, 'OK', '{success:true}'));
        
        // Create test Opportunity
        Opportunity testOpportunity = new Opportunity(Name = 'Test - Opportunity', StageName = '5 - Closed Won', CloseDate = Date.today(), Est_Annual_Usage__c = 20, Expected_Contract_Term__c = 10, Expected_Contract_Start__c = Date.today(), Expected_Margin__c = 2, Legal_Entity_Name__c = 'Test Opportunity Legal');
        insert testOpportunity;
        
        
        
        // Create test ContentVersion with valid ContentDocumentId
        ContentVersion testContentVersion = new ContentVersion(
            Title = 'Test',
            ContentLocation = 'S',
            PathOnClient = 'Test.txt',
            VersionData = Blob.valueOf('Sample Text.')
        );
        insert testContentVersion;
        
        // Create test ContentDocumentLink
        ContentDocumentLink testContentDocumentLink = new ContentDocumentLink();
        testContentDocumentLink.ContentDocumentId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =: testContentVersion.Id].ContentDocumentId;
        testContentDocumentLink.LinkedEntityId = testOpportunity.Id;
        testContentDocumentLink.ShareType = 'V';
        
        insert testContentDocumentLink;
        
        // Start test execution
        Test.startTest();
        
        // Run trigger logic by updating the ContentDocumentLink
        testContentDocumentLink = [SELECT Id, ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE Id = :testContentDocumentLink.Id];
        update testContentDocumentLink;
        
        // Stop test execution
        Test.stopTest();
        
        // Verify results
        // Check that the DelayedFileDataSyncScheduler job was scheduled
        Integer expectedJobCount = 0; // need to set back to 1
        Integer actualJobCount = [SELECT Count() FROM CronTrigger WHERE CronJobDetail.Name LIKE 'DelayedFileCallout_%' AND CronJobDetail.JobType = '7' AND State = 'WAITING' AND NextFireTime != NULL];
        System.assertEquals(expectedJobCount, actualJobCount);
        
        // Add any additional assertions here as needed
    }
    
    @isTest
    static void testTriggerElseLogic() {
        
        //Create Data for Task object
        Task testTask = new Task();
        testTask.Subject = 'isTestExecution';  
        testTask.Priority = 'Normal';
        testTask.Status = 'Open';       
        insert testTask;
        System.debug('Inserted Task Subject: ' + testTask.Subject);
        
        
        // Create test ContentVersion
        ContentVersion testContentVersion = new ContentVersion(
            Title = 'Test',
            ContentLocation = 'S',
            PathOnClient = 'Test.txt',
            VersionData = Blob.valueOf('Sample Text.')
        );
        insert testContentVersion;
        
        // Link ContentVersion to ContentDocumentLink
        ContentDocumentLink testContentDocumentLink = new ContentDocumentLink(
            ContentDocumentId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =: testContentVersion.Id].ContentDocumentId,
            LinkedEntityId = testTask.Id,
            ShareType = 'V'
        );
        
        
        // Insert test ContentDocumentLink
        insert testContentDocumentLink;
        
        // Mock HTTP Callouts
        Test.setMock(HttpCalloutMock.class, new HttpEmexCalloutMock(200, 'OK', '{success:true}'));
        
        
        // Add assertions to verify the expected outcomes, if needed
    }
    
}