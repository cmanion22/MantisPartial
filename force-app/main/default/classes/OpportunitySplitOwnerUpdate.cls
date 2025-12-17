public with sharing class OpportunitySplitOwnerUpdate {

    public static void updateOpportunitySplits() {
        try {
            // Step 1: Query Open Opportunities
            List<Opportunity> openOpps = [
                SELECT Id, OwnerId, Previous_Owner__c
                FROM Opportunity
                WHERE IsClosed = false
                AND Legacy_Opportunity_No_Splits__c = false
            ];
            System.debug('Open Opps: ' + openOpps);

            if (openOpps.isEmpty()) {
                System.debug('No Opportunities to process.');
                DataLogService.logError(
                    'OpportunitySplitUpdater Apex Class',
                    'No Open Opportunities Found'
                );
                return;
            }

            // Step 2: Query Opportunity Splits for the retrieved Opportunities
            List<Opportunity_Split__c> oppSplits = [
                SELECT Opportunity__c, OwnerId, Default_Owner_Split__c
                FROM Opportunity_Split__c
                WHERE Opportunity__c IN :openOpps
            ];

            if (oppSplits.isEmpty()) {
                System.debug('No Opportunity Splits to process.');
                DataLogService.logError(
                    'OpportunitySplitUpdater Apex Class',
                    'No Opportunity Splits Found'
                );
                return;
            }

            // Step 3: Organize the splits by Opportunity
            Map<Id, List<Opportunity_Split__c>> splitsByOpp = new Map<Id, List<Opportunity_Split__c>>();
            for (Opportunity_Split__c split : oppSplits) {
                if (!splitsByOpp.containsKey(split.Opportunity__c)) {
                    splitsByOpp.put(split.Opportunity__c, new List<Opportunity_Split__c>());
                }
                splitsByOpp.get(split.Opportunity__c).add(split);
            }

            // Step 4: Process Opportunities to update splits
            List<Opportunity_Split__c> splitsToUpdate = new List<Opportunity_Split__c>();
            
            for (Opportunity opp : openOpps) {
                List<Opportunity_Split__c> splits = splitsByOpp.get(opp.Id);
                
                // Check if the splits list is not null
                if (splits != null) {
                    Boolean newOwnerHasSplit = false;
                    Opportunity_Split__c previousOwnerSplit = null;
            
                    // Check existing splits and ensure we respect the default split logic
                    for (Opportunity_Split__c split : splits) {
                        // If the split already belongs to the new owner, don't update.
                        if (split.OwnerId == opp.OwnerId) {
                            newOwnerHasSplit = true;
                        }
            
                        // Check for the split owned by the previous owner, if available
                        System.debug('Previous Owner ID: ' + opp.Previous_Owner__c);
						System.debug('Split Owner ID: ' + split.OwnerId);
                        if (split.OwnerId == opp.Previous_Owner__c) {
                            previousOwnerSplit = split;
                        }
                    }
            
                    // Step 5: Update the previous owner split if no split exists for the new owner
                    if (!newOwnerHasSplit) {
                        // Check if the previous owner has a split record
                        if (previousOwnerSplit != null) {
                            // If there is a split for the previous owner, update the OwnerId to the new Opportunity owner
                            previousOwnerSplit.OwnerId = opp.OwnerId; 
                            splitsToUpdate.add(previousOwnerSplit);    
                        }
                    }
                } else {
                    System.debug('No splits found for Opportunity ID: ' + opp.Id);
                }
            }

            // Step 6: Perform DML operation to update splits
            if (!splitsToUpdate.isEmpty()) {
                update splitsToUpdate;
                DataLogService.logInfo('Scheduled Class: OpportunitySplitOwnerUpdate', 
                                        'Splits Owners Updated:' + splitsToUpdate);
                System.debug(splitsToUpdate.size() + ' Opportunity Splits updated.');
            } else {
                System.debug('No Opportunity Splits needed updates.');
                DataLogService.logError(
                    'OpportunitySplitUpdater Apex Class',
                    'No Opportunity Splits needed Updates'
                );
            }
            
        } catch (Exception e) {
            // Log error using DataLogService
            String errorMessage = 'Error in OpportunitySplitUpdater: ' + e.getMessage();
            String stackTrace = e.getStackTraceString();
            
            // Call the logError method from DataLogService
            DataLogService.logError(
                'OpportunitySplitUpdater Apex Class',
                errorMessage + '\n\nStack Trace:\n' + stackTrace
            );

            // Optionally, rethrow the exception if you want it to be visible in the logs as well
            throw e;  
        }
    }
}