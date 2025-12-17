public class OpportunityHelper {
    @TestVisible private static Broker__c getTestBroker() {
        Broker__c testBroker = new Broker__c();
        Uuid brokerUuid = new Uuid();
        String brokerUuidValue = brokerUuid.getValue();
        testBroker.Name = 'Test Broker ' + brokerUuidValue;
        testBroker.Source_ID__c = 'Source Id ' + brokerUuidValue;
        testBroker.Source_Database__c = 'Source DB ' + brokerUuidValue;
        insert testBroker;

        return testBroker;
    }

    public static Opportunity getOpportunity(ID opportunityId) {
        // Set the body as a JSON object               
        String qry = Helper.generateSelectQuery('Opportunity') + ' WHERE Id =:opportunityId';      
        System.debug('OpportunityHelper-->getOpportunity-->Query-->' + qry);
        Opportunity opportunity = database.query(qry);

        System.debug('OpportunityHelper-->getOpportunity-->opportunity-->' + opportunity);                           
        return opportunity;
    }
    
    public static ID getAccountId(ID opportunityId) 
    {
        System.debug('OpportunityHelper-->getAccountId-->opportunityId-->' + opportunityId);                      
        return [SELECT AccountId FROM Opportunity WHERE Id = :opportunityId].AccountId; 
    }

    public static String postUpdateOpportunityJson(Id opportunityId, Id syncUserId) {
        System.debug('OpportunityHelper-->postUpdateOpportunityJson-->opportunityId --> ' + opportunityId);
        
        String body = 
            '{"event": "update_opportunity"' +
            ', "data": {' +
                '"opportunity": { "Id": "' + opportunityId + '" }' +
            '}' +
            '}';

        System.debug('OpportunityHelper-->postUpdateOpportunityJson-->Body -->' + body);
        System.enqueueJob(new HttpRetryAsync(ESBController.getESBUrl(syncUserId), 'POST', body, 'UpdateOpportunity', opportunityId));

        return body;
    }

    public static Opportunity upsertOpportunity(Map<String, Object> compositeMapObjects, ID accountId, ID contactId) 
    {        
        Map<String, Object> opportunityMap = (Map<String, Object>)compositeMapObjects.get('opportunity');       
        System.debug('OpportunityHelper-->upsertOpportunity-->opportunityMap -->' + opportunityMap);
        Opportunity thisOpportunity = new Opportunity();        
        Boolean isPartnerAccount = false;
        
        // Iterate through each parameter field and value
        for(String fieldName : opportunityMap.keySet()) {
                        
            System.debug(fieldName + '-' + opportunityMap.get(fieldName));
            if((fieldName == 'CloseDate' || fieldName == 'Expected_Contract_Start__c' 
            || fieldName == 'Current_Provider_Contract_End__c') && opportunityMap.get(fieldName) != NULL)
            {
                String temp = opportunityMap.get(fieldName).toString();
                Date myDate = Date.valueOf(temp);
                System.debug('OpportunityHelper-->upsertOpportunity-->mydate -->' + mydate);
                thisOpportunity.put(fieldName, myDate);
            }
            else if (fieldName == 'Partner_Account__c')
            {
                System.debug('OpportunityHelper-->upsertOpportunity-->Partner_Account__c-->' + fieldName);
                isPartnerAccount = true;
                thisOpportunity.put(fieldName, opportunityMap.get(fieldName));
            }
            else if (fieldName == 'Primary_Contact__c')
            {
                // After the OpportunityContactRole record is updated, a PB updates the Primary_Contact__c field in the Opportunity to the new Primary Contact.
                // Due to order of execution, this field isn't synced by the OpportunityContactRole trigger to the Back Office.
                // Since the Back Office doesn't have the latest value for this field, it should be ignored here.
                continue;
            }
            else
            {
                // Set the field and value on the Opportunity sObject
                thisOpportunity.put(fieldName, opportunityMap.get(fieldName));
            }
        }
        thisOpportunity.Registered_in_Back_Office__c = true;
        thisOpportunity.put('AccountId', accountId);
        thisOpportunity.put('RecordTypeId', getRecordTypeId(isPartnerAccount));
        
        System.debug('OpportunityHelper-->upsertOpportunity-->thisOpportunity -->' + thisOpportunity);
        upsert thisOpportunity;
        
        System.debug('OpportunityHelper-->upsertOpportunity-->thisOpportunity.Id -->' + thisOpportunity.Id);        
        return thisOpportunity;
    } 
    
    public static Opportunity setBackOfficeFlagSuccess(ID opportunityId) 
    {
        System.debug('OpportunityHelper->setBackOfficeFlag');
        
        Helper.LockRecord(opportunityId);
        
        SObject record = Helper.getSObject(opportunityId);
        record.put('Registered_in_Back_Office__c',true);
        record.put('Sync_Error__c', 'Registration to BackOffice is successful');
        record.put('SyncMessageDisplay__c', true );
        
        System.debug('OpportunityHelper-->Update_Opportunity_BackOffice_Flag-->Registered_in_Back_Office__c flag set to true' );
        update record;
        
        Helper.UnlockRecord(opportunityId);
        
        return (Opportunity)record;
    } 
    
    public static Opportunity setBackOfficeFlagError(ID opportunityId, string error, string jsonBody)
    {
        System.debug('OpportunityHelper->setBackOfficeFlagError');
        
        Helper.LockRecord(opportunityId);
        
        SObject record = Helper.getSObject(opportunityId);
        record.put('Registered_in_Back_Office__c',false);
        record.put('Sync_Error__c', 'Error in registering Opportunity to Backoffice: ' + error);
        record.put('SyncMessageDisplay__c', true );
        
       
        System.debug('OpportunityHelper-->Update_Opportunity_BackOffice_Flag_Error-->Registered_in_Back_Office__c flag set to FALSE' );
        update record;
        
        Helper.UnlockRecord(opportunityId);
        
        return (Opportunity)record;
    }
    
    public static ID getRecordTypeId(Boolean isPartnerAccount)
    {
        String recordTypeName = 'Energy';
        
        String qry = Helper.generateSelectQuery('RecordType') + ' WHERE NAME =:recordTypeName';      
        System.debug('OpportunityHelper-->getRecordTypeId->Query-->' + qry);
        
        RecordType recordType = database.query(qry);
        System.debug('OpportunityHelper-->getRecordTypeId-->recordType-->' + recordType);
        System.debug('OpportunityHelper-->getRecordTypeId-->recordType.Id-->' + recordType.ID);
        
        return recordType.ID;
    }
}