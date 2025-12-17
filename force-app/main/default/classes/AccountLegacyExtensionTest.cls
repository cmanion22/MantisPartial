@isTest 
public class AccountLegacyExtensionTest
{
     static testMethod void Test1() 
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

        Test.StartTest(); 
        PageReference pageRef = Page.Notes;             
        pageRef.getParameters().put('id', String.valueOf(testAccount.Id));
        Test.setCurrentPage(pageRef);
        
        ApexPages.StandardController thisStandardController = new ApexPages.StandardController(testAccount);
        AccountLegacyExtension controllerObj = new AccountLegacyExtension(thisStandardController);                         
        Test.StopTest();
     }     
}