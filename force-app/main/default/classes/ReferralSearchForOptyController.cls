/*
 * accessed from Search for Opportunity button on Referral page layout
 * if duplicate selling opty is found, user may replace Selling opty on Referral rcd
 * -get all optys for that p-c - (same sales org? timeframe=3 months)
 * -display all optys, mark the one already linked to referral
 * -check other referrals and exclude optys already linked to referral
 * -if select an opty, change referral selling opty to new one, update status on orig opty to "dup" or something
 *
 * History
 * ---------
 * 10/6/2015    Cindy Freeman   created
 *
 */

public without sharing class ReferralSearchForOptyController {
  
    private Id refId = null;
    public Referral__c ref{get; set;}

    public class oppWrap {
        public Opportunity opp {get; set;}
        public Boolean selected {get; set;}
    }   
    public List<oppWrap> oppWrapList {get; set;}
        
    // list of all referrals with same sales org so dont relink selling opty to multiple referrals 
    public List<Referral__c> allRefList;
    
    public Boolean selectAll {get;set;}
    public String sectionHeaderSubTitle {get; set;}
    
    public Boolean allDone {get; set;}      // true when referral has been successfully updated with new selling opty 
    
    /* constructor */
    public ReferralSearchForOptyController(){       
         
        refId = System.currentPageReference().getParameters().get('id');
        if (refId == null) 
        {       ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'Missing Referral Id.  Did you click the button on the referral record to get here?'));    }
        else
        {       // get referral info
                getReferral(refId);      
               // get all referrals with same sales org                        
                getallRefList();
                // get any other optys                              
                getOppWrapList();
                selectAll = false;  
                allDone = false;                
            sectionHeaderSubTitle = 'Search for Duplicate Opportunity';
        }
                    
    } // constructor
    
    /* confirm and update referral linkage
     * */
    public PageReference submit() {
        // update referral with new selling opty info
        // update old selling opty status
        // refresh page (new info on top), add back to referral button
        Opportunity selectedOpp;
        
        Integer selectedCnt = 0;
        for (oppWrap ow: oppWrapList)
        {   if (ow.selected)
            {   selectedCnt +=1;    
                selectedOpp = ow.opp;
            }
        } // for

        if (selectedCnt != 1)
        {   ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'Only 1 opportunity can be selected!'));
            return null;
        }
        if (selectedOpp != null && selectedOpp.Id == ref.Selling_Opportunity__r.Id)
        {   ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'If you are not changing the opportunity, just hit Cancel.'));
            return null;            
        }    
        unlockRef(); 
        Opportunity originalOpp;
        if (ref.Selling_Opportunity__c != null)
        {       originalOpp = [Select Id, StageName, Owner.Id from Opportunity where Id = :ref.Selling_Opportunity__c]; }
    
        ref.Status__c = 'Approved';
        ref.Selling_Opportunity__c = selectedOpp.Id;
        ref.User__c = selectedOpp.OwnerId;
        ref.DSA__c = selectedOpp.Owner.DSA_FSS__r.Id;
        ref.DSM__c = selectedOpp.Owner.ManagerId;
        ref.HR_Person_Id__c = selectedOpp.Owner.HR_Person_Id__c;        
        update ref;

        if (originalOpp != null)              
        {       originalOpp.StageName = 'Referral Duplicate';
                update originalOpp;          
        }
        getReferral(refId);
        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'Referral updated and linked to new opportunity'));       
        allDone = true;
        // lock referral so noone can edit it
        Approval.LockResult lr = Approval.lock(ref, true);
    	if (!lr.isSuccess()) 
        {  ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'Record lock failed. Please open an AskIT ticket including this referral record name.'));	}
        return null;
    } // submit
 
    /* dont change anything, go back to Referral screen
     */
    public PageReference cancel() {
        PageReference returnPr = null;
        try {
             returnPr = new PageReference('/'+(ref.Id != null ? ref.Id : ''));
        } catch (Exception e) {
        // in case returnId isn't a valid id.
        returnPr = new PageReference('/');
        }
        returnPr.setRedirect(true);             
        return returnPr;
   } // cancel
    
   /* pull referral info
    * */
    private void getReferral(Id p_refId) {
                ref = [Select Id, Name, Account__c, Account__r.Id, Account__r.Name
                                ,Referring_Opportunity__r.Id 
                                ,Selling_Opportunity__c
                                ,Selling_Opportunity__r.Name
                                ,Selling_Opportunity__r.Id
                                ,Selling_Opportunity__r.RecordType.Name
                                ,Selling_Opportunity__r.StageName
                                ,Selling_Opportunity__r.CloseDate
                                ,Selling_Opportunity__r.Payroll_Platform__c
                                ,Referral_Partner__r.Name
                                ,Referring_User__c
                                ,User__c
                                ,User__r.Id
                                ,DSA__c
                                ,DSM__c
                                ,HR_Person_Id__c
                                ,SourceContact__r.Name
                                ,ReferralJoin__c
                                ,Commission_Products__c
                                ,Status__c
                                From Referral__c where id = :p_refId];
        return;       
    } // getReferral
        
    /* pull info for all other referrals with same sales org
     */
        private void getallRefList() {
            allRefList = [Select Id, Name, Account__r.Id, Account__r.Name
                                ,Referring_Opportunity__r.Id
                                ,Selling_Opportunity__r.Name
                                ,Selling_Opportunity__r.Id
                                ,Selling_Opportunity__r.RecordType.Name
                                ,Selling_Opportunity__r.StageName
                                ,Selling_Opportunity__r.CloseDate
                                ,Referral_Partner__r.Name
                                ,Referring_User__c
                                ,User__c   
                                ,DSA__c
                                ,DSM__c
                                ,HR_Person_Id__c                      
                                ,SourceContact__r.Name
                                ,ReferralJoin__c
                                ,Commission_Products__c
                                ,Status__c
                                From Referral__c 
                                where Account__r.Id = :ref.Account__r.Id and Referral_Partner__r.Name = :ref.Referral_Partner__r.Name
                                and Selling_Opportunity__c != null and CreatedDate = LAST_90_DAYS];
            return;
        } // getallRefList   
        
      /* pull all optys
       */  
        private void getoppWrapList() {
            Set<Id> optyAlreadyReferred = new Set<Id>();
            for (Referral__c ref: allRefList)
            {   optyAlreadyReferred.add(ref.Selling_Opportunity__r.Id);         }
            List<opportunity> oppList = [Select Id,Name
                                    ,RecordTypeId
                                    ,RecordType.Name
                                    ,StageName
                                    ,LeadSource
                                    ,CloseDate
                                    ,CreatedDate
                                    ,Payroll_Unit__c
                                    ,Payroll_Platform__c
                                    ,Owner.Id
                                    ,Owner.Name 
                                    ,Owner.DSA_FSS__c
                                    ,Owner.DSA_FSS__r.Id
                                    ,Owner.ManagerId
                                    ,Owner.HR_Person_Id__c
                                    from Opportunity where Id = :ref.Selling_Opportunity__r.Id
                                    or (Account.Id = :ref.Account__r.Id
                                    	and StageName != 'Referred'
                                    	and CreatedDate = LAST_90_DAYS
                                    	and Payroll_Platform__c = :ref.Selling_Opportunity__r.Payroll_Platform__c)];
                                    	//and Payroll_Platform__c = :ref.Referral_Partner__r.Name];                                
                oppWrapList = new List<oppWrap>(); 
          
                for (Opportunity opp: oppList)
                {   if (opp.Id == ref.Selling_Opportunity__r.Id || !optyAlreadyReferred.contains(opp.Id))
                    {       oppWrap ow = new oppWrap();
                            ow.opp = opp;           
                            ow.selected = (opp.Id == ref.Selling_Opportunity__r.Id ? true : false);         
                            oppWrapList.add(ow);
                    } // if !contains
                } // for
            
            return;            
        } // getoppWrapList
    
    /* unlock the Referral record so we can edit it
     */
    private void unlockRef() {
        // unlock referral so DSAs can edit it  
        // Boolean ans = Approval.isLocked(ref.Id);
        Approval.UnLockResult lr = Approval.unlock(ref, true);	        
        if (!lr.isSuccess()) 
        {  ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'Record unlock failed. Please open an AskIT ticket including this referral record name.'));	}	
        return;

    } // unlockRef
    
}