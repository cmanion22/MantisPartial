@IsTest
public class TestcreateMaintenancePlanFlow {
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
    }
    
    private static testMethod void createDefectSectionLineItem(){
        List<MaintenancePlan> mp = [select Id, Section__c,Work_Template__c from MaintenancePlan limit 1];
        Test.startTest();
        try{
        	createMaintenancePlanFlow.createDefectSectionLineItemForMP(mp);    
        } catch(Exception e){
            System.debug(e.getMessage());
        }
        
        Test.stopTest();
    }
}