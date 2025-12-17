trigger SendEmailWhenSADispached on ServiceAppointment (after update) {
	for(ServiceAppointment sr : Trigger.New){
    	system.debug('SR ID : '+sr.ID);
        ServiceAppointment srOld = Trigger.oldMap.get(sr.Id);
        if(sr.Status != srOld.Status && sr.Status == 'Dispatched'){
            If(srOld.Status == 'Exceed NTE'){
                List<AssignedResource> ServiceResourceId = [select ID, ServiceResourceId from AssignedResource where ServiceAppointmentId=:sr.Id];
                for(Integer i=0; i<ServiceResourceId.size(); i++){
                    String UserId = [select Id, RelatedRecordId from serviceresource where Id = :ServiceResourceId[i].ServiceResourceId].RelatedRecordId;
                    String[] toAddresses = new String[] {[select Id, email from user where Id = :UserId].email};
                    String title = 'NTE Request Addressed';
                    String body = 'Service Appointment : '+sr.AppointmentNumber+' assigned to you.';
                    EmailManager.sendMail(toAddresses, title, body, '', '', null);
                }
            }
            else{
                List<AssignedResource> ServiceResourceId = [select ID, ServiceResourceId from AssignedResource where ServiceAppointmentId=:sr.Id];
                for(Integer i=0; i<ServiceResourceId.size(); i++){
                    String UserId = [select Id, RelatedRecordId from serviceresource where Id = :ServiceResourceId[i].ServiceResourceId].RelatedRecordId;
                    String[] toAddresses = new String[] {[select Id, email from user where Id = :UserId].email};
                    String title = 'Service Appointment Assigned';
                    String body = 'Service Appointment : '+sr.AppointmentNumber+' assigned to you.';
                    EmailManager.sendMail(toAddresses, title, body, '', '', null);
                }    
            }            
        }
        if(sr.Status != srOld.Status && sr.Status == 'Rejected'){
            Group groupId = [select id from Group where Name = 'Field Agents' limit 1];                   
            //system.debug(GroupId);
            //User user = [Select id, email, name from user where name = 'Srishty Rawat'];
            List<GroupMember> userId = [SELECT UserOrGroupId FROM GroupMember WHERE GroupId = :groupId.id];      
            Messaging.CustomNotification obj = new Messaging.CustomNotification();
            CustomNotificationType notification = [SELECT Id, CustomNotifTypeName, DeveloperName from CustomNotificationType where CustomNotifTypeName = 'Exceed NTE Request' limit 1];
            obj.setNotificationTypeId(notification.Id);
            obj.setTargetId(sr.Id); // when we click on the notification it will redirect to the specified targetId
            obj.setTitle('Appointment Rejected');
            obj.setBody('Contactor rejected the Appointment with reason: ' + sr.Rejection_Reason__c );
            //obj.send(user.id);
           
            for(GroupMember g: userId){
                //system.debug(g);
                obj.send(new set<String>{g.UserOrGroupId});
            }
        }        
    }
}