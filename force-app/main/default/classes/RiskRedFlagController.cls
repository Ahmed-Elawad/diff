/* 
 * Controller to handle a potential red flag event from an Account.
 *
 * History
 * -------
 * 02/22/2011 Dan Carmen        Created.
   10/26/2018 Dan Carmen        Increment API version - not sure that we actually need this anymore
   05/07/2020 Dan Carmen        Remove AccountHelper.getRecordType
   09/08/2021 Carrie Marciano	Commented out for Forseva uninstall
 */
public with sharing class RiskRedFlagController {
    public RiskRedFlagController(){}
/*
   public Account acct{get;set;}
    
   User curUser{get;set;}
   
   public Boolean hasAcct{
   	  get {return (acct != null); }
   } // hasAcct
   
   public RiskRedFlagController(ApexPages.StandardController stdController) {
   	  curUser = [Select Id, Name, Sales_Org__c from User where Id=:UserInfo.getUserId()];
   	  
   	  String acctId = System.currentPageReference().getParameters().get('Id');
   	  if (acctId != null) {
   	  	 try {
            acct = [Select Id, Name from Account where Id = :acctId];
   	  	 } catch (Exception e) {
   	  	 	
   	  	 }
   	  } // if (acctId != null
   	  setFlags();
   } // RiskRedFlagController
   
   List<Risk_Red_Flag__c> flags{get;private set;}
   
   private void setFlags() {
   	  if (flags == null) {
   	  	 flags = new List<Risk_Red_Flag__c>([Select Id
   	  	                                           ,Name
   	  	                                           ,Start_Date__c
   	  	                                           ,End_Date__c
   	  	                                           ,Sort_Order__c
   	  	                                           ,Description__c
   	  	                                       From Risk_Red_Flag__c
   	  	                                      where Start_Date__c <= :Date.Today() 
   	  	                                        and End_Date__c >= :Date.Today()
   	  	                                      order by Sort_Order__c]);
   	     displayFlags = new List<FlagSelected>();
   	     for (Risk_Red_Flag__c rrf : flags) {
   	     	displayFlags.add(new FlagSelected(rrf,false));
   	     } // for
   	  } // if (flags == null
   } // setFlags
   
   public List<FlagSelected> displayFlags{get;set;}
   
   /** Custom class to keep track of which ones are selected/
  
   public class FlagSelected {
   	  /** Is this checked?
   	  public Boolean checked{get; set;} 
   	  
   	  public Risk_Red_Flag__c flag{get; set;}
   	  
   	  public FlagSelected(Risk_Red_Flag__c p_flag, Boolean p_checked) {
   	     flag = p_flag;
   	     checked = p_checked;
   	  } // Fl
   } // class FlagSelected
   
   /** Save the Risk request.
 
   public PageReference saveRequest() {
   	  // make sure at least one record is checked
   	  if (verifyChecked()) {
   	  	 // record type for the case
         Schema.RecordTypeInfo rtInfo = RecordTypeHelper.getRecordType('Credit Risk Audit Case', 'Case');
         // create a case
         Case c = new Case(RecordTypeId = rtInfo.getRecordTypeId()
                          ,AccountId = acct.Id
                          ,Type='Escalation'
                          ,Origin='Red Flag'
                          ,Priority='High' 
                          ,Status='New' 
                          ,Current_Step__c='Case Creation' 
                          ,User__c=curUser.Id 
                          ,Subject='Red Flag Escalaton - '+curUser.Sales_Org__c 
                          );
         Database.DMLOptions dmo = new Database.DMLOptions();
         dmo.assignmentRuleHeader.useDefaultRule=true;
         c.setOptions(dmo);
         
         insert c;
         // the case creation should trigger the creation of the reference object.
         // select the reference object
         Reference_Credit_Risk__c rcr = [Select Id from Reference_Credit_Risk__c where Case__c = :c.Id];
         // update the fields  
         rcr.Type__c='Red Flag Escalation';
         // default to blank 
         rcr.Red_Flag_Reason__c = '';
         
         // setup link objects
         Risk_Red_Flag_Link__c[] links = new Risk_Red_Flag_Link__c[]{};
         for (FlagSelected fs : displayFlags) {
            if (fs.checked) {
               Risk_Red_Flag_Link__c link = new Risk_Red_Flag_Link__c();
               link.Reference_Credit_Risk__c = rcr.Id;
               link.Risk_Red_Flag__c = fs.Flag.Id;
               rcr.Red_Flag_Reason__c += fs.Flag.Description__c+' ';
               links.add(link);
            }
         } // for (FlagSelected

         rcr.Red_Flag_Reason__c += addInfo;
         update rcr;

         if (!links.isEmpty()) {
            insert links;
         }
         // return to the Account
         PageReference acctPage = new PageReference('/'+acct.id);
         acctPage.setRedirect(true);
         return acctPage;
   	  } // if (verifyChecked
   	  return null;
   } // saveRequest
   
   /** Verify that at least one reason is checked.
  
   private Boolean verifyChecked() {
   	  Boolean checked = false;
   	  for (FlagSelected fs : displayFlags) {
   	  	 if (fs.checked) {
   	  	    checked = true;
   	  	    break;
   	  	 }
   	  } // for (FlagSelected
   	  if (!checked) {
         ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'At least one reason must be selected to proceed!'));
   	  }
   	  return checked;
   } // verifyChecked
   
   /** Additional Information.
   public String addInfo{get; set;}
   
   /** Cancel the operation - return to original record.

   public PageReference cancel() {
      PageReference pr= new PageReference('/'+acct.Id);
      return pr;
   } // cancel

*/
} // class RiskRedFlagController