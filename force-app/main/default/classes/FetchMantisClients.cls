public class FetchMantisClients {
    public class CompanyList {
        public List<MantisCompany> data;
        public Pagination pagination;
    }

    public class Pagination {
        public String next_url;
        public Integer count;
        public Integer pages;
        public Integer page;
        public Integer recordLimit;
        public Integer itemsIn;
    }

    @Future(callout=true)
    public static void makeAccountGetCallout() {

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
        
        // Construct the initial endpoint URL
        String nextUrl = getEndpointUrl(isSandbox); // Get the initial endpoint URL for the first page
        
        if (String.isEmpty(nextUrl)) {
            return; // Exit if the next URL is empty (invalid).
        }

        while (nextUrl != null) {
            HttpRequest request = new HttpRequest();
            request.setEndpoint(nextUrl);
            request.setMethod('GET');
            
            // Set the Authorization header with the Bearer token
            if (!String.isEmpty(bearerToken)) {
                request.setHeader('Authorization', 'Bearer ' + bearerToken);
            } else {
                DataLogService.logInfo('FetchMantisClients Apex Class', 'Bearer token is not set in Perform_Integration_Settings custom settings.');
                System.debug('Bearer token is not set in Perform_Integration_Settings custom settings.');
                return;
            }
            
            Http http = new Http();
            HttpResponse response = http.send(request);
            
            // If the request is successful, parse the JSON response.
            if (response.getStatusCode() == 200) {
                DataLogService.logInfo('FetchMantisClients Apex Class', 'Callout returned an HTTP ' + response.getStatusCode() + ' response.\n\n Response body:\n');
                
                // Directly deserialize the response body
                CompanyList companyList = (CompanyList) System.JSON.deserialize(response.getBody(), CompanyList.class);
                List<MantisCompany> mCompany = companyList.data; // Accessing the 'data' field
                
                // Pagination logic
                Integer currentPage = companyList.pagination.page;
                Integer totalPages = companyList.pagination.pages;
                
                // Update the nextUrl for pagination
                if (currentPage < totalPages) {
                    nextUrl = companyList.pagination.next_url; // Set next URL for the next page
                } else {
                    nextUrl = null; // Exit the loop if there are no more pages
                }
                
                // Add the companies to the map
                Map<String, MantisCompany> mapmc = new Map<String, MantisCompany>();
                for (MantisCompany mc : mCompany) {
                    mapmc.put(mc.id, mc);
                }
                
                // Enqueue the job if we have companies
                if (mCompany.size() > 0) {
                    System.enqueueJob(new ProcessMantisClientsQueueable(mapmc));
                } else {
                    System.debug('Empty API response.');
                }
                
            } else {
                DataLogService.logError('FetchMantisClients Apex Class', 'Callout returned an HTTP ' + response.getStatusCode() + ' response.\n\n Response body:\n' + response.getBody());
                break; // If the response is not successful, exit the loop
            }
        }
    }

    private static String getEndpointUrl(Boolean isSandbox) {
        String namedCredentialName;
        if(isSandbox) {
            namedCredentialName = 'PerformStaging';
        } else {
            namedCredentialName = 'PerformProduction';
        }
        NamedCredential performCred = [SELECT Endpoint FROM NamedCredential WHERE DeveloperName = :namedCredentialName LIMIT 1];
        
        // Construct the URL with pagination parameters for the first page
        return performCred.Endpoint + '/companies?page=1&limit=1000';
    }
}