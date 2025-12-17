public class MonthlyOppCloseDatePushBatch implements Database.Batchable<SObject> {

    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator([SELECT Id, StageName, CloseDate FROM Opportunity WHERE CloseDate < THIS_MONTH AND Demo_Opportunity__c = false AND IsClosed = false AND (LeadSource != 'Partner' OR (LeadSource = 'Partner' AND Partner_Account_Name_Text__c != null))]);
    }

    public void execute(Database.BatchableContext context, List<SObject> scope) {
        for (SObject scopeRecord : scope) {
            Opportunity opportunity = (Opportunity) scopeRecord;

            // Skip certain inactive Closed Lost stages that were not correctly set up with the Closed/Lost stage type
            if (opportunity.StageName.contains('Closed')) continue;

            Date startOfCurrentMonth = Date.today().toStartOfMonth();
            Date newCloseDate;

            if (opportunity.StageName == '0 - Delayed') {
                newCloseDate = startOfCurrentMonth.addMonths(1);
                Integer daysInNewCloseDateMonth = Date.daysInMonth(newCloseDate.year(), newCloseDate.month());
                opportunity.CloseDate = Date.newInstance(newCloseDate.year(), newCloseDate.month(), daysInNewCloseDateMonth);
            } else {
                Integer daysInCurrentMonth = Date.daysInMonth(startOfCurrentMonth.year(), startOfCurrentMonth.month());
                opportunity.CloseDate = Date.newInstance(startOfCurrentMonth.year(), startOfCurrentMonth.month(), daysInCurrentMonth);
            }
        }

        Database.update(scope, false);
    }

    public void finish(Database.BatchableContext context) {
        System.debug('Batch job finished');
    }

}