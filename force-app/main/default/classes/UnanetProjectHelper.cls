public with sharing class UnanetProjectHelper {

    public static String buildUnanetProjectPayload(Project__c proj, Account acc, Opportunity opp, String token) {
        
        try {
            // Construct the payload map            
            String costStructureType;
            if (opp.Mantis_Division__c == 'Efficiency') {
                costStructureType = 'Fairbanks Standard';
            } else {
                costStructureType = 'Standard';
            }
            
            Integer costStructureKey = getCostStructureKey(costStructureType, token);
            Integer postingGroupKey = getPostingGroupKey('Default', token);
            Integer currecnyKey = UnanetHelper.getCurrencyKey(opp.CurrencyIsoCode, token);
            Integer pmKey = getProjectManagerKey(proj.Project_Manager_Unanet__c);
            Boolean useProjectAmount = useProjectAmount(proj.Type__c);
            Integer payCodeKey = getPayCodeKey('Regular', token);
    
            Map<String, Object> payload = new Map<String, Object>{
                'code' => proj.Project_Number__c,
                'title' => proj.Name,
                'projectOrgKey' => acc.Unanet_Id__c != null ? Integer.valueOf(acc.Unanet_Id__c) : null,
                'owningOrgKey' => getOrgKey(opp.Mantis_Division__c, token),
                'projectTypeKey' => getProjectTypeKey(proj.Unanet_Project_Type__c, token),
                'projectCurrencyKey' => currecnyKey,           
                'taskLevelAssignment' => false,
                'tsTaskRequired' => proj.Project_Requires_TASKS__c == 'Yes',
                'erTaskRequired' => proj.Project_Requires_TASKS__c == 'Yes',
                'itemTaskRequired' => proj.Project_Requires_TASKS__c == 'Yes',
                'origStartDate' => formatDate(proj.Start_Date__c),
                'origEndDate' => formatDate(proj.End_Date__c),
                'revStartDate' => getFirstOfMonth(proj.Start_Date__c),
                'revEndDate' => getLastOfMonth(proj.End_Date__c),
                'laborBillBudget' => proj.Project_Amount__c,
                'expBillBudget' => useProjectAmount ? 0 : proj.Pass_Through_Costs__c,
                'totalValue' => useProjectAmount ? proj.Project_Amount__c : proj.Pass_Through_Costs__c,
                'fundedValue' => useProjectAmount ? proj.Project_Amount__c : proj.Pass_Through_Costs__c,
                'billingTypeKey' => getBillingTypeKey('Lump Sum/Fixed Price', token),
                'statusKey' => getStatusKey(proj, token),
                'projectManagerKey' => pmKey,
                'projectColor' => 'GREEN',
                'pctComplRule' => 'TOTAL',
                'intercompanyEffort' => false,
                'enforceWBSDates' => proj.Project_Requires_TASKS__c == 'Yes',
                'probabilityPercent' => 100,
                'postingGroupKey' => postingGroupKey,   
                'costStructureKey' => costStructureKey,
                'allowTimeCharge' => useProjectAmount ? true : false,
                'allowItems' => false,
                'allowExpenseCharge' => true,
                'alwaysRequireComments' => true,
                'futureCharge' => false,
                'locationRequired' => false,
                'locationKey' => getLocationKey(proj.Project_State__c, token),
                'payCodeKey' => payCodeKey,
                'projectAccess' => new Map<String, Boolean>{
                    'billingManagers' => true,
                    'billingViewers' => true,
                    'projectDocumentViewers' => true,
                    'projectManagers' => true,
                    'projectPOViewers' => true,
                    'projectPRViewers' => true,
                    'projectViewers' => true,
                    'resourceAssigners' => true,
                    'resourcePlanners' => true,
                    'resourceRequestors' => true
                }
            };
            
            // Fetch UDF metadata dynamically for the 'PROJECT' type
            Map<String, Integer> udfIndexMap = UnanetHelper.getUdfMetadata('PROJECT', token);
    
            // Initialize a list for UDF values
            List<Map<String, Object>> udfValues = new List<Map<String, Object>>();
    
            // Dynamically handle the UDF for Owner Name (Primary Salesperson)
            Integer ownerNameIndex = udfIndexMap.get('Primary Salesperson');
            if (ownerNameIndex != null && opp.OwnerId != null && opp.Owner.Name != null) {
                udfValues.add(new Map<String, Object>{
                    'index' => ownerNameIndex,
                    'value' => opp.Owner.Name
                });
            }
    
            // Dynamically handle the UDF for Service Street
            Integer serviceStreetIndex = udfIndexMap.get('Street Address');
            if (serviceStreetIndex != null && proj.Service_Street__c != null) {
                udfValues.add(new Map<String, Object>{
                    'index' => serviceStreetIndex,
                    'value' => proj.Service_Street__c
                });
            }
    
            // Dynamically handle the UDF for Service City
            Integer serviceCityIndex = udfIndexMap.get('City');
            if (serviceCityIndex != null && proj.Service_City__c != null) {
                udfValues.add(new Map<String, Object>{
                    'index' => serviceCityIndex,
                    'value' => proj.Service_City__c
                });
            }    
            
            // Dynamically handle the UDF for SF Id (Project Id)
            Integer sfIdIndex = udfIndexMap.get('SF Id');
            if (sfIdIndex != null && proj.Id != null) {
                udfValues.add(new Map<String, Object>{
                    'index' => sfIdIndex,
                    'value' => proj.Id
                });
            }
            
            // Dynamically handle the UDF for As-Sold Gross Margin for Standard Projects Only
            if (useProjectAmount) {
                Integer asSoldIndex = udfIndexMap.get('As-Sold Margin (for new bookings as of 1/1/23)');
                if (asSoldIndex != null && proj.As_Sold_Gross_Margin2__c != null) {
                    Decimal percent = proj.As_Sold_Gross_Margin2__c;
                    String asSoldString = String.valueOf(percent.setScale(2)) + '%';
                    udfValues.add(new Map<String, Object>{
                        'index' => asSoldIndex,
                        'value' => asSoldString
                    });
                }
            }
            
            // Dynamically handle the UDF for Secondary Salesperson
    		Integer secSalesIndex = udfIndexMap.get('Secondary Salesperson');
            if (secSalesIndex != null && proj.Opportunity__c != null) {
                String secRepNames = getSecondarySalesRep(proj.Opportunity__c);
                udfValues.add(new Map<String, Object>{
                        'index' => secSalesIndex,
                        'value' => secRepNames
                    });
            }
       
            // Wrap UDFs in 'udfs' -> 'values'
            Map<String, Object> udfsWrapper = new Map<String, Object>{
                'values' => udfValues
            };
    
            // Add to payload
            payload.put('udfs', udfsWrapper);  // Ensure this Map accepts 'String' as the key and 'Object' as value
    
            
            // Serialize to JSON
            return JSON.serialize(payload);
        
        } catch(DmlException e) {
            System.debug('The following exception has occurred: ' + e.getMessage());
            logError('UnanetCreateProjectSync Error', 'Error building project payload: ' + e.getMessage(), null);
            throw new CalloutException('Error building project payload: ' + e.getMessage());            
        }
    }

            
    public static String getSecondarySalesRep(Id oppId) {
        String secRepName = '';
        if (oppId == null) {
            System.debug('UnanetProjectHalper.getSecondarySalesRep: ' + 'OppId was null');
            return secRepName;
        }
        
        List<Opportunity_Split__c> oppSplits = [SELECT Id, Team_MemberFx__c, Opportunity__c 
                                                FROM Opportunity_Split__c 
                                                WHERE Opportunity__c = :oppId 
                                                AND Default_Owner_Split__c != true];
        
        List<String> repNames = new List<String>();
        
        if (!oppSplits.isEmpty()) {
            for(Opportunity_Split__c split : oppSplits){
                repNames.add(split.Team_MemberFx__c);
            }
            
        } else {
            
            System.debug('UnanetProjectHalper.getSecondarySalesRep: ' + 'No other splits were found');
            return secRepName;
        }
        
        secRepName = String.join(repNames, ', ');
        
        return secRepName;
    }

    public static Integer getOrgKey(String mantisDivision, String token) {
        if (mantisDivision == null || String.isBlank(token)) {
            return null;
        }
    
        // Map Mantis divisions to Unanet org codes
        Map<String, String> divisionToOrgCode = new Map<String, String>{
            'FMS' => 'FMS_OPERATIONS',
            'Efficiency' => 'EFF_OPERATIONS',
            'Sustainability' => 'SSG_OPERATIONS'
        };
    
        String unanetOrgCode = divisionToOrgCode.get(mantisDivision);
        if (unanetOrgCode == null) {
            return null;
        }
    
        String baseUrl = UnanetHelper.getUnanetBaseUrl();
        
        Map<String, Integer> orgKeyMap = getOrgCodeKeyMap(token, baseUrl);
    
        return orgKeyMap.get(unanetOrgCode);
    }

    private static Map<String, Integer> orgCodeToKeyCache;

    public static Map<String, Integer> getOrgCodeKeyMap(String token, String baseUrl) {
        // If we already have the data cached in-memory, return it immediately
        if (orgCodeToKeyCache != null) {
            return orgCodeToKeyCache;
        }
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(baseUrl + '/platform/rest/organizations/list');
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + token);
        req.setHeader('Content-Type', 'application/json');
        
        Http http = new Http();
        HttpResponse res = http.send(req);
        
        if (res.getStatusCode() == 200) {
            try {
                // Deserialize the raw array response directly into a list
                List<UnanetOrgListWrapper> orgs = (List<UnanetOrgListWrapper>) JSON.deserialize(
                    res.getBody(), 
                    List<UnanetOrgListWrapper>.class
                );
        
                // Initialize the cache
                orgCodeToKeyCache = new Map<String, Integer>();
        
                // Populate the cache with the organization data
                for (UnanetOrgListWrapper org : orgs) {
                    orgCodeToKeyCache.put(org.code, org.key);
                }
        
                return orgCodeToKeyCache;
            } catch (Exception e) {
                throw new CalloutException('Error deserializing response: ' + e.getMessage());
            }
        } else {
            // Provide detailed error message including response body for debugging
            throw new CalloutException('Failed to fetch Unanet Orgs. Status: ' + res.getStatus() + ', Body: ' + res.getBody());
        }
    }

    public class UnanetOrgListWrapper {
        public Integer key;
        public String name;
        public String code;
    }


    public static Integer getProjectTypeKey(String projectType, String token) {
        // Null check
        if (projectType == null || String.isBlank(token)) {
            System.debug('getProjectTypeKey: projectType is null or token');
            return null;
        }

        System.debug('getProjectTypeKey: projectType value - ' + projectType);
    
    
        String baseUrl = UnanetHelper.getUnanetBaseUrl();
        
        Map<String, Integer> projectTypeKeyMap = getProjTypeKeyMap(token, baseUrl);
    
        Integer key = projectTypeKeyMap.get(projectType);
        System.debug('getProjectTypeKey: returned project type key = ' + key);
    
        return key;
    }
    

    private static Map<String, Integer> projTypeToKeyMapCache;

    public static Map<String, Integer> getProjTypeKeyMap(String token, String baseUrl) {
        if (projTypeToKeyMapCache != null) {
            return projTypeToKeyMapCache;
        }

        HttpRequest req = new HttpRequest();
        req.setEndpoint(baseUrl + '/platform/rest/project-types');
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + token);
        req.setHeader('Content-Type', 'application/json');

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200) {
            try {
                // Deserialize full response
                UnanetProjTypeResponseWrapper wrapper = (UnanetProjTypeResponseWrapper) JSON.deserialize(res.getBody(), UnanetProjTypeResponseWrapper.class);
                List<UnanetProjTypeListWrapper> projTypes = wrapper.items;

                projTypeToKeyMapCache = new Map<String, Integer>();
                for (UnanetProjTypeListWrapper item : projTypes) {
                    projTypeToKeyMapCache.put(item.name, item.key);
                }

                return projTypeToKeyMapCache;
            } catch (Exception e) {
                throw new CalloutException('Error deserializing response: ' + e.getMessage());
            }
        } else {
            throw new CalloutException('Failed to fetch Unanet Project Types. Status: ' + res.getStatus() + ', Body: ' + res.getBody());
        }
    }


    public class UnanetProjTypeResponseWrapper {
        public List<UnanetProjTypeListWrapper> items;
        public Integer page;
        public Integer pageSize;
        public Integer pageCount;
        public Integer resultCount;
    }

    private class UnanetProjTypeListWrapper {
        public Integer key;
        public String  description;
        public String  name;
        public Boolean administrative;
        public Boolean billable;
        public Boolean active;
        public Integer startWithProjectCodeSeq;
        public Integer lastProjectCodeSeq;
    }


    public static Integer getStatusKey(Project__c currProj, String token) {
        // Null check
        if (currProj == null || String.isBlank(token)) {
            System.debug('getStatusKey: currProj is null or token');
            return null;
        }
    
        // WAR flag to name mapping
        Map<Boolean, String> warToStatus = new Map<Boolean, String>{
            true => 'WAR (Work At Risk)',
            false => 'Open'
        };
    
        Boolean isWar = currProj.Work_At_Risk_WAR__c;
        String statusName = warToStatus.get(isWar);
        System.debug('getStatusKey: isWar = ' + isWar + ', statusName = ' + statusName);
    
        String baseUrl = UnanetHelper.getUnanetBaseUrl();
        Map<String, Integer> statusKeyMap = getProjStatusKeyMap(token, baseUrl);
    
        Integer statusKey = statusKeyMap.get(statusName);
        System.debug('getStatusKey: returned status key = ' + statusKey);
    
        return statusKey;
    }

    private static Map<String, Integer> projStatusToKeyMapCache;

    public static Map<String, Integer> getProjStatusKeyMap(String token, String baseUrl) {
        if (projStatusToKeyMapCache != null) {
            return projStatusToKeyMapCache;
        }
    
        HttpRequest req = new HttpRequest();
        req.setEndpoint(baseUrl + '/platform/rest/project-statuses');
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + token);
        req.setHeader('Content-Type', 'application/json');
    
        Http http = new Http();
        HttpResponse res = http.send(req);
    
        if (res.getStatusCode() == 200) {
            try {
                UnanetProjStatusResponseWrapper wrapper = (UnanetProjStatusResponseWrapper) JSON.deserialize(res.getBody(), UnanetProjStatusResponseWrapper.class);
                List<UnanetProjStatusListWrapper> projStatuses = wrapper.items;
    
                projStatusToKeyMapCache = new Map<String, Integer>();
                for (UnanetProjStatusListWrapper item : projStatuses) {
                    projStatusToKeyMapCache.put(item.name, item.key);
                }
    
                return projStatusToKeyMapCache;
            } catch (Exception e) {
                throw new CalloutException('Error deserializing response: ' + e.getMessage());
            }
        } else {
            throw new CalloutException('Failed to fetch Unanet Project Statuses. Status: ' + res.getStatus() + ', Body: ' + res.getBody());
        }
    }


    public class UnanetProjStatusResponseWrapper {
        public List<UnanetProjStatusListWrapper> items;
        public Integer page;
        public Integer pageSize;
        public Integer pageCount;
        public Integer resultCount;
    }

    private class UnanetProjStatusListWrapper {
        public Integer key;
        public String  name;
        public Boolean open;
        public Boolean active;
    }

    public static Integer getLocationKey(String projState, String token) {
        // null check for the parameter
        if (projState == null || String.isBlank(token)) {
            System.debug('getLocationKey: projState is null or token');
            return null;
        }
    
        System.debug('getLocationKey: projState = ' + projState);
    
        String baseUrl = UnanetHelper.getUnanetBaseUrl();
    
        Map<String, Integer> stateToKeyMap = getLocationKeyMap(token, baseUrl);
    
        Integer key = stateToKeyMap.get(projState);
        System.debug('getLocationKey: returned key = ' + key);
    
        return key;
    }

    private static Map<String, Integer> locationToKeyMapCache;

    public static Map<String, Integer> getLocationKeyMap(String token, String baseUrl) {
        if (locationToKeyMapCache != null) {
            System.debug('getLocationKeyMap: returning cached location map');
            return locationToKeyMapCache;
        }

        locationToKeyMapCache = new Map<String, Integer>();
        Integer currentPage = 1;
        Integer totalPages = 1;

        do {
            HttpRequest req = new HttpRequest();
            req.setEndpoint(baseUrl + '/platform/rest/locations?page=' + currentPage);
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer ' + token);
            req.setHeader('Content-Type', 'application/json');

            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() == 200) {
                try {
                    UnanetLocationResponseWrapper wrapper = (UnanetLocationResponseWrapper)
                        JSON.deserialize(res.getBody(), UnanetLocationResponseWrapper.class);

                    for (UnanetLocationListWrapper item : wrapper.items) {
                        locationToKeyMapCache.put(item.name, item.key);
                    }

                    totalPages = wrapper.pageCount;
                    currentPage++;
                } catch (Exception e) {
                    throw new CalloutException('Error deserializing location response: ' + e.getMessage());
                }
            } else {
                throw new CalloutException('Failed to fetch Unanet Locations. Status: ' +
                    res.getStatus() + ', Body: ' + res.getBody());
            }

        } while (currentPage <= totalPages);

        return locationToKeyMapCache;
    }

    public class UnanetLocationResponseWrapper {
        public List<UnanetLocationListWrapper> items;
        public Integer page;
        public Integer pageSize;
        public Integer pageCount;
        public Integer resultCount;
    }

    public class UnanetLocationListWrapper {
        public Integer key;
        public String name;
        public Boolean active;
    }

    public static Integer getBillingTypeKey(String contractType, String token) {
        // null check params
        if (contractType == null) return null;
        if (String.isBlank(token)) return null;

        // map to return
        Map<String, String> billingTypeMap = new Map <String, String>();
        billingTypeMap.put('Lump Sum/Fixed Price','FIXED_PRICE');
        billingTypeMap.put('Lump Sum/Fixed Price + Travel at Actuals', 'FIXED_PRICE');
        billingTypeMap.put('Time & Materials', 'Time & Materials');

        String billingType = billingTypeMap.get(contractType);

        if (billingType == null) {
            System.debug('No billingType mapping found for contractType: ' + contractType);
            return null;
        }

        String baseUrl = UnanetHelper.getUnanetBaseUrl();

        Map<String, Integer> billingTypeKeyMap = getBillTypeKeyMap(token, baseUrl);

        Integer key = billingTypeKeyMap.get(billingType);

        return key;
        
    }

    private static Map<String, Integer> billTypeToKeyMapCache;

    public static Map<String, Integer> getBillTypeKeyMap(String token, String baseUrl) {
        if (billTypeToKeyMapCache != null) {
            System.debug('getBillTypeKeyMap: returning cached location map');
            return billTypeToKeyMapCache;
        }

        billTypeToKeyMapCache = new Map<String, Integer>();
        Integer currentPage = 1;
        Integer totalPages = 1;

        do {
            HttpRequest req = new HttpRequest();
            req.setEndpoint(baseUrl + '/platform/rest/config/billing-types?page=' + currentPage);
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer ' + token);
            req.setHeader('Content-Type', 'application/json');

            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() == 200) {
                try {
                    UnanetBillTypeResponseWrapper wrapper = (UnanetBillTypeResponseWrapper)
                        JSON.deserialize(res.getBody(), UnanetBillTypeResponseWrapper.class);

                    for (UnanetBillTypeListWrapper item : wrapper.items) {
                        billTypeToKeyMapCache.put(item.type, item.key);
                    }

                    totalPages = wrapper.pageCount;
                    currentPage++;
                } catch (Exception e) {
                    throw new CalloutException('Error deserializing location response: ' + e.getMessage());
                }
            } else {
                throw new CalloutException('Failed to fetch Unanet Billing Types. Status: ' +
                    res.getStatus() + ', Body: ' + res.getBody());
            }

        } while (currentPage <= totalPages);

        return billTypeToKeyMapCache;
    }

    public class UnanetBillTypeResponseWrapper {
        public List<UnanetBillTypeListWrapper> items;
        public Integer page;
        public Integer pageSize;
        public Integer pageCount;
        public Integer resultCount;
    }

    public class UnanetBillTypeListWrapper {
        public Integer key;
        public String type;
        public String description;
    }

    public static Integer getCostStructureKey(String costStructure, String token) {
        if (String.isBlank(costStructure) || String.isBlank(token)) {
            System.debug('getCostStructureKey: costStructure or token is blank');
            return null;
        }
    
        String baseUrl = UnanetHelper.getUnanetBaseUrl();
        Map<String, Integer> costStructureToKeyMap = getCostStructureKeyMap(token, baseUrl);
    
        if (costStructureToKeyMap == null || costStructureToKeyMap.isEmpty()) {
            System.debug('getCostStructureKey: Retrieved cost structure map is null or empty');
            logError('Cost Structure Lookup Failed', 'Cost structure map was empty or not returned', null);
            return null;
        }
    
        Integer key = costStructureToKeyMap.get(costStructure);
    
        if (key == null) {
            System.debug('getCostStructureKey: No key found for cost structure name: ' + costStructure);
            logError('Cost Structure Not Found', 'No key found for cost structure: ' + costStructure, null);
            return null;
        }
    
        System.debug('Cost structure Returned Key: ' + key);
        return key;
    }
    
    private static Map<String, Integer> costStructureToKeyMapCache;
    
    public static Map<String, Integer> getCostStructureKeyMap(String token, String baseUrl) {
        if (costStructureToKeyMapCache != null) {
            System.debug('getCostStructureKeyMap: returning cached cost structure map with ' + costStructureToKeyMapCache.size() + ' entries');
            return costStructureToKeyMapCache;
        }
    
        costStructureToKeyMapCache = new Map<String, Integer>();
        Integer currentPage = 1;
        Integer totalPages = 1;
    
        do {
            HttpRequest req = new HttpRequest();
            req.setEndpoint(baseUrl + '/platform/rest/cost-structures?page=' + currentPage);
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer ' + token);
            req.setHeader('Content-Type', 'application/json');
    
            Http http = new Http();
            HttpResponse res = http.send(req);
    
            if (res.getStatusCode() == 200) {
                try {
                    UnanetCostStructureResponseWrapper wrapper = (UnanetCostStructureResponseWrapper)
                        JSON.deserialize(res.getBody(), UnanetCostStructureResponseWrapper.class);
    
                    for (UnanetCostStructureListWrapper item : wrapper.items) {
                        costStructureToKeyMapCache.put(item.name, item.key);
                    }
    
                    totalPages = wrapper.pageCount;
                    currentPage++;
                } catch (Exception e) {
                    logError('Deserialization Error', 'Error deserializing Cost Structure response: ' + e.getMessage(), null);
                    throw new CalloutException('Error deserializing Cost Structure response: ' + e.getMessage());
                }
            } else {
                logError('API Call Failed', 'Failed to fetch Unanet Cost Structures. Status: ' + res.getStatus() + ', Body: ' + res.getBody(), null);
                throw new CalloutException('Failed to fetch Unanet Cost Structures. Status: ' +
                    res.getStatus() + ', Body: ' + res.getBody());
            }
    
        } while (currentPage <= totalPages);
    
        return costStructureToKeyMapCache;
    }
    
    // Wrapper classes (unchanged)
    public class UnanetCostStructureResponseWrapper {
        public List<UnanetCostStructureListWrapper> items;
        public Integer page;
        public Integer pageSize;
        public Integer pageCount;
        public Integer resultCount;
    }
    
    public class UnanetCostStructureListWrapper {
        public Integer key;
        public String name;
        public String description;
        public Boolean active;
        public Integer costPoolGroupKey;
    }

    public static Integer getPostingGroupKey(String postingGroupName, String token) {
        if (String.isBlank(postingGroupName) || String.isBlank(token)) {
            System.debug('getPostingGroupKey: postingGroupName or token is blank');
            return null;
        }

        String baseUrl = UnanetHelper.getUnanetBaseUrl();
        Map<String, Integer> postingGroupMap = getPostingGroupKeyMap(token, baseUrl);

        if (postingGroupMap == null || postingGroupMap.isEmpty()) {
            System.debug('getPostingGroupKey: Retrieved posting group map is null or empty');
            logError('Posting Group Lookup Failed', 'Posting group map was empty or not returned', null);
            return null;
        }

        Integer key = postingGroupMap.get(postingGroupName);

        if (key == null) {
            System.debug('getPostingGroupKey: No key found for posting group: ' + postingGroupName);
            logError('Posting Group Not Found', 'No key found for posting group: ' + postingGroupName, null);
            return null;
        }

        System.debug('Posting Group Returned Key: ' + key);
        return key;
    }

    private static Map<String, Integer> postingGroupToKeyMapCache;

    public static Map<String, Integer> getPostingGroupKeyMap(String token, String baseUrl) {
        if (postingGroupToKeyMapCache != null) {
            System.debug('getPostingGroupKeyMap: returning cached posting group map with ' + postingGroupToKeyMapCache.size() + ' entries');
            return postingGroupToKeyMapCache;
        }

        postingGroupToKeyMapCache = new Map<String, Integer>();
        Integer currentPage = 1;
        Integer totalPages = 1;

        do {
            HttpRequest req = new HttpRequest();
            req.setEndpoint(baseUrl + '/platform/rest/posting-groups?page=' + currentPage);
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer ' + token);
            req.setHeader('Content-Type', 'application/json');

            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() == 200) {
                try {
                    UnanetPostingGroupResponseWrapper wrapper = (UnanetPostingGroupResponseWrapper)
                        JSON.deserialize(res.getBody(), UnanetPostingGroupResponseWrapper.class);

                    for (UnanetPostingGroupWrapper item : wrapper.items) {
                        postingGroupToKeyMapCache.put(item.name, item.key);
                    }

                    totalPages = wrapper.pageCount;
                    currentPage++;
                } catch (Exception e) {
                    logError('Deserialization Error', 'Error deserializing Posting Group response: ' + e.getMessage(), null);
                    throw new CalloutException('Error deserializing Posting Group response: ' + e.getMessage());
                }
            } else {
                logError('API Call Failed', 'Failed to fetch Unanet Posting Groups. Status: ' + res.getStatus() + ', Body: ' + res.getBody(), null);
                throw new CalloutException('Failed to fetch Unanet Posting Groups. Status: ' + res.getStatus() + ', Body: ' + res.getBody());
            }

        } while (currentPage <= totalPages);

        return postingGroupToKeyMapCache;
    }

    // Wrapper classes for response
    public class UnanetPostingGroupResponseWrapper {
        public List<UnanetPostingGroupWrapper> items;
        public Integer page;
        public Integer pageSize;
        public Integer pageCount;
        public Integer resultCount;
    }

    public class UnanetPostingGroupWrapper {
        public Integer key;
        public String name;
        public Boolean active;
        public String description;
        public String type;
    }
    
    public static Integer getPayCodeKey(String payCodeName, String token) {
        if (String.isBlank(payCodeName) || String.isBlank(token)) {
            System.debug('getPayCodeKey: payCodeName or token is blank');
            return null;
        }
        System.debug('getPayCodeKey String: ' + payCodeName);

        String baseUrl = UnanetHelper.getUnanetBaseUrl();
        Map<String, Integer> payCodeMap = getPayCodeKeyMap(token, baseUrl);

        if (payCodeMap == null || payCodeMap.isEmpty()) {
            System.debug('getPayCodeKey: Retrieved pay code map is null or empty');
            logError('Pay code Lookup Failed', 'Pay code map was empty or not returned', null);
            return null;
        }

        Integer key = payCodeMap.get(payCodeName);

        if (key == null) {
            System.debug('getPayCodeKey: No key found for pay code: ' + payCodeName);
            logError('Pay code Not Found', 'No key found for pay code: ' + payCodeName, null);
            return null;
        }

        System.debug('Pay code Returned Key: ' + key);
        return key;
    }
    
    private static Map<String, Integer> payCodeToKeyMapCache;
    
    public static Map<String, Integer> getPayCodeKeyMap(String token, String baseUrl) {
        if (payCodeToKeyMapCache != null) {
            System.debug('getPayCodeKeyMap: returning cached pay code map with ' + payCodeToKeyMapCache.size() + ' entries');
            return payCodeToKeyMapCache;
        }

        payCodeToKeyMapCache = new Map<String, Integer>();
        Integer currentPage = 1;
        Integer totalPages = 1;

        do {
            HttpRequest req = new HttpRequest();
            req.setEndpoint(baseUrl + '/platform/rest/pay-codes?page=' + currentPage);
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer ' + token);
            req.setHeader('Content-Type', 'application/json');

            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() == 200) {
                try {
                    UnanetPayCodeResponseWrapper wrapper = (UnanetPayCodeResponseWrapper)
                        JSON.deserialize(res.getBody(), UnanetPayCodeResponseWrapper.class);

                    for (UnanetPayCodeWrapper item : wrapper.items) {
                        payCodeToKeyMapCache.put(item.name, item.key);
                    }

                    totalPages = wrapper.pageCount;
                    currentPage++;
                } catch (Exception e) {
                    logError('Deserialization Error', 'Error deserializing Pay Code response: ' + e.getMessage(), null);
                    throw new CalloutException('Error deserializing Pay Code response: ' + e.getMessage());
                }
            } else {
                logError('API Call Failed', 'Failed to fetch Unanet Pay Codes. Status: ' + res.getStatus() + ', Body: ' + res.getBody(), null);
                throw new CalloutException('Failed to fetch Unanet Pay Codes. Status: ' + res.getStatus() + ', Body: ' + res.getBody());
            }

        } while (currentPage <= totalPages);

        return payCodeToKeyMapCache;
    }
    
    public class UnanetPayCodeResponseWrapper {
        public List<UnanetPayCodeWrapper> items;
        public Integer page;
        public Integer pageSize;
        public Integer pageCount;
        public Integer resultCount;
    }
    
    public class UnanetPayCodeWrapper {
        public Integer key;
        public String name;
    }
    
    /*
    public static Integer getInvoiceFormatKey(String invFormatName, String token) {
        if (String.isBlank(invFormatName) || String.isBlank(token)) {
            System.debug('getInvoiceFormatKey: invFormatName or token is blank');
            return null;
        }

        String baseUrl = UnanetHelper.getUnanetBaseUrl();
        Map<String, Integer> invFormatMap = getInvoiceFormatKeyMap(token, baseUrl);

        if (invFormatMap == null || invFormatMap.isEmpty()) {
            System.debug('getInvoiceFormatKey: Retrieved Invoice format map is null or empty');
            logError('Invoice Format Lookup Failed', 'Invoice Format map was empty or not returned', null);
            return null;
        }

        Integer key = invFormatMap.get(invFormatName);

        if (key == null) {
            System.debug('getInvoiceFormatKey: No key found for Invoice Format: ' + invFormatName);
            logError('Invoice Format Not Found', 'No key found for Invoice Format: ' + invFormatName, null);
            return null;
        }

        System.debug('Invoice Format Returned Key: ' + key);
        return key;
    }
    
    private static Map<String, Integer> invoiceFormatToKeyMapCache;
    
    public static Map<String, Integer> getInvoiceFormatKeyMap(String token, String baseUrl) {
        if (invoiceFormatToKeyMapCache != null) {
            System.debug('getInvoiceFormatKeyMap: returning cached invoice format map with ' + invoiceFormatToKeyMapCache.size() + ' entries');
            return invoiceFormatToKeyMapCache;
        }

        invoiceFormatToKeyMapCache = new Map<String, Integer>();
        Integer currentPage = 1;
        Integer totalPages = 1;

        do {
            HttpRequest req = new HttpRequest();
            req.setEndpoint(baseUrl + '/platform/rest/invoice-formats?page=' + currentPage);
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer ' + token);
            req.setHeader('Content-Type', 'application/json');

            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() == 200) {
                try {
                    UnanetInvoiceFormatResponseWrapper wrapper = (UnanetInvoiceFormatResponseWrapper)
                        JSON.deserialize(res.getBody(), UnanetInvoiceFormatResponseWrapper.class);

                    for (UnanetInvoiceFormatWrapper item : wrapper.items) {
                        invoiceFormatToKeyMapCache.put(item.name, item.key);
                    }

                    totalPages = wrapper.pageCount;
                    currentPage++;
                } catch (Exception e) {
                    logError('Deserialization Error', 'Error deserializing Invoice Format response: ' + e.getMessage(), null);
                    throw new CalloutException('Error deserializing Invoice Format response: ' + e.getMessage());
                }
            } else {
                logError('API Call Failed', 'Failed to fetch Unanet Invoice Formats. Status: ' + res.getStatus() + ', Body: ' + res.getBody(), null);
                throw new CalloutException('Failed to fetch Unanet Invoice Formats. Status: ' + res.getStatus() + ', Body: ' + res.getBody());
            }

        } while (currentPage <= totalPages);

        return invoiceFormatToKeyMapCache;
    }
    
    public class UnanetInvoiceFormatResponseWrapper {
        public List<UnanetInvoiceFormatWrapper> items;
        public Integer page;
        public Integer pageSize;
        public Integer pageCount;
        public Integer resultCount;
    }
    
    public class UnanetInvoiceFormatWrapper {
        public Integer key;
        public String name;
    }
    
    public static Integer getInvoiceNumFormatKey(String numFormatName, String token) {
        if (String.isBlank(numFormatName) || String.isBlank(token)) {
            System.debug('getInvoiceNumFormatKey: numFormatName or token is blank');
            return null;
        }

        String baseUrl = UnanetHelper.getUnanetBaseUrl();
        Map<String, Integer> invNumFormatMap = getInvoiceNumberFormatKeyMap(token, baseUrl);

        if (invNumFormatMap == null || invNumFormatMap.isEmpty()) {
            System.debug('getInvoiceNumFormatKey: Retrieved Invoice number format map is null or empty');
            logError('Invoice Number Format Lookup Failed', 'Invoice number format map was empty or not returned', null);
            return null;
        }

        Integer key = invNumFormatMap.get(numFormatName);

        if (key == null) {
            System.debug('getInvoiceFormatKey: No key found for Invoice Number Format: ' + numFormatName);
            logError('Invoice Format Not Found', 'No key found for Invoice Number Format: ' + numFormatName, null);
            return null;
        }

        System.debug('Invoice Number Format Returned Key: ' + key);
        return key;
    }
    
    private static Map<String, Integer> invoiceNumberFormatToKeyMapCache;
    
    public static Map<String, Integer> getInvoiceNumberFormatKeyMap(String token, String baseUrl) {
        if (invoiceNumberFormatToKeyMapCache != null) {
            System.debug('getInvoiceNumberFormatKeyMap: returning cached invoice number format map with ' + invoiceNumberFormatToKeyMapCache.size() + ' entries');
            return invoiceNumberFormatToKeyMapCache;
        }

        invoiceNumberFormatToKeyMapCache = new Map<String, Integer>();
        Integer currentPage = 1;
        Integer totalPages = 1;

        do {
            HttpRequest req = new HttpRequest();
            req.setEndpoint(baseUrl + '/platform/rest/invoice-number-formats?page=' + currentPage);
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer ' + token);
            req.setHeader('Content-Type', 'application/json');

            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() == 200) {
                try {
                    UnanetInvoiceNumberFormatResponseWrapper wrapper = (UnanetInvoiceNumberFormatResponseWrapper)
                        JSON.deserialize(res.getBody(), UnanetInvoiceNumberFormatResponseWrapper.class);

                    for (UnanetInvoiceNumberFormatWrapper item : wrapper.items) {
                        invoiceNumberFormatToKeyMapCache.put(item.name, item.key);
                    }

                    totalPages = wrapper.pageCount;
                    currentPage++;
                } catch (Exception e) {
                    logError('Deserialization Error', 'Error deserializing Invoice Number Format response: ' + e.getMessage(), null);
                    throw new CalloutException('Error deserializing Invoice Number Format response: ' + e.getMessage());
                }
            } else {
                logError('API Call Failed', 'Failed to fetch Unanet Invoice Number Formats. Status: ' + res.getStatus() + ', Body: ' + res.getBody(), null);
                throw new CalloutException('Failed to fetch Unanet Invoice Number Formats. Status: ' + res.getStatus() + ', Body: ' + res.getBody());
            }

        } while (currentPage <= totalPages);

        return invoiceNumberFormatToKeyMapCache;
    }
    
    public class UnanetInvoiceNumberFormatResponseWrapper {
        public List<UnanetInvoiceNumberFormatWrapper> items;
        public Integer page;
        public Integer pageSize;
        public Integer pageCount;
        public Integer resultCount;
    }
    
    public class UnanetInvoiceNumberFormatWrapper {
        public Integer key;
        public String name;
    }
    
    public static Integer getPaymentTermKey(String paymentTermCode, String token) {
        if (String.isBlank(paymentTermCode) || String.isBlank(token)) {
            System.debug('getPaymentTermKey: paymentTermCode or token is blank');
            return null;
        }

        String baseUrl = UnanetHelper.getUnanetBaseUrl();
        Map<String, Integer> paymentTermMap = getPaymentTermKeyMap(token, baseUrl);

        if (paymentTermMap == null || paymentTermMap.isEmpty()) {
            System.debug('getPaymentTermKey: Retrieved Payment Term map is null or empty');
            logError('Payment Term Lookup Failed', 'Payment Term map was empty or not returned', null);
            return null;
        }

        Integer key = paymentTermMap.get(paymentTermCode);

        if (key == null) {
            System.debug('getPaymentTermKey: No key found for Payment Term: ' + paymentTermCode);
            logError('Payment Term Not Found', 'No key found for Payment Term: ' + paymentTermCode, null);
            return null;
        }

        System.debug('Payment Term Returned Key: ' + key);
        return key;
    }
    
    private static Map<String, Integer> paymentTermToKeyMapCache;
    
    public static Map<String, Integer> getPaymentTermKeyMap(String token, String baseUrl) {
        if (paymentTermToKeyMapCache != null) {
            System.debug('getPaymentTermKeyMap: returning cached payment term map with ' + paymentTermToKeyMapCache.size() + ' entries');
            return paymentTermToKeyMapCache;
        }

        paymentTermToKeyMapCache = new Map<String, Integer>();
        Integer currentPage = 1;
        Integer totalPages = 1;

        do {
            HttpRequest req = new HttpRequest();
            req.setEndpoint(baseUrl + '/platform/rest/payment-terms?page=' + currentPage);
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer ' + token);
            req.setHeader('Content-Type', 'application/json');

            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() == 200) {
                try {
                    UnanetPaymentTermResponseWrapper wrapper = (UnanetPaymentTermResponseWrapper)
                        JSON.deserialize(res.getBody(), UnanetPaymentTermResponseWrapper.class);

                    for (UnanetPaymentTermWrapper item : wrapper.items) {
                        paymentTermToKeyMapCache.put(item.code, item.key);
                    }

                    totalPages = wrapper.pageCount;
                    currentPage++;
                } catch (Exception e) {
                    logError('Deserialization Error', 'Error deserializing Payment Term response: ' + e.getMessage(), null);
                    throw new CalloutException('Error deserializing Payment Term response: ' + e.getMessage());
                }
            } else {
                logError('API Call Failed', 'Failed to fetch Unanet Payment Terms. Status: ' + res.getStatus() + ', Body: ' + res.getBody(), null);
                throw new CalloutException('Failed to fetch Unanet Payment Terms. Status: ' + res.getStatus() + ', Body: ' + res.getBody());
            }

        } while (currentPage <= totalPages);

        return paymentTermToKeyMapCache;
    }
    
    public class UnanetPaymentTermResponseWrapper {
        public List<UnanetPaymentTermWrapper> items;
        public Integer page;
        public Integer pageSize;
        public Integer pageCount;
        public Integer resultCount;
    }
    
    public class UnanetPaymentTermWrapper {
        public Integer key;
        public String code;
    } */

       

    public static String getFirstOfMonth(Date startDate) {
        if (startDate == null) return null;
        Date firstOfMonth = startDate.toStartOfMonth();
        return formatDate(firstOfMonth);
    }
    
    public static Date getLastOfMonth(Date inputDate) {
        if (inputDate == null) return null;
        // Calculate the last day of the month
        return inputDate.toStartOfMonth().addMonths(1).addDays(-1);
    }    

    public static String formatDate(Date inputDate) {
        if (inputDate == null) return null;
        // Convert Date to DateTime at midnight (default time is 00:00:00)
        DateTime dt = DateTime.newInstance(inputDate.year(), inputDate.month(), inputDate.day());
        // Format DateTime to a String with the desired format
        return dt.format('yyyy-MM-dd');  // Adjust format as needed
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
    
    public static Integer getProjectManagerKey(Id projectManagerId) {
        if (projectManagerId == null) {
            return null;
        }
        
        Unanet_User__c pManager;
        try {
            pManager = [SELECT Unanet_User_Id__c FROM Unanet_User__c WHERE Id = :projectManagerId LIMIT 1];
        } catch (Exception e) {
            System.debug('UnanetProjectHelper.getProjectManagerKey: No Project Manager Found');
            return null;
        }
        
        if (pManager != null && pManager.Unanet_User_Id__c != null) {
            try {
                return Integer.valueOf(pManager.Unanet_User_Id__c);
            } catch (Exception e) {
                // Handle case where Unanet_User_Id__c is not a valid integer string
                System.debug('UnanetProjectHelper.getProjectManagerKey Exception Thrown: ' + e.getMessage());
                return null;
            }
        }
        
        return null;
    }
    
    public static Integer getProjectLeadKey(Id primarySalesPersonId) {
        if (primarySalesPersonId == null) {
            return null;
        }
    
        // Get the Salesforce User
        User pSalesUser = [
            SELECT FirstName, LastName 
            FROM User 
            WHERE Id = :primarySalesPersonId 
            LIMIT 1
        ];
    
        // Find corresponding Unanet User
        try {
            Unanet_User__c pSalesPerson = [
                SELECT Unanet_User_Id__c 
                FROM Unanet_User__c 
                WHERE First_Name__c = :pSalesUser.FirstName 
                AND Last_Name__c = :pSalesUser.LastName 
                LIMIT 1
            ];
    
            if (String.isNotBlank(pSalesPerson.Unanet_User_Id__c)) {
                try {
                    return Integer.valueOf(pSalesPerson.Unanet_User_Id__c);
                } catch (Exception e) {
                    System.debug('UnanetProjectHelper.getProjectLeadKey: Invalid Unanet_User_Id__c format - ' + e.getMessage());
                }
            }
    
        } catch (Exception e) {
            System.debug('UnanetProjectHelper.getProjectLeadKey: No matching Unanet user found - ' + e.getMessage());
        }
    
        return null;
    }
    
    
    public static Boolean useProjectAmount(String type) {
        if (type == 'Standard Project') {
            return true;
        } else {
            return false;
        }
    }


    public static String buildStandardFixedPriceItemPayload(Project__c proj, String projectKey) {
        Map<String, Object> payload = new Map<String, Object>();
    
        // Safely parse projectKey
        Integer parsedProjectKey = 0;
        try {
            parsedProjectKey = Integer.valueOf(projectKey);
        } catch (Exception e) {
            parsedProjectKey = 0;
        }
        payload.put('projectKey', parsedProjectKey);
    
        // Add description
        String rawDescription = proj.Name + ' - ' + proj.Account__r.Name + ' - ' + proj.Project_Number__c;
        String fallbackDescription = proj.Name + ' - ' + proj.Project_Number__c;
        
        String description = rawDescription.length() <= 128 ? rawDescription : fallbackDescription;
        
        payload.put('description', description);
    
        // Format and add bill date
        Date endDate = proj != null ? proj.End_Date__c : null;
        payload.put('billDate', formatDate(endDate));
    
        payload.put('billOnCompletion', false);
        payload.put('revenueRecognitionMethod', 'PERCENT_COMPLETE');
    
        // Determine amount based on project type
        Decimal amount = 0;
        if (proj != null && proj.Type__c != null) {
            if (proj.Type__c == 'Standard Project') {
                amount = proj.Project_Amount__c;
            } else if (proj.Type__c == 'Change Order') {
                amount = proj.Project_Amount__c;
            } else if (proj.Type__c == 'EXP' || proj.Type__c == 'PT') {
                amount = proj.Pass_Through_Costs__c != null ? proj.Pass_Through_Costs__c : 0;
            }
        }
    
        payload.put('amount', amount);
    
        return JSON.serialize(payload);
    }    

}