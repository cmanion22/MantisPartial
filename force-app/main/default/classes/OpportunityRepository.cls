/**
 * @author Gustavo Pupo
 */
public virtual class OpportunityRepository {

    virtual
    public Map<Id, Opportunity> findFieldsForOpportunityTriggerValidationByIds(Set<Id> opportunityIds) {
        return new Map<Id, Opportunity>([SELECT Id, ContactId, RecordType.Name, Registered_in_Back_Office__c, Market__c, Market__r.Name, Broker__c, Broker__r.Name FROM Opportunity WHERE Id IN :opportunityIds]);
    }

    virtual
    public Map<Id, Opportunity> findAllFieldsForBackOfficeCalloutByIds(Set<Id> opportunityIds) {
        Map<Id, Opportunity> recordsIndexedById = new Map<Id, Opportunity>();

        String query = 'SELECT';
        Map<String, Schema.SObjectField> objectFields = Schema.getGlobalDescribe().get('Opportunity').getDescribe().fields.getMap();

        // Grab the fields from the describe method and append them to the queryString one by one.
        for (String field : objectFields.keySet()) {
            query += ' ' + field + ', ';
        }

        // Field required only for the Opportunity object
        query += 'RecordType.Name ';

        // Strip off the last comma if it exists.
        if (query.substring(query.length() - 2, query.length()).trim() == ',') {
            query = query.substring(0, query.length() - 2);
        }

        query += ' FROM Opportunity ';
        query += ' WHERE Id IN ( ';

        for (Id opportunityId : opportunityIds) {
            query += '\'' + opportunityId + '\', ';
        }

        // Strip off the last comma if it exists.
        if (query.substring(query.length() - 2, query.length()).trim() == ',') {
            query = query.substring(0, query.length() - 2);
        }

        query += ' ) ';

        List<Opportunity> opportunities = Database.query(query);

        for (Opportunity opportunity : opportunities) {
            recordsIndexedById.put(opportunity.Id, opportunity);
        }

        return recordsIndexedById;
    }

}