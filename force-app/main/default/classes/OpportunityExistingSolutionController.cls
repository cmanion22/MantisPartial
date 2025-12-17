public without sharing class OpportunityExistingSolutionController {
    @AuraEnabled(cacheable=true)
    public static List<OpportunityChartWrapper> getOpportunities(String opportunityId) {
        // Validate input
        if (String.isBlank(opportunityId)) {
            throw new AuraHandledException('Invalid Opportunity ID');
        }

        // Fetch the current opportunity details
        Opportunity currentOpp;
        try {
            currentOpp = [
                SELECT Id, AccountId, Type_of_Service__c
                FROM Opportunity
                WHERE Id = :opportunityId
                LIMIT 1
            ];
            System.debug('Current Opportunity: ' + currentOpp);
        } catch (Exception e) {
            throw new AuraHandledException('Failed to retrieve Opportunity details: ' + e.getMessage());
        }

        // Return list of related opportunities matching criteria
        List<Opportunity> relatedOpps = [
            SELECT CloseDate, Type_of_Service__c
            FROM Opportunity
            WHERE AccountId = :currentOpp.AccountId
                AND StageName = '5 - Closed Won'
                AND Type_of_Service__c = :currentOpp.Type_of_Service__c
                AND Id != :currentOpp.Id
                AND CloseDate != NULL
            ORDER BY CloseDate ASC
        ];

        // Debug the fetched related opportunities
        System.debug('Related Opportunities: ' + relatedOpps);

        // Transform related opportunities into wrapper objects
        List<OpportunityChartWrapper> wrapperList = new List<OpportunityChartWrapper>();
        for (Opportunity opp : relatedOpps) {
            // Handle potential null CloseDate
            String closeDateYear = (opp.CloseDate != null) ? String.valueOf(opp.CloseDate.year()) : 'Unknown';
            String typeOfService = (opp.Type_of_Service__c != null) ? opp.Type_of_Service__c : 'Unknown';

            // Add the transformed data to the wrapper list
            wrapperList.add(new OpportunityChartWrapper(closeDateYear, typeOfService));
        }

        return wrapperList;
    }

    // Wrapper class to structure data for the chart
    public class OpportunityChartWrapper {
        @AuraEnabled public String closeDateYear { get; set; }
        @AuraEnabled public String typeOfService { get; set; }

        // Constructor now expects only two parameters: closeDateYear and typeOfService
        public OpportunityChartWrapper(String closeDateYear, String typeOfService) {
            this.closeDateYear = closeDateYear;
            this.typeOfService = typeOfService;
        }
    }
}