public class OpportunityTriggerHandler extends TriggerHandler {

    private List<Opportunity> newList;
    private Map<Id, Opportunity> newMap;
    private Map<Id, Opportunity> oldMap;
  

    public OpportunityTriggerHandler() {
        this.newList = (List<Opportunity>) Trigger.new;
        this.newMap = (Map<Id, Opportunity>) Trigger.newMap;

        if (Trigger.isUpdate) {
            this.oldMap = (Map<Id, Opportunity>) Trigger.oldMap;
            System.debug('OpportunityTriggerHandler - oldMap assigned. Size: ' + (oldMap != null ? oldMap.size() : 0));
        } else {
            System.debug('OpportunityTriggerHandler - Not Update Event');
        }       
    }

    public override void beforeUpdate() {
        System.debug('Entering OpportunityTriggerHandler.beforeUpdate()');
        System.debug('OpportunityTriggerHandler.beforeUpdate() opps list size: ' + newList.size());
    
        if (newList.isEmpty()) {
            System.debug('OpportunityTriggerHandler.beforeUpdate(): No Opportunities Found');
            return;
        }
        
        // Query RecordType Name for all opportunities in newList
        Map<Id, String> oppIdToRecordTypeName = new Map<Id, String>();
        for (Opportunity oppWithRT : [
            SELECT Id, RecordType.Name 
            FROM Opportunity 
            WHERE Id IN :newList
        ]) {
            oppIdToRecordTypeName.put(oppWithRT.Id, oppWithRT.RecordType.Name);
        }
    
        List<Opportunity> oppsForXactlyUpdate = new List<Opportunity>();
        
        for (Opportunity opp : newList) {
            Opportunity oldOpp = this.oldMap != null ? this.oldMap.get(opp.Id) : null;
            System.debug('Evaluating Opportunity: ' + opp);
            System.debug('Old StageName: ' + (oldOpp != null ? oldOpp.StageName : 'null'));
            System.debug('New StageName: ' + opp.StageName);
            System.debug('Project_Number__c: ' + opp.Project_Number__c);
            System.debug('Agreement_Type__c: ' + opp.Agreement_Type__c);
    
            // Logic for ProjectNumberHandler.assignNumbersForOpportunity
            if (opp.StageName == '5 - Closed Won' && (oldOpp == null || oldOpp.StageName != '5 - Closed Won') 
                    && opp.Project_Number__c == null && opp.Agreement_Type__c == 'Standard Agreement') {
                System.debug('Calling ProjectNumberHandler.assignNumbersForOpportunity');
                ProjectNumberHandler.assignNumbersForOpportunity(opp, opp.Parent_Opportunity__c);
            } else {
                System.debug('Criteria not met for ProjectNumberHandler.assignNumbersForOpportunity');
            }
            
            // Logic for BillingManagerAssignmentHelper.updateBillingManager
            if (
                opp != null &&
                opp.StageName == '5 - Closed Won' &&
                (oldOpp == null || oldOpp.StageName != '5 - Closed Won') &&
                opp.Current_Approval_Step__c == 'All Steps Completed' &&
                opp.Billing_Manager__c == null
            ) {
                System.debug('Calling BillingManagerAssignmentHelper.updateBillingManager');
                BillingManagerAssignmentHelper.updateBillingManager(new List<Opportunity>{ opp });
            } else {
                System.debug('Criteria not met for BillingManagerAssignmentHelper.updateBillingManager');
            }

            // Logic for UpdateXactlyAsSold.updateProjects
            String recordTypeName = oppIdToRecordTypeName.get(opp.Id);
            if (opp.StageName == '5 - Closed Won' && (oldOpp == null || oldOpp.StageName != '5 - Closed Won') 
                    && recordTypeName == 'Services') {
                oppsForXactlyUpdate.add(opp);
                System.debug('Opportunity added for Xactly update: ' + opp.Id);
            }
        }
        
        if (!oppsForXactlyUpdate.isEmpty()) {
            UpdateXactlyAsSold.updateProjects(oppsForXactlyUpdate);
        }
    }

	
    /*
    public override void beforeInsert() {
        cleanLeadSourceDetailValues();
    }*/

    public override void afterUpdate() {
        System.debug('Entering OpportunityTriggerHandler.afterUpdate()');
        // Check if running in test context
        if (!updateMadeViaTest()) {
            // Not running in test context, perform permission and endpoint check
            if (userHasBypassPermission() || updateMadeViaCustomOrNativeEndpoint()) {
                System.debug('User has Bypass Permission: ' + userHasBypassPermission());
                System.debug('updateMadeViaCustomOrNativeEndpoint: ' + updateMadeViaCustomOrNativeEndpoint());
                return; // Exit method early if either condition is true
            }
        }
    
        OpportunityRepository opportunityRepository = new OpportunityRepository();
        Map<Id, Opportunity> opportunitiesWithFieldsForValidation = opportunityRepository.findFieldsForOpportunityTriggerValidationByIds(this.newMap.keySet());
        Map<Id, Opportunity> opportunitiesWithFieldsForBackOfficeCallout = opportunityRepository.findAllFieldsForBackOfficeCalloutByIds(this.newMap.keySet());

        OpportunityContactRoleRepository opportunityContactRoleRepository = new OpportunityContactRoleRepository();
        List<OpportunityContactRole> opportunityContactRoles = opportunityContactRoleRepository.findPrimaryContactForOpportunityIds(this.newMap.keySet());
        Map<Id, OpportunityContactRole> opportunityContactRolesIndexedByOpportunityId = new Map<Id, OpportunityContactRole>();
        for (OpportunityContactRole ocr : opportunityContactRoles) {
            opportunityContactRolesIndexedByOpportunityId.put(ocr.OpportunityId, ocr);
        }

        ContactRepository contactRepository = new ContactRepository();
        Set<Id> contactIds = new Set<Id>();
        for (OpportunityContactrole ocr : opportunityContactRoles) {
            contactIds.add(ocr.ContactId);
        }
        Map<Id, Contact> contacts = contactRepository.findFieldsForOpportunityTriggerValidationByIds(contactIds);

        List<Opportunity_BO_Sync__e> oppBoSyncEvents = new List<Opportunity_BO_Sync__e>();

        for(Opportunity opp : this.newList) {
            Opportunity oppWithFields = opportunitiesWithFieldsForValidation.get(opp.Id);
            Contact oppPrimaryContact = contacts.get(oppWithFields.ContactId);

            // [SD-693] Before an Opportunity can be registered in the BO, the Broker and the Market fields must both have valid data.
            // We just need to make sure that the Broker field cannot be "Patriot" if the Market field has a value of "ISO-NE CT". 
            //
            // Disabled 05/Feb/2024 as requested by Chris Page: 
            /* if (
                oppWithFields.RecordType.Name == 'Energy' && 
                oppWithFields.Broker__c != null &&
                oppWithFields.Broker__r.Name.contains('Patriot') &&
                oppWithFields.Market__c != null &&
                oppWithFields.Market__r.Name.contains('ISO-NE CT')
            ) {
                opp.addError('The Opportunity Broker field cannot be "Patriot" if the Opportunity Market field has a value of "ISO-NE CT".');
                continue;
            } */

            // Doesn't send this opportunity to the BO if it isn't an Energy opportunity or if it wasn't registered before
            if (oppWithFields.RecordType.Name != 'Energy' || oppWithFields.Registered_in_Back_Office__c == false) continue;

            // Checks if the opportunity is an Energy opportunity and if it has a primary contact (BO requires a primary contact)
            if (oppWithFields.RecordType.Name == 'Energy' && !opportunityContactRolesIndexedByOpportunityId.containsKey(opp.Id)) {
                opp.addError('Please add a Primary Contact to this Opportunity.');
                continue;
            }

            // Checks if the opportunity is an Energy opportunity and if the opportunity's primary contact has a Phone (BO requires the contact to have a phone number)
            if (oppWithFields.RecordType.Name == 'Energy' && String.isBlank(oppPrimaryContact.Phone)) {
                opp.addError('Please add a Phone to this Opportunity\'s Primary Contact.');
                continue;
            }
            
            // Generate platform event
            Opportunity_BO_Sync__e newOppBoSyncEvent = new Opportunity_BO_Sync__e();
            newOppBoSyncEvent.Opportunity_ID__c = opp.Id;
            newOppBoSyncEvent.Sync_User_ID__c = UserInfo.getUserId();

            oppBoSyncEvents.add(newOppBoSyncEvent);
        }

        publishOppBoSyncEvents(oppBoSyncEvents);
    }

    private void publishOppBoSyncEvents(List<Opportunity_BO_Sync__e> oppBoSyncEvents) {
        // Call method to publish events
        List<Database.SaveResult> results = EventBus.publish(oppBoSyncEvents);

        // Inspect publishing result for each event
        for (Database.SaveResult sr : results) {
            if (sr.isSuccess()) {
                System.debug('Successfully published event.');
            } else {
                for (Database.Error err : sr.getErrors()) {
                    System.debug('Error returned: ' + err.getStatusCode() + ' - ' + err.getMessage());
                }
            }
        }
    }

    private Boolean userHasBypassPermission() {
        return FeatureManagement.checkPermission('Bypass_Opportunity_trigger');
    }

    private Boolean updateMadeViaCustomOrNativeEndpoint() {
        String callingURL = System.URL.getCurrentRequestUrl().getPath();
        system.debug('PathUrl: ' + System.URL.getCurrentRequestUrl().getPath());
        return callingURL.contains('/services/apexrest/') || callingURL.contains('/services/data');
    }
    
    private Boolean updateMadeViaTest(){
        Boolean isTest = Test.isRunningTest();
        Return isTest;
    }

    /*private void cleanLeadSourceDetailValues() {
        for (Opportunity opp : newList) {
            if (DependentPicklistValueInvocable.checkDependentPicklistValue(
                    'Opportunity',
                    'LeadSource',
                    'Lead_Source_Detail__c',
                    opp.LeadSource,
                    opp.Lead_Source_Detail__c
                )) 
            {
                // Lead_Source_Detail__c value is compatible with LeadSource value
                continue;
            }
            
			System.debug('LeadSource: ' + opp.LeadSource);
			System.debug('Lead_Source_Detail__c: ' + opp.Lead_Source_Detail__c);

            System.debug('Setting Lead_Source_Detail__c to null since the previous value \'' + opp.Lead_Source_Detail__c + '\' was not compatible with the LeadSource value \'' + opp.LeadSource + '\'');
            opp.Lead_Source_Detail__c = null;
        }
    }*/

}