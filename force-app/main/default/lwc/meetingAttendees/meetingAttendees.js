import { LightningElement, api, wire, track } from 'lwc';
import getInternalAttendees from '@salesforce/apex/InternalAttendeesController.getInternalAttendees';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import INTERNAL_ATTENDEES_OBJECT from '@salesforce/schema/Internal_Attendees__c';
import { refreshApex } from '@salesforce/apex';
import './meetingAttendees.css'; // Import the CSS file
import deleteInternalAttendee from '@salesforce/apex/InternalAttendeesController.deleteInternalAttendee';


const columns = [
    { label: 'Attendee', fieldName: 'AttendeeName', type: 'text',
        cellAttributes: { iconName: 'utility:user' } }, 
    { label: 'Attendee Role', fieldName: 'Sales_Role__c', type: 'text' }, 
];
export default class InternalAttendees extends LightningElement {
    @api recordId;
    @track internalAttendees = [];
    @track error;
    @track isModalOpen = false;
    columns = columns;

    wiredAttendeesResult;

    @wire(getInternalAttendees, { eventId: '$recordId' })
    wiredAttendees(result) {
        this.wiredAttendeesResult = result;
        if (result.data) {
            this.internalAttendees = result.data.map(record => ({
                ...record,
                AttendeeName: record.Attendee__r ? record.Attendee__r.Name : 'N/A'
            }));
            this.error = undefined;
        } else if (result.error) {
            this.internalAttendees = [];
            this.error = result.error;
        }
    }

    // Handle row selection
    handleRowSelection(event) {
        const selectedRows = event.detail.selectedRows;
        // Only allow one row to be selected for deletion
        this.selectedAttendeeId = selectedRows.length > 0 ? selectedRows[0].Id : null;
    }

     // Handle row selection
     handleRowSelection(event) {
        const selectedRows = event.detail.selectedRows;
        if (selectedRows.length > 0) {
            this.selectedAttendeeId = selectedRows[0].Id;
            console.log('Selected Attendee ID: ', this.selectedAttendeeId); // Debug log
        } else {
            this.selectedAttendeeId = null;
            console.log('No row selected'); // Debug log
        }
    }

    // Delete selected attendee
    handleDeleteSelectedAttendee() {
        if (this.selectedAttendeeId) {
            console.log('Attempting to delete Attendee ID: ', this.selectedAttendeeId); // Debug log

            deleteInternalAttendee({ attendeeId: this.selectedAttendeeId })
                .then(() => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'Attendee deleted',
                            variant: 'success'
                        })
                    );
                    // Refresh the list
                    return refreshApex(this.wiredAttendeesResult);
                })
                .catch(error => {
                    console.error('Error deleting attendee: ', error); // Debug log
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error deleting record',
                            message: error.body.message,
                            variant: 'error'
                        })
                    );
                });
        } else {
            console.log('No Attendee selected for deletion'); // Debug log
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Please select an attendee to delete',
                    variant: 'error'
                })
            );
        }
    }

    handleNewAttendee() {
        this.isModalOpen = true;
    }

    closeModal() {
        this.isModalOpen = false;
    }

    handleSubmit(event) {
        event.preventDefault(); // stop the form from submitting
        const fields = event.detail.fields;
        fields.Event_Id__c = this.recordId;
        //fields.Event_Name__c = 'Example Event Name'; // Replace with dynamic event name if available

        this.template.querySelector('lightning-record-edit-form').submit(fields);
    }

    handleSuccess(event) {
        const evt = new ShowToastEvent({
            title: "Attendee Added to Meeting",
            message: "Success Message: " + "Attendee has been Successfully Added",
            variant: "success"
        });
        this.dispatchEvent(evt);

        // Close the modal
        this.closeModal();

        // Refresh the list
        refreshApex(this.wiredAttendeesResult)
        .then(() => {
            console.log('Data refreshed');
        })
        .catch(error => {
            console.error('Error refreshing data', error);
        });
    }
}