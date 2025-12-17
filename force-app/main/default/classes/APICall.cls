public class APICall {
    @future(callout=true)
    public static void makeCallout(String wn, String status, String property, Decimal company) {
        system.debug('Inside callout');
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:IgniteBasic/workorders/'+ wn );
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json;charset=UTF-8');
        // Set the body as a JSON object
        String body = '{"status": "' + status + '", "companyid":"' + company + '", "propertyid":"' + property + '"}';
        system.debug(body);
        request.setBody(body);
        HttpResponse response = http.send(request);
        // Parse the JSON response
        if (response.getStatusCode() != 200) {
            DataLogService.logError(
                'APICall Apex Class',
                'Parameters: wn = \'' + wn + '\', status = \'' + status + '\', property = \'' + property + '\', company = \'' + company + '\'\n\nCallout returned an HTTP ' + response.getStatusCode() + ' response.\n\n Request body:\n ' + body + '\n\n Response body:\n' + response.getBody()
            );
            System.debug('The status code returned was not expected: ' +
                response.getStatusCode() + ' ' + response.getStatus());
        } else {
            DataLogService.logInfo(
                'APICall Apex Class',
                'Parameters: wn = \'' + wn + '\', status = \'' + status + '\', property = \'' + property + '\', company = \'' + company + '\'\n\nCallout returned an HTTP ' + response.getStatusCode() + ' response.\n\n Request body:\n ' + body + '\n\n Response body:\n' + response.getBody()
            );
            System.debug(response.getBody());
        }
    }

}