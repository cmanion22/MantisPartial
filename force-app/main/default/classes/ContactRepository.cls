/**
 * @author Gustavo Pupo
 */
public virtual class ContactRepository {

    virtual
    public Map<Id, Contact> findFieldsForOpportunityTriggerValidationByIds(Set<Id> contactIds) {
        return new Map<Id, Contact>([SELECT Id, Phone FROM Contact WHERE Id IN :contactIds]);
    }

    virtual
    public Database.QueryLocator getQueryLocatorForResyncToBackOffice() {

        String query = ' SELECT ';
        Map<String, Schema.SObjectField> objectFields = Schema.getGlobalDescribe().get('Contact').getDescribe().fields.getMap();

        // Grab the fields from the describe method and append them to the queryString one by one.
        for (String field : objectFields.keySet()) {
            if (field == 'Pending_Resync_to_Back_Office__c') continue;
            query += ' ' + field + ', ';
        }

        // Strip off the last comma
        if (query.substring(query.length() - 2, query.length()).trim() == ',') {
            query = query.substring(0, query.length() - 2);
        }

        query += ' FROM Contact ';
        query += ' WHERE Pending_Resync_to_Back_Office__c = true ';

        return Database.getQueryLocator(query);
    }

}