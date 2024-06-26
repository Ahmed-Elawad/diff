/* 
 * Select discrepancies and send an email to the selected users
 
 *
 * History
 * -------
 * 04/18/2013 Dan Carmen   Created
 *
 */
public with sharing class RefHreDiscrepancyController extends RefDiscrepancyHelper { 

   /** No argument constructor. 
    */
   public RefHreDiscrepancyController(ApexPages.StandardController stdController) {
   	objectName = 'Reference HRE';
      emailSubject = 'HRE Open Discrepancies';
      taskSubject = 'HRE Open Discrepancy';
   	setup();
   } // RefHreDiscrepancyController

   public override Boolean getReference(Id refHreId) {
      try {
         refHre = [Select Id, Name
                         ,Account_Lookup__r.Id
                         ,Account_Lookup__r.Name
                         ,Account_Lookup__r.AccountNumber
                         ,Handbook_Setup_Specialist__c,Handbook_Setup_Specialist__r.Name
                         ,Handbook_Setup_Specialist__r.Email,Handbook_Setup_Specialist__r.IsActive
                         ,DSM__c, DSM__r.Name, DSM__r.Email, DSM__r.IsActive
                         ,FSS__c, FSS__r.Name, FSS__r.Email, FSS__r.IsActive
                         ,Sales_Rep__c,Sales_Rep__r.Name, Sales_Rep__r.Email, Sales_Rep__r.IsActive
                         ,(Select Id, Name
                                 //,Critical__c
                                 //,Discrepancy_Area__c
                                 ,Discrepancy_Type__c
                                 ,Discrepancy_Sub_Type__c
                                 ,Additional_Information__c
                                 ,Status__c
                             From Handbook_Discrepancies__r
                            where Status__c = 'Open'
                            order by Discrepancy_Type__c)
                     from Reference_HRE_CHB_Onboarding__c
                    where Id = :refHreId];
         acct = refHre.Account_Lookup__r;
      } catch (Exception e) {
         ApexPages.addMessages(e);
      }
      // verify there are discrepancies
      if (hasRef && !setupDiscrepancies(refHre.Name, refHre.Handbook_Discrepancies__r)) {
         refHre = null;
      }
      
      return hasRef;
   } // getReference
   
   public override Boolean setupUsers() {
      users = new List<UserSelect>();
      checkAddUser(refHre.Handbook_Setup_Specialist__r,null,'Handbook_Setup_Specialist__c');
      checkAddUser(refHre.DSM__r,null,'DSM__c');
      checkAddUser(refHre.FSS__r,null,'FSS__c');
      checkAddUser(refHre.Sales_Rep__r,null,'Sales_Rep__c');

      return true;
   } // setupUsers

   public override String getMessageBody(Boolean isText) {
      //String baseUrl = URL.getSalesforceBaseUrl().toExternalForm()+'/';
      String baseUrl = Utilities.instanceUrl()+'/';
       
      String line = (isText ? '\n' : '<br>');

      String mailText = 'Hello,'+line;
      mailText += 'Here are the open New Business discrepancies for: '+line;
      mailText += 'Prospect-Client Name: '+acct.Name+line;
      if (acct.AccountNumber != null) {
         mailText += 'Prospect-Client Number (Account): '+ acct.AccountNumber+line;
      }
      //mailText += 'PEO Tracking ID: '+ (refPEO.PEO_Tracking_DB_ID__c != null ? String.valueOf(refPEO.PEO_Tracking_DB_ID__c) : '')+line;
      mailText += 'Salesforce ID: '+refHre.Name+' - '+baseUrl + refHre.id+' '+line;
      
      mailText += 'Message: '+emailNote+line;
      
      mailText += line+'Discrepancies:'+line;

      for (DiscWrapper dw : discrepancies) {
         if (dw.selected) {
            mailText += (isText ? '-------------------------------------------------'+line : '<hr width=100%>');
            mailText += 'Id: '+dw.discHre.Name+' '+baseUrl+dw.discHre.Id+' '+line;
            mailText += 'Type: '+dw.discHre.Discrepancy_Type__c+line;
            mailText += 'Sub-Type: '+dw.discHre.Discrepancy_Sub_Type__c+line;
            mailText += 'Additional Information: '+(dw.discHre.Additional_Information__c != null ? dw.discHre.Additional_Information__c : '')+line;
            mailText += line;
         } // if (disc.selected
      } // for (DiscWrapper

      mailText += line+'If you are sending corrections via fax please use this email as the coversheet and send to my attention. If corrections can be emailed, please use this email and reply all.'+line;
      
      mailText += line+'Thank-you!'+line;
      mailText += runningUser.Name+line;
      mailText += runningUser.Email+line;
            
      return mailText;
   } // getMessageBody
   

} // class RefHreDiscrepancyController