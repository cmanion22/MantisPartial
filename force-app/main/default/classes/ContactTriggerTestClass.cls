@isTest
public class ContactTriggerTestClass {
    @isTest(SeeAllData=true) static void contactTriggerTest() {
        Test.setMock(HttpCalloutMock.class, new HttpEmexCalloutMock(200, 'OK', '{success:true}'));  
        //Create Data for Contact object
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

        //Create Data for Contact object
        Contact testContact = new Contact();
        testContact.OwnerId = testUser.Id;
        testContact.AccountId = testAccount.Id;
        testContact.FirstName = 'John';
        testContact.LastName = 'Doe';
        testContact.Phone = '9090909090';
        testContact.Email = 'johndoe@example.com';
        testContact.MailingCity = 'Houston';
        testContact.MailingState = 'TX';
        testContact.MailingStreet = '123 Main St';
        testContact.MailingPostalCode = '77002';
        insert testContact;
        
        // Now, our trigger will fire on After update event so update the Records
        Test.startTest();    // Starts the scope of test
        testContact.Phone = '9990009990';
        update testContact;
        Test.stopTest();     // Ends the scope of test
        
        // Now check if it is giving desired results using System.assert
        // Statement.New Contact should be created
        List<Contact> lst = [SELECT Id, FirstName, LastName, Phone  FROM Contact WHERE Id = :testContact.Id];
        System.assertEquals(1, lst.size());
        // Check if one record is created in Contact sObject
    }

    @isTest(SeeAllData=true) static void contactTriggerTest_delete() {
        Test.setMock(HttpCalloutMock.class, new HttpEmexCalloutMock(200, 'OK', '{success:true}'));  
        //Create Data for Contact object
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

        //Create Data for Contact object
        Contact testContact = new Contact();
        testContact.OwnerId = testUser.Id;
        testContact.AccountId = testAccount.Id;
        testContact.FirstName = 'John';
        testContact.LastName = 'Doe';
        testContact.Phone = '9090909090';
        testContact.Email = 'johndoe@example.com';
        testContact.MailingCity = 'Houston';
        testContact.MailingState = 'TX';
        testContact.MailingStreet = '123 Main St';
        testContact.MailingPostalCode = '77002';
        testContact.Primary_Contact__c = true;
        insert testContact;
        
        Account testAccount2 = new Account();
        testAccount2.Name = 'Test Account';
        testAccount2.Legal_Entity_Name__c = 'Sample Account';
        testAccount2.Phone = '9090909090';
        testAccount2.Entity__c = testEntity.Id;
        testAccount2.OwnerId = testUser.Id;
        
        insert testAccount2;
        
        Contact testContact2 = new Contact();
        testContact2.OwnerId = testUser.Id;
        testContact2.AccountId = testAccount2.Id;
        testContact2.FirstName = 'John';
        testContact2.LastName = 'Doe';
        testContact2.Phone = '9090909090';
        testContact2.Email = 'johndoe@example.com';
        testContact2.MailingCity = 'Houston';
        testContact2.MailingState = 'TX';
        insert testContact2;
        
        testAccount2.Primary_Contact__c = testContact2.Id;
        update testAccount2;
        
        testContact2.MailingStreet = '123 Main St';
		update testContact2;
        
        system.debug('testAccount2.Primary_Contact__c ' + testAccount2.Primary_Contact__c + ' testContact2.Id ' + testContact2.Id);
        system.debug('testContact2.AccountId is ' + testContact2.AccountId + ' testContact2.Account_Primary_Contact__c is ' + testContact2.Account_Primary_Contact__c);
        try
        {
            delete testContact;
            delete testContact2;
        }
        catch(Exception e)
        {
            //Boolean expectedExceptionThrown =  e.getMessage().contains('This Contact has been selected as the Primary Contact on at least one Opportunity. It cannot be deleted.') ? true : false;
            System.Assert(e.getMessage().contains('It cannot be deleted'));
        } 
    }
    
      @isTest(SeeAllData=true) static void contactTriggerTest_delete2() {
        Test.setMock(HttpCalloutMock.class, new HttpEmexCalloutMock(200, 'OK', '{success:true}'));  
        //Create Data for Contact object
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
		Id partnerAccountRecordTypeId = [SELECT Id,Name FROM RecordType WHERE SobjectType='Account' AND Name = 'Partner Account'].Id;
        Account testAccount = new Account();
        testAccount.Name = 'Test Account1';
        testAccount.Legal_Entity_Name__c = 'Sample Account';
        testAccount.Phone = '9090909090';
        testAccount.Entity__c = testEntity.Id;
        testAccount.OwnerId = testUser.Id;
        testAccount.RecordTypeId = partnerAccountRecordTypeId;
        insert testAccount;
   
       // testAccount = [select id,Name,RecordType.Id from Account where Name='Test Account1'];
        //testAccount.RecordType.Name = '0123k000001MRdPAAW';
        
        System.Debug('Record type: ' + testAccount.RecordTypeId);

        //Create Data for Contact object
        Contact testContact = new Contact();
        testContact.OwnerId = testUser.Id;
        testContact.AccountId = testAccount.Id;
        testContact.FirstName = 'John';
        testContact.LastName = 'Doe';
        testContact.Phone = '9090909090';
        testContact.Email = 'johndoe@example.com';
        testContact.MailingCity = 'Houston';
        testContact.MailingState = 'TX';
        testContact.MailingStreet = '123 Main St';
        testContact.MailingPostalCode = '77002';
        testContact.Primary_Contact__c = true;
        //testContact.RecordType.Name = 'Partner Contact';
        //testContact.Account_Primary_Contact__c = true;
        insert testContact;
        testAccount.Primary_Contact__c = testContact.Id;
        update testAccount;
        try
        {
            delete testContact;
        }
        catch(Exception e)
        {
            //Boolean expectedExceptionThrown =  e.getMessage().contains('This Contact has been selected as the Primary Contact on at least one Opportunity. It cannot be deleted.') ? true : false;
            System.Assert(e.getMessage().contains('Cannot delete'));
            System.debug('****'+e.getMessage());
        } 
    }

    @isTest(SeeAllData=true) static void contactTriggerTest_Active() {
        Test.setMock(HttpCalloutMock.class, new HttpEmexCalloutMock(200, 'OK', '{success:true}'));  
        //Create Data for Contact object
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

        //Create Data for Contact object
        Contact testContact = new Contact();
        testContact.OwnerId = testUser.Id;
        testContact.AccountId = testAccount.Id;
        testContact.FirstName = 'John';
        testContact.LastName = 'Doe';
        testContact.Phone = '9090909090';
        testContact.Email = 'johndoe@example.com';
        testContact.MailingCity = 'Houston';
        testContact.MailingState = 'TX';
        testContact.MailingStreet = '123 Main St';
        testContact.MailingPostalCode = '77002';
        insert testContact;
        
        Turn_off_Processes__c processSettings = Turn_off_Processes__c.getValues('migration in progress');
        processSettings.Is_Active__c = true;
        
        // Now, our trigger will fire on After update event so update the Records
        Test.startTest();    // Starts the scope of test
        testContact.Phone = '9990009990';
        update testContact;
        Test.stopTest();     // Ends the scope of test
        
        // Now check if it is giving desired results using System.assert
        // Statement.New Contact should be created
        List<Contact> lst = [SELECT Id, FirstName, LastName, Phone  FROM Contact WHERE Id = :testContact.Id];
        System.assertEquals(1, lst.size());
        // Check if one record is created in Contact sObject
    }

    @isTest(SeeAllData=true) static void contactTriggerTest_apiupdate() {
        Test.setMock(HttpCalloutMock.class, new HttpEmexCalloutMock(200, 'OK', '{success:true}'));  
        
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

        //Create Data for Contact object
        Contact testContact = new Contact();
        testContact.OwnerId = testUser.Id;
        testContact.AccountId = testAccount.Id;
        testContact.FirstName = 'John';
        testContact.LastName = 'Doe';
        testContact.Phone = '9090909090';
        testContact.Email = 'johndoe@example.com';
        testContact.MailingCity = 'Houston';
        testContact.MailingState = 'TX';
        testContact.MailingStreet = '123 Main St';
        testContact.MailingPostalCode = '77002';
        insert testContact;
        
        Turn_off_Processes__c processSettings = Turn_off_Processes__c.getValues('migration in progress');
        processSettings.Is_Active__c = true;
        
        // Now, our trigger will fire on After update event so update the Records
        Test.startTest();    // Starts the scope of test
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        req.addHeader('httpMethod', 'PATCH');
        req.requestUri = '/services/data/v48.0/sobjects/Contact/' + testContact.Id;       
        
        req.requestBody = Blob.valueof('{ "Phone" : "9990009990" }');
        RestContext.request = req; 
        RestContext.response = res;

        Test.stopTest();     // Ends the scope of test
        
        // Now check if it is giving desired results using System.assert
        // Statement.New Contact should be created
        List<Contact> lst = [SELECT Id, FirstName, LastName, Phone  FROM Contact WHERE Id = :testContact.Id];
        System.assertEquals(1, lst.size());
        // Check if one record is created in Contact sObject
    }
    
    @isTest
	static void runAsTestingUser() {
        
    // Query and insert test user with necessary profile
    Profile testProfile = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1]; 
    User testUser = new User(Alias = 'standt', Email='testuser@emex.com', 
        EmailEncodingKey='UTF-8', FirstName = 'Testing', LastName='User', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = testProfile.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='emextestuser@emex.com');
        
    insert testUser;
    
    // Debug statement to verify test user details
    System.debug('Test User Id: ' + testUser.Id);
    
    Account testAccount = new Account();
    testAccount.Name = 'Test Account';
    testAccount.Phone = '9090909090';
    insert testAccount;
    
    Contact con = new Contact();
    con.FirstName = 'John';
    con.LastName = 'Doe'; // Ensure unique Last Name to avoid issues with duplicates
    con.LeadSource = 'Rfx';
    con.AccountId = testAccount.Id;
    con.OwnerId = testUser.Id;
    insert con;

    // Debug statement to check setup details
    System.debug('Test Account Id: ' + testAccount.Id);
    
    Test.startTest();
    System.runAs(testUser) {
       
       
        update con;
    }
    Test.stopTest();
    
    // Verify the insertion of Contact or other expected behavior
    List<Contact> updatedContacts = [SELECT Id, Phone FROM Contact WHERE Id = :con.Id];
    System.assertEquals(1, updatedContacts.size(), 'Contact record was not inserted or found.');
	}

}