@isTest
public class EntityCallInTest {
    
     @isTest static void createEntityTest() {
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        req.addHeader('httpMethod', 'POST');
        req.requestUri = '/services/apexrest/UploadEntityToSF/';  
        req.requestBody = Blob.valueof('{ "Name":"Test Entity", "Brand__c": "Test Brand", "Source_ID__c":"Test Source Id Entity", "Source_Database__c" : "Test Source DB Entity"}');
        
        RestContext.request = req; 
        RestContext.response = res;
        
        Test.startTest();
        Entity__c testEntity = EntityCallIn.createEntity();
        Test.stopTest();

        List<Entity__c> lst = [SELECT Id, Name FROM Entity__c WHERE Id = :testEntity.Id];
        System.assertEquals(1, lst.size()); 
    } 
}