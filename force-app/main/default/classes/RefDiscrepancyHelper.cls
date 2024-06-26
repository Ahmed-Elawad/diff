/* 
 * Shared logic when handling discrepancies
 
 *
 * History
 * -------
 * 04/18/2013 Dan Carmen   Created
   09/23/2013 Dan Carmen   Added ASO information
   09/06/2014 Frank Lurz   Added Handbooks Orders information
   02/25/2016 Frank Lurz   Added Implementation Project Manager to list of field names translated to a label
   02/28/2018 Frank Lurz   Added PEO+ HRC to list of field names translated to a label
   10/29/2018 Carrie Marciano   Added HR Specialist and PEO Sales Analyst to the field name to label translation
   1/29/2018  Sunnish           Added Onboarding HRG and Responsible HRG to the field name to label translation
   10/28/2019 Brandon Vidro Case 34342730 - Added more fields to field name to label translation
   05/28/2024 Susmitha Somavarapu Commentedout "if no other user selected, send email to the runningUser" code for APR0166500.Business User don't want to send email to "TO"(Running user)email address.

 *
 */
public abstract with sharing class RefDiscrepancyHelper {
  
   /** Is there a reference object? */
   public Boolean hasRef{
      get {return (refPEO != null || refHre != null || refASO != null || refHbkOdr != null);}
   } // hasRef
   
   public Reference_PEO__c refPEO{get;set;}
   
   public Reference_HRE_CHB_Onboarding__c refHre{get;set;}
   
   public Reference_ASO__c refASO{get;set;}

   public Reference_HRE_CHB_Orders__c refHbkOdr{get;set;}

  /** Any common setup that needs to be done. */
  public Boolean setup() {
      setRunningUser();
      
      // the Id of the reference object should be passed in here. If not, cannot proceed
      Boolean allOkay = setRefId();

      // select the Reference object and discrepancies
      allOkay = (allOkay && getReference(refId));
      if (allOkay) {
         // if select is successful, set the users
         setupUsers();
         setAddlNames();
         
         emailNote = '';
      } // if
      return allOkay;
  } // setup
  
  /** The account attached to the reference object. */
  public Account acct;
  
   public abstract Boolean setupUsers();
   
   public abstract Boolean getReference(Id refId);
  
   /** Any additional notes that can be included on the email. */
   public String emailNote {get;set;}

   /** The name of the object to display to users. */
   public String objectName=null;
   
   /** The user using the form. */
   public User runningUser{get;set;}
   
   /** Set the running user. */
   public void setRunningUser() {
      runningUser = [Select Id, Name, Email, Profile.Name from User where Id = :UserInfo.getUserId()];
   } // setRunningUser
   
   /** The Id of the reference object. */
   public Id refId=null;
   
   public Boolean setRefId() {
      refId = System.currentPageReference().getParameters().get('id');
      if (refId == null) {
         ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'No '+objectName+' Id was passed in! Unable to proceed'));
      }
      return (refId != null);      
   } // setRefId

   /** Add a record to the users list for the user to select. */   
   public void checkAddUser(User u, Contact c, String fieldName) {
      if ((u != null && u.IsActive) || (c != null)) {
         UserSelect us = new UserSelect();
         us.selected = true;
         us.userId = (u != null ? u.Id : null);
         us.name = (u!= null ? u.Name : c.Name);
         us.email = (u!= null ? u.Email : c.Email);
         // only add in records that have an email
         if (us.email != null) {
            //us.label = soh.getFieldLabel('Reference_PEO__c',fieldName);
            us.label = getFieldLabel(fieldName);
            users.add(us);
         }
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Added User record for '+u.Name));
      }
   } // checkAddUser
   
   /* Translate a field name to a label. */
   public String getFieldLabel(String fieldName) {
      String fieldLabel = '';
      if (fieldName == 'Area_Manager__c') {
         fieldLabel = 'Area Manager';
      } else if (fieldName == 'Benefits_Specialist__c') {
         fieldLabel = 'Benefits Specialist';
      } else if (fieldName == 'Contractual_Specialist__c') {
          fieldLabel = 'Contractual Specialist';
      } else if (fieldName == 'Onboarding_Specialist__c') {
          fieldLabel = 'Onboarding Specialist';
      } else if (fieldName == 'Sales_Analyst_1__c') {
          fieldLabel = 'Sales Analyst';
      } else if (fieldName == 'DSM__c') {
          fieldLabel = 'DSM';
      } else if (fieldName == 'FSS__c') {
          fieldLabel = 'FSS';
      } else if (fieldName == 'HRG__c') {
         fieldLabel = 'HRG';
      } else if (fieldName == 'Implementation_Project_Manager__c') {
         fieldLabel = 'Implementation Project Manager';         
      } else if (fieldName == 'National_HRG__c') {
         fieldLabel = 'National HRG';
      } else if (fieldName == 'National_Sales_Rep__c') {
         fieldLabel = 'National Sales Consultant';
      } else if (fieldName == 'NCS_Benefits_Specialist__c') {
         fieldLabel = 'Benefits NCS';
      } else if (fieldName == 'NCS_Payroll_Specialist__c') {
         fieldLabel = 'Payroll NCS';
      } else if (fieldName == 'Payroll_Specialist__c') {
         fieldLabel = 'Payroll Specialist';
      } else if (fieldName == 'PEO_HRC__c') {
        fieldLabel = 'PEO+ HRBP';  
      } else if (fieldName == 'Sales_Rep__c') {
         fieldLabel = 'Sales Rep';
      } else if (fieldName == 'Handbook_Setup_Specialist__c') {
         fieldLabel = 'Handbook Setup Specialist';
      } else if (fieldName == 'PEO_Sales_Analyst__c') {
         fieldLabel = 'PEO Sales Analyst';
      } else if (fieldName == 'HR_Specialist__c') {
         fieldLabel = 'HR Specialist';
      }else if (fieldName == 'Responsible_HRG__c') {
         fieldLabel = 'Responsible HRG';
      } else if (fieldName == 'Onboarding_HRG__c') {
         fieldLabel = 'Onboarding HRG';
      }
      return fieldLabel;
   } // getFieldLabel
   

   /** Is there only one User record? */
   public Boolean onlyOneUserRecord{
      get {return users != null && users.size() == 1;}
   } // onlyOneUserRecord
   
   /** The list of users to display. */
   public List<UserSelect> users{get;set;}
   
   /** A Wrapper for the Users to determine who to send to. */
   public class UserSelect {
      public Boolean selected{get;set;}

      /** This will only be set if from a User record. */
      public Id userId {get;set;}

      public String label{get;set;}
      
      public String name{get;set;}

      public String email{get;set;}
   } // userSelect
   
   /** Setup the discrepancies from the reference object. */
   public Boolean setupDiscrepancies(String name, List<SObject> discs) {
     Boolean okay = true;
      // verify there are discrepancies
      if (discs == null || discs.isEmpty()) {
         ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'No Open Discrepancies were found for '+name+'! Must have discrepancies to proceed.'));
         okay = false;
      }
      
      discrepancies = new List<DiscWrapper>();

      if (okay) {      
         for (SObject disc : discs) {
            DiscWrapper dw = new DiscWrapper(disc);
            discrepancies.add(dw);
         } // for
      } // if (okay
      return okay;
   } // setupDiscrepancies
   
   public Boolean onlyOneDiscRecord{
      get {return discrepancies != null && discrepancies.size() == 1;}
   } // onlyOneDiscRecord
   
   public List<DiscWrapper> discrepancies{get;set;}
   
   /** A Wrapper for the Discrepancies. */
   public class DiscWrapper {
     public DiscWrapper(SObject p_disc) {
       if (p_disc.getSObjectType() == Reference_PEO_Discrepancy__c.SObjectType) {
         discPeo = (Reference_PEO_Discrepancy__c)p_disc;
       } else if (p_disc.getSObjectType() == Reference_HRE_CHB_Discrepancy__c.SObjectType) {
         discHre = (Reference_HRE_CHB_Discrepancy__c)p_disc;
       } else if (p_disc.getSObjectType() == Reference_ASO_Discrepancy__c.SObjectType) {
          discASO = (Reference_ASO_Discrepancy__c)p_disc;
       } else if (p_disc.getSObjectType() == Reference_Handbooks_Order_Discrepancy__c.SObjectType) {
          discHbkOrd = (Reference_Handbooks_Order_Discrepancy__c)p_disc;
       }
        disc = p_disc;
        // default to selected
        selected = true;
     } // DiscWrapper
     
     public Reference_PEO_Discrepancy__c discPeo{get;set;}
     public Reference_HRE_CHB_Discrepancy__c discHre{get;set;}
     public Reference_ASO_Discrepancy__c discAso{get;set;}
     public Reference_Handbooks_Order_Discrepancy__c discHbkOrd{get;set;}
     
      public SObject disc{get;set;}
      
      public Boolean selected{get;set;} 
   } // DiscWrapper
   
   /** The number of additional names we are sending to - default to 1. */
   public Integer nbrAddlNames{get;set;}
   
   /** The maximum number of additional names to add. */
   public static Integer MAX_ADDL=15;
   
   public void setAddlNames() {
     // make sure list is initialized
     if (addlNames == null) {
        addlNames = new List<Reference_PEO__c>();
     }
      // do not allow any lower than 1
      if (nbrAddlNames == null || nbrAddlNames<1) {
         nbrAddlNames = 1;
      }
      // do not allow any more than 15
      if (nbrAddlNames > MAX_ADDL) {
         nbrAddlNames = MAX_ADDL;
      }
      while (addlNames.size() != nbrAddlNames) {
        // remove extra rows
         if (addlNames.size() > nbrAddlNames) {
           // remove the latest element
            addlNames.remove(addlNames.size()-1);
         } else if (addlNames.size() < nbrAddlNames) {
            addlNames.add(new Reference_PEO__c());
         }
         
      } // while
      
   } // setAddlNames
   
   /** Additional names to send the email to.
       Using the Reference PEO object only because we already have a filtered lookup field there (Contact_Paychex_Emp__c).
    */
   public List<Reference_PEO__c> addlNames{get;set;}
   
   public boolean checkForContacts() {
      contacts.clear();
      Id[] ctctIds = new Id[]{};
     System.debug('in checkforcon AddlNames'+addlNames);
      for (Reference_PEO__c ctctPEO : addlNames) {
         if (ctctPEO.Contact_Paychex_Emp__c != null) {
            ctctIds.add(ctctPEO.Contact_Paychex_Emp__c);
         }
      }
      if (!ctctIds.isEmpty()) {
         contacts = [Select Id, Name, Email from Contact where Id in :ctctIds];
      }
      return true;
   } // checkForContacts
   
   public List<Contact> contacts = new List<Contact>();
   
   /** verify data entered and send the email. */
   public PageReference sendEmail() {
      checkForContacts();
      if (processEmail()) {
        // if successful return to the reference object
         PageReference returnUrl = new PageReference('/'+refId);
         return returnUrl;
      }
      return null;
   } // sendEmail
   
   public String emailSubject = 'Open Discrepancies';
   public String taskSubject = 'Open Discrepancy';
   
   /** Build the email and send it. 
    */
   private Boolean processEmail() {
      // the first User record will be in the "To" field if possible
      Id toId = null;
      // any subsequent emails will be cc'd
      // use a set to get only unique emails
      Set<String> ccEmailsSet = new Set<String>();
      String emailList = '';
              
      // look through users
      for (UserSelect us : users) {
         if (us.selected) {
            emailList += us.name+' - '+us.email+'\n';
            if (toId == null && us.userId != null) {
               toId = us.userId;
            } else {
               ccEmailsSet.add(us.email);
            }
         }
      } // for (UserSelect
      
      // add any contacts as CC's
      for (Contact ctct : contacts) {
         emailList += ctct.Name+' - '+ctct.Email+'\n';
         ccEmailsSet.add(ctct.Email);
      }

      // if no direct recipient and no cc's, this is an error
      if (toId == null && ccEmailsSet.isEmpty()) {
         ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'At least 1 Recipient needs to be Selected for an Email!'));
         return false;
      }  // if (toId == null
      
      // if no other user selected, send email to the runningUser.
    /*  if (toId == null) {
         toId = runningUser.Id;
         emailList += runningUser.name+' - '+runningUser.email+'\n';
      } */  //commenting out for APR0166500 
      
      // only 25 cc email addresses are allowed. Do we need to check for it??
      
      // put the set data into a normal String list
      String[] ccEmails = new String[]{};
      for (String email : ccEmailsSet) {
         ccEmails.add(email);
      }
      String bodyText = getMessageBody(true);
      String bodyHtml = getMessageBody(false);
      // prepare and send email
      Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
      // If going to a Salesforce user, does not count towards apex email limit.
      if (toId != null ) {
       mail.setTargetObjectId(toId);
      }
      mail.setSubject(emailSubject+' for - '+acct.Name);
      mail.setHtmlBody(bodyHtml);
      mail.setPlainTextBody(bodyText);
      
      if (!ccEmails.isEmpty()) {
         mail.setCcAddresses(ccEmails);
      } // if (!ccEmails
      mail.setBccSender (false);
      mail.setUseSignature(false);
      mail.setSaveAsActivity(false);
      Messaging.sendEmail (new Messaging.SingleEmailMessage[] { mail });
      
      Task task = new Task(Lead_Source_WAR_Call_Type__c='Not WAR'
            //,RecordTypeId = rt.Id // use the default record type of the user
            ,Type=taskSubject+' Email'
            ,Subject=taskSubject+' Email'
            ,Status='Completed'
            ,Priority='Normal'
            ,ActivityDate=Date.today()
            ,WhatId=refId
            ,OwnerId=runningUser.Id
            ,Description=emailList+'\n'+bodyText
            );
      insert task;

      return true;
   } // processEmail
   
   public abstract String getMessageBody(Boolean isText);


} // class RefDiscrepancyHelper