public with sharing class FetchPerformPropertiesInvocable {
    
    @InvocableMethod
    public static void fetchPerformProperties(List<String> company_uuids) {
        if (company_uuids.isEmpty()) {
            DataLogService.logInfo('FetchPerformPropertiesInvocable Apex Class', 'Company uuids List was passed as empty');
            return;  // Return empty list if no company UUIDs are passed
        }

        try {
            // Retrieve companyUUID from List
            String companyUUID = company_uuids[0];
            List<ApiResponsePropertyWrapper> properties = fetchPropertiesFromApi(company_uuids);
            System.debug('Properties size: ' + properties.size());
            
            if (!properties.isEmpty()) {
                System.debug('Enqueue Job');
                System.enqueueJob(new ProcessPropertiesQueueable(properties, companyUUID));
                
            } else {
                DataLogService.logInfo('FetchPerformPropertiesInvocable Apex Class', 'No properties returned for companyUUID: ' + companyUUID);
            }

        } catch(Exception ex) {
            String errMsg = 'Error in fetchPerformProperties. Input UUIDs: ' + String.join(company_uuids, ',') +
                ' | Message: ' + ex.getMessage() +
                ' | StackTrace: ' + ex.getStackTraceString();

            DataLogService.logError('FetchPerformPropertiesInvocable Apex Class', errMsg);
        }
        
    }

    public static List<ApiResponsePropertyWrapper> fetchPropertiesFromApi(List<String> company_uuids) {
        List<ApiResponsePropertyWrapper> allProperties = new List<ApiResponsePropertyWrapper>();
        
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
        
        String nextUrl = getEndpointUrl(company_uuids[0], isSandbox);
        
        while (nextUrl != null) {
            HttpRequest request = new HttpRequest();        
            request.setMethod('GET');        
            request.setEndpoint(nextUrl);

            if (!String.isEmpty(bearerToken)) {
                request.setHeader('Authorization', 'Bearer ' + bearerToken);
            } else {
                return new List<ApiResponsePropertyWrapper>();
            }

            Http http = new Http();
            HttpResponse response = http.send(request);

            if (response.getStatusCode() == 200) {
                ApiResponseWrapper apiResponse = (ApiResponseWrapper) JSON.deserialize(response.getBody(), ApiResponseWrapper.class);
                allProperties.addAll(apiResponse.data);

                // Update nextUrl using pagination logic
                Integer currentPage = apiResponse.pagination.page;
                Integer totalPages = apiResponse.pagination.pages;

                if (currentPage < totalPages) {
                    nextUrl = apiResponse.pagination.next_url; // Use the next_url from the response
                } else {
                    nextUrl = null; // Exit loop if there are no more pages
                }
            } else {
                throw new FetchPerformPropertiesException('Callout returned an error: ' + response.getStatusCode());
            }
        }
		System.debug('Properties Returned: ' + allProperties.size());
        return allProperties;
    }

    private static String getEndpointUrl(String company_uuid, Boolean isSandbox) {
        String namedCredentialName;
        if(isSandbox) {
            namedCredentialName = 'PerformStaging';
        } else {
            namedCredentialName = 'PerformProduction';
        }
        NamedCredential performCred = [SELECT Endpoint FROM NamedCredential WHERE DeveloperName = :namedCredentialName LIMIT 1];
        
        return performCred.Endpoint + '/companies/' +
            EncodingUtil.urlEncode(company_uuid, 'UTF-8') + 
            '/company_locations?page=1&limit=100';
    }

    public class ApiResponseWrapper {
        public List<ApiResponsePropertyWrapper> data { get; set; }
        public Pagination pagination { get; set; }
    }

    public class Pagination {
        public String next_url; 
        public Integer page; 
        public Integer pages; 
    }

    public class FetchPerformPropertiesException extends Exception {}
}