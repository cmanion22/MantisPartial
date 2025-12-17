public with sharing class HttpRetryAsync extends Retry { 
    private final String url;
    private final String method;
    private final String body;
    private final string event;
    private final ID id;
    public HttpCalloutMock mock = null;

    public HttpRetryAsync(String url, String method, String body, String event)
    {
        this.url = url;
        this.method = method;
        this.body = body;
        this.event = event;
    }

    public HttpRetryAsync(String url, String method, String body, String event, ID id)
    {
        this.url = url;
        this.method = method;
        this.body = body; 
        this.event = event;
        this.id = id;
    }

    public override JobResult startJob()
    {
        HttpRequest request = new HttpRequest();

        Back_Office_Integration_Settings__c integrationSettings;
        if (Utils.isSandbox) {
            integrationSettings = Back_Office_Integration_Settings__c.getValues('Staging');
        } else {
            integrationSettings = Back_Office_Integration_Settings__c.getValues('Production');
        }

        if (integrationSettings != null && integrationSettings.Endpoint_Requires_Authentication__c) {
            Blob headerValue = Blob.valueOf(integrationSettings.Endpoint_Username__c + ':' + integrationSettings.Endpoint_Password__c);
            String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
            request.setHeader('Authorization', authorizationHeader);
        }

        request.setMethod(method);
        request.setHeader('Content-Type', 'application/json;charset=UTF-8');
        request.setBody(body);
        request.setEndpoint(url);
        System.debug('HttpRetryAsync-->startJob-->Sending Request --> ' + body);
        
        HttpResponse response = null;
        Http http = new Http();
        response = http.send(request);

        if (response.getStatusCode() != 200) {
            DataLogService.logError(
                'HttpRetryAsync Apex Class',
                'Callout returned an HTTP ' + response.getStatusCode() + ' response.\n\n Request body:\n ' + body + '\n\n Response body:\n' + response.getBody()
            );
            System.debug('HttpHelperAsync->execute->body->' + 'The status code returned was not expected: ' + response.getStatusCode() + ' ' + response.getStatus());
        } else {
            DataLogService.logInfo(
                'HttpRetryAsync Apex Class',
                'Callout returned an HTTP ' + response.getStatusCode() + ' response.\n\n Request body:\n ' + body + '\n\n Response body:\n' + response.getBody()
            );
            System.debug('HttpHelperAsync->execute->Response Received <-- ' + response.getBody());
        }
        
        System.debug('Response status code:' + response.getStatusCode());
        System.debug('Response body:' + response.getBody());
        
        Retry.Status status = Helper.httpRetryScenario(response.getStatusCode());
        System.debug('HttpRetryAsync-->startJob-->retryStatus-->'+ status);
        
        return new JobResult(status, response.getBody(), event, response.getStatusCode());
    }
}