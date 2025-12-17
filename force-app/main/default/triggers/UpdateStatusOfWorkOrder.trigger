trigger UpdateStatusOfWorkOrder on ServiceAppointment (after update) {
	for(ServiceAppointment srNew : Trigger.New){
        ServiceAppointment srOld = Trigger.oldMap.get(srNew.Id);
        ServiceAppointment parent = [select Id, ParentRecordType from ServiceAppointment where Id = :srNew.Id limit 1];
        if(parent.ParentRecordType == 'WorkOrder'){
            WorkOrder w = [select Id, Status, WorkOrderNumber, RootWorkOrderId from WorkOrder where Id = :srNew.ParentRecordId limit 1];
            system.debug(w);
            if(w != null){
                if(srNew.Status == 'None'){
                    w.Status = 'New';
                } 
                if(srNew.Status == 'Rejected'){
                    w.Status = 'On Hold';
                } 
                if(srNew.Status == 'Completed'){
                    w.Status = 'Completed';
                } 
                if(srNew.Status == 'Cannot Complete'){
                    w.Status = 'Cannot Complete';
                }
                if(srNew.Status == 'Canceled'){
                    w.Status = 'Canceled';
                } 
                if(srNew.Status == 'Scheduled' || srNew.Status == 'Dispatched' || srNew.Status == 'Accepted' || srNew.Status == 'In Progress'){
                    w.Status = 'In Progress';
                }
                if(srNew.Status == 'Exceed NTE'){
                    w.Status = 'Exceed NTE';
                }
                update w;
            }
        }
    }
}