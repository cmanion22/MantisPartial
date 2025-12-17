@isTest
public class AccountCalloutClassTest{
    @isTest static void updateAccountTest() {
        Test.startTest();

        insert new Configuration__c(Name = 'ESBURL');
        insert new Back_Office_Integration_Settings__c(Name = 'Staging', Endpoint_URL__c = 'https://www.example.com');
        insert new Back_Office_Integration_Settings__c(Name = 'Production', Endpoint_URL__c = 'https://www.example.com');
        
		List<Id> accountIdList = new List<Id>();        
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
            Entity_ID__c=testEntity.Id, Entity_Name__c=testEntity.Name, API_Token__c = 'test');
            
        insert testUser;

        Account testAccount = new Account();
        testAccount.Name = 'Test Account';
        testAccount.Legal_Entity_Name__c = 'Sample Account';
        testAccount.Phone = '9090909090';
        testAccount.Entity__c = testEntity.Id;
        testAccount.OwnerId = testUser.Id;   
        insert testAccount;
        accountIdList.add(testAccount.Id);
                
        Savepoint sp = Database.setSavepoint();

        Test.setMock(HttpCalloutMock.class, new HttpEmexCalloutMock(200, 'OK', '{success:true}'));
        String json = AccountCalloutClass.updateAccount(testAccount.Id, testUser.Id);
        AccountCalloutClass.createAccount(accountIdList);
        Database.rollback(sp);
        Test.stopTest(); 

        List<Account> lst = [SELECT Id, Name  FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals(1, lst.size());        
    }
}