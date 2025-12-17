public class CreateOpportunityRecord {
	@AuraEnabled
    public string defaultRecordTypeId {get; set;}
    @AuraEnabled
    public Map<Id, String> contactRecordTypes {get; set;}
    
    public class Wrapper{
        @AuraEnabled
        public String accountId {get; set;}
        @AuraEnabled
        public String parentConsultantId {get; set;}
    }
    
    @AuraEnabled
    public static Wrapper getAccountId(String recordTypeId, String childRecordName){
        try{
            if(recordTypeId!=null && String.isNotBlank(recordTypeId)){
                Wrapper wrapperObj = new Wrapper();
                Opportunity oppObj = [Select Id,AccountId from Opportunity where Id=:recordTypeId];
                if(oppObj!=null){ 
                    wrapperObj.accountId = oppObj.AccountId;
                }
                Parent_Consultative_Opportunity__c parentConsultativeOpp = new Parent_Consultative_Opportunity__c();
                parentConsultativeOpp.Opportunity__c = recordTypeId;
                if(childRecordName!=null && String.isNotBlank(childRecordName)){
                    parentConsultativeOpp.Name = childRecordName;
                }
                insert parentConsultativeOpp;
                if(parentConsultativeOpp!=null){
                    wrapperObj.parentConsultantId = parentConsultativeOpp.Id;
                }
                return wrapperObj;
            }
        }
        catch(Exception ex){
            
        }
        return null;
    }
    
    @AuraEnabled        
    public static CreateOpportunityRecord getRecordTypeValues(){
        CreateOpportunityRecord obj = new CreateOpportunityRecord();
        Map<Id, String> recordtypeMap = new Map<Id, String>();
        //Get all record types of Contact object
        List<Schema.RecordTypeInfo> recordTypeInfoList = Opportunity.SObjectType.getDescribe().getRecordTypeInfos();
        for(RecordTypeInfo info: recordTypeInfoList) {
            //Check record type is available for current user profile
            if(info.isAvailable()) {
                //Check master record type
                if(info.getName().trim() != ''){
                    recordtypeMap.put(info.getRecordTypeId(), info.getName());
                }
                //Get the default record type for current user profile
                if(info.isDefaultRecordTypeMapping()){
                    obj.defaultRecordTypeId = info.getRecordTypeId();
                }
            }
        }    
        obj.contactRecordTypes = recordtypeMap;
        return obj;
    }
}