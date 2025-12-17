@isTest
public class ContentDocumentTriggerTestClass {
    @isTest(SeeAllData=false) static void deleteFileTest() {
        Test.setMock(HttpCalloutMock.class, new HttpEmexCalloutMock(200, 'OK', '{success:true}'));  
        //Create Data 
        
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
        testContentDocumentLink.ContentDocumentId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =: testContentVersion.Id].ContentDocumentId;
        testContentDocumentLink.LinkedEntityId = testOpportunity.Id;
        testContentDocumentLink.ShareType = 'V';
        insert testContentDocumentLink;
        
        ContentDocument testContentDocument = [SELECT    Id, CreatedById, CreatedDate, LastModifiedById, LastModifiedDate, 
                                        IsArchived, ArchivedById, ArchivedDate, IsDeleted, OwnerId, SystemModstamp, 
                                        Title, PublishStatus, LatestPublishedVersionId, ParentId, LastViewedDate, 
                                        LastReferencedDate, Description, ContentSize, FileType, FileExtension,  
                                        SharingOption, SharingPrivacy, ContentModifiedDate, ContentAssetId 
                              FROM ContentDocument 
                              WHERE Id =:testContentDocumentLink.ContentDocumentId];
        Test.startTest();
        delete testContentDocument;
        Test.stopTest();
        
        // Now check if it is giving desired results using System.assert
        // Statement.New File should be created
        List<ContentDocumentLink> lst = [SELECT Id, ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE Id = :testContentDocumentLink.Id];
        System.assertEquals(0, lst.size());
        // Check if one record is created in File sObject
    }


    @isTest(SeeAllData=false) static void deleteFileTest_Active() {
        Test.setMock(HttpCalloutMock.class, new HttpEmexCalloutMock(200, 'OK', '{success:true}'));  
        //Create Data 

        
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
        testContentDocumentLink.ContentDocumentId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =: testContentVersion.Id].ContentDocumentId;
        testContentDocumentLink.LinkedEntityId = testOpportunity.Id;
        testContentDocumentLink.ShareType = 'V';
        insert testContentDocumentLink;
        
        ContentDocument testContentDocument = [SELECT    Id, CreatedById, CreatedDate, LastModifiedById, LastModifiedDate, 
                                        IsArchived, ArchivedById, ArchivedDate, IsDeleted, OwnerId, SystemModstamp, 
                                        Title, PublishStatus, LatestPublishedVersionId, ParentId, LastViewedDate, 
                                        LastReferencedDate, Description, ContentSize, FileType, FileExtension,  
                                        SharingOption, SharingPrivacy, ContentModifiedDate, ContentAssetId 
                              FROM ContentDocument 
                              WHERE Id =:testContentDocumentLink.ContentDocumentId];
        
        Turn_off_Processes__c processSettings = new Turn_off_Processes__c();
        processSettings.Name = 'migration in progress';
        processSettings.Is_Active__c = true;
        insert processSettings;
        
        Test.startTest();
        delete testContentDocument;
        Test.stopTest();
        
        // Now check if it is giving desired results using System.assert
        // Statement.New File should be created
        List<ContentDocumentLink> lst = [SELECT Id, ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE Id = :testContentDocumentLink.Id];
        System.assertEquals(0, lst.size());
        // Check if one record is created in File sObject
    }
    
    
    @isTest 
		public static void foundOtherCDLs() {
    	// Create test user
    	Profile testProfile = [SELECT Id FROM Profile WHERE Name='Standard User'];
    	User testUser = new User(
        Alias = 'standt',
        Email='testuser@emex.com',
        EmailEncodingKey='UTF-8',
        FirstName ='Mantis',
        LastName='Back Office',
        LanguageLocaleKey='en_US',
        LocaleSidKey='en_US',
        ProfileId = testProfile.Id,
        TimeZoneSidKey='America/Los_Angeles',
        UserName='emextestuser@emex.com'); 
    	        
    	insert testUser;

    	// Create an account
    	Account acc = new Account();
    	acc.Name = '123Test';
    	insert acc;
            
        // Create a Contact
        Contact newContact = new Contact();
            newContact.LastName = 'test';
            newContact.AccountId = acc.Id;
            newContact.LeadSource = 'Event';
            insert newContact;
            
    	 // Create a ContentVersion
    	ContentVersion testContentVersion = new ContentVersion(); 
    	testContentVersion.Title = 'Test';
    	testContentVersion.ContentLocation = 'S';
    	testContentVersion.PathOnClient = 'Test.txt';
    	testContentVersion.VersionData = Blob.valueOf('Sample Text.');
    	insert testContentVersion;

    	// Create a ContentDocumentLink related to the testUser
    	ContentDocumentLink testContentDocumentLink = new ContentDocumentLink();
    	testContentDocumentLink.ContentDocumentId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion.Id].ContentDocumentId;
    	testContentDocumentLink.LinkedEntityId = testUser.Id;
    	testContentDocumentLink.ShareType = 'V';
    	insert testContentDocumentLink;
        
    	// Create another ContentDocumentLink related to the account
    	ContentDocumentLink testContentDocumentLink2 = new ContentDocumentLink();
    	testContentDocumentLink2.ContentDocumentId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion.Id].ContentDocumentId;
    	testContentDocumentLink2.LinkedEntityId = acc.Id;
    	testContentDocumentLink2.ShareType = 'V';
    	insert testContentDocumentLink2;
            
        // Create another ContentDocumentLink related to the Contact
    	ContentDocumentLink testContentDocumentLink3 = new ContentDocumentLink();
    	testContentDocumentLink3.ContentDocumentId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion.Id].ContentDocumentId;
    	testContentDocumentLink3.LinkedEntityId = newContact.Id;
    	testContentDocumentLink3.ShareType = 'V';
    	insert testContentDocumentLink3;

    	// Retrieve ContentDocumentLink related to acc
			List<ContentDocumentLink> updatedCDLs = [SELECT Id, ContentDocumentId, LinkedEntityId
    													FROM ContentDocumentLink
                                                     	WHERE Id = :testContentDocumentLink2.Id];
		User mantisBackOffice = [SELECT Id 
                         FROM User 
                         WHERE Name = 'Mantis Back Office' 
                         LIMIT 1];

    	// Set the current context user to the testUser
    	System.runAs(mantisBackOffice) {
        // Call the method under test
        Test.startTest();
        ContentDocumentLinkClass.beforeDeleteCDL(updatedCDLs);
        Test.stopTest();
    }	
        
    	// Verify the ContentDocument has not been deleted
    	List<ContentDocument> cd = [SELECT Id FROM ContentDocument WHERE Id = :testContentDocumentLink.ContentDocumentId];
        system.debug('Test Method Name: foundOtherCDLs');
        system.debug('cd retrieved: ' + cd.size());
    	System.assertEquals(1, cd.size(), 'ContentDocument should not have been deleted');
   }
    
    @isTest 
		public static void foundOneOtherUserCDL() {
    	// Create test user
    	Profile testProfile = [SELECT Id FROM Profile WHERE Name='Standard User'];
    	User testUser = new User(
        Alias = 'standt',
        Email='testuser@emex.com',
        EmailEncodingKey='UTF-8',
        FirstName ='Mantis',
        LastName='Back Office',
        LanguageLocaleKey='en_US',
        LocaleSidKey='en_US',
        ProfileId = testProfile.Id,
        TimeZoneSidKey='America/Los_Angeles',
        UserName='emextestuser@emex.com'); 
    	        
    	insert testUser;

    	// Create an account
    	Account acc = new Account();
    	acc.Name = '123Test';
    	insert acc;

   		// Create a ContentVersion
    	ContentVersion testContentVersion = new ContentVersion(); 
    	testContentVersion.Title = 'Test';
    	testContentVersion.ContentLocation = 'S';
    	testContentVersion.PathOnClient = 'Test.txt';
    	testContentVersion.VersionData = Blob.valueOf('Sample Text.');
    	insert testContentVersion;

    	// Create a ContentDocumentLink related to the testUser
    	ContentDocumentLink testContentDocumentLink = new ContentDocumentLink();
    	testContentDocumentLink.ContentDocumentId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion.Id].ContentDocumentId;
    	testContentDocumentLink.LinkedEntityId = testUser.Id;
    	testContentDocumentLink.ShareType = 'V';
    	insert testContentDocumentLink;
        
    	// Create another ContentDocumentLink related to the account
    	ContentDocumentLink testContentDocumentLink2 = new ContentDocumentLink();
    	testContentDocumentLink2.ContentDocumentId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion.Id].ContentDocumentId;
    	testContentDocumentLink2.LinkedEntityId = acc.Id;
    	testContentDocumentLink2.ShareType = 'V';
    	insert testContentDocumentLink2;

    	// Retrieve ContentDocumentLink related to acc
			List<ContentDocumentLink> updatedCDLs = [SELECT Id, ContentDocumentId, LinkedEntityId
    													FROM ContentDocumentLink
                                                     	WHERE Id = :testContentDocumentLink2.Id];
          
		User mantisBackOffice = [SELECT Id 
                         FROM User 
                         WHERE Name = 'Mantis Back Office' 
                         LIMIT 1];

    	// Set the current context user to the testUser
    	System.runAs(mantisBackOffice) {
        // Call the method under test
        Test.startTest();
        ContentDocumentLinkClass.beforeDeleteCDL(updatedCDLs);
        Test.stopTest();
    }	
        
    	// Verify the ContentDocument has been deleted
    	List<ContentDocument> cd = [SELECT Id FROM ContentDocument WHERE Id = :testContentDocumentLink.ContentDocumentId];
                                  
        system.debug('Test Method Name: foundOneOtherUserCDL');
        system.debug('cd retrieved: ' + cd.size());
    	System.assertEquals(0, cd.size(), 'ContentDocument should have been deleted');
   }
    
    @isTest public static void testContinueStatement() {
        
         // Create test data with one null ContentDocumentLink
        List<ContentDocumentLink> cdls = new List<ContentDocumentLink>();
        ContentDocumentLink cdl1 = new ContentDocumentLink(); // Valid ContentDocumentLink
        cdls.add(cdl1);
        ContentDocumentLink cdl2 = null; // Null ContentDocumentLink
        cdls.add(cdl2);
        ContentDocumentLink cdl3 = new ContentDocumentLink(); // Another valid ContentDocumentLink
        cdls.add(cdl3);
        
        // Call the method under test
        Test.startTest();
        ContentDocumentLinkClass.beforeDeleteCDL(cdls);
        Test.stopTest();
        system.debug('Test Method Name: testContinueStatement');
        
       
    }
    
      @isTest 
		public static void testUserDeletedCDL() {
    	// Create test user
    	Profile testProfile = [SELECT Id FROM Profile WHERE Name='Standard User'];
    	User testUser = new User(
        Alias = 'standt',
        Email='testuser@emex.com',
        EmailEncodingKey='UTF-8',
        FirstName ='Mantis',
        LastName='Back Office',
        LanguageLocaleKey='en_US',
        LocaleSidKey='en_US',
        ProfileId = testProfile.Id,
        TimeZoneSidKey='America/Los_Angeles',
        UserName='emextestuser@emex.com'); 
    	        
    	insert testUser;

    	// Create an account
    	Account acc = new Account();
    	acc.Name = '123Test';
    	insert acc;

   		// Create a ContentVersion
    	ContentVersion testContentVersion = new ContentVersion(); 
    	testContentVersion.Title = 'Test';
    	testContentVersion.ContentLocation = 'S';
    	testContentVersion.PathOnClient = 'Test.txt';
    	testContentVersion.VersionData = Blob.valueOf('Sample Text.');
    	insert testContentVersion;

    	// Create a ContentDocumentLink related to the testUser
    	ContentDocumentLink testContentDocumentLink = new ContentDocumentLink();
    	testContentDocumentLink.ContentDocumentId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion.Id].ContentDocumentId;
    	testContentDocumentLink.LinkedEntityId = testUser.Id;
    	testContentDocumentLink.ShareType = 'V';
    	insert testContentDocumentLink;
        
    	// Create another ContentDocumentLink related to the account
    	ContentDocumentLink testContentDocumentLink2 = new ContentDocumentLink();
    	testContentDocumentLink2.ContentDocumentId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion.Id].ContentDocumentId;
    	testContentDocumentLink2.LinkedEntityId = acc.Id;
    	testContentDocumentLink2.ShareType = 'V';
    	insert testContentDocumentLink2;

    	// Retrieve ContentDocumentLink related to acc
			List<ContentDocumentLink> updatedCDLs = [SELECT Id, ContentDocumentId, LinkedEntityId
    													FROM ContentDocumentLink
                                                     	WHERE Id = :testContentDocumentLink2.Id];
          
		User mantisBackOffice = [SELECT Id 
                         FROM User 
                         WHERE Name = 'Mantis Back Office' 
                         LIMIT 1];

    	// Set the current context user to the testUser
    	System.runAs(testUser) {
        // Call the method under test
        Test.startTest();
        ContentDocumentLinkClass.beforeDeleteCDL(updatedCDLs);
        Test.stopTest();
    }	
        
    	// Verify the ContentDocument has been deleted
    	List<ContentDocument> cd = [SELECT Id FROM ContentDocument WHERE Id = :testContentDocumentLink.ContentDocumentId];
                                  
        system.debug('Test Method Name: testUserDeletedCDL');
        system.debug('cd retrieved: ' + cd.size());
    	System.assertEquals(1, cd.size(), 'ContentDocument should not have been deleted since the current user was not MBO');
   }
    
    @isTest 
		public static void testCDLBeforeDeleteTrigger() {
    	// Create test user
    	Profile testProfile = [SELECT Id FROM Profile WHERE Name='Standard User'];
    	User testUser = new User(
        Alias = 'standt',
        Email='testuser@emex.com',
        EmailEncodingKey='UTF-8',
        FirstName ='Mantis',
        LastName='Back Office',
        LanguageLocaleKey='en_US',
        LocaleSidKey='en_US',
        ProfileId = testProfile.Id,
        TimeZoneSidKey='America/Los_Angeles',
        UserName='emextestuser@emex.com'); 
    	        
    	insert testUser;

    	// Create an account
    	Account acc = new Account();
    	acc.Name = '123Test';
    	insert acc;

   		// Create a ContentVersion
    	ContentVersion testContentVersion = new ContentVersion(); 
    	testContentVersion.Title = 'Test';
    	testContentVersion.ContentLocation = 'S';
    	testContentVersion.PathOnClient = 'Test.txt';
    	testContentVersion.VersionData = Blob.valueOf('Sample Text.');
    	insert testContentVersion;

    	// Create a ContentDocumentLink related to the testUser
    	ContentDocumentLink testContentDocumentLink = new ContentDocumentLink();
    	testContentDocumentLink.ContentDocumentId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion.Id].ContentDocumentId;
    	testContentDocumentLink.LinkedEntityId = testUser.Id;
    	testContentDocumentLink.ShareType = 'V';
    	insert testContentDocumentLink;
        
    	// Create another ContentDocumentLink related to the account
    	ContentDocumentLink testContentDocumentLink2 = new ContentDocumentLink();
    	testContentDocumentLink2.ContentDocumentId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion.Id].ContentDocumentId;
    	testContentDocumentLink2.LinkedEntityId = acc.Id;
    	testContentDocumentLink2.ShareType = 'V';
    	insert testContentDocumentLink2;

    	// Retrieve ContentDocumentLink related to acc
			List<ContentDocumentLink> updatedCDLs = [SELECT Id, ContentDocumentId, LinkedEntityId
    													FROM ContentDocumentLink
                                                     	WHERE Id = :testContentDocumentLink2.Id];
          
		delete testContentDocumentLink2;

    	
        
    	// Verify the ContentDocument has been deleted
    	List<ContentDocument> cd = [SELECT Id FROM ContentDocument WHERE Id = :testContentDocumentLink.ContentDocumentId];
                                  
        system.debug('Test Method Name: testCDLBeforeDeleteTrigger');
        system.debug('cd retrieved: ' + cd.size());
    	System.assertEquals(1, cd.size(), 'ContentDocument should not have been deleted since the current user was not MBO');
   }
}