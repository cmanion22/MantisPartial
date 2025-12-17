trigger WorkOrderStatusUpdate on WorkOrder (after update, after insert) {
    if(Trigger.IsInsert && Trigger.IsAfter){
    WorkOrderStatusHandler.WorkOrderAfterInsert(Trigger.New);
    }
    else if (Trigger.isUpdate && Trigger.isAfter) {
        WorkOrderStatusHandler.WorkOrderStatusAfterUpdate(Trigger.new, Trigger.oldMap);
    }
}