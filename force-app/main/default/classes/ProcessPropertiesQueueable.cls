public class ProcessPropertiesQueueable implements Queueable, Database.AllowsCallouts {
    private List<ApiResponsePropertyWrapper> properties;
    private String companyUUID;
    
    public ProcessPropertiesQueueable(List<ApiResponsePropertyWrapper> properties, String companyUUID) {
        this.properties = properties;
        this.companyUUID = companyUUID;
    }
    
    public void execute(QueueableContext context) {
        
        try {
            // Ensure companyUUID is not null or empty before proceeding
            if (String.isEmpty(companyUUID)) {
                System.debug('companyUUID is null or empty');
                DataLogService.logInfo('ProcessPropertiesQueueable', 'companyUUID is null or empty');
                return;
            }
            
            Account company;
            try {
                company = [
                    SELECT Id FROM Account WHERE Company_UUID__c = :companyUUID LIMIT 1
                ];
            } catch (Exception e) {
                DataLogService.logError('ProcessPropertiesQueueable', 'Failed to retrieve Account for UUID: ' + companyUUID + ' | ' + e.getMessage());
                return;
            }
            
            
            if (company == null) {
                System.debug('No company found for the given companyUUID');
                DataLogService.logInfo('ProcessPropertiesQueueable', 'No Account found for companyUUID: ' + companyUUID);
                return; 
            }
            
            Set<String> propertyIds = new Set<String>();
            for (ApiResponsePropertyWrapper propertyWrapper : properties) {
                propertyIds.add(propertyWrapper.id);
            }
            
            // Query existing properties based on property_uuid__c to check for existing records
            List<Property__c> existingProperties = [
                SELECT Id, property_uuid__c, company_uuid__c, Name, Add1__c, Add2__c, City__c, State__c, Zip__c, Country__c, Active__c, Account__c
                FROM Property__c
                WHERE property_uuid__c IN :propertyIds
            ];
            
            // Create a map for fast lookup of existing properties by property_uuid__c
            Map<String, Property__c> propertiesByPropertyId = new Map<String, Property__c>();
            for (Property__c property : existingProperties) {
                propertiesByPropertyId.put(property.property_uuid__c, property);
            }
            
            List<Property__c> propertiesToUpsert = new List<Property__c>();
            
            // Process each property and either update or create new
            for (ApiResponsePropertyWrapper propertyWrapper : properties) {
                Property__c property;
                
                // If the property exists in the map, update it; otherwise, create a new one
                if (propertiesByPropertyId.containsKey(propertyWrapper.id)) {
                    property = propertiesByPropertyId.get(propertyWrapper.id);
                } else {
                    property = new Property__c();
                }
                
                // Populate property fields with data from propertyWrapper
                property.property_uuid__c = propertyWrapper.id;
                property.company_uuid__c = propertyWrapper.company_id;
                property.Name = propertyWrapper.name;
                property.Add1__c = propertyWrapper.address_1;
                property.Add2__c = propertyWrapper.address_2;
                property.City__c = propertyWrapper.city;
                property.State__c = propertyWrapper.state;
                property.Zip__c = propertyWrapper.zip;
                property.Country__c = propertyWrapper.country;
                property.Active__c = propertyWrapper.active;
                property.Account__c = (company != null) ? company.Id : null;
                
                // Add the property to the list of properties to upsert
                propertiesToUpsert.add(property);
            }
            
            // Perform the upsert operation if there are properties to upsert
            if (!propertiesToUpsert.isEmpty()) {
                // Optional: Break the upsert into chunks if the list gets too large to avoid DML limits
                Integer chunkSize = 200; // Salesforce DML limit for records is 10,000, so 200 is a safe threshold
                
                // Loop through the properties list in chunks manually
                for (Integer i = 0; i < propertiesToUpsert.size(); i += chunkSize) {
                    // Create a new list to store the current chunk
                    List<Property__c> chunk = new List<Property__c>();
                    
                    // Add the elements for the current chunk
                    for (Integer j = i; j < Math.min(i + chunkSize, propertiesToUpsert.size()); j++) {
                        chunk.add(propertiesToUpsert[j]);
                    }
                    
                    try {
                        upsert chunk;
                    } catch (DmlException dmlEx) {
                        DataLogService.logError('ProcessPropertiesQueueable', 'Upsert failed for chunk. Error: ' + dmlEx.getMessage());
                    }
                }
            }
        } catch (Exception ex) {
            String errMsg = 'Error in ProcessPropertiesQueueable | companyUUID: ' + companyUUID +
                ' | Message: ' + ex.getMessage() +
                ' | StackTrace: ' + ex.getStackTraceString();
            DataLogService.logError('ProcessPropertiesQueueable', errMsg);
        }
        
    }
}