@isTest
public class UnanetUserIntegrationMock implements HttpCalloutMock {
    public HttpResponse respond(HttpRequest req) {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(200);

        String endpoint = req.getEndpoint();
        String method = req.getMethod();
        System.debug('Mocking endpoint: ' + endpoint + ' | Method: ' + method);

        if (endpoint.contains('/platform/rest/login') && method == 'POST') {
            res.setBody('{"token": "testTokenExample", "username": "CMANION"}');
        }
        else if (endpoint.contains('/platform/rest/people/list')) {
            res.setBody(JSON.serialize(new Map<String, Object>{
                'items' => new List<Object>{
                    new Map<String, Object>{
                        'key' => 1,
                        'username' => 'active.user',
                        'firstName' => 'Test',
                        'lastName' => 'User',
                        'active' => true,
                        'activationPending' => false
                    },
                    new Map<String, Object>{
                        'key' => 2,
                        'username' => 'inactive.user',
                        'firstName' => 'Old',
                        'lastName' => 'User',
                        'active' => false,
                        'activationPending' => false
                    }
                },
                'page' => 0,
                'pageSize' => 100,
                'pageCount' => 1,
                'resultCount' => 2
            }));
        }
        else if (endpoint.contains('/platform/rest/people/1')) {
            res.setBody(JSON.serialize(new Map<String, Object>{
                'key' => 1,
                'username' => 'active.user',
                'firstName' => 'Test',
                'lastName' => 'User',
                'active' => true,
                'employeeType' => new Map<String, Object>{ 'name' => 'Full-Time' },
                'organization' => new Map<String, Object>{ 'name' => 'Bluefin' },
                'personCode' => 'ABC123'
            }));
        }
        else if (endpoint.contains('/platform/rest/people/2')) {
            res.setBody(JSON.serialize(new Map<String, Object>{
                'key' => 2,
                'username' => 'inactive.user',
                'firstName' => 'Old',
                'lastName' => 'User',
                'active' => false,
                'employeeType' => new Map<String, Object>{ 'name' => 'Contractor' },
                'organization' => new Map<String, Object>{ 'name' => 'Bluefin' },
                'personCode' => 'XYZ789'
            }));
        }
        else {
            res.setBody('{}'); // fallback for unknown endpoints
        }

        return res;
    }
}