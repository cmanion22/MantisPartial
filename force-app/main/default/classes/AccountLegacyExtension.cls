public class AccountLegacyExtension {

    public string db {get; set;}
    public string notes {get; set;}

    public AccountLegacyExtension(ApexPages.StandardController cont) {
        String acctId = ApexPages.currentPage().getParameters().get('id');
        Account acct = [SELECT Source_Database__c, Description FROM Account WHERE id=:acctId];
        this.db = acct.Source_Database__c;
        this.notes = acct.Description;      
    }    
}