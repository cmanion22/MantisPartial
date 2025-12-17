@RestResource(urlMapping='/UploadBrokerToSF/*')
global with sharing class BrokerCallIn {
    
    @HttpPost
    global static Broker__c createBroker() {
        System.debug('BrokerCallIn->createBroker');
        RestRequest request = RestContext.request;
        System.debug('BrokerCallIn->Request Body --> ' + request.requestbody.tostring());
        Map<String, Object> params = (Map<String, Object>)JSON.deserializeUntyped(request.requestbody.tostring());
        System.debug('BrokerCallIn->createBroker->Broker map-->' + params);
        Broker__c Broker = BrokerHelper.upsertBroker(params);
        
        // Return the Broker.
        return Broker;        
    } 
}