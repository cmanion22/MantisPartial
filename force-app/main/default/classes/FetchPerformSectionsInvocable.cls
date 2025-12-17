public with sharing class FetchPerformSectionsInvocable {
   
    @InvocableMethod
    public static List<List<Section__c>> fetchPerformSections(List<String> propertyUUIDS) {
        if (propertyUUIDS.isEmpty()) {
            DataLogService.logInfo('FetchPerformSectionsInvocable', 'No property UUIDs passed.');
            return new List<List<Section__c>>();
        }

        try {
            // Retrieve propertyUUID from List
            String propertyUUID = propertyUUIDS[0];
            List<ApiResponseSectionWrapper> allSections = fetchSectionsFromApi(propertyUUID);

            // Enqueue the job to process the fetched sections
            if (!allSections.isEmpty()) {
                System.enqueueJob(new ProcessSectionsQueueable(allSections));
            } else {
                DataLogService.logInfo('FetchPerformSectionsInvocable', 'No sections returned for propertyUUID: ' + propertyUUID);
            }

        } catch (Exception ex) {
            String errMsg = 'Error in fetchPerformSections | UUIDs: ' + String.join(propertyUUIDS, ',') +
                            ' | Msg: ' + ex.getMessage() +
                            ' | Stack: ' + ex.getStackTraceString();
            DataLogService.logError('FetchPerformSectionsInvocable', errMsg);
        }

        return new List<List<Section__c>>();
    }

    // Fetches sections from the API, handling pagination
    public static List<ApiResponseSectionWrapper> fetchSectionsFromApi(String propertyUUID) {
        List<ApiResponseSectionWrapper> allSections = new List<ApiResponseSectionWrapper>();
        
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
        
        String nextUrl = getEndpointUrl(propertyUUID, isSandbox);
        
        while (nextUrl != null) {
            HttpRequest request = new HttpRequest();        
            request.setMethod('GET');        
            request.setEndpoint(nextUrl);

            if (!String.isEmpty(bearerToken)) {
                request.setHeader('Authorization', 'Bearer ' + bearerToken);
            } else {
                // Handle missing Bearer token
                return new List<ApiResponseSectionWrapper>();
            }

            Http http = new Http();
            HttpResponse response = http.send(request);

            if (response.getStatusCode() == 200) {
                ApiResponseWrapper apiResponse = (ApiResponseWrapper) JSON.deserialize(response.getBody(), ApiResponseWrapper.class);
                allSections.addAll(apiResponse.data);
                System.debug('Response Status Code: ' + response.getStatusCode());

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
                    'FetchPerformSectionsInvocable Invocable Apex Action',
                    'Callout returned an error: ' + response.getStatusCode() + ' Response body: ' + response.getBody()
                );
                throw new FetchPerformSectionsException('Callout returned an error: ' + response.getStatusCode());
            }
        }

        System.debug('Sections Returned: ' + allSections.size());
        return allSections;
    }

    // Returns the endpoint URL for the API call
    private static String getEndpointUrl(String propertyUUID, Boolean isSandbox) {
        String namedCredentialName;
        if(isSandbox) {
            namedCredentialName = 'PerformStaging';
        } else {
            namedCredentialName = 'PerformProduction';
        }
        NamedCredential performCred = [SELECT Endpoint FROM NamedCredential WHERE DeveloperName = :namedCredentialName LIMIT 1];
        
        return performCred.Endpoint + '/company_locations/' +
            EncodingUtil.urlEncode(propertyUUID, 'UTF-8') + 
            '/sections?page=1&limit=1000'; // Start with page 1, limit 1000 results per page
    }

    public class ApiResponseWrapper {
        public List<ApiResponseSectionWrapper> data { get; set; }
        public Pagination pagination { get; set; }
    }

    public class Pagination {
        public String next_url; 
        public Integer page; 
        public Integer pages; 
    }

    public class FetchPerformSectionsException extends Exception {}
}