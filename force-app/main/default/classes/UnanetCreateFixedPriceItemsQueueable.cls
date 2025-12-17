public with sharing class UnanetCreateFixedPriceItemsQueueable implements Queueable, Database.AllowsCallouts {

    private List<Project__c> changeOrders;
    private String token;
    private String baseUrl;

    public UnanetCreateFixedPriceItemsQueueable(
        List<Project__c> changeOrders,
        String token,
        String baseUrl
    ) {
        this.changeOrders = changeOrders;
        this.token = token;
        this.baseUrl = baseUrl;
    } 

    public void execute(QueueableContext context) {
        List<Project__c> projectsToUpdate = new List<Project__c>();
    
        for (Project__c coProj : changeOrders) {
            System.debug('Processing Change Order Project: ' + coProj.Id + ' - ' + coProj.Name);
    
            Id parentId = coProj.Parent_Project__c;
            if (parentId == null) {
                System.debug('Parent Project not found for Change Order Project: ' + coProj.Id);
                logError('UnanetCreateFixedPriceItemsQueueable', 'Missing parent Project for: ' + coProj.Id, coProj.Id);
                continue;
            }
    
            String parentUnanetKey;
            List<Project__c> parentList = [
                SELECT Unanet_Id__c FROM Project__c WHERE Id = :parentId LIMIT 1
            ];
            if (parentList.isEmpty() || String.isBlank(parentList[0].Unanet_Id__c)) {
                logError(
                    'UnanetCreateFixedPriceItemsQueueable',
                    'Parent Project__c missing or has no Unanet_Id__c for Id: ' + parentId,
                    String.valueOf(coProj.Id)
                );
                continue;
            }
            parentUnanetKey = parentList[0].Unanet_Id__c;


            String endpoint = baseUrl + '/platform/rest/projects/' + parentUnanetKey + '/fixed-price-items';
            String jsonBody = UnanetHelper.buildFixedPriceItemPayload(coProj, parentUnanetKey);
    
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('POST');
            req.setHeader('Authorization', 'Bearer ' + token);
            req.setHeader('Content-Type', 'application/json');
            req.setBody(jsonBody);
    
            try {
                Http http = new Http();
                HttpResponse res = http.send(req);
                System.debug('Fixed-price item response for ' + coProj.Id + ': ' + res.getBody());
    
                if (res.getStatusCode() == 201 || res.getStatusCode() == 200) {
                    // Parse the response to get the "key"
                    String responseBody = res.getBody();
                    Map<String, Object> parsedResponse = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
                    if (parsedResponse.containsKey('key')) {
                        Object keyValue = parsedResponse.get('key');
                        coProj.Unanet_Id__c = String.valueOf(keyValue);
                        projectsToUpdate.add(coProj);
                    } else {
                        logError('UnanetCreateFixedPriceItemsQueueable', 'Key not found in response for: ' + coProj.Id, coProj.Id);
                    }
                } else {
                    logError(
                                'UnanetCreateFixedPriceItemsQueueable',
                                'Failed to create fixed-price item. Status: ' + res.getStatusCode() + ', Body: ' + res.getBody(),
                                coProj.Id
                            );

                }
    
            } catch (Exception e) {
                System.debug('Exception during fixed-price item creation for ' + coProj.Id + ': ' + e.getMessage());
                logError('UnanetCreateFixedPriceItemsQueueable', e.getMessage(), coProj.Id);
            }
        }
    
        // Perform DML after loop
        if (!projectsToUpdate.isEmpty()) {
            try {
                update projectsToUpdate;
                System.debug('Successfully updated Unanet_Id__c for ' + projectsToUpdate.size() + ' projects.');
            } catch (DmlException dmlEx) {
                System.debug('DML Exception while updating projects: ' + dmlEx.getMessage());
                for (Project__c failedProj : projectsToUpdate) {
                    logError('UnanetCreateFixedPriceItemsQueueable', 'DML failure on update: ' + dmlEx.getMessage(), failedProj.Id);
                }
            }
        }
    }
    

    private static void logError(String name, String description, String relatedId) {
        try {
            insert new Data_Log__c(
                Description__c       = description,
                Related_Record_Id__c = relatedId,
                Log_Origin__c        = 'Unanet Organization Sync Error'
            );
            System.debug('Inserting DataLog Record');
        } catch (Exception e) {
            System.debug('Failed to insert Data_Log__c: ' + e.getMessage());
        }
    }
}