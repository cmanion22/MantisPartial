public class AccountHelper {
    public static Account getAccount(ID accountId) {    
        System.debug('AccountHelper-->getAccount-->fetching account -->' + accountId);
        
        String qry = Helper.generateSelectQuery('Account') + ' WHERE Id =:accountId';      
        System.debug('AccountHelper-->getAccount->Query-->' + qry);
        Account account = database.query(qry); 
        System.debug('AccountHelper-->getAccount-->fetched account -->' + accountId);       
        return account;
    }
    
    public static string postUpdateAccountJson(ID accountId) {        
        System.debug('AccountHelper-->postUpdateAccountJson-->accountId --> ' + accountId);                  
        String accountJson = Helper.getFormattedJson(getAccount(accountId));
        
        String body = 
                '{"event": "update_account"' +
                ', "data": {' +                
                    '"account": ' + accountJson +                
                    '}' + 
                '}';
        
        System.debug('AccountHelper-->postUpdateAccountJson-->Body -->' + body);              
        
        System.enqueueJob(new HttpRetryAsync(ESBController.getESBUrl(), 'POST', body, 'UpdateAccount', accountId));
        return body;
    }

    public static string postUpdateAccountJson(Id accountId, Id syncUserId) {
        String body = 
                '{"event": "update_account"' +
                ', "data": {' +
                    '"account": { "Id": "' + accountId + '" }' +
                    '}' +
                '}';

        System.debug('AccountHelper-->postUpdateAccountJson-->Body -->' + body);

        System.enqueueJob(new HttpRetryAsync(ESBController.getESBUrl(syncUserId), 'POST', body, 'UpdateAccount', accountId));
        return body;
    }

    public static Account upsertAccount(Map<String, Object> compositeMapObjects) {        
        Map<String, Object> accountMap = (Map<String, Object>)compositeMapObjects.get('account');       
        System.debug('AccountHelper-->upsertAccount-->accountMap -->' + accountMap);
        Account thisAccount = new Account();        
       
        // Iterate through each parameter field and value
        for(String fieldName : accountMap.keySet()) {                        
            System.debug(fieldName + '-' + accountMap.get(fieldName));           
            
            // Set the field and value on the Opportunity sObject
            thisAccount.put(fieldName, accountMap.get(fieldName));            
        }
        System.debug('AccountHelper-->upsertAccount-->thisAccount -->' + thisAccount);
        upsert thisAccount;
        
        System.debug('AccountHelper-->upsertAccount-->thisAccount.Id -->' + thisAccount.Id);
        return thisAccount;
    }

    public static Boolean isPartnerAccount(Id accountId) {
        return isPartnerAccount(new Set<Id>{ accountId }).get(accountId);
    }

    public static Map<Id, Boolean> isPartnerAccount(Set<Id> accountIds) {
        Map<Id, Boolean> partnerAccountsIndexedById = new Map<Id, Boolean>();
        List<Account> accounts = [SELECT Id, RecordTypeId, RecordType.Name FROM Account WHERE Id IN :accountIds];

        for (Account account : accounts) {
            if (account.RecordType.Name == 'Partner Account') {
                partnerAccountsIndexedById.put(account.Id, true);
            } else {
                partnerAccountsIndexedById.put(account.Id, false);
            }
        }

        return partnerAccountsIndexedById;
    } 
}