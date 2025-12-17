public with sharing class AccountCalloutClass { 
    @InvocableMethod(label='create_account')
    public static List<string> createAccount(List<ID> accountIdList) 
    {
        System.debug('AccountCalloutClass-->createAccount-->accountIdList-->' + accountIdList);
        ID accountId = accountIdList[0];
        Account account = [SELECT Id, RecordType.DeveloperName FROM Account WHERE Id = :accountId];
        Boolean isPartnerAccount = account.RecordType.DeveloperName == 'Partner_Account';
        String pageMessage = '';
        list<string> tempList = new List<string>();
        tempList.add('true');
        
        String body = '';
        if (isPartnerAccount) {
            body = '{"event": "create_partner", "data": { "account": { "Id": "' + accountId + '" } } }';
        } else {
            String apiToken = [SELECT API_Token__c FROM  User WHERE Id = :UserInfo.getUserId()].API_Token__c;
            body = '{"api_token": "' + apiToken + '", "event": "create_client", "data": { "account": { "Id": "' + accountId + '" } } }';
        }
        
        System.debug('AccountCalloutClass->createAccount->Body-->' + body);        
        
        string url  = ESBController.getESBUrl();
        HTTPHelper httpHelper = new HTTPHelper(url, 'POST', body);
        if(Test.isRunningTest()) 
        {
            return null;
        }
        HttpResponse response = httpHelper.executeHTTP();        
        System.debug('AccountCalloutClass->createAccount->response-->' + response);
         
        if (response.getStatusCode() == 200)
        {
            DataLogService.logInfo(
                'AccountCalloutClass Invocable Apex Action',
                'Callout returned an HTTP ' + response.getStatusCode() + ' response.\n\n Request body:\n ' + body + '\n\n Response body:\n' + response.getBody(),
                account.Id
            );
            System.debug('AccountCalloutClass->calling Success');
            return tempList;
        }
        else
        {
            DataLogService.logError(
                'AccountCalloutClass Invocable Apex Action',
                'Callout returned an HTTP ' + response.getStatusCode() + ' response.\n\n Request body:\n ' + body + '\n\n Response body:\n' + response.getBody(),
                account.Id
            );
            System.debug('AccountCalloutClass->calling Error');
            return null;
        }
    }

    /**
     * @return the JSON body of the callout sent to the Back Office
     */
    public static String updateAccount(Id accountId, Id syncUserId) {
        return AccountHelper.postUpdateAccountJson(accountId, syncUserId);
    }
}