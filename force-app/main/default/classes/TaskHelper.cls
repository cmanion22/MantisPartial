public class TaskHelper {
    
    public static string postUpdateTaskJson(Task task) {    
        System.debug('TaskHelper->postUpdateTaskJson->task--> ' + task);  

        String body = 
            '{"event": "update_task"' +
            ', "data": {' +                
                '"task": ' + Helper.getFormattedJson(task) +                
              '}' + 
            '}';
        
        System.debug('TaskHelper->postUpdateTaskJson->Body-->' + body);                 
        System.enqueueJob(new HttpRetryAsync(ESBController.getESBUrl(), 'POST', body, 'UpdateTask', task.Id)); 
        return body;
    }

    public static string postUpdateTaskJson(Id taskId, Id syncUserId) {
        String body = '{"event": "update_task", "data": {"task": {"Id": "' + taskId + '"}}}';
        System.enqueueJob(new HttpRetryAsync(ESBController.getESBUrl(syncUserId), 'POST', body, 'UpdateTask', taskId));

        return body;
    }

    public static string postCreateTaskCommentJson(ID contentDocumentId, ID taskId) {    
        System.debug('TaskHelper->postCreateTaskCommentJson->contentDocumentId' + contentDocumentId + ' | taskId--> ' + taskId);  
                
        ContentNote cn = getNotesData(contentDocumentId);
                
        System.debug('TaskHelper->postCreateTaskCommentJson->Task comment JSON-->'+ Helper.getFormattedJson( getNotesData(contentDocumentId)));
            
        Map<String, Object> jsonObj= Helper.removeAttribute(Helper.getJsonMap(cn),'Content');
        jsonObj=Helper.addAttribute(jsonObj, 'Content', cn.Content.toString());
        jsonObj=Helper.addAttribute(jsonObj, 'ParentTaskId', taskId);
            
        String body = 
            '{"event": "create_task_comment"' +
            ', "data": {' +                
                '"taskComment": ' + Helper.getFormattedJsonFromMap(jsonObj) +  
              '}' + 
            '}';
            
        System.debug('TaskHelper->postCreateTaskCommentJson->Body-->' + body);  

        System.enqueueJob(new HttpRetryAsync(ESBController.getESBUrl(), 'POST', body, 'CreateTaskComment')); 
        return body;      
    }
    
    public static ContentNote getNotesData(ID contentDocumentId) {
        ContentNote cn =  [SELECT Id, OwnerId, Content FROM ContentNote WHERE  Id =: contentDocumentId];
        System.debug('TaskHelper-->getNotesData-->ContentNote-->' + cn); 
        return cn;
    }
    
}