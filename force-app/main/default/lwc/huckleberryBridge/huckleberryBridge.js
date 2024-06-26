/**
 * Huckleberry Button Lightning Web Component.
 * 
 * This component handles the functionality to create
 * P&C Quote Data Record and send the information to Huckleberry.
 * Upon a successful response, updates the Opportunity with Quote URL.
 * 
 * @changes
 * 12-22-2023  Vinay  Created.
 * 
 */
import { LightningElement, wire, api } from 'lwc';
import { createRecord, updateRecord } from 'lightning/uiRecordApi';
import PCQuoteDataProbability from '@salesforce/label/c.PCQuoteDataProbability';
import PCQuoteDataSalesOrg from '@salesforce/label/c.PCQuoteDataSalesOrg';
import PCQuoteDataRecordTypeId from '@salesforce/label/c.PCQuoteDataRecordTypeId';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import PC_QUOTE_OBJECT from '@salesforce/schema/PC_Quote_Data__c';
import SUBMITTED_BY from '@salesforce/schema/PC_Quote_Data__c.Submitted_By__c';
import PROSPECT_CLIENT from '@salesforce/schema/PC_Quote_Data__c.Prospect_Client__c';
import OPPORTUNITY from '@salesforce/schema/PC_Quote_Data__c.Opportunity__c';
import OPPORTUNITY_TYPE from '@salesforce/schema/PC_Quote_Data__c.Opportunity_Type__c';
import EMAPLOYEES_PAID from '@salesforce/schema/PC_Quote_Data__c.Employees_Paid_Per_Payroll__c';
import PROSPECT_CLIENT_NAME from '@salesforce/schema/PC_Quote_Data__c.Prospect_Client_Name__c';
import RENEWAL_DATE from '@salesforce/schema/PC_Quote_Data__c.Renewal_Date__c';
import ORGANIZATION_TYPE from '@salesforce/schema/PC_Quote_Data__c.Organization_Type__c';
import FEDERAL_ID_NUMBER from '@salesforce/schema/PC_Quote_Data__c.Federal_Id_Number__c';
import STREET from '@salesforce/schema/PC_Quote_Data__c.Prospect_Client_Street__c';
import CITY from '@salesforce/schema/PC_Quote_Data__c.Prospect_Client_City__c';
import STATE from '@salesforce/schema/PC_Quote_Data__c.Prospect_Client_State__c';
import POSTAL_CODE from '@salesforce/schema/PC_Quote_Data__c.Prospect_Client_Postal_Code__c';
import ADDRESS from '@salesforce/schema/PC_Quote_Data__c.Prospect_Client_Address_Text__c';
import CONTACT_FIRST_NAME from '@salesforce/schema/PC_Quote_Data__c.Contact_First_Name__c';
import CONTACT_LAST_NAME from '@salesforce/schema/PC_Quote_Data__c.Contact_Last_Name__c';
import CONTACT_PHONE from '@salesforce/schema/PC_Quote_Data__c.Contact_Phone_Number__c';
import CONTACT_EMAIL from '@salesforce/schema/PC_Quote_Data__c.Contact_Email_Address__c';
import P_C_QUOTED_TOOL from '@salesforce/schema/PC_Quote_Data__c.P_C_Quoted_Tool__c';
import ONBORADING_FORMAT from '@salesforce/schema/PC_Quote_Data__c.Onboarding_Format__c';
import RUNNING_USER_ID from '@salesforce/user/Id';
import { gql, graphql } from 'lightning/uiGraphQLApi';
import { RefreshEvent } from 'lightning/refresh';
import SendDataToHuckleberry from '@salesforce/apex/HuckleberryBridgeController.SendDataToHuckleberry';
import deletePCQuoteRecord from '@salesforce/apex/HuckleberryBridgeController.deletePCQuoteRecord'; 
import OPPORTUNITY_PC_QUOTE from '@salesforce/schema/Opportunity.Tarmika_Quote__c';
import OPPORTUNITY_ID from '@salesforce/schema/Opportunity.Id';
import quoteDataPermission from '@salesforce/customPermission/P_C_Quote_Data_Access_Huckleberry';

export default class HuckleberryBridge extends LightningElement {
    @api recordId; //usually component is made aware of the record id when it is placed on the record detail page.
    opportunity; //Object to store Opportunity related data.
    user; //Object to store User related data.
    opportunityContactRoles;
    error;
    userId = RUNNING_USER_ID;
    successIcon = {
        name : 'action:approval',
        size : 'xx-small',
        title : 'Valid',
    };
    warningIcon = {
        name : 'action:close',
        size : 'xx-small',
        title : 'Items Needing Attention',
    };
    isOpportunityAtDiscoveryStage;
    isCorrectRecordType;
    hasOpptyQuote;
    isPCSalesUser;
    isPCQuoteCreationSuccessful;
    showSpinner;
    pcQuoteData;
    opportunityUpdated;
    isRendered;

    /**
     * Wire method to run the queries and perform necessary checks.
     * 
     * This method will run the graphql queries and get the required information, 
     * performs necessary checks and proceeds further to Create PC Quote Data record based
     * on the result.
     * 
     */
    @wire(graphql, {
        query: "$opportunityAndUserQuery",
        variables: "$queryData",
    }) graphqlQueryResult({ data, error }) {
        if (data && !this.isRendered) {
            this.opportunity = data.uiapi.query.Opportunity.edges.map((edge) => edge.node)[0];
            this.opportunityContactRoles = this.opportunity.OpportunityContactRoles.edges.map((edge) => edge.node)[0];
            this.user = data.uiapi.query.User.edges.map((edge) => edge.node)[0];
            this.isOpportunityAtDiscoveryStage = Number(this.opportunity.Probability.value) >= Number(PCQuoteDataProbability);
            this.isCorrectRecordType = this.opportunity.RecordTypeId.value.substring(0, 15) === PCQuoteDataRecordTypeId;
            this.hasOpptyQuote = this.opportunity.Tarmika_Quote__c.value ? true : false;
            console.log(this.hasOpptyQuote, this.opportunity.Tarmika_Quote__c.value);
            this.isPCSalesUser = (PCQuoteDataSalesOrg.split(',')).includes(this.user.Sales_Org__c.value);
            if(this.isPCSalesUser && this.isOpportunityAtDiscoveryStage && this.isCorrectRecordType && !this.hasOpptyQuote && this.hasPermission) {
                this.createPCQuoteRecord();
            }
            this.isRendered = true; //check to determine if the method already ran.
        } else if (error) {
            this.dispatchToastMessage('error', error.body.message);
        }
    }

    /**
     * Get method to return the queries.
     * 
     * This method will run the queries with all the required Objects
     * and fields.
     * 
     * @returns {gql} graphql module from Salesforce.
     */
    get opportunityAndUserQuery() {
        return gql`
          query getOpportunity ($recordId: ID!, $userId: ID!) {
            uiapi {
                query {
                    Opportunity (
                        where: { Id: { eq: $recordId }}
                    ) {
                        edges {
                            node {
                                Id
                                Name { value }
                                Probability { value }
                                RecordTypeId { value }
                                Tarmika_Quote__c { value }
                                Employees_Paid_Per_Payroll__c { value }
                                Renewal_Date__c { value }
                                OpportunityType__c { value }
                                CloseDate { value }
                                OwnerId { value }
                                Onboarding_Format__c { value }
                                Account {
                                    Id
                                    Name { value }
                                    Organization_Type__c { value }
                                    Federal_ID_Number__c { value }
                                    ShippingStreet { value }
                                    ShippingCity { value }
                                    ShippingState { value }
                                    ShippingPostalCode { value }
                                }
                                OpportunityContactRoles (
                                    first: 1
                                    where: { IsPrimary: { eq: true}}
                                ) {
                                    edges {
                                        node {
                                            Id
                                            Contact {
                                                Id
                                                FirstName { value }
                                                LastName { value }
                                                Phone { value }
                                                Email { value }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    User (
                        where: { Id: { eq: $userId } }
                    ) {
                        edges {
                            node {
                                Id
                                Name { value }
                                Email { value }
                                Sales_Org__c { value }
                            }
                        }
                    }
                }
            }
        }`
    }

    /**
     * Get method to return queryData.
     * 
     * Sets the return object with recordId and userId.
     * 
     * @returns {object} Query paramters Object.
     */
    get queryData() {
        return {
          recordId: this.recordId,
          userId: this.userId
        };
    }

    /**
     * Method to create P&C Quote Data Record.
     * 
     * Sets the field values for P&C Quote Data to create the
     * record in Salesforce. Then calls "SendDataToHuckleberry"
     * method to send the record to Huckleberry. If there is a
     * successful response it further updates the Opportunity.
     */
    createPCQuoteRecord() {
        const fields = {};
        fields[SUBMITTED_BY.fieldApiName] = this.user.Email.value;
        fields[OPPORTUNITY.fieldApiName] = this.recordId;
        fields[PROSPECT_CLIENT.fieldApiName] = this.opportunity.Account.Id;
        fields[OPPORTUNITY_TYPE.fieldApiName] = this.opportunity.OpportunityType__c.value;
        fields[EMAPLOYEES_PAID.fieldApiName] = this.opportunity.Employees_Paid_Per_Payroll__c.value;
        fields[RENEWAL_DATE.fieldApiName] = this.opportunity.Renewal_Date__c.value;
        fields[PROSPECT_CLIENT_NAME.fieldApiName] = this.opportunity.Account.Name.value;
        fields[ORGANIZATION_TYPE.fieldApiName] = this.opportunity.Account.Organization_Type__c.value;
        fields[FEDERAL_ID_NUMBER.fieldApiName] = this.opportunity.Account.Federal_ID_Number__c.value;
        fields[STREET.fieldApiName] = this.opportunity.Account.ShippingStreet.value;
        fields[CITY.fieldApiName] = this.opportunity.Account.ShippingCity.value;
        fields[STATE.fieldApiName] = this.opportunity.Account.ShippingState.value;
        fields[POSTAL_CODE.fieldApiName] = this.opportunity.Account.ShippingPostalCode.value;
        fields[ONBORADING_FORMAT.fieldApiName] = this.opportunity.Onboarding_Format__c.value;
        fields[P_C_QUOTED_TOOL.fieldApiName] = 'Huckleberry';
        if(this.opportunityContactRoles.Contact) {
            fields[CONTACT_FIRST_NAME.fieldApiName] = this.opportunityContactRoles.Contact.FirstName.value;
            fields[CONTACT_LAST_NAME.fieldApiName] = this.opportunityContactRoles.Contact.LastName.value;
            fields[CONTACT_PHONE.fieldApiName] = this.opportunityContactRoles.Contact.Phone.value;
            fields[CONTACT_EMAIL.fieldApiName] = this.opportunityContactRoles.Contact.Email.value;
        }
        if(!this.opportunity.Account.ShippingStreet.value || !this.opportunity.Account.ShippingCity.value ||
            !this.opportunity.Account.ShippingState.value || !this.opportunity.Account.ShippingPostalCode.value) {
            fields[ADDRESS.fieldApiName] = '';
        } else {
            fields[ADDRESS.fieldApiName] = `${this.opportunity.Account.ShippingStreet.value}, ${this.opportunity.Account.ShippingCity.value}, 
            ${this.opportunity.Account.ShippingState.value} ${this.opportunity.Account.ShippingPostalCode.value}`;
        }
        const recordInput = {
            apiName: PC_QUOTE_OBJECT.objectApiName,
            fields: fields
        };
        this.showSpinner = true;
        createRecord(recordInput)
            .then((record) => {
                //If PC Quote Data is created.
                if(record) {
                    this.isPCQuoteCreationSuccessful = true;
                    this.showSpinner = false;
                    this.pcQuoteData = record;
                    let pcQuoteDataToSend = {
                        Id : record.id,
                        //Format date to YYYY-MM-DD format.
                        runEffectiveDate : this.opportunity.CloseDate.value ?
                        new Date(this.opportunity.CloseDate.value).toISOString().split('T')[0] :
                        ''
                    };
                    for (const [apiName, fieldValue] of Object.entries(record.fields)) {
                        pcQuoteDataToSend[apiName] = fieldValue.value ? fieldValue.value : '';
                    }
                    SendDataToHuckleberry({pcQuoteDataString : JSON.stringify(pcQuoteDataToSend)})
                    .then(response => {
                        //If Huck sends back URL for quote.
                        if(response.statusCode === '200') {
                            this.updateOpportunity(response.message);
                        } else {
                            this.dispatchToastMessage('error', response.message);
                            //Delete the PC Quote Data record that is created, as it cannot be used by Huck.
                            deletePCQuoteRecord({recordId : record.id});
                        }
                    })
                    .catch(error=> {
                        console.log('Error when sending data to Huckleberry==>', JSON.stringify(error));
                        this.dispatchToastMessage('error', error.status.message);
                    })
                }
        })
        .catch(error=> {
            this.showSpinner = false;
            console.log('Error creating PC Quote record==>', JSON.stringify(error));
            this.dispatchToastMessage('error', error.status.message);
        });
    }

    /**
     * Method to update Opportunity.
     * 
     * This method will update the Opportunity with the URL
     * sent from Huckleberry.
     * 
     * @param {String} huckURL URL sent by Huckleberry.
     */
    updateOpportunity(huckURL) {
        this.showSpinner = true;
        const fields = {};
        fields[OPPORTUNITY_ID.fieldApiName] = this.recordId;
        fields[OPPORTUNITY_PC_QUOTE.fieldApiName] = huckURL;
        const recordInput = { fields };
        updateRecord(recordInput)
        .then(()=> {
            this.dispatchEvent(new RefreshEvent());
            this.opportunityUpdated = true;
            this.dispatchToastMessage('success', 'PC Quote field updated with Huckleberry Application URL.');
            this.showSpinner = false;
        })
        .catch((error) => {
            this.opportunityUpdated = false;
            this.dispatchToastMessage('error', error.body.message);
            this.showSpinner = false;
        });
    }

    /**
     * Get method to determine if user has permission.
     * 
     * @returns {boolean} true/false based on the permission assignment.
     */
    get hasPermission() {
        return quoteDataPermission;
    }

    /**
     * Method to dispatch Toast message.
     * 
     * This method will display a Toast message
     * to the user based on the variant.
     * 
     * @param {String} variant variant for message.
     * @param {String} message message to be displayed.
     */
    dispatchToastMessage(variant, message) {
        this.dispatchEvent(
            new ShowToastEvent({
              title: variant === 'error' ? 'Error Occured' : 'Success!!',
              message: message,
              variant: variant,
              mode: 'sticky'
            }),
        );
    }
}