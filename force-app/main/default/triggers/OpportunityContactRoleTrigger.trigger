trigger OpportunityContactRoleTrigger on OpportunityContactRole (after insert, after update, before delete) {
    Turn_off_Processes__c processSettings = Turn_off_Processes__c.getValues('migration in progress');

    if (processSettings != null) {
        if ((Trigger.isInsert || Trigger.isUpdate) && Trigger.isAfter) {
            System.debug('OpportunityContactRoleTrigger-->Trigger.new-->' + Trigger.new);
            for (OpportunityContactRole ocr : Trigger.new) {
                Opportunity opp = OpportunityHelper.getOpportunity(ocr.OpportunityId);

                if (opp.RecordType.Name!='Services') {
                    if (ocr.IsPrimary) {
                        if (ContactHelper.validatePrimaryContact(ocr.ContactId)) {
                            System.debug('OpportunityContactRoleTrigger->calling ContactHelper.updatePrimaryContact-->' + ocr.ContactId);
                            ContactHelper.updatePrimaryContact(ocr.ContactId);
                            if (Test.isRunningTest()) {
                                System.debug('OpportunityContactRoleTrigger-->Test.RunningTest()');
                                Test.setMock(HttpCalloutMock.class, new HttpEmexCalloutMock(200, 'OK', '{success:true}'));
                            } else {
                                System.debug('OpportunityContactRoleTrigger->calling OpportunityCalloutClass.updateOpportunity');
                                OpportunityCalloutClass.updateOpportunity(opp.ID, UserInfo.getUserId());
                            }
                        } else {
                            ocr.addError('Please ensure that this Primary Contact has data in the following fields: ' +
                            'First Name, Last Name, Email, Phone Number, Contact Address (Street, City and Zip Code)');
                        }
                    }
                }
            }
        }

        if (Trigger.isDelete && Trigger.isBefore) {
            System.debug('OpportunityContactRole-->isDelete-->isBefore');
            for (OpportunityContactRole ocr: Trigger.old) {
                Opportunity opp = OpportunityHelper.getOpportunity(ocr.OpportunityId);
                System.debug('IsPrimary-->' + ocr.IsPrimary);
                System.debug('Registered_in_Back_Office__c-->' + opp.Registered_in_Back_Office__c);
                if (ocr.IsPrimary && opp.Registered_in_Back_Office__c) {
                    ocr.addError('This Opportunity is registered in the Back Office, and must have a Primary Contact. Please use the Edit Contact Roles feature to set a new Primary Contact before deleting.'); 
                }
            }
        }
    }
}