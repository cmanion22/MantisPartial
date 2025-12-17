public class UnanetInvoiceSyncScheduler implements Schedulable {
    public void execute(SchedulableContext sc) {
        UnanetInvoiceSyncBatch batch = new UnanetInvoiceSyncBatch();
        Database.executeBatch(batch, 50); 
    }
}