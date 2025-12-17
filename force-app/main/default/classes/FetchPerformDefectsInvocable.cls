public with sharing class FetchPerformDefectsInvocable {
    
    @InvocableMethod
    public static List<List<Defect__c>> fetchPerformDefects(List<String> sectionUUIDs) {
        if (sectionUUIDs.isEmpty()) {
            DataLogService.logInfo('FetchPerformDefectsInvocable', 'No section UUIDs passed.');
            return new List<List<Defect__c>>();  // Return empty list if no section UUIDs are passed            
        }
        
        try {
            String sectionUUId = sectionUUIDs[0];
            List<ApiResponseDefectWrapper> allDefects = fetchDefectsFromApi(sectionUUId);

            if (!allDefects.isEmpty()) {
                System.enqueueJob(new ProcessDefectsQueueable(allDefects));
            } else {
                DataLogService.logInfo('FetchPerformDefectsInvocable', 'No defects returned for sectionUUID: ' + sectionUUId);
            }
        } catch (Exception ex) {
            String errMsg = 'Error in fetchPerformDefects | UUIDs: ' + String.join(sectionUUIDs, ',') +
                            ' | Msg: ' + ex.getMessage() +
                            ' | Stack: ' + ex.getStackTraceString();
            DataLogService.logError('FetchPerformDefectsInvocable', errMsg);
        }

        // Return an empty list as the upsert is now handled in the queueable class
        return new List<List<Defect__c>>();
    
    }

    // Fetches sections from the API, handling pagination
    public static List<ApiResponseDefectWrapper> fetchDefectsFromApi(String sectionUUId) {
        List<ApiResponseDefectWrapper> allDefects = new List<ApiResponseDefectWrapper>();

        // Check wether the Org is Sandbox or Production
        Boolean isSandbox = Utils.isSandbox;

        // Retrieve the Bearer Token from the custom setting "Perform_Integration_Settings__c"
        Perform_Integration_Settings__c settings;
        if(isSandbox) {
            settings = Perform_Integration_Settings__c.getInstance('Companies Staging');
        } else {
            settings = Perform_Integration_Settings__c.getInstance('Companies Production');
        }
        
        String bearerToken = settings != null ? settings.Bearer_Token__c : '';
        
        String nextUrl = getEndpointUrl(sectionUUId, isSandbox);

        while (nextUrl != null) {
            HttpRequest request = new HttpRequest();        
            request.setMethod('GET');        
            request.setEndpoint(nextUrl);

            if (!String.isEmpty(bearerToken)) {
                request.setHeader('Authorization', 'Bearer ' + bearerToken);
            } else {
                // Handle missing Bearer token
                return new List<ApiResponseDefectWrapper>();
            }

            Http http = new Http();
            HttpResponse response = http.send(request);

            if (response.getStatusCode() == 200) {
                ApiResponseWrapper apiResponse = (ApiResponseWrapper) JSON.deserialize(response.getBody(), ApiResponseWrapper.class);
                allDefects.addAll(apiResponse.data);

                // Check pagination and update nextUrl
                Integer currentPage = apiResponse.pagination.page;
                Integer totalPages = apiResponse.pagination.pages;

                if (currentPage < totalPages) {
                    nextUrl = apiResponse.pagination.next_url; // Get the next page's URL
                } else {
                    nextUrl = null; // Exit loop if there are no more pages
                }
            } else {
                // Handle error
                DataLogService.logError(
                    'FetchPerformDefectsInvocable Invocable Apex Action',
                    'Callout returned an error: ' + response.getStatusCode()
                );
                throw new FetchPerformDefectsException('Callout returned an error: ' + response.getStatusCode());
            }
        }

        System.debug('Defects Returned: ' + allDefects.size());
        return allDefects;
    }

    // Returns the endpoint URL for the API call    
    private static String getEndpointUrl(String sectionUUID, Boolean isSandbox) {
        String namedCredentialName;
        if(isSandbox) {
            namedCredentialName = 'PerformStaging';
        } else {
            namedCredentialName = 'PerformProduction';
        }
        
        NamedCredential performCred = [SELECT Endpoint FROM NamedCredential WHERE DeveloperName = :namedCredentialName LIMIT 1];
        
        return performCred.Endpoint + '/sections/' +
            EncodingUtil.urlEncode(sectionUUID, 'UTF-8') + 
            '/defects?page=1&limit=50'; // Start with page 1, limit 50 results per page
    }
   
    public class ApiResponseWrapper {
        public List<ApiResponseDefectWrapper> data { get; set; }
        public Pagination pagination { get; set; }
    }

    public class Pagination {
        public String next_url;
        public Integer count;
        public Integer pages;
        public Integer page;
        public Integer recordLimit;
        public Integer itemsIn;
    }

    public class FetchPerformDefectsException extends Exception {}

}