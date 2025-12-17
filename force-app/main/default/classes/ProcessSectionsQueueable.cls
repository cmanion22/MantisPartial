public with sharing class ProcessSectionsQueueable implements Queueable, Database.AllowsCallouts {
    private List<ApiResponseSectionWrapper> sections;

    public ProcessSectionsQueueable(List<ApiResponseSectionWrapper> sections) {
        this.sections = sections;
    }


    public void execute(QueueableContext context) {

        if (sections == null || sections.isEmpty()) {
            DataLogService.logInfo('ProcessSectionsQueueable', 'No section data provided.');
            return;
        }
        // Extract section UUIDs
        Set<String> sectionUUIDs = collectSectionUUIDS(sections);
        
        // Get existing Section records based on the section UUIDs
        List<Section__c> existingSections = [SELECT
                                                Id,
                                                section_uuid__c,
                                                company_uuid__c,
                                                property_uuid__c,
                                                SecID__c,
                                                Name,
                                                TotalSF__c,
                                                SystemType__c,
                                                MaterialType__c,
                                                Property__c,
                                                Deleted_At__c                                            
                                            FROM Section__c
                                            WHERE 
                                            section_uuid__c IN :sectionUUIDs];
        
        Map<String, Section__c> sectionsBySectionUUID = getSectionsBySectionUUID(existingSections);

        // Assume property_uuid is needed and passed
        String propertyUUID = sections.isEmpty() ? null : sections[0].property_id;

        Property__c property = null;
        try {
            property = [SELECT Id FROM Property__c WHERE property_uuid__c = :propertyUUID LIMIT 1];
        } catch (Exception ex) {
            DataLogService.logError('ProcessSectionsQueueable', 'Property__c not found for UUID: ' + propertyUUID);
        }

        List<Section__c> sectionsToUpsert = new List<Section__c>();
        Integer secUpdated = 0;
        Integer secCreated = 0;

        // Handle records from the API response and update/create Section__c instances
        for (ApiResponseSectionWrapper sectionWrapper : sections) {
            Section__c section;

            if (sectionsBySectionUUID.get(sectionWrapper.id) != null) {
                section = sectionsBySectionUUID.get(sectionWrapper.id);
                secUpdated++;
            } else {
                section = new Section__c();
                secCreated++;
            }

            section.section_uuid__c = sectionWrapper.id;
            section.company_uuid__c = sectionWrapper.company_id;
            section.property_uuid__c = sectionWrapper.property_id;
            section.SecID__c = sectionWrapper.code;
            section.Name = sectionWrapper.Name;
            section.TotalSF__c = Decimal.valueOf(sectionWrapper.total_area);
            section.SystemType__c = sectionWrapper.asset_type;
            section.MaterialType__c = sectionWrapper.classification_name;
            section.Property__c = (property == null) ? null : property.Id;
            section.Deleted_At__c = (sectionWrapper.deleted_at == null) ? null : sectionWrapper.deleted_at;

            sectionsToUpsert.add(section);
        }

        System.debug('# of Sections upserted: ' + sectionsToUpsert.size());
        System.debug('# of Sections updated: ' + secUpdated);
        System.debug('# of Sections created: ' + secCreated);
        
        try {
                upsert sectionsToUpsert;
            } catch (DmlException dmlEx) {
                DataLogService.logError('ProcessSectionsQueueable', 
                    'Upsert failed. Msg: ' + dmlEx.getMessage() + ' | Stack: ' + dmlEx.getStackTraceString());
            }
    }

    private Set<String> collectSectionUUIDS(List<ApiResponseSectionWrapper> sectionWrappers) {
        Set<String> sectionUUIDS = new Set<String>();
        for (ApiResponseSectionWrapper sectionWrapper : sectionWrappers) {
            sectionUUIDS.add(sectionWrapper.id);
        }
        return sectionUUIDS;
    }

    private Map<String, Section__c> getSectionsBySectionUUID(List<Section__c> sections) {
        Map<String, Section__c> sectionsBySectionUUID = new Map<String, Section__c>();
        for (Section__c section : sections) {
            sectionsBySectionUUID.put(section.section_uuid__c, section);
        }
        return sectionsBySectionUUID;
    }
}