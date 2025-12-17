@isTest
public class BrokerHelperTest {
    @isTest static void upsertBrokerTest() { 
        String strJson = '{ "Name":"Broker 1", "Source_ID__c":"1", "Source_Database__c" : "EMEX"}'; 
        Map<String, Object> params = (Map<String, Object>)JSON.deserializeUntyped(strJson);
        Broker__c testBroker = BrokerHelper.upsertBroker(params);
        
        List<Broker__c> lst = [SELECT Id, Name FROM Broker__c WHERE Id = :testBroker.Id];
        System.assertEquals(1, lst.size()); 
    } 
}