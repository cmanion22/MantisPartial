public class UnanetHelper {

    public static String createOrganization(Account acc, String token, String baseUrl, String oppDivision) {
        // Null Check Params
        if (acc == null) return null;
        if (String.isBlank(token)) return null;
        if (String.isBlank(baseUrl)) return null;
    
        String endpoint = baseUrl + '/platform/rest/organizations';
    
        // Get relative Account fields
        Account acct = [SELECT Id, Name, CurrencyIsoCode, Unanet_Customer_Code__c, Unanet_Id__c, BillingAddress
                        FROM Account
                        WHERE Id = :acc.Id
                        LIMIT 1];
    
        // Check if the Account has a valid Name
        if (acct != null && String.isNotBlank(acct.Name)) {
            // Trim leading/trailing spaces and split by space
            String[] words = acct.Name.trim().split(' ');
    
            // Grab the first word and convert to uppercase
            String firstWord = words.size() > 0 ? words[0].toUpperCase() : '';
    
            // Generate Org Code
            String orgCode = 'C_' + firstWord;

            Integer typeKey = getOrganizationTypeKey('CUSTOMERS', token);
            Integer parentOrgKey = getOrganizationKey('Mantis Customers', token);
            Integer currencyKey = getCurrencyKey(acct.CurrencyIsoCode, token);
            
            String legalEntityName;
            if (oppDivision == 'Efficiency') {
                legalEntityName = 'Fairbanks Energy Services';
            } else if (oppDivision == 'FMS ') {
                legalEntityName = 'Bluefin, LLC';
            } else {
                legalEntityName = 'Bluefin, LLC';
            }
            
            Integer legalEntityOrgKey = getOrganizationKey(legalEntityName, token);
    
            // Prepare request body
            UnanetOrgPutBody orgBody = new UnanetOrgPutBody();
            orgBody.code = orgCode;
            orgBody.name = acct.Name;
            orgBody.active = true;
            orgBody.typeKey = typeKey;
            orgBody.parentOrgKey = parentOrgKey;
            orgBody.currencyCodeKey = currencyKey;
            orgBody.financialOrg = false;
            orgBody.legalEntity = false;
            //orgBody.legalEntityOrgKey = legalEntityOrgKey;

            Map<String, Integer> udfIndexMap = UnanetHelper.getUdfMetadata('ORGANIZATION', token);

            Integer sfIdIndex = udfIndexMap.get('SF Id');
            if (sfIdIndex != null) {
                orgBody.udfs = new UnanetOrgPutBody.UdfWrapper();

                UnanetOrgPutBody.UdfValue sfIdUdf = new UnanetOrgPutBody.UdfValue();
                sfIdUdf.index = sfIdIndex;
                sfIdUdf.value = acc.Id;

                orgBody.udfs.values.add(sfIdUdf);
            }

            String requestBody = JSON.serialize(orgBody);
            System.debug('Serialized JSON body: ' + requestBody);
    
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('POST');
            req.setHeader('Authorization', 'Bearer ' + token);
            req.setHeader('Content-Type', 'application/json');
            req.setBody(requestBody);
    
            System.debug('UnanetHelper.createOrganization Endpoint: ' + endpoint);
            System.debug('UnanetHelper.createOrganization Request Body: ' + requestBody);
    
            try {
                Http http = new Http();
                HttpResponse response = http.send(req);
    
                if (response.getStatusCode() == 200) {
                    String responseBody = response.getBody();
                    Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
                    System.debug('UnanetHelper.createOrganization Callout Successful: ' + response.getStatusCode());
                    System.debug('UnanetHelper.createOrganization Callout Successful: ' + response.getBody());
                    return String.valueOf(result.get('key'));
                } else {
                    System.debug('UnanetHelper.Create Organization Callout Failed' + response.getStatusCode());
                    System.debug('UnanetHelper.Create Organization Callout Failed' + response.getBody());
                    logError('Create Organization Failed', 'Status ' + response.getStatusCode() + ': ' + response.getBody(), null);
                }
            } catch (Exception ex) {
                System.debug('UnanetHelper.Create Organization Callout Failed: ' + ex.getMessage());
                logError('Create Organization Callout Error', ex.getMessage(), null);
            }
        }
    
        return null;
    }        

    public static UnanetOrganizationWrapper getOrganization(String unanetId, String token, String baseUrl) {
        // Null Check Params
        if (String.isBlank(unanetId)) return null;
        if (String.isBlank(token)) return null;
        if (String.isBlank(baseUrl)) return null; 
    
        String endpoint = baseUrl + '/platform/rest/organizations/' + unanetId;
        System.debug('UnanetHelper.getOrganization Endpoint: ' + endpoint);
    
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + token);
        req.setHeader('Content-Type', 'application/json');
    
        try {
            Http http = new Http();
            HttpResponse response = http.send(req);
            if (response.getStatusCode() == 200) {
                UnanetOrganizationWrapper org = 
                    (UnanetOrganizationWrapper) JSON.deserialize(response.getBody(), UnanetOrganizationWrapper.class);
                
                System.debug('UnanetHelper.getOrganization HTTP Status Code: ' + response.getStatusCode());
                System.debug('UnanetHelper.getOrganization HTTP Response Body: ' + response.getBody());
                return org;
            } else {
                System.debug('UnanetHelper Get Organization Callout Failed' + response.getStatusCode());
                System.debug('UnanetHelper Get Organization Callout Failed' + response.getBody());
                logError('UnanetHelper Get Organization Failed', 'Status ' + response.getStatusCode() + ': ' + response.getBody(), null);
            }
        } catch (Exception ex) {
            System.debug('UnanetHelper Get Organization Callout Failed: ' + ex.getMessage());
            logError('UnanetHelper Get Organization Callout Error', ex.getMessage(), null);
        }
        return null;
    }
    
    // Commenting out until Unanet fixes the update bug on their end
    // - Cody Manion 5/8/2024
    /*  
    public static void updateOrganizationWithSFId(UnanetOrganizationWrapper orgWrapper, String sfId, String token, String baseUrl) {
        if (orgWrapper == null || String.isBlank(sfId) || String.isBlank(token) || String.isBlank(baseUrl)) {
            logError('Update Organization Failed', 'Invalid input parameters.', orgWrapper != null ? String.valueOf(orgWrapper.key) : null);
            return;
        }
    
        System.debug('Updating SF Id in orgWrapper: ' + JSON.serialize(orgWrapper));
        // logError('Update Organization: orgWrapper', JSON.serialize(orgWrapper), sfId);
    
        // Ensure udfs and values are initialized
        if (orgWrapper.udfs == null) {
            orgWrapper.udfs = new UnanetOrganizationWrapper.UdfWrapper();
        }
    
        if (orgWrapper.udfs.values == null) {
            orgWrapper.udfs.values = new List<UnanetOrganizationWrapper.UdfValueWrapper>();
        }
    
        // Fetch UDF metadata dynamically using the helper
        Map<String, Integer> udfIndexMap = UnanetHelper.getUdfMetadata('ORGANIZATION', token);
        
        Integer sfIdIndex = udfIndexMap.get('SF Id'); // Retrieve the dynamic index for SF Id
        
        if (sfIdIndex == null) {
            logError('Update Failed', 'SF Id UDF not found in metadata.', String.valueOf(orgWrapper.key));
            return;
        }
    
        // Try to find existing SF Id entry
        Boolean found = false;
        for (UnanetOrganizationWrapper.UdfValueWrapper udf : orgWrapper.udfs.values) {
            if (udf != null && udf.metadata != null && udf.metadata.label == 'SF Id') {
                udf.value = sfId; // Update value if it exists
                found = true;
                break;
            }
        }
    
        // If SF Id entry is not found, add it dynamically
        if (!found) {
            UnanetOrganizationWrapper.UdfValueWrapper sfUdf = new UnanetOrganizationWrapper.UdfValueWrapper();
            sfUdf.index = sfIdIndex;  // Use the dynamic index here
            sfUdf.value = sfId;
    
            UnanetOrganizationWrapper.MetadataWrapper metadata = new UnanetOrganizationWrapper.MetadataWrapper();
            metadata.dataType = 'STRING';
            metadata.label = 'SF Id';
            metadata.visibility = 'ENABLED';
            metadata.required = false;
            metadata.active = true;
    
            sfUdf.metadata = metadata;
            orgWrapper.udfs.values.add(sfUdf);
        }
    
        // Serialize and send request
        String jsonBody = JSON.serialize(orgWrapper);
    
        System.debug('TAX1: ' + orgWrapper.tax1);
        System.debug('TAX2: ' + orgWrapper.tax2);
        System.debug('TAX3: ' + orgWrapper.tax3);
    
        logError('Update Organization Payload', jsonBody, sfId);
    
        HttpRequest req = new HttpRequest();
        req.setEndpoint(baseUrl + '/platform/rest/organizations/' + orgWrapper.key);
        req.setMethod('PUT');
        req.setHeader('Authorization', 'Bearer ' + token);
        req.setHeader('Content-Type', 'application/json');
        req.setBody(jsonBody);
    
        try {
            Http http = new Http();
            HttpResponse res = http.send(req);
    
            if (res.getStatusCode() == 200) {
                System.debug('Organization updated successfully.');
            } else {
                logError('Update Failed', 'Status ' + res.getStatusCode() + ': ' + res.getBody(), String.valueOf(orgWrapper.key));
            }
        } catch (Exception e) {
            logError('Update Organization Failed', 'Exception: ' + e.getMessage(), String.valueOf(orgWrapper.key));
        }
    }
    */
    

    public static void createOrgAddress(Account acc, String unanetId, String baseUrl, String token) {
        // Null check params
        if (acc == null) return;
        if (String.isBlank(unanetId)) return;
        if (String.isBlank(baseUrl)) return;
        if (String.isBlank(token)) return;
        System.debug('UnanetHelper.createOrgAddress() unanetId: ' + unanetId + ' baseUrl: ' + baseUrl + ' token: ' + token);
    
        // Set Endpoint
        String endpoint = baseUrl + '/platform/rest/organizations/' + unanetId + '/addresses';
    
        // Get Account's Legal Address
        Account acct = [SELECT Id, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry
                        FROM Account
                        WHERE Id = :acc.Id
                        LIMIT 1];
        System.debug('UnanetHelper.createOrgAddress Get Accounts Legal Address: ' + acct);
    
        // Prepare the request body
        Map<String, Object> requestBody = new Map<String, Object>();
        requestBody.put('orgKey', unanetId);
        requestBody.put('defaultBillTo', true);
        requestBody.put('defaultShipTo', true);
        requestBody.put('defaultRemitTo', true);
    
        Map<String, Object> addressMap = new Map<String, Object>();
        addressMap.put('streetLine1', acct.BillingStreet);
        addressMap.put('city', acct.BillingCity);
        addressMap.put('stateProvince', acct.BillingState);
        addressMap.put('country', acct.BillingCountry);
        addressMap.put('postalCode', acct.BillingPostalCode);
    
        requestBody.put('primaryAddress', addressMap);
    
        try {
            String jsonBody = JSON.serialize(requestBody);
            System.debug('UnanetHelper.createOrgAddress Organization Address Body: ' + jsonBody);
    
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('POST');
            req.setHeader('Authorization', 'Bearer ' + token);
            req.setHeader('Content-Type', 'application/json');
            req.setBody(jsonBody);
    
            Http http = new Http();
            HttpResponse res = http.send(req);
    
            if (res.getStatusCode() == 200) {
                System.debug('Organization Address created successfully.');
            } else {
                System.debug('Organization Address creation failed.');
                System.debug('UnanetHelper.createOrgAddress Response Status Code: ' + res.getStatusCode());
                System.debug('UnanetHelper.createOrgAddress Endpoint: ' + endpoint);
                System.debug('UnanetHelper.createOrgAddress Response Body: ' + res.getBody());
                logError('Create Organization Address Failed', 'Status ' + res.getStatusCode() + ': ' + res.getBody(), unanetId);
            }
        } catch (Exception e) {
            System.debug('UnanetHelper.createOrgAddress Callout Failed ' + e.getMessage());
            logError('Create Organization Address Failed', 'Exception: ' + e.getMessage(), unanetId);
        }
    }

    public static Integer getOrgContactKey(Contact con, String token, String baseUrl, String orgKey) {
        if (con == null || String.isBlank(con.Email) || String.isBlank(orgKey) || String.isBlank(token) || String.isBlank(baseUrl)) {
            logError('getOrgContactKey', 'Missing required input for contact sync.', (con != null ? con.Id : null));
            return null;
        }
    
        Map<String, Integer> orgContactToKeyMap = new Map<String, Integer>();
        Integer currentPage = 1;
        Integer totalPages = 1;
    
        do {
            try {
                HttpRequest req = new HttpRequest();
                req.setEndpoint(baseUrl + '/platform/rest/organizations/' + orgKey + '/contacts?page=' + currentPage);
                req.setMethod('GET');
                req.setHeader('Authorization', 'Bearer ' + token);
                req.setHeader('Content-Type', 'application/json');
    
                Http http = new Http();
                HttpResponse res = http.send(req);
    
                if (res.getStatusCode() == 200) {
                    UnanetOrgContactResponseWrapper wrapper = (UnanetOrgContactResponseWrapper)
                        JSON.deserialize(res.getBody(), UnanetOrgContactResponseWrapper.class);
    
                    for (UnanetOrgContactListWrapper item : wrapper.items) {
                        if (!String.isBlank(item.primaryEmail)) {
                            orgContactToKeyMap.put(item.primaryEmail.toLowerCase(), item.key);
                        }
                    }
    
                    totalPages = wrapper.pageCount;
                    currentPage++;
                } else {
                    logError('getOrgContactKey', 'Unanet API returned non-200 status: ' + res.getStatus() + ' | Body: ' + res.getBody(), con.Id);
                    return null;
                }
            } catch (Exception e) {
                logError('getOrgContactKey', 'Exception during Unanet contact sync: ' + e.getMessage(), con.Id);
                return null;
            }
    
        } while (currentPage <= totalPages);
    
        return orgContactToKeyMap.get(con.Email.toLowerCase());
    }       

    public class UnanetOrgContactResponseWrapper {
        public List<UnanetOrgContactListWrapper> items;
        public Integer page;
        public Integer pageSize;
        public Integer pageCount;
        public Integer resultCount;
    }
    
    public class UnanetOrgContactListWrapper {
        public Integer key;
        public String first;
        public String middle;
        public String last;
        public String primaryEmail;
        public Boolean active;
    }

    public static String createContact(Contact con, String token, String baseUrl, Integer orgKey) {
        try {
            // Prepare the HTTP request
            HttpRequest req = new HttpRequest();
            req.setEndpoint(baseUrl + '/platform/rest/organizations/' + orgKey + '/contacts'); 
            req.setMethod('POST');
            req.setHeader('Authorization', 'Bearer ' + token); 
            req.setHeader('Content-Type', 'application/json');
            
            Map<String, Object> contactData = new Map<String, Object>();
            
            // Required fields
            contactData.put('orgKey', orgKey);
            contactData.put('active', true); 
            contactData.put('defaultBillTo', false);  
            contactData.put('defaultShipTo', false); 
            contactData.put('defaultRemitTo', false); 
            contactData.put('first', con.FirstName);
            contactData.put('last', con.LastName);
            contactData.put('title', con.Title);
    
            // Phone Numbers
            Integer phoneTypeKey = getPhoneTypeKey('Mobile', token);
    
            List<Map<String, Object>> phoneNumbers = new List<Map<String, Object>>();
            if (String.isNotBlank(con.Phone)) {
                if (phoneTypeKey != null) {
                    Map<String, Object> phone = new Map<String, Object>();
                    phone.put('phoneType', new Map<String, Object>{ 'key' => phoneTypeKey });
                    phone.put('phoneNumber', con.Phone);
                    phone.put('primary', true);  
                    phoneNumbers.add(phone);
                } else {
                    System.debug('Warning: Phone type "Mobile" not found in Unanet.');
                    logError('Missing Phone Type', 'Phone type "Mobile" not found in Unanet for contact: ' + con.FirstName + ' ' + con.LastName, con.Id);
                }
            }
            contactData.put('phoneNumbers', phoneNumbers);
            
            // Email
            String emailType = 'Business';
            Integer emailTypeKey = getEmailTypeKey(emailType, token);
    
            List<Map<String, Object>> emails = new List<Map<String, Object>>();
            if (String.isNotBlank(con.Email)) {
                if (emailTypeKey != null) {
                    Map<String, Object> email = new Map<String, Object>();
                    email.put('emailType', new Map<String, Object>{'key' => emailTypeKey});
                    email.put('email', con.Email);
                    email.put('primary', true);
                    emails.add(email);
                } else {
                    System.debug('Warning: Email type "Business" not found in Unanet.');
                    logError('Missing Email Type', 'Email type "Business" not found in Unanet for contact: ' + con.FirstName + ' ' + con.LastName, con.Id);
                }
            }
            contactData.put('emails', emails);
            
            // Addresses
            List<Map<String, Object>> addresses = new List<Map<String, Object>>();
            if (con.MailingStreet != null) {
                Map<String, Object> addressWrapper = new Map<String, Object>();
    
                Integer mailingKey = getAddressTypeKey('Mailing', token);
                if (mailingKey != null) {
                    addressWrapper.put('addressType', new Map<String, Object>{ 'key' => mailingKey });
                } else {
                    System.debug('Warning: Address type "Mailing" not found in Unanet. Skipping address.');
                    logError('Missing Address Type', 'Address type "Mailing" not found in Unanet for contact: ' + con.FirstName + ' ' + con.LastName, con.Id);
                }
    
                // Prepare the nested address structure
                Map<String, Object> addressDetails = new Map<String, Object>();
                addressDetails.put('streetLine1', con.MailingStreet);
                addressDetails.put('city', con.MailingCity);
                addressDetails.put('stateProvince', con.MailingState);
                addressDetails.put('postalCode', con.MailingPostalCode);
                addressDetails.put('country', con.MailingCountry);
    
                addressWrapper.put('address', addressDetails);
                addressWrapper.put('primary', true);
    
                addresses.add(addressWrapper);
            } else {
                logError('Missing Address', 'No mailing address found for contact: ' + con.FirstName + ' ' + con.LastName, con.Id);
            }
            contactData.put('addresses', addresses);
    
    
            // Fetch UDF metadata dynamically for the 'CONTACT' type
            Map<String, Integer> udfIndexMap = UnanetHelper.getUdfMetadata('ORG_CONTACT', token);

            // Retrieve the dynamic index for 'SF Id'
            Integer sfIdIndex = udfIndexMap.get('SF Id');
            if (sfIdIndex == null) {
                logError('Update Failed', 'SF Id UDF not found in metadata for ORG_CONTACT.', null);
                return null;
            }

            // UDFs 
            if (con.Id != null) {  
                // Create UDF value for 'SF Id'
                Map<String, Object> udfValue = new Map<String, Object>();
                udfValue.put('index', sfIdIndex);  // Use the dynamic index
                udfValue.put('value', con.Id);     // Assign the Contact Id to the UDF value
                
                // Prepare the UDF wrapper
                Map<String, Object> udfWrapper = new Map<String, Object>();
                udfWrapper.put('values', new List<Object>{ udfValue });
                
                // Add to the contact data
                contactData.put('udfs', udfWrapper);
            }
    
            // Convert the Map to JSON string
            String jsonPayload = JSON.serialize(contactData);
            req.setBody(jsonPayload);
            
            // Send the HTTP request
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            // Check the response status code
            if (res.getStatusCode() == 200) {
                // Parse the response if needed
                Map<String, Object> result = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
                String unanetId = String.valueOf(result.get('key'));
                System.debug('Contact created successfully in Unanet with ID: ' + unanetId);
                return unanetId;  
            } else {
                // Log error if response is not successful
                String errorMessage = res.getBody();
                System.debug('Failed to create contact in Unanet. Status: ' + res.getStatusCode() + ', Message: ' + errorMessage);
    
                logError(
                    'Failed to Create Unanet Contact',
                    'Unanet returned status ' + res.getStatusCode() + ' for contact creation. Response: ' + errorMessage,
                    con.Id
                );
    
                return null;
            }
        } catch (Exception e) {
            // Catch any unexpected errors and log them
            System.debug('Error creating contact in Unanet: ' + e.getMessage());
    
            logError(
                'Exception During Contact Creation',
                'An exception occurred while creating contact in Unanet: ' + e.getMessage(),
                con.Id
            );
    
            return null;
        }
    }
    
    
    public static Integer getAddressTypeKey(String addressType, String token) {
        if (String.isBlank(addressType) || String.isBlank(token)) {
            return null;
        }

        String baseUrl = getUnanetBaseUrl();

        Map<String, Integer> addressTypeToKeyMap = getAddressTypeKeyMap(token, baseUrl);
        return addressTypeToKeyMap.get(addressType);

    }

    private static Map<String, Integer> AddressTypeToKeyMapCache;

    public static Map<String, Integer> getAddressTypeKeyMap(String token, String baseUrl) {
        if (AddressTypeToKeyMapCache != null) {
            System.debug('getAddressTypeKeyMap: returning cached location map');
            return AddressTypeToKeyMapCache;
        }

        AddressTypeToKeyMapCache = new Map<String, Integer>();
        Integer currentPage = 1;
        Integer totalPages = 1;

        do {
            HttpRequest req = new HttpRequest();
            req.setEndpoint(baseUrl + '/platform/rest/contacts/address-types?page=' + currentPage);
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer ' + token);
            req.setHeader('Content-Type', 'application/json');

            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() == 200) {
                try {
                    UnanetAddTypesResponseWrapper wrapper = (UnanetAddTypesResponseWrapper)
                        JSON.deserialize(res.getBody(), UnanetAddTypesResponseWrapper.class);

                    for (UnanetAddTypesListWrapper item : wrapper.items) {
                        AddressTypeToKeyMapCache.put(item.name, item.key);
                    }

                    totalPages = wrapper.pageCount;
                    currentPage++;
                } catch (Exception e) {
                    throw new CalloutException('Error deserializing location response: ' + e.getMessage());
                }
            } else {
                throw new CalloutException('Failed to fetch Unanet Address Types. Status: ' +
                    res.getStatus() + ', Body: ' + res.getBody());
            }

        } while (currentPage <= totalPages);

        return AddressTypeToKeyMapCache;
    }

    public class UnanetAddTypesResponseWrapper {
        public List<UnanetAddTypesListWrapper> items;
        public Integer page;
        public Integer pageSize;
        public Integer pageCount;
        public Integer resultCount;
    }

    public class UnanetAddTypesListWrapper {
        public Integer key;
        public String name;
    }

    public static Integer getPhoneTypeKey(String phoneType, String token) {
        if(phoneType == null || String.isBlank(token)) {
            return null;
        }

        String baseUrl = getUnanetBaseUrl();

        Map<String, Integer> phoneTypeToKeyMap = getPhoneTypeKeyMap(token, baseUrl);
        Integer key = phoneTypeToKeyMap.get(phoneType);

        return key;
    }

    private static Map<String, Integer> PhoneTypeToKeyMapCache;

    public static Map<String, Integer> getPhoneTypeKeyMap(String token, String baseUrl) {
        if (PhoneTypeToKeyMapCache != null) {
            System.debug('getPhoneTypeKeyMap: returning cached PhoneType map');
            return PhoneTypeToKeyMapCache;
        }

        PhoneTypeToKeyMapCache = new Map<String, Integer>();
        Integer currentPage = 1;
        Integer totalPages = 1;

        do {
            HttpRequest req = new HttpRequest();
            req.setEndpoint(baseUrl + '/platform/rest/contacts/phone-types?page=' + currentPage);
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer ' + token);
            req.setHeader('Content-Type', 'application/json');

            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() == 200) {
                try {
                    UnanetPhoneTypesResponseWrapper wrapper = (UnanetPhoneTypesResponseWrapper)
                        JSON.deserialize(res.getBody(), UnanetPhoneTypesResponseWrapper.class);

                    for (UnanetPhoneTypesListWrapper item : wrapper.items) {
                        PhoneTypeToKeyMapCache.put(item.name, item.key);
                    }

                    totalPages = wrapper.pageCount;
                    currentPage++;
                } catch (Exception e) {
                    throw new CalloutException('Error deserializing phoneType response: ' + e.getMessage());
                }
            } else {
                throw new CalloutException('Failed to fetch Unanet Phone Types. Status: ' +
                    res.getStatus() + ', Body: ' + res.getBody());
            }

        } while (currentPage <= totalPages);

        return PhoneTypeToKeyMapCache;
    }

    public class UnanetPhoneTypesResponseWrapper {
        public List<UnanetPhoneTypesListWrapper> items;
        public Integer page;
        public Integer pageSize;
        public Integer pageCount;
        public Integer resultCount;
    }

    public class UnanetPhoneTypesListWrapper {
        public Integer key;
        public String name;
    }

    // Cache
    private static Map<String, Integer> EmailTypeToKeyMapCache;

    // Public method to get Email Type Key
    public static Integer getEmailTypeKey(String emailType, String token) {
        if (emailType == null || String.isBlank(token)) {
            return null;
        }

        String baseUrl = getUnanetBaseUrl();

        Map<String, Integer> emailTypeToKeyMap = getEmailTypeKeyMap(token, baseUrl);
        return emailTypeToKeyMap.get(emailType);
    }

    // Private method to fetch and cache Email Types
    public static Map<String, Integer> getEmailTypeKeyMap(String token, String baseUrl) {
        if (EmailTypeToKeyMapCache != null) {
            System.debug('getEmailTypeKeyMap: returning cached EmailType map');
            return EmailTypeToKeyMapCache;
        }

        EmailTypeToKeyMapCache = new Map<String, Integer>();
        Integer currentPage = 1;
        Integer totalPages = 1;

        do {
            HttpRequest req = new HttpRequest();
            req.setEndpoint(baseUrl + '/platform/rest/contacts/email-types?page=' + currentPage);
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer ' + token);
            req.setHeader('Content-Type', 'application/json');

            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() == 200) {
                try {
                    UnanetEmailTypesResponseWrapper wrapper = (UnanetEmailTypesResponseWrapper)
                        JSON.deserialize(res.getBody(), UnanetEmailTypesResponseWrapper.class);

                    for (UnanetEmailTypesListWrapper item : wrapper.items) {
                        EmailTypeToKeyMapCache.put(item.name, item.key);
                    }

                    totalPages = wrapper.pageCount;
                    currentPage++;
                } catch (Exception e) {
                    throw new CalloutException('Error deserializing emailType response: ' + e.getMessage());
                }
            } else {
                throw new CalloutException('Failed to fetch Unanet Email Types. Status: ' +
                    res.getStatus() + ', Body: ' + res.getBody());
            }

        } while (currentPage <= totalPages);

        return EmailTypeToKeyMapCache;
    }

    // Wrappers
    public class UnanetEmailTypesResponseWrapper {
        public List<UnanetEmailTypesListWrapper> items;
        public Integer page;
        public Integer pageSize;
        public Integer pageCount;
        public Integer resultCount;
    }

    public class UnanetEmailTypesListWrapper {
        public Integer key;
        public String name;
    }

    public static String buildFixedPriceItemPayload(Project__c coProj, String parentUnanetKey) {
        Map<String, Object> payload = new Map<String, Object>();
        
        // Safely parse projectKey
        Integer parsedProjectKey = 0;
        try {
            parsedProjectKey = Integer.valueOf(parentUnanetKey);
        } catch (Exception e) {
            parsedProjectKey = 0;
        }
        payload.put('projectKey', parsedProjectKey);
    
        // Add description
        String rawDescription = coProj.Name + ' - ' + coProj.Account__r.Name + ' - ' + coProj.Project_Number__c;
        String fallbackDescription = coProj.Name + ' - ' + coProj.Project_Number__c;
        
        String description = rawDescription.length() <= 128 ? rawDescription : fallbackDescription;
        
        payload.put('description', description);

        // Format and add bill date
        Date endDate = coProj != null ? coProj.End_Date__c : null;
        payload.put('billDate', UnanetProjectHelper.formatDate(endDate)); 
        payload.put('billOnCompletion', false);  
        payload.put('revenueRecognitionMethod', 'PERCENT_COMPLETE'); 
        
        // Determine amount based on project type
        Decimal amount = 0;
        if (coProj != null && coProj.Type__c != null) {
            if (coProj.Type__c == 'Standard Project') {
                amount = coProj.Project_Amount__c;
            } else if (coProj.Type__c == 'Change Order' && coProj.Parent_Project__r.Type__c == 'Standard Project') {
                amount = coProj.Project_Amount__c;
            } else if (coProj.Type__c == 'Change Order' && 
                      (coProj.Parent_Project__r.Type__c == 'PT' || coProj.Parent_Project__r.Type__c == 'EXP')) {
                amount = coProj.Pass_Through_Costs__c != null ? coProj.Pass_Through_Costs__c : 0;
            } else if (coProj.Type__c == 'EXP' || coProj.Type__c == 'PT') {
                amount = coProj.Pass_Through_Costs__c != null ? coProj.Pass_Through_Costs__c : 0;
            }
        }

    
        payload.put('amount', amount);
    
        return JSON.serialize(payload);
    }

    public static Integer getCurrencyKey(String isoCurrencyCode, String token) {
        if (String.isBlank(isoCurrencyCode) || String.isBlank(token)) {
            System.debug('getProjectCurrencyKey: isoCurrencyCode or token is null/blank');
            return null;
        }

        String baseUrl = getUnanetBaseUrl();
        Map<String, Integer> currencyMap = getCurrencyKeyMap(token, baseUrl);

        Integer key = currencyMap.get(isoCurrencyCode);
        System.debug('Currency ISO Code: ' + isoCurrencyCode + ' returned Key: ' + key);
        return key;
    }

    private static Map<String, Integer> isoCurrencyCodeToKeyCache;

    public static Map<String, Integer> getCurrencyKeyMap(String token, String baseUrl) {
        if (isoCurrencyCodeToKeyCache != null) {
            System.debug('getCurrencyKeyMap: returning cached currency map');
            return isoCurrencyCodeToKeyCache;
        }

        isoCurrencyCodeToKeyCache = new Map<String, Integer>();
        Integer currentPage = 1;
        Integer totalPages = 1;

        do {
            HttpRequest req = new HttpRequest();
            req.setEndpoint(baseUrl + '/platform/rest/currencies/currency-codes?page=' + currentPage);
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer ' + token);
            req.setHeader('Content-Type', 'application/json');

            Http http = new Http();
            HttpResponse res;

            try {
                res = http.send(req);
            } catch (Exception ex) {
                System.debug('HTTP callout failed: ' + ex.getMessage());
                logError('Currency Key Fetch Error', ex.getMessage(), null);
                throw new CalloutException('Failed to send request to Unanet: ' + ex.getMessage());
            }

            if (res.getStatusCode() == 200) {
                try {
                    UnanetCurrencyResponseWrapper wrapper = (UnanetCurrencyResponseWrapper)
                        JSON.deserialize(res.getBody(), UnanetCurrencyResponseWrapper.class);

                    for (UnanetCurrencyWrapper item : wrapper.items) {
                        if (!String.isBlank(item.isoCurrencyCode)) {
                            isoCurrencyCodeToKeyCache.put(item.isoCurrencyCode, item.key);
                        }
                    }

                    totalPages = wrapper.pageCount;
                    currentPage++;
                } catch (Exception e) {
                    System.debug('Deserialization error: ' + e.getMessage());
                    logError('Currency Key Deserialization Error', e.getMessage(), null);
                    throw new CalloutException('Error deserializing currency response: ' + e.getMessage());
                }
            } else {
                String errorMsg = 'Unanet currency fetch failed. Status: ' +
                    res.getStatus() + ', Body: ' + res.getBody();
                System.debug(errorMsg);
                logError('Currency Key Fetch Failure', errorMsg, null);
                throw new CalloutException(errorMsg);
            }

        } while (currentPage <= totalPages);

        return isoCurrencyCodeToKeyCache;
    }

    public class UnanetCurrencyResponseWrapper {
        public List<UnanetCurrencyWrapper> items;
        public Integer page;
        public Integer pageSize;
        public Integer pageCount;
        public Integer resultCount;
    }
    
    public class UnanetCurrencyWrapper {
        public Integer key;
        public String isoNumericCode;
        public String isoCurrencyCode;
        public String name;
        public Integer decimals;
    }

    public static Integer getOrganizationTypeKey(String orgTypeName, String token) {
        if (String.isBlank(orgTypeName) || String.isBlank(token)) {
            System.debug('getOrganizationTypeKey: orgTypeName or token is blank.');
            return null;
        }
    
        String baseUrl = getUnanetBaseUrl();
        Map<String, Integer> orgTypeKeyMap = getOrganizationTypeKeyMap(token, baseUrl);
    
        Integer key = orgTypeKeyMap.get(orgTypeName);
        System.debug('Organization Type "' + orgTypeName + '" returned key: ' + key);
        return key;
    }
    
    private static Map<String, Integer> orgTypeKeyMapCache;
    
    public static Map<String, Integer> getOrganizationTypeKeyMap(String token, String baseUrl) {
        if (orgTypeKeyMapCache != null) {
            System.debug('getOrganizationTypeKeyMap: returning cached map');
            return orgTypeKeyMapCache;
        }
    
        orgTypeKeyMapCache = new Map<String, Integer>();
        Integer currentPage = 1;
        Integer totalPages = 1;
    
        do {
            HttpRequest req = new HttpRequest();
            req.setEndpoint(baseUrl + '/platform/rest/organization-types?page=' + currentPage);
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer ' + token);
            req.setHeader('Content-Type', 'application/json');
    
            Http http = new Http();
            HttpResponse res = http.send(req);
    
            if (res.getStatusCode() == 200) {
                try {
                    UnanetOrgTypeResponseWrapper wrapper = (UnanetOrgTypeResponseWrapper)
                        JSON.deserialize(res.getBody(), UnanetOrgTypeResponseWrapper.class);
    
                    for (UnanetOrgTypeWrapper item : wrapper.items) {
                        orgTypeKeyMapCache.put(item.name, item.key);
                    }
    
                    totalPages = wrapper.pageCount;
                    currentPage++;
                } catch (Exception e) {
                    logError('OrganizationType Key Map Error', e.getMessage(), null);
                    throw new CalloutException('Error deserializing organization type response: ' + e.getMessage());
                }
            } else {
                logError('OrganizationType API Failure', res.getBody(), null);
                throw new CalloutException('Failed to fetch organization types. Status: ' +
                    res.getStatus() + ', Body: ' + res.getBody());
            }
        } while (currentPage <= totalPages);
    
        return orgTypeKeyMapCache;
    }
    
    public class UnanetOrgTypeResponseWrapper {
        public List<UnanetOrgTypeWrapper> items;
        public Integer page;
        public Integer pageSize;
        public Integer pageCount;
        public Integer resultCount;
    }
    
    public class UnanetOrgTypeWrapper {
        public Integer key;
        public String name;
        public String description;
    }
    
    public static Integer getOrganizationKey(String orgIdentifier, String token) {
        if (String.isBlank(orgIdentifier) || String.isBlank(token)) {
            System.debug('getOrganizationKey: orgIdentifier or token is blank.');
            return null;
        }
    
        String baseUrl = getUnanetBaseUrl();
        Map<String, Integer> orgKeyMap = getOrganizationKeyMap(token, baseUrl);
    
        Integer key = orgKeyMap.get(orgIdentifier);
        System.debug('Organization Identifier "' + orgIdentifier + '" returned key: ' + key);
        return key;
    }
    
    private static Map<String, Integer> orgKeyMapCache;
    
    public static Map<String, Integer> getOrganizationKeyMap(String token, String baseUrl) {
        if (orgKeyMapCache != null) {
            System.debug('getOrganizationKeyMap: returning cached map');
            return orgKeyMapCache;
        }
    
        orgKeyMapCache = new Map<String, Integer>();
    
        HttpRequest req = new HttpRequest();
        req.setEndpoint(baseUrl + '/platform/rest/organizations/list');
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + token);
        req.setHeader('Content-Type', 'application/json');
    
        Http http = new Http();
        HttpResponse res = http.send(req);
    
        if (res.getStatusCode() == 200) {
            try {
                List<UnanetOrganizationListItem> orgList = 
                    (List<UnanetOrganizationListItem>) JSON.deserialize(
                        res.getBody(), List<UnanetOrganizationListItem>.class
                    );
    
                for (UnanetOrganizationListItem item : orgList) {
                    if (item.name != null) {
                        orgKeyMapCache.put(item.name, item.key);
                    }
                    if (item.code != null) {
                        orgKeyMapCache.put(item.code, item.key);
                    }
                }
            } catch (Exception e) {
                logError('Organization Key Map Error', e.getMessage(), null);
                throw new CalloutException('Error deserializing organization list response: ' + e.getMessage());
            }
        } else {
            logError('Organization List API Failure', res.getBody(), null);
            throw new CalloutException('Failed to fetch organization list. Status: ' +
                res.getStatus() + ', Body: ' + res.getBody());
        }
    
        return orgKeyMapCache;
    }
    
    public class UnanetOrganizationListItem {
        public Integer key;
        public String name;
        public String code;
    }

    public static Map<String, Integer> getUdfMetadata(String udfType, String token) {
        // Build the request URL
        String baseUrl = getUnanetBaseUrl();
        String endpoint = baseUrl + '/platform/rest/config/udf-metadata/' + udfType;
        
        // Prepare the HTTP request
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + token);
        
        Http http = new Http();
        HttpResponse res;
        
        Map<String, Integer> udfMap = new Map<String, Integer>();
        
        try {
            res = http.send(req);
            
            if (res.getStatusCode() == 200) {
                Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                List<Object> items = (List<Object>) response.get('items');
                
                for (Object itemObj : items) {
                    Map<String, Object> item = (Map<String, Object>) itemObj;
                    Map<String, Object> metadata = (Map<String, Object>) item.get('metadata');
                    
                    String label = (String) metadata.get('label');
                    String visibility = (String) metadata.get('visibility');
                    Integer index = (Integer) item.get('index');
                    
                    if (!String.isBlank(label) && visibility == 'ENABLED') {
                        udfMap.put(label, index);
                    }
                }
            } else {
                logError('UDF Metadata Request Failed', 'Status: ' + res.getStatusCode(), udfType);
            }
        } catch (Exception e) {
            logError('UDF Metadata Exception', e.getMessage(), udfType);
        }
        
        return udfMap;
    }
        
    public static String getUnanetBaseUrl() {
        Boolean isSandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
        return isSandbox
            ? 'https://bluefinllc-sand.unanet.biz'
            : 'https://bluefinllc.unanet.biz';
    }

    public static String fetchUnanetToken(String baseUrl) {
        Unanet_User_Authentication__mdt creds = [
            SELECT Username__c, Password__c
            FROM Unanet_User_Authentication__mdt
            WHERE DeveloperName = 'Unanet_User_Auth_Credentials'
            LIMIT 1
        ];
        if (creds == null || String.isBlank(creds.Username__c) || String.isBlank(creds.Password__c)) {
            logError('Missing Credentials',
                     'Custom metadata for Unanet login is missing or incomplete.', null);
            return null;
        }
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setEndpoint(baseUrl + '/platform/rest/login');
        req.setHeader('Content-Type', 'application/json;charset=UTF-8');
        req.setBody('{"username":"' + creds.Username__c + '","password":"' + creds.Password__c + '"}');
        try {
            HttpResponse res = new Http().send(req);
            System.debug('Login Status Code: ' + res.getStatusCode());
            System.debug('Login Response Body: ' + res.getBody());
            if (res.getStatusCode() == 200) {
                Map<String,Object> result = (Map<String,Object>)
                    JSON.deserializeUntyped(res.getBody());
                return (String) result.get('token');
            } else {
                logError('Login Failed', 'Status ' + res.getStatusCode() + ': ' + res.getBody(), null);
            }
        } catch (Exception ex) {
            logError('Login Callout Error', ex.getMessage(), null);
        }
        return null;
    }

    private static void logError(String name, String description, String relatedId) {
        try {
            insert new Data_Log__c(
                Description__c       = description,
                Related_Record_Id__c = relatedId,
                Log_Origin__c        = 'Unanet Organization Sync Error'
            );
            System.debug('Inserting DataLog Record');
        } catch (Exception e) {
            System.debug('Failed to insert Data_Log__c: ' + e.getMessage());
        }
    }
    
}