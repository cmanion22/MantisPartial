public class Helper {
    //Returns formatted json without attributes which are added by SF objects
    public static string getFormattedJson(Object obj) {     
        System.debug('Entering getFormattedJson');
        Map<String, Object> resultMap = (Map<String,Object>)JSON.deserializeUntyped(JSON.serialize(obj, false));
        removeAttributes(resultMap);
        //NG: Temporary 
        setTemporaryValues(resultMap);
        String resultJson = JSON.serialize(resultMap, false);
        
        System.debug('Exiting getFormattedJson');
        return resultJson;
    }
    
    public static void removeAttributes(Map<String, Object> jsonObj)  {
        for(String key : jsonObj.keySet()) {
            if(key == 'attributes') {
                jsonObj.remove(key);
            } 
        }  
    }

    // NG: Sets temporary values for Entity, Market and Broker for testing in CGDEV2 env
    // Should be deleted later
    public static void setTemporaryValues(Map<String, Object> jsonObj)  {
        for(String key : jsonObj.keySet()) {
            if(key == 'Entity__c') {
                jsonObj.put(key, 'a043I000001jL33QAE');//'a043k00001pgn7WAAQ'
            } 
            else if(key == 'Market__c') {
                jsonObj.put(key, 'a003I000001E9jqQAC');//'a003k00000RwVXgAAN'
            }
            else if(key == 'Broker__c') {
                jsonObj.put(key, 'a033I0000006zomQAA');//'a033k00000RcM1WAAV'
            } 
        } 
    }

    public static string generateSelectQuery(String objectName)
    {
        System.debug('Helper->generateSelectQuery-->Creating select * query');
        //String objectName = objectName;  // modify as needed
        String query = 'SELECT';
        Map<String, Schema.SObjectField> objectFields = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap();

        // Grab the fields from the describe method and append them to the queryString one by one.
        for(String field : objectFields.keySet()) {
            query += ' ' + field + ', ';
        }
        
        if(objectName == 'Opportunity'){
           query += 'RecordType.Name '; 
        }

        // Strip off the last comma if it exists.
       if ( query.subString(query.Length()-2, query.Length()).trim() == ',')
       {
            query = query.subString(0,query.Length()-2);
        }
        
        // Add FROM statement
        query += ' FROM ' + objectName;
        System.debug('Helper-->generateSelectQuery-->query-->' + query);
        return query;
    }
        
    public static Retry.Status httpRetryScenario(integer statusCode) {
        System.debug('Helper-->httpRetryScenario-->statusCode-->' + statusCode);
        if (statusCode == 400) {
            return Retry.Status.BAD_REQUEST;
        } else if (statusCode == 401) {            
            return Retry.Status.UNAUTHORISED;
        } else if (statusCode == 403) {
            return Retry.Status.FORBIDDEN;
        } else if (statusCode == 404) {
            return Retry.Status.NOT_FOUND;
        } else if (statusCode == 500) {
            return Retry.Status.INTERNAL_SERVER_ERROR;
        } else if (statusCode == 503) {
            return Retry.Status.SERVICE_UNAVAILABLE;
        } else if (statusCode != 200 && statusCode != 201) {
            return Retry.Status.FAILED_RETRY;
        }        
        return Retry.Status.SUCCEEDED;
    }
    
    public static Map<String,Object> getJsonMap(Object obj) {     
        System.debug('Entering getJsonMap');
        Map<String, Object> resultMap = (Map<String,Object>)JSON.deserializeUntyped(JSON.serialize(obj, false));
      
        System.debug('Exiting getJsonMap');
        return resultMap ;
    }
    
    public static Map<String,Object> removeAttribute(Map<String, Object> jsonObj, String attribName) {     
        System.debug('Entering getJsonMap');
        
        for(String key : jsonObj.keySet()) {
            if(key == attribName) {
                jsonObj.remove(key);
            } 
        }  
      
        System.debug('Exiting getJsonMap');
        return jsonObj;
    }
    
    public static Map<String,Object> addAttribute(Map<String, Object> jsonObj, String attribName, String attribValue) {     
        System.debug('Entering getJsonMap');
        
        jsonObj.put(attribName, attribValue);      
            
        System.debug('Exiting getJsonMap');
        return jsonObj;
    }
    
    public static string getFormattedJsonFromMap(Map<String, Object> resultMap) {     
        System.debug('Entering getFormattedJson');

        String resultJson = JSON.serialize(resultMap, false);
        
        System.debug('Exiting getFormattedJson');
        return resultJson;
    }

    public static ID getSyncDataId(SObject record)
    {
        String sObjectId = (String)record.get('Id');
        String queryStr = 'SELECT Sync_Data__c FROM ' + record.getSObjectType() + ' WHERE Id =: sObjectId';
        System.debug('Helper-->updateSyncData-->queryStr-->' + queryStr);
        Sobject result = Database.query(queryStr);

        String syncDataId = (String)result.get('Sync_Data__c');
        System.debug('Helper-->updateSyncData-->Sync_Data__c-->' + syncDataId);
        return syncDataId;
    }
    

    public static Sobject clearSyncData(ID id) 
    {
        System.debug('Helper-->clearSyncData-->Id=' + id);        

        if(!IsRecordLocked(id))
        {
            LockRecord(id);
        }

        SObject record = getSObject(id);
        System.debug('Helper-->clearSyncData-->record-->' + record);
        record.put('Out_of_Sync__c', false);        
        record.put('Sync_Lock_Timestamp__c', null);
        //record.put('SyncMessageDisplay__c', false);
        
        if (id.getSObjectType().getDescribe().getName() != 'Task'){
            record.put('Sync_Payload__c', null);
            //record.put('Sync_Error__c', null);
        }

        update record;

        UnlockRecord(id);

        return record;
    }
    
    
    public static Sobject getSObject(ID id) 
    {      
        SObject record = id.getSObjectType().newSObject(id);
        return record;
    } 
    
   
    public static boolean LockRecord(ID id)
    {
        System.debug('Helper->LockRecord - begin');
        
        Trigger_Disabled__c disabled = Trigger_Disabled__c.getValues(id); 
        
        if (disabled == null)
        {
            disabled = new Trigger_Disabled__c();
            disabled.Name = id;
            upsert disabled Name;
            System.debug('Helper->LockRecord - Locked');
            return true;
        }
        else
        {
            System.debug('Helper->LockRecord - Already Locked');
            return false;
        }
    }
   
    public static boolean UnlockRecord(ID id)
    {
        System.debug('Helper->UnlockRecord - begin');
        
        Trigger_Disabled__c disabled = Trigger_Disabled__c.getValues(id); 
        
        if (disabled == null)
        {
            System.debug('Helper->UnlockRecord- No lock found');
            return false;
        }
        else
        {
            delete disabled;
            System.debug('Helper->UnlockRecord- Unlocked');
            return true;
        }
    }
   
    public static boolean IsRecordLocked(ID id)
    {
        System.debug('Helper->IsRecordLocked - begin');
        
        Trigger_Disabled__c disabled = Trigger_Disabled__c.getValues(id); 
        
        if (disabled != null)
        {
            System.debug('Helper->IsRecordLocked - true');
            return true;
        }
        else
        {
            System.debug('Helper->IsRecordLocked - false');
            return false;
        }
    }
}