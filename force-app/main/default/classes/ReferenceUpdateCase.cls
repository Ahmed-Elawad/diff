/* 
   Update the Case object from one of the reference objects.
   
  History
  -------
  08/05/2010 Dan Carmen         Created
  02/21/2011 Dan Carmen         Added the Credit Risk object
  03/02/2011 Dan Carmen/Michelle Brown   Added the Client Relation object
  03/27/2012 Carrie Marciano    changed HRO NCT to HRO LCT
  06/29/2012 Justin Stouffer    Added functionality to change the Record Type of the Reference_TAA__c Object
  01/16/2012 Justin Stouffer    Added Service Onboarding PEM Record Type
  03/06/2013 Josh Cartwright    Added payroll fullfillment object
  03/06/2013 Josh Cartwright    Added Terms/Transfers Object
  5/21/2013  Carrie Marciano    Updated 401k/S125 to use Onboarding Complete
  07/02/2013 Josh Cartwright    Added MSP
  08/02/2013 Justin Henderson   Added SEBS/ePlan/RRS to 401k/S125 Section 
  09/16/2013 Justin Henderson   Added ASO 
  09/29/2013 Cindy Freeman      Changed to public without sharing to give everyone permission to update reference and related objects 
  09/29/2013 Cindy Freeman      Added functionality to change Owner, Current_Step and Status from Reference_MMS_Payroll__c 
  12/31/2013 Josh Cartwright    Added Reference CA HRO Onboarding  
  01/07/2014 Josh Cartwright    Added reference hnbf
  03/10/2014 Justin henderson   Removed call to update opportunity status for MMS
  01/20/2015 Justin Henderson   Added ESR Onboarding
  02/02/2015 Justin Henderson   Updated ESR Current Step Values
  04/22/2015 Jacob Hinds        Changed case status field update from "Solved" to "Follow Up with Client" for GL Onboarding
  08/04/2015 Frank Lurz         Added the updateCaseStatus method, for updating the Case Status via the Reference PEO No Start object
  10/29/2015 Jacob Hinds        Added caseOwnerUpdate method and Reference Incoming Funds values for 401k Operations Support
  02/05/2016 Josh Cartwright    per case:20232252 removed 401k steps from updating case to solved 
  03/11/2016 Lynn Michels       create related Support case for Service STM Onboarding when Ref TAA is Client Gradutated
  05/25/2016 Josh Cartwright    updated code was showing a special character instead of - in some lines
  06/15/2016 Lynn Michels       added code to set status for Service Onboarding MPSC Core Payroll Case 
  06/16/2016 Jacob Hinds        Removing ESR from Case Status Update
  07/27/2016 Jacob Hinds        Readding ESR to Case Status Update
  11/09/2016 Jacob Hinds        Adding MPSC Reload
  12/08/2016 Jacob Hinds        Adding MPSC Exception
  06/21/2017 Sunnish Annu       Added code to update the STM case creation subject and Owner
  07/13/2018 Lynn Michels		Set current step for Service Onboarding P&C Case RT
  09/05/2018 Lynn Michels		Added current step value for 401k/s125 cases
  09/22/2018 Jermaine Stukes	Updated Reference TAA case logic to suppress creation for MPSC, Case#24914212
  11/27/2018 Cindy Freeman		fix bug if account number is blank for Service Onboarding STM case record type
  04/09/2020 Dan Carmen         Remove a call to AccountHelper to get RecordType info.
  09/01/2021 Carrie Marciano  Removed the Credit Risk object due to uninstalling Equifax package
  1/12/2023 Susmitha Somavarapu APR0143795-ATC Case to allow for HNBF Enrollments
  04/12/2023 Chris Santoro		Added current step for Service Support Client Retention record type 
  05/17/2023 Eric Porter      Added in code to handle RCP case management
  04/05/2024 Eric Porter      Updated Related STM Case to Status Solved as per APR0167743
  04/10/2024  Carrie Marciano    Removed code related to old MPSC Process
  04/22/2024 Eric Porter      Updated Case Status for STM Onboarding 
 */
public without sharing class ReferenceUpdateCase {
   
   /**  Update the current step field on the case object when it has been updated on the Reference TAA
    *   object and the Case lookup is not null.
    */
    //Map of Case and current Step
   public static void updateCaseStep(Map<Id,String> caseStepMap) {

      //get the cases linked to the reference objects that were updated
      List<Case> cases = new List<Case>([Select Id, Current_Step__c
                                                   ,Reassign_Category_1__c 
                                                   ,Status
                                                   ,AccountId
                                         		   ,Account.AccountNumber
                                                   ,ContactId
                                                   ,RecordType.Name
                                                   ,OwnerId
                                                   ,Product__c
                                               from Case 
                                              where Id in :caseStepMap.keySet()]);
      List<Case> casesToUpdate = new List<Case>();
      List<Case> casesToInsert = new List<Case>();
      
      for (Case c : cases) {
        //get the current step of the reference TAA attached to the case 
         String step = caseStepMap.get(c.Id);
         if (step != null) {
            c.Current_Step__c = step;  //set the current step on the case to match the reference TAA
            casesToUpdate.add(c);  //update case
            if (c.RecordType.Name.startsWith('Service Onboarding TAA')) { 
               // TAA records
               if (step == 'Client Graduated') {
                  // mark current case as solved
                  c.Status = 'Solved';
                  // Updates the record type of the Reference TAA Object to support
                  List<Reference_TAA__c> rTAAList = [Select Id, RecordType.Id From Reference_TAA__c
                                                        Where Case_Lookup__c = :c.Id];
                  If(rTAAList.size() == 1){
                      Reference_TAA__c rTAA = rTAAList.get(0);
                      if (rTAA.RecordTypeId != RecordTypeHelper.getRecordType('Reference TAA Support Record Type', 
                                                                                'Reference_TAA__c').getRecordTypeID()){
                             rTAA.RecordTypeId = RecordTypeHelper.getRecordType('Reference TAA Support Record Type', 
                                                                            'Reference_TAA__c').getRecordTypeID();
                      update rTAA;
                      }
                  }
                  // TAA creates a new Case when onboarding case is solved.
                  createTAACase(casesToInsert,c);
               } // if (step == 'Client Graduated
            } 
            //For Service Onboarding P&C Cases
            else if (c.RecordType.Name.startsWith('Service Onboarding P&C')) { 
            	if (step == 'Completed') {
                  // mark current case as solved
                  c.Status = 'Completed';
            	}//end if
            	else if (step == 'Cancelled') {
                  c.Status = 'Cancelled';
            	}//end if
            }//end else if
            
            //LM added - for Service STM Onboarding
            else if (c.RecordType.Name.startsWith('Service Onboarding STM'))
            { 
                String kaseBranch = (c.Account.AccountNumber == Null ? Null : c.Account.AccountNumber.substringBefore('-'));
                List<String> mpscList = label.MPSC_Locations.split(',');
               // TAA records
               if (step == 'Client Graduated')
               {
                  // mark current case as solved
                  c.Status = 'Solved';
                
                  //create a new, related STM Support Case when onboarding case is solved.
                  List<Reference_TAA__c> refTAAList = [Select Id, RecordType.Id From Reference_TAA__c
                                                        Where Case_Lookup__c = :c.Id];
                  if(refTAAList.size() == 1 && !mpscList.contains(kaseBranch))
                  {
                      Reference_TAA__c refTAA = refTAAList.get(0); 
                      //createSTMCase(casesToInsert, c, refTAA);
                  }                                    
               } // if (step == 'Client Graduated
            }
            
            else if (c.RecordType.Name.startsWith('Service Onboarding HRO') ||
                       c.RecordType.Name.startsWith('Service Onboarding EAO') || 
                       c.RecordType.Name.startsWith('Service Onboarding W2')  || 
                       c.RecordType.Name.startsWith('Service Additional HRO') ||
                       c.RecordType.Name.startsWith('Service Onboarding MSP') ||
                       c.RecordType.Name.startsWith('Service Onboarding CA HRO Record Type') ||
                       c.RecordType.Name.startsWith('Service Onboarding PEM')) {                       
               // HRO records
               if (step == 'Onboarding Complete') {
                  c.Status = 'Completed';
               } else if (step == 'Client Unresponsive') {
                  c.Status = 'Client Unresponsive';
               } else if (step == 'Refused' && 
                           !c.RecordType.Name.startsWith('Service Onboarding PEM') &&
                           !c.RecordType.Name.startsWith('Service Onboarding CA HRO Record Type') &&                          
                           !c.RecordType.Name.startsWith('Service Onboarding HRO')) {                  
                  c.Status = 'Refused';
               } else if (step == 'Lost Client' && 
                           c.RecordType.Name.startsWith('Service Onboarding MSP'))
                            {                  
                  c.Status = 'Lost Client';                  
               } else if (step == 'LCT Complete') {
                  c.Status = 'LCT Complete';
               }
            } else if (c.RecordType.Name.startsWith('Service Onboarding 401k') ||
                       c.RecordType.Name.startsWith('Service Onboarding S125')||
                       c.RecordType.Name.startsWith('Service Onboarding SEBS')||
                       c.RecordType.Name.startsWith('Service Onboarding RRS')||
                       c.RecordType.Name.startsWith('Service Onboarding ePlan')||
                       c.RecordType.Name.startsWith('Service Onboarding ASO New Business')) {
               // 401k-S125 records
               if ((step == 'Onboarding Complete') || 
                   (step == '(4 of 4) Onboarding Complete')||
                   (step == 'Lost During Onboarding') ||
                   (step == 'No Assets/No Contact'))
 // jc 2/5/16                   (step == '(8 of 8) Conversion Complete')||
 // jc 2/5/16                  (step == '(4 of 4) Conversion Complete')||
 // jc 2/5/16                  (step == 'Setup Complete')
                   {
                  // mark current case as solved
                  c.Status = 'Solved';
               } // if ((step == 'Onboarding Complete
               
            } else if (c.RecordType.Name.startsWith('Service Onboarding GL')) {
               if (step == 'Set Up Complete') {
                  c.Status = 'Follow Up With Client';
               }
            } else if (c.RecordType.Name.startsWith('Service Onboarding Core Payroll')) {
               if (
                   (step == 'Client Never Ran')|| (step == 'Onboarding Complete')) {
                  c.Status = 'Completed';
                  }
                  //03.21.2023 ECP New SMB RCP Status handling for new Insite step values
               if(step =='Case Creation'){
                  c.Status = 'New';
               }
               if(step == 'Client Received'
               || step == 'Client Received/Missing Information'
               || step == 'Client Assigned to IS'
               || step == 'Welcome Email Complete'
               || step == 'Welcome Call Complete'
               || step == 'Ready to Run First Payroll'
               || step == 'First Payroll Processed'){
                  c.Status='In Progress';
               }
               if(step =='Lost Client'){
                  c.Status='Lost Client';
                  //close out case if possible 
               }
               if(step =='Completed'){
                  c.Status = 'Completed';
               }
               //End Changes - ECP- 
                  
            } else if (c.RecordType.Name == 'Service Onboarding HNBF Case Record Type') {
               if (step == 'Onboarding Complete') {
                  c.Status = 'Closed';
                  }
            } else if (c.RecordType.Name == 'Service Onboarding ESR Case') {
               if (step == '2 - Case being Reviewed/Scrubbed') {
                  c.Status = 'In Progress';
                  }
               else if(step=='Onboarding Complete'){
                   c.Status = 'Completed';
               }
            } else if (c.RecordType.Name.startsWith('401k/S125 Operations Support')) {
               // 401k/S125 Operations Support Records
               if ((step == 'Closed – Paperwork Discrepancy Never Resolved') || 
                   (step == 'Term/Transfer Stopped') ||
                   (step == '401(k) Termination Complete') ||
                   (step == 'S125 FSA Termination Complete' )||
                   (step == 'S125 FSA Termination Complete - POP Downgrade Complete')||
                   (step == 'S125 FSA Termination Cancelled - Client Saved')||
                   (step == 'NSF Closed')||
                   (step == '401k Transfer Complete')||                   
                   (step == 'S125 POP Termination Complete') ||
                   (step == 'Completed') ||
                   (step == 'Complete') ||
                   (step == 'Closed - NSF Unresolved') ||
                   (step == 'Returned - Not Processed')) {
                  // mark current case as solved
                  c.Status = 'Solved'; 
                }
                 else if (step == 'In Process'){
                  c.Status = 'New';
                }
                else if (step == 'Open Discrepancy'){
                  c.Status = 'Unresolved Research';
                }
            } else if (c.RecordType.Name.startsWith('Service Onboarding Payroll Fulfillment')) {
               // Payroll Fulfillment Records
               if ((step == '(6 of 6) Final Verification/ Released/ Processed')||
                   (step == 'Closed â€“ Client Never Started')||
                   (step == 'Closed â€“ Client NSF')||
                   (step == 'Closed â€“ Other')|| 
                   (step == 'Lost During Onboarding')) {
                  // mark current case as solved
                  c.Status = 'Solved';      
                        
               } // if ((step == '(4 of 4)               
            } // if (c.RecordType.Name
            //else if (c.RecordType.Name.startsWith('Service Onboarding MPSC Core Payroll Case')||c.RecordType.Name.startsWith('MPSC Reload')) {
            else if (c.RecordType.Name.startsWith('Service Onboarding MPSC Core Payroll Case')) {    
               if (step == 'Client Never Ran') {
                  c.Status = 'Lost Client';
                  }
               else if(step=='On Hold'){
                  c.Status = 'In Progress - Client Delay';
               }
               else if(step=='Lost During Onboarding'){
                  c.Status = 'Lost Client';
               }
            }
            
            /*else if (c.RecordType.Name.startsWith('MPSC Exception')) {
               if (step == '(1 of 3) Submitted - Waiting on DSM') {
                  c.Status = 'Waiting on Sales';
                  }
               else if(step=='(2 of 3) DSM Approved - Waiting on Ops'){
                  c.Status = 'Waiting on Ops';
               }
               else if(step=='(3 of 3) Approved'){
                  c.Status = 'Completed';
               }
               else if(step=='Rejected'){
                  c.Status = 'Refused';
               }
            } */
            else if (c.RecordType.Name.startsWith('Service Support Client Retention')) 
             {
                 System.Debug('DEBUG --- Service Support Client Retention recordtype found');
                 List<String> statusList = label.Client_Retention_Status.split(',');
                 if (statusList.contains(step))
                 {
                     c.Status = 'Closed';
                     System.Debug('DEBUG --- Closed (Closed) status set');
                 }
                 else
                 {
                     c.Status = 'In Progress';
                     System.Debug('DEBUG --- In Progress status set');
                 }
             }
             
         } // if (step != null
      } // for (Reference_TAA__c
      if (!casesToUpdate.isEmpty()) {
         update casesToUpdate;
      }
      if (!casesToInsert.isEmpty()) {
         insert casesToInsert;
      }
      
   } // updateCaseStep
   
   //added LM
   private static void createSTMCase(List<Case> casesToInsert, Case c, Reference_TAA__c refTAA)
   {
  system.debug('LM create STM case' + c.OwnerId);
        String str;
        User UnassignedcoreUsr=[Select Id From User Where Name Like '%Unassigned Core%'];
       If(c.Product__c==Null){
           str='STM';
               } 
       else{str=c.Product__c;}
        Id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Service Support STM Case').getRecordTypeId();
        Case newCase = new Case(RecordTypeId = recordTypeId,
                                        AccountId = c.AccountId,
                                        ContactId = c.ContactId,
                                        Subject = 'Subject '+str+ ' Onboarding Complete - Graduated to Support',
                                        Status = 'Solved',
                                        Product__c = 'STM',
                                        Call_Out_Required__c = 'Yes',
                                        ParentId = c.id,
                                        //OwnerId = c.OwnerId
                                        OwnerId=UnassignedcoreUsr.Id);
                casesToInsert.add(newCase);
   }// end createSTMCase

   private static void createTAACase(List<Case> casesToInsert, Case c) {//Select (Select Id, RecordTypeId From Reference_TAAs__r) From Case c
      
      casesToInsert.add(createNewCase(c,'Service Support TAA Case'
                                     ,'TLO Onboarding Complete - Graduate to Support'
                                     ,'TLO'));
   } // createTAACase
   
   private static Case createNewCase(Case c, String recordTypeName, String subject
                                    ,String product) {
      Schema.RecordTypeInfo rtInfo = Schema.SObjectType.Case.getRecordTypeInfosByName().get(recordTypeName);

      Case newC = new Case(RecordTypeId = (rtInfo != null ? rtInfo.getRecordTypeId() : null)
                          ,AccountId = c.AccountId
                          ,ContactId = c.ContactId
                          ,ParentId = c.Id
                          ,Subject = subject
                          ,Status = 'New'
                          ,Product__c = product
                          ,Reassign_Category_1__c = c.Reassign_Category_1__c
                          ,TAA_Category_1__c = 'Graduated'
                          ,Call_Out_Required__c='Yes'
                          ,Follow_Up_Date__c = Utilities.getNextBusinessDay(5)
                           );
      return newC;  
   } // createNewCase
   
   /** Process the MMS Onboarding Reference objects - Update the opportunity from the reference object
    */   
   /*
    public static void updateMMSOpty(Reference_MMS_Payroll__c[] toUpdateSubmitted, Reference_MMS_Payroll__c[] toUpdateStarted) { 
      Map<Id,String> opptyIds = new Map<Id, String>();
      Schema.RecordTypeInfo rt = RecordTypeHelper.getRecordType('MMS Opportunity (DSA) Record Type', 'Opportunity');
      Id dsaRT = rt.getRecordTypeId();
            
      for (Reference_MMS_Payroll__c mms : toUpdateSubmitted) {
          if (mms.Date_Client_Load_Received__c != null 
                &&
               (mms.Current_Step__c != '(5 of 5) Transferred to Client Support' && mms.Current_Step__c != 'Client Never Ran'))
          {   opptyIds.put(mms.Opportunity_Name__c, 'Sold - Submitted');    }
      } // for

      for (Reference_MMS_Payroll__c mms : toUpdateStarted) {
          if (mms.First_Payroll_has_Run__c) 
          {   opptyIds.put(mms.Opportunity_Name__c, 'Sold - Started');  }
      } // for
         
      // select the opportunities
      Map<Id,Opportunity> opptys = new Map<Id,Opportunity>([Select Id
                                                         ,StageName
                                                         ,RecordTypeId
                                                     From Opportunity
                                                    where Id in :opptyIds.keySet()]);
      if (!opptys.isEmpty())                                          
      {   Opportunity[] updateOpptys = new Opportunity[]{};
          for (Id oId : opptyIds.keySet())
          {   Opportunity oppty = opptys.get(oId);
              if (oppty != null)
              {   oppty.StageName = opptyIds.get(oId);
                  if (oppty.StageName == 'Sold - Submitted')
                  {   //oppty.RecordTypeId = rt.getRecordTypeId();  
                      oppty.RecordTypeId = dsaRT;
                  }
                  updateOpptys.add(oppty);
              } // if oppty != null
          } // for mms      
          // save the update to the opportunities
          if (!updateOpptys.isEmpty()) 
          {   update updateOpptys;  }         
      } // !opptys.isEmpty
      
   } // updateMMSOpty
 */
       
   /** Update the Status field on the case object.  
    */
      public static void updateCaseStatus(Map<Id,String> caseStatusMap) {
      List<Case> cases = new List<Case>([Select Id, Current_Step__c
                                                   ,Reassign_Category_1__c 
                                                   ,Status
                                                   ,AccountId
                                                   ,ContactId
                                                   ,RecordType.Name
                                               from Case 
                                              where Id in :caseStatusMap.keySet()]);
      List<Case> casesToUpdate = new List<Case>();
      for (Case c : cases) {
         String status = caseStatusMap.get(c.Id);
         if (status != null) {
            c.Status = status;
            casesToUpdate.add(c);
         } // if (status != null
      } // for (Case c :
      if (!casesToUpdate.isEmpty()) {
         update casesToUpdate;
      }
      
   } // updateCaseStatus
   
   /** Update the Owner field on the case object.  
    */
      public static Boolean OWNER_CHANGE_WAS_PROCESSED = false;
      public static void updateCaseOwner(Map<Id,Id> caseOwnerMap) {
      List<Case> cases = new List<Case>([Select Id, Current_Step__c
                                                   ,Reassign_Category_1__c 
                                                   ,OwnerId
                                                   ,AccountId
                                                   ,ContactId
                                                   ,RecordType.Name
                                               from Case 
                                              where Id in :caseOwnerMap.keySet()]);
      List<Case> casesToUpdate = new List<Case>();
      for (Case c : cases) {
         String owner = caseOwnerMap.get(c.Id);
         if (owner != null) {
            c.OwnerId = owner;
            casesToUpdate.add(c);
         } // if (status != null
      } // for (Case c :
      if (!casesToUpdate.isEmpty()) {
         update casesToUpdate;
         OWNER_CHANGE_WAS_PROCESSED = true;
      }
      
   } // updateCaseStatus  
    //APR0143795
   public static  case updateCaseStatus(Reference_HNBF__c newRT){
      Case csretn; 
      if (newRT.Status__c == 'New' || newRT.Status__c == 'Pending' || newRT.Status__c == 'Sent' ) {	
         csretn = new Case(Id =newRT.Case_Number__c, Status = 'New' ); 	
     }	
     else if (newRT.Status__c == 'Closed' || newRT.Status__c == 'Rejected' ) {	
        csretn = new Case(Id =newRT.Case_Number__c, Status = 'Closed' ); 	
     }	
    return csretn; 
   }   //APR0143795     
   
} // ReferenceUpdateCase