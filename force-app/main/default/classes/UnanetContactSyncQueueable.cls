public with sharing class UnanetContactSyncQueueable implements Queueable, Database.AllowsCallouts {

    private Id contactId;
    private Id opportunityId;
    private String orgKey;
    private String token;

    public UnanetContactSyncQueueable(Id contactId, Id opportunityId, String orgKey, String token) {
        this.contactId = contactId;
        this.opportunityId = opportunityId;
        this.orgKey = orgKey;
        this.token = token;
    }

    public void execute(QueueableContext context) {
        try {
            Contact con = [
                SELECT Id, Email, FirstName, LastName, Unanet_Id__c, Title, Phone, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry
                FROM Contact
                WHERE Id = :contactId
                LIMIT 1
            ];

            if (String.isBlank(con.Email)) {
                logError('UnanetContactSyncQueueable', 'Contact email is blank. Skipping sync.', con.Id);
                return;
            }

            if (String.isBlank(token)) {
                logError('UnanetContactSyncQueueable', 'Unanet token is blank. Aborting.', con.Id);
                return;
            }

            String baseUrl = UnanetHelper.getUnanetBaseUrl();
            Integer existingKey = UnanetHelper.getOrgContactKey(con, token, baseUrl, orgKey);

            if (existingKey != null) {
                // Sync the Unanet Key if Salesforce doesn't have it yet
                if (String.isBlank(con.Unanet_Id__c)) {
                    con.Unanet_Id__c = String.valueOf(existingKey);
                    update con;
                    System.debug('Updated Contact with existing Unanet Key: ' + existingKey);
                } else {
                    System.debug('Contact already exists and Unanet ID matches. No update needed.');
                    if (!Test.isRunningTest()) {
                        System.debug('System.enqueueJob(new UnanetProjectSyncQueueable opportunityId: ' + opportunityId);
                    	System.enqueueJob(new UnanetProjectSyncQueueable(opportunityId, token));
                    }
                    
                }
            } else {
                // If contact doesn't exist, create it
                Integer orgKeyInt = Integer.valueOf(orgKey); 
                String unanetId = UnanetHelper.createContact(con, token, baseUrl, orgKeyInt);

                if (!String.isBlank(unanetId)) {
                    if (!Test.isRunningTest()) {
                        System.debug('System.enqueueJob(new UnanetProjectSyncQueueable opportunityId: ' + opportunityId);
                    	System.enqueueJob(new UnanetProjectSyncQueueable(opportunityId, token));
                    }
                    
                    con.Unanet_Id__c = unanetId;
                    update con;
                    System.debug('Contact created in Unanet and updated locally with ID: ' + unanetId);
                } else {
                    logError('UnanetContactSyncQueueable', 'Unanet Contact creation failed. No ID returned.', con.Id);
                }
            }

        } catch (Exception e) {
            logError('UnanetContactSyncQueueable', 'Exception: ' + e.getMessage(), contactId);
        }
    }

    private void logError(String name, String description, Id relatedId) {
        try {
            insert new Data_Log__c(
                Description__c       = description,
                Related_Record_Id__c = relatedId,
                Log_Origin__c        = name
            );
        } catch (Exception e) {
            System.debug('Failed to insert Data_Log__c: ' + e.getMessage());
        }
    }
}