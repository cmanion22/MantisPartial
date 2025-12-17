public class ContactHelper {
    public static Contact getPrimaryContact(ID opportunityId) {
        // Get Primary Contact for current opportunity
        List<OpportunityContactRole> lstOpportunityContactRole = [
                                                                    Select Id, ContactId 
                                                                    FROM OpportunityContactRole 
                                                                    WHERE OpportunityId = :opportunityId
                                                                    AND IsPrimary = true
                                                                 ]; 
        System.debug('ContactHelper-->getPrimaryContact-->lstOpportunityContactRole-->' + lstOpportunityContactRole);                                                                
        // Get details of Primary Contact   
        return getContactData(lstOpportunityContactRole[0].ContactId) ;
    }
    
    // Get Contact data from SOQL using Contact ID
    public static Contact getContactData(ID contactId) {                 
        String qry = Helper.generateSelectQuery('Contact') + ' WHERE Id =:contactId';      
        System.debug('ContactHelper-->getContactData -->Query-->' + qry);
        Contact contact = database.query(qry); 

        System.debug('ContactHelper-->getContactData -->contact-->' + contact);                    
        return contact;                    
    }

    public static string postUpdateContactJson(ID contactId) {
        System.debug('ContactHelper-->postUpdateContactJson-->contactId --> ' + contactId);
                  
        String contactJson = Helper.getFormattedJson(getContactData(contactId));   
        
        String body = 
                    '{"event": "update_contact"' +
                    ', "data": {' +                
                        '"contact": ' + contactJson +                
                        '}' + 
                    '}';        
        
        System.debug('ContactHelper-->postUpdateContactJson-->Body -->' + body); 
        System.enqueueJob(new HttpRetryAsync(ESBController.getESBUrl(), 'POST', body, 'UpdateContact', contactId)); 
        return body;
    }

    public static String postUpdateContactJson(Id contactId, Id syncUserId) {
        String body = 
                    '{"event": "update_contact"' +
                    ', "data": {' +
                        '"contact": { "Id": "' + contactId + '" }' +
                        '}' + 
                    '}';
        
        System.debug('ContactHelper-->postUpdateContactJson-->Body -->' + body);
        System.enqueueJob(new HttpRetryAsync(ESBController.getESBUrl(syncUserId), 'POST', body, 'UpdateContact', contactId));

        return body;
    }

    public static String postUpdateContactJson(Contact contact) {
        System.debug('ContactHelper-->postUpdateContactJson-->contactId --> ' + contact.Id);

        String contactJson = Helper.getFormattedJson(contact);
        
        String body =
                    '{"event": "update_contact"' +
                    ', "data": {' +
                        '"contact": ' + contactJson +
                        '}' +
                    '}';
        
        System.debug('ContactHelper-->postUpdateContactJson-->Body -->' + body);
        //System.enqueueJob(new HttpRetryAsync(ESBController.getESBUrl(contact.User_for_Back_Office_Resync__c), 'POST', body, 'UpdateContact', contact.Id));
        return body;
    }

    public static Contact upsertContact(Map<String, Object> compositeMapObjects, ID accountId) {               
        Map<String, Object> contactMap = (Map<String, Object>)compositeMapObjects.get('contact');       
        System.debug('ContactHelper-->upsertContact-->contactMap -->' + contactMap);
        Contact thisContact = new Contact(); 
        
        // Iterate through each parameter field and value
        for(String fieldName : contactMap.keySet()) {                        
            System.debug(fieldName + '-' + contactMap.get(fieldName));           
            
            // Set the field and value on the Opportunity sObject
            thisContact.put(fieldName, contactMap.get(fieldName));            
        }
        thisContact.AccountId = accountId;
        System.debug('ContactHelper-->upsertContact-->thisContact -->' + thisContact);
        upsert thisContact;
        
        System.debug('ContactHelper-->upsertContact-->thisContact.Id -->' + thisContact.Id);      
        return thisContact;
    }

    public static boolean validatePrimaryContact(ID contactId){
        boolean isValid = true;

        Contact thisContact = getContactData(contactId);
        if(thisContact.FirstName  == NULL || thisContact.FirstName == '') {
            isValid = false;
        }
        else if(thisContact.MailingStreet  == NULL || thisContact.MailingStreet == '') {
            isValid = false;
        }
        else if(thisContact.MailingCity  == NULL || thisContact.MailingCity == '') {
            isValid = false;
        }
        else if(thisContact.MailingPostalCode  == NULL || thisContact.MailingPostalCode == '') {
            isValid = false;
        }
        else if(thisContact.Phone  == NULL || thisContact.Phone == '') {
            isValid = false;
        }
        else if(thisContact.Email  == NULL || thisContact.Email == '') {
            isValid = false;
        }

        return isValid;
    }  

    public static void updatePrimaryContact(Id contactId){
        Contact contact = new Contact();
        contact.Id = contactId;
        contact.Primary_Contact__c = true;
        update contact;
    }    
}