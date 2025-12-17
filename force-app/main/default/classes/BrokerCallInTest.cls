@isTest
public class BrokerCallInTest {    
     @isTest static void createBrokerTest() {        
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        req.addHeader('httpMethod', 'POST');
        req.requestUri = '/services/apexrest/UploadBrokerToSF/'; 
        req.requestBody = Blob.valueof('{ "Name":"Broker 1", "Source_ID__c":"1", "Source_Database__c" : "EMEX"}');
        
        RestContext.request = req; 
        RestContext.response = res;

        Test.startTest();
        Broker__c testBroker = BrokerCallIn.createBroker();
        Test.stopTest();

        List<Broker__c> lst = [SELECT Id, Name FROM Broker__c WHERE Id = :testBroker.Id];
        System.assertEquals(1, lst.size()); 
    } 
}