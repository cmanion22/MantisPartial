public class UnanetInvoiceSyncBatch implements Database.Batchable<UnanetInvoiceWrapper.Invoice>, Database.AllowsCallouts, Database.Stateful {
    private String baseUrl;
    private String authToken;
    private Map<String, Id> unanetKeyToProjectId;
    private Integer totalInvoicesReturned = 0;
    private Integer totalProjectsMatched = 0;
    private Integer totalInvoicesUpserted = 0;
    private Integer calloutErrors = 0;
    private Integer unmatchedProjects = 0;
    private Integer newInvoices = 0;
    private Integer updatedInvoices = 0;
    private Boolean isValid = true;
    
    public UnanetInvoiceSyncBatch() {
        baseUrl = getUnanetBaseUrl();

    }
        

    public Iterable<UnanetInvoiceWrapper.Invoice> start(Database.BatchableContext bc) {
        
        authToken = fetchUnanetToken(baseUrl);
        if (String.isBlank(authToken)) {
            System.debug('Unanet Invoice Sync: Failed to get Auth Token');
            DataLogService.logError('Unanet Invoice Sync', 'Failed to get Unanet Auth Token');
            isValid = false;
            return new List<UnanetInvoiceWrapper.Invoice>(); // nothing to process
        }

        // Load project map here too
        unanetKeyToProjectId = new Map<String, Id>();
        for (Project__c proj : [SELECT Id, Unanet_Id__c FROM Project__c WHERE Unanet_Id__c != null]) {
            unanetKeyToProjectId.put(proj.Unanet_Id__c, proj.Id);
        }

        List<UnanetInvoiceWrapper.Invoice> allInvoices = fetchInvoices(baseUrl, authToken);
        List<UnanetInvoiceWrapper.Invoice> filtered = new List<UnanetInvoiceWrapper.Invoice>();

        for (UnanetInvoiceWrapper.Invoice inv : allInvoices) {
            if (unanetKeyToProjectId.containsKey(String.valueOf(inv.project.key))) {
                filtered.add(inv);
                
            } else {
                unmatchedProjects++;
                System.debug(
                        'Unmatched Project | Key: ' + inv.Project.key + 
                        ' | Code: ' + inv.Project.code
                    );
            }
        }
        
        totalInvoicesReturned = allInvoices.size();
    	totalProjectsMatched = filtered.size();

        return filtered;
    }

    public void execute(Database.BatchableContext bc, List<UnanetInvoiceWrapper.Invoice> invoices) {
        Map<String, Unanet_Invoice__c> existingInvoices = new Map<String, Unanet_Invoice__c>();
        try {
            Set<String> invoiceKeys = new Set<String>();
            for (UnanetInvoiceWrapper.Invoice i : invoices) {
                invoiceKeys.add(String.valueOf(i.key));
            }
            
            for (Unanet_Invoice__c inv : [
                SELECT Id, Unanet_Id__c, Amount__c, Billed_Account__c, Billed_Organization__c,
                       Billing_Period_From_Date__c, Billing_Through_Date__c, Discount_Amount__c,
                       Instance_Amount__c, Invoice_Date__c, Invoice_Number__c, Local_Amount__c,
                       Organization__c, Payment_Term__c, Post_Date__c, Project__c, Status__c
                FROM Unanet_Invoice__c
                WHERE Unanet_Id__c IN :invoiceKeys
            ]) {
                existingInvoices.put(inv.Unanet_Id__c, inv);
            }

        } catch (Exception e) {
            logError('Fetch Existing Invoices Error', e.getMessage(), null);
            return;
        }

        List<Unanet_Invoice__c> toUpsert = new List<Unanet_Invoice__c>();

        for (UnanetInvoiceWrapper.Invoice summary : invoices) {
            try {
                String projKey = String.valueOf(summary.project.key);
                Id projectId = unanetKeyToProjectId.get(projKey);
                if (projectId == null) {
                    System.debug('No matching Salesforce project for key ' + projKey);
                    
                    continue;
                }

                UnanetInvoiceIndividualWrapper detailed = getIndividualInvoice(baseUrl, authToken, summary.key);
                if (detailed == null) {
                    calloutErrors++;
                    continue;
                } 

                String invoiceKey = String.valueOf(summary.key);
                if (existingInvoices.containsKey(invoiceKey)) {
                    Unanet_Invoice__c existing = existingInvoices.get(invoiceKey);
                    // Update fields...
                    existing.Amount__c = detailed.amount;
                    existing.Billed_Account__c = detailed.billedAccount != null ? String.valueOf(detailed.billedAccount.key) : null;
                    existing.Billed_Organization__c = detailed.billedOrganization != null ? detailed.billedOrganization.name : null;
                    existing.Billing_Period_From_Date__c = detailed.billingPeriodFromDate;
                    existing.Billing_Through_Date__c = detailed.billingThroughDate;
                    existing.Discount_Amount__c = detailed.discountAmount;
                    existing.Instance_Amount__c = detailed.instanceAmount;
                    existing.Invoice_Date__c = detailed.invoiceDate;
                    existing.Invoice_Number__c = detailed.invoiceNumber;
                    existing.Local_Amount__c = detailed.localAmount;
                    existing.Organization__c = detailed.organization != null ? detailed.organization.name : null;
                    existing.Payment_Term__c = detailed.paymentTerm != null ? detailed.paymentTerm.code : null;
                    existing.Post_Date__c = detailed.postDate;
                    existing.Status__c = detailed.status;
                    updatedInvoices++;
                    toUpsert.add(existing);
                } else {
                    newInvoices++;
                    toUpsert.add(buildInvoice(detailed, projectId));
                }
            } catch (Exception e) {
                logError('Invoice Processing Error', 'Invoice key: ' + summary.key + ' - ' + e.getMessage(), null);
            }
        }

        if (!toUpsert.isEmpty()) {
            totalInvoicesUpserted += toUpsert.size();
            try {
                upsert toUpsert;
            } catch (Exception e) {
                logError('Upsert Error', e.getMessage(), null);
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
        String timestamp = Datetime.now().format('yyyy-MM-dd HH:mm:ss');
        String msg = 'Run Date/Time: ' + timestamp +
            '\nInvoices returned: ' + totalInvoicesReturned +
            ', Projects matched: ' + totalProjectsMatched +
            ', Invoices upserted: ' + totalInvoicesUpserted +
            ', New: ' + newInvoices +
            ', Updated: ' + updatedInvoices +
            ', Unmatched Projects: ' + unmatchedProjects +
            ', Callout Errors: ' + calloutErrors;

    	System.debug('Unanet Invoice Sync: Logging Results of batch job...');
        System.debug('Unanet Invoice Sync: Results -> ' + msg);
        DataLogService.logInfo('Unanet Invoice Sync', msg);
    }

    // (Include your existing helper methods here: getUnanetBaseUrl(), fetchUnanetToken(), fetchInvoices(), getIndividualInvoice(), buildInvoice(), logError()
    private String getUnanetBaseUrl() {
        Boolean isSandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
        return isSandbox
            ? 'https://bluefinllc-sand.unanet.biz'
            : 'https://bluefinllc.unanet.biz';
    }
    
    private String fetchUnanetToken(String baseUrl) {
        Unanet_User_Authentication__mdt creds = [
            SELECT Username__c, Password__c
            FROM Unanet_User_Authentication__mdt
            WHERE DeveloperName = 'Unanet_User_Auth_Credentials'
            LIMIT 1
        ];
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setEndpoint(baseUrl + '/platform/rest/login');
        req.setHeader('Content-Type', 'application/json;charset=UTF-8');
        req.setBody('{"username":"' + creds.Username__c + '","password":"' + creds.Password__c + '"}');
        
        try {
            HttpResponse res = new Http().send(req);
            if (res.getStatusCode() == 200) {
                Map<String,Object> result = (Map<String,Object>) JSON.deserializeUntyped(res.getBody());
                return (String) result.get('token');
            } else {
                logError('Login Failed', 'Status ' + res.getStatusCode() + ': ' + res.getBody(), null);
            }
        } catch (Exception ex) {
            logError('Login Callout Error', ex.getMessage(), null);
        }
        return null;
    }
    
    private List<UnanetInvoiceWrapper.Invoice> fetchInvoices(String baseUrl, String token) {
        List<UnanetInvoiceWrapper.Invoice> invoices = new List<UnanetInvoiceWrapper.Invoice>();
        Integer currentPage = 1;
        Integer totalPages = 1;
    
        do {
            Integer pageSize = 100;
            
            Date today = Date.today();

            // Beginning of last month
            Date startDate = Date.newInstance(today.year(), today.month(), 1).addMonths(-1);
            
            // Today
            Date endDate = today;
            System.debug('Invoice Range Dates: ' + 'Start Date: ' + startDate + ', End Date: ' + endDate);

            String endpoint = baseUrl + '/platform/rest/invoices/search?page=' + currentPage + '&pageSize=' + pageSize;
    
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('POST');
            req.setHeader('Authorization', 'Bearer ' + token);
            req.setHeader('Content-Type', 'application/json');
            req.setTimeout(120000);
    
            Map<String, Object> invoiceDate = new Map<String, Object>{
                'rangeStart' => startDate,
                'rangeEnd'   => endDate
            };
            Map<String, Object> body = new Map<String, Object>{
                'invoiceDate' => invoiceDate
            };
            req.setBody(JSON.serialize(body));
    
            try {
                System.debug('Fetching page ' + currentPage + ' of ' + totalPages);
                HttpResponse res = new Http().send(req);
                if (res.getStatusCode() == 200) {
                    UnanetInvoiceWrapper response = (UnanetInvoiceWrapper)
                        JSON.deserialize(res.getBody(), UnanetInvoiceWrapper.class);
                    if (response != null && response.items != null) {
                        invoices.addAll(response.items);
                    }
                    totalPages = response.pageCount != null ? response.pageCount : 1;
                } else {
                    logError('Invoice API Error (Page ' + currentPage + ')',
                             'Status ' + res.getStatusCode() + ': ' + res.getBody(), null);
                    break;
                }
            } catch (Exception ex) {
                logError('Invoice Callout Error (Page ' + currentPage + ')',
                         ex.getMessage(), null);
                break;
            }
    
            currentPage++;
        } while (currentPage <= totalPages);
    
        return invoices;
	}
    
    private UnanetInvoiceIndividualWrapper getIndividualInvoice(String baseUrl, String token, Integer key) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(baseUrl + '/platform/rest/invoices/' + key);
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + token);
        req.setHeader('Content-Type', 'application/json');

        try {
            HttpResponse res = new Http().send(req);
            if (res.getStatusCode() == 200) {
                return (UnanetInvoiceIndividualWrapper)
                    JSON.deserialize(res.getBody(), UnanetInvoiceIndividualWrapper.class);
            } else {
                System.debug('Non-200 response for invoice key ' + key + ': ' + res.getStatusCode() + ' - ' + res.getBody());
                logError('Invoice Callout Error', 'Invoice key: ' + key + ' - Status: ' + res.getStatusCode() + ' Body: ' + res.getBody(), String.valueOf(key));
            }
        } catch (Exception e) {
            System.debug('Exception during callout for invoice key ' + key + ': ' + e.getMessage());
            logError('Invoice Callout Exception', 'Invoice key: ' + key + ' - ' + e.getMessage(), String.valueOf(key));
        }
        return null;
    }

    private Unanet_Invoice__c buildInvoice(UnanetInvoiceIndividualWrapper indInvoice, Id projectId) {
        return new Unanet_Invoice__c(
            Amount__c = indInvoice.amount,
            Billed_Account__c = indInvoice.billedAccount != null ? String.valueOf(indInvoice.billedAccount.key) : null,
            Billed_Organization__c = indInvoice.billedOrganization != null ? indInvoice.billedOrganization.name : null,
            Billing_Period_From_Date__c = indInvoice.billingPeriodFromDate,
            Billing_Through_Date__c = indInvoice.billingThroughDate,
            Discount_Amount__c = indInvoice.discountAmount,
            Instance_Amount__c = indInvoice.instanceAmount,
            Invoice_Date__c = indInvoice.invoiceDate,
            Invoice_Number__c = indInvoice.invoiceNumber,
            Local_Amount__c = indInvoice.localAmount,
            Organization__c = indInvoice.organization != null ? indInvoice.organization.name : null,
            Payment_Term__c = indInvoice.paymentTerm != null ? indInvoice.paymentTerm.code : null,
            Post_Date__c = indInvoice.postDate,
            Project__c = projectId,
            Status__c = indInvoice.status,
            Unanet_Id__c = String.valueOf(indInvoice.key)
        );
    }

    private void logError(String name, String description, String relatedId) {
        try {
            insert new Data_Log__c(
                Description__c       = description,
                Related_Record_Id__c = relatedId,
                Log_Origin__c        = 'Unanet invoice sync error'
            );
        } catch (Exception e) {
            System.debug('Failed to insert Data_Log__c: ' + e.getMessage());
        }
    }

}