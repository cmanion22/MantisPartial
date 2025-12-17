public with sharing class CustomerPaymentUploadController {
    @AuraEnabled
    public static Map<String, Object> uploadCustomerPayments(List<Map<String, Object>> rows) {
        List<Unanet_Customer_Payment__c> recordsToInsert = new List<Unanet_Customer_Payment__c>();
        List<Map<String, String>> errors = new List<Map<String, String>>();  // Changed to List of Maps for better error info

        Set<String> projectNumbers = new Set<String>();
        Set<String> invoiceNumbers = new Set<String>();

        for (Map<String, Object> row : rows) {
            String projectNumber = (String) row.get('Project Number');
            String invoiceNumber = (String) row.get('Paid Invoice number');
            if (!String.isBlank(projectNumber)) projectNumbers.add(projectNumber);
            if (!String.isBlank(invoiceNumber)) invoiceNumbers.add(invoiceNumber);
        }

        Map<String, Project__c> projectMap = new Map<String, Project__c>();
        Map<String, Unanet_Invoice__c> invoiceMap = new Map<String, Unanet_Invoice__c>();
        List<Map<String, String>> rowMetadata = new List<Map<String, String>>();

        for (Project__c p : [
            SELECT Id, Project_Number__c 
            FROM Project__c 
            WHERE Project_Number__c IN :projectNumbers
        ]) {
            projectMap.put(p.Project_Number__c, p);
        }

        for (Unanet_Invoice__c inv : [
            SELECT Id, Invoice_Number__c 
            FROM Unanet_Invoice__c 
            WHERE Invoice_Number__c IN :invoiceNumbers
        ]) {
            invoiceMap.put(inv.Invoice_Number__c, inv);
        }
        
        for (Integer i = 0; i < rows.size(); i++) {
            Map<String, Object> row = rows[i];
            try {
                String projectNumber = (String) row.get('Project Number');
                String invoiceNumber = (String) row.get('Paid Invoice number');

                Project__c project = projectMap.get(projectNumber);
                if (project == null) {
                    errors.add(new Map<String, String>{
                        'row' => String.valueOf(i + 2),
                        'documentNumber' => (String) row.get('Document number'),
                        'projectNumber' => (String) row.get('Project Number'),
                        'invoiceNumber' => (String) row.get('Paid Invoice number'),
                        'error' => 'No matching Project for "' + projectNumber + '"'
                    });
                    continue;
                }

                Unanet_Invoice__c invoice = invoiceMap.get(invoiceNumber);

                Unanet_Customer_Payment__c cp = new Unanet_Customer_Payment__c(
                    Document_Number__c  = (String) row.get('Document number'),
                    Document_Date__c  = parseCustomDate((String) row.get('Document date')),
                    Post_Date__c  = parseCustomDate((String) row.get('Post date')),
                    Customer_Org_Code__c = (String) row.get('Customer org code'),
                    Project_Number__c = projectNumber,
                    Project_Name__c = (String) row.get('Project Name'),
                    Project__c = project.Id,
                    Paid_payment_amount__c = safeToDecimal(row.get('Paid payment amount')),
                    Unanet_Invoice__c = (invoice != null && invoice.Id != null) ? invoice.Id : null,
                    Paid_Invoice_number__c = invoiceNumber,
                    Paid_Document_Invoice_POST_Date__c = parseCustomDate((String) row.get('Paid Document Invoice POST Date')),
                    Paid_Invoice_Amt_of_Invoice__c = safeToDecimal(row.get('Paid Invoice - Amt of Invoice')),
                    Payment_Amount__c = safeToDecimal(row.get('Payment amount')),
                    Primary_Salesperson__c = (String) row.get('Primary Salesperson'),
                    Secondary_Sales_Person__c = (String) row.get('Secondary Sales Person'),
                    As_Sold_Margin__c = safeToDecimal(row.get('As-Sold Margin')),
                    Commission_Plan_Year__c = (String) row.get('Commission Plan Year'),
                    Offering_Status__c = (String) row.get('Offering Status'),
                    Commissionable__c = row.get('Commissionable') == null ? false : Boolean.valueOf(String.valueOf(row.get('Commissionable'))),
                    Mantis_Fee__c = safeToDecimal(row.get('Mantis Fee'))
                );

                rowMetadata.add(new Map<String, String>{
                    'documentNumber' => (String) row.get('Document number'),
                    'projectNumber' => (String) row.get('Project Number'),
                    'invoiceNumber' => (String) row.get('Paid Invoice number')
                });

                recordsToInsert.add(cp);

            } catch (Exception e) {
                errors.add(new Map<String, String>{
                    'row' => String.valueOf(i + 1),
                    'documentNumber' => (String) row.get('Document number'),
                    'projectNumber' => (String) row.get('Project Number'),
                    'invoiceNumber' => (String) row.get('Paid Invoice number'),
                    'error' => e.getMessage()
                });
            }
        }

        if (!recordsToInsert.isEmpty()) {
            Database.SaveResult[] results = Database.insert(recordsToInsert, false);
        
            for (Integer i = 0; i < results.size(); i++) {
                if (!results[i].isSuccess()) {
                    for (Database.Error err : results[i].getErrors()) {
                        System.debug('>>> Failed record: ' + JSON.serialize(recordsToInsert[i]));
                        System.debug('>>> Error: ' + err.getMessage());
        
                        Map<String, String> meta = (i < rowMetadata.size()) ? rowMetadata[i] : new Map<String, String>();
        
                        errors.add(new Map<String, String>{
                            'row' => String.valueOf(i + 2),
                            'documentNumber' => meta.get('documentNumber'),
                            'projectNumber' => meta.get('projectNumber'),
                            'invoiceNumber' => meta.get('invoiceNumber'),
                            'error' => 'DML Error: ' + err.getMessage()
                        });
                    }
                }
            }
        }


        return new Map<String, Object>{
            'insertedRecords' => recordsToInsert,
            'errors' => errors,
            'errorCount' => errors.size()
        };
    }

    private static Decimal safeToDecimal(Object inputObj) {
        if (inputObj == null) return 0;
    
        String input = String.valueOf(inputObj).trim();
        if (String.isBlank(input)) return 0;
    
        input = input
            .replace('−', '-')
            .replace('–', '-')
            .replace('—', '-')
            .replace('‐', '-');
    
        input = input.replaceAll('[$,]', '');
    
        if (input == '-' || input == '$-' || input == '-$') {
            return 0;
        }
    
        try {
            return Decimal.valueOf(input);
        } catch (Exception e) {
            throw new AuraHandledException('Invalid decimal: ' + input);
        }
    }

    private static Date parseCustomDate(String input) {
        if (String.isBlank(input)) return null;

        input = input.trim();
        List<String> parts = input.split('/');

        if (parts.size() != 3) {
            throw new AuraHandledException('Invalid date format: ' + input);
        }

        try {
            Integer month = Integer.valueOf(parts[0]);
            Integer day = Integer.valueOf(parts[1]);
            Integer year = Integer.valueOf(parts[2]);

            if (year < 100) {
                year += 2000;
            }

            return Date.newInstance(year, month, day);
        } catch (Exception e) {
            throw new AuraHandledException('Invalid date components in: ' + input);
        }
    }

    @AuraEnabled
    public static void sendErrorEmailWithAttachment(String base64Data, String fileName, String mimeType) {
        System.debug('Preparing Error Email to be sent out');

        // Decode the Base64 file
        Blob fileBlob = EncodingUtil.base64Decode(base64Data);

        // Build the email attachment
        Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
        attachment.setFileName(fileName);
        attachment.setBody(fileBlob);
        attachment.setContentType(mimeType);

        // Construct the email
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[] { UserInfo.getUserEmail() });
        // mail.setToAddresses(new String[] { 'manioncody22@gmail.com' });
        mail.setSubject('CSV Upload Errors');
        mail.setPlainTextBody('Your file upload contained errors. See attached CSV for details.');
        mail.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });

        List<OrgWideEmailAddress> oweList = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'sfsupport@mantisinnovation.com' LIMIT 1];
        if (!oweList.isEmpty()) {
            mail.setOrgWideEmailAddressId(oweList[0].Id);
        }

        System.debug('Sending Email');

        try {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        } catch (Exception e) {
            System.debug('Error sending email: ' + e.getMessage());
        }
    }

}