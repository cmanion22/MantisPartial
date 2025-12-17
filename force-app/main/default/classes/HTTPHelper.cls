public class HTTPHelper
{
    private final String url;
    private final String method;
    private final String body;
    
    public HTTPHelper(String url, String method, String body)
    {
        this.url= url;
        this.method= method;
        this.body= body;
    }

    public HttpResponse executeHTTP()
    {
        HttpRequest request = new HttpRequest();

        // Duplicated auth code from HttpRetryAsync
        Back_Office_Integration_Settings__c integrationSettings;
        if (Utils.isSandbox) {
            integrationSettings = Back_Office_Integration_Settings__c.getValues('Staging');
        } else {
            integrationSettings = Back_Office_Integration_Settings__c.getValues('Production');
        }

        if (integrationSettings.Endpoint_Requires_Authentication__c) {
            Blob headerValue = Blob.valueOf(integrationSettings.Endpoint_Username__c + ':' + integrationSettings.Endpoint_Password__c);
            String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
            request.setHeader('Authorization', authorizationHeader);
        }
        
        request.setMethod(method);      
        request.setHeader('Content-Type', 'application/json;charset=UTF-8');
        request.setEndpoint(url);
        request.setBody(body);
        
        System.debug('HttpHelper->executeHTTP->Sending Request --> ' + body);
        
        Http http = new Http();
       
        HttpResponse response= http.send(request);
        
        if (response.getStatusCode() != 200) {
            DataLogService.logError(
                'HTTPHelper Apex Class',
                'Callout returned an HTTP ' + response.getStatusCode() + ' response.\n\n Request body:\n ' + body + '\n\n Response body:\n' + response.getBody()
            );
            System.debug('The status code returned was not expected: ' +
                            response.getStatusCode() + ' ' + response.getStatus());
            System.debug('HttpHelper->executeHTTP->Response Received <-- ' + response.getBody());               
        } else {
            DataLogService.logInfo(
                'HTTPHelper Apex Class',
                'Callout returned an HTTP ' + response.getStatusCode() + ' response.\n\n Request body:\n ' + body + '\n\n Response body:\n' + response.getBody()
            );
            System.debug('HTTPHelper->executeHTTP->response->Status-->' + response.getStatusCode());
            System.debug('HttpHelper->executeHTTP->Response Received <-- ' + response.getBody());
        }
        
        return response;
        
    }
}