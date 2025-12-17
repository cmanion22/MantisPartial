@isTest
public class MarketHelperTest {
    @isTest static void upsertMarketTest() {  
        String strJson='{ "Name":"Market 1", "Commodity__c": "electricity", "Region__c": "US", "Country__c": "US", "Source_ID__c":"1", "Source_Database__c" : "EMEX"}';    
        Map<String, Object> params = (Map<String, Object>)JSON.deserializeUntyped(strJson);
        
        Market__c testMarket = MarketHelper.upsertMarket(params);

        List<Market__c> lst = [SELECT Id, Name FROM Market__c WHERE Id = :testMarket.Id];
        System.assertEquals(1, lst.size());
        
    } 
}