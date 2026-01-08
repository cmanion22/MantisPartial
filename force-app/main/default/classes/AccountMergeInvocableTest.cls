@IsTest
public class AccountMergeInvocableTest {
    
    private static void createTestData() {
        System.debug('createTestData: Starting test data creation');

        List<Account> duplicateAccounts = new List<Account>{
            new Account(Name = 'Global1', CurrencyIsoCode = 'USD'),
            new Account(Name = 'Global2', CurrencyIsoCode = 'USD')
        };

        insert duplicateAccounts;

        System.debug('createTestData: Inserted Accounts -> ' + duplicateAccounts);
    }
    
    @IsTest
    public static void callMergeInvocableWithDuplicates() {
        System.debug('callMergeInvocableWithDuplicates: Test started');

        createTestData();

        // Query Master Account
        Account masterAccount = [
            SELECT Id, Name
            FROM Account
            WHERE Name = 'Global1'
            LIMIT 1
        ];
        System.debug('Master Account Id: ' + masterAccount.Id);

        // Query Duplicate Account
        Account duplicateAccount = [
            SELECT Id, Name
            FROM Account
            WHERE Name = 'Global2'
            LIMIT 1
        ];
        System.debug('Duplicate Account Id: ' + duplicateAccount.Id);

        // Build Invocable Request
        AccountMergeInvocable.MergeRequest request =
            new AccountMergeInvocable.MergeRequest();

        request.masterAccountId = masterAccount.Id;
        request.duplicateAccountIds = new List<Id>{
            duplicateAccount.Id
        };

        List<AccountMergeInvocable.MergeRequest> requests =
            new List<AccountMergeInvocable.MergeRequest>{ request };

        System.debug('Prepared MergeRequest: ' + requests);

        Test.startTest();
            AccountMergeInvocable.mergeAccounts(requests);
        Test.stopTest();

        System.debug('Merge operation completed');

        // Assertions: Duplicate account should be gone
        Integer duplicateCount = [
            SELECT COUNT()
            FROM Account
            WHERE Id = :duplicateAccount.Id
        ];
        System.debug('Duplicate account count after merge: ' + duplicateCount);

        System.assertEquals(
            0,
            duplicateCount,
            'Duplicate account should be merged and deleted'
        );

        // Assertions: Master account should still exist
        Integer masterCount = [
            SELECT COUNT()
            FROM Account
            WHERE Id = :masterAccount.Id
        ];
        System.debug('Master account count after merge: ' + masterCount);

        System.assertEquals(
            1,
            masterCount,
            'Master account should still exist after merge'
        );

        System.debug('callMergeInvocable: Test completed successfully');
    }
    
    @isTest
    public static void callMergeInvocableWithOneAccount() {
        System.debug('callMergeInvocableWithOneAccount: Test started');
        
        createTestData();

        // Query Master Account
        Account masterAccount = [
            SELECT Id, Name
            FROM Account
            WHERE Name = 'Global1'
            LIMIT 1
        ];
        
        System.debug('Master Account Id: ' + masterAccount.Id);
        
        // Build Invocable Request
        AccountMergeInvocable.MergeRequest request =
            new AccountMergeInvocable.MergeRequest();

        request.masterAccountId = masterAccount.Id;
        request.duplicateAccountIds = new List<Id>{
            
        };

        List<AccountMergeInvocable.MergeRequest> requests =
            new List<AccountMergeInvocable.MergeRequest>{ request };

        System.debug('Prepared MergeRequest: ' + requests);

        Test.startTest();
            AccountMergeInvocable.mergeAccounts(requests);
        Test.stopTest();

        System.debug('Merge operation completed');
        
    }
    
    @IsTest
    static void callMergeInvocable_MasterNotFound() {
        // Create a real duplicate account
        Account dup = new Account(Name = 'DupOnly', CurrencyIsoCode = 'USD');
        insert dup;
    
        // Fake master Id
        Id fakeMasterId = '001000000000000AAA';
    
        AccountMergeInvocable.MergeRequest request =
            new AccountMergeInvocable.MergeRequest();
        request.masterAccountId = fakeMasterId;
        request.duplicateAccountIds = new List<Id>{ dup.Id };
    
        Test.startTest();
            AccountMergeInvocable.mergeAccounts(
                new List<AccountMergeInvocable.MergeRequest>{ request }
            );
        Test.stopTest();
    
        // Assert Data_Log__c was created
        System.assertEquals(
            1,
            [SELECT COUNT() FROM Data_Log__c WHERE Related_Record_Id__c = :fakeMasterId]
        );
    }
    
    @IsTest
    static void callMergeInvocable_SameMasterAndDuplicate() {
        // Create one account
        Account acc = new Account(Name = 'SelfMergeTest', CurrencyIsoCode = 'USD');
        insert acc;
    
        // Build invocable request with same Id for master and duplicate
        AccountMergeInvocable.MergeRequest request = new AccountMergeInvocable.MergeRequest();
        request.masterAccountId = acc.Id;
        request.duplicateAccountIds = new List<Id>{ acc.Id };
    
        List<AccountMergeInvocable.MergeRequest> requests = new List<AccountMergeInvocable.MergeRequest>{ request };
    
        Test.startTest();
            AccountMergeInvocable.mergeAccounts(requests);
        Test.stopTest();
    
        // Assert that Data_Log__c captured the merge error
        Integer logCount = [SELECT COUNT() FROM Data_Log__c WHERE Related_Record_Id__c = :acc.Id];
        System.assert(logCount > 0, 'Data_Log__c should contain merge error from self-merge attempt');
    }


}