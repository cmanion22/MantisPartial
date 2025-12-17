//Trigger is fired when a file is deleted from opportunity.
trigger ContentDocumentTrigger on ContentDocument (before delete) {
    Turn_off_Processes__c processSettings = Turn_off_Processes__c.getValues('migration in progress');
    
    if(processSettings != null) {
        System.debug('ContentDocumentTrigger-->processSettings.Is_Active__c-->' + processSettings.Is_Active__c);
        
        if(processSettings.Is_Active__c) 
        {
            return;
        }

        /* Fix for the issue where: INSERT/UPDATE calls from custom / native endpoints to Salesforce objects
         resulted in the execution of respective object’s update trigger. Due to this the UPDATE operation 
         from custom/native endpoint was not resulting in data update at SF end, 
        and since the trigger was fired it was posting the data to EMEX which was not expected.  */
        String callingURL = System.URL.getCurrentRequestUrl().getPath();
        System.debug('ContentDocumentTrigger-->callingURL-->' + callingURL);
        if(callingURL.contains('/services/apexrest/') || callingURL.contains('/services/data'))
        {
            return;
        }

        String strObjPrefix;    
        List<Id> setOppIds = new List<Id>();            
        
        for (ContentDocument cd: Trigger.old) {
            System.debug('ContentDocumentTrigger-->ContentDocument-->cd-->' + cd);        
            List<ContentDocumentLink> cdls = [SELECT LinkedEntityId FROM ContentDocumentLink WHERE ContentDocumentId = :cd.Id];
            for(ContentDocumentLink cdl : cdls) {
                strObjPrefix = String.valueOf(cdl.LinkedEntityId).substring(0, 3);
                System.debug('ContentDocumentTrigger-->strObjPrefix-->' + strObjPrefix);
                if(strObjPrefix == Opportunity.sObjectType.getDescribe().getKeyPrefix()) {                
                    setOppIds.add(cdl.LinkedEntityId);
                } 
            }
            System.debug('ContentDocumentTrigger-->setOppIds -->' + setOppIds);
            System.debug('ContentDocumentTrigger-->cd.Id -->' + cd.Id);
            
            if(setOppIds.size() > 0) {
                if(Test.isRunningTest()){
                    System.debug('ContentDocumentTrigger-->Test.RunningTest()');                        
                    Test.setMock(HttpCalloutMock.class, new HttpEmexCalloutMock(200, 'OK', '{success:true}'));
                } else {   
                    FileCalloutClass.deleteFile(cd.Id, setOppIds[0]);
                }
            }                                               
        }
    }
}