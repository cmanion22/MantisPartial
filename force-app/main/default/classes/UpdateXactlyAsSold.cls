public class UpdateXactlyAsSold {
    public static void updateProjects(List<Opportunity> opps) {
        if (opps == null || opps.isEmpty()) {
            System.debug('UpdateXactlyAsSold.updateProjects: Opportunities list is empty or null');
            return;
        }

        Opportunity opp = opps[0];
        List<Project__C> projsToUpdate = new List<Project__C>();

        List<Project__C> relatedProjs = [
            SELECT Id, As_Sold_Gross_Margin2__c, Xactly_As_Sold_Gross_Margin__c
            FROM Project__C
            WHERE Opportunity__c = :opp.Id
        ];
        System.debug('UpdateXactlyAsSold.updateProjects Related Projects: ' + relatedProjs.size());

        if (!relatedProjs.isEmpty()) {
            for (Project__C proj : relatedProjs) {
                proj.Xactly_As_Sold_Gross_Margin__c = proj.As_Sold_Gross_Margin2__c;
                projsToUpdate.add(proj);
            }
        } else {
            System.debug('UpdateXactlyAsSold.updateProjects No related projects found: ' + opp.Id);
            DataLogService.logInfo('UpdateXactlyAsSold.updateProjects', 'No related projects found', opp.Id);
        }

        if (!projsToUpdate.isEmpty()) {
            try {
                update projsToUpdate;
            } catch (Exception e) {
                System.debug('UpdateXactlyAsSold.updateProjects DML Exception: ' + e.getMessage());
                DataLogService.logError('UpdateXactlyAsSold.updateProjects', 'DML Update Failed: ' + e.getMessage(), opp.Id);
            }
        }
    }
}