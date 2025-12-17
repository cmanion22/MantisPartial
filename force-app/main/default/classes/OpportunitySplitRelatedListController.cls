public with sharing class OpportunitySplitRelatedListController {

    // Method to fetch Opportunity Splits for a given Opportunity Id
    @AuraEnabled(cacheable=true)
    public static List<Opportunity_Split__c> getOpportunitySplits(String opportunityId) {
        try {
            return [SELECT Id, Team_MemberLink__c, Split_Percentage__c, Current_Percentage__c, Team_MemberFX__c, OwnerId, Name
                    FROM Opportunity_Split__c
                    WHERE Opportunity__c = :opportunityId];
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching Opportunity Splits: ' + e.getMessage());
        }
    }

    // Method to create a new Opportunity Split
    @AuraEnabled
    public static Opportunity_Split__c createOpportunitySplit(Id opportunityId, Id ownerId) {
        // Create the Opportunity Split record
        Opportunity_Split__c newSplit = new Opportunity_Split__c(
            Opportunity__c = opportunityId,
            OwnerId = ownerId,
            Split_Percentage__c = 0,  // Default values
            Current_Percentage__c = 0
        );
        insert newSplit;

        Opportunity_Split__c split = [SELECT Id, Team_MemberLink__c, Split_Percentage__c, Current_Percentage__c, Team_MemberFX__c, OwnerId
                                        FROM Opportunity_Split__c
                                        WHERE Id = :newSplit.Id
                                        LIMIT 1];
        return split;

    }

    // Method to check user permissions based on Opportunity and user role
    @AuraEnabled
    public static Map<String, Boolean> checkUserPermissions(String opportunityId) {
        Map<String, Boolean> permissions = new Map<String, Boolean>();

        // Fetch Opportunity data to determine visibility
        Opportunity opp = [SELECT Id, IsClosed, More_than_1_Opp_Split__c 
                           FROM Opportunity WHERE Id = :opportunityId LIMIT 1];
        System.debug('Check User Permissions Opportunity Id: ' + opportunityId);
        
        

        Boolean isClosed = opp.IsClosed;
        System.debug('Check User Permissions Opportunity IsClosed: ' + opp.IsClosed);

        Boolean moreThanOneOppSplit = opp.More_than_1_Opp_Split__c;
        System.debug('Check User Permissions Opportunity More_than_1_Opp_Split__c:');

        // Fetch Permission Set Assignments for the current user
        List<PermissionSetAssignment> psaList = [SELECT PermissionSet.Name 
                                                  FROM PermissionSetAssignment 
                                                  WHERE AssigneeId = :UserInfo.getUserId() 
                                                  AND (PermissionSet.Name IN ('Sales_Admin_Access', 'Sales_Admin_Split_Access', 'Finance_Split_Access'))];

        // Boolean flags for button display logic
        Boolean displayEdit = false;
        Boolean displayNew = false;
        Boolean hasSalesAdminAccess = false;
        Boolean hasEditSplitAccess = false;
        Boolean hasFinanceSplitAccess = false;

        // Check each permission set assigned to the user
        for (PermissionSetAssignment psa : psaList) {
            if (psa.PermissionSet.Name == 'Sales_Admin_Access') {
                hasSalesAdminAccess = true;
            } else if (psa.PermissionSet.Name == 'Sales_Admin_Split_Access') {
                hasEditSplitAccess = true;
            } else if (psa.PermissionSet.Name == 'Finance_Split_Access') {
                hasFinanceSplitAccess = true;
            }
        }

        System.debug('Check User Permissions hasSalesAdminAccess: ' + hasSalesAdminAccess);
        System.debug('Check User Permissions hasEditSplitAccess: ' + hasEditSplitAccess);
        System.debug('Check User Permissions hasFinanceSplitAccess: ' + hasFinanceSplitAccess);

        // Logic to determine if the "Edit" and "New" buttons should be displayed
        if (!isClosed && (hasSalesAdminAccess || hasEditSplitAccess || hasFinanceSplitAccess)) {
            displayEdit = true;
        } else if (isClosed && hasSalesAdminAccess) {
            displayEdit = true;
        }

        if(hasSalesAdminAccess) {
            displayNew = true;
        }

        System.debug('Check User Permissions displayEdit: ' + displayEdit);
        System.debug('Check User Permissions displayNew: ' + displayNew);


        // Populate the permissions map to be returned
        permissions.put('showNew', displayNew);
        permissions.put('showEdit', displayEdit);
        permissions.put('showChangeRequest', moreThanOneOppSplit); // Assuming change request visibility based on splits

        System.debug('Check User Permissions: ' + permissions);
        return permissions;
    }

    // New method to fetch related Opportunity for a given Opportunity Id
    @AuraEnabled(cacheable=true)
    public static Opportunity getRelatedOpportunity(String opportunityId) {
        try {
            return [SELECT Id, Name FROM Opportunity WHERE Id = :opportunityId LIMIT 1];
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching related Opportunity: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static void updateOpportunitySplits(List<Opportunity_Split__c> splits) {
        try {
            update splits; // Bulk update the Opportunity Split records
        } catch (Exception e) {
            throw new AuraHandledException('Error updating Opportunity Splits: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static Boolean isServicesRecordType(Id opportunityId) {
        Opportunity opp = [
            SELECT RecordType.Name 
            FROM Opportunity 
            WHERE Id = :opportunityId 
            LIMIT 1
        ];
        return opp.RecordType.Name == 'Services';
    }

    @AuraEnabled(cacheable=true)
    public static List<User> getUsers(Id oppId) {
        try {
            // Query for OpportunityTeamMember records related to the given OpportunityId
            List<OpportunityTeamMember> teamMembers = [
                SELECT UserId, User.Name
                FROM OpportunityTeamMember
                WHERE OpportunityId = :oppId
            ];
            
            // Collect the User IDs from the related OpportunityTeamMembers
            Set<Id> userIds = new Set<Id>();
            for (OpportunityTeamMember teamMember : teamMembers) {
                userIds.add(teamMember.UserId);
            }
            
            // Query the User records based on the collected User IDs
            List<User> users = [
                SELECT Id, Name
                FROM User
                WHERE Id IN :userIds
                AND IsActive = TRUE
                ORDER BY Name
            ];
            
            return users;
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching users: ' + e.getMessage());
        }
    }

}