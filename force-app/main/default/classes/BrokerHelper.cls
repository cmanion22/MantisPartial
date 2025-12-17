public class BrokerHelper {
    public static Broker__c upsertBroker(Map<String, Object> params) {   
        Broker__c thisBroker = new Broker__c();        
        
        System.debug('BrokerHelper-->upsertBroker-->params -->' + params);
        
        // Iterate through each parameter field and value
        for(String fieldName : params.keySet()) {                        
            System.debug(fieldName + '-' + params.get(fieldName));
            // Set the field and value on the Opportunity sObject
            thisBroker.put(fieldName, params.get(fieldName));            
        }
        
        System.debug('BrokerHelper-->upsertBroker-->Broker -->' + thisBroker);
        upsert thisBroker;
        
        System.debug('BrokerHelper-->upsertBroker-->Broker.Id -->' + thisBroker.Id);              
        return thisBroker;
    } 
}