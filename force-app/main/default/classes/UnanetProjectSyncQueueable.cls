public with sharing class UnanetProjectSyncQueueable implements Queueable, Database.AllowsCallouts {

    private Id opportunityId;
    private String token;

    public UnanetProjectSyncQueueable(Id opportunityId, String token) {
        this.opportunityId = opportunityId;
        this.token = token;
    }

    public void execute(QueueableContext context) {
        Opportunity opp = [
            SELECT Id, AccountId, Account.Name, Account.Unanet_Id__c, Account.Unanet_Customer_Code__c,
                   Account.CurrencyIsoCode, Account.BillingAddress, Primary_Contact__c, Unanet_Id__c, Mantis_Division__c, OwnerId, Owner.Name, Project_State__c, CurrencyIsoCode, Billing_Manager__c 
            FROM Opportunity
            WHERE Id = :opportunityId
            LIMIT 1
        ];

        if (opp == null || opp.Account == null || String.isBlank(opp.Account.Unanet_Id__c)) {
            logError('UnanetProjectSyncQueueable.execute()', 'Invalid Opportunity or Account data for Id: ' + opportunityId, opportunityId);
            return;
        }

        Account acc = [
                        SELECT Id, BillingStreet, BillingCity, Unanet_Id__c
                        FROM Account
                        WHERE Id = :opp.AccountId
                        LIMIT 1
                    ];

        String baseUrl = UnanetHelper.getUnanetBaseUrl();

        if (String.isBlank(token) || String.isBlank(baseUrl)) {
            logError('UnanetProjectSyncQueueable.execute()', 'Missing token or base URL', opp.Id);
            return;
        }

        List<Project__c> allProjects = [
            SELECT Id, Name, Account__r.Name, Total_Contract_Value__c, Start_Date__c, End_Date__c,
                   Opportunity__r.Mantis_Division__c, CurrencyIsoCode, Project_Number__c,
                   Type__c, Project_Type__c, Unanet_Id__c, Contract_Type__c, Opportunity__r.Owner.Name,
                   Work_At_Risk_WAR__c, Project_Requires_TASKS__c, Project_State__c,
                   Parent_Project__c, Service_Area__c, Type_of_Service__c, Service_City__c, Service_Street__c, 
                   Unanet_Project_Type__c, Revised_End_Date__c, Revised_Start_Date__c, Project_Amount__c, 
                   Pass_Through_Costs__c,Project_Manager_Unanet__c, As_Sold_Gross_Margin2__c, Parent_Project__r.Type__c
            FROM Project__c
            WHERE Opportunity__c = :opp.Id
        ];

        if (allProjects.isEmpty()) {
            logError('UnanetProjectSyncQueueable.execute()', 'No Projects found for Opportunity: ' + opp.Id, opp.Id);
            return;
        }

        // Partition Projects
        List<Project__c> standardProjects = new List<Project__c>();
        List<Project__c> changeOrders = new List<Project__c>();

        for (Project__c proj : allProjects) {
            System.debug('Evaluating Project: ' + proj.Id + ' - Type: ' + proj.Type__c);
            if (proj.Type__c == 'Change Order') {
                changeOrders.add(proj);
            } else {
                standardProjects.add(proj);
            }
        }

        System.debug('Standard Projects Count: ' + standardProjects.size());
        System.debug('Change Orders Count: ' + changeOrders.size());
		
        if (!Test.isRunningTest()) {
            // Enqueue next phase
        	System.enqueueJob(new UnanetCreateProjectsQueueable(acc, opp, standardProjects, changeOrders, token, baseUrl)); 
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