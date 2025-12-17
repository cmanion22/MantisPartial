public class UnanetContactHttpMock implements HttpCalloutMock {
    public HttpResponse respond(HttpRequest req) {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(200);
        String endpoint = req.getEndpoint();
        String method = req.getMethod();

        System.debug('Mocking endpoint: ' + endpoint + ' | Method: ' + method);

        // Specific checks FIRST
        if (endpoint.contains('/platform/rest/contacts/phone-types')) {
            res.setBody('{"items":[{"key":0,"name":"Mobile"}]}');
        }

        else if (endpoint.contains('/contacts/email-types')) {
            res.setBody('{"items":[{"key":0,"name":"Business"}]}');
        }

        else if (endpoint.contains('/contacts/address-types')) {
            res.setBody('{"items":[{"key":0,"name":"Mailing"}]}');
        }

        else if (endpoint.contains('/config/udf-metadata/ORG_CONTACT')) {
            res.setBody(JSON.serialize(new Map<String, Object>{
                'items' => new List<Object>{
                    new Map<String, Object>{
                        'index' => 1,
                        'metadata' => new Map<String, Object>{
                            'label' => 'SF Id',
                            'dataType' => 'STRING',
                            'visibility' => 'ENABLED',
                            'required' => false,
                            'active' => true
                        }
                    }
                }
            }));
        }

        // General checks LAST
        else if (endpoint.contains('/contacts') && method == 'GET') {
            // Simulate existing contact in Unanet
            res.setBody(JSON.serialize(new Map<String, Object>{
                'items' => new List<Object>{
                    new Map<String, Object>{
                        'key' => 1,
                        'first' => 'MockFirst',
                        'last' => 'MockLast',
                        'primaryEmail' => 'mock@example.com',
                        'primaryPhone' => '123-456-7890',
                        'active' => true
                    }
                },
                'page' => 0,
                'pageSize' => 0,
                'pageCount' => 0,
                'resultCount' => 1
            }));
        }

        else if (endpoint.contains('/contacts') && method == 'POST') {
            // Simulate contact creation
            res.setBody('{ "key": 987654 }');
        }

        else {
            res.setBody('{}'); // fallback
        }

        return res;
    }
}