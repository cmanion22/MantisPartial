public with sharing class DependentPicklistValueInvocable {

    public static Boolean checkDependentPicklistValue(String objectName, String controllingField, String dependentField, String controllingValue, String dependentValue) {
        Request request = new Request();
        request.objectName = objectName;
        request.controllingField = controllingField;
        request.dependentField = dependentField;
        request.controllingValue = controllingValue;
        request.dependentValue = dependentValue;

        List<Response> responses = checkDependentPicklistValue(new List<Request> { request });

        return responses[0].picklistValueIsValid;
    }

    @InvocableMethod(label='Check if picklist value is valid according to its controlling picklist settings')
    public static List<Response> checkDependentPicklistValue(List<Request> requests) {
        List<Response> responses = new List<Response>();

        for (Request request : requests) {
            Response response = new Response();

            Map<String, List<String>> fieldDependencies = DependentPicklistUtils.getFieldDependencies(request.objectName, request.controllingField, request.dependentField);

            if (!fieldDependencies.containsKey(request.controllingValue) || !fieldDependencies.get(request.controllingValue).contains(request.dependentValue)) {
                response.picklistValueIsValid = false;
            } else {
                response.picklistValueIsValid = true;
            }

            responses.add(response);
        }

        return responses;
    }

    public class Request {
        @InvocableVariable(required=true)
        public String objectName;
        @InvocableVariable(required=true)
        public String controllingField;
        @InvocableVariable(required=true)
        public String dependentField;
        @InvocableVariable(required=true)
        public String controllingValue;
        @InvocableVariable(required=true)
        public String dependentValue;
    }

    public class Response {
        @InvocableVariable
        public Boolean picklistValueIsValid;
    }
}