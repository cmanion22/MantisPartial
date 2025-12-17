@isTest
public class TestCreateWorkOrderLineItems {

    @TestSetUp
    static void makeData(){
        WorkType WT = new WorkType(Name = 'Test', EstimatedDuration = 30);
        insert WT;
        Account acc = new Account(Name = 'Test', Industry = 'Banking');
        insert acc;
        User user = [select Id, Name from User limit 1];
        Work_Template__c template = new Work_Template__c(Name = 'test');
        insert template;
        Work_Template_Line_Item__c lineItem = new Work_Template_Line_Item__c(Work_Template__c = template.ID, Description__c='test');
        insert lineItem;
        MaintenancePlan mp = new MaintenancePlan(MaintenancePlanTitle = 'test subject', Description = 'test desc', StartDate=System.today()+1,
                                                 Section__c = '1',Frequency=2,FrequencyType='Days',GenerationTimeframe=2,
                                                 GenerationTimeframeType='Days',NextSuggestedMaintenanceDate=System.today()+10,Work_Template__c=template.ID);
        insert mp;
        WorkOrder w = new WorkOrder(subject='test subject new', description='test desc2', Defects__c  = '1,2', Cost__c =  30,OwnerId = user.id,
                                    Technician_s__c = 2, StartDate = System.today()+1, EndDate=System.today()+5,status='new',
                                    WorkTypeId = WT.Id, AccountId = acc.Id,  Cause_Of_Leak__c = 'Storm Damage', Sections_Name__c = 'Test',
                                    MaintenancePlanId=MP.ID,SuggestedMaintenanceDate=System.today()+5);
        insert w;
    }
    
    public TestMethod static void testLineItems(){
        WorkOrder w = [select Id, MaintenancePlanId, SuggestedMaintenanceDate from WorkOrder where subject='test subject new' limit 1];
        Work_Template__c template = [select Id from Work_Template__c limit 1];
        
        test.startTest();
        
        CreateWorkOrderLineItems.createLineItems(template.Id, w.Id, w.MaintenancePlanId, w.SuggestedMaintenanceDate);
        
        test.stopTest();
        
    }
}