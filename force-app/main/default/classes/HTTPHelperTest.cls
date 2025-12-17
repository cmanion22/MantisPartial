@isTest
public class HTTPHelperTest { 
    @isTest(SeeAllData=true)  static void startJobTest() 
    {
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

        Account testAccount = new Account();
        testAccount.Name = 'Test Account';
        testAccount.Legal_Entity_Name__c = 'Sample Account';
        testAccount.Phone = '9090909090';
        testAccount.Entity__c = testEntity.Id;
        testAccount.OwnerId = testUser.Id;   
        insert testAccount;

        String accountJson = Helper.getFormattedJson(AccountHelper.getAccount(testAccount.Id));

        String body = 
                  '{"event": "update_account"' +
                  ', "data": {' +                
                      '"account": ' + accountJson +                
                    '}' + 
                  '}';
                    
        HTTPHelper sync = new HTTPHelper(ESBController.getESBUrl(), 'POST', body);
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new HttpEmexCalloutMock(200, 'OK', '{success:true}'));
        HttpResponse response = sync.executeHTTP();
        Test.stopTest();
        
        System.assertEquals(response.getStatusCode(), 200);           
    }  
    
    @isTest(SeeAllData=true)  static void startJobTest_Fail() 
    {
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

        Account testAccount = new Account();
        testAccount.Name = 'Test Account';
        testAccount.Legal_Entity_Name__c = 'Sample Account';
        testAccount.Phone = '9090909090';
        testAccount.Entity__c = testEntity.Id;
        testAccount.OwnerId = testUser.Id;   
        insert testAccount;

        String accountJson = Helper.getFormattedJson(AccountHelper.getAccount(testAccount.Id));

        String body = 
                  '{"event": "update_account"' +
                  ', "data": {' +                
                      '"account": ' + accountJson +                
                    '}' + 
                  '}';
                    
        HTTPHelper sync = new HTTPHelper('http://urldoesnotexist.com' , 'POST', body);
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new HttpEmexCalloutMock(404, 'Not Found', '{"error":"Does not exist"}'));
        HttpResponse response = sync.executeHTTP();
        Test.stopTest();
        
        System.assertEquals(response.getStatusCode(), 404);           
    }  
}