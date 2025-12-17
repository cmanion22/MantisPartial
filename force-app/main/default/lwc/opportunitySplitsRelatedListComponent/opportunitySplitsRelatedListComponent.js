import { LightningElement, track, wire, api } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import getOpportunitySplits from '@salesforce/apex/OpportunitySplitRelatedListController.getOpportunitySplits';
import createOpportunitySplit from '@salesforce/apex/OpportunitySplitRelatedListController.createOpportunitySplit';
import checkUserPermissions from '@salesforce/apex/OpportunitySplitRelatedListController.checkUserPermissions'; // Import checkUserPermissions
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import updateOpportunitySplits from '@salesforce/apex/OpportunitySplitRelatedListController.updateOpportunitySplits';
import isServicesRecordType from '@salesforce/apex/OpportunitySplitRelatedListController.isServicesRecordType';
import getUsers from '@salesforce/apex/OpportunitySplitRelatedListController.getUsers';  // Apex method to fetch users
import { refreshApex } from '@salesforce/apex';

const FIELDS = ['Opportunity.OwnerId'];

export default class OpportunitySplits extends LightningElement {
    @api recordId; // Salesforce automatically populates this with the OpportunityId when on a record page
    @track opportunitySplits;
    @track tableData; // For datatable functionality
    @track isModalOpen = false;
    @track isEditModalOpen = false;
    @track isFlowOpen = false; // Tracks if the Flow modal is open
    @track permissions = { showNew: true, showChangeRequest: true, showEdit: true }; // Initialize permissions
    @track draftValues = [];
    @track isServicesRecordType = false;
    @track ownerOptions = []; 
    @track isUserPicklistVisible = false; // Toggle for picklist visibility
    @track selectedUserId = ''; // Holds the selected user ID
    @track showAddRow = false;
    @track inputVariables = [];
    @track refreshKey = 0;
    @track isDataLoaded = false; // Flag to check if data is loaded
    @track wiredResult; // To store the wire result for refresh
    @track error;

    // Columns for opportunity splits
    columns = [
        {
            label: 'Team Member',
            fieldName: 'recordUrl', // The Salesforce record ID
            type: 'url', // Render as a hyperlink
            typeAttributes: {
                label: { fieldName: 'Team_MemberFx__c' }, // Display the Name as the clickable link
                target: '_self' // Open in the same tab (optional, default is `_self`)
            }
        },
        {
            label: 'Percent (%)',
            fieldName: 'Formatted_Percent',
            type: 'text', // Use type 'text' since we're formatting the value ourselves
        }
    ];

 
    // Columns for existing splits in the modal
    existingSplitColumns = [
        {
            label: 'Team Member',
            fieldName: 'Team_MemberFx__c',
            type: 'text',
            cellAttributes: { class: 'custom-datatable-editable-cell' },
            initialWidth: 300, // Fixed width for "Percent (%)"
            
        },
    
        {
            label: 'Percent (%)',
            fieldName: 'Split_Percentage__c',
            type: 'number',
            editable: true,
            cellAttributes: { class: 'custom-datatable-editable-cell' },
            initialWidth: 200, // Fixed width for "Percent (%)"
        }
    ];

    // Getter for dynamically adding "Current Percentage" to opportunity splits columns
    get columnsWithConditionalField() {
        return this.isServicesRecordType
            ? this.columns // Just return the columns without "Current Percentage" for Services
            : [
                ...this.columns,
                {
                    label: 'Current Percentage',
                    fieldName: 'Formatted_Current_Percent',
                    type: 'text', // Use type 'text' since we're formatting the value ourselves
                }
            ];
    }


    // Getter for dynamically adding "Current Percentage" to existing splits columns
    get existingSplitColumnsWithConditionalField() {
        return this.isServicesRecordType
            ? this.existingSplitColumns // Just return the existingSplitColumns without "Current Percentage" for Services
            : [
                ...this.existingSplitColumns,
                {
                    label: 'Current Percentage',
                    fieldName: 'Current_Percentage__c',
                    type: 'number',
                    editable: true,
                    cellAttributes: { class: 'custom-datatable-editable-cell' },
                    initialWidth: 200, // Fixed width for "Current Percentage"
                }
            ];
    }

        // Wire to get the Opportunity record
        @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
        wiredOpportunity({ error, data }) {
            if (data) {
                this.opportunityData = data;
                this.handleManualRefresh();
            } else if (error) {
                this.error = error;
            }
        }
    

    @wire(getOpportunitySplits, { opportunityId: '$recordId', refreshKey: '$refreshKey' })
    wiredOpportunitySplits(result) {
        this.wiredOpportunitySplitsResult = result; // Store the reference to the wire result

        if (result.data) {
            this.opportunitySplits = result.data.map(split => {
                return {
                    ...split,
                    recordUrl: `/lightning/r/Opportunity_Split__c/${split.Id}/view`, // Generate record URL
                    Formatted_Percent: split.Split_Percentage__c !== null && split.Split_Percentage__c !== undefined
                        ? (split.Split_Percentage__c).toFixed(2) + '%'
                        : '0%', // Default to '0%' if the value is missing
                    Formatted_Current_Percent: split.Current_Percentage__c !== null && split.Current_Percentage__c !== undefined
                        ? (split.Current_Percentage__c).toFixed(2) + '%'
                        : '0%' // Default to '0%' if the value is missing
                };
            });
            this.tableData = [...this.opportunitySplits]; // Populate tableData
            this.isDataLoaded = true;
        } else if (result.error) {
            this.error = result.error.body.message;
            console.error('Error loading Opportunity Splits:', result.error);
        }
    }

    // Lifecycle hook to load data when component initializes
    connectedCallback() {
        console.log('Record Id:', this.recordId);
        this.checkUserPermissions(); // Check permissions when the component loads
        this.checkRecordType();
        this.handleManualRefresh();

        // Fetch users on component initialization
        getUsers({ oppId: this.recordId })  // Pass the recordId to the Apex method
            .then((result) => {
                this.ownerOptions = result.map(user => ({
                    label: user.Name,
                    value: user.Id
                }));
            })
            .catch((error) => {
                console.error('Error fetching users:', error);
            });
    }

    checkRecordType() {
        isServicesRecordType({ opportunityId: this.recordId })
            .then(result => {
                this.isServicesRecordType = result;
            })
            .catch(error => {
                console.error('Error checking record type:', error);
            });
    }

           
    // Show toast notifications
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(event);
    }

    // Modal handlers
    handleNewSplit() {
        if (this.permissions.showNew) {
            this.isModalOpen = true;
            refreshApex(this.wiredOpportunitySplitsResult) // Refresh directly
                .then(() => {
                    this.isDataLoaded = true;
                    console.log('Data refreshed successfully');
                    // Proceed to handle any other modal logic if necessary
                })
                .catch(error => {
                    this.isDataLoaded = false;
                    console.error('Error refreshing data:', error);
                });
        } else {
            this.showToast('Access Denied', 'You do not have permission to create a new Opportunity Split.', 'error');
        }
    }

    closeModal() {
        this.handleManualRefresh();
        this.isUserPicklistVisible = false;
        this.isModalOpen = false;       
    }

    handleEditOpportunitySplits() {
        if (this.permissions.showEdit) {
            this.isEditModalOpen = true;
            refreshApex(this.wiredOpportunitySplitsResult) // Refresh directly
                .then(() => {
                    this.isDataLoaded = true;
                    console.log('Data refreshed successfully');
                    // Proceed to handle any other modal logic if necessary
                })
                .catch(error => {
                    this.isDataLoaded = false;
                    console.error('Error refreshing data:', error);
                });
        } else {
            this.showToast('Access Denied', 'You do not have permission to edit Opportunity Splits.', 'error');
        }
    }

    closeEditModal() {
        this.handleManualRefresh();
        this.isEditModalOpen = false;
        this.handleRefresh();
    }

    // Flow handlers
    handleSubmitForApproval() {
        console.log('handleSubmitForApproval triggered');
        console.log('Record ID:', this.recordId);

        if (!this.recordId) {
            this.showToast('Error', 'Opportunity ID is not available.', 'error');
            return;
        }

        this.inputVariables = [
            {
                name: 'OpportunityId',  // Variable name in flow
                type: 'String',  // Type of the variable (use String for text, SObject for record, etc.)
                value: this.recordId  // Pass the recordId dynamically
            }
        ];
        console.log('Flow Parameters before opening:', JSON.stringify(this.inputVariables));

        // Add a slight delay before opening the modal
        setTimeout(() => {
            this.isFlowOpen = true;
        }, 100);
    }

    handleFlowFinish(event) {
        console.log('Flow Status Changed:', event.detail.status);
        console.log('Output Variables:', event.detail.outputVariables);
    }

    

    closeFlowModal() {
        this.isFlowOpen = false;
        this.flowParams = null; 
    }

    handleFlowFinish(event) {
        if (event.detail.status === 'FINISHED') {
            this.showToast('Success', 'Change request submitted successfully!', 'success');
            this.closeFlowModal();
        } else if (event.detail.status === 'CANCELLED') {
            this.showToast('Cancelled', 'Change request was cancelled.', 'warning');
        }
    }

    // Check User Permissions for the current Opportunity
    checkUserPermissions() {
        checkUserPermissions({ opportunityId: this.recordId })
            .then(result => {
                this.permissions = result;
            })
            .catch(error => {
                console.error('Error fetching user permissions:', error);
            });
    }

    handleSaveEdit(event) {
        try {
            const updatedRows = event.detail.draftValues;
    
            if (!this.tableData || this.tableData.length === 0) {
                this.showToast('Error', 'No data available to validate.', 'error');
                return;
            }
    
            const allRows = [...this.tableData];
            updatedRows.forEach(draftRow => {
                const index = allRows.findIndex(row => row.Id === draftRow.Id);
                if (index !== -1) {
                    allRows[index] = { ...allRows[index], ...draftRow };
                }
            });
    
            const validationMessage = this.validateSplits(allRows);
            if (validationMessage) {
                this.showToast('Error', validationMessage, 'error');
                return;
            }
    
            updateOpportunitySplits({ splits: updatedRows })
                .then(() => {
                    this.showToast('Success', 'Opportunity Splits updated successfully!', 'success');
                    this.closeModal();
                    this.closeEditModal();
                    this.handleRefresh();
                    const datatable = this.template.querySelector('lightning-datatable');
                    if (datatable) {
                        datatable.draftValues = [];
                    }
                })
                .catch(error => {
                    this.showToast('Error', 'Error updating Opportunity Splits.', 'error');
                    console.error('Error updating Opportunity Splits:', error);
                });
        } catch (error) {
            console.error('Unexpected Error:', error);
            this.showToast('Error', 'An unexpected error occurred. Check console for details.', 'error');
        }
    }    

    validateSplits(updatedRows) {
        let totalSplitPercentage = 0;
        let totalCurrentPercentage = 0;
    
        for (let row of updatedRows) {
            const splitPercentage = parseFloat(row.Split_Percentage__c || 0);
            const currentPercentage = parseFloat(row.Current_Percentage__c || 0);
    
            if (isNaN(splitPercentage)) {
                return 'Split Percentage contains invalid values.';
            }
            totalSplitPercentage += splitPercentage;
    
            if (!this.isServicesRecordType) {
                if (isNaN(currentPercentage)) {
                    return 'Current Percentage contains invalid values.';
                }
                totalCurrentPercentage += currentPercentage;
            }
        }
    
        if (totalSplitPercentage !== 100) {
            return `The total sum of the Split Percent (%) values must equal 100%. Current total is ${totalSplitPercentage}%.`;
        }
    
        if (!this.isServicesRecordType && totalCurrentPercentage !== 0 && totalCurrentPercentage !== 100) {
            return `The total sum of the Current Percentage values must be either 0% or 100%. Current total is ${totalCurrentPercentage}%.`;
        }
    
        return null; // Validation passed
    }
    

    // Handle Add New Split button click
    handleAddSplit() {
        this.isUserPicklistVisible = true; // Show the picklist
        this.selectedUserId = ''; // Clear previous selection
    }

    // Handle user selection from picklist
    handleUserChange(event) {
        this.selectedUserId = event.target.value;
        this.showAddRow = true;
    }

   // Create new split after user selection
   createNewSplit() {
    console.log('createNewSplit: Start'); // Log entry into the method

        if (!this.selectedUserId) {
            console.log('createNewSplit: No user selected'); // Log if no user is selected
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Please select a user to create a new split.',
                    variant: 'error',
                })
            );
            return;
        }

        console.log('createNewSplit: Selected userId:', this.selectedUserId); // Log the selected userId

        // Call Apex method to create the new split
        createOpportunitySplit({
            opportunityId: this.recordId,
            ownerId: this.selectedUserId,
        })
        .then((newSplit) => {
            console.log('createNewSplit: New split created:', newSplit); // Log the new split record returned from Apex

            // Directly add the new split to tableData
            this.tableData = [...this.tableData, newSplit];

            // Log the updated tableData
            console.log('createNewSplit: Updated tableData:', JSON.stringify(this.tableData, null, 2));

            // Hide the user picklist
            this.isUserPicklistVisible = false; // Hide the picklist
            console.log('createNewSplit: Picklist hidden'); // Log that picklist visibility is hidden

        })
        .catch((error) => {
            console.error('Error creating new split:', error); // Log any errors from Apex
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Failed to create a new split. Please try again.',
                    variant: 'error',
                })
            );
        });
    }

    get splitCount() {
        return this.opportunitySplits ? this.opportunitySplits.length : 0;
    }

    handleManualRefresh() {
        this.refreshKey++; // Increment the refreshKey to force a refresh
    }

    handleRefresh() {
        refreshApex(this.wiredOpportunitySplitsResult)
            .then(() => {
                console.log('Data refreshed successfully');
            })
            .catch(error => {
                console.error('Error refreshing data:', error);
            });
    }

}