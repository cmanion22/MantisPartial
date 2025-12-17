public class CreateWorkOrderLineItems {

    public static void createLineItems(String templateID, String WOID, String MPID, Date SuggestedMaintenanceDate){
        if(templateID != null){
               List<WorkOrderLineItem> WOLI = new List<WorkOrderLineItem>();
               List<Work_Template_Line_Item__c> WTLI = [select Id, Description__c from Work_Template_Line_Item__c where Work_Template__c =:templateID];
               for(Work_Template_Line_Item__c i : WTLI){
                   WOLI.add(new WorkOrderLineItem(description = i.Description__c, MaintenancePlanId=MPID, 
                                                  WorkOrderID=WOID, SuggestedMaintenanceDate=SuggestedMaintenanceDate));
               }
               insert WOLI;
           }
    }
}