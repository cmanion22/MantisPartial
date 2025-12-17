public with sharing class ContactCalloutClass {

    public static String updateContact(Id contactId, Id syncUserId) { 
        System.debug('ContactCalloutClass-->updateContact-->contactId-->' + contactId);
        return ContactHelper.postUpdateContactJson(contactId, syncUserId);
    }

}