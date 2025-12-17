public with sharing class FetchInactiveUsersInvocable {

    @InvocableMethod(label='Fetch inactive users from a given Division')
    public static List<Response> fetchInactiveUsers(List<Request> requests) {
        List<Response> responses = new List<Response>();
        Set<String> divisions = new Set<String>();
        Map<String, List<AggregateResult>> resultsByDivision = new Map<String, List<AggregateResult>>();

        for (Request request : requests) {
            divisions.add(request.division);
        }

        List<AggregateResult> groupedResults = [
            SELECT OwnerId, Owner.FirstName, Owner.LastName, Owner.Division
            FROM Account
            WHERE Owner_Active__c = false AND Owner.Division IN :divisions
            GROUP BY OwnerId, Owner.FirstName, Owner.LastName, Owner.Division
            ORDER BY Owner.FirstName
        ];

        for (AggregateResult ar : groupedResults) {
            String resultDivision = (String) ar.get('Division');

            if (!resultsByDivision.containsKey(resultDivision)) {
                resultsByDivision.put(resultDivision, new List<AggregateResult>());
            }

            resultsByDivision.get(resultDivision).add(ar);
        }

        for (Request request : requests) {
            Response response = new Response();

            if (resultsByDivision.containsKey(request.division)) {
                for (AggregateResult ar : resultsByDivision.get(request.division)) {
                    User user = new User();
                    user.Id = (Id) ar.get('OwnerId');
                    user.FirstName = (String) ar.get('FirstName');
                    user.LastName = (String) ar.get('LastName');
                    user.Division = (String) ar.get('Division');
                    response.users.add(user);
                }
            }

            Formula.recalculateFormulas(response.users);

            responses.add(response);
        }

        return responses;
    }

    public class Request {
        @InvocableVariable(required=true)
        public String division;
    }

    public class Response {
        @InvocableVariable
        public List<User> users = new List<User>();
    }
}