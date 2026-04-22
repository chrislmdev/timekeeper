import { LightningElement, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import { createRecord } from 'lightning/uiRecordApi';
import getProjectOptions from '@salesforce/apex/TimeEntryPortalController.getProjectOptions';

import TIME_ENTRY_OBJECT from '@salesforce/schema/Time_Entry__c';
import PROJECT_FIELD from '@salesforce/schema/Time_Entry__c.Project__c';
import WORK_DATE_FIELD from '@salesforce/schema/Time_Entry__c.Work_Date__c';
import HOURS_FIELD from '@salesforce/schema/Time_Entry__c.Hours__c';
import TASK_CATEGORY_FIELD from '@salesforce/schema/Time_Entry__c.Task_Category__c';
import JOB_ROLE_FIELD from '@salesforce/schema/Time_Entry__c.Job_Role__c';
import LABOR_POOL_FIELD from '@salesforce/schema/Time_Entry__c.Labor_Pool__c';
import TICKET_NUM_FIELD from '@salesforce/schema/Time_Entry__c.ServiceNow_Ticket_Number__c';
import TICKET_URL_FIELD from '@salesforce/schema/Time_Entry__c.ServiceNow_Ticket_URL__c';
import NOTES_FIELD from '@salesforce/schema/Time_Entry__c.Notes__c';

export default class TimeEntryPortal extends LightningElement {
    projectSearchTerm = '';
    projectId;
    workDate;
    hours;
    taskCategory;
    jobRole;
    laborPool;
    ticketNumber;
    ticketUrl;
    notes;
    submitting = false;

    objectInfo;

    @wire(getObjectInfo, { objectApiName: TIME_ENTRY_OBJECT })
    wiredObjectInfo({ data, error }) {
        if (data) {
            this.objectInfo = data;
        } else if (error) {
            this.objectInfo = undefined;
        }
    }

    get recordTypeId() {
        return this.objectInfo?.defaultRecordTypeId;
    }

    @wire(getPicklistValues, {
        recordTypeId: '$recordTypeId',
        fieldApiName: TASK_CATEGORY_FIELD
    })
    wiredTaskCategory;

    @wire(getPicklistValues, {
        recordTypeId: '$recordTypeId',
        fieldApiName: JOB_ROLE_FIELD
    })
    wiredJobRole;

    @wire(getPicklistValues, {
        recordTypeId: '$recordTypeId',
        fieldApiName: LABOR_POOL_FIELD
    })
    wiredLaborPool;

    @wire(getProjectOptions, { searchTerm: '$projectSearchTerm' })
    wiredProjects;

    get taskCategoryOptions() {
        return this.picklistToOptions(this.wiredTaskCategory?.data?.values);
    }

    get jobRoleOptions() {
        return this.picklistToOptions(this.wiredJobRole?.data?.values);
    }

    get laborPoolOptions() {
        return this.picklistToOptions(this.wiredLaborPool?.data?.values);
    }

    get projectOptions() {
        const rows = this.wiredProjects?.data;
        if (!rows || rows.length === 0) {
            return [];
        }
        return rows.map((p) => ({
            label: this.formatProjectLabel(p),
            value: p.id
        }));
    }

    picklistToOptions(values) {
        if (!values) {
            return [];
        }
        return values.map((v) => ({ label: v.label, value: v.value }));
    }

    formatProjectLabel(p) {
        const acc = p.accountName ? ` — ${p.accountName}` : '';
        return `${p.name}${acc}`;
    }

    handleProjectSearch(event) {
        this.projectSearchTerm = event.target.value;
    }

    handleProjectChange(event) {
        this.projectId = event.detail.value;
    }

    handleWorkDate(event) {
        this.workDate = event.target.value;
    }

    handleHours(event) {
        this.hours = event.target.value;
    }

    handleTaskCategory(event) {
        this.taskCategory = event.detail.value;
    }

    handleJobRole(event) {
        this.jobRole = event.detail.value;
    }

    handleLaborPool(event) {
        this.laborPool = event.detail.value;
    }

    handleTicketNumber(event) {
        this.ticketNumber = event.target.value;
    }

    handleTicketUrl(event) {
        this.ticketUrl = event.target.value;
    }

    handleNotes(event) {
        this.notes = event.target.value;
    }

    handleReset() {
        this.projectSearchTerm = '';
        this.projectId = undefined;
        this.workDate = undefined;
        this.hours = undefined;
        this.taskCategory = undefined;
        this.jobRole = undefined;
        this.laborPool = undefined;
        this.ticketNumber = undefined;
        this.ticketUrl = undefined;
        this.notes = undefined;
    }

    async handleSubmit() {
        if (this.submitting) {
            return;
        }
        this.submitting = true;
        try {
            const fields = {};
            fields[PROJECT_FIELD.fieldApiName] = this.projectId;
            fields[WORK_DATE_FIELD.fieldApiName] = this.workDate;
            fields[HOURS_FIELD.fieldApiName] = this.parseHours(this.hours);
            fields[TASK_CATEGORY_FIELD.fieldApiName] = this.taskCategory;
            fields[JOB_ROLE_FIELD.fieldApiName] = this.jobRole;
            fields[LABOR_POOL_FIELD.fieldApiName] = this.laborPool;
            if (this.ticketNumber) {
                fields[TICKET_NUM_FIELD.fieldApiName] = this.ticketNumber;
            }
            if (this.ticketUrl) {
                fields[TICKET_URL_FIELD.fieldApiName] = this.ticketUrl;
            }
            if (this.notes) {
                fields[NOTES_FIELD.fieldApiName] = this.notes;
            }

            const recordInput = {
                apiName: TIME_ENTRY_OBJECT.objectApiName,
                fields
            };
            const result = await createRecord(recordInput);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Time saved',
                    message: `Entry ${result.id} was created.`,
                    variant: 'success'
                })
            );
            this.handleReset();
        } catch (e) {
            const message = this.reduceErrors(e);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Could not save',
                    message,
                    variant: 'error',
                    mode: 'sticky'
                })
            );
        } finally {
            this.submitting = false;
        }
    }

    parseHours(value) {
        if (value === undefined || value === null || value === '') {
            return undefined;
        }
        const n = Number(value);
        return Number.isFinite(n) ? n : undefined;
    }

    reduceErrors(error) {
        if (!error) {
            return 'Unknown error';
        }
        if (Array.isArray(error.body)) {
            return error.body.map((e) => e.message).join(', ');
        }
        if (error.body?.output?.errors?.length) {
            return error.body.output.errors.map((e) => e.message).join(', ');
        }
        if (error.body?.fieldErrors) {
            const parts = Object.keys(error.body.fieldErrors).flatMap((f) =>
                error.body.fieldErrors[f].map((fe) => fe.message)
            );
            if (parts.length) {
                return parts.join(', ');
            }
        }
        if (typeof error.body?.message === 'string') {
            return error.body.message;
        }
        if (typeof error.message === 'string') {
            return error.message;
        }
        return 'Unknown error';
    }
}
