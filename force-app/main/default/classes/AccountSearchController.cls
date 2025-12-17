public class AccountSearchController {
	
    public string accountUrl {get; set;}
    Account currentRecord = new Account();
    public Boolean displayNoRecordSection {get; set;}
    
    public AccountSearchController(ApexPages.StandardController controller) 
    {
        ID currentAccountId = controller.getRecord().get('id').tostring();
        this.accountUrl = ESBController.getAccountESBUrl(currentAccountId);
        
        this.displayNoRecordSection = false;           
        
        If(accountUrl.length()==0)
        {
            this.displayNoRecordSection = true;
        }
    }
}