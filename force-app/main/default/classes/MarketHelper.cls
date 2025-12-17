public class MarketHelper {
    public static Market__c upsertMarket(Map<String, Object> params) {   
        Market__c thisMarket = new Market__c();        
        
        System.debug('MarketHelper-->upsertMarket-->params -->' + params);
        
        // Iterate through each parameter field and value
        for(String fieldName : params.keySet()) {                        
            System.debug(fieldName + '-' + params.get(fieldName));
            // Set the field and value on the Opportunity sObject
            thisMarket.put(fieldName, params.get(fieldName));            
        }
        
        System.debug('MarketHelper-->upsertMarket-->market -->' + thisMarket);
        upsert thisMarket;
        
        System.debug('MarketHelper-->upsertMarket-->market.Id -->' + thisMarket.Id);              
        return thisMarket;
    } 
}