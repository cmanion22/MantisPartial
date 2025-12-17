global class createMaintenancePlanFlow {
	@InvocableMethod
	public static void createDefectSectionLineItemForMP(List<MaintenancePlan> w){
       if(w.size() > 0){
           String section = w[0].Section__c;
           If (section != null){
               List<String> sections = section.split(';');                    
               List<Maint_Defect_Junction__c> WOSJ = new List<Maint_Defect_Junction__c>();
                    
               for(String a : sections){
                  WOSJ.add(new Maint_Defect_Junction__c(Maintenance_Plan__c = w[0].Id, 	Section__c = a));
               }
               insert WOSJ;
           }
       }
	}
}