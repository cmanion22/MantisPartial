public with sharing class CheckIfRestApiRequestInvocable {

    @InvocableMethod(label='Check if current transaction was started from the REST API')
    public static List<Boolean> checkIfRestApiRequest() {
        return new List<Boolean> { Utils.isRestApiRequest };
    }

}