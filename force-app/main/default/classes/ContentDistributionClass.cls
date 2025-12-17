@RestResource(urlMapping='/ContentDistribution/*')
global with sharing class ContentDistributionClass {
    @HttpGet
    global static List<ContentDistribution> getWorkOrderId() {
        RestRequest request = RestContext.request;
        // grab the caseId from the end of the URL
        String LinkedEntityId = request.requestURI.substring(
          request.requestURI.lastIndexOf('/')+1);
        System.debug('LinkedEntityId'+LinkedEntityId);
        ContentDocumentLink resultlink = [SELECT ContentDocumentId 
                                          FROM ContentDocumentLink
                                          where LinkedEntityId = :LinkedEntityId];
        List<ContentDistribution> result =  [SELECT ContentDownloadUrl FROM ContentDistribution WHERE ContentDocumentId = :resultlink.ContentDocumentId];
        return result;
    }
}