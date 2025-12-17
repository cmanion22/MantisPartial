public with sharing class TaskCalloutClass { 
    public static string updateTask(Id taskId, Id syncUserId) {  
        return TaskHelper.postUpdateTaskJson(taskId, syncUserId);
    }   

    public static string createTaskComment(ID contentDocumentId, ID taskId) {
        System.debug('TaskCalloutClass->createTaskComment-->contentDocumentId' + contentDocumentId + ' | taskId--> ' + taskId);
        return TaskHelper.postCreateTaskCommentJson(contentDocumentId, taskId);
    }
}