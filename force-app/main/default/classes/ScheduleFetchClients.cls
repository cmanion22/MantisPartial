global class ScheduleFetchClients implements Schedulable {
    global void execute(SchedulableContext ctx) {
        FetchMantisClients.makeAccountGetCallout();
    }

}