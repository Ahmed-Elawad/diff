/* 
 * Controller for submitting CSA inquiries
 *
 * History
 * -------
 * 10/04/2010 Dan Carmen        Add check for blank employee number field. Clean up code.
 * 01/25/2011 Tom Muskatevc     Changed to use new Sales Admin Contact field from standard contact field.
   03/09/2011 Dan Carmen        Added setting the record type of CSA_Inquiries__c
   06/02/2011 Leslie Hogan      Added new fields to CSA Inquiries object for Request Tracker.
   05/03/2013 Justin Stouffer   Updated to add attachments
   09/04/2016 Lynn Michels      Changed the description that is created when 'COMM/AUDIT...' is selected Case 22280012
   11/08/2016 Lynn Michels      Added more criteria for setting the case fields and cleaned up inactive values that were still in code
   12/15/2016 Dan Carmen        Modifications for submitting referral issues
   12/16/2016 Jermaine Stukes   Added method for split opportunity request type
   04/07/2017 Sunnish Annu      Added method for getting the inactive users in the Sales rep field
   02/14/2018 Frank Lurz        Added new fields to CSA Inquiries object
   03/20/2018 Frank Lurz        Modifications for submitting INTERNAL REFERRALS
   07/13/2018 Cindy Freeman     Added 2 lines to set the Case record type instead of depending on the user's profile to get the default Case record type
   01/03/2020 Michael Karcz     Modifications for submitting 'DISTRICT CREDIT REASSIGNMENT'
   01/20/2021 Brandon Vidro     Added PEO - Rev on Sub to list of SPLIT OPPORTUNITY REQUEST TYPE products
   09/29/2022 Susmitha Somavarapu APR0141600: New Products Needed for HRS Splits
   07/23/2023 Pratik Das        APR0139853: Changes to the 'Submit Corporate Commissions Inquiry' field added Related_Opportunity__c
 *
 */
public without sharing class SubmitCSAInquiries2 {
    
    public Date submitDate = Date.today();
    public Boolean split{get;set;}
    public String searchString{get;set;}
    public Boolean isActive{get;set;}
    public List<User> results{get;set;}
    public SubmitCSAInquiries2() {
       setupFound = false;
       c = new Case();
       Schema.RecordTypeInfo caseRt = RecordTypeHelper.getRecordType('Sales CSA Support Cases Record Type','Case'); 
       c.RecordTypeId = caseRt.getRecordTypeId();
       cSAInq = new CSA_Inquiries__c();
       Schema.RecordTypeInfo rt = RecordTypeHelper.getDefaultRecordType('CSA_Inquiries__c');
       if (rt != null) {
          cSAInq.RecordTypeId = rt.getRecordTypeId();
       }
       u = [Select Id, Sales_Org__c, Zone__c, HR_Person_Id__c from User where Id = :UserInfo.getUserId()];
       Contact ctct = null;
       if (u.HR_Person_Id__c != null) {
          try {
             // person id is a unique external id so there will only ever be one matching value.
             ctct = [Select Id from Contact where Account.Name = 'Paychex Inc SA' and HR_Person_Id__c = :u.HR_Person_Id__c limit 1];
             c.Sales_Admin_Contact__c = ctct.Id;
          } catch (Exception e) {
             ctct = null;
          } // try
       } // if (u.EmployeeNumber != null
       if (ctct == null) {
          // this is in case there is no match.
          ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'A matching contact record could not be found for person id '+u.HR_Person_Id__c));
       }
    } // SubmitCSAInquiries
    
    public Boolean setupFound {get; private set;}
    
    public CSA_Inquiries_Setup__c cSAInqSetup {get; private set;}
    
     //SPLIT OPPORTUNITY REQUEST TYPE ONLY
    public List<SelectOption> getProducts() 
    {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('','--None--'));
        options.add(new SelectOption('401k','401k'));
        options.add(new SelectOption('Custom Handbook','Custom Handbook'));
        options.add(new SelectOption('ERTC','ERTC'));
        options.add(new SelectOption('ESR','ESR'));
        options.add(new SelectOption('HR Essentials','HR Essentials'));
        options.add(new SelectOption('HR SOLUTION','HR SOLUTION'));
        options.add(new SelectOption('Hiring','Hiring'));
        options.add(new SelectOption('IRA','IRA'));
        options.add(new SelectOption('Onboarding','Onboarding'));
        options.add(new SelectOption('PBA','PBA'));
        options.add(new SelectOption('PEO','PEO'));
        options.add(new SelectOption('PEO - Rev on Sub','PEO - Rev on Sub'));
        options.add(new SelectOption('Premier Non-Payroll (PNP)','Premier Non-Payroll (PNP)'));
        
        
        return options;
    }

    //APR0139853: Changes to the 'Submit Corporate Commissions Inquiry' field added Related_Opportunity__c
    public PageReference setRequestType() {
       setupFound = false;
       CSAInqSetup = null;
       if (CSAInq.Request_Type__c != '') {
          try {
              CSAInqSetup = [Select Id, Name
                             ,Action_Add_Modify__c
                             ,Additional_URLs_Affected__c
                             ,Affected_Commission__c
                             ,Affected_Revenue__c
                             ,Affected_Role__c
                             ,Affected_Unit__c
                             ,Allow_Attachment__c
                             ,Approved_Reject_Status__c
                             ,Approved_Revenue__c
                             ,Bank_Level__c
                             ,BISID_ClientID__c
                             ,Bonus_Effected__c
                             ,Bonus_Expected__c
                             ,Bonus_Received__c
                             ,Bonus_Type__c
                             ,Branch_Number__c
                             ,Business_Justification__c
                             ,Client_Number__c
                             ,Client_Platform__c
                             ,Client_Start_Date__c
                             ,Comp_Plan_Type__c
                             ,Commissionable_Month__c
                             ,Commissionable_Year__c
                             ,Corporate_Comment__c
                             ,District__c
                             ,District_Number__c
                             ,District_to_be_Credited__c
                             ,Division__c
                             ,DSM__c
                             ,Lead_ID__c
                             ,LeadIdRequired__c
                             ,Moving_From_Rep_del__c
                             ,Moving_From_District__c
                             ,Moving_From_DSM_del__c
                             ,New_Units__c
                             ,Order_Number__c
                             ,Original_Units__c
                             ,Payroll_Spec_Branch_No__c
                             ,Payroll_Specialist__c
                             ,Prospect_Client_Name__c
                             ,Product__c
                             ,Product_Picklist__c
                             ,Product_Picklist_Single__c
                             ,Product_Start_Date__c
                             ,Processing_Branch__c
                             ,Question_Comment__c
                             ,Reason_for_Request__c
                             ,Reason_Code__c
                             ,Requestors_Role__c
                             ,Request_Type__c
                             ,Report_Type__c
                             ,Report_Status__c
                             ,Report_Name__c
                             ,Referring_Rep__c
                             ,Referral_Type__c
                             ,Referral_Bank_Name__c
                             ,Receiving_Rep_del__c
                             ,Receiving_District__c
                             ,Receiving_DSM_del__c
                             ,RSM__c
                             ,RECOGNITION_TYPE__c
                             ,Sales_ID__c
                             ,Sales_Rep__c
                             ,Sales_Rep_Code__c
                             ,SOAR_Referral_Type__c
                             ,Splitting_Rep_Name__c
                             ,Subject__c
                             ,Submitted_By__c
                             ,Submitted_By_Zone__c
                             ,Suggested_Revenue__c
                             ,Term_ed_Rep__c
                             ,Tier_1_Bank__c
                             ,Tier_2_Bank__c
                             ,TRR__c
                             ,Unit_Type__c
                             ,URL__c
                             ,Web_Request_Type__c
                             ,Zone_Number_Picklist__c
                             ,Related_Opportunity__c
                             From CSA_Inquiries_Setup__c
                             where Name = :CSAInq.Request_Type__c limit 1];             
             setupFound = true;
             system.debug('Event on Change ====== '+CSAInqSetup );

          } catch (Exception e) {
             ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'Could not find a record for '+CSAInq.Request_Type__c));
          }
           if(CSAInq.Request_Type__c == 'SPLIT OPPORTUNITY' || CSAInq.Request_Type__c == 'INTERNAL REFERRALS')
           {
               split = true;
           }
           if(CSAInq.Request_Type__c == 'DISTRICT CREDIT REASSIGNMENT' ||CSAInq.Request_Type__c == 'REP TRANSFER_DIVISION/DISTRICT REASSIGNMENT')
           {
               CSAInq.Submitted_By__c = UserHelper.GetRunningUser().Id;
           }
       } // if (CSAInq.Request_Type__c
       return null;
    } // setRequestType
        
    public CSA_Inquiries__c cSAInq {get;set;}
    
    public Case c { get; private set; }
            
    public User u {get;private set;} 
              
    public PageReference cancel() {
        return null;
    }

    public Boolean showTier1 {
        get {
           Boolean showSection = (cSAInqSetup != null && cSAInqSetup.Tier_1_Bank__c &&
                                  ((cSAInqSetup.Bank_Level__c && cSAInq.Bank_Level__c == 'Tier 1') ||
                                   (!cSAInqSetup.Bank_Level__c)));
            
           return showSection;
        }
    } // showTier1
    
    public Boolean showTier2 {
        get {
           Boolean showSection = (cSAInqSetup != null && cSAInqSetup != null && cSAInqSetup.Tier_2_Bank__c &&
                                  ((cSAInqSetup.Bank_Level__c && cSAInq.Bank_Level__c == 'Tier 2') ||
                                   (!cSAInqSetup.Bank_Level__c)));
            
           return showSection;
        }
    } // showTier2
    
    


    public void setCaseFields() {
       c.origin ='CSA Submit Request'; 
       c.Type = 'CSA Inquiry'; 
       c.subject = CSAInq.Request_Type__c;
       String tempDesc = null;
       if (CSAInq.Request_Type__c == 'REPORT') {             
          tempDesc = ' '+CSAInq.Report_Status__c+' : '+ CSAInq.Division__c+' ';           
       }
       if (CSAInq.Request_Type__c == 'RECOGNITION') { 
          tempDesc = ' '+CSAInq.RECOGNITION_Type__c+' : '+ U.Sales_Org__c+' ';            
       }  
       /*new functionality below        
       if ((CSAInq.Request_Type__c == 'COMM/AUDIT - ** For Monthly Audit Use Only **') ||
           (CSAInq.Request_Type__c == 'GENERAL QUESTION')) { 
          tempDesc = ' '+ U.Zone__c + ' : '+ U.Sales_Org__c+' ';            
       }*/
       if (CSAInq.Request_Type__c == 'COMM/AUDIT - ** For Monthly Audit Use Only **'){
            tempDesc = ' '+ CSAInq.Division__c +' ';    
       }
       if (CSAInq.Request_Type__c == 'GENERAL QUESTION') {
            if (CSAInq.Division__c == 'AGENCY' ||
                CSAInq.Division__c == 'P&C' ||
                CSAInq.Division__c == 'BUSINESS DEV'){
                    tempDesc = ' '+ CSAInq.Division__c +' '; 
            }
            else{ 
                tempDesc = ' '+ U.Zone__c + ' : '+ U.Sales_Org__c+' ';
            }
       } 
       if (CSAInq.Request_Type__c == 'STAT DISCREPANCY') { 
          tempDesc = ' '+ U.Sales_Org__c+' '; 
       }
       if (CSAInq.Request_Type__c == 'COMMISSION SYSTEM ACCESS') { 
          tempDesc = ' '+ U.Zone__c + ' : '+ U.Sales_Org__c+' '; 
       }
       if (CSAInq.Request_Type__c == 'DISTRICT CREDIT REASSIGNMENT' ||CSAInq.Request_Type__c == 'REP TRANSFER_DIVISION/DISTRICT REASSIGNMENT') {
           c.Status = 'Closed';
       }
       c.Description = tempDesc;            
    } // setCaseFields
    
    public Date getSecondBusinessDay(Date checkDate) {
       Datetime dt = DateTime.newInstance(checkDate.year(), checkDate.month(), checkDate.day());
       // get the next business day. If Friday, Saturday, or Sunday, next day will be Monday.
       Date nextDay = Utilities.getNextBusinessDay(dt,1);
       dt = DateTime.newInstance(nextDay.year(), nextDay.month(), nextDay.day());
       // get the next business day after that. This means if originally Thursday, next day will be Monday.
       // If originally Friday, Saturday or Sunday, next day will be Tuesday.
       return Utilities.getNextBusinessDay(dt, 1);
    } // getSecondBusinessDay
    
    /** Set the follow up date on the case.
     */
    public Date getFollowUpDate(String requestType, Date checkDate) {
       Date followUpDate = null;
       if ((requestType == 'BONUS DISCREPANCY') ||
           (requestType == 'PAYROLL UNIT DISCREPANCY')) {
          if (19 > checkDate.day()) {
             followUpDate = checkDate.toStartOfMonth().addDays(17);
          } else {
             followUpDate = checkDate.toStartOfMonth().addMonths(1).addDays(17);
          } // if (Date.today().day
       } else {
          // default second business day
          followUpDate = getSecondBusinessDay(checkDate);
       }
       return followUpDate;
    } // getFollowUpDate
    public PageReference save() 
    {
        system.debug(' ***   FRL entered save() in SubmitCSAInquiries2   *** ');
        return submit2(false);
  /*
       setCaseFields();
       Database.DMLOptions dmo = new Database.DMLOptions();
       dmo.assignmentRuleHeader.useDefaultRule= true;
       c.setOptions(dmo);
       insert c;
       CSAInq.case__c = c.Id;
       insert CSAInq;
    
       PageReference casePage = new ApexPages.StandardController(c).view();
       
       if (setupFound){
           if(CSAInqSetup.Allow_Attachment__c){
           casePage = new PageReference('/apex/AttachmentUpload?parent=' + c.id + '&CSA=TRUE' + '&savedList=');
           }
       }
        
       casePage.setRedirect(true);
       return casePage ; 
    */
    } // save
    public PageReference submit() {
        system.debug(' ***   FRL entered submit() in SubmitCSAInquiries2   *** ');
        return submit2(true);
        /*
       setCaseFields();
       c.Follow_Up_Date__c = getFollowUpDate(CSAInq.Request_Type__c,submitDate);
       
       //check for duplicate INTERNAL REFERRALS records
       List<CSA_Inquiries__c> cSAInqList = [select id
                                            From CSA_Inquiries__c
                                            Where Request_Type__c = 'INTERNAL REFERRALS'
                                                       and Division__c = CSAInq.Division__c
                                                       and Branch_Number__c = CSAInq..Branch_Number__c
                                                       and Client_Number__c = CSAInq..Client_Number__c
                                                       and Product_Picklist__c = CSAInq..Product_Picklist__c
                                                       and Commissionable_Month__c = CSAInq..Commissionable_Month__c
                                                       and Commissionable_Year__c = CSAInq..Commissionable_Year__c];
    
    if (!cSAInqList.isEmpty()) {
                 //refMPSC.addError('You cannot submit a Survey for this record. There are related Reference MPSC records that are not Completed.');
                 //ADD APEX MESSAGE WITH WARNING NOT ERROR OR FATAL HERE
                 //ADD return null HERE
    } //end if
                     
       Database.DMLOptions dmo = new Database.DMLOptions();
       dmo.assignmentRuleHeader.useDefaultRule= true;
       c.setOptions(dmo);
       insert c;
       CSAInq.case__c = c.Id;
       insert CSAInq;
       
       // setup CaseTeamMember
       CaseTeamMember caseMemb = new CaseTeamMember();
       //put CaseId into CaseMemb object
       caseMemb.ParentId = c.Id;
       //put userId into CaseMemb object
       caseMemb.MemberId = u.Id;
       // set Read Only case role.
       CaseTeamRole ctr = [Select id from CaseTeamRole where Name='Read Only'];
       //set TeamRoleId 
       // CaseMemb.TeamRoleId = '0B770000000Gmbv'; 
       caseMemb.TeamRoleId = ctr.Id;       
       insert caseMemb;
       
       PageReference hmPage = new PageReference('/home/home.jsp');
        //SPLIT OPPORTUNITY and INTERNAL REFERRALS requests return to form for multiple submissions
        if(CSAInq.Request_Type__c == 'SPLIT OPPORTUNITY' || CSAInq.Request_Type__c == 'INTERNAL REFERRALS')
        {
            hmPage = new PageReference('/apex/SubmitCSARequest');
        }
        else if (setupFound){
           if(CSAInqSetup.Allow_Attachment__c){
           hmPage = new PageReference('/apex/AttachmentUpload?parent=' + c.id + '&CSA=FALSE' + '&savedList=');
           }
       }
       
       hmPage.setRedirect(true);
       return hmPage ; 
      */
    } // submit

 
     public PageReference submit2(Boolean notCsaRole) {

       system.debug(' ***   FRL entered submit2() in SubmitCSAInquiries2   *** ');
       setCaseFields();
       if (notCsaRole) {
       c.Follow_Up_Date__c = getFollowUpDate(CSAInq.Request_Type__c,submitDate);
       }
                     
       //check for duplicate INTERNAL REFERRALS records
       if (CSAInq.Request_Type__c == 'INTERNAL REFERRALS') {
       CSAInq.Product_Picklist__c = CSAInq.Product_Picklist_Single__c;
       List<CSA_Inquiries__c> cSAInqListDup = [select id
                                            From CSA_Inquiries__c
                                            Where Request_Type__c = :CSAInq.Request_Type__c
                                              and Division__c = :CSAInq.Division__c
                                              and Branch_Number__c = :CSAInq.Branch_Number__c
                                              and Client_Number__c = :CSAInq.Client_Number__c
                                              and Product_Picklist__c = :CSAInq.Product_Picklist__c
                                              and Commissionable_Month__c = :CSAInq.Commissionable_Month__c
                                              and Commissionable_Year__c = :CSAInq.Commissionable_Year__c];
    
          if (!cSAInqListDup.isEmpty()) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'Duplicate Referral - This record already exists for the current period.'));
                    return null;
          } 
       } //end if (CSAInq.Request_Type__c == 'INTERNAL REFERRALS')

                     
       Database.DMLOptions dmo = new Database.DMLOptions();
       dmo.assignmentRuleHeader.useDefaultRule= true;
       c.setOptions(dmo);
       try{
            if (CSAInq.case__c == null) {
               insert c;
            }   
            system.debug(' ***   FRL immediately AFTER inserting Case.id = '+ C.Id );
            CSAInq.case__c = c.Id;
       //try
            insert CSAInq;
       }
        catch(DMLException e){
            system.debug('testCheckForBadProductStartDate error:'+e);
            for (Integer i = 0; i < e.getNumDml(); i++) {
              ApexPages.Message csaMsg = new ApexPages.Message(ApexPages.Severity.Error,e.getDmlMessage(i));
              ApexPages.addMessage(csaMsg);
              return null;          
          }
        }      
       
       if (notCsaRole) {
       // setup CaseTeamMember
       CaseTeamMember caseMemb = new CaseTeamMember();
       //put CaseId into CaseMemb object
       caseMemb.ParentId = c.Id;
       //put userId into CaseMemb object
       caseMemb.MemberId = u.Id;
       // set Read Only case role.
       CaseTeamRole ctr = [Select id from CaseTeamRole where Name='Read Only'];
       //set TeamRoleId 
       // CaseMemb.TeamRoleId = '0B770000000Gmbv'; 
       caseMemb.TeamRoleId = ctr.Id;       
       insert caseMemb;
       }
       
         PageReference resultPage;
         
         if(UserInfo.getUiThemeDisplayed().startsWith('Theme4')) {
             resultPage = new PageReference('/lightning/page/home');
         }
         else {
             resultPage = (notCsaRole ? new PageReference('/home/home.jsp') : new ApexPages.StandardController(c).view());
         }
         
        //SPLIT OPPORTUNITY, INTERNAL REFERRALS, DISTRICT CREDIT REASSIGNMENT, and COMM/AUDIT requests return to form for multiple submissions
        if(CSAInq.Request_Type__c == 'SPLIT OPPORTUNITY' || CSAInq.Request_Type__c == 'INTERNAL REFERRALS' || CSAInq.Request_Type__c == 'DISTRICT CREDIT REASSIGNMENT' || CSAInq.Request_Type__c == 'REP TRANSFER_DIVISION/DISTRICT REASSIGNMENT')
        {
            resultPage = new PageReference('/apex/SubmitCSARequest');
        }
        else if (setupFound){
           if(CSAInqSetup.Allow_Attachment__c){
           resultPage = new PageReference('/apex/AttachmentUpload?parent=' + c.id + '&CSA='+(notCsaRole ? 'TRUE' : 'FALSE') + '&savedList=');
           }
       }
       
       System.debug('REDIRECT PAGE: ' + resultPage);
         
       resultPage.setRedirect(true);
       return resultPage ; 
    } // submit2
    
    public void searchUser()
    {
        results = new List<User>();
        if( searchString != null && searchString != '')//isActive != null &&
        {
            searchString = '%' + searchString + '%';
          results = [SELECT id,name,isActive,email,username,Person_ID_Number__c from user where (name like :searchString or username like :searchString ) ];
        }

    }
  
    //public Boolean salesRepAvailable{get;set;}
    //public Boolean splittingSalesRepAvailable{get;set;}

} // class SubmitCSAInquiries2