public without sharing class AccountMantisDivisionBatch implements Database.Batchable<SObject> {

    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator('SELECT Id, OwnerId FROM Account WHERE Mantis_Division__c = null');
    }

    public void execute(Database.BatchableContext context, List<SObject> scope) {
        List<Account> updatedAccounts = new List<Account>();
        List<Id> accountOwnerIds = new List<Id>();

        for (SObject s : scope) {
            Account acc = (Account) s;

            if (acc.OwnerId != null && String.valueOf(acc.OwnerId).startsWith('005')) { // If Owner is a User record
                accountOwnerIds.add(acc.OwnerId);
            }
        }

        Map<Id, User> userIndexedById = new Map<Id, User>([SELECT Id, Brand_Name__c FROM User WHERE Id IN :accountOwnerIds]);

        for (SObject s : scope) {
            Account acc = (Account) s;

            if (!userIndexedById.containsKey(acc.OwnerId)) continue;

            User accOwner = userIndexedById.get(acc.OwnerId);

            if (accOwner.Brand_Name__c == 'PEG' || accOwner.Brand_Name__c == 'EMEX') {
                acc.Mantis_Division__c = 'Energy';
                updatedAccounts.add(acc);
            } else if (accOwner.Brand_Name__c == 'Bluefin') {
                acc.Mantis_Division__c = 'FMS';
                updatedAccounts.add(acc);
            } else if (accOwner.Brand_Name__c == 'FES') {
                acc.Mantis_Division__c = 'Efficiency';
                updatedAccounts.add(acc);
            }
        }

        update updatedAccounts;
    }

    public void finish(Database.BatchableContext context) {
        System.debug('Done');
    }

}