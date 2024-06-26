/* Check the number of licenses being used. Send out a summary email at the end.

   Execute Anonymous:
   UserLicenseCheck ulc = new UserLicenseCheck();
   ulc.execute(null);
   
  History
  -------
  12/04/2017 Dan Carmen      Created
  04/05/2018 Dan Carmen      Modify format of output file.
  
 */
global without sharing class UserLicenseCheck implements Schedulable, BatchControlInterface {
    
   global void execute(SchedulableContext SC) {
      runProcess();
   } // execute

   // the names of the profiles used for Read Only licenses
   public static String[] READ_ONLY_PROFILES = Label.LicenseReadOnly.split(',');
   // the number of read only licenses allocated to our organization
   public static Integer NBR_READ_ONLY = Integer.valueOf(Label.LicenseNbrReadOnly);
   
   global boolean handleProcessCheck(PurgeControl__c pc, PurgeControlTracker__c pcd, Messaging.SingleEmailMessage[] emails, String[] processMsgs) {
      Boolean success=true;
      runProcess(emails, processMsgs);
      return success;
   } // handleProcessCheck

   global void runProcess() {
      runProcess(null,null);
   }

   global void runProcess(Messaging.SingleEmailMessage[] emails, String[] processMsgs) {
      Integer totalLicensesAvailable = getTotalLicenseCount();
      Integer nbrReadOnlyActive = [Select count() from User where IsActive=true and UserType='Standard' and Profile.UserLicense.Name='Salesforce' and Profile.Name in :READ_ONLY_PROFILES];
      Integer totalActive = [Select count() from User where IsActive=true and UserType='Standard' and Profile.UserLicense.Name='Salesforce' and Profile.Name NOT in :READ_ONLY_PROFILES];
      System.debug('runProcess totalLicensesAvailable='+totalLicensesAvailable+' nbrReadOnlyActive='+nbrReadOnlyActive+' totalActive='+totalActive);
      
      String licenseNames = READ_ONLY_PROFILES[0];
      if (READ_ONLY_PROFILES.size() > 1) {
         for (String licenseName : READ_ONLY_PROFILES) {
            licenseNames += ', '+licenseName;
         }
      } // if (READ_ONLY_PROFILES.size()
      
      Integer freeLicenses = totalLicensesAvailable - (nbrReadOnlyActive + totalActive);
      Boolean inCompliance = ((nbrReadOnlyActive + freeLicenses) >= NBR_READ_ONLY);
      System.debug('runProcess inCompliance='+inCompliance);
      // nbrReadOnlyActive + freeLicenses should be greater than NBR_READ_ONLY to be in compliance
      String subject='License Read-Only Compliance Summary';
      if (!inCompliance) {
         subject = '**Read-Only licenses are NOT in Compliance!**';
      }
      if (processMsgs != null) {
          processMsgs.add(subject);
      }
      String msgBody = 'License Summary:';
      
      String instanceName = Utilities.checkForProduction();
      if (String.isNotBlank(instanceName)) {
         msgBody += '\n**This ran in the '+instanceName+' instance.**';
      }
      
      /*
      Read-Only Licenses Purchased:  Y (this is the number of read only licenses we have purchased, should be 156)
Read-Only Licenses Assigned:  A (this is the number of active, assigned read only licenses)
Read-Only Licenses Available to be Assigned: B (this is Y - A)

Full Licenses Purchased: Z (this is X-Y)
Full Licenses Assigned: C (this is the number active, assigned full licenses)
Full Licenses Available to be Assigned: D (this is Z - C)
      
      */
      msgBody += '\n\nTotal Licenses Available: '+totalLicensesAvailable;
      
      msgBody += '\n\nRead-Only Licenses Purchased: '+NBR_READ_ONLY;
      msgBody += '\nRead-Only Licenses Assigned: '+nbrReadOnlyActive;
      msgBody += '\nRead-Only Licenses Available to be Assigned: '+(NBR_READ_ONLY-nbrReadOnlyActive);
      if ((NBR_READ_ONLY-nbrReadOnlyActive) <= 0) {
         msgBody+= ' ********';
      }

      msgBody += '\n\nFull Licenses Purchased: '+(totalLicensesAvailable-NBR_READ_ONLY);
      msgBody += '\nFull Licenses Assigned: '+totalActive;
      msgBody += '\nFull Licenses Available to be Assigned: '+((totalLicensesAvailable-NBR_READ_ONLY)-totalActive);
      if (((totalLicensesAvailable-NBR_READ_ONLY)-totalActive) <= 0) {
         msgBody+= ' ********';
      }
      
      msgBody += '\n\nRead-Only License Name(s): '+licenseNames;
      msgBody += '\n\n Total active licenses: '+(totalActive+nbrReadOnlyActive);
      
      if (inCompliance) {
         //msgBody +=  
         
      } else {
         msgBody += '\n****** NOT ENOUGH LICENSES ARE ALLOCATED FOR READ-ONLY!! ******';
         msgBody += '\n'+(NBR_READ_ONLY - ((nbrReadOnlyActive + freeLicenses))) +' licenses need to be freed up.';
      }
      
      System.debug('runProcess msgBody='+msgBody);
      
      Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
      mail.setSaveAsActivity(false);
      mail.setTargetObjectId(UserInfo.getUserId());
      mail.setSubject(subject);
      mail.setPlainTextBody (msgBody);

      Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance('UserLicenseCheck');
      if (abc != null && String.isNotBlank(abc.AdditionalEmails__c)) {
         // CC everyone in the "AdditionalEmails__c" field
         String[] ccEmails = abc.AdditionalEmails__c.split(',');
         System.debug('runProcess ccEmails='+ccEmails);
         mail.setCcAddresses(ccEmails);
      }
      
      if (emails != null) {
         emails.add(mail);
      } else {
         Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
      }
   } // runProcess
   
   global static Integer getTotalLicenseCount() {
      UserLicense ul = [Select ID, Name, LicenseDefinitionKey, TotalLicenses from UserLicense where Name='Salesforce'];
      return (ul != null ? Integer.valueOf(ul.TotalLicenses) : 0);
   } // getTotalLicenseCount

} // class UserLicenseCheck