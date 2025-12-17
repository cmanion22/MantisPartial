public class UnanetHttpMock implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(200);
        res.setHeader('Content-Type', 'application/json');

        String endpoint = req.getEndpoint();
        System.debug('Mock endpoint called: ' + req.getEndpoint());

        if (endpoint.contains('/cost-structures')) {
            res.setBody('{' +
                '"items":[{"key":1,"name":"Standard","description":"Standard","active":true,"costPoolGroupKey":1}],'+
                '"page":1,'+
                '"pageSize":100,'+
                '"pageCount":1,'+
                '"resultCount":1'+
            '}');
        } else if (endpoint.contains('/posting-groups')) {
            res.setBody('{"items":[{"key":1,"name":"Default","description":"Default","active":true,"type":"DEFAULT"}]}');
        } else if (endpoint.contains('/currencies/currency-codes')) {
            res.setBody('{"items":[{"key":1,"isoCurrencyCode":"USD","name":"US Dollar"}]}');
        } else if (endpoint.contains('/project-types')) {
            res.setBody('{"items":[{"key":1,"name":"BID","description":"Bid Project"}]}');
        } else if (endpoint.contains('/organizations/list')) {
            res.setBody('[{"key":1,"name":"FMS","code":"FMS"}]');
        } else if (endpoint.contains('/billing-types')) {
            res.setBody('{"items":[{"key":1,"type":"FIXED_PRICE","description":"Lump Sum/Fixed Price"}]}');
        } else if (endpoint.contains('/locations')) {
            res.setBody('{"items":[{"key":1,"name":"Florida","active":true}]}');
        } else if (endpoint.contains('/udf-metadata/PROJECT')) {
            res.setBody('{"items":[' +
                '{"index":1,"metadata":{"label":"Primary Salesperson","dataType":"STRING","visibility":"ENABLED","active":true}},' +
                '{"index":13,"metadata":{"label":"Street Address","dataType":"STRING","visibility":"ENABLED","active":true}},' +
                '{"index":14,"metadata":{"label":"City","dataType":"STRING","visibility":"ENABLED","active":true}},' +
                '{"index":15,"metadata":{"label":"SF Id","dataType":"STRING","visibility":"ENABLED","active":true}}' +
            ']}');
        } else if (endpoint.contains('/project-statuses')) {
            res.setBody('{"items":[{"key":1,"name":"Active","open":true}]}');
        } else if (endpoint.contains('/projects') && req.getMethod() == 'POST') {
            res.setBody('{"key":"MOCK-UNANET-KEY"}');
        } // Simulating pay-code data
          else if (endpoint.contains('pay-codes')) {
                res.setBody(
                    '{"items":[{"key":567,"name":"Regular"}],' +
                    '"page":1,"pageSize":100,"pageCount":1,"resultCount":1}'
                );
        
        }

          else {
            res.setBody('{}');
        }

        return res;
    }
}