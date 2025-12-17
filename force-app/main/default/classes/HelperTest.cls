@isTest
public class HelperTest {
    //Returns formatted json without attributes which are added by SF objects
    @isTest(SeeAllData=false) static void getFormattedJsonTest() {   
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
        testOpportunity.Name = 'Test - Test City, ST - Test Opportunity';
        testOpportunity.StageName = 'Closed Won';
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
        
        Test.setMock(HttpCalloutMock.class, new HttpEmexCalloutMock(200, 'OK', '{success:true}'));
        Opportunity opportunity = OpportunityHelper.getOpportunity(testOpportunity.Id);
        String strJson = Helper.getFormattedJson(opportunity);
        System.assertNotEquals(null, strJson);
    }    
            
    @isTest static void httpRetryScenarioTest_Pass_200() {
        integer statusCode = 200;
        Retry.Status status = Helper.httpRetryScenario(statusCode);
        System.assertEquals(Retry.Status.SUCCEEDED, status);
    }
    
    @isTest static void httpRetryScenarioTest_Pass_201() {
        integer statusCode = 201;
        Retry.Status status = Helper.httpRetryScenario(statusCode);
        System.assertEquals(Retry.Status.SUCCEEDED, status);
    }
    
    @isTest static void httpRetryScenarioFailTest_400() {
        integer statusCode = 400;
        Retry.Status status = Helper.httpRetryScenario(statusCode);
        System.assertEquals(Retry.Status.BAD_REQUEST, status);
    }
    
    @isTest static void httpRetryScenarioFailTest_401() {
        integer statusCode = 401;
        Retry.Status status = Helper.httpRetryScenario(statusCode);
        System.assertEquals(Retry.Status.UNAUTHORISED, status);
    }
    
    @isTest static void httpRetryScenarioFailTest_403() {
        integer statusCode = 403;
        Retry.Status status = Helper.httpRetryScenario(statusCode);
        System.assertEquals(Retry.Status.FORBIDDEN, status);
    }
    
    @isTest static void httpRetryScenarioFailTest_404() {
        integer statusCode = 404;
        Retry.Status status = Helper.httpRetryScenario(statusCode);
        System.assertEquals(Retry.Status.NOT_FOUND, status);
    }
    
    @isTest static void httpRetryScenarioFailTest_500() {
        integer statusCode = 500;
        Retry.Status status = Helper.httpRetryScenario(statusCode);
        System.assertEquals(Retry.Status.INTERNAL_SERVER_ERROR, status);
    }
    
    @isTest static void httpRetryScenarioFailTest_503() {
        integer statusCode = 503;
        Retry.Status status = Helper.httpRetryScenario(statusCode);
        System.assertEquals(Retry.Status.SERVICE_UNAVAILABLE, status);
    }
    
    @isTest static void httpRetryScenarioFailTest_501() {
        integer statusCode = 501;
        Retry.Status status = Helper.httpRetryScenario(statusCode);
        System.assertEquals(Retry.Status.FAILED_RETRY, status);
    }

    @isTest static void generateSelectQueryTest() {
        String query = Helper.generateSelectQuery('User');
        System.assertNotEquals(null, query);
    }

    @isTest static void removeAttributesTest() {
        Map<String, Object> jsonObj = new Map<String, Object>();
        jsonObj.put('Id', '001');
        jsonObj.put('attributes', 'Test');        
        Helper.removeAttributes(jsonObj);
        System.assertEquals(false, jsonObj.containsKey('attributes'));
    }

    @isTest static void removeAttributeTest() {
        Map<String, Object> jsonObj = new Map<String, Object>();
        jsonObj.put('Id', '001');
        jsonObj.put('attributes', 'Test');        
        Helper.removeAttribute(jsonObj, 'attributes');
        System.assertEquals(false, jsonObj.containsKey('attributes'));
    }

    @isTest static void getJsonMapTest() {
        Market__c testMarket = new Market__c();
        testMarket.Name = 'Test Market';
        testMarket.Commodity__c = 'Electricity';
        testMarket.Region__c = 'US';    
        testMarket.Country__c = 'US';
        testMarket.Source_ID__c = 'Test Source Id Market';
        testMarket.Source_Database__c = 'Test Source DB Market';    
        insert testMarket;

        Map<String,Object> mapObj = Helper.getJsonMap(testMarket);
        System.assertEquals(testMarket.Id, mapObj.get('Id'));
    }

    @isTest static void addAttributeTest() {
        Map<String, Object> jsonObj = new Map<String, Object>();
        jsonObj.put('Id', '001');
        Map<String, Object> updatedJsonObj = Helper.addAttribute(jsonObj, 'attributes', 'Test');
        System.assertEquals(true, updatedJsonObj.containsKey('attributes'));
    }

    @isTest static void getFormattedJsonFromMapTest() {
        Map<String, Object> jsonObj = new Map<String, Object>();
        jsonObj.put('Name', 'Test Market');
        jsonObj.put('Commodity__c', 'Electricity');
        jsonObj.put('Region__c', 'US');    
         
        String result = Helper.getFormattedJsonFromMap(jsonObj);
        System.assertNotEquals(null, result);
    }


    @isTest static void LockRecordTest(){
        Task testTask = new Task();
        testTask.Subject = 'Test Task';  
        testTask.Priority = 'Normal';
        testTask.Status = 'Open';       
        insert testTask;

        Trigger_Disabled__c disabled = new Trigger_Disabled__c();
        disabled.Name = testTask.Id;
        upsert disabled Name;

        Boolean isLocked = Helper.LockRecord(testTask.Id);
        System.assertEquals(false, isLocked);
    }

    @isTest static void UnlockRecordTest(){
        Task testTask = new Task();
        testTask.Subject = 'Test Task';  
        testTask.Priority = 'Normal';
        testTask.Status = 'Open';       
        insert testTask;

        Boolean isLocked = Helper.UnlockRecord(testTask.Id);
        System.assertEquals(false, isLocked);
    }

    @isTest static void IsRecordLockedTest(){
        Task testTask = new Task();
        testTask.Subject = 'Test Task';  
        testTask.Priority = 'Normal';
        testTask.Status = 'Open';       
        insert testTask;

        Trigger_Disabled__c disabled = new Trigger_Disabled__c();
        disabled.Name = testTask.Id;
        upsert disabled Name;

        Boolean isLocked = Helper.IsRecordLocked(testTask.Id);
        System.assertEquals(true, isLocked);
    }
}