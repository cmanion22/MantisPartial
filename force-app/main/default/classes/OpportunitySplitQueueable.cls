public class OpportunitySplitQueueable implements Queueable, Database.AllowsCallouts {
    private List<Opportunity_Split__c> splits;
    private String operation;

    public OpportunitySplitQueueable(List<Opportunity_Split__c> splits, String operation) {
        this.splits = splits;
        this.operation = operation;
    }

    public void execute(QueueableContext context) {
        for (Opportunity_Split__c split : splits) {
            try {
                // Process each split individually
                String jsonPayload;
                if (operation == 'create') {
                    jsonPayload = createOpportunitySplitPayload(split);
                } else if (operation == 'update') {
                    jsonPayload = updateOpportunitySplitPayload(split);
                } else if (operation == 'delete') {
                    jsonPayload = deleteOpportunitySplitPayload(split);
                } else {
                    System.debug('Unknown operation: ' + operation);
                    continue; // Skip unknown operations
                }

                sendHttpRequest(jsonPayload);
            } catch (Exception e) {
                System.debug('Exception while processing split ' + split.Id + ': ' + e.getMessage());
            }
        }
    }

    private String createOpportunitySplitPayload(Opportunity_Split__c split) {
        User currentUser;
        try {
            currentUser = [SELECT API_Token__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        } catch (Exception e) {
            System.debug('Error querying user: ' + e.getMessage());
            return null;
        }

        Map<String, Object> splitData = new Map<String, Object>{
            'Id' => split.Id
        };

        Map<String, Object> payloadMap = new Map<String, Object>{
            'api_token' => currentUser.API_Token__c,
            'event'     => 'create_opportunity_split',
            'data'      => new Map<String, Object>{
                'opportunity_split' => splitData
            }
        };

        return JSON.serialize(payloadMap);
    }

    private String updateOpportunitySplitPayload(Opportunity_Split__c split) {
        User currentUser;
        try {
            currentUser = [SELECT API_Token__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        } catch (Exception e) {
            System.debug('Error querying user: ' + e.getMessage());
            return null;
        }

        Map<String, Object> splitData = new Map<String, Object>{
            'Id' => split.Id
        };

        Map<String, Object> payloadMap = new Map<String, Object>{
            'api_token' => currentUser.API_Token__c,
            'event'     => 'update_opportunity_split',
            'data'      => new Map<String, Object>{
                'opportunity_split' => splitData
            }
        };

        return JSON.serialize(payloadMap);
    }

    private String deleteOpportunitySplitPayload(Opportunity_Split__c split) {
        User currentUser;
        try {
            currentUser = [SELECT API_Token__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        } catch (Exception e) {
            System.debug('Error querying user: ' + e.getMessage());
            return null;
        }

        Map<String, Object> splitData = new Map<String, Object>{
            'Id' => split.Id
        };

        Map<String, Object> payloadMap = new Map<String, Object>{
            'api_token' => currentUser.API_Token__c,
            'event'     => 'delete_opportunity_split',
            'data'      => new Map<String, Object>{
                'opportunity_split' => splitData
            }
        };

        return JSON.serialize(payloadMap);
    }

    private void sendHttpRequest(String jsonPayload) {
        String url = ESBController.getESBUrl();
        if (String.isEmpty(url)) {
            System.debug('Endpoint URL is empty.');
            return;
        }

        HttpRequest req = new HttpRequest();

        // Fetch integration settings
        Back_Office_Integration_Settings__c integrationSettings;
        if (Utils.isSandbox) {
            integrationSettings = Back_Office_Integration_Settings__c.getValues('Staging');
        } else {
            integrationSettings = Back_Office_Integration_Settings__c.getValues('Production');
        }

        // Set Authorization header if required
        if (integrationSettings.Endpoint_Requires_Authentication__c) {
            Blob headerValue = Blob.valueOf(integrationSettings.Endpoint_Username__c + ':' + integrationSettings.Endpoint_Password__c);
            String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
            req.setHeader('Authorization', authorizationHeader);
        }

        req.setEndpoint(url);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json;charset=UTF-8');
        req.setBody(jsonPayload);

        System.debug('OpportunitySplitHandler->OpportunitySplitQueueable->Sending Request --> ' + jsonPayload);
        
        Http http = new Http();
        HttpResponse response;
        try {
            response = http.send(req);
            if (response.getStatusCode() == 200) {
                DataLogService.logInfo(
                'OpportunitySplitQueueable Invocable Apex Action',
                'Callout returned an HTTP ' + response.getStatusCode() + ' response.\n\n Request body:\n ' + jsonPayload + '\n\n Response body:\n' + response.getBody()
                
            );
               
                System.debug('Callout successful: ' + response.getBody());
            } else {
                System.debug('Callout failed: ' + response.getBody());
                System.debug('Status Code: ' + response.getStatusCode());
                DataLogService.logError(
                'OpportunitySplitQueueable Invocable Apex Action',
                'Callout returned an HTTP ' + response.getStatusCode() + ' response.\n\n Request body:\n ' + jsonPayload + '\n\n Response body:\n' + response.getBody()
               
            );
            }
        } catch (Exception e) {
            System.debug('Exception occurred during HTTP callout: ' + e.getMessage());
        }
    }
}