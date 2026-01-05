public with sharing class AccountMergeInvocable {

    public class MergeRequest {
        @InvocableVariable(required=true)
        public Id masterAccountId;

        @InvocableVariable(required=true)
        public List<Id> duplicateAccountIds;
    }

    @InvocableMethod(
        label='Merge Accounts'
        description='Merges duplicate Accounts into a master Account'
    )
    public static void mergeAccounts(List<MergeRequest> requests) {

        System.debug('AccountMergeInvocable.mergeAccounts invoked.');
        System.debug('Number of merge requests received: ' + requests.size());

        for (MergeRequest request : requests) {
            System.debug('----------------------------------------');
            System.debug('Processing merge request.');
            System.debug('Master Account Id: ' + request.masterAccountId);
            System.debug('Duplicate Account Ids: ' + request.duplicateAccountIds);

            try {
                // Query master account
                System.debug('Querying Master Account...');
                List<Account> masterList = [
                    SELECT Id
                    FROM Account
                    WHERE Id = :request.masterAccountId
                    LIMIT 1
                ];

                if (masterList.isEmpty()) {
                    System.debug('Master Account NOT found.');
                    logError(
                        'Account Merge Error',
                        'Master Account not found with Id: ' + request.masterAccountId,
                        request.masterAccountId
                    );
                    continue;
                }

                Account masterAccount = masterList[0];
                System.debug('Master Account found: ' + masterAccount.Id);

                // Query duplicate accounts
                System.debug('Querying duplicate Accounts...');
                List<Account> duplicateAccounts = [
                    SELECT Id
                    FROM Account
                    WHERE Id IN :request.duplicateAccountIds
                ];

                if (duplicateAccounts.isEmpty()) {
                    System.debug('No duplicate Accounts found to merge.');
                    logError(
                        'Account Merge Error',
                        'No duplicate Accounts found to merge.',
                        request.masterAccountId
                    );
                    continue;
                }

                System.debug('Number of duplicate Accounts found: ' + duplicateAccounts.size());
                System.debug('Duplicate Account Ids: ' + duplicateAccounts);

                // Perform merge
                System.debug('Performing Account merge...');
                Database.MergeResult[] results =
                    Database.merge(masterAccount, duplicateAccounts, false);

                System.debug('Merge operation completed. Number of results: ' + results.size());

                for (Database.MergeResult result : results) {
                    if (result.isSuccess()) {
                        System.debug('Successfully merged into Master Account Id: ' + result.getId());
                    } else {
                        System.debug('Merge failed for Master Account Id: ' + result.getId());
                        for (Database.Error error : result.getErrors()) {
                            System.debug('Merge error: ' + error.getMessage());
                            logError(
                                'Account Merge Error',
                                error.getMessage(),
                                request.masterAccountId
                            );
                        }
                    }
                }

            } catch (Exception e) {
                System.debug('Unhandled exception during Account merge.');
                System.debug('Exception message: ' + e.getMessage());
                System.debug('Stack trace: ' + e.getStackTraceString());

                logError(
                    'Account Merge Exception',
                    e.getMessage(),
                    request.masterAccountId
                );
            }
        }

        System.debug('AccountMergeInvocable.mergeAccounts execution complete.');
    }

    private static void logError(String name, String description, Id relatedId) {
        try {
            System.debug('Logging error to Data_Log__c.');
            System.debug('Description: ' + description);
            System.debug('Related Record Id: ' + relatedId);

            insert new Data_Log__c(
                Description__c       = description,
                Related_Record_Id__c = relatedId,
                Log_Origin__c        = 'Account Merge Invocable'
            );

            System.debug('Data_Log__c record inserted successfully.');
        } catch (Exception e) {
            System.debug('Failed to insert Data_Log__c.');
            System.debug('Exception message: ' + e.getMessage());
        }
    }
}
