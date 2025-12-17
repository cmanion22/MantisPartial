import { LightningElement, track } from 'lwc';
import uploadCustomerPayments from '@salesforce/apex/CustomerPaymentUploadController.uploadCustomerPayments';
import sendErrorEmailWithAttachment from '@salesforce/apex/CustomerPaymentUploadController.sendErrorEmailWithAttachment';

export default class CustomerPaymentUpload extends LightningElement {
    @track data;
    @track errorMessage;
    @track errorCount = 0;
    @track errorList = [];
    @track showSpinner = false;

    @track columns = [
        { label: 'Document number', fieldName: 'Document_Number__c' },
        { label: 'Document date', fieldName: 'Document_Date__c' },
        { label: 'Post date', fieldName: 'Post_Date__c' },
        { label: 'Customer org code', fieldName: 'Customer_Org_Code__c' },
        { label: 'Project Number', fieldName: 'Project_Number__c' },
        { label: 'Project Name', fieldName: 'Project_Name__c' },
        { label: 'Paid payment amount', fieldName: 'Paid_payment_amount__c' },
        { label: 'Paid Invoice number', fieldName: 'Paid_Invoice_number__c' },
        { label: 'Paid Document Invoice POST Date', fieldName: 'Paid_Document_Invoice_POST_Date__c' },
        { label: 'Paid Invoice - Amt of Invoice', fieldName: 'Paid_Invoice_Amt_of_Invoice__c' },
        { label: 'Payment amount', fieldName: 'Payment_Amount__c' },
        { label: 'Primary Salesperson', fieldName: 'Primary_Salesperson__c' },
        { label: 'Secondary Sales Person', fieldName: 'Secondary_Sales_Person__c' },
        { label: 'As-Sold Margin', fieldName: 'As_Sold_Margin__c' },
        { label: 'Commission Plan Year', fieldName: 'Commission_Plan_Year__c' },
        { label: 'Offering Status', fieldName: 'Offering_Status__c' },
        { label: 'Commissionable', fieldName: 'Commissionable__c' },
        { label: 'Mantis Fee', fieldName: 'Mantis_Fee__c' }

    ];

    handleFileUpload(event) {
        this.errorMessage = null;
        this.data = null;
        this.errorCount = 0;
        this.errorList = [];
        this.showSpinner = true;

        const file = event.target.files[0];
        if (!file) return;

        const reader = new FileReader();
        reader.onload = () => {
            const csv = reader.result;
            try {
                const jsonData = this.parseCsvToJson(csv);
                this.sendToApex(jsonData);
            } catch (e) {
                this.showSpinner = false;
                this.errorMessage = 'Failed to parse CSV file: ' + e.message;
            }
        };
        reader.onerror = () => {
            this.showSpinner = false;
            this.errorMessage = 'Failed to read the file.';
        };
        reader.readAsText(file);
    }

    parseCsvToJson(csv) {
        const lines = csv.split(/\r\n|\n/).filter(line => line.trim() !== '');
        if (lines.length < 2) {
            throw new Error('CSV must contain a header and at least one row.');
        }

        const headers = this.parseCsvLine(lines[0]);
        const data = [];

        for (let i = 1; i < lines.length; i++) {
            const row = this.parseCsvLine(lines[i]);
            if (row.length === 0 || row.every(cell => cell.trim() === '')) continue;

            const obj = {};
            headers.forEach((header, index) => {
                const rawValue = row[index] ? row[index].trim() : '';
                obj[header.trim()] = this.castValue(header.trim(), rawValue);
            });

            data.push(obj);
        }

        return data;
    }

    parseCsvLine(line) {
        const result = [];
        let current = '';
        let inQuotes = false;

        for (let i = 0; i < line.length; i++) {
            const char = line.charAt(i);
            if (char === '"') {
                if (inQuotes && line.charAt(i + 1) === '"') {
                    current += '"';
                    i++;
                } else {
                    inQuotes = !inQuotes;
                }
            } else if (char === ',' && !inQuotes) {
                result.push(current);
                current = '';
            } else {
                current += char;
            }
        }
        result.push(current);
        return result;
    }

    castValue(header, value) {
        const numberFields = [
            'Paid payment amount',
            'Paid Invoice - Amt of Invoice',
            'Payment amount',
            'As-Sold Margin'
        ];
        const dateFields = [
            'Document date',
            'Post date',
            'Paid Document Invoice POST Date'
        ];

        if (numberFields.includes(header)) {
            const num = parseFloat(value.replace(/[$,]/g, ''));
            return isNaN(num) ? null : num;
        }

        if (dateFields.includes(header)) {
            return value;
        }

        return value;
    }

    sendToApex(rows) {
        uploadCustomerPayments({ rows })
            .then(result => {
                console.log('Apex returned result:', result);
                this.showSpinner = false;

                this.data = result.insertedRecords || [];
                this.errorList = result.errors || [];
                this.errorCount = this.errorList.length;

                console.log('Error count:', this.errorCount);

                if (this.errorCount > 0) {
                    this.errorMessage = `${this.errorCount} rows failed to upload. Download error CSV for details.`;
                    console.log('Calling sendErrorEmail from sendToApex');
                    this.sendErrorEmail();
                } else {
                    this.errorMessage = null;
                }
            })
            .catch(error => {
                console.error('Upload error:', JSON.stringify(error));
                this.errorMessage =
                    error?.body?.message || error?.message || 'Upload failed. Please contact support.';
            });
    }

    // CSV download helper
    downloadErrorsCsv() {
        console.log('downloadErrorsCsv called');
        if (this.errorCount === 0) {
            console.log('No errors to download');
            return;
        }

        const headers = ['Row', 'Document Number', 'Project Number', 'Invoice Number', 'Error'];
        console.log('Error list:', this.errorList);

        const rows = this.errorList.map(err => {
            const docNum = err.documentNumber ? err.documentNumber.replace(/"/g, '""') : '';
            const projNum = err.projectNumber ? err.projectNumber.replace(/"/g, '""') : '';
            const invNum = err.invoiceNumber ? err.invoiceNumber.replace(/"/g, '""') : '';
            const errorMsg = err.error ? err.error.replace(/"/g, '""') : '';
            return [
                err.row,
                `"${docNum}"`,
                `"${projNum}"`,
                `"${invNum}"`,
                `"${errorMsg}"`
            ];
        });

        let csvContent = headers.join(',') + '\n';
        rows.forEach(r => {
            csvContent += `${r.join(',')}\n`;
        });
        console.log('CSV content:', csvContent);

        const encodedUri = 'data:text/csv;charset=utf-8,' + encodeURIComponent(csvContent);
        console.log('Encoded URI:', encodedUri);

        const anchor = document.createElement('a');
        anchor.href = encodedUri;
        anchor.target = '_self';
        const today = new Date();
        const yyyy = today.getFullYear();
        const mm = String(today.getMonth() + 1).padStart(2, '0');
        const dd = String(today.getDate()).padStart(2, '0');

        const fileName = `customer_payment_upload_errors_${yyyy}${mm}${dd}.csv`;
        anchor.download = fileName;

        document.body.appendChild(anchor);
        console.log('Anchor added to DOM');
        anchor.click();
        console.log('Anchor clicked');
        document.body.removeChild(anchor);
        console.log('Anchor removed from DOM');
    }

    generateErrorsCsv() {
        if (this.errorCount === 0) return '';

        const headers = ['Row', 'Project Number', 'Invoice Number', 'Document Number', 'Error'];

        const rows = this.errorList.map(err => {
            const row = err.row != null ? String(err.row).replace(/"/g, '""') : '';
            const projectNumber = err.projectNumber ? err.projectNumber.replace(/"/g, '""') : '';
            const invoiceNumber = err.invoiceNumber ? err.invoiceNumber.replace(/"/g, '""') : '';
            const documentNumber = err.documentNumber ? err.documentNumber.replace(/"/g, '""') : '';
            const errorMsg = err.error ? err.error.replace(/"/g, '""') : '';

            return [
                `"${row}"`,
                `"${documentNumber}"`,
                `"${projectNumber}"`,
                `"${invoiceNumber}"`,                
                `"${errorMsg}"`
            ];
        });

        let csvContent = headers.join(',') + '\n';
        rows.forEach(row => {
            csvContent += row.join(',') + '\n';
        });

        return csvContent;
    }


    sendErrorEmail() {
        try {
            console.log('Calling Send Error Email in JS');
            const csvContent = this.generateErrorsCsv();
            if (!csvContent) {
                console.warn('No errors to send by email.');
                return;
            }

            const base64Data = btoa(
                encodeURIComponent(csvContent).replace(/%([0-9A-F]{2})/g,
                    (match, p1) => String.fromCharCode(parseInt(p1, 16))
                )
            );

            sendErrorEmailWithAttachment({
                base64Data: base64Data,
                fileName: 'Upload_Errors.csv',
                mimeType: 'text/csv'
            })
            .then(() => console.log('Email sent'))
            .catch(error => console.error('Error sending email', error));

        } catch (error) {
            console.error('Error in sendErrorEmail:', error);
        }
    }

}