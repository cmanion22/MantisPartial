@isTest
public class EntityHelperTest {
    @isTest static void upsertEntityTest() { 
        String strJson= '{ "Name":"Test Entity", "Brand__c": "Test Brand", "Source_ID__c":"Test Source Id Entity", "Source_Database__c" : "Test Source DB Entity"}'; 
        Map<String, Object> params = (Map<String, Object>)JSON.deserializeUntyped(strJson);
        Entity__c testEntity = EntityHelper.upsertEntity(params);
        
        List<Entity__c> lst = [SELECT Id, Name FROM Entity__c WHERE Id = :testEntity.Id];
        System.assertEquals(1, lst.size()); 
    } 
}