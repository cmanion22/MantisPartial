trigger UpdateStatusOnAcceptReject on ServiceAppointment(before update) {
    for(ServiceAppointment srNew : Trigger.New){
        ServiceAppointment srOld = Trigger.oldMap.get(srNew.Id);
		System.debug('ABCD : '+srNew.Accept_Reject_Work__c+' ; '+srOld.Accept_Reject_Work__c);
        if((srNew.Accept_Reject_Work__c != srOld.Accept_Reject_Work__c) && srOld.Accept_Reject_Work__c != null ){
            if(srOld.Accept_Reject_Work__c == 'Accept' && srNew.Accept_Reject_Work__c == 'Reject'){
                srNew.addError('Cannot Reject After Accepting!');
            }
            if(srOld.Accept_Reject_Work__c == 'Reject' && srNew.Accept_Reject_Work__c == 'Accept'){
                srNew.addError('Cannot Accept After Rejecting!');
            }
            if((srOld.Accept_Reject_Work__c == 'Reject' || srOld.Accept_Reject_Work__c == 'Accept') && srNew.Accept_Reject_Work__c == null){
                srNew.addError('Cannot set to None in Accept/Reject Work!!');
            }
        }
        
        if(srNew.Accept_Reject_Work__c == 'Accept' && srNew.Status == 'Dispatched' && (srNew.Accept_Reject_Work__c != srOld.Accept_Reject_Work__c)){
            srNew.Status = 'Accepted';
        }
        
        if(srNew.Accept_Reject_Work__c == 'Reject' && srNew.Status == 'Dispatched' && (srNew.Accept_Reject_Work__c != srOld.Accept_Reject_Work__c)){
            srNew.Status = 'Rejected';
        }
        
        if(srOld.Status != srNew.Status){
            if((srNew.Status == 'In Progress' || srNew.Status == 'Accepted') && srOld.Accept_Reject_Work__c == null){
                srNew.Accept_Reject_Work__c = 'Accept';
            }
            if(srNew.Status == 'Rejected' && srOld.Accept_Reject_Work__c == null){
                srNew.Accept_Reject_Work__c = 'Reject';            
            }
            if(srNew.Status == 'Exceed NTE'){
                srNew.Accept_Reject_Work__c = null;
            }
        }
    }
}