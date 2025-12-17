@isTest
public class TestWorkOrder {
	
    @TestSetUp
    static void makeData(){
        Email_Approved_Status__c EAS = new Email_Approved_Status__c(Name = 'Email', Email__c = 'test@gmail.com');
        insert EAS;
        WorkType WT = new WorkType(Name = 'Test', EstimatedDuration = 30);
        insert WT;
        Account acc = new Account(Name = 'Test', Industry = 'Banking');
        insert acc;
        Contact contractor = new Contact(LastName = 'Test1');
        insert contractor;
        Contact siteContact = new Contact(LastName = 'Test2');
        insert siteContact;
        //Contact contractor = [select id, Name from Contact limit 1];
        User user = [select Id, Name, Email from User where IsActive = true order by Id asc limit 1];
        OperatingHours OH = new OperatingHours(Name='test');
        insert OH;
        ServiceResource sr = new ServiceResource(Name='test', RelatedRecordId=user.ID, IsActive=true);
        insert sr;
        ServiceTerritory st = new ServiceTerritory(Name='test', OperatingHoursId=OH.ID, IsActive=true);
        insert st;
        ServiceTerritoryMember stm = new ServiceTerritoryMember(ServiceResourceId=sr.ID,ServiceTerritoryId=st.ID,EffectiveStartDate=System.today());
        insert stm;
        MaintenancePlan mp = new MaintenancePlan(MaintenancePlanTitle = 'test subject', Description = 'test desc', StartDate=System.today()+1,
                                                 Section__c = '1',Frequency=2,FrequencyType='Days',GenerationTimeframe=2,
                                                 GenerationTimeframeType='Days',NextSuggestedMaintenanceDate=System.today()+10);
        insert MP;
        WorkOrder w = new WorkOrder(subject='test subject new', description='test desc2', Defects__c  = '1,2', Cost__c =  30,OwnerId = user.id,
                                    Technician_s__c = 2, StartDate = System.today()+1, EndDate=System.today()+5,status='In Progress',
                                    WorkTypeId = WT.Id, AccountId = acc.Id,Contractor__c = contractor.Id,Contact__c = siteContact.Id,Cause_Of_Leak__c = 'Storm Damage',
                                    MaintenancePlanId=MP.ID,SuggestedMaintenanceDate=System.today()+5, Sections_Name__c = 'Test', Client_PO_Number__c = '123456');
        insert w;
        WorkOrderLineItem WL = new WorkOrderLineItem(description = 'test2', Price__c=10, WorkOrderId=w.Id,StartDate = System.today()+1, EndDate=System.today()+5);
        insert WL;
        ServiceAppointment sa = new ServiceAppointment(ParentRecordId = w.Id, Status = 'Dispatched', DueDate = System.today() + 5,
                                                      EarliestStartTime = System.today(), SchedStartTime = System.today() + 1,
                                                      SchedEndTime = System.today() + 2, OwnerId = w.OwnerId ,Accept_Reject_Work__c = null);
        insert sa;
        AssignedResource ar = new AssignedResource(ServiceResourceId=sr.ID,ServiceAppointmentId=sa.ID);
        insert ar;
        
        HttpMockFactory mock = new HttpMockFactory(200, 'OK', 'I found it!', new Map<String,String>());
    	Test.setMock(HttpCalloutMock.class, mock);
    }
    
	public TestMethod static void testWorkOrder(){
        
        WorkOrder w = [select Id, Status from WorkOrder where subject = 'test subject new' limit 1];
        ServiceAppointment sa = [Select ID, Status from ServiceAppointment where ParentRecordId =: w.Id];
        System.debug('SA Status : '+sa.Status+' ;'+w.Status);
        
        HttpMockFactory mock = new HttpMockFactory(200, 'OK', 'I found it!', new Map<String,String>());
    	Test.setMock(HttpCalloutMock.class, mock);
        
        test.startTest();
        
        sa.Accept_Reject_Work__c = 'Accept';
        update sa;
                
        w.Status = 'In Progress';
        update w;    
                
        /* w.Status = 'Completed';
        try{
            Database.SaveResult result = Database.update(w);
            System.assert(!result.success);
        } catch(Exception e){
            
        }
        test.stopTest(); */
        List<Cost_Type__c> ct = new List<Cost_Type__c>();
        ct.add(new Cost_Type__c(Cost_Type__c = 'labor', Cost__c = 20, Work_Order__c = w.Id));
        ct.add(new Cost_Type__c(Cost_Type__c = 'Travel', Cost__c = 20, Work_Order__c = w.Id));
        ct.add(new Cost_Type__c(Cost_Type__c = 'Other Costs', Other_Cost_Type__c = 'Test', Cost__c = 20, Work_Order__c = w.Id));
        insert ct;
        
        w.Status = 'Completed';
        update w;
        
        w.Status = 'Approved';
        update w;
        
        test.stopTest();
        
    }

}