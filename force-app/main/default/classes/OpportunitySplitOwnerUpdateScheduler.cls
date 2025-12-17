global class OpportunitySplitOwnerUpdateScheduler implements Schedulable {
    global void execute(SchedulableContext ctx) {
        OpportunitySplitOwnerUpdate.updateOpportunitySplits();
    }
}