/* Select discrepancies and send an email to selected Users/Contacts
 
  using a template.
 *
 * History
 * -------
 * 09/13/2011 Dan Carmen   Created
   10/31/2011 Dan Carmen   Added FSS
   04/18/2013 Dan Carmen   Modified to use shared code
   11/03/2015 Frank Lurz   Modified body of email, based on presence of HRG and/or Sales Rep   
   02/25/2016 Frank Lurz   Added Implementation Project Manager to list of email recipients
   03/16/2016 Lynn Michels Modified body of email case 20616481
   07/14/2017 Lynn Michels Replace "na5" in urls
   02/28/2018 Frank Lurz   Added PEO+ HRC to list of email recipients
   09/21/2018 Jermaine Stukes  Added text to email - FT#29198937
   10/25/2018 Carrie Marciano FT#30661425 Removed/added users from email list displayed on VF page
   10/28/2018 Brandon Vidro Case 34342730 Removed/added users from email list displayed on VF page
   04/20/2020 Manmeet Vaseer	SFDC-3072 (US5), Modified email body text in getMessageBody().
   06/09/2022 LoAnn Desmond sfdc-14125, disabled the link of faxing and added in the Loader__c 
 *
 */
public with sharing class RefPEODiscrepancyController extends RefDiscrepancyHelper {
 
   /** No argument constructor. 
    */
   public RefPEODiscrepancyController(ApexPages.StandardController stdController) {
      objectName = 'Reference PEO';
      emailSubject = 'PEO Open Discrepancies';
      taskSubject = 'PEO Open Discrepancy';
      setup();
   } // RefPEODiscrepancyController

   public override Boolean getReference(Id refPeoId) {
      try {
         refPEO = [Select Id, Name
                         ,PEO_Tracking_DB_ID__c
                         ,Account_Lookup__r.Name
                         ,Account_Lookup__r.AccountNumber
                         ,Area_Manager__c,Area_Manager__r.Name
                         ,Area_Manager__r.Email,Area_Manager__r.IsActive
                         ,Benefits_Specialist__c,Benefits_Specialist__r.Name
                         ,Benefits_Specialist__r.Email, Benefits_Specialist__r.IsActive
                         ,Branch_Client_Number__c
                         ,Contractual_Specialist__c,Contractual_Specialist__r.Name
                         ,Contractual_Specialist__r.Email, Contractual_Specialist__r.IsActive
                         ,Onboarding_Specialist__c, Onboarding_Specialist__r.Name
                         ,Onboarding_Specialist__r.Email, Onboarding_Specialist__r.IsActive
                         ,Sales_Analyst_1__c, Sales_Analyst_1__r.Name
                         ,Sales_Analyst_1__r.Email, Sales_Analyst_1__r.IsActive
                         ,DSM__c, DSM__r.Name, DSM__r.Email, DSM__r.IsActive
                         ,FSS__c, FSS__r.Name, FSS__r.Email, FSS__r.IsActive
                         ,HRG__c, HRG__r.Name, HRG__r.Email, HRG__r.IsActive
                         ,HR_Specialist__c, HR_Specialist__r.Name, HR_Specialist__r.Email, HR_Specialist__r.IsActive
                         ,PEO_Sales_Analyst__c, PEO_Sales_Analyst__r.Name, PEO_Sales_Analyst__r.Email, PEO_Sales_Analyst__r.IsActive
                         ,Implementation_Project_Manager__c, Implementation_Project_Manager__r.Name, Implementation_Project_Manager__r.Email, Implementation_Project_Manager__r.IsActive
                         ,Loader__c,Loader__r.Name      
                         ,National_HRG__c,National_HRG__r.Name, National_HRG__r.Email, National_HRG__r.IsActive
                         ,Responsible_HRG__c,Responsible_HRG__r.Name, Responsible_HRG__r.Email, Responsible_HRG__r.IsActive
                         ,Onboarding_HRG__c,Onboarding_HRG__r.Name, Onboarding_HRG__r.Email, Onboarding_HRG__r.IsActive
                         ,National_Sales_Rep__c,National_Sales_Rep__r.Name, National_Sales_Rep__r.Email, National_Sales_Rep__r.IsActive
                         ,NCS_Benefits_Specialist__c
                         ,NCS_Benefits_Specialist__r.Name, NCS_Benefits_Specialist__r.Email, NCS_Benefits_Specialist__r.IsActive
                         ,NCS_Payroll_Specialist__c
                         ,NCS_Payroll_Specialist__r.Name, NCS_Payroll_Specialist__r.Email, NCS_Payroll_Specialist__r.IsActive
                         ,Onbrdg_Spreadsheet_Rec_Target__c
                         ,Payroll_Specialist__c
                         ,Payroll_Specialist__r.Name, Payroll_Specialist__r.Email, Previous_Client_Number__c
                         ,PEO_HRC__c, PEO_HRC__r.Name, PEO_HRC__r.Email, PEO_HRC__r.IsActive
                         ,Sales_Rep__c,Sales_Rep__r.Name, Sales_Rep__r.Email, Sales_Rep__r.IsActive
                         ,(Select Id, Name
                                 ,Additional_Information__c
                                 ,Discrepancy_Area__c
                                 ,Discrepancy_Type__c
                                 ,Discrepancy_Sub_Type__c
                                 ,HoldPayrollWillNotRun__c
                                 ,NonHoldPayrollWillRun__c
                                 ,Status__c
                             From PEO_Discrepancies__r
                            where Status__c = 'Open'
                            order by Discrepancy_Area__c, Discrepancy_Type__c)
                     from Reference_PEO__c
                    where Id = :refPeoId];
         acct = refPEO.Account_Lookup__r;
      } catch (Exception e) {
         ApexPages.addMessages(e);
      }
      if (hasRef && !setupDiscrepancies(refPEO.Name, refPEO.PEO_Discrepancies__r)) {
         refPEO = null;
      }
      return hasRef;
   } // getReference
   
//   public static final String[] userFlds = new String[]{'Area_Manager__','Benefits_Specialist__','Contractual_Specialist__'
//                                             ,'DSM__','HRG__','Implementation_Project_Manager__','National_HRG__','National_Sales_Rep__'
//                                             ,'NCS_Benefits_Specialist__','NCS_Payroll_Specialist__'
//                                             ,'Payroll_Specialist__','PEO_HRC__','Sales_Rep__'}; 
                                           
   public override Boolean setupUsers() {
      users = new List<UserSelect>();
      //checkAddUser(refPEO.Area_Manager__r,null,'Area_Manager__c');
      //checkAddUser(refPEO.Benefits_Specialist__r,null,'Benefits_Specialist__c');
      checkAddUser(refPEO.Contractual_Specialist__r,null,'Contractual_Specialist__c');
      checkAddUser(refPEO.Onboarding_Specialist__r, null,'Onboarding_Specialist__c');
      checkAddUser(refPEO.Sales_Analyst_1__r, null, 'Sales_Analyst_1__c');
      checkAddUser(refPEO.DSM__r,null,'DSM__c');
      //checkAddUser(refPEO.FSS__r,null,'FSS__c');
      //checkAddUser(refPEO.HRG__r,null,'HRG__c');
      checkAddUser(refPEO.Implementation_Project_Manager__r,null,'Implementation_Project_Manager__c');
      //checkAddUser(refPEO.National_HRG__r,null,'National_HRG__c');
      checkAddUser(refPEO.National_Sales_Rep__r,null,'National_Sales_Rep__c');
      checkAddUser(refPEO.NCS_Benefits_Specialist__r,null,'NCS_Benefits_Specialist__c');
      checkAddUser(refPEO.NCS_Payroll_Specialist__r,null,'NCS_Payroll_Specialist__c');
      //checkAddUser(null,refPEO.Payroll_Specialist__r,'Payroll_Specialist__c');
      checkAddUser(refPEO.PEO_HRC__r,null,'PEO_HRC__c');
      checkAddUser(refPEO.Sales_Rep__r,null,'Sales_Rep__c');
      checkAddUser(refPEO.PEO_Sales_Analyst__r,null,'PEO_Sales_Analyst__c');
      //checkAddUser(refPEO.HR_Specialist__r,null,'HR_Specialist__c');
      checkAddUser(refPEO.Onboarding_HRG__r,null,'Onboarding_HRG__c');
      //checkAddUser(refPEO.Responsible_HRG__r,null,'Responsible_HRG__c');

      return true;
   } // setupUsers
   
   
    public override String getMessageBody(Boolean isText) {
        List<DiscWrapper> holdPayroll = new List<DiscWrapper>();
        List<DiscWrapper> notHoldPayroll = new List<DiscWrapper>();
        
        //String baseUrl = URL.getSalesforceBaseUrl().toExternalForm()+'/';
        String baseUrl = Utilities.instanceUrl()+'/';
        
        String line = (isText ? '\n' : '<br>'); 
        
        String mailText = ' '+line;
        
        mailText += 'Hello,'+line;
        mailText += 'The PEO onboarding of '+acct.Name+ ' is underway. Below is a listing of current discrepancies that need to be addressed.';
        
        for (DiscWrapper dw : discrepancies) {
            if (dw.selected) {
                
                if(dw.discPeo.HoldPayrollWillNotRun__c) {
                    holdPayroll.add(dw);    
                }
                
                else {
                    notHoldPayroll.add(dw);
                }
                
            }//end selected
        } //for DisWrapper
        
        if(!holdPayroll.isEmpty()){
            mailText += +line+line+ (isText ? '' : '<div style="font-weight:bold;">');
            mailText += 'Open discrepancies that will hold payroll:' +(!isText ? '</div>':'')+line;
            mailText += (isText ? '' : '<ul>');
            for(DiscWrapper refPEOHold : holdPayroll)
            {
                mailText += (isText ? '- ' : '<li>');mailText += refPEOHold.discPeo.Discrepancy_Sub_Type__c + ' (' +refPEOHold.discPeo.Discrepancy_Area__c+ ': ' +refPEOHold.discPeo.Discrepancy_Type__c+ ')';
                if (refPEOHold.discPeo.Additional_Information__c != null)
                {
                    mailText += (isText ? +line : '<ul><li>');
                    mailText += 'Additional Information: ' +refPEOHold.discPeo.Additional_Information__c;
                    mailText += (isText ? '' : '</ul></li>');
                }
                mailText += (isText ? +line+line : '</li>');    
            }
            mailText += (isText ? +line : '</ul>');
        }//end !holdPayroll.isEmpty()
        
        if(!notHoldPayroll.isEmpty()){
            if(holdPayroll.isEmpty()){
                mailText += +line+line;
            }
            mailText += (isText ? '' : '<div style="font-weight:bold;">');
            mailText += 'Open Discrepancies that are not marked as a payroll hold, but need to be addressed:' +(!isText ? '</div>':'')+line;
            mailText += (isText ? '' : '<ul>');
            for(DiscWrapper refPEONotHold : notHoldPayroll)
            {
                mailText += (isText ? '- ' : '<li>');mailText += refPEONotHold.discPeo.Discrepancy_Sub_Type__c + ' (' +refPEONotHold.discPeo.Discrepancy_Area__c+ ': ' +refPEONotHold.discPeo.Discrepancy_Type__c+ ')';
                if (refPEONotHold.discPeo.Additional_Information__c != null)
                {
                    mailText += (isText ? +line : '<ul><li>');
                    mailText += 'Additional Information: ' +refPEONotHold.discPeo.Additional_Information__c;
                    mailText += (isText ? '' : '</ul></li>');
                }
                mailText += (isText ? +line+line : '</li>');
            }
            mailText += (isText ? +line : '</ul>');
        }//end !notHoldPayroll.isEmpty()
        
        mailText += +line+ 'Added Notes: '+emailNote+line;
        mailText += line+'Our goal is to provide an excellent onboarding experience for our clients.';
        mailText += ' Please send all documentation required to clear open discrepancies as soon as possible to the assigned';
        mailText += ' Contractual Specialist - '+refPEO.Contractual_Specialist__r.Name;
        mailText += ', Payroll NCS - '+refPEO.NCS_Payroll_Specialist__r.Name;
        mailText += ', and Benefits NCS - '+refPEO.NCS_Benefits_Specialist__r.Name+ '. '; 
        mailText += ', and Payroll Loader - '+refPEO.Loader__r.Name+ '. ';
      //  mailText += 'If you are sending corrections via fax, please use this email as the coversheet and send to my attention.';
        
        mailText += +line+line+'Prospect-Client Name: ' + acct.Name ;
        if (refPEO.Previous_Client_Number__c != null)
        {
            mailText += +line+'Prospect-Client Number (Account): '+ refPEO.Previous_Client_Number__c ;
        }
        mailText += +line+'Prospect-Client Number (Reference PEO): '+ refPEO.Branch_Client_Number__c  ;
        mailText += +line+'PEO Tracking ID: '+ refPEO.PEO_Tracking_DB_ID__c ;
        // mailText += +line+'Salesforce ID: https://na5.salesforce.com/'+refPEO.id;
        mailText += +line+'Salesforce ID: '+ baseUrl +refPEO.id;
        mailText += +line+ 'In order to receive revenue recognition, a payroll journal or equivalent is due at submission of signed contracts.'+line;
        mailText += line+line+'Thank you!'+line;
        mailText += runningUser.Name+line;
       
		//System.debug('RefPEODiscrepancyController, getMessageBody: ' + mailText);
       
       return mailText;
   } // getMessageBody

} // class RefPEODiscrepancyController