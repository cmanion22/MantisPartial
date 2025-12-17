public with sharing class ProcessDefectsQueueable implements Queueable, Database.AllowsCallouts {
    private List<ApiResponseDefectWrapper> defects;

    public ProcessDefectsQueueable(List<ApiResponseDefectWrapper> defects) {
        this.defects = defects;
    }

    public void execute(QueueableContext context) {

        if (defects == null || defects.isEmpty()) {
            DataLogService.logInfo('ProcessDefectsQueueable', 'No defects passed for processing.');
            return;
        }

        List<Defect__c> defectsToUpsert = new list<Defect__c>();

        Set<String> defectIds = new Set<String>();
        for(ApiResponseDefectWrapper defect : defects) {
            defectIds.add(defect.id);
        }

        List<Defect__c> existingDefects = [SELECT Id,
                                                    defect_uuid__c,
                                                    company_uuid__c,
                                                    property_uuid__c,
                                                    section_uuid__c,
                                                    survey_uuid__c,
                                                    AssetType__c,
                                                    AssetMaterialType__c,
                                                    BuildingName__c,
                                                    SecID__c,
                                                    DefTitle__c,
                                                    DefectLabel__c,
                                                    UOM__c,
                                                    Quantity__c,
                                                    SeverityTitle__c,
                                                    Status__c,
                                                    Recommend__c,
                                                    Deleted_At__c                                            
                                                FROM Defect__c
                                                WHERE defect_uuid__c IN :defectIds];
        Map<String, Defect__c> defectsByDefectUUID = new Map<String, Defect__c>();
        for(Defect__c defect : existingDefects) {
            if(defect.defect_uuid__c != null) {
                defectsByDefectUUID.put(defect.defect_uuid__c, defect);
            }
        }

        Integer defUpdated = 0;
        Integer defCreated = 0;
        for (ApiResponseDefectWrapper defectWrapper : defects) {
            Defect__c defect;

            if (defectsByDefectUUID.containsKey(defectWrapper.id)) {
                defect = defectsByDefectUUID.get(defectWrapper.id);
                defUpdated ++;
            } else {
                defect = new Defect__c();
                defCreated ++;
            }

            defect.defect_uuid__c = defectWrapper.id;
            defect.company_uuid__c = defectWrapper.company_id;
            defect.property_uuid__c = defectWrapper.property_id;
            defect.section_uuid__c = defectWrapper.section_id;
            defect.survey_uuid__c = defectWrapper.survey_id;
            defect.AssetMaterialType__c = defectWrapper.asset_material_type;
            defect.BuildingName__c = defectWrapper.building_name;
            defect.SecID__c = defectWrapper.section_code;
            defect.DefTitle__c = defectWrapper.name;
            defect.DefectLabel__c = defectWrapper.label;
            defect.UOM__c = defectWrapper.uom;
            defect.Quantity__c = defectWrapper.quantity;
            defect.SeverityTitle__c = defectWrapper.severity_title;
            defect.Status__c = defectWrapper.status;
            defect.Recommend__c = defectWrapper.recommendation;
            defect.Deleted_At__c = defectWrapper.deleted_at;

            defectsToUpsert.add(defect);
        }
        System.debug('# of Defects Updated: ' + defUpdated);
        System.debug('# of Defects Created: ' + defCreated);
        
        if(!defectsToUpsert.isEmpty()) {
            try {
                upsert defectsToUpsert;
            } catch (DmlException dmlEx) {
                DataLogService.logError('ProcessDefectsQueueable', 
                    'Failed to upsert defects. Msg: ' + dmlEx.getMessage() + 
                    ' | Stack: ' + dmlEx.getStackTraceString());
            }
        }
    }
}