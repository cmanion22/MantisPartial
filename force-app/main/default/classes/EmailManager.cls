public class EmailManager {
    public static void sendMail(String[] address, String subject, String body, String fileName, String fileID, WorkOrder w) {

        // Create an email message object
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = address; //new String[] {'rishabh.singhal@cygrp.com'};//address; 
        mail.setToAddresses(toAddresses);
        mail.setSubject(subject);
        // 12.9.25 - Per request from Andrea Tovar, Service Report PDFs should no longer be attached to approval emails.
       // Change implemented by: Cody Manion
        // Attaching ServiceReport
        /*
        List<Messaging.Emailfileattachment> fileAttachments = new List<Messaging.Emailfileattachment>();
        
        if(fileId != ''){
            Messaging.Emailfileattachment efa = new Messaging.Emailfileattachment();
            Blob attBody = [select DocumentBody from ServiceReport where Id = :fileID limit 1].DocumentBody;
            efa.setContentType('application/pdf');
            efa.setInline(false);
            efa.setFileName(fileName+'.pdf');
            efa.setBody(attBody);
            fileAttachments.add(efa);
        }
                    	
        if(w != null){
			if(w.Status == 'Approved'){
                List<FeedItem> feeds = [select Id,Type,Body,Title,RelatedRecordId from FeedItem where ParentId = :w.Id order by ID desc];
                Messaging.Emailfileattachment efa = new Messaging.Emailfileattachment();
                for(Integer i=0; i<feeds.size(); i++){
                    if(feeds[i].Type == 'ContentPost'){
                        Messaging.Emailfileattachment efa2 = new Messaging.Emailfileattachment();
                        system.debug('IDDD : '+feeds[i].RelatedRecordId);
                        Blob attBody = [Select VersionData from ContentVersion where Id = :feeds[i].RelatedRecordId and IsLatest = true].VersionData;
                        efa2.setInline(false);
                        efa2.setFileName(feeds[i].Title);
                        efa2.setBody(attBody);
                        fileAttachments.add(efa2);
                        //zip.addFile('Attachments/'+feeds[i].Title, Blob.valueOf('Testing'), null);    
                    } 
                }
                String pdfData =  createServiceReport(w, feeds);
                                
                efa.setContentType('application/pdf');
                efa.setInline(false);
                efa.setFileName('ServiceReport.pdf');
                efa.setBody(Blob.toPdf(pdfData));
                
                fileAttachments.add(efa);                
        	}
        }
            
        mail.setFileAttachments(fileAttachments);
        mail.setHtmlBody(body);
        */
        mail.setHtmlBody(body);

        if (!Test.isRunningTest()) {
            // Pass this email message to the built-in sendEmail method 
            // of the Messaging class
            Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            
            // Call a helper method to inspect the returned results
            inspectResults(results);
        }
    }
    
    // Helper method
    private static Boolean inspectResults(Messaging.SendEmailResult[] results) {
        Boolean sendResult = true;
        
        // sendEmail returns an array of result objects.
        // Iterate through the list to inspect results. 
        // In this class, the methods send only one email, 
        // so we should have only one result.
        for (Messaging.SendEmailResult res : results) {
            if (res.isSuccess()) {
                System.debug('Email sent successfully');
            }
            else {
                sendResult = false;
                System.debug('The following errors occurred: ' + res.getErrors());                 
            }
        }
        
        return sendResult;
    }
	
    private static String createServiceReport(WorkOrder w, List<FeedItem> feeds){
        List<WorkOrderLineItem> WL = [select Id, LineItemNumber,Description, Status,Price__c, StartDate, EndDate, UnitPrice,Discount,Quantity__c,TotalPrice__c from WorkOrderLineItem where WorkOrderId = :w.Id];
        
        List<Work_Order_Section_Junction__c> woSections = [SELECT Id, Section_NameFx__c FROM Work_Order_Section_Junction__c WHERE Work_Order__c = :w.Id];
		String SectionsName = ''; 

		if (!woSections.isEmpty()) {
    	for (Work_Order_Section_Junction__c woSec : woSections) {
        	// Append the section name to the SectionsName string with a semicolon
        	if (String.isNotEmpty(SectionsName)) {
            SectionsName += ';';  // Add semicolon between names
        	}
        	SectionsName += woSec.Section_NameFx__c;  // Append the Section_NameFx__c value
    	}
	}

        
        ServiceAppointment sr = [select Id, Status from ServiceAppointment where ParentRecordId = :w.Id ORDER BY Id DESC limit 1];
        String sRes = ([select ID, ServiceResourceId from AssignedResource where ServiceAppointmentId=:sr.Id limit 1].size() < 1 ? '' : [select ID, ServiceResourceId from AssignedResource where ServiceAppointmentId=:sr.Id limit 1].ServiceResourceId);
        String STM = (sRes == '') ? '' :[select ID, ServiceTerritoryId from ServiceTerritoryMember where ServiceResourceId=:sRes].ServiceTerritoryId;
        String regionName = (STM == '') ? '' : [select Id, Name from ServiceTerritory where Id =:STM].Name;
        WorkType workType = (w.WorkTypeId == null ? null : [select Id, Name from WorkType where Id=:w.WorkTypeId]);
        List<Cost_Type__c> CT = [select Id, Cost_Type__c, Other_Cost_Type__c, Cost__c,CurrencyIsoCode  from Cost_Type__c where Work_Order__c =: w.Id];
        String User = [Select Id, Name from User where Id = :w.OwnerId].Name;
        Integer TotalPrice=0, Quantity=0,UnitPrice=0;
        String AccountName='';
        if(w.AccountId != null){
        	Account acc = [select Id, Name from Account where Id =: w.AccountId];
         	AccountName = acc.Name == null ? '' : acc.Name+';';    
        }
        String ContactPhone = '',ContactEmail='',ContactMobile='';
        if(w.ContactId != null){
            Contact contact = [Select Id, Name, Email, Phone, MobilePhone from Contact where Id =: w.ContactId];
            ContactPhone = contact.Phone == null ? '' : ' ,'+contact.Phone;
            ContactEmail = contact.Email == null ? '' : ' ,'+contact.Email;
            ContactMobile = contact.MobilePhone == null ? '' : ' ,'+contact.MobilePhone; 
        }
         
        
        String WOStartDate = '', WOEndDate = '';
        if(w.StartDate != null){
            WOStartDate = String.valueOf(w.StartDate);
        }
        if(w.EndDate != null){
            WOEndDate = String.valueOf(w.EndDate);
        }
               
        String header = '<DIV><TABLE Cellpadding="2" style="font-size:10px;"><TR><TH style="text-align:left;">WO : '+w.WorkOrderNumber+'</TH><TH style="text-align:right;">Reported: '+date.today().format()+'</TH></TR></Table></DIV>';
        
        header = header+'<p style="font-size:12px;text-align:center;"><b>Bluefin LLC</b></p>'+ 
                        '<p style="font-size:12px;text-align:center;"><b>WORK ORDER</b></p>'+
                        '<p style="font-size:12px;text-align:center;">'+ AccountName + (WorkType !=null ?WorkType.Name:'') +'</p> ';
        
        String ServiceReport = '<TABLE bgColor="#C7C7F6" Cellpadding="2" style="font-size:10px;"><TR><TH>Site Information</TH></TR></Table>' +
                                '<TABLE cellpadding=0 cellspacing=0 class="t0" style="font-size:8px;">' +
                                    '<TR> <TD><b>Site Name: </b></TD> <TD colspan="2"><P>' + (w.PropertyName__c == null ? '' : w.PropertyName__c) + '</P></TD> ' +
                                    '<TD><b>AREA 1 NAME:</b></TD> <TD colspan="2"><P>' + (SectionsName == null ? '' : SectionsName) + '</P></TD> </TR>' +
                                    '<TR> <TD><b>NTE: </b></TD> <TD colspan="2"><P>$' + w.NTE__c + '</P></TD> ' +
                                    '<TD><b>REGION:</b></TD> <TD colspan="2"><P>' + regionName + '</P></TD> </TR>' + 
                                    '<TR> <TD colspan="1"><b>Address</b></TD> <TD colspan="5"><P>' + w.PropertyAddress__c + '</P></TD> </TR>' +
                                    '<TR> <TD colspan="6" style="font-size:10px;"><b>Contact Information</b></TD> </TR>' +  
                                    '<TR> <TD colspan="1"><b>Reported By: </b></TD> <TD colspan="5">' + contact.Name + ContactPhone + ContactMobile + ContactEmail + '</TD> </TR>' +
                                '</TABLE>';

                                
        
        String CostType = '<TR> 	<TD colspan="12" style="font-size:10px;"><b>Cost Types :-</b></TD>  </TR>';
        for(Integer i=0; i<CT.size(); i++){
            //System.debug(i);
            CostType = CostType + '<TR>'+
                		'<td colspan="3"><b>'+(CT[i].Cost_Type__c == 'Other Costs' ? CT[i].Other_Cost_Type__c : CT[i].Cost_Type__c)+'</b></td>'+
                		'<td colspan="3">'+ CT[i].CurrencyIsoCode + ' ' + CT[i].Cost__c +'</td>';
            If(CT.size() > i+1){
                CostType = CostType +
                		'<td colspan="3"><b>'+(CT[i+1].Cost_Type__c == 'Other Costs' ? CT[i+1].Other_Cost_Type__c : CT[i+1].Cost_Type__c)+'</b></td>'+
                		'<td colspan="3">'+ CT[i+1].CurrencyIsoCode + ' ' + CT[i+1].Cost__c +'</td>';
            } else {
                CostType = CostType +
                		'<td>&nbsp;</td>'+
                		'<td colspan="5">&nbsp;</td>';
            }
            CostType = CostType + '</TR>';
            i = i+1;
            //System.debug(i);
        }
        
        String WorkDetails = '<p>&nbsp;</p><TABLE bgColor="#C7C7F6" Cellpadding="2" style="font-size:10px;"><TR><TH>Work Details</TH></TR></Table>'+
                             '<TABLE cellpadding=0 cellspacing=0 class="t0" style="font-size:8px;">'+
                             '<TR> 	<TD colspan="2"><b>Subject</b></TD> 	<TD colspan="10"><P>'+(w.Subject == null ? '' : w.Subject)+'</P></TD> </TR>'+
                             '<TR> 	<TD colspan="2"><b>Description</b></TD> 	<TD colspan="10"><P>'+(w.Description == null ? '' : w.Description)+'</P></TD> </TR>'+
            				 '<TR> 	<TD colspan="2"><b>Start Date</b></TD> 	<TD colspan="4"><P>'+WOStartDate+'</P></TD> 	<TD colspan="2"><b>End Date</b></TD> 	<TD colspan="4"><P>'+ WOEndDate +'</P></TD> </TR>'+
            				 '<TR> 	<TD colspan="2"><b>Bluefin Fee:</b></TD> 	<TD colspan="4"><P>'+w.Cost__c+'</P></TD> 	<TD colspan="2"><b>Total Amount:</b></TD> 	<TD colspan="4"><P>'+ w.Total_Price__c +'</P></TD> </TR>'+
                             CostType +                    
                             '</TABLE>';
        
        
        
        // Work Order Line Items
        String WorkOrderLineItems = '<p>&nbsp;</p><TABLE bgColor="#C7C7F6" style="font-size:10px;"><TR><TH>Work Order Line Items</TH></TR></Table>'+
                                    '<TABLE Cellpadding="2" cellspacing=0 style="font-size:9px;">'+ 
                                    '<TR bgColor="#A7A7A9" style="font-size:9px;">'+
                                    '<TD colspan="3" ><b>Description</b></TD>'+
                                    '<TD><b>Status</b></TD>'+
                                    '<TD><b>Start Date</b></TD>'+
                                    '<TD><b>End Date</b></TD>'+	
                                    '<TD><b>Price</b></TD> '+
                                    '<TD><b>Quantity</b></TD>'+
                                    '<TD><b>Total Price</b></TD> '+
                                    '</TR> ';
        for(Integer i=0; i < WL.size(); i++){
            UnitPrice = (WL[i].UnitPrice == null) ? 0 : Integer.valueOf(WL[i].UnitPrice);
            Quantity = (WL[i].Quantity__c == null) ? 0 : Integer.valueOf(WL[i].Quantity__c);
            TotalPrice = TotalPrice + (UnitPrice*Quantity);
            String WOLI_StartDate = '', WOLI_EndDate = '';
            If(WL[i].StartDate != null){
                WOLI_StartDate = String.valueOf(WL[i].StartDate);
            }
            If(WL[i].EndDate != null){
                WOLI_EndDate = String.valueOf(WL[i].EndDate);
            }
            WorkOrderLineItems = WorkOrderLineItems + 
                				'<TR bgColor='+(math.mod(i,2) == 1 ? '"#C3C3C7"' : '"white"')+' style="font-size:8px;">'+
                                '<TD colspan="2" ><P>'+WL[i].Description+'</P></TD>'+
                                '<TD>&nbsp;</TD>'+
                                '<TD><P>'+ (WL[i].Status == null ? '' : WL[i].Status) +'</P></TD>'+
                                '<TD><P>'+ WOLI_StartDate +'</P></TD>'+
                                '<TD><P>'+ WOLI_EndDate +'</P></TD>'+	
                                '<TD><P>'+ (WL[i].Price__c) +'</P></TD>'+
                                '<TD><P>'+ Quantity +'</P></TD>'+
                                '<TD><P>'+ WL[i].TotalPrice__c +'</P></TD>'+
                				'</TR>';
        }
        WorkOrderLineItems += '<p>&nbsp;</P><TR> '+
                            '<TD colspan="2"><P>&nbsp;</P></TD>'+
                            '<TD>&nbsp;</TD>'+
                            '<TD><P>&nbsp;</P></TD>'+
                            '<TD><P>&nbsp;</P></TD>'+
                            '<TD><P>Total Price</P></TD>'+	
                            '<TD><P>&nbsp;</P></TD>'+
                            '<TD  colspan="2"><P>USD '+w.WO_Line_Item_Price__c+'</P></TD>'+
                            '</TR>'+'</TABLE>';
        
        // Notes And Attachment
        String NotesAndAttachments = '<p>&nbsp;</p><TABLE Cellpadding="2" bgColor="#C7C7F6" style="font-size:10px;"><TR><TH>Notes And Attachments</TH></TR></Table>';
        NotesAndAttachments += '<TABLE Cellpadding="2">'+ 
                               '<TR bgColor="#A7A7A9" style="font-size:9px;">'+
                               '<TH><b>S.No</b></TH>'+
                               '<TH><b>Title</b></TH>'+
       	   					   '<TH>&nbsp;</TH>'+
                               '<TH><b>Body</b></TH>'+
                			   '<TH>&nbsp;</TH>'+
                			   '<TH>&nbsp;</TH>'+
                			   '<TH>&nbsp;</TH>'+
                               '<TH><b>Attachment</b></TH>'+
                			   '<TH>&nbsp;</TH>'+
                               '</TR> ';
        
        for(Integer i=0; i<feeds.size(); i++){
             If(feeds[i].Type == 'TextPost'){
                 NotesAndAttachments += '<TR bgColor='+(math.mod(i,2) == 1 ? '"#C3C3C7"' : '"white"')+' style="font-size:8px;">'+
                                        '<TD><P>'+(i+1)+'</P></TD>'+
                                        '<TD colspan="2"><P>'+(feeds[i].Title == null ? '' : feeds[i].Title)+'</P></TD>'+
                                        '<TD colspan="4"><P>'+(feeds[i].Body == null ? '' : feeds[i].Body)+'</P></TD>'+
                                        '<TD colspan="2"><P>'+''+'</P></TD>'+
                                        '</TR> ';
             }
             If(feeds[i].Type == 'ContentPost'){
                 String fileType = [Select FileType from ContentVersion where Id = :feeds[i].RelatedRecordId and IsLatest = true].FileType;
                 NotesAndAttachments += '<TR bgColor='+(math.mod(i,2) == 1 ? '"#C3C3C7"' : '"white"')+' style="font-size:8px;">'+
                                        '<TD><P>'+(i+1)+'</P></TD>'+
                                        '<TD colspan="2"><P>'+(feeds[i].Title == null ? '' : feeds[i].Title)+'</P></TD>'+
                                        '<TD colspan="4"><P>'+(feeds[i].Body == null ? '' : feeds[i].Body)+'</P></TD>'+
                                        //'<TD colspan="2"><P>'+'<a href="https://mantis--partial.lightning.force.com/lightning/r/ContentDocument/'+feeds[i].RelatedRecordId+'/view" style="color:blue;">click here to see attachment</a>'+'</P></TD>'+
                                        '<TD colspan="2"><P>'+'<a href="'+feeds[i].Title+'" style="color:blue;">click here to see attachment</a>'+'</P></TD>'+
                                        '</TR> ';
             }
        }    
        NotesAndAttachments += '</TABLE>';
        
        return '<HTML>'+
               '<BODY>'+
               '<DIV class="id1_1">'+
               header+//image+
               ServiceReport+
               WorkDetails+
               WorkOrderLineItems+
               NotesAndAttachments+
               '</DIV>'+
               '</BODY>'+
               '</HTML>';
    }
}