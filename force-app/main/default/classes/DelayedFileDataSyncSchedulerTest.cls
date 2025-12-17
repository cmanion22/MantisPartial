@isTest
public class DelayedFileDataSyncSchedulerTest {

   @isTest 
    static void testExecuteSandbox() {
        
        // Set mock for HTTP callout
        Test.setMock(HttpCalloutMock.class, new MyHttpCalloutMock());

        // Create test data
        Broker__c testBroker = new Broker__c(Name = 'Test Broker', Source_ID__c = 'Test Source Id Broker', Source_Database__c = 'Test Source DB Broker');
        insert testBroker;

        Entity__c testEntity = new Entity__c(Name = 'Test Entity', Brand__c = 'Test Brand', Source_ID__c = 'Test Source Id Entity', Source_Database__c = 'Test Source DB Entity');
        insert testEntity;

        Market__c testMarket = new Market__c(Name = 'Test Market', Commodity__c = 'Electricity', Region__c = 'US', Country__c = 'US', Source_ID__c = 'Test Source Id Market', Source_Database__c = 'Test Source DB Market');
        insert testMarket;

        Profile testProfile = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User testUser = new User(
            Alias = 'standt', 
            Email='testuser@emex.com', 
            EmailEncodingKey='UTF-8',
            FirstName = 'Mantis',
            LastName='Back Office', 
            LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', 
            ProfileId = testProfile.Id, 
            TimeZoneSidKey='America/Los_Angeles', 
            UserName='emextestuser@emex.com', 
            Entity_ID__c = testEntity.Id, 
            Entity_Name__c = testEntity.Name,
            API_Token__c = '111111ad-11e1-1111-bf1c-fa11c1cb1a11'
        );
        insert testUser;

        Opportunity testOpportunity = new Opportunity(
            Name = 'Test - Opportunity', 
            StageName = '5 - Closed Won', 
            Broker__c = testBroker.Id, 
            Entity__c = testEntity.Id, 
            Commodity__c = 'Electricity', 
            Market__c = testMarket.Id, 
            CloseDate = Date.today(), 
            Est_Annual_Usage__c = 20, 
            Expected_Contract_Term__c = 10, 
            Expected_Contract_Start__c = Date.today(), 
            Expected_Margin__c = 2, 
            Legal_Entity_Name__c = 'Test Opportunity Legal', 
            OwnerId = testUser.Id
        );
        insert testOpportunity;

        ContentVersion testContentVersion = new ContentVersion(
            Title = 'Test', 
            ContentLocation = 'S', 
            PathOnClient = 'Test.txt', 
            VersionData = Blob.valueOf('Sample Text.')
        );
        insert testContentVersion;

        ContentDocumentLink testContentDocumentLink = new ContentDocumentLink(
            ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion.Id].ContentDocumentId, 
            LinkedEntityId = testOpportunity.Id, 
            ShareType = 'V'
        );
        insert testContentDocumentLink;
        
         // Create ESBURL configuration record
        Configuration__c esbUrlConfig = new Configuration__c(
            Name = 'ESBURL',
            ESBBaseURL__c = 'https://placeholder-esb-url.com' // Placeholder: Replace with your actual ESB base URL
        );
        insert esbUrlConfig;

        // Create the scheduler instance
        DelayedFileDataSyncScheduler scheduler = new DelayedFileDataSyncScheduler(
            testContentDocumentLink.Id, 
            testContentDocumentLink.ContentDocumentId, 
            testOpportunity.Id
        );
        
        // Set the Utils.isSandbox flag to true
        Utils.isSandbox = true;
        
        // Create a mock integration setting for sandbox
        Back_Office_Integration_Settings__c sandboxSettings = new Back_Office_Integration_Settings__c(
            Name = 'Staging',
            Endpoint_Username__c = 'redsox-full-user',
            Endpoint_Requires_Authentication__c = true,
            Endpoint_Password__c = 'patriots - brady - love',
            Endpoint_URL__c = 'https://staging.mantisinnovation1.com'
        );
        
        // Insert the integration setting into the database
        insert sandboxSettings;

        // Retrieve the ID of the user who will be used to get the ESB URL
        User mantisBackOffice = [SELECT Id 
                         FROM User 
                         WHERE Name = 'Mantis Back Office' 
                         LIMIT 1];

        // Set the current context user to the testUser
        System.runAs(mantisBackOffice) {
            Test.startTest();

            // Schedule the job to run immediately
            String jobId = System.schedule('TestDelayedFileSync', '0 0 0 * * ?', scheduler);

            Test.stopTest();

            // Assertions
            System.assertNotEquals(null, jobId, 'Job ID should not be null');
            // Assert the ESB URL is not null
			String esbUrl = ESBController.getESBUrl(mantisBackOffice.Id);
			System.assertNotEquals(null, esbUrl, 'ESB URL should not be null');
    	}
	}
    
    @isTest 
    static void testExecuteProd() {
        
        // Set mock for HTTP callout
        Test.setMock(HttpCalloutMock.class, new MyHttpCalloutMock());

        // Create test data
        Broker__c testBroker = new Broker__c(Name = 'Test Broker', Source_ID__c = 'Test Source Id Broker', Source_Database__c = 'Test Source DB Broker');
        insert testBroker;

        Entity__c testEntity = new Entity__c(Name = 'Test Entity', Brand__c = 'Test Brand', Source_ID__c = 'Test Source Id Entity', Source_Database__c = 'Test Source DB Entity');
        insert testEntity;

        Market__c testMarket = new Market__c(Name = 'Test Market', Commodity__c = 'Electricity', Region__c = 'US', Country__c = 'US', Source_ID__c = 'Test Source Id Market', Source_Database__c = 'Test Source DB Market');
        insert testMarket;

        Profile testProfile = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User testUser = new User(
            Alias = 'standt', 
            Email='testuser@emex.com', 
            EmailEncodingKey='UTF-8',
            FirstName = 'Mantis',
            LastName='Back Office', 
            LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', 
            ProfileId = testProfile.Id, 
            TimeZoneSidKey='America/Los_Angeles', 
            UserName='emextestuser@emex.com', 
            Entity_ID__c = testEntity.Id, 
            Entity_Name__c = testEntity.Name,
            API_Token__c = '111111ad-11e1-1111-bf1c-fa11c1cb1a11'
        );
        insert testUser;

        Opportunity testOpportunity = new Opportunity(
            Name = 'Test - Opportunity', 
            StageName = '5 - Closed Won', 
            Broker__c = testBroker.Id, 
            Entity__c = testEntity.Id, 
            Commodity__c = 'Electricity', 
            Market__c = testMarket.Id, 
            CloseDate = Date.today(), 
            Est_Annual_Usage__c = 20, 
            Expected_Contract_Term__c = 10, 
            Expected_Contract_Start__c = Date.today(), 
            Expected_Margin__c = 2, 
            Legal_Entity_Name__c = 'Test Opportunity Legal', 
            OwnerId = testUser.Id
        );
        insert testOpportunity;

        ContentVersion testContentVersion = new ContentVersion(
            Title = 'Test', 
            ContentLocation = 'S', 
            PathOnClient = 'Test.txt', 
            VersionData = Blob.valueOf('Sample Text.')
        );
        insert testContentVersion;

        ContentDocumentLink testContentDocumentLink = new ContentDocumentLink(
            ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion.Id].ContentDocumentId, 
            LinkedEntityId = testOpportunity.Id, 
            ShareType = 'V'
        );
        insert testContentDocumentLink;
        
         // Create ESBURL configuration record
        Configuration__c esbUrlConfig = new Configuration__c(
            Name = 'ESBURL',
            ESBBaseURL__c = 'https://placeholder-esb-url.com' // Placeholder: Replace with your actual ESB base URL
        );
        insert esbUrlConfig;

        // Create the scheduler instance
        DelayedFileDataSyncScheduler scheduler = new DelayedFileDataSyncScheduler(
            testContentDocumentLink.Id, 
            testContentDocumentLink.ContentDocumentId, 
            testOpportunity.Id
        );
        
       // Set the Utils.isSandbox flag to false
        Utils.isSandbox = false;
                
        // Create a mock integration setting for production
        Back_Office_Integration_Settings__c productionSettings = new Back_Office_Integration_Settings__c(
            Name = 'Production',
            Endpoint_Username__c = 'redsox-full-user',
            Endpoint_Requires_Authentication__c = true,
            Endpoint_Password__c = 'patriots - brady - love',
            Endpoint_URL__c = 'https://app.mantisinnovation1.com'
        );
        
        // Insert the integration setting into the database
        insert productionSettings;

        // Retrieve the ID of the user who will be used to get the ESB URL
        User mantisBackOffice = [SELECT Id 
                         FROM User 
                         WHERE Name = 'Mantis Back Office' 
                         LIMIT 1];

        // Set the current context user to the testUser
        System.runAs(mantisBackOffice) {
            Test.startTest();

            // Schedule the job to run immediately
            String jobId = System.schedule('TestDelayedFileSync', '0 0 0 * * ?', scheduler);

            Test.stopTest();

            // Assertions
            System.assertNotEquals(null, jobId, 'Job ID should not be null');
            // Assert the ESB URL is not null
			String esbUrl = ESBController.getESBUrl(mantisBackOffice.Id);
			System.assertNotEquals(null, esbUrl, 'ESB URL should not be null');
    	}
	}

    	// Mock class for HTTP callout
		private class MyHttpCalloutMock implements HttpCalloutMock {
    		public HttpResponse respond(HttpRequest req) {
			// Simulate response from external service
        	HttpResponse res = new HttpResponse();
        	res.setStatusCode(200);
        	res.setBody('{"success": true}');
        	return res;
   		 }
	}
       
}