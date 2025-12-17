@isTest
global class HttpEmexCalloutMock implements HttpCalloutMock{
    public Integer statusCode {get; set;}
    public String status {get; set;}
    public String body {get; set;}
    public HttpRequest request {get; set;}

    public HttpEmexCalloutMock() {}

    public HttpEmexCalloutMock (Integer statusCode, String status, String body) {
        this.statusCode = statusCode;
        this.status = status;
        this.body = body;
    }

    global HTTPResponse respond(HTTPRequest req) {
        this.request = req;
        HttpResponse res = new HttpResponse();
        res.setBody(this.body);
        res.setStatusCode(this.statusCode);
        res.setStatus(this.status);
        return res;
    }

    /*global HttpResponse respond(HTTPRequest req) {
        System.debug('HttpEmexCalloutMock -->respond->running mock http call');
        HttpResponse res = new HttpResponse();
        res.setStatus('OK');
        res.setStatusCode(200);
        res.setBody('{success:true}');
        return res;
    }*/
}