/*
 * This class processes bank leads that come in through the WebBankLeadEmailHandler.  
 *
 * History
 * --------
 * 06/26/2014   Carrie Marciano created
 * 08/05/2015   Jacob Hinds  Added in products field, HNBF and Payroll products
   04/08/2020   Dan Carmen   Increment API Version
   09/20/2023   Dan Carmen   Remove Dupeblocker code.

 */
 
public with sharing class WebSPLeadHelper {
 public class SPLead {
        public string surePayrollLeadID;
        public string firstName;
        public string lastName;
        public string fullName;
        public string contactFullName;
        public string company;
        public string email;
        public string phone;
        public string mobile;
        public string street;
        public string city;
        public string state;
        public string zip;
        public integer NumOfEmployees;
        public string product;
        public ID userId;
    } // Update with the correct xml tags

   public static void processSPlead(List<SPLead> SPLList) {
        system.debug('*** CLM *** enter processSPlead');
        string productDiv;
 		Schema.RecordTypeInfo leadRT;
        map<Messaging.SingleEmailMessage,lead> leadsToInsert = new map<Messaging.SingleEmailMessage,lead>(); // Map used to collect the leads to be updated as they are processed.
        for (SPlead SPL: SPLList){
            Contact spEmp = new Contact();
            spEmp = searchContact(SPL.contactFullName);
            SPL.fullName = SPL.firstName + ' ' + SPL.lastName;
            system.debug('*** CLM *** spEmp '+ spEmp + ' spEmpID ' + spEmp.Id+' product '+SPL.product);
            if(SPL.product == 'Payroll'){
            	if(SPL.NumOfEmployees!=null && SPL.NumOfEmployees > 50){
            		productDiv = 'MMS';
            		leadRT= RecordTypeHelper.getRecordType(Label.RT_MMS_Lead, 'Lead');
            	}
            	else{
            		productDiv = 'Core';
            		leadRT= RecordTypeHelper.getRecordType(Label.RT_Core_Lead, 'Lead');
            	}
            }
            else if(SPL.product == 'HNBF'){
            	productDiv = 'HNBF';
            	leadRT= RecordTypeHelper.getRecordType(Label.RT_HNBF_Lead, 'Lead');
            }
            //default to HNBF if there is no product
            else
            {
            	productDiv = 'HNBF';
            	leadRT= RecordTypeHelper.getRecordType(Label.RT_HNBF_Lead, 'Lead');
            }
            System.debug('processSPlead productDiv='+productDiv);
            lead l = new lead(RecordTypeId = leadRT.getRecordTypeId()
                                    , Duplicate_OK__c = TRUE
                                    , LastName =  SPL.lastName
                                    , FirstName =  SPL.firstName
                                    , Company =  SPL.company
                                    , Email = SPL.email
                                    , Phone =  SPL.phone
                                    , MobilePhone = SPL.mobile
                                    , Street =  SPL.street
                                    , City =  SPL.city
                                    , State =  SPL.state
                                    , PostalCode =  SPL.zip                                 
                                    , NumberOfEmployees = SPL.NumOfEmployees
                                    , LeadSource = Label.LeadSource_Internal_SurePayroll
                                    , Product_Division__c = productDiv
                                    , Products__c = productDiv
                                    , Referring_Employee__c = spEmp.Id
                                    , Date_Lead_Submitted__c = system.today()
                                    , SurePayroll_ID__c = SPL.surePayrollLeadID
                                    );
            system.debug('*** CLM *** before determine ownership code');                        
            //Determine Ownership Section
            if(l.OwnerId == NULL){//If All Else fails, use Zip Assignment
                l.UseZipAssignmentRules__c = TRUE;
                l.Hold_Out__c = FALSE;
                l.Hold_Out_Expiration__c = NULL;
            }//End of Determine Ownership Section
            system.debug('*** CLM *** before add lead to leadsToInsert'); 
            leadsToInsert.put(createMail(SPL,l,spEmp),l);     
            system.debug('*** CLM *** after add lead to leadsToInsert');             
        }
        system.debug('*** CLM *** after for loop building leadsToInsert');
        //Insert Leads, Check for Duplicates and Update leads, and Send EMail back to Submitter with SurePayroll Lead ID  
        if(!leadsToInsert.isEmpty()){
            system.debug('*** CLM *** leadsToInsert is not empty');
            list<Messaging.SingleEmailMessage> rMails = new list<Messaging.SingleEmailMessage>();
            for(Messaging.SingleEmailMessage rMail : leadsToInsert.keySet()){
                string firstName = leadsToInsert.get(rMail).firstName;
                string lastName = leadsToInsert.get(rMail).LastName;
                string companyName =  leadsToInsert.get(rMail).Company;
                string surePayrollID = leadsToInsert.get(rMail).SurePayroll_ID__c;
                string zipCode  = leadsToInsert.get(rMail).PostalCode;
                string body = '';
                if (surePayrollID == null || surePayrollID == '' || lastName== null || lastName == '' || zipCode == null || zipCode == '' || companyName == null || companyName == ''){
                    system.debug('*** CLM *** no surePayrollID');
                    rMail.setSubject ('Paychex Referral - Not Accepted - missing required information');
                    body = '<body>Thank you for referring ' + leadsToInsert.get(rMail).firstName + ' ' + leadsToInsert.get(rMail).LastName;
                    body += ' (' + leadsToInsert.get(rMail).Company + ') to Paychex.<br/><br/>The referral is missing required information (SurePayroll Id, Company Name, LastName, Zip Code) therefore we cannot accept it.  Please update and resend with all required information.<br/>';
                    body += '<br/><br/>Thank You,<br/>Paychex</body>';
                    //remove the lead without SurePayroll ID from leadsToInsert
                    leadsToInsert.remove(rMail);
                    rMail.setHTMLBody(body);
                    rMails.add(rMail);     
                }            
            }
            if(!rMails.isEmpty()){
                Messaging.sendEmail(rMails);
                system.debug('*** CLM *** sent SurePayroll Rejection Email');
            }
            Try{
                insert leadsToInsert.values();
            }
            catch(Exception ex){
                Throw new WebSPLeadEmailHandler.SPEmailException('Unable to Insert Lead ' + ex);    
            }
            list<Messaging.SingleEmailMessage> mails = new list<Messaging.SingleEmailMessage>();
            for(Messaging.SingleEmailMessage mail : leadsToInsert.keySet()){
                string firstName = leadsToInsert.get(mail).firstName;
                string lastName = leadsToInsert.get(mail).LastName;
                string companyName =  leadsToInsert.get(mail).Company;
                string body = '';
                list<StaticResource> resourceList = [select body from StaticResource where name = 'SurePayrollRepEmail' Limit 1];
                if (!resourceList.isEmpty()){
                    body = resourceList[0].body.toString();
                    body = body.replaceFirst('JGSLeadName', (firstName == Null ? '' : firstName + ' ') + (lastName == Null ? '' : lastName + ' ') + (companyName == Null ? '' : '(' +companyName + ')'));
                    body = body.replaceFirst('JGSSurePayrollID',[select SurePayroll_ID__c from lead where id = :leadsToInsert.get(mail).id limit 1].SurePayroll_ID__c);
                }
                else {
                    body = '<body>Thank you for referring ' + leadsToInsert.get(mail).firstName + ' ' + leadsToInsert.get(mail).LastName;
                    body += ' (' + leadsToInsert.get(mail).Company + ') to Paychex.<br/><br/>Please keep the following reference number for your records:<br/>';
                    body += [select SurePayroll_ID__c from lead where id = :leadsToInsert.get(mail).id limit 1].SurePayroll_ID__c;
                    body += '<br/><br/>Thank You,<br/>Paychex</body>';
                }
                mail.setHTMLBody(body);
                mails.add(mail);
            }
            list<lead> leadsToUpdate = leadDuplicateCheck(leadsToInsert.values());
            if (!leadsToUpdate.isEmpty()){
                update leadsToUpdate;
                system.debug('*** CLM *** leadsToUpdate not empty after dupCheck');
            }
            if(!mails.isEmpty()){
                Messaging.sendEmail(mails);
                system.debug('*** CLM *** sent SurePayroll Confirmation Email');
            }
        } 
       
    } // processSPLead
    
    //search the contacts associated with Paychex Inc SA for SurePayroll rep submitting lead
    private static Contact searchContact(String contactFullName) {
        system.debug('*** CLM *** enter searchContact, contactFullName: ' + contactFullName);       
        Contact foundContact = new Contact();
        list<Contact> searchContactsResults = [Select Id, Email, Name, Prefered_Name__c, LastName, Title from Contact 
                         WHERE Title like '%SurePayroll%' and HR_Person_Id__c != null ];
        
        for (Contact searchContact : searchContactsResults){  
            system.debug('*** CLM *** searchContact.Name: ' + searchContact.Name + ' and contactFullName: ' + contactFullName);         
            if (searchContact.Name == contactFullName)
            {   foundContact = searchContact;
                system.debug('*** CLM *** foundContact based on Full Name: ' + foundContact);                 
                break;
            } 
            else if(searchContact.Prefered_Name__c + ' ' + searchContact.LastName == contactFullName){
            	foundContact = searchContact;
                system.debug('*** CLM *** foundContact based on Prefered Name: ' + foundContact);                 
                break;
            }
        } // for searchContactsResults
        system.debug('*** CLM *** foundContact: ' + foundContact);           
        return foundContact;
   } // searchContact
    
    // Create Basic Email - Used mostly to store the To address so that the email processing can be completed outside of the main for loop.
    private static Messaging.SingleEmailMessage createMail(webSPLeadHelper.SPLead SPL, lead l, contact spEmp){
        Messaging.Singleemailmessage mail = new Messaging.Singleemailmessage();
        if(spEmp.Email != NULL && spEmp.Email != ''){
            mail.setToAddresses (new String[]{spEmp.Email});
            mail.setSubject ('Paychex Referral');
            //mail.setInReplyTo('jpellett@paychex.com');
            SurePayroll_Email__c spEmail = SurePayroll_Email__c.getOrgDefaults();
            system.debug('*** CLM *** spEmail.Org_Wide_Email__c: ' + spEmail.Org_Wide_Email__c);
            if (spEmail.Org_Wide_Email__c != NULL && spEmail.Org_Wide_Email__c != ''){
                mail.setOrgWideEmailAddressId(spEmail.Org_Wide_Email__c);
            }    
        }
        else{
            mail.setToAddresses (new String[]{'cmarciano@paychex.com'});
            mail.setSubject ('No email specified for SurePayroll referral');
        }
        system.debug('*** CLM *** mail: ' + mail);
        return mail;
    }
    
    private static list<lead> leadDuplicateCheck(list<lead> leadsToCheck){
        list<lead> leadsToUpdate = new list<lead>();
        list<lead> leadsToCheckAcct = new list<lead>();
        Schema.RecordTypeInfo leadHRSRT = RecordTypeHelper.getRecordType('HRS Lead Record Type', 'Lead');
        DuplicateHelper.DupeResult[] results = DuplicateHelper.findDuplicates(leadsToCheck); 
        for (Integer cnt=0; cnt<leadsToCheck.size(); cnt++) {
           DuplicateHelper.DupeResult result = results[cnt];
           Lead ld = leadsToCheck[cnt];
           if (result.hasResults) {
              if (!result.acctIds.isEmpty()) {
                 ld.Status = 'Already Contacted/Duplicate';
                 ld.Original_Lead_Detail__c += ', Prospect-Client Id: ' + result.acctIds[0];
                 ld.Exception_Reason__c = 'Contact and P-C Already Exists in Salesforce';
                 ld.RecordTypeId = leadHRSRT.getRecordTypeId();
                 leadsToUpdate.add(ld);
             } else if (!result.leadIds.isEmpty()) {
                 ld.Status = 'Already Contacted/Duplicate';
                 ld.RecordTypeId = leadHRSRT.getRecordTypeId();
                 ld.Original_Lead_Detail__c += ', Pre-Existing Lead Id: ' + result.leadIds[0];
                 ld.Exception_Reason__c = 'Lead Already Exists in Salesforce';
                 leadsToUpdate.add(ld);
              }
                   
           } // if (!results.isEmpty
        } // for (Integer cnt=0

        return leadsToUpdate;
    }// leadDuplicateCheck     
}