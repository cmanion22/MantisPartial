// Trigger is fired when:
// 1. a file is added to Opportunity after / along with File Upload
// 2. a note is added to a task
//Updates:
/*@JaceKoretz @ 5.20.25: To ensure files sync correctly to the BO with Attachment_Type__c
- Added A new Map to contain the correct ContentDocumetId 
- Assigned the Map after the cd query to be used in the cvList query and Queried the Content Version record that was created on Upload
- Added logic to ensure that there was a delay in syncing if Attachment Tyoe is currently null because Attachment type gets assigned
after the CD, CDL, and CV get committed to the database
*/
trigger ContentDocumentLinkTrigger on ContentDocumentLink (after insert) {
    Turn_off_Processes__c processSettings = Turn_off_Processes__c.getValues('migration in progress');

    if(processSettings != null) {
        System.debug('ContentDocumentLinkTrigger-->processSettings.Is_Active__c-->' + processSettings.Is_Active__c);
        
        if(processSettings.Is_Active__c) 
        {
            return;
        }

        /* Fix for the issue where: INSERT/UPDATE calls from custom / native endpoints to Salesforce objects
         resulted in the execution of respective object’s update trigger. Due to this the UPDATE operation 
         from custom/native endpoint was not resulting in data update at SF end, 
         and since the trigger was fired it was posting the data to EMEX which was not expected.  */
        String callingURL = System.URL.getCurrentRequestUrl().getPath();
        System.debug('ContentDocumentLinkTrigger-->callingURL-->' + callingURL);
        Boolean requestFromRestApi = callingURL.contains('/services/apexrest/') || callingURL.contains('/services/data');
        Boolean requestFromBackOfficeUser = UserInfo.getUserName().contains('mantissfadmin@emexllc.com');
        if(requestFromRestApi && requestFromBackOfficeUser)
        { return;
        }

        if(Trigger.isInsert) {
            String strObjPrefix;
            List<Id> setCDLIds = new List<Id>();
            List<Id> setCntDocIds = new List<Id>();
            List<Id> setOppIds = new List<Id>(); 
            List<Id> setTaskIds = new List<Id>();
            Map<Id, ContentDocument> contentDocumentMap = new Map<Id, ContentDocument>(); //set up map to be used later for content version query 
            
            for(ContentDocumentLink clIterator : Trigger.new) {  
                System.debug('ContentDocumentLinkTrigger-->clIterator-->' + clIterator);    
                            
                strObjPrefix = String.valueOf(clIterator.LinkedEntityId).substring(0, 3); 
                System.debug('ContentDocumentLinkTrigger-->strObjPrefix-->' + strObjPrefix);
                                
                if(strObjPrefix == Opportunity.sObjectType.getDescribe().getKeyPrefix()) {
                    ContentDocument cd = [SELECT Id, FileType, CreatedDate FROM ContentDocument WHERE Id =:clIterator.ContentDocumentId]; contentDocumentMap.put(clIterator.ContentDocumentId, cd); //assigning correct CD Id to map established above to use in CV query
                    if (cd.FileType != 'SNOTE') { setCntDocIds.add(clIterator.ContentDocumentId); setOppIds.add(clIterator.LinkedEntityId); setCDLIds.add(clIterator.Id);
                    }
                }                 
                else if (strObjPrefix == Task.sObjectType.getDescribe().getKeyPrefix()) 
                {
                    setCntDocIds.add(clIterator.ContentDocumentId);
                    setTaskIds.add(clIterator.LinkedEntityId);
                }                        
            }
            
            System.debug('ContentDocumentLinkTrigger-->setCntDocIds-->' + setCntDocIds + 
            ' | setOppIds-->' + setOppIds + ' | setTaskIds-->' + setTaskIds);
            System.debug('SetCntDocIds Size: ' + setCntDocIds.size());
            System.debug('setOppIds Size: ' + setOppIds.size());
            Boolean isTestExecution = true; // Used to Bypass the Test.IsRunningTest Else logic
  
            list <Task> isTestExecutionTasks = [SELECT Id, Subject 
												FROM Task
												WHERE Subject = 'isTestExecution'];
            system.debug('isTestExecutionTasks List size: ' + isTestExecutionTasks.size());
            
            if (isTestExecutionTasks.size() > 0) {
                isTestExecution = false;
            }
                         
            if(setCntDocIds.size() > 0) {                  
                if(setOppIds.size() > 0) {
                   system.debug('isTestExecution boolean: ' + isTestExecution);
             	   system.debug('Running Test condtion logic: ' + Test.isRunningTest()); 
                    /*if(Test.isRunningTest() && isTestExecution) {
                        System.debug('ContentDocumentLinkTrigger-->Test.RunningTest()');                            
                        Test.setMock(HttpCalloutMock.class, new HttpEmexCalloutMock(200, 'OK', '{success:true}'));
                    } else {*/
                        //correctly assign cd id with map
                        Id firstContentDocumentId = setCntDocIds[0]; ContentDocument firstContentDocument = contentDocumentMap.get(firstContentDocumentId);
                        //Query the Content Version record that was just created and will sync to BO
                        List<ContentVersion> cvList = [SELECT Id, Attachment_Type__c, CreatedDate FROM ContentVersion WHERE ContentDocumentId = :firstContentDocumentId AND CreatedDate = :firstContentDocument.CreatedDate LIMIT 1]; if(cvList.size() > 0){ ContentVersion cv = cvList[0];                               
                       if (cv.Attachment_Type__c == null){ Datetime scheduledTime = Datetime.now().addMinutes(2); /* Format scheduled time to a string representation of the cron expression*/ String cronExpression = scheduledTime.second() + ' ' + scheduledTime.minute() + ' ' + scheduledTime.hour() + ' ' + scheduledTime.day() + ' ' + scheduledTime.month() + ' ? ' + scheduledTime.year(); /* Schedule the job*/ DelayedFileDataSyncScheduler job = new DelayedFileDataSyncScheduler(setCDLIds[0], setCntDocIds[0], setOppIds[0]); String jobId = System.schedule('DelayedFileCallout_' + DateTime.now().getTime(), cronExpression, job);
                       } else { FileCalloutClass.uploadFile(setCDLIds[0], setCntDocIds[0], setOppIds[0]);
                        }
                      } 
                    //}
                } else if (setTaskIds.size() > 0) {
                    if(Test.isRunningTest()) {
                        System.debug('ContentDocumentLinkTrigger-->Test.RunningTest()');                            
                        Test.setMock(HttpCalloutMock.class, new HttpEmexCalloutMock(200, 'OK', '{success:true}'));
                    } else { TaskCalloutClass.createTaskComment(setCntDocIds[0], setTaskIds[0]);
                    }
                }
            }
        }                
    }
}