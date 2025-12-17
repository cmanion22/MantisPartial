public with sharing class DataLogService {

    public static Data_Log__c logInfo(String logOrigin, String description, String relatedRecordId) {
        return insertDataLog(logOrigin, description, relatedRecordId, 'Info');
    }

    public static Data_Log__c logInfo(String logOrigin, String description) {
        return insertDataLog(logOrigin, description, null, 'Info');
    }

    public static Data_Log__c logError(String logOrigin, String description, String relatedRecordId) {
        return insertDataLog(logOrigin, description, relatedRecordId, 'Error');
    }

    public static Data_Log__c logError(String logOrigin, String description) {
        return insertDataLog(logOrigin, description, null, 'Error');
    }

    public static Data_Log__c insertDataLog(String logOrigin, String description, String relatedRecordId, String severity) {
        Data_Log__c dataLog = new Data_Log__c();
        dataLog.Log_Origin__c = logOrigin;
        dataLog.Description__c = description;
        dataLog.Related_Record_Id__c = relatedRecordId;
        dataLog.Log_Severity__c = severity;

        insert dataLog;

        return dataLog;
    }

}