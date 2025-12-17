@isTest
public class MarketCallInTest {    
     @isTest static void createMarketTest() {
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        req.addHeader('httpMethod', 'POST');
        req.requestUri = '/services/apexrest/UploadMarketToSF/';   
        req.requestBody = Blob.valueof('{ "Name":"Market 1", "Commodity__c": "electricity", "Region__c": "US", "Country__c": "US", "Source_ID__c":"1", "Source_Database__c" : "EMEX" }');
        
        RestContext.request = req; 
        RestContext.response = res;
        
        Test.startTest();
        Market__c testMarket = MarketCallIn.createMarket();
        Test.stopTest();

        List<Market__c> lst = [SELECT Id, Name FROM Market__c WHERE Id = :testMarket.Id];
        System.assertEquals(1, lst.size());
    } 
}