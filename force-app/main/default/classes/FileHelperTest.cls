@isTest
public class FileHelperTest {

    @testSetup static void setup() {
        Uuid brokerUuid = new Uuid();
        String brokerUuidValue = brokerUuid.getValue();
        insert new Broker__c(
            Name = 'Mock Broker',
            Source_ID__c = 'Source Id ' + brokerUuidValue,
            Source_Database__c = 'Source DB ' + brokerUuidValue
        );

        insert new Configuration__c(Name = 'ESBURL');
    }

    @isTest(SeeAllData=false) static void createFileJsonTest() 
    {
        Broker__c testBroker = [SELECT Id, Name, Source_ID__c, Source_Database__c FROM Broker__c WHERE Name='Mock Broker'];
        
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
        testContentDocumentLink.ContentDocumentId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =: testContentVersion.Id].ContentDocumentId;
        testContentDocumentLink.LinkedEntityId = testOpportunity.Id;
        testContentDocumentLink.ShareType = 'V';
        insert testContentDocumentLink;

        string result = FileHelper.createFileJson(testOpportunity.Id);
        System.assertNotEquals(null, result);
    }
    
    @isTest(SeeAllData=false) static void getFilesTest() 
    {    
        Broker__c testBroker = [SELECT Id, Name, Source_ID__c, Source_Database__c FROM Broker__c WHERE Name='Mock Broker'];
        
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
        testContentDocumentLink.ContentDocumentId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =: testContentVersion.Id].ContentDocumentId;
        testContentDocumentLink.LinkedEntityId = testOpportunity.Id;
        testContentDocumentLink.ShareType = 'V';
        insert testContentDocumentLink;

        List<ContentDocument> lstContentDocument = FileHelper.getFiles(testOpportunity.Id); 
        
        System.assertEquals(1, lstContentDocument.size());        
    }
    
    @isTest(SeeAllData=false) static void createClsFileTest() 
    {   
        Test.setMock(HttpCalloutMock.class, new HttpEmexCalloutMock(200, 'OK', '{success:true}'));
        
        Broker__c testBroker = [SELECT Id, Name, Source_ID__c, Source_Database__c FROM Broker__c WHERE Name='Mock Broker'];
        
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
        testContentDocumentLink.ContentDocumentId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =: testContentVersion.Id].ContentDocumentId;
        testContentDocumentLink.LinkedEntityId = testOpportunity.Id;
        testContentDocumentLink.ShareType = 'V';
        insert testContentDocumentLink;
        
        ContentDocument testContentDocument = [SELECT  Id, CreatedById, CreatedDate, LastModifiedById, LastModifiedDate, 
                              IsArchived, ArchivedById, ArchivedDate, IsDeleted, OwnerId, SystemModstamp, 
                              Title, PublishStatus, LatestPublishedVersionId, ParentId, LastViewedDate, 
                              LastReferencedDate, Description, ContentSize, FileType, FileExtension,  
                              SharingOption, SharingPrivacy, ContentModifiedDate, ContentAssetId 
                              FROM ContentDocument 
                              WHERE Id =:testContentDocumentLink.ContentDocumentId];
        
        
        ClsFile clsFileObj = new ClsFile();     
           
        clsFileObj = FileHelper.createClsFile(testContentDocument, testOpportunity.Id);   
        System.assertEquals(testContentDocument.Id, clsFileObj.Id);     
    }
    
    @isTest(SeeAllData=false) static void insertContentDistributionTest() 
    {     
        Test.setMock(HttpCalloutMock.class, new HttpEmexCalloutMock(200, 'OK', '{success:true}'));    
        
        Broker__c testBroker = [SELECT Id, Name, Source_ID__c, Source_Database__c FROM Broker__c WHERE Name='Mock Broker'];
        
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
        testContentDocumentLink.ContentDocumentId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =: testContentVersion.Id].ContentDocumentId;
        testContentDocumentLink.LinkedEntityId = testOpportunity.Id;
        testContentDocumentLink.ShareType = 'V';
        insert testContentDocumentLink;
        
        ContentDocument testContentDocument = [SELECT  Id, CreatedById, CreatedDate, LastModifiedById, LastModifiedDate, 
                              IsArchived, ArchivedById, ArchivedDate, IsDeleted, OwnerId, SystemModstamp, 
                              Title, PublishStatus, LatestPublishedVersionId, ParentId, LastViewedDate, 
                              LastReferencedDate, Description, ContentSize, FileType, FileExtension,  
                              SharingOption, SharingPrivacy, ContentModifiedDate, ContentAssetId 
                              FROM ContentDocument 
                              WHERE Id =:testContentDocumentLink.ContentDocumentId];
                               
        ContentDistribution conDist = FileHelper.insertContentDistribution(testContentDocument);  
        System.assertEquals(testContentVersion.Id, conDist.ContentVersionId);      
    } 
    
    @isTest(SeeAllData=false) static void postDeleteFileJsonTest() 
    {      
        Test.startTest();   
        Broker__c testBroker = [SELECT Id, Name, Source_ID__c, Source_Database__c FROM Broker__c WHERE Name='Mock Broker'];
        
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
        testContentDocumentLink.ContentDocumentId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =: testContentVersion.Id].ContentDocumentId;
        testContentDocumentLink.LinkedEntityId = testOpportunity.Id;
        testContentDocumentLink.ShareType = 'V';
        insert testContentDocumentLink;
        
        Savepoint sp = Database.setSavepoint();
       
        Test.setMock(HttpCalloutMock.class, new HttpEmexCalloutMock(200, 'OK', '{success:true}'));
        String json = FileHelper.postDeleteFileJson(testContentDocumentLink.ContentDocumentId, testOpportunity.Id);
        
        Database.rollback(sp);
        
        Test.stopTest();        
        System.assertNotEquals(null, json);  
    }  
    
    @isTest(SeeAllData=false) static void postFileUploadedJsonTest() 
    {   
        Test.startTest();
        
        Broker__c testBroker = [SELECT Id, Name, Source_ID__c, Source_Database__c FROM Broker__c WHERE Name='Mock Broker'];
        
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
        testContentDocumentLink.ContentDocumentId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =: testContentVersion.Id].ContentDocumentId;
        testContentDocumentLink.LinkedEntityId = testOpportunity.Id;
        testContentDocumentLink.ShareType = 'V';
        insert testContentDocumentLink;
        
        Savepoint sp = Database.setSavepoint();        
        
        Test.setMock(HttpCalloutMock.class, new HttpEmexCalloutMock(200, 'OK', '{success:true}'));
        String json = FileHelper.postFileUploadedJson(testContentDocumentLink.Id, testContentDocumentLink.ContentDocumentId, testOpportunity.Id);
        
        Database.rollback(sp);        
        Test.stopTest();        
        
        System.assertNotEquals(null, json); 
    }
}