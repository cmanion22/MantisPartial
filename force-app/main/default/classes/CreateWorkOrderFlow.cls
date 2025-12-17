global class CreateWorkOrderFlow {
	@InvocableMethod
	public static void createDefectSectionLineItem(List<String> WID){
       
       if(WID.size() > 0){
           WorkOrder WO = [select Id, Defects__c, Sections__c, Work_Template__c, WorkTypeID, Sections_Name__c from WorkOrder where Id =:WID[0]];
           String woDefects = WO.Defects__c;
           If (woDefects != null){
                List<String> defectGUIDs = woDefects.split(';');
                List<Defect__c> defects = [SELECT Id, DefGUID__c FROM Defect__c WHERE DefGUID__c IN :defectGUIDs];
                Map<String, Defect__c> defectByDefectGUID = new Map<String, Defect__c>();
                for (Defect__c defect : defects) {
                    defectByDefectGUID.put(defect.DefGUID__c, defect);
                }

                List<Work_Order_Defect_Junction__c> WODJ = new List<Work_Order_Defect_Junction__c>();

                for(String a : defectGUIDs) {
                    WODJ.add(new Work_Order_Defect_Junction__c(Work_Order__c = WO.Id, Defect__c = a, Defect2__c = defectByDefectGUID.get(a).Id));
                }
               insert WODJ;
           }
           
           String woSections = WO.Sections__c;
           String sectionName = WO.Sections_Name__c;
           If (woSections != null){
               List<String> sectionGUIDs = woSections.split(';');  
               List<String> sectionsName = sectionName.split(';');
               List<Section__c> sections = [SELECT Id, SectionGUID__c FROM Section__c WHERE SectionGUID__c IN :sectionGUIDs];
                Map<String, Section__c> sectionBySectionGUID = new Map<String, Section__c>();
                for (Section__c section : sections) {
                    sectionBySectionGUID.put(section.SectionGUID__c, section);
                }
               List<Work_Order_Section_Junction__c> WOSJ = new List<Work_Order_Section_Junction__c>();
               for(Integer i=0; i<sectionGUIDs.size();i++){
                  WOSJ.add(new Work_Order_Section_Junction__c(Work_Order__c=WO.Id, Section2__c = sectionBySectionGUID.get(sectionGUIDs[i]).Id, Section_Name__c=sectionsName[i]));
               }
               insert WOSJ;
           }
           
           String WorkTemplateId = WO.Work_Template__c;
           if(WorkTemplateId != null){
               List<WorkOrderLineItem> WOLI = new List<WorkOrderLineItem>();
               List<Work_Template_Line_Item__c> WTLI = [select Id, Description__c from Work_Template_Line_Item__c where Work_Template__c =:WorkTemplateId];
               for(Work_Template_Line_Item__c i : WTLI){
                   WOLI.add(new WorkOrderLineItem(description = i.Description__c, WorkOrderId=WO.Id, WorkTypeId = WO.WorkTypeId));
               }
               if(WOLI != null){
                   insert WOLI;	
               }
           }
       }
	}
}