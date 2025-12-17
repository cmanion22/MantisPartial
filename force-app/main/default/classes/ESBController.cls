public class ESBController {

    public static String getESBUrl(Id userId) {
        Back_Office_Integration_Settings__c integrationSettings;
        if (Utils.isSandbox) {
            integrationSettings = Back_Office_Integration_Settings__c.getValues('Staging');
        } else {
            integrationSettings = Back_Office_Integration_Settings__c.getValues('Production');
        }
		
        
        String apiToken = '';
        // adding a null check for the userId passed to the method
        if(userId != null){
            User userRecord = [SELECT API_Token__c 
                               FROM User 
                               WHERE Id = :userId Limit 1];
            // adding a null check for the returned query and the API Token
            if(userRecord != null && userRecord.API_Token__c != null) {
                apiToken = userRecord.API_Token__c;
            }
        }

        String esbUrl = integrationSettings.Endpoint_URL__c + '/salesforce/esb' + '?api_token=' + apiToken;

        return esbUrl;
    }

    public static string getESBUrl() 
    {
        Configuration__c config = Configuration__c.getValues('ESBURL');        
        System.debug('ESBController -->getESBUrl-->ESBUrlconfig.ESBBaseURL__c-->' + config.ESBBaseURL__c);
    
        System.debug('ESBController -->getESBUrl-->UserInfo.getUserName-->' + UserInfo.getUserName());
        
        /*assigns API token as Mantis Back office if user is a System user, otherwise fetches API token of that user*/
        System.debug('ESBController-->getESBURL__>Userinfo.getOrgID-->'+ userInfo.getOrganizationId());
        System.debug('Index Of OrgID within Username-->'+UserInfo.getUserName().tolowercase().indexof(UserInfo.getOrganizationId().toLowerCase()));
        string currentUserApiToken = UserInfo.getUserName().tolowercase().indexof(UserInfo.getOrganizationId().toLowerCase())!= -1?
            [Select API_Token__c from User where name = 'Mantis Back Office'].API_Token__c:
            [Select API_Token__c from User where Id = :UserInfo.getUserId()].API_Token__c;

        string esbUrl = config.ESBBaseURL__c + '/salesforce/esb' +  '?api_token=' + currentUserApiToken;        
        System.debug('ESBController -->getESBUrl-->ESBUrl -->' + esbUrl);
        
        return esbUrl;
    }
    
    public static string getOpportunityESBUrl(ID opportunityId) 
    {
        Configuration__c config = Configuration__c.getValues('ESBURL');
        System.debug('ESBController -->getESBUrl-->ESBUrlconfig.ESBBaseURL__c-->' + config.ESBBaseURL__c);

        System.debug('ESBController -->getESBUrl-->UserInfo.getUserName-->' + UserInfo.getUserName());
        string currentUserApiToken = [Select API_Token__c from User where Id = :UserInfo.getUserId()].API_Token__c;
        
        string esbUrl = config.ESBBaseURL__c + '/salesforce/deals/' + opportunityId + '?api_token=' + currentUserApiToken;        
        System.debug('ESBController -->getESBUrl-->ESBUrl -->' + esbUrl);
        
        return esbUrl;

    }
    
    public static string getAccountESBUrl(ID accountId) 
    {
        Configuration__c config = Configuration__c.getValues('ESBURL');
        System.debug('ESBController -->getESBUrl-->ESBUrlconfig.ESBBaseURL__c-->' + config.ESBBaseURL__c);

        System.debug('ESBController -->getESBUrl-->UserInfo.getUserName-->' + UserInfo.getUserName());
        string currentUserApiToken = [Select API_Token__c from User where Id = :UserInfo.getUserId()].API_Token__c;
        
        string esbUrl = config.ESBBaseURL__c + '/salesforce/orgs/' + accountId + '?api_token=' + currentUserApiToken;        
        System.debug('ESBController -->getESBUrl-->ESBUrl -->' + esbUrl);
        
        return esbUrl;

    }
}