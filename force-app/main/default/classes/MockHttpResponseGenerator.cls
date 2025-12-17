@isTest
public class MockHttpResponseGenerator implements HttpCalloutMock {
    // Static variable to hold the mock response body
    public static String mockResponseBody;

    // Mock the response for the HTTP callout
    public HTTPResponse respond(HTTPRequest req) {
        // Create a mock HTTP response
        HTTPResponse res = new HTTPResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(200); // HTTP OK status code

        // Use the static mock response body if it is set
        res.setBody(mockResponseBody != null ? mockResponseBody : '{"data":[],"pagination":{}}');

        return res;
    }
}