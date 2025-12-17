@RestResource(urlMapping='/UploadEntityToSF/*')
global with sharing class EntityCallIn {
    
    @HttpPost
    global static Entity__c createEntity() {
        RestRequest request = RestContext.request;
        System.debug('Request Body --> ' + request.requestbody.tostring());
        Map<String, Object> params = (Map<String, Object>)JSON.deserializeUntyped(request.requestbody.tostring());
        
        Entity__c entity = EntityHelper.upsertEntity(params);
        
        // Return the Entity.
        return entity;        
    } 
}