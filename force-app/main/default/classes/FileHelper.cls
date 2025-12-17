public class FileHelper {    
    public static string createFileJson(ID opportunityId)
    {
        List<ClsFile> lstClsFile = new List<ClsFile>();       
        List<ContentDocument> lstContentDocument = getFiles(opportunityId);        
            
        String fileJson = '';             
        for(ContentDocument cd : lstContentDocument) {            
            lstClsFile.Add(createClsFile(cd, opportunityId));
        }          
        
        fileJson = JSON.serialize(lstClsFile, false);
        System.debug('FileHelper-->createFileJson-->fileJson-->' + fileJson);        
        return fileJson;
    }
    
    public static List<ContentDocument> getFiles(ID opportunityId) {
        List<ContentDocumentLink> lstContentDocumentLink = [
                                                             SELECT ContentDocumentId 
                                                             FROM ContentDocumentLink 
                                                             WHERE LinkedEntityId = :opportunityId
                                                           ]; 
                                                           
        String contentDocumentIDs = '';
        for (ContentDocumentLink cdl : lstContentDocumentLink) {
            String id_in_quotes = '\'' + cdl.ContentDocumentId + '\'';
            if (contentDocumentIDs != '') { contentDocumentIDs += ',' ; }  //  add a comma if this isn't the first one
            contentDocumentIDs += id_in_quotes;
        }
        
        System.debug('FileHelper-->getFiles-->contentDocumentIDs -->' + contentDocumentIDs); 
                
        List<ContentDocument> lstContentDocument = new List<ContentDocument>();
        if(!String.isEmpty(contentDocumentIDs)) {
            String soqlGetContentDocuments = '  SELECT  Id, CreatedById, CreatedDate, LastModifiedById, LastModifiedDate, ' + 
                                                       ' IsArchived, ArchivedById, ArchivedDate, IsDeleted, OwnerId, SystemModstamp, ' + 
                                                       ' Title, PublishStatus, LatestPublishedVersionId, ParentId, LastViewedDate, ' + 
                                                       ' LastReferencedDate, Description, ContentSize, FileType, FileExtension, ' + 
                                                       ' SharingOption, SharingPrivacy, ContentModifiedDate, ContentAssetId ' + 
                                               ' FROM ContentDocument ' + 
                                               ' WHERE Id IN (' + contentDocumentIDs + ') ORDER BY Id ASC';
            lstContentDocument  = database.query(soqlGetContentDocuments);  
        }
        
        System.debug('FileHelper-->getFiles-->lstContentDocument-->' + lstContentDocument); 
        return lstContentDocument;
    }
    
    public static ClsFile createClsFile(ContentDocument cd, ID opportunityId) {
        ClsFile clsFileObj = new ClsFile();
        clsFileObj.Id = cd.Id;
        
        List<ContentDistribution> lstContentDistribution = [
                                                             SELECT DistributionPublicUrl 
                                                             FROM ContentDistribution 
                                                             WHERE ContentDocumentId = :cd.Id
                                                           ];
        if (lstContentDistribution.size() > 0) {       
            clsFileObj.DistributionPublicUrl = lstContentDistribution[0].DistributionPublicUrl; 
        } else { clsFileObj.DistributionPublicUrl = ''; }

        clsFileObj.Title = cd.Title; 
        clsFileObj.Description = cd.Description;
        clsFileObj.FileExtension = cd.FileExtension;
        clsFileObj.ContentSize = cd.ContentSize;
        clsFileObj.OpportunityId = opportunityId;
        
        clsFileObj.CreatedById = cd.CreatedById;
        clsFileObj.CreatedDate = cd.CreatedDate;
        clsFileObj.LastModifiedById = cd.LastModifiedById;
        clsFileObj.LastModifiedDate = cd.LastModifiedDate;
        clsFileObj.IsArchived = cd.IsArchived;
        clsFileObj.ArchivedById = cd.ArchivedById;    
        clsFileObj.ArchivedDate = cd.ArchivedDate;
        clsFileObj.IsDeleted = cd.IsDeleted;
        clsFileObj.OwnerId = cd.OwnerId;
        clsFileObj.SystemModstamp = cd.SystemModstamp; 
        clsFileObj.PublishStatus = cd.PublishStatus;     
        clsFileObj.LatestPublishedVersionId = cd.LatestPublishedVersionId;
        clsFileObj.ParentId = cd.ParentId;
        clsFileObj.LastViewedDate = cd.LastViewedDate;
        clsFileObj.LastReferencedDate = cd.LastReferencedDate; 
        clsFileObj.FileType = cd.FileType; 
        clsFileObj.SharingOption = cd.SharingOption;
        clsFileObj.SharingPrivacy = cd.SharingPrivacy;
        clsFileObj.ContentModifiedDate = cd.ContentModifiedDate;
        clsFileObj.ContentAssetId = cd.ContentAssetId;
        
        System.debug('FileHelper-->createClsFile-->clsFileObj-->' + clsFileObj);

        return clsFileObj;
    }
    
    public static ContentDistribution insertContentDistribution(ContentDocument cd) {
        ContentDistribution contentDistribution = new ContentDistribution();
        contentDistribution.Name = cd.Title.abbreviate(100);
        contentDistribution.ContentVersionId = [SELECT Id FROM ContentVersion WHERE ContentDocumentId =:cd.Id].Id;
        contentDistribution.PreferencesAllowOriginalDownload = true;
        contentDistribution.PreferencesAllowPDFDownload = false;
        contentDistribution.PreferencesPasswordRequired = false;
        contentDistribution.PreferencesAllowViewInBrowser = true;
        contentDistribution.PreferencesAllowPDFDownload = true;
        
        System.debug('FileHelper-->insertContentDistribution-->contentDistribution-->' + contentDistribution);

        insert contentDistribution;             
        return contentDistribution;
    }
    
    public static string postDeleteFileJson(ID contentDocumentId, ID opportunityId) {
        System.debug('FileHelper-->postDeleteFileJson-->contentDocumentId -->' + contentDocumentId);
        System.debug('FileHelper-->postDeleteFileJson-->opportunityId --> ' + opportunityId);

        String apiToken = [SELECT API_Token__c FROM User WHERE Id = :UserInfo.getUserId()].API_Token__c;
        String contentDocumentLinkId = [SELECT Id FROM ContentDocumentLink WHERE ContentDocumentId = :contentDocumentId AND LinkedEntityId = :opportunityId].Id;

        String body = '{"api_token":"' + apiToken + '","event":"delete_file","data":{"content_document_link":{"Id":"' + contentDocumentLinkId + '","LinkedEntityId":"' + opportunityId + '","ContentDocumentId":"' + contentDocumentId + '"}}}';
        
        System.debug('FileHelper-->postDeleteFileJson-->Body -->' + body); 
        System.enqueueJob(new HttpRetryAsync(ESBController.getESBUrl(), 'POST', body, 'DeleteFile'));
        return body; 
    }
    
    public static string postFileUploadedJson(Id contentDocumentLinkId, ID contentDocumentId, ID opportunityId) {
        System.debug('FileHelper-->postFileUploadedJson-->contentDocumentId --> ' + contentDocumentId);
        System.debug('FileHelper-->postFileUploadedJson-->opportunityId --> ' + opportunityId);

        String fileJson = '';
        ContentDocument cd = [SELECT  Id, CreatedById, CreatedDate, LastModifiedById, LastModifiedDate, IsArchived, ArchivedById,
                                    ArchivedDate, IsDeleted, OwnerId, SystemModstamp, Title, PublishStatus, 
                                    LatestPublishedVersionId, ParentId, LastViewedDate, LastReferencedDate, Description, 
                                    ContentSize, FileType, FileExtension, SharingOption, SharingPrivacy, ContentModifiedDate, 
                                    ContentAssetId
                            FROM    ContentDocument 
                            WHERE   Id =:contentDocumentId];

        String apiToken = [SELECT API_Token__c FROM User WHERE Id = :UserInfo.getUserId()].API_Token__c;

        insertContentDistribution(cd);
        //ClsFile clsFileObj = createClsFile(cd, opportunityId);

        //fileJson = JSON.serialize(clsFileObj, false);

        String body = '{"api_token": "' + apiToken + '", "event": "upload_file", "data": { "content_document_link": { "Id": "' + contentDocumentLinkId + '" } } }';

        System.debug('FileHelper-->postFileUploadedJson-->Body -->' + body);
        System.enqueueJob(new HttpRetryAsync(ESBController.getESBUrl(), 'POST', body, 'FileUploaded'));
        return body;
    }
}