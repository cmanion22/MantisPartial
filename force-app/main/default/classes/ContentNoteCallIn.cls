@RestResource(urlMapping='/UploadTaskNoteToSF/*')
global with sharing class ContentNoteCallIn {
   
    @HttpPost
    global static ContentNote createContentNote() {
    //ContentNote 
        System.debug('ContentNoteCallIn ->createContentNote');
        RestRequest request = RestContext.request;
        System.debug('Request Body --> ' + request.requestbody.tostring());
        Map<String, Object> params = (Map<String, Object>)JSON.deserializeUntyped(request.requestbody.tostring());
        
        System.debug('ContentNoteCallIn ->createContentNote->ContentNote map1-->' + params);
       
        ContentNote objCn = new ContentNote();
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ShareType = 'V';
          
        for(String fieldName : params.keySet()) 
        {                        
            System.debug(fieldName + ' = ' + params.get(fieldName));      
            
            objCn.Title = 'Note from backoffice'; 
                
            if(fieldName == 'Content')        
                objCn.Content = Blob.valueOf(params.get(fieldName).tostring());  
            
            if(fieldName == 'OwnerId')        
                objCn.OwnerId = params.get(fieldName).tostring();              
                
            if(fieldName == 'ParentTaskId')
                cdl.LinkedEntityId = params.get(fieldName).tostring();
        }
                
        System.debug('ContentNoteCallIn -->createContentNote-here');
        insert objCn;        
      
        cdl.ContentDocumentId = objCn.Id;        
        insert cdl;
        
        System.debug('ContentNoteCallIn -->createContentNote-->ContentDocumentLink-->' + cdl); 
        System.debug('ContentNoteCallIn -->ContentNote -->ContentDocumentLink-->' + objCn);
        
        ContentNote cn = [SELECT Id, TextPreview, Content FROM ContentNote WHERE Id =: objCn.Id];
        System.debug('Content=' + EncodingUtil.base64Encode(cn.Content));
        System.debug('Content=' + cn.Content.toString());
        //cn.Content = cn.Content.toString();
        return cn;       

    } 
}