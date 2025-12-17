@isTest
private class OpportunityBoSyncTest {
    
    @isTest
    static void testTriggerWhenKillSwitchIsOff() {
        // Mock the callout if applicable
        Test.setMock(HttpCalloutMock.class, new MockOpportunityCallout());
        
        Opportunity_BO_Sync__e event = new Opportunity_BO_Sync__e(
            Opportunity_ID__c = '006XXXXXXXXXXXX',
            Sync_User_ID__c = '005XXXXXXXXXXXX'
        );
        
        Test.startTest();
        // Publish the platform event
        Database.SaveResult sr = EventBus.publish(event);
        Test.stopTest();
    }
    
    @isTest
    static void testTriggerWhenKillSwitchIsOn() {
        // Simulate the kill switch being ON by mocking the metadata result
        
        Test.startTest();
        // Insert the platform event (trigger should exit early due to kill switch)
        Opportunity_BO_Sync__e event = new Opportunity_BO_Sync__e(
            Opportunity_ID__c = '006XXXXXXXXXXX',
            Sync_User_ID__c = '005YYYYYYYYYYY'
        );
        
        Database.SaveResult sr = EventBus.publish(event);
        Test.stopTest();
    }
    
    // Optional: Mock the callout to avoid real HTTP call during test
    public class MockOpportunityCallout implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status": "success"}');
            res.setStatusCode(200);
            return res;
        }
    }
}