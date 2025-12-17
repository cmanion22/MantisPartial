@RestResource(urlMapping='/ClearSyncData/*')
global with sharing class SobjectCallIn {
    @HttpPost
    global static Sobject clearSyncData() {
        RestRequest request = RestContext.request;
        System.debug('Request Body --> ' + request.requestbody.tostring());
        Map<String, Object> params = (Map<String, Object>)JSON.deserializeUntyped(request.requestbody.tostring());
        
        Id id = params.get('id').toString();
        System.debug('id-->' + id);
        
        Sobject record = Helper.clearSyncData(id);
        return record;
    }    
}