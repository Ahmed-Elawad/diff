/* 
 * Select discrepancies and send an email to the selected users
 *
 * History
 * -------
 * 09/06/2014 Frank Lurz   Created
 * 02/18/2015 Frank Lurz   commented out mailText += line+'If you are sending corrections... per BUs request during post-imp
 * 08/30/2022 Josh Cartwright	updated baseURL for enhanced domains 
 * 04/12/2024 Susmitha Somavarapu The Handbooks can select whether they want to send the email to the exsiting HRG email or the new handbookproduction email(APR0166500).


 */
public with sharing class RefHbkOrdDiscrepancyController extends RefDiscrepancyHelper { 

   /** No argument constructor. 
    */
   public RefHbkOrdDiscrepancyController(ApexPages.StandardController stdController) {
    objectName = 'Reference HRE CHB Orders';
      emailSubject = 'Handbook Open Discrepancies';
      taskSubject = 'Handbook Open Discrepancy';
    setup();
   } // RefHbkOrdDiscrepancyController

   public override Boolean getReference(Id refHbkOdrId) {
      try {
         refHbkOdr = [Select Id, Name
                         ,Reference_HR_Essentials__r.Account_Lookup__r.Id
                         ,Reference_HR_Essentials__r.Account_Lookup__r.Name
                         ,Reference_HR_Essentials__r.Account_Lookup__r.AccountNumber
                         //,Handbook_Setup_Specialist__c,Handbook_Setup_Specialist__r.Name
                         //,Handbook_Setup_Specialist__r.Email,Handbook_Setup_Specialist__r.IsActive
                         ,HRG__c, HRG__r.Name, HRG__r.Email, HRG__r.IsActive
                         ,Area_Manager__c, Area_Manager__r.Name, Area_Manager__r.Email, Area_Manager__r.IsActive
                         ,(Select Id, Name
                                 //,Critical__c
                                 //,Discrepancy_Area__c
                                 ,Discrepancy_Type__c
                                 ,Additional_Information__c
                                 ,Status__c
                             From Reference_Handbook_Order_Discrepancies__r
                            where Status__c = 'Open'
                            order by Discrepancy_Type__c)
                     from Reference_HRE_CHB_Orders__c
                    where Id = :refHbkOdrId];
         acct = refHbkOdr.Reference_HR_Essentials__r.Account_Lookup__r;
      } catch (Exception e) {
         ApexPages.addMessages(e);
      }
      // verify there are discrepancies
      if (hasRef && !setupDiscrepancies(refHbkOdr.Name, refHbkOdr.Reference_Handbook_Order_Discrepancies__r)) {
         refHbkOdr = null;
      }
      
      return hasRef;
   } // getReference
   
   public override Boolean setupUsers() {
      users = new List<UserSelect>();
      //checkAddUser(refHbkOdr.Handbook_Setup_Specialist__r,null,'Handbook_Setup_Specialist__c');
      checkAddUser(refHbkOdr.HRG__r,null,'HRG__c');
      checkAddUser(refHbkOdr.Area_Manager__r,null,'Area_Manager__c');
      //Handbooks can select whether they want to send the email to the existing HRG email or the new handbookproduction email(Sush APR0166500)
      OrgWideEmailAddress owea = new OrgWideEmailAddress();
      owea = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE DisplayName='Handbook Production'];       
      UserSelect us = new UserSelect();
      us.selected = false      ;
      us.name = owea.DisplayName;
      us.email = owea.Address;         
      us.label = owea.DisplayName;
      users.add(us);// APR0166500
         
      System.debug('users'+users);
      //checkAddUser(refHbkOdr.Sales_Rep__r,null,'Sales_Rep__c');

      return true;
   } // setupUsers

   public override String getMessageBody(Boolean isText) {
      //String baseUrl = URL.getSalesforceBaseUrl().toExternalForm()+'/';
      String baseUrl = Utilities.getInstanceURL()+'/';
       
      String line = (isText ? '\n' : '<br>');
	
      String phone = Label.Handbook_Contact_Phone;
      String email = Label.Handbook_Contact_Email;
       
      String mailText = 'Hello,'+line;
      mailText += line+'If you have any questions regarding this discrepancy, please DO NOT reply to this email.  Please contact our Client Service Center at ' + Label.Handbook_Contact_Phone + ', or e-mail ' + Label.Handbook_Contact_Email + '. Representatives are available to assist you Monday through Friday, from 8:00 a.m. to 8:00 p.m. ET.'+line;      
      mailText += line+'Here are the open Handbook discrepancies for: '+line;
      mailText += line+'Prospect-Client Name: '+acct.Name+line;
      if (acct.AccountNumber != null) {
         mailText += 'Prospect-Client Number (Account): '+ acct.AccountNumber+line;
      }
      //mailText += 'PEO Tracking ID: '+ (refPEO.PEO_Tracking_DB_ID__c != null ? String.valueOf(refPEO.PEO_Tracking_DB_ID__c) : '')+line;
      mailText += 'Salesforce ID: '+refHbkOdr.Name+' - '+baseUrl + refHbkOdr.id+' '+line;
      
      mailText += 'Message: '+emailNote+line;
      
      mailText += line+'Discrepancies:'+line;

      for (DiscWrapper dw : discrepancies) {
         if (dw.selected) {
            mailText += (isText ? '-------------------------------------------------'+line : '<hr width=100%>');
            mailText += 'Id: '+dw.discHbkOrd.Name+' '+baseUrl+dw.discHbkOrd.Id+' '+line;
            mailText += 'Type: '+dw.discHbkOrd.Discrepancy_Type__c+line;
            mailText += 'Additional Information: '+(dw.discHbkOrd.Additional_Information__c != null ? dw.discHbkOrd.Additional_Information__c : '')+line;
            mailText += line;
         } // if (disc.selected
      } // for (DiscWrapper

      //mailText += line+'If you are sending corrections via fax please use this email as the coversheet and send to my attention. If corrections can be emailed, please use this email and reply all.'+line;
      mailText += line+'In order to remove this order from discrepancy, please:'+line;
      mailText += (isText ? '1) Take appropriate action to correct the information on the order, and'+line : '<ol><li>Take appropriate action to correct the information on the order, and </li>');
      mailText += (isText ? '2) Follow the link next to the Discrepancies - Id and fill in the Resolution Type using the drop-down box.'+line : '<li>Follow the link next to the Discrepancies - Id and fill in the Resolution Type using the drop-down box.</li></ol>'+line);
      mailText += (isText ? 'Answers to Frequently Asked Questions can be located here: https://paychex.sharepoint.com/:w:/r/sites/Resources/hrg-resource-center/_layouts/15/Doc.aspx?sourcedoc=%7B0413E204-9462-4EC4-8E1C-159C56A5F50A%7D&file=Salesforce%20Handbook%20Discrepancy%20FAQ.docx&action=default&mobileredirect=true&DefaultItemOpen=1'+line : 'Answers to Frequently Asked Questions can be located <a href="https://paychex.sharepoint.com/:w:/r/sites/Resources/hrg-resource-center/_layouts/15/Doc.aspx?sourcedoc=%7B0413E204-9462-4EC4-8E1C-159C56A5F50A%7D&file=Salesforce%20Handbook%20Discrepancy%20FAQ.docx&action=default&mobileredirect=true&DefaultItemOpen=1">here</a>'+line);
      
      mailText += line+'Sincerely,'+line;
      mailText += 'Handbooks Department'+line;      
      //mailText += runningUser.Name+line;
      //mailText += runningUser.Email+line;
            
      return mailText;
   } // getMessageBody
   

} // class RefHbkOrdDiscrepancyController