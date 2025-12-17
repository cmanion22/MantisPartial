public with sharing class PartnerOppAccUpdatesInvocable {
    
    @InvocableMethod(label='Partner Opp Roll-ups for Account Updates Flow')
    public static List<Response> partnerOppRollups(List<Request> requests) {
        List<Response> responses = new List<Response>();

        for (Request request : requests) {
            Response response = new Response();
            for (Opportunity opp : request.opps) {
                if (opp.IsClosed && opp.IsWon) {
                    response.latestCloseDate = response.latestCloseDate == null || opp.CloseDate > response.latestCloseDate ? opp.CloseDate : response.latestCloseDate;
                    response.totalWonAmount += opp.Amount != null ? opp.Amount : 0;
                    response.totalWonOpps++;
                } else if (!opp.IsClosed) {
                    response.totalOpenOpps++;
                }
            }
            responses.add(response);
        }

        return responses;
    }

    public class Request {
        @InvocableVariable
        public List<Opportunity> opps;
    }

    public class Response {
        @InvocableVariable
        public Date latestCloseDate;
        @InvocableVariable
        public Decimal totalWonAmount = 0;
        @InvocableVariable
        public Integer totalWonOpps = 0;
        @InvocableVariable
        public Integer totalOpenOpps = 0;
    }

}