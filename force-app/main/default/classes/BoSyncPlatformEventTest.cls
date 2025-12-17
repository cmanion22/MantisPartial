@isTest
public class BoSyncPlatformEventTest {

    @isTest
    static void accountBoSyncTest() {
        Account_BO_Sync__e newBoSyncEvent = new Account_BO_Sync__e();
        newBoSyncEvent.Account_ID__c = TestUtil.generateId(Account.SObjectType);
        newBoSyncEvent.Sync_User_ID__c = TestUtil.generateId(User.SObjectType);

        Test.startTest();
        Database.SaveResult sr = EventBus.publish(newBoSyncEvent);
        Test.stopTest();

        Assert.isTrue(sr.isSuccess());
    }

    @isTest
    static void contactBoSyncTest() {
        Contact_BO_Sync__e newBoSyncEvent = new Contact_BO_Sync__e();
        newBoSyncEvent.Contact_ID__c = TestUtil.generateId(Contact.SObjectType);
        newBoSyncEvent.Sync_User_ID__c = TestUtil.generateId(User.SObjectType);

        Test.startTest();
        Database.SaveResult sr = EventBus.publish(newBoSyncEvent);
        Test.stopTest();

        Assert.isTrue(sr.isSuccess());
    }

    @isTest
    static void fileDeletionBoSyncTest() {
        File_Deletion_BO_Sync__e newBoSyncEvent = new File_Deletion_BO_Sync__e();
        newBoSyncEvent.Content_Document_ID__c = TestUtil.generateId(ContentDocument.SObjectType);
        newBoSyncEvent.Opportunity_ID__c = TestUtil.generateId(Opportunity.SObjectType);
        newBoSyncEvent.Sync_User_ID__c = TestUtil.generateId(User.SObjectType);

        Test.startTest();
        Database.SaveResult sr = EventBus.publish(newBoSyncEvent);
        Test.stopTest();

        Assert.isTrue(sr.isSuccess());
    }

    @isTest
    static void fileUploadBoSyncTest() {
        File_Upload_BO_Sync__e newBoSyncEvent = new File_Upload_BO_Sync__e();
        newBoSyncEvent.Content_Document_ID__c = TestUtil.generateId(ContentDocument.SObjectType);
        newBoSyncEvent.Opportunity_ID__c = TestUtil.generateId(Opportunity.SObjectType);
        newBoSyncEvent.Sync_User_ID__c = TestUtil.generateId(User.SObjectType);

        Test.startTest();
        Database.SaveResult sr = EventBus.publish(newBoSyncEvent);
        Test.stopTest();

        Assert.isTrue(sr.isSuccess());
    }

    @isTest
    static void opportunityBoSyncTest() {
        Opportunity_BO_Sync__e newBoSyncEvent = new Opportunity_BO_Sync__e();
        newBoSyncEvent.Opportunity_ID__c = TestUtil.generateId(Opportunity.SObjectType);
        newBoSyncEvent.Sync_User_ID__c = TestUtil.generateId(User.SObjectType);

        Test.startTest();
        Database.SaveResult sr = EventBus.publish(newBoSyncEvent);
        Test.stopTest();

        Assert.isTrue(sr.isSuccess());
    }

    @isTest
    static void taskBoSyncTest() {
        Task_BO_Sync__e newBoSyncEvent = new Task_BO_Sync__e();
        newBoSyncEvent.Task_ID__c = TestUtil.generateId(Task.SObjectType);
        newBoSyncEvent.Sync_User_ID__c = TestUtil.generateId(User.SObjectType);

        Test.startTest();
        Database.SaveResult sr = EventBus.publish(newBoSyncEvent);
        Test.stopTest();

        Assert.isTrue(sr.isSuccess());
    }

    @isTest
    static void taskCommentBoSyncTest() {
        Task_Comment_BO_Sync__e newBoSyncEvent = new Task_Comment_BO_Sync__e();
        newBoSyncEvent.Task_ID__c = TestUtil.generateId(Task.SObjectType);
        newBoSyncEvent.Content_Document_ID__c = TestUtil.generateId(ContentDocument.SObjectType);
        newBoSyncEvent.Sync_User_ID__c = TestUtil.generateId(User.SObjectType);

        Test.startTest();
        Database.SaveResult sr = EventBus.publish(newBoSyncEvent);
        Test.stopTest();

        Assert.isTrue(sr.isSuccess());
    }

    @isTest
    static void userBoSyncTest() {
        User_BO_Sync__e newBoSyncEvent = new User_BO_Sync__e();
        newBoSyncEvent.User_ID__c = TestUtil.generateId(User.SObjectType);
        newBoSyncEvent.Sync_User_ID__c = TestUtil.generateId(User.SObjectType);

        Test.startTest();
        Database.SaveResult sr = EventBus.publish(newBoSyncEvent);
        Test.stopTest();

        Assert.isTrue(sr.isSuccess());
    }

}