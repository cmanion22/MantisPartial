public class HttpHelperAsync implements System.Queueable, Database.AllowsCallouts {
    private final String url;
    private final String method;
    private final String body;
    
    public HttpHelperAsync(String url, String method, String body)
    {
        this.url = url;
        this.method = method;
        this.body = body;
    }

    public void execute(System.QueueableContext ctx)
    {
        HttpRequest request = new HttpRequest();
        request.setMethod(method);
        request.setHeader('Content-Type', 'application/json;charset=UTF-8');
        request.setBody(body);
        request.setEndpoint(url);
        System.debug('HttpHelperAsync->execute->Sending Request --> ' + body);        
        Http http = new Http();
        HttpResponse response = http.send(request);
        if (response.getStatusCode() != 200) {
            DataLogService.logError(
                'HttpHelperAsync Apex Class',
                'Callout returned an HTTP ' + response.getStatusCode() + ' response.\n\n Request body:\n ' + body + '\n\n Response body:\n' + response.getBody()
            );
            System.debug('HttpHelperAsync->execute->body->' + 'The status code returned was not expected: ' + response.getStatusCode() + ' ' + response.getStatus());
        } else {
            DataLogService.logInfo(
                'HttpHelperAsync Apex Class',
                'Callout returned an HTTP ' + response.getStatusCode() + ' response.\n\n Request body:\n ' + body + '\n\n Response body:\n' + response.getBody()
            );
            System.debug('HttpHelperAsync->execute->Response Received <-- ' + response.getBody());
        }
    }
}