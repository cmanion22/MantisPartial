@RestResource(urlMapping='/UploadMarketToSF/*')
global with sharing class MarketCallIn {    
    @HttpPost
    global static Market__c createMarket() {
        RestRequest request = RestContext.request;
        System.debug('Request Body --> ' + request.requestbody.tostring());
        Map<String, Object> params = (Map<String, Object>)JSON.deserializeUntyped(request.requestbody.tostring());
        
        Market__c thisMarket = MarketHelper.upsertMarket(params);
        
        // Return the market.
        return thisMarket;        
    } 
}