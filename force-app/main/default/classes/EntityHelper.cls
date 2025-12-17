public class EntityHelper {
    public static Entity__c upsertEntity(Map<String, Object> params) {   
        Entity__c thisEntity = new Entity__c();        
        
        System.debug('EntityHelper-->upsertEntity-->params -->' + params);
        
        // Iterate through each parameter field and value
        for(String fieldName : params.keySet()) {                        
            System.debug(fieldName + '-' + params.get(fieldName));
            // Set the field and value on the Opportunity sObject
            thisEntity.put(fieldName, params.get(fieldName));            
        }
        
        System.debug('EntityHelper-->upsertEntity-->Entity -->' + thisEntity);
        upsert thisEntity;
        
        System.debug('EntityHelper-->upsertEntity-->Entity.Id -->' + thisEntity.Id);              
        return thisEntity;
    } 
}