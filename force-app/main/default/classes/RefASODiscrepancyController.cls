/* 
 * Select discrepancies and send an email to the selected users
 
 *
 * History
 * -------
 * 09/18/2013 Justin Henderson   Created
 *
 */
public with sharing class RefASODiscrepancyController extends RefDiscrepancyHelper {

   /** No argument constructor. 
    */
   public RefASODiscrepancyController(ApexPages.StandardController stdController) {
      objectName = 'Reference ASO';
      emailSubject = 'ASO Open Discrepancies';
      taskSubject = 'ASO Open Discrepancy';
      setup();
   } // RefASODiscrepancyController

   public override Boolean getReference(Id refASOId) {
      try {
         refASO = [Select Id, Name
                         ,Case_Number__r.Account.Name
                         ,Case_Number__r.Account.AccountNumber
                         ,Prospect_Client_Name__r.Id
                         ,Prospect_Client_Name__r.Name
                         ,Prospect_Client_Name__r.AccountNumber
                         ,Branch_Client_Number__c
                         ,Area_Manager__c,Area_Manager__r.Name
                         ,Area_Manager__r.Email,Area_Manager__r.IsActive
                         ,DSM__c, DSM__r.Name, DSM__r.Email, DSM__r.IsActive
                         ,FSS__c, FSS__r.Name, FSS__r.Email, FSS__r.IsActive
                         ,HRG__c, HRG__r.Name, HRG__r.Email, HRG__r.IsActive
                         ,Sales_Rep__c,Sales_Rep__r.Name, Sales_Rep__r.Email, Sales_Rep__r.IsActive
                         ,(Select Id, Name
                                 ,Discrepancy_Type__c
                                 ,Resolved_by__c
                                 ,Additional_Information__c
                                 ,Status__c
                             From Reference_ASO_Discrepancies__r
                            where Status__c = 'Open'
                            order by Discrepancy_Type__c)
                     from Reference_ASO__c
                    where Id = :refASOId];
         acct = (refASO.Prospect_Client_Name__r != null ? refASO.Prospect_Client_Name__r : refASO.Case_Number__r.Account);
      } catch (Exception e) {
         ApexPages.addMessages(e);
      }
      // verify there are discrepancies
      if (hasRef && !setupDiscrepancies(refASO.Name, refASO.Reference_ASO_Discrepancies__r)) {               
         refASO = null;
      }
      
      return hasRef;
   } // getReference
   
   public override Boolean setupUsers() {
      users = new List<UserSelect>();
      checkAddUser(refASO.DSM__r,null,'DSM__c');
      checkAddUser(refASO.FSS__r,null,'FSS__c');
      checkAddUser(refASO.Sales_Rep__r,null,'Sales_Rep__c');
      checkAddUser(refASO.HRG__r,null,'HRG__c');
      checkAddUser(refASO.Area_Manager__r,null,'Area_Manager__c');

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
      mailText += 'Salesforce ID: '+refASO.Name+' - '+baseUrl + refASO.id+' '+line;
      
      mailText += 'Message: '+emailNote+line;
      
      mailText += line+'Discrepancies:'+line;

      for (DiscWrapper dw : discrepancies) {
         if (dw.selected) {
            mailText += (isText ? '-------------------------------------------------'+line : '<hr width=100%>');
            mailText += 'Id: '+dw.discASO.Name+' '+baseUrl+dw.discASO.Id+' '+line;
            mailText += 'Type: '+dw.discASO.Discrepancy_Type__c+line;
            mailText += 'Additional Information: '+(dw.discASO.Additional_Information__c != null ? dw.discASO.Additional_Information__c : '')+line;
            mailText += line;
            mailText += 'Please resolve any discrepancies and scan the resolution into WebORS when complete. If you have any questions regarding the above, please contact newclientaso@paychex.com.';
            mailText += line;
         } // if (disc.selected
      } // for (DiscWrapper

     
      mailText += line+'Thank you!'+line;
      mailText += runningUser.Name+line;
      mailText += runningUser.Email+line;
            
      return mailText;
   } // getMessageBody

} // class RefASODiscrepancyController