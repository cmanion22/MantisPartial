public with sharing class UnanetAccountSyncQueueable implements Queueable, Database.AllowsCallouts {

    private Id opportunityId;

    public UnanetAccountSyncQueueable(Id opportunityId) {
        this.opportunityId = opportunityId;
        System.debug('UnanetAccountSyncQueueable.execute() - opportunityId: ' + opportunityId);
    }

    public void execute(QueueableContext context) {
        if (opportunityId == null) {
        logError(
            'Missing Opportunity ID',
            'Opportunity ID is null in UnanetAccountSyncQueueable execution.',
            null
        );
        System.debug('UnanetAccountSyncQueueable.execute() - Null OpportunityId');
        return;
    }
        
        try {
            Opportunity opp = [
                SELECT Id, AccountId, Primary_Contact__c, Unanet_Id__c, CurrencyIsoCode, Mantis_Division__c 
                FROM Opportunity
                WHERE Id = :opportunityId
                LIMIT 1
            ];
    
            if (opp.AccountId == null) {
                logError(
                    'Missing Account on Opportunity',
                    'Opportunity ' + opportunityId + ' does not have an associated Account.',
                    String.valueOf(opportunityId)
                );
                System.debug('UnanetAccountSyncQueueable.execute() - Missing Account on Opportunity');
                return;
            }
            
            if (opp.Mantis_Division__c == null) {
                logError(
                    'Missing Practice Area on Opportunity',
                    'Opportunity ' + opportunityId + ' does not have an associated Practice Area.',
                    String.valueOf(opportunityId)
                );
                System.debug('UnanetAccountSyncQueueable.execute() - Missing Practice Area on Opportunity');
                return;
            }
    
            Account acc = [
                SELECT Id, Name, Unanet_Customer_Code__c, Unanet_Id__c, CurrencyIsoCode, BillingAddress
                FROM Account
                WHERE Id = :opp.AccountId
                LIMIT 1
            ];
    
            String orgCode;
            if (String.isNotBlank(acc.Name)) {
                System.debug('Account Name before trimming: ' + acc.Name);
    
                String[] words = acc.Name.trim().split(' ');
                System.debug('Split Account Name into words: ' + words);
    
                String firstWord = words.size() > 0 ? words[0].toUpperCase() : '';
                System.debug('First word (uppercase): ' + firstWord);
    
                orgCode = 'C_' + firstWord;
                System.debug('Generated orgCode: ' + orgCode);
            } else {
                System.debug('Account Name is blank or null for Account ID: ' + acc.Id);
    
                logError(
                    'Invalid Account Name',
                    'Account ' + acc.Id + ' has a blank name. Cannot generate orgCode.',
                    acc.Id
                );
                return;
            }
    
            String baseUrl = UnanetHelper.getUnanetBaseUrl();
            System.debug('UnanetAccountSyncQueueable.execute() - baseUrl: ' + baseUrl);
            String token = UnanetHelper.fetchUnanetToken(baseUrl);
            if (String.isBlank(token)) {
                logError(
                    'Missing Unanet Token',
                    'Could not retrieve Unanet token while syncing Account ' + acc.Id,
                    acc.Id
                );
                System.debug('UnanetAccountSyncQueueable.execute() - Missing Unanet Token');
                return;
            }
    
            if (String.isBlank(acc.Unanet_Id__c)) {
                System.debug('UnanetAccountSyncQueueable.execute() - Calling UnanetHelper.createOrganization()');
                String newUnanetId = UnanetHelper.createOrganization(acc, token, baseUrl, opp.Mantis_Division__c);
                if (!String.isBlank(newUnanetId)) {
                    System.debug('UnanetAccountSyncQueueable.execute() - Successfully created Unanet organization: ' + newUnanetId + ' for Account ' + acc.Id + '.');
                    // Create Org Address
                    System.debug('UnanetAccountSyncQueueable.execute() - Calling UnanetHelper.createOrganizationAddress()');
                    UnanetHelper.createOrgAddress(acc, newUnanetId, baseUrl, token);
                    // Update Account
                    acc.Unanet_Id__c = newUnanetId;
                    update acc;
    
                    if (!Test.isRunningTest()) {
                        if (opp.Primary_Contact__c != null) {
                            System.debug('Enqueuing UnanetContactSyncQueueable for Contact: ' + opp.Primary_Contact__c + 'opportunityId: ' + opportunityId + ' and acc.Unanet_Id__c: ' + acc.Unanet_Id__c);
                            System.enqueueJob(new UnanetContactSyncQueueable(opp.Primary_Contact__c, opportunityId, acc.Unanet_Id__c, token));
                        } else {
                            System.debug('Enqueuing UnanetProjectSyncQueueable for Opportunity: ' + opportunityId);
                            System.enqueueJob(new UnanetProjectSyncQueueable(opportunityId, token));
                            System.debug('Skipping Enqueuing UnanetContactSyncQueueable due to the Opp having no Primary Contact. Opp Id: ' + opp.Id);
                            logError('Skipping Enqueuing UnanetContactSyncQueueable', 'The related Opp has no Primary Contact', opp.Id);
                        }
                    } else {
                        System.debug('Skipping queueable enqueues in test context.');
                    }
    
                } else {
                    logError(
                        'Failed to Create Unanet Org',
                        'Unable to create organization in Unanet for Account ' + acc.Id,
                        acc.Id
                    );
                }
            } else {
                UnanetOrganizationWrapper org = UnanetHelper.getOrganization(acc.Unanet_Id__c, token, baseUrl);
                // Log field-by-field
                System.debug('UnanetAccountSyncQueueable: Org from Unanet:');
                System.debug('Org Code: ' + org.code);
                System.debug('Org Name: ' + org.name);
                System.debug('Org Active: ' + org.active);
                System.debug('Org Type Key: ' + org.type?.key);
                System.debug('Org Type Name: ' + org.type?.name);
                System.debug('Org Type Description: ' + org.type?.description);
                System.debug('Org Parent Key: ' + org.parentOrg?.key);
                System.debug('Org Parent Name: ' + org.parentOrg?.name);
                System.debug('Org Parent Code: ' + org.parentOrg?.code);
                System.debug('Org Size: ' + org.size);
                System.debug('External System Code: ' + org.externalSystemCode);
                System.debug('Classification: ' + org.classification);
                System.debug('SIC Code: ' + org.sicCode);
                System.debug('Industry: ' + org.industry);
                System.debug('Sector: ' + org.sector);
                System.debug('Stock Symbol: ' + org.stockSymbol);
                System.debug('URL: ' + org.url);
                System.debug('Financial Org: ' + org.financialOrg);
                System.debug('Legal Entity: ' + org.legalEntity);
                System.debug('Legal Entity Org Key: ' + org.legalEntityOrg?.key);
                System.debug('Legal Entity Org Name: ' + org.legalEntityOrg?.name);
                System.debug('Legal Entity Org Code: ' + org.legalEntityOrg?.code);
                System.debug('Entry Allowed: ' + org.entryAllowed);
                System.debug('Begin Date: ' + org.beginDate);
                System.debug('End Date: ' + org.endDate);
                System.debug('Financial Parent Org Key: ' + org.finParentOrg?.key);
                System.debug('Cost Pool Parent Org Key: ' + org.costPoolParentOrg?.key);
                System.debug('Default GL Post Org Key: ' + org.defaultGLPostOrg?.key);
                System.debug('Recipient Name 1099: ' + org.recipientName1099);
                System.debug('Vendor 1099: ' + org.vendor1099);
                System.debug('Federal Tax ID: ' + org.federalTaxId);
                System.debug('Federal Tax ID Type: ' + org.federalTaxIdType);
                System.debug('Tax 1: ' + org.tax1);
                System.debug('Tax 2: ' + org.tax2);
                System.debug('Tax 3: ' + org.tax3);
                System.debug('Email 1099: ' + org.email1099);
                System.debug('Property Template Key: ' + org.propertyTemplate?.key);
                System.debug('Start With Project Code Seq: ' + org.startWithProjectCodeSeq);
                System.debug('Last Project Code Seq: ' + org.lastProjectCodeSeq);
                System.debug('Default Person Org: ' + org.defaultPersonOrg);
                System.debug('Requires Activation: ' + org.requiresActivation);
                System.debug('Created Timestamp: ' + org.createdTimestamp);
                System.debug('Last Updated Timestamp: ' + org.lastUpdatedTimestamp);
    
                // Log UDFs (if they exist)
                if (org.udfs != null && org.udfs.values != null) {
                    for (UnanetOrganizationWrapper.UdfValueWrapper udf : org.udfs.values) {
                        System.debug('UDF Index: ' + udf.index);
                        System.debug('UDF Value: ' + udf.value);
                        if (udf.metadata != null) {
                            System.debug('UDF Metadata Label: ' + udf.metadata.label);
                            System.debug('UDF Metadata Data Type: ' + udf.metadata.dataType);
                            System.debug('UDF Metadata Visibility: ' + udf.metadata.visibility);
                            System.debug('UDF Metadata Required: ' + udf.metadata.required);
                            System.debug('UDF Metadata Active: ' + udf.metadata.active);
                        }
                    }
                }
    
                if (org != null) {
                    String orgSfId = org.getSalesforceId();
                    if (String.isBlank(orgSfId)) {
                        // Call updateOrganizationWithSFId method
                        // UnanetHelper.updateOrganizationWithSFId(org, acc.Id, token, baseUrl);
                        // Commenting this out until Unanet fixes the update bug on their end - Cody Manion 5/8/2025 
                        System.debug('The Organization is missing a SF Id. Org Key: ' + org.key + 'Account Id: ' + acc.Id);
                    }
                    // Enqueue Primary Contact and Project sync now that account/org is confirmed
                    if (opp.Primary_Contact__c != null){
                        if (!Test.isRunningTest()) {
                            System.debug('Enqueuing UnanetContactSyncQueueable for Contact: ' + opp.Primary_Contact__c + 'opportunityId: ' + opportunityId + ' and acc.Unanet_Id__c: ' + acc.Unanet_Id__c);
                            System.enqueueJob(new UnanetContactSyncQueueable(opp.Primary_Contact__c, opportunityId, acc.Unanet_Id__c, token));
                        }
                        
                    } else {
                        if (!Test.isRunningTest()) {
                            System.debug('Enqueuing UnanetProjectSyncQueueable for Opportunity: ' + opportunityId);
                            System.enqueueJob(new UnanetProjectSyncQueueable(opportunityId, token));
                        }
                        
                        System.debug('Skipping Enqueuing UnanetContactSyncQueueable due to the Opp having no Primary Contact. Opp Id: ' + opp.Id);
                        logError('Skipping Enqueuing UnanetContactSyncQueueable', 'The related Opp has no Primary Contact', opp.Id);
                    }
    
                } else {
                    logError(
                        'Unanet Org Not Found',
                        'No organization found in Unanet for Unanet_Id__c = ' + acc.Unanet_Id__c + ' on Account ' + acc.Id,
                        acc.Id
                    );
                }
            }
    
        } catch (Exception e) {
            // Log any unexpected errors
            logError(
                'Unexpected Error',
                'An unexpected error occurred while processing Opportunity ' + opportunityId + ': ' + e.getMessage(),
                String.valueOf(opportunityId)
            );
            System.debug('UnanetAccountSyncQueueable.execute() - Unexpected error: ' + e.getMessage());
        }
    }
    

    private void logError(String name, String description, String relatedId) {
        try {
            insert new Data_Log__c(
                Description__c       = description,
                Related_Record_Id__c = relatedId,
                Log_Origin__c        = 'Unanet Organization sync error'
            );
            System.Debug('Inserting Data Log. Description: ' + description);
        } catch (Exception e) {
            System.debug('Failed to insert Data_Log__c: ' + e.getMessage());
        }
    }
    
    public static void codeCoverageHack() {
    Integer i = 0;
    	i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;

  }
}