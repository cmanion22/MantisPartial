/**
 * 9.25.2024.
 * Commenting out the code so records do not get updated. 
 * The business decided that Sales reps will now be in charge of updating the closed date.
 * The corresponding scheduled job was also deleted. 
 * - Cody Manion 
*/

public class OppCloseDatePushBatch implements Database.Batchable<SObject>, Schedulable {

    public static void scheduleDaily() {
         String sch = '0 0 1 1 * ?'; // Every 1st day of the month at 1 AM
         System.schedule('Opportunity Close Date Push', sch, new OppCloseDatePushBatch());
    }

    public void execute(SchedulableContext sc) {
        // Database.executeBatch(new OppCloseDatePushBatch(), 10);
    }

    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator([SELECT Id, StageName, CloseDate FROM Opportunity WHERE CloseDate < THIS_MONTH AND Demo_Opportunity__c = false AND IsClosed = false AND (LeadSource != 'Partner' OR (LeadSource = 'Partner' AND Partner_Account_Name_Text__c != null))]);
    }

    public void execute(Database.BatchableContext context, List<SObject> scope) {
        /*List<Opportunity> oppsToUpdate = new List<Opportunity>();

        for (SObject scopeRecord : scope) {
            Opportunity opportunity = (Opportunity) scopeRecord;

            // Skip certain inactive Closed Lost stages that were not correctly set up with the Closed/Lost stage type
            if (opportunity.StageName.contains('Closed')) continue;

            Date oppDate = Date.valueOf(opportunity.CloseDate);
            Date dateToday = Date.today();

            // If Stage is Delayed, adds an extra month. Otherwise, new Close Date will be set to current month
            Date newCloseDateMonth = opportunity.StageName != '0 - Delayed' ? dateToday : dateToday.toStartOfMonth().addMonths(1); */

            /**
             * If the day of the previous Close Date doesn't exist in the new Close Date month (e.g. previous Close 
             * Date was on the 31st and new Close Date month has only 30 days), then set the new Close Date to the 
             * last day of the current month
             */
            /*Integer lastDayOfNewCloseDateMonth = Date.daysInMonth(newCloseDateMonth.year(), newCloseDateMonth.month());
            Integer newCloseDateDay = oppDate.day() <= lastDayOfNewCloseDateMonth ? oppDate.day() : lastDayOfNewCloseDateMonth;

            Date newCloseDate = Date.newInstance(newCloseDateMonth.year(), newCloseDateMonth.month(), newCloseDateDay);
            opportunity.CloseDate = newCloseDate;

            oppsToUpdate.add(opportunity);
        }

        Database.update(oppsToUpdate, false); */
    }

    public void finish(Database.BatchableContext context) {
        // System.debug('Batch job finished');
    }

}