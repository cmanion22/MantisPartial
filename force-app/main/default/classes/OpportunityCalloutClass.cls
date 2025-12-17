public with sharing class OpportunityCalloutClass {
    @InvocableMethod(label='create_opportunity')
    public static void createOpportunity(List<ID> opportunityIdList) 
    {
          
        System.debug('OpportunityCalloutClass-->createOpportunity-->opportunityIdList-->' + opportunityIdList);
        ID opportunityId = opportunityIdList[0];
        String pageMessage = '';
                
        String opportunityJson =  Helper.getFormattedJson(OpportunityHelper.getOpportunity(opportunityId));
        System.debug('OpportunityCalloutClass-->createOpportunity-->opportunityJson -->' + opportunityJson);
       
        String accountJson = Helper.getFormattedJson(AccountHelper.getAccount(OpportunityHelper.getAccountId(opportunityId)));    
        System.debug('OpportunityCalloutClass-->createOpportunity-->accountJson -->' + accountJson);
        
        String contactJson = Helper.getFormattedJson(ContactHelper.getPrimaryContact(opportunityId));
        System.debug('OpportunityCalloutClass-->createOpportunity-->contactJson -->' + contactJson);
        
        String fileJson = FileHelper.createFileJson(opportunityId);
        System.debug('OpportunityCalloutClass-->createOpportunity-->fileJson -->' + fileJson);
                            
        String body = 
                    '{"event": "create_opportunity"' +
                    ', "data": {' +
                        ' "account": ' + accountJson +
                        ', "contact": ' + contactJson + 
                        ', "opportunity": ' + opportunityJson +
                        ', "files": ' + fileJson +
                      '}' + 
                    '}';
        
        System.debug('OpportunityCalloutClass->createOpportunity->Body-->' + body);        
        
        if(Test.isRunningTest()) 
        {
            return;
        }
        
        string url  = ESBController.getESBUrl();
        //System.debug('OpportunityCalloutClass->createOpportunity->URL created-->' + url);
        HTTPHelper httpHelper = new HTTPHelper(url, 'POST', body);
        HttpResponse response = httpHelper.executeHTTP();        
        System.debug('OpportunityCalloutClass->createOpportunity->response-->' + response);
        
        //this should done before http call but SF wouldn't allow and throw error saying System.CalloutException: You have uncommitted work pending. Please commit or rollback before calling out
        //Helper.LockRecord(opportunityId);
         
        if (response.getStatusCode() == 200)
        {
            System.debug('OpportunityCalloutClass->callling OpportunityHelper.setBackOfficeFlagSuccess');
            
            OpportunityHelper.setBackOfficeFlagSuccess(opportunityId); 
            
            SObject opp = Helper.getSObject(opportunityId);
            
            System.debug('OpportunityCalloutClass->invoking OpportunityRegistrationResultController');
            ApexPages.StandardController thisStandardController = new ApexPages.StandardController(opp);
            OpportunityRegistrationResultController o = new OpportunityRegistrationResultController(thisStandardController);   
            
            //Helper.UnlockRecord(opportunityId);

        }
        else
        {
            System.debug('OpportunityCalloutClass->callling OpportunityHelper.setBackOfficeFlagError');
            string errorMsg = response.getBody().substringBetween('"errors":["', '"]');
            
            OpportunityHelper.setBackOfficeFlagError(opportunityId, errorMsg, body);
            
            SObject opp= Helper.getSObject(opportunityId);
            System.debug('OpportunityCalloutClass->calling OpportunityRegistrationResultController');
            ApexPages.StandardController thisStandardController = new ApexPages.StandardController(opp);
            OpportunityRegistrationResultController o = new OpportunityRegistrationResultController(thisStandardController);  
            
            //Helper.UnlockRecord(opportunityId);
        }
    }

    /**
     * @return the JSON body of the callout sent to the Back Office
     */
    public static String updateOpportunity(Id opportunityId, Id syncUserId) {
        System.debug('OpportunityCalloutClass->updateOpportunity-->opportunityId-->' + opportunityId);
        return OpportunityHelper.postUpdateOpportunityJson(opportunityId, syncUserId);
    }
}