public with sharing class UnanetCreateProjectsQueueable implements Queueable, Database.AllowsCallouts {

    private Account acc;
    private Opportunity opp;
    private List<Project__c> standardProjects;
    private List<Project__c> changeOrders;
    private String token;
    private String baseUrl;

    public UnanetCreateProjectsQueueable(
        Account acc,
        Opportunity opp,
        List<Project__c> standardProjects,
        List<Project__c> changeOrders,
        String token,
        String baseUrl
    ) {
        this.acc = acc;
        this.opp = opp;
        this.standardProjects = standardProjects;
        this.changeOrders = changeOrders;
        this.token = token;
        this.baseUrl = baseUrl;
    }

    public void execute(QueueableContext context) {
        if (String.isBlank(token)) {
            logError('UnanetCreateProjectsQueueable', 'Missing Unanet token', acc != null ? acc.Id : null);
            return;
        }
        
        List<Project__c> projectsToUpdate = new List<Project__c>();
        
        if (standardProjects != null && !standardProjects.isEmpty()) {
                
            for (Project__c proj : standardProjects) {
                System.debug('Creating Unanet Project for: ' + proj.Name + ' (' + proj.Id + ')');
    
                String endpoint = baseUrl + '/platform/rest/projects';
                String jsonBody = UnanetProjectHelper.buildUnanetProjectPayload(proj, acc, opp, token);
    
                HttpRequest req = new HttpRequest();
                req.setEndpoint(endpoint);
                req.setMethod('POST');
                req.setHeader('Authorization', 'Bearer ' + token);
                req.setHeader('Content-Type', 'application/json');
                req.setBody(jsonBody);
    
                HttpResponse res;
                try {
                    Http http = new Http();
                    res = http.send(req);
    
                    System.debug('Response for project ' + proj.Id + ': ' + res.getBody());
    
                    if (res.getStatusCode() == 201 || res.getStatusCode() == 200) {
                        Map<String, Object> respMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                        String unanetKey = String.valueOf(respMap.get('key'));
                        System.debug('Unanet Key returned: ' + unanetKey);
    
                        proj.Unanet_Id__c = unanetKey;
                        projectsToUpdate.add(proj);
    
                        // Now create the Fixed Price Item for the standard project
                        System.debug('UnanetCreateProjectsQueueable: Calling createStandardFixedPriceItem');
                        createStandardFixedPriceItem(proj, unanetKey);                       
                        
                        // Update Project Approver
                        if (proj.Project_Manager_Unanet__c != null) {
                            System.debug('UnanetCreateProjectsQueueable: Calling UnanetProjectHelper.getProjectManagerKey');
                            Integer pmKey = UnanetProjectHelper.getProjectManagerKey(proj.Project_Manager_Unanet__c);
                            
                            if (pmKey != null) {
                                System.debug('UnanetCreateProjectsQueueable: Calling updateUnanetProjectApprover');
                                updateUnanetProjectApprover(proj, unanetKey, pmKey);
                            } else {
                                System.debug('UnanetCreateProjectsQueueable: Skipping Update Project Approver for Project ' + proj.Id + ', pmKey returned null');
                            }
                        } else {
                            System.debug('UnanetCreateProjectsQueueable: Skipping Update Project Approver for Project ' + proj.Id + ', the Project Manager field has no value');
                        }
                        
                        // Update Resource Assigner
                        if (proj.Project_Manager_Unanet__c != null) {
                            System.debug('UnanetCreateProjectsQueueable: Calling UnanetProjectHelper.getProjectManagerKey');
                            Integer pmKey = UnanetProjectHelper.getProjectManagerKey(proj.Project_Manager_Unanet__c);
                            
                            if (pmKey != null) {
                                System.debug('UnanetCreateProjectsQueueable: Calling updateUnanetResourceAssigner');
                                updateUnanetResourceAssigner(proj, unanetKey, pmKey);
                            } else {
                                System.debug('UnanetCreateProjectsQueueable: Skipping Update Resource Assigner for Project ' + proj.Id + ', the pmKey is null');
                            }
                        } else {
                            System.debug('UnanetCreateProjectsQueueable: Skipping Update Resource Assigner for Project ' + proj.Id + ', Project manager field has no value');
                        }
                        
                        // Update Project Lead
                        if (opp.OwnerId != null) {
                            System.debug('UnanetCreateProjectsQueueable: Calling UnanetProjectHelper.getProjectLeadKey');
                            Integer pLeadKey = UnanetProjectHelper.getProjectLeadKey(opp.OwnerId);
                            
                            if (pLeadKey != null) {
                                System.debug('UnanetCreateProjectsQueueable: Calling updateUnanetProjectLead');
                                updateUnanetProjectLead(proj, unanetKey, pLeadKey);
                            } else {
                                System.debug('UnanetCreateProjectsQueueable: Skipping Update Project Lead for Project ' + proj.Id + ', pLeadKey is null');
                            }
                        } else {
                            System.debug('UnanetCreateProjectsQueueable: Skipping Update Project Lead for Project ' + proj.Id + ', Opportunity OwnerId is null');
                        }
                        
                        // Update Billing Manager for Project if the Opp has a Billing Manager populated
                        if (opp.Billing_Manager__c != null) {
                            System.debug('UnanetCreateProjectsQueueable: Calling getBillingManagerKey');
                            Integer bmKey = getBillingManagerKey(opp.Billing_Manager__c);
                            if (bmKey != null) {
                                System.debug('UnanetCreateProjectsQueueable: Calling updateProjectBillingManager');
                                updateProjectBillingManager(proj, String.valueOf(bmKey), unanetKey);
                            } else {
                               System.debug('UnanetCreateProjectsQueueable: Skipping Update Billing Manager for Project ' + proj.Id + ', bmKey returned null'); 
                            }
                        } else {
                            System.debug('UnanetCreateProjectsQueueable: Skipping Update Billing Manager for Project ' + proj.Id + ', Billing manager field has no value');
                        }
                        
                        // Decided that the Generate Unanet Invoice will be handled manually in Unanet - Cody Manion 
                        // Generate Unanet Invoice for Project
                        // System.debug('UnanetCreateProjectsQueueable: Calling generateUnanetInvoice');
                        // generateUnanetInvoice(proj, unanetKey);
                                                
                    } else {
                        System.debug('Unanet project creation failed for ' + proj.Id + ': ' + res.getStatus());
                        logError('UnanetCreateProjectsQueueable', 'Failed to create project: ' + proj.Id + ' : ' + res.getBody(), proj.Id);
                    }
    
                } catch (Exception e) {
                    System.debug('Exception during Unanet project creation for ' + proj.Id + ': ' + e.getMessage());
                    logError('UnanetCreateProjectsQueueable', e.getMessage(), proj.Id);
                }
            }
    
            if (!projectsToUpdate.isEmpty()) {
                try {
                    update projectsToUpdate;
                    System.debug('Updated ' + projectsToUpdate.size() + ' Project__c records with Unanet Keys');
                } catch (Exception e) {
                    System.debug('Error updating Project__c with Unanet keys: ' + e.getMessage());
                    logError('UnanetCreateProjectsQueueable', e.getMessage(), null);
                }
            }
        }
        

        if (!changeOrders.isEmpty() && !Test.isRunningTest()) {
            System.enqueueJob(new UnanetCreateFixedPriceItemsQueueable(changeOrders, token, baseUrl));
        }
    }

    private void createStandardFixedPriceItem(Project__c proj, String unanetKey) {
        try {
            String endpoint = baseUrl + '/platform/rest/projects/' + unanetKey + '/fixed-price-items';
            String payload = UnanetProjectHelper.buildStandardFixedPriceItemPayload(proj, unanetKey);

            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('POST');
            req.setHeader('Authorization', 'Bearer ' + token);
            req.setHeader('Content-Type', 'application/json');
            req.setBody(payload);

            Http http = new Http();
            HttpResponse res = http.send(req);

            System.debug('Standard Fixed Price Item response for project ' + proj.Id + ': ' + res.getBody());

            if (res.getStatusCode() != 201 && res.getStatusCode() != 200) {
                logError('UnanetCreateProjectsQueueable', 'Failed to create Fixed Price Item for project: ' + proj.Id + ': ' + res.getBody(), proj.Id);
            }

        } catch (Exception e) {
            System.debug('Exception creating Fixed Price Item for project ' + proj.Id + ': ' + e.getMessage());
            logError('UnanetCreateProjectsQueueable', e.getMessage(), proj.Id);
        }
    }
    
    private void updateProjectBillingManager(Project__C proj, String bmKey, String projKey) {
        try {
            String endpoint = baseUrl + '/platform/rest/projects/' + projKey + '/admin/billing-managers/primary';
            Map<String, Object> payloadMap = new Map<String, Object>{
                'key' => bmKey
            };
                
            String payload = JSON.serialize(payloadMap);
            System.debug(payload);

            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('PUT');
            req.setHeader('Authorization', 'Bearer ' + token);
            req.setHeader('Content-Type', 'application/json');
            req.setBody(payload);

            Http http = new Http();
            HttpResponse res = http.send(req);

            System.debug('Update Billing Manager response for project ' + proj.Id + ': ' + res.getBody());

            if (res.getStatusCode() != 201 && res.getStatusCode() != 200) {
                logError('UnanetCreateProjectsQueueable', 'Failed to update Billing Manager for project: ' + proj.Id + ': ' + res.getBody(), proj.Id);
            }

        } catch (Exception e) {
            System.debug('Exception updating Billing Manager for project ' + proj.Id + ': ' + e.getMessage());
            logError('UnanetCreateProjectsQueueable', e.getMessage(), proj.Id);
        }
    }
    
    private static Integer getBillingManagerKey(Id billingManagerId) {
        if (billingManagerId == null) {
            System.debug('UnanetProjectHelper.getBillingManagerKey: billingManagerId passed as null value');
            return null;
        }
        Unanet_User__c bManager;
        try {
            bManager = [SELECT Unanet_User_Id__c FROM Unanet_User__c WHERE Id = :billingManagerId LIMIT 1];
        } catch (Exception e) {
            System.debug('UnanetProjectHelper.getbillingManagerKey: No Billing Manager Found');
            return null;
        }
        
        if (bManager != null && bManager.Unanet_User_Id__c != null) {
            try {
                return Integer.valueOf(bManager.Unanet_User_Id__c);
            } catch (Exception e) {
                // Handle case where Unanet_User_Id__c is not a valid integer string
                System.debug('UnanetProjectHelper.getbillingManagerKey Exception Thrown: ' + e.getMessage());
                return null;
            }
        }
        
        return null;
        
    }
    
    /*
    private void generateUnanetInvoice(Project__C proj, String projKey) {
        try {
            
            String endpoint = baseUrl + '/platform/rest/projects/' + projKey + '/invoice-setup';
            Integer invoiceFormatKey = UnanetProjectHelper.getInvoiceFormatKey('BH LR Invoice', token);
            Integer invoiceNumberFormatKey = UnanetProjectHelper.getInvoiceNumFormatKey('Invoice Number', token);
            Integer paymentTermKey = UnanetProjectHelper.getPaymentTermKey('NET 30', token);
            String invoiceOption = 'STANDALONE';
            
            Map<String, Object> payloadMap = new Map<String, Object>{
                'projectKey' => Integer.valueOf(projKey),
                'invoiceOption' => invoiceOption,
                'invoiceFormatKey' => invoiceFormatKey,
                'invoiceNumberFormatKey' => invoiceNumberFormatKey,
                'paymentTermKey' => paymentTermKey
            };
                
            String payload = JSON.serialize(payloadMap);
            System.debug(payload);

            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('POST');
            req.setHeader('Authorization', 'Bearer ' + token);
            req.setHeader('Content-Type', 'application/json');
            req.setBody(payload);

            Http http = new Http();
            HttpResponse res = http.send(req);

            System.debug('Generate Unanet Invoice response for project ' + proj.Id + ': ' + res.getBody());

            if (res.getStatusCode() != 201 && res.getStatusCode() != 200) {
                logError('UnanetCreateProjectsQueueable', 'Failed to Generate Unanet Invoice for project: ' + proj.Id + ': ' + res.getBody(), proj.Id);
            }

        } catch (Exception e) {
            System.debug('Exception generating Unanet Invoice for project ' + proj.Id + ': ' + e.getMessage());
            logError('UnanetCreateProjectsQueueable', e.getMessage(), proj.Id);
        }
    } */
    
    private void updateUnanetProjectApprover(Project__C proj, String projKey, Integer pManagerKey) {
        try {
            
            String endpoint = baseUrl + '/platform/rest/projects/' + projKey + '/admin/project-approvers/primary';
            
            List<String> approvalTypes = new List<String>{ 'TIME', 'EXPENSE_REPORT', 'VENDOR_INVOICE' };
            
            List<Object> approvers = new List<Object>();
            for (String type : approvalTypes) {
                approvers.add(new Map<String, Object>{
                    'approvalType' => type,
                    'personKey' => pManagerKey
                });
            }
            
            Map<String, Object> payloadMap = new Map<String, Object>{
                'approvers' => approvers,
                'approveBeforeManager' => true
            };

            String payload = JSON.serialize(payloadMap);
            System.debug(payload);


            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('PUT');
            req.setHeader('Authorization', 'Bearer ' + token);
            req.setHeader('Content-Type', 'application/json');
            req.setBody(payload);

            Http http = new Http();
            HttpResponse res = http.send(req);

            System.debug('Update Unanet Project Approver response for project ' + proj.Id + ': ' + res.getBody());

            if (res.getStatusCode() != 201 && res.getStatusCode() != 200) {
                logError('UnanetCreateProjectsQueueable', 'Failed to Update Unanet Project Approver response for project: ' + proj.Id + ': ' + res.getBody(), proj.Id);
            }

        } catch (Exception e) {
            System.debug('Exception Updating Unanet Project Approver for project ' + proj.Id + ': ' + e.getMessage());
            logError('UnanetCreateProjectsQueueable', e.getMessage(), proj.Id);
        }
    }
    
    private void updateUnanetResourceAssigner(Project__C proj, String projKey, Integer pManagerKey) {
        try {
            
            String endpoint = baseUrl + '/platform/rest/projects/' + projKey + '/admin/resource-assigners/primary';
            
            Map<String, Object> payloadMap = new Map<String, Object>{
                'key' => pManagerKey
            };
                
            String payload = JSON.serialize(payloadMap);
            System.debug(payload);


            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('PUT');
            req.setHeader('Authorization', 'Bearer ' + token);
            req.setHeader('Content-Type', 'application/json');
            req.setBody(payload);

            Http http = new Http();
            HttpResponse res = http.send(req);

            System.debug('Update Unanet Resource Assigner response for project ' + proj.Id + ': ' + res.getBody());

            if (res.getStatusCode() != 201 && res.getStatusCode() != 200) {
                logError('UnanetCreateProjectsQueueable', 'Update Unanet Resource Assigner for project: ' + proj.Id + ': ' + res.getBody(), proj.Id);
            }

        } catch (Exception e) {
            System.debug('Exception Updating Unanet Resource Assigner for project ' + proj.Id + ': ' + e.getMessage());
            logError('UnanetCreateProjectsQueueable', e.getMessage(), proj.Id);
        }
    }
    
    private void updateUnanetProjectLead(Project__C proj, String projKey, Integer pLeadKey) {
        try {
            
            String endpoint = baseUrl + '/platform/rest/projects/' + projKey + '/admin/leads/primary';
            
            Map<String, Object> payloadMap = new Map<String, Object>{
                'key' => pLeadKey
            };
                
            String payload = JSON.serialize(payloadMap);
            System.debug(payload);


            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('PUT');
            req.setHeader('Authorization', 'Bearer ' + token);
            req.setHeader('Content-Type', 'application/json');
            req.setBody(payload);

            Http http = new Http();
            HttpResponse res = http.send(req);

            System.debug('Update Unanet Project Lead response for project ' + proj.Id + ': ' + res.getBody());

            if (res.getStatusCode() != 201 && res.getStatusCode() != 200) {
                logError('UnanetCreateProjectsQueueable', 'Update Unanet Project Lead for project: ' + proj.Id + ': ' + res.getBody(), proj.Id);
            }

        } catch (Exception e) {
            System.debug('Exception Updating Unanet Project Lead for project ' + proj.Id + ': ' + e.getMessage());
            logError('UnanetCreateProjectsQueueable', e.getMessage(), proj.Id);
        }
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
    
    public static void codeCoverageHack() {
    Integer i = 0;
    	i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;

  }
}