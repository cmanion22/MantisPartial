@IsTest
public class TestCreateWorkOrderFlow {
    
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
        WorkOrder w = new WorkOrder(subject = 'test subject', description = 'test desc', Defects__c  = '1;2;3', Work_Template__c=template.ID,
                                    Technician_s__c = 2, StartDate = System.today()+1, EndDate=System.today()+5,Sections__c = '1',Sections_Name__c = 'A',
                                    WorkTypeId = WT.Id, AccountId = acc.Id, OwnerId = user.id, Cause_Of_Leak__c = 'Storm Damage');
        insert w;
    }
    
    private static testMethod void createDefectSectionLineItem(){
        List<WorkOrder> w = [select Id, Defects__c, Sections__c, Work_Template__c from WorkOrder limit 1];
        Test.startTest();
        try{
            CreateWorkOrderFlow.createDefectSectionLineItem(new List<String>{w[0].ID});    
        } catch(Exception e){
            System.debug(e.getMessage());
        }
        
        Test.stopTest();
    }
}