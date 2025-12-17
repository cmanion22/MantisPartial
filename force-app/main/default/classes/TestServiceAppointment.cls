@isTest
public class TestServiceAppointment {
    
    @TestSetUp
    static void makeData(){
        Email_Approved_Status__c EAS = new Email_Approved_Status__c(Name = 'Email', Email__c = 'test@gmail.com');
        insert EAS;
        WorkType WT = new WorkType(Name = 'Test', EstimatedDuration = 30);
        insert WT;
        Account acc = new Account(Name = 'Test', Industry = 'Banking');
        insert acc;
        User user = [select Id, Name, Email from User where IsActive = true order by Id asc limit 1];
        OperatingHours OH = new OperatingHours(Name='test');
        insert OH;
        ServiceResource sr = new ServiceResource(Name='test', RelatedRecordId=user.ID, IsActive=true);
        insert sr;
        ServiceTerritory st = new ServiceTerritory(Name='test', OperatingHoursId=OH.ID, IsActive=true);
        insert st;
        ServiceTerritoryMember stm = new ServiceTerritoryMember(ServiceResourceId=sr.ID,ServiceTerritoryId=st.ID,EffectiveStartDate=System.today());
        insert stm;
        WorkOrder w = new WorkOrder(subject = 'test subject', description = 'test desc', Defects__c  = '1,2,3', Cost__c =  30,
                                    Technician_s__c = 2, StartDate = System.today()+1, EndDate=System.today()+5, Sections_Name__c = 'Test',
                                    WorkTypeId = WT.Id, AccountId = acc.Id, OwnerId = user.id, Cause_Of_Leak__c = 'Storm Damage', Client_PO_Number__c = '123456');
        insert w;
        List<Cost_Type__c> ct = new List<Cost_Type__c>();
        ct.add(new Cost_Type__c(Cost_Type__c = 'labor', Cost__c = 20, Work_Order__c = w.Id));
        insert ct;
        HttpMockFactory mock = new HttpMockFactory(200, 'OK', 'I found it!', new Map<String,String>());
    	Test.setMock(HttpCalloutMock.class, mock);
    }
    
    public TestMethod static void testAcceptAfterDispatched(){
        WorkOrder w = [select Id, Status, OwnerId from WorkOrder where subject = 'test subject' limit 1];
        ServiceAppointment sa = new ServiceAppointment(ParentRecordId = w.Id, Status = 'None', DueDate = System.today() + 5,
                                                      EarliestStartTime = System.today(), SchedStartTime = System.today() + 1,
                                                      SchedEndTime = System.today() + 2, OwnerId = w.OwnerId ,Accept_Reject_Work__c = null);
        insert sa;
        ServiceResource sr = [select Id from ServiceResource where Name='test'];
        AssignedResource ar = new AssignedResource(ServiceResourceId=sr.ID,ServiceAppointmentId=sa.ID);
        insert ar;
        HttpMockFactory mock = new HttpMockFactory(200, 'OK', 'I found it!', new Map<String,String>());
    	Test.setMock(HttpCalloutMock.class, mock);
        
        sa.status = 'Dispatched';
        update sa;
        
        test.startTest();
        
        sa.Accept_Reject_Work__c = 'Accept';
        update sa;
        
        test.stopTest(); 
        
    }
    
    /* public TestMethod static void testSAStatusFlow(){
        WorkOrder w = [select Id, Status, OwnerId from WorkOrder where subject = 'test subject' limit 1];
        ServiceAppointment sa = new ServiceAppointment(ParentRecordId = w.Id, Status = 'None', DueDate = System.today() + 5,
                                                      EarliestStartTime = System.today(), SchedStartTime = System.today() + 1,
                                                      SchedEndTime = System.today() + 2, ActualEndTime = System.today() + 2, OwnerId = w.OwnerId ,Accept_Reject_Work__c = null);
        insert sa;
        ServiceResource sr = [select Id from ServiceResource where Name='test'];
        AssignedResource ar = new AssignedResource(ServiceResourceId=sr.ID,ServiceAppointmentId=sa.ID);
        insert ar;
        HttpMockFactory mock = new HttpMockFactory(200, 'OK', 'I found it!', new Map<String,String>());
    	Test.setMock(HttpCalloutMock.class, mock);  
        
        sa.status = 'Dispatched';
        update sa;
        
		test.startTest();
        
        sa.Status = 'In Progress';
        update sa;
        
        sa.Accept_Reject_Work__c = 'Accept';
        
        test.stopTest();  
        sa.Status = 'Completed';
        update sa;
        
             
        
    } */
    
    public TestMethod static void testNoneRejectAfterAcceptSA(){
        WorkOrder w = [select Id, Status, OwnerId from WorkOrder where subject = 'test subject' limit 1];
        
        ServiceAppointment sa = new ServiceAppointment(ParentRecordId = w.Id, Status = 'Accepted', DueDate = System.today() + 5,
                                                      EarliestStartTime = System.today(), SchedStartTime = System.today() + 1,
                                                      SchedEndTime = System.today() + 2, OwnerId = w.OwnerId ,
                                                      Accept_Reject_Work__c = 'Accept');
        
        
        insert sa;
     
        test.startTest();
        
        sa.Accept_Reject_Work__c = null;
        try{
        	Database.SaveResult result = DataBase.update(sa);
            System.assert(!result.isSuccess());
        } catch(Exception e){
            system.debug(e.getMessage()); 
        }
        
        sa.Accept_Reject_Work__c = 'Reject';
        try{
        	Database.SaveResult result = DataBase.update(sa);
            System.assert(!result.isSuccess());
        } catch(Exception e){
            system.debug(e.getMessage()); 
        }
        
        test.stopTest();       
        
    }
    
    public TestMethod static void testRejectAfterDispatched(){
        WorkOrder w = [select Id, Status, OwnerId from WorkOrder where subject = 'test subject' limit 1];
        ServiceAppointment sa = new ServiceAppointment(ParentRecordId = w.Id, Status = 'None', DueDate = System.today() + 5,
                                                      EarliestStartTime = System.today(), SchedStartTime = System.today() + 1,
                                                      SchedEndTime = System.today() + 2, OwnerId = w.OwnerId ,Accept_Reject_Work__c = null);
        insert sa;
        ServiceResource sr = [select Id from ServiceResource where Name='test'];
        AssignedResource ar = new AssignedResource(ServiceResourceId=sr.ID,ServiceAppointmentId=sa.ID);
        insert ar;
        HttpMockFactory mock = new HttpMockFactory(200, 'OK', 'I found it!', new Map<String,String>());
    	Test.setMock(HttpCalloutMock.class, mock);
        
        sa.status = 'Dispatched';
        update sa;
        
        test.startTest();
        
        sa.Accept_Reject_Work__c = 'Reject';
        sa.Rejection_Reason__c = 'Test';
        update sa;
        
        test.stopTest();
    }
	
    public TestMethod static void testStatusAfterAcceptSA(){
        WorkOrder w = [select Id, Status, OwnerId from WorkOrder where subject = 'test subject' limit 1];
        ServiceAppointment sa = new ServiceAppointment(ParentRecordId = w.Id, Status = 'None', DueDate = System.today() + 5,
                                                      EarliestStartTime = System.today(), SchedStartTime = System.today() + 1,
                                                      SchedEndTime = System.today() + 2, ActualEndTime = System.today() + 2, OwnerId = w.OwnerId ,Accept_Reject_Work__c = null);
        insert sa;
        ServiceResource sr = [select Id from ServiceResource where Name='test'];
        AssignedResource ar = new AssignedResource(ServiceResourceId=sr.ID,ServiceAppointmentId=sa.ID);
        insert ar;
        HttpMockFactory mock = new HttpMockFactory(200, 'OK', 'I found it!', new Map<String,String>());
        Test.setMock(HttpCalloutMock.class, mock);
        test.startTest();
        
        sa.Status = 'Canceled';
        update sa;
        
        test.stopTest();        
    }
    
    
}