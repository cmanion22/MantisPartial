public class FetchMantisContacts {
    public class ContactList
    {
        public List<MantisContact> ContactList;
    }
     @Future(callout=true)
    public static void makeContactGetCallout() {
        Http http = new Http();
        HttpRequest request = new HttpRequest(); 
        request.setEndpoint('callout:IgniteBasic/companyContacts');
        request.setMethod('GET');
        HttpResponse response = http.send(request);
        // If the request is successful, parse the JSON response.
        if (response.getStatusCode() == 200) {   
            DataLogService.logInfo(
                'FetchMantisContacts Apex Class',
                'Callout returned an HTTP ' + response.getStatusCode() + ' response.\n\n Response body:\n' + response.getBody()
            );           
        	String jsonStr = '{"ContactList":' + response.getBody() + '}';
            //System.debug('API Contacts' + jsonStr);
            
            ContactList contactList = new ContactList();
            contactList = (ContactList)System.JSON.deserialize(jsonStr, ContactList.class);
  
            List<MantisContact> mContact = contactList.ContactList;
            if(mContact.Size()>0){    
                
                Map<String, MantisContact> mantisContactMap = new Map<String, MantisContact>(); 
                List<Integer> mantisId = new List<Integer>();
                // Convert the List into Map
                for(MantisContact m: mContact){
                    mantisContactMap.put(m.Email, m);
                    mantisId.add(m.CompanyID);
                }
                System.debug('Sending contact map:'+ mantisContactMap);

                //UpsertAccountContact.SyncContact(mantisContactMap, mantisId);                
            }
            else{
                System.debug('Empty API response.');
            }
        } else {
            DataLogService.logError(
                'FetchMantisContacts Apex Class',
                'Callout returned an HTTP ' + response.getStatusCode() + ' response.\n\n Response body:\n' + response.getBody()
            );
        }
    }


}