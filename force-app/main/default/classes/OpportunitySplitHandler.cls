public with sharing class OpportunitySplitHandler {

    @InvocableMethod(label='Handle Split Operation')
    public static void handleSplitsOperation(List<OpportunitySplitsHandlerWrapper> requests) {
        if (requests == null || requests.isEmpty()) {
            throw new IllegalArgumentException('Request not provided');
        }

        System.debug('Requests passed to OpportunitySplitHandler: ' + requests);

        // Step 1: Collect all Opportunity Split Ids
        Set<Id> splitIds = new Set<Id>();
        for (OpportunitySplitsHandlerWrapper request : requests) {
            if (request.opportunitySplitIds != null && !request.opportunitySplitIds.isEmpty()) {
                splitIds.addAll(request.opportunitySplitIds);
            }
        }

        // Step 2: Query all Opportunity Splits
        Map<OpportunitySplitsHandlerWrapper, List<Opportunity_Split__c>> wrapperToSplitsMap = new Map<OpportunitySplitsHandlerWrapper, List<Opportunity_Split__c>>();

        List<Opportunity_Split__c> splits = [SELECT Id, Opportunity__c FROM Opportunity_Split__c WHERE Id IN :splitIds];
        for (OpportunitySplitsHandlerWrapper request : requests) {
            List<Opportunity_Split__c> relatedSplits = new List<Opportunity_Split__c>();
            for (Opportunity_Split__c split : splits) {
                if (request.opportunitySplitIds.contains(split.Id)) {
                    relatedSplits.add(split);
                }
            }
            wrapperToSplitsMap.put(request, relatedSplits);
        }

        // Step 3: Process each wrapper and its related splits
        for (OpportunitySplitsHandlerWrapper request : requests) {
            List<Opportunity_Split__c> splitsToProcess = wrapperToSplitsMap.get(request);
            if (splitsToProcess != null && !splitsToProcess.isEmpty()) {
                if (request.operation == 'insert') {
                    handleAfterInsert(splitsToProcess);
                } else if (request.operation == 'update') {
                    handleAfterUpdate(splitsToProcess);
                } else if (request.operation == 'delete') {
                    handleBeforeDelete(splitsToProcess);
                }
            }
        }
    }

    public static void handleAfterInsert(List<Opportunity_Split__c> splits) {
        List<Opportunity_Split__c> splitsToSync = opportunitySplitsToSync(splits);
        if (!splitsToSync.isEmpty()) {
            System.enqueueJob(new OpportunitySplitQueueable(splitsToSync, 'create'));
        }
    }

    public static void handleAfterUpdate(List<Opportunity_Split__c> splits) {
        List<Opportunity_Split__c> splitsToSync = opportunitySplitsToSync(splits);
        if (!splitsToSync.isEmpty()) {
            System.enqueueJob(new OpportunitySplitQueueable(splitsToSync, 'update'));
        }
    }

    public static void handleBeforeDelete(List<Opportunity_Split__c> splits) {
        List<Opportunity_Split__c> splitsToSync = opportunitySplitsToSync(splits);
        if (!splitsToSync.isEmpty()) {
            System.enqueueJob(new OpportunitySplitQueueable(splitsToSync, 'delete'));
        }
    }

    private static List<Opportunity_Split__c> opportunitySplitsToSync(List<Opportunity_Split__c> splits) {
        Set<Id> oppIds = new Set<Id>();
        for (Opportunity_Split__c split : splits) {
            oppIds.add(split.Opportunity__c);
        }

        Map<Id, Opportunity> opportunitiesMap = new Map<Id, Opportunity>(
            [SELECT Id, Registered_in_Back_Office__c FROM Opportunity WHERE Id IN :oppIds]
        );
                
        List<Opportunity_Split__c> filteredSplits = new List<Opportunity_Split__c>();
        
        for (Opportunity_Split__c split : splits) {
            Opportunity opp = opportunitiesMap.get(split.Opportunity__c);
            if (opp != null && opp.Registered_in_Back_Office__c) {
                filteredSplits.add(split);
            }
        }

        return filteredSplits;
    }
}