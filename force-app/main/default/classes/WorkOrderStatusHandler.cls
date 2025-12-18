public class WorkOrderStatusHandler {
    public static void WorkOrderAfterInsert(List<WorkOrder> wos) {
        if (wos.isEmpty()) return;

        for (WorkOrder w : wos) {
            if (w.MaintenancePlanId != null) {
                MaintenancePlan mp = [SELECT Id, Work_Template__c FROM MaintenancePlan WHERE Id = :w.MaintenancePlanId LIMIT 1];
                if (mp.Work_Template__c != null) {
                    CreateWorkOrderLineItems.createLineItems(mp.Work_Template__c, w.Id, w.MaintenancePlanId, w.SuggestedMaintenanceDate);
                }
            }
        }
    }

    public static void WorkOrderStatusAfterUpdate(List<WorkOrder> newWos, Map<Id, WorkOrder> oldWosMap) {
        if (newWos.isEmpty()) return;
        
        // Collect Property Ids
        Set<Id> propertyIds = new Set<Id>();
        for(WorkOrder w : newWos){
            if(w.Property2__c != null) {
                propertyIds.add(w.Property2__c);
            }
        }
        
		// Query all related Properties
        Map<Id, Property__c> propertyMap = new Map<Id, Property__c>(
            [SELECT Id, Name, Add1__c, City__c, State__c, Zip__c, Country__c
             FROM Property__c
             WHERE Id IN :propertyIds]
        );
        
        for (WorkOrder w : newWos) {
            WorkOrder wOld = oldWosMap.get(w.Id);

            if (wOld.Status != w.Status) {
                handleStatusChange(w, wOld, propertyMap);
            }
        }
    }

    private static void handleStatusChange(WorkOrder w, WorkOrder wOld, Map<Id, Property__c> propertyMap) {
        if (wOld.Status == 'Exceed NTE' && w.Status == 'In Progress') {
            updateServiceAppointments(w.Id, 'Dispatched');
        } else if (w.Status == 'Exceed NTE') {
            handleExceedNTE(w);
        } else if (w.Status == 'Completed') {
            handleCompletion(w);
        } else if (w.Status == 'Approved') {
            handleApproval(w, propertyMap);
        }
    }

    private static void updateServiceAppointments(Id workOrderId, String newStatus) {
        List<ServiceAppointment> serviceAppointments = [SELECT Id FROM ServiceAppointment WHERE ParentRecordId = :workOrderId];
        for (ServiceAppointment sa : serviceAppointments) {
            sa.Status = newStatus;
        }
        if (!serviceAppointments.isEmpty()) {
            update serviceAppointments;
        }
    }

    private static void handleExceedNTE(WorkOrder w) {
        List<ServiceAppointment> sr = [select Id, Status from ServiceAppointment where ParentRecordId = :w.Id];
                    Group groupId = [select id from Group where Name = 'Field Agents' limit 1];
                    //system.debug(GroupId);
                    List<GroupMember> userId = [SELECT UserOrGroupId FROM GroupMember WHERE GroupId = :groupId.id];        
                    Messaging.CustomNotification obj = new Messaging.CustomNotification();
                    CustomNotificationType notification = [SELECT Id, CustomNotifTypeName, DeveloperName from CustomNotificationType where CustomNotifTypeName = 'Exceed NTE Request' limit 1];
                    obj.setNotificationTypeId(notification.Id);
                    obj.setTargetId(w.Id); // when we click on the notification it will redirect to the specified targetId
                    obj.setTitle('Request to Increase NTE');
                    obj.setBody('Contactor has requested to Increase NTE for the Work Order.');
                    for(Integer i=0; i<sr.size(); i++){
                        //sr[i].Accept_Reject_Work__c = null;
                        sr[i].Status = 'Exceed NTE';
                    }
                    for(GroupMember g: userId){  
                        //system.debug(g);
                        obj.send(new set<String>{g.UserOrGroupId});
                    }
                    update sr;
                }
    

    private static void handleCompletion(WorkOrder w) {
        
        List<Cost_Type__c> CT = [select Id from Cost_Type__c where Work_Order__c =:w.Id];
                    If(CT.size() < 1){
                        w.addError('Please Enter the cost type and cost!');
                    } else{
                        Group groupId = [select id from Group where Name = 'Field Agents' limit 1];
                        List<GroupMember> userId = [SELECT UserOrGroupId FROM GroupMember WHERE GroupId = :groupId.id];    
                        String[] toAddresses = new String[] {};
                        String title = 'Work Order '+w.Work_Order_Number_2__c+' is completed';
                        String baseUrl = URL.getOrgDomainUrl().toExternalForm();
                        String body = 'Work Order ' + w.Work_Order_Number_2__c + ' is completed. Please review it by clicking the following link: ' +
                                      baseUrl + '/' + w.Id;
                        Messaging.CustomNotification obj = new Messaging.CustomNotification();
                        CustomNotificationType notification = [SELECT Id, CustomNotifTypeName, DeveloperName from CustomNotificationType where CustomNotifTypeName = 'Exceed NTE Request' limit 1];
                        obj.setNotificationTypeId(notification.Id);
                        obj.setTargetId(w.Id); // when we click on the notification it will redirect to the specified targetId
                        obj.setTitle('Work Order '+w.Work_Order_Number_2__c+' is completed');
                        obj.setBody('Work Order '+w.Work_Order_Number_2__c+' is completed; Please review.');
                        
                        for(GroupMember g: userId){  
                            User user = [SELECT Id, Email, IsActive FROM User WHERE Id = :g.UserOrGroupId];
                            if (!user.IsActive) continue;

                            toAddresses.add(user.Email);
                            obj.send(new set<String>{g.UserOrGroupId});
                        }
                        if(toAddresses.size() > 1){
                        	EmailManager.sendMail(toAddresses, title, body, '', '', null);    
                        }
                    }
                }
    

    private static void handleApproval(WorkOrder w, Map<Id, Property__c> propertyMap) {
        
        List<ServiceAppointment> srs = [select Id, Status, Invoice_Number__c,AccountId, ActualStartTime, ActualEndTime from ServiceAppointment where ParentRecordId = :w.Id ORDER BY Id DESC limit 1];
                    If(srs.size() > 0){
                        if(w.Service_Line__c == 'RLR') {
                            
                            ServiceAppointment sr = srs[0];
                            List<AssignedResource> sResList = [select ID, ServiceResourceId from AssignedResource where ServiceAppointmentId=:sr.Id limit 1];
                            String sRes = (sResList.size() < 1 ? '' : sResList[0].ServiceResourceId);
                            List<ServiceResource> UserList = [select ID, RelatedRecordId from ServiceResource where ID=:sRes limit 1];
                            String UserID = ((UserList.size() <  1) ? '' : UserList[0].RelatedRecordId);
                            
                            String SRUserName = ((UserID == '') ? '' : [select Id, Name from User where ID =:UserID].Name);
                            String propertyName = (w.PropertyName__c == null ? '' : w.PropertyName__c);
                            String propertyEmail = (w.Contact.Email == null ? '' : w.Contact.Email);
                            WorkType workType = (w.WorkTypeId == null ? null : [select Id, Name from WorkType where Id=:w.WorkTypeId]);
                            Account AccountName = (w.AccountId == null ? null : [select Id, Name from Account where Id=:w.AccountId]);
                            Contact contact = (w.ContactId == null ? null : [select Id, Email from Contact where Id=:w.ContactId]);
                            Contact contractor = (w.Contractor__c == null ? null : [select Name from Contact where Id=:w.Contractor__c]);
                            Contact siteContact = (w.Contact__c == null ? null : [select Id, Name from Contact where Id=:w.Contact__c]);
                            String invoiceNumber = sr.Invoice_Number__c;
    
                            String[] toAddresses = new String[] {};
                            String email = Email_Approved_Status__c.getInstance('Email').Email__c;
                            toAddresses.Add(email);
    
                            String formattedActualStartTime = sr.ActualStartTime != null ? sr.ActualStartTime.format('yyyy-MM-dd') : '';
                            String formattedActualEndTime = sr.ActualEndTime != null ? sr.ActualEndTime.format('yyyy-MM-dd') : '';
    
                            String title = 'WO# ' + w.Work_Order_Number_2__c + ' Invoice# ' + invoiceNumber + ' ' + ( AccountName != null ? AccountName.Name : ''); 
                            String Body = '<html><body><table>';
                            Body += '<tr><td><p>OK to process '+ w.Work_Order_Number_2__c +' '+ (WorkType !=null ?WorkType.Name:'') +' '+contractor.Name+'</p></tr></td>'; 
                            Body += '<tr><td><p>&nbsp;</p><p>Bldg.#: '+ w.PropertyName__c +'</p></tr></td>';
                            Body += '<tr><td><p>Project.#: '+ w.Project_No__c +'</p></tr></td>';
                            Body += '<tr><td><p>Account Name: '+ (AccountName !=null?AccountName.Name:'') +'</p></tr></td>';
                            Body += '<tr><td><p>WO#: '+ w.Work_Order_Number_2__c +'</p></tr></td>';
                            Body += '<tr><td><p>Client PO: '+ w.Client_PO_Number__c +'</p></tr></td>';
                            Body += '<tr><td><p>Site Contact: '+ (siteContact !=null?siteContact.Name:'') +'</p></tr></td>';
                            Body += '<tr><td><p>Date/Time: '+ w.CreatedDate +'</p></tr></td>';
                            Body += '<tr><td><p>Bldg.#: '+ w.PropertyName__c +'</p></tr></td>';
                            Body += '<tr><td><p>Address: '+ w.PropertyAddress__c +'</p></tr></td>';
                            Body += '<tr><td><p>Cost: '+ w.Cost_Type_Price__c +'</p></tr></td>';
                            Body += '<tr><td><p>Fee: '+ w.Cost__c +'</p></tr></td>';
                            Body += '<tr><td><p>Full Amount: '+ (w.Cost_Type_Price__c + w.Cost__c)  +'</p></tr></td>';
                            Body += '<tr><td><p>Date Of Service: ' + formattedActualStartTime + ' - ' + formattedActualEndTime + '</p></tr></td>';
                            Body += '<tr><td><p>Work Completed: '+ w.Work_Completed__c +'</p></tr></td></table></body></HTML>';
                            System.debug('sending email');
                            // Sending Email Notification to predefined EmailID
                            EmailManager.sendMail(toAddresses, title, Body, '', '', w);
                            
                        } else if (w.Service_Line__c == 'BMS Service') {
                            
                            ServiceAppointment sr = srs[0];
                            List<AssignedResource> sResList = [select ID, ServiceResourceId from AssignedResource where ServiceAppointmentId=:sr.Id limit 1];
                            String sRes = (sResList.size() < 1 ? '' : sResList[0].ServiceResourceId);
                            List<ServiceResource> UserList = [select ID, RelatedRecordId from ServiceResource where ID=:sRes limit 1];
                            String UserID = ((UserList.size() <  1) ? '' : UserList[0].RelatedRecordId);
                            
                            String SRUserName = ((UserID == '') ? '' : [select Id, Name from User where ID =:UserID].Name);
                            String propertyName = (w.PropertyName__c == null ? '' : w.PropertyName__c);
                            String propertyEmail = (w.Contact.Email == null ? '' : w.Contact.Email);
                            WorkType workType = (w.WorkTypeId == null ? null : [select Id, Name from WorkType where Id=:w.WorkTypeId]);
                            Account AccountName = (w.AccountId == null ? null : [select Id, Name from Account where Id=:w.AccountId]);
                            Contact contact = (w.ContactId == null ? null : [select Id, Email from Contact where Id=:w.ContactId]);
                            Contact contractor = (w.Contractor__c == null ? null : [select Name from Contact where Id=:w.Contractor__c]);
                            Contact siteContact = (w.Contact__c == null ? null : [select Id, Name from Contact where Id=:w.Contact__c]);
                            String invoiceNumber = sr.Invoice_Number__c;
    
                            String[] toAddresses = new String[] {};
                            String email = Email_Approved_Status__c.getInstance('BMS_Email').Email__c;
                            toAddresses.Add(email);
    
                            String formattedActualStartTime = sr.ActualStartTime != null ? sr.ActualStartTime.format('yyyy-MM-dd') : '';
                            String formattedActualEndTime = sr.ActualEndTime != null ? sr.ActualEndTime.format('yyyy-MM-dd') : '';
                            
                            Property__c prop = propertyMap.get(w.Property2__c);
                            String address = '';
                            if(prop != null) {
                                if (prop != null) {
                                    List<String> parts = new List<String>();
                                    if (prop.Add1__c != null) parts.add(prop.Add1__c);
                                    if (prop.City__c != null) parts.add(prop.City__c);
                                    String stateZip = '';
                                    if (prop.State__c != null) stateZip += prop.State__c;
                                    if (prop.Zip__c != null) stateZip += (stateZip != '' ? ' ' : '') + prop.Zip__c;
                                    if (stateZip != '') parts.add(stateZip);
                                    if (prop.Country__c != null) parts.add(prop.Country__c);
                                    address = String.join(parts, ', ');
                                }
                            } else {
                                w.addError('A Property record must be selected to approve this Work Order.');
    							return;
                            }
    
                            String title = 'WO# ' + w.Work_Order_Number_2__c + ' Invoice# ' + invoiceNumber + ' ' + ( AccountName != null ? AccountName.Name : ''); 
                            String Body = '<html><body><table>';
                            Body += '<tr><td><p>OK to process '+ w.Work_Order_Number_2__c +' '+ (WorkType !=null ?WorkType.Name:'') +' '+contractor.Name+'</p></tr></td>'; 
                            Body += '<tr><td><p>&nbsp;</p><p>Bldg.#: '+ prop.Name +'</p></tr></td>';
                            Body += '<tr><td><p>Project.#: '+ w.Project_No__c +'</p></tr></td>';
                            Body += '<tr><td><p>Account Name: '+ (AccountName !=null?AccountName.Name:'') +'</p></tr></td>';
                            Body += '<tr><td><p>WO#: '+ w.Work_Order_Number_2__c +'</p></tr></td>';
                            Body += '<tr><td><p>Client PO: '+ w.Client_PO_Number__c +'</p></tr></td>';
                            Body += '<tr><td><p>Site Contact: '+ (siteContact !=null?siteContact.Name:'') +'</p></tr></td>';
                            Body += '<tr><td><p>Date/Time: '+ w.CreatedDate +'</p></tr></td>';
                            Body += '<tr><td><p>Bldg.#: '+ prop.Name +'</p></tr></td>';
                            Body += '<tr><td><p>Address: '+ address +'</p></tr></td>';
                            Body += '<tr><td><p>Cost: '+ w.Total_Cost__c +'</p></tr></td>';
                            Body += '<tr><td><p>Date Of Service: ' + formattedActualStartTime + ' - ' + formattedActualEndTime + '</p></tr></td>';
                            Body += '<tr><td><p>Work Completed: '+ w.Work_Completed__c +'</p></tr></td></table></body></HTML>';
                            System.debug('sending email');
                            // Sending Email Notification to predefined EmailID
                            EmailManager.sendMail(toAddresses, title, Body, '', '', w);
                        }
                        
                    }
    }
}