@isTest
private class AccountStatusBatchTest {
    @isTest
    static void shouldUpdateEnergyAccountStatusToProspect() {
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');

        Account account = new Account();
        account.Name = 'Test Account';
        account.Mantis_Division__c = 'Energy';
        account.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Client_Account').getRecordTypeId();
        insert account;

        Test.startTest();
        Database.executeBatch(new AccountStatusBatch(), 10);
        Test.stopTest();

        account = [SELECT Id, Account_Status__c FROM Account WHERE Id = :account.Id];

        Assert.areEqual('Prospect', account.Account_Status__c);
    }

    @isTest
    static void shouldUpdateEnergyAccountStatusToClient() {
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');

        Account account = new Account();
        account.Name = 'Test Account';
        account.Mantis_Division__c = 'Energy';
        account.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Client_Account').getRecordTypeId();
        insert account;

        account = [SELECT Id, Account_Status__c FROM Account WHERE Id = :account.Id];

        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opp';
        opp.CloseDate = Date.today().addMonths(-1);
        opp.StageName = '5 - Closed Won';
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Energy').getRecordTypeId();
        opp.AccountId = account.Id;
        insert opp;

        Test.startTest();
        Database.executeBatch(new AccountStatusBatch(), 10);
        Test.stopTest();

        account = [SELECT Id, Account_Status__c FROM Account WHERE Id = :account.Id];

        Assert.areEqual('Client', account.Account_Status__c);
    }

    @isTest
    static void shouldUpdateEnergyAccountStatusToFormerClient() {
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');

        Account account = new Account();
        account.Name = 'Test Account';
        account.Mantis_Division__c = 'Energy';
        account.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Client_Account').getRecordTypeId();
        insert account;

        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opp';
        opp.CloseDate = Date.today().addMonths(-24);
        opp.Contract_End_Date__c = Date.today().addMonths(-24);
        opp.StageName = '5 - Closed Won';
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Energy').getRecordTypeId();
        opp.AccountId = account.Id;
        insert opp;

        Test.startTest();
        Database.executeBatch(new AccountStatusBatch(), 10);
        Test.stopTest();

        account = [SELECT Id, Account_Status__c FROM Account WHERE Id = :account.Id];

        Assert.areEqual('Former Client', account.Account_Status__c);
    }

    @isTest
    static void shouldUpdateFMSAccountStatusToClient() {
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');

        Account account = new Account();
        account.Name = 'Test Account';
        account.Mantis_Division__c = 'FMS';
        account.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Client_Account').getRecordTypeId();
        insert account;

        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opp';
        opp.CloseDate = Date.today().addMonths(-12);
        opp.StageName = '5 - Closed Won';
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Services').getRecordTypeId();
        opp.AccountId = account.Id;
        insert opp;

        Test.startTest();
        Database.executeBatch(new AccountStatusBatch(), 10);
        Test.stopTest();

        account = [SELECT Id, Account_Status__c FROM Account WHERE Id = :account.Id];

        Assert.areEqual('Client', account.Account_Status__c);
    }

    @isTest
    static void shouldUpdateFMSAccountStatusToFormerClient() {
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');

        Account account = new Account();
        account.Name = 'Test Account';
        account.Mantis_Division__c = 'FMS';
        account.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Client_Account').getRecordTypeId();
        insert account;

        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opp';
        opp.CloseDate = Date.today().addMonths(-36);
        opp.Contract_End_Date__c = Date.today().addMonths(-24);
        opp.StageName = '5 - Closed Won';
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Services').getRecordTypeId();
        opp.AccountId = account.Id;
        insert opp;

        Test.startTest();
        Database.executeBatch(new AccountStatusBatch(), 10);
        Test.stopTest();

        account = [SELECT Id, Account_Status__c FROM Account WHERE Id = :account.Id];

        Assert.areEqual('Former Client', account.Account_Status__c);
    }
}