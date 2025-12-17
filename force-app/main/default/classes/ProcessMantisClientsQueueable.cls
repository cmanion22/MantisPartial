public with sharing class ProcessMantisClientsQueueable implements Queueable, Database.AllowsCallouts {
    private Map<String, MantisCompany> companies;

    // Constructor to initialize the map of MantisCompany
    public ProcessMantisClientsQueueable(Map<String, MantisCompany> mc) {
        this.companies = mc;  
    }

    // Queueable job execution method
    public void execute(QueueableContext context) {
        // Query Accounts that match the company_uuid__c values in the map
        List<Account> accounts = [
            SELECT id, name, company_uuid__c, Entity__c, Work_Orders_Enabled__c
            FROM Account
            WHERE company_uuid__c IN :companies.keySet()
        ];
        System.debug('Available accounts in DB: ' + accounts.size());

        List<Account> updatedAccounts = new List<Account>();

        // Iterate through the accounts and update if needed
        if (accounts.size() > 0) {
            for (Account a : accounts) {
                MantisCompany m = companies.get(a.company_uuid__c);
                if (m != null && (
                    a.Name != m.name ||
                    a.Work_Orders_Enabled__c != m.work_orders_enabled
                )) {
                    a.Name = m.name;
                    a.Work_Orders_Enabled__c = m.work_orders_enabled;
                    System.debug('Updated account: ' + a);
                    updatedAccounts.add(a);
                    companies.remove(m.id); 
                }
            }
        } else {
            DataLogService.logInfo('ProcessMantisClientsQueueable Apex Class', 'No Accounts returned from query');
        }

        // Query accounts where company_uuid__c is null and Work_Orders_Enabled__c is true
        List<Account> accsToUpdate = [
            SELECT Id, Work_Orders_Enabled__c, company_uuid__c
            FROM Account
            WHERE company_uuid__c = null
            AND Work_Orders_Enabled__c = TRUE
        ];

        if (accsToUpdate.size() > 0) {
            for (Account acc : accsToUpdate) {
                acc.Work_Orders_Enabled__c = false;
                updatedAccounts.add(acc);
            }
        }

        // Perform the update operation if there are accounts to update
        if (!updatedAccounts.isEmpty()) {
            try {
                Database.update(updatedAccounts, false); // False for partial success if needed
                System.debug('Updated Accounts: ' + updatedAccounts.size());
            } catch (DmlException e) {
                System.debug('Error updating accounts: ' + e.getMessage());
                DataLogService.logError('ProcessMantisClientsQueueable Apex Class', 'Failed to insert/update Account records: ' + e.getMessage());
            }
            
        }
    }
}