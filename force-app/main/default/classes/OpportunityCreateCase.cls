/* 
 * When an opportunity is saved with a certain status, create a case and Reference object.
 *
 * History
 * -------
 * 06/28/2010 Dan Carmen      Created
 * 10/07/2010 Dan Carmen      Added logic to delete case and reference core payroll when
 *                               status changed from sold to pending or not sold.
   09/15/2011 Dan Carmen      Added logic for PEO
   10/31/2011 Dan Carmen      Added in check for PEO Service Center
   11/10/2011 Dan Carmen      Modified logic for when moved from Sold back to Pending or Not Sold.
   02/22/2012 Cindy Freeman   Added logic for Advisor Select
   05/22/2012 Dan Carmen      Added in logic for MMS record type selling core products
   12/21/2012 Dan Carmen      Modify code to simplify trigger.
   04/12/2013 Cindy Freeman   Added MMS Payroll to list of excluded service locations
   08/08/2013 Josh Cartwright Added all mms hubs to excluded service locations
   09/05/2013 Dan Carmen      Cleaned up code, added ASO changes
   09/12/2013 Dan Carmen      Added HNBF record types
   11/01/2013 Josh Cartwright Adding Sure Payroll as an excluded location
   09/14/2015 Cindy Freeman   Added HNBF values to SOLD_STATUS string for Hold Out expiration calc
   12/09/2015 Jacob Hinds     Changed hardcoded record type names to labels.
   02/19/2016 Lynn Michels    Added code check for already created Cases with RT Service Onboarding MPSC Core Payroll Case
   03/07/2017 Lynn Michels    change the evaluation the Opportunities that move to Not Sold or Pending
   01/28/2018 Frank Lurz      changes to split to the PEO-ASO Opportunities to ASO and PEO
   02/15/2018 Lynn Michels    add functionality to create benAdmin Cases from Sold Opps
   05/18/2018 Lynn Michels    add more criteria to the creation of benAdmin cases FTcase#28858177
   11/30/2020 Matt Fritschi   added Sold - Submitted to CTT to sold status list
   01/05/2020 Jake Hinds      changing processStageChangedFromSold to fire properly if already in future
   06/21/2023 Shilpa		  APR0151467: Added method processSendtoHBOpps to create Case, Reference Agency records when HNBF oppty moves to 70% and Send to H&B Implementation is Yes
   3/20/2024  Carrie Marciano    Removed code related to old MPSC Process
 *
 */
public without sharing class OpportunityCreateCase {
    
   public static final String RT_CASE_PEO = Label.PEO_New_Business_Case_Record_Type;
   public static final String RT_CASE_CORE = Label.Core_Payroll_Case_Record_Type;  //Service Onboarding Core Payroll Case
   public static final String RT_CASE_ADV = Label.Advisor_Select_New_Case_Record_Type;
   public static final String RT_CASE_ASO = Label.ASO_New_Business_Case_Record_Type;
   public static final String RT_CASE_MPSC = Label.MPSC_Core_Payroll_Case;  //Service Onboarding MPSC Core Payroll Case
   //public static final String RT_CASE_MPSCBenAdmin = Label.MPSC_BenAdmin_Case;
   public static final String RT_CASE_HNBF = 'Service Onboarding HNBF Case Record Type';
   
   public static final String[] CASE_RT_NAMES = new String[]{RT_CASE_PEO,RT_CASE_CORE,RT_CASE_ADV,RT_CASE_ASO,RT_CASE_MPSC};
   
   public static final String RT_OPPTY_CORE = Label.PAY_Opportunity_Record_Type;
   public static final String RT_OPPTY_CORE_DSA = Label.PAY_Opportunity_DSA_Record_Type;
   public static final String RT_OPPTY_MMS = Label.MMS_Opportunity_Record_Type;
   public static final String RT_OPPTY_MMS_DSA = Label.MMS_Opportunity_DSA_Record_Type;
   public static final String RT_OPPTY_PEO = Label.PEO_Opportunity_Record_Type;
   public static final String RT_OPPTY_PEO_FSS = Label.PEO_Opportunity_FSS_Record_Type;
   public static final String RT_OPPTY_ASO = Label.ASO_Opportunity_Record_Type;
   public static final String RT_OPPTY_ASO_FSS = Label.ASO_Opportunity_FSS_Record_Type;
   public static final String RT_OPPTY_401K_FSS = Label.HRS_Opportunity_FSS_Record_Type;
   public static final String RT_OPPTY_401K = Label.HRS_Opportunity_Record_Type;
   public static final String RT_OPPTY_HNBF = Label.HNBF_Opportunity_Record_Type;
   public static final String RT_OPPTY_HNBF_DSA = Label.HNBF_DSA_Opportunity_Record_Type;
         
   public static final String PEO_SERVICE_CENTER = 'PEO Service Center';
   public static final String ASO_SERVICE_CENTER = 'ASO Service Center';
   
   public static final String ADV_SERVICE_CENTER = 'Advisor Select/ePlan';   
   public static final String ADVFSA_SERVICE_CENTER = 'Advisor Select/ePlan + FSA';

   /** Service centers to exclude from case creation. */      
   public static Set<String> excludeServiceCenterSet = new Set<String>{
                'Advantage Corporate Operations 0610'
               ,'Advantage Operations Auburn 0611'
               ,'Advantage Operations Chicago 0613'
               ,'Advantage Operations Dallas 0621'
               ,'Advantage Operations Orange County 0616' 
               ,'Advantage Operations Providence 0609'
               ,'Advantage Operations Rock Hill 0614'
               ,'Advantage Operations San Leandro 0618'
               ,'Advantage Operations Sarasota 0619'
               ,'Small Biz East 0624'
               ,'Small Biz West 0625'
               ,'MMS Payroll'
               ,'Albany Hub 415'
               ,'Atlanta Hub 435'
               ,'Baltimore Hub 430'
               ,'Boston Hub 411'
               ,'Buffalo Hub 445'
               ,'Chicago Hub 405'
               ,'Columbus Hub 444'
               ,'Cuyahoga Valley Hub 447'
               ,'Dallas Hub 472'
               ,'Denver Hub 465'
               ,'Detroit Hub 450'
               ,'East Bay Hub 400'
               ,'Greensboro Hub 429'
               ,'Hartford Hub 414'
               ,'Houston Hub 470' 
               ,'Indianapolis Hub 451'
               ,'Inland Empire Hub 479'
               ,'Kansas City Hub 463'
               ,'Las Vegas Hub 477'
               ,'Long Island Hub 408'
               ,'Metro Hub 402'
               ,'Miami Hub 440'
               ,'Milwaukee Hub 454'
               ,'Minneapolis Hub 456'
               ,'Nashville Hub 434'
               ,'Northern NJ Hub 476'
               ,'Orange Cty Hub 480'
               ,'Orlando Hub 439'                
               ,'Philadelphia Hub 426'
               ,'Phoenix Hub 475'
               ,'Pittsburgh Hub 446'
               ,'Portland Hub 490'
               ,'Providence Hub 412'
               ,'Rochester Hub 407'                
               ,'Sacramento Hub 485'
               ,'San Diego Hub 482'
               ,'Seattle Hub 495'
               ,'St. Louis Hub 462'
               ,'Syracuse Hub 416'
               ,'Tampa Hub 441'
               ,'Ventura Hub 483'
               ,'SurePayroll'
   };
   
   /** The valid record type names. */
   public static Set<String> recordTypeNameSet = new Set<String>{
                RT_OPPTY_CORE,RT_OPPTY_CORE_DSA
               ,RT_OPPTY_MMS, RT_OPPTY_MMS_DSA
               ,RT_OPPTY_PEO,RT_OPPTY_ASO,RT_OPPTY_ASO_FSS
               ,RT_OPPTY_401K, RT_OPPTY_401K_FSS
               ,RT_OPPTY_HNBF//LM FBAE
   };

   // The sold statuses that trigger the case creation.
   //public static Set<String> SOLD_STATUS_SET = new Set<String>{Label.OppStage_Sold,'Sold:','Sold - Case Submitted to New Case','Sold - Submitted','Sold - Revenue Recognition','Sold - Submitted to CTT'};
   
   // The sold statuses that trigger possible deletion of case and reference Core payroll records for MPSC RT.
   //public static Set<String> SOLD_STATUS_SET_MPSC = new Set<String>{Label.OppStage_Sold,'Sold - Started','Sold - Submitted'};
   
   
   // When a status moves from sold back to either Pending or Not Sold - so we look to remove any case created against it.  
   //public static Set<String> NO_LONGER_SOLD_SET = new Set<String>{'Pending',Label.OppStage_Lost};
   
   // Process an Opportunity when the stage name changes to Sold.
   //@future
   public static void processOpptysSold(Id[] opptyIds) {
      system.debug('processOpptysSold IN' +opptyIds.size());
      // check for cases already created
      Case[] existingCases = getCases(opptyIds);

      // create a key set of existing records - [ID][Record Type Name]
      // so we don't create a case type if that case already exists      
      Set<String> foundKeys = new Set<String>();
      for (Case c : existingCases) {
         String key= c.Opportunity__c+c.RecordType.Name;
         System.debug('adding key:'+key);
         foundKeys.add(key);
      } // for
          
      // retrieve the opportunities
      List<Opportunity> opptys = new List<Opportunity>([Select Id, RecordType.Name
                                                                 ,AccountId
                                                                 ,Account.Medical__c
                                                                 ,Account.isChild__c
                                                                 ,Product_Summary__c
                                                                 ,Service_Location__c
                                                                 ,OwnerId
                                                                 ,CloseDate
                                                                 ,(Select Id, ContactId, OpportunityId, IsPrimary from OpportunityContactRoles
                                                                 // only need to get the first contact
                                                                    order by OpportunityId asc, IsPrimary desc limit 1)
                                                             from Opportunity
                                                            where Id in :opptyIds
                                                              and Service_Location__c != null
                                                              and Service_Location__c not in :excludeServiceCenterSet
                                                              and RecordType.Name in :recordTypeNameSet]);
                                                         
      // if no records returned do nothing.
      if (opptys.isEmpty()) {
         return;
      }

      // a collection for all of the cases
      List<Case> cases = new List<Case>();
    
      Database.DMLOptions dmo = new Database.DMLOptions();
      dmo.assignmentRuleHeader.useDefaultRule=true;
      
      
      Map<String,Schema.RecordTypeInfo> byName = new Map<String,Schema.RecordTypeInfo>();
      RecordTypeHelper.getRecordTypesMap(new String[]{'Case'},CASE_RT_NAMES,null,byName);

      Id coreCaseRtId = byName.get(RT_CASE_CORE).getRecordTypeId();
      Id peoCaseRtId = byName.get(RT_CASE_PEO).getRecordTypeId();
      Id advCaseRtId = byName.get(RT_CASE_ADV).getRecordTypeId();
      Id asoCaseRtId = byName.get(RT_CASE_ASO).getRecordTypeId();
      Id mspcCaseRtId = byName.get(RT_CASE_MPSC).getRecordTypeId();
      //Id mspcBenAdminCaseRtId = byName.get(RT_CASE_MPSCBenAdmin).getRecordTypeId();
      
      UserHelper uh = new UserHelper();
      for (Opportunity oppty : opptys) {
       
         Id ctctId = ((oppty.OpportunityContactRoles != null && oppty.OpportunityContactRoles.size() > 0) ? oppty.OpportunityContactRoles[0].ContactId : null);
     
         // create a Case object
         Case thisCase = new Case(ContactId = ctctId //opptyCtctMap.get(oppty.Id)
                             ,AccountId = oppty.AccountId
                             ,Service_Location__c = oppty.Service_Location__c
                             ,User__c = oppty.OwnerId
                             ,Opportunity__c = oppty.Id
                             );
         if (!Test.isRunningTest()) {
            thisCase.setOptions(dmo);
         }
        
         // for right now we are doing the same thing for core and mms opportunities
         if ((oppty.RecordType.Name == RT_OPPTY_CORE
              || oppty.RecordType.Name == RT_OPPTY_MMS
              || oppty.RecordType.Name == RT_OPPTY_MMS_DSA) 
             && oppty.Service_Location__c != null
             && !oppty.Service_Location__c.contains('MPSC')
             // make sure a case doesn't already exist with this record type
             && !foundKeys.contains(oppty.Id+RT_CASE_CORE)){
            // if core opportunity
            cases.add(thisCase);
            //ocs.add(oc);
            thisCase.RecordTypeId = coreCaseRtId;
            thisCase.Origin = 'New Business';
            Group que = uh.getQueue('Core Payroll NCS Queue');
            if (que != null) {
               thisCase.OwnerId = que.Id;
            }
         }
         else if ((oppty.RecordType.Name == RT_OPPTY_PEO) &&  
                    oppty.Service_Location__c != null && oppty.Service_Location__c == PEO_SERVICE_CENTER
                   // make sure a case doesn't already exist with this record type
                    && !foundKeys.contains(oppty.Id+RT_CASE_PEO)) {
            cases.add(thisCase);
            thisCase.Subject='PEO Onboarding';
            thisCase.Origin = 'Opportunity';
            thisCase.RecordTypeId = peoCaseRtId;
         } else if ((oppty.RecordType.Name == RT_OPPTY_ASO || oppty.RecordType.Name == RT_OPPTY_ASO_FSS) && 
                    oppty.Service_Location__c != null && oppty.Service_Location__c == ASO_SERVICE_CENTER
                   // make sure a case doesn't already exist with this record type
                    && !foundKeys.contains(oppty.Id+RT_CASE_ASO)) {
            cases.add(thisCase);
            thisCase.Subject='ASO Onboarding';
            thisCase.Origin = 'Opportunity';
            thisCase.RecordTypeId = asoCaseRtId;
         } else if ((oppty.RecordType.Name == RT_OPPTY_401K || oppty.RecordType.Name == RT_OPPTY_401K_FSS) && 
                   oppty.Service_Location__c != null && 
                   (oppty.Service_Location__c == ADV_SERVICE_CENTER || oppty.Service_Location__c == ADVFSA_SERVICE_CENTER)
                   // make sure a case doesn't already exist with this record type
                    && !foundKeys.contains(oppty.Id+RT_CASE_ADV)) {                      
            thisCase.Subject='Advisor Select Onboarding';
            thisCase.Origin = 'Opportunity';
            thisCase.Product__c = 'Advisor Select';
            if (advCaseRtId != null) {
               thisCase.RecordTypeId = advCaseRtId;
            }        
            cases.add(thisCase);
         }
         //if Oppty has FBAE product, Account is not a child, and does not already have a BenAdmin case 
         /*
        if(oppty.Product_Summary__c != null && oppty.Product_Summary__c.contains('FBAE') &&
            !foundKeys.contains(oppty.Id+RT_CASE_MPSCBenAdmin) && oppty.Account.isChild__c == false){
            system.debug('processOpptysSold isChild? '+oppty.Account.isChild__c); 
            //create a Case object with BenAdmin Record type
            //cannot use case created above because other record types are creating cases too and there may be duplicates
             Case benAdminCase = new Case(ContactId = ctctId
                                 ,AccountId = oppty.AccountId
                                 ,Service_Location__c = oppty.Service_Location__c
                                 ,User__c = oppty.OwnerId
                                 ,Opportunity__c = oppty.Id
                                 ,Origin = 'Opportunity'
                                 ,RecordTypeId = mspcBenAdminCaseRtId
                                 );
             //set to use Case Assignment Rules
             benAdminCase.setOptions(dmo);
            //if ASO, determine if client has Paychex H&B Service 
                system.debug('processOpptysSold oppty.Account.Medical__c '+oppty.Account.Medical__c);       
                //if ASO, and client has Paychex H&B Service (indicated by a check in the PAYX H&B (medical__c)field)
                //or HNBF   
                if((oppty.RecordType.Name == RT_OPPTY_ASO && oppty.Account.Medical__c) || oppty.RecordType.Name == RT_OPPTY_HNBF ){
                    cases.add(benAdminCase);
                    benAdminCase.Reason = 'H&B New Client'; 
                    benAdminCase.Subject = 'FBAE H&B New Client';
                }
                //if ASO, and client does not Paychex H&B Service
                //or MMS
                if ((oppty.RecordType.Name == RT_OPPTY_ASO && !oppty.Account.Medical__c) || oppty.RecordType.Name == RT_OPPTY_MMS){
                    cases.add(benAdminCase);
                    benAdminCase.Reason = 'MPSC New Client';
                    benAdminCase.Subject = 'FBAE MPSC New Client';
                }//end else
        }//end if Product summary
        */
        
      } // for (Opportunity
      if (!cases.isEmpty()) {
         insert cases;
         //reselectCases(cases,ocs);
      } // if (!cases.isEmpty
     
      
      // reselect cases to get new owners. Use new owners on Reference objects.
      
      //processRefObjects(ocs);
   } // processOpptys

   /** Get any cases attached to the Opportunities
    */
   private static Case[] getCases(Id[] opptyIds) {
      Case[] cases = [Select Id
                            ,Opportunity__c
                            ,RecordType.Name
                        From Case
                       Where Opportunity__c in :opptyIds
                         and RecordType.Name in :CASE_RT_NAMES];
      return cases;
   } // getCases
   
   /** If the stage is changed from Sold, Sold - Started, or Sold - Submitted, back to Pending or Not Sold (changed to sold by mistake)
    *  then check for the reference object and case. If they exist, delete them and send notification to owner
    *  of reference object.
    *  This code is only working for Core, MMS and MMS (DSA) Opportunity Record Types currently.
    */
   public static void processStageChangedFromSold(Id[] noLongerSoldOppIds) {
       if (System.isFuture() || System.isBatch() || Test.isRunningTest()) {
           processStageChangedFromSoldNow(noLongerSoldOppIds);
       }
       else{
           processStageChangedFromSoldFuture(noLongerSoldOppIds);
       }
   }
   
   @future
   public static void processStageChangedFromSoldFuture(Id[] noLongerSoldOppIds) {
        processStageChangedFromSoldNow(noLongerSoldOppIds);
   }    
   public static void processStageChangedFromSoldNow(Id[] noLongerSoldOppIds) {
   
      System.debug('processStageChangedFromSold opptyIds='+noLongerSoldOppIds);
      Id[] pendingOppIds = new Id[]{};
      Set<Id> notSoldOppIds = new Set<Id>();
      
      //only working for Core, MMS and MMS (DSA) Opportunity Record Types currently     
      String[] OPP_RT_NAMES = new String[]{RT_OPPTY_CORE, RT_OPPTY_MMS, RT_OPPTY_MMS_DSA};
      
      //LM if stage changes, send over the ids from OpptyAfter.trigger to process
      //query to get the opportunities
      List<Opportunity> oppsToProcess = [SELECT Id, RecordType.Name, StageName, isClosed, isWon, Probability FROM Opportunity
                                        WHERE Id IN: noLongerSoldOppIds
                                        AND RecordType.Name in :OPP_RT_NAMES];   
      for (Opportunity o : oppsToProcess){
        //if CORE 
        if(o.RecordType.Name == RT_OPPTY_CORE){
            //and if pending - get Case and RCP and delete them (this was the previous code)
            if(o.isClosed == false && o.Probability < 80){
                pendingOppIds.add(o.id);
            }//end if pending
            //if not Pending, then it is Not Sold but to make sure we are only taking in the Not Sold
            else if (o.isClosed && !o.isWon){
                notSoldOppIds.add(o.id);
            }//end else
        }//end if CORE
        //if MMS or MMS(DSA) and Not Sold, need to process
        else if((o.RecordType.Name == RT_OPPTY_MMS || o.RecordType.Name == RT_OPPTY_MMS_DSA) && o.isClosed && !o.isWon){
                notSoldOppIds.add(o.id);
        }//end if MMS or MMS(DSA)   
      }//end for oppsToProcess
      
      //this is the PROIR CODE that deletes Case and RCP if Core Opp goes from Sold to Not Sold
      if (!pendingOppIds.isEmpty()){
            //get the cases related to this opportunity
            Case[] cases = getCases(pendingOppIds);
            // do nothing more if no cases
            if (cases.isEmpty()) {
                return;
            }
            // delete the cases
            if (!cases.isEmpty()) {
                delete cases;
            }
            // delete any associated reference objects
            delete [Select Id from Reference_Core_Payroll__c where Opportunity_Lookup__c in :pendingOppIds];
    }//if pendingOpps is not empty
    
   List<Id> casesToDelete = new List<Id>();
   List<Reference_Core_Payroll__c> rcpToDelete = new List<Reference_Core_Payroll__c>();
    
    if(!notSoldOppIds.isEmpty()){
        //get RCP and evalulate them
        List<Reference_Core_Payroll__c> rcps = [SELECT Id, OwnerId, Case_Lookup__c, Current_Step__c, RecordType.Name FROM Reference_Core_Payroll__c
                                                WHERE Opportunity_Lookup__c IN: notSoldOppIds
                                                AND RecordType.Name =: 'Reference MPSC Onboarding Core Payroll'];
        for(Reference_Core_Payroll__c r: rcps){
            //if rcp is still in Case Creation, it has not been worked yet and can be deleted.
            if (r.Current_Step__c == 'Case Creation'){
                //collect case ids and rcp ids to delete
                casesToDelete.add(r.Case_Lookup__c);
                rcpToDelete.add(r);
            }//end Case Creation
            //for any other current step, send chatter notification
            else{
                String owner = String.valueof(r.OwnerId);
                String[] chatterBody = new String[]{}; 
                List<id> mentionList = new List<id>();
                List<CollaborationGroup> queueId = [SELECT Id FROM CollaborationGroup where Name = 'Not Sold Status Group'];

                //if the owner is a queue, send notification to Not Sold Status Group  
                if (owner.startsWith('00G')){mentionList.add(queueId[0].id);
                    chatterBody.add('This client was set to Not Sold, please delete the Case and this Reference Core Payroll record.');
                }//end if queue
                //if owner is a user, send notification to that user
                if (owner.startsWith('005')){
                    mentionList.add(r.ownerid);
                    chatterBody.add('Sales has moved this client to Not Sold. Please check with your sales partner; this record may need to be moved to Client Never Ran.');
                }//end if user
                
                ChatterMentionPost.createChatterMentionPost(r.Id, mentionList, chatterBody, true,false);
            }//end else
        }//end for 
        
        chatterMentionPost.postBatchFeedElements();
        
        if(!casesToDelete.isEmpty()){
            delete [SELECT Id FROM Case WHERE Id IN :casesToDelete];
        }
        if(!rcpToDelete.isEmpty()){
            delete rcpToDelete;
        }
    }//end notSoldOppIds        
    
   } // processStageChangedFromSold
    
    //APR0151467: Added method to create Case, Reference Agency records when HNBF oppty moves to 70% and Send to H&B Implementation is Yes
    public static void processSendtoHBOpps(Map<Id,Opportunity> sendtoHBMap){
        List<Case> newCases = new List<Case>();
        Set<Id> newCaseIds = new Set<Id>();
        List<Reference_HNBF__c> newRefHNBFs = new List<Reference_HNBF__c>();
        Map<Id,Opportunity> oppMap;
        Map<String,Group> QueueMapByName = new Map<String,Group>();
        Map<String,String> csDistQueueMap = new Map<String,String>();
        
        for(Case_HB_District_Queue_Mapping__c cs:Case_HB_District_Queue_Mapping__c.getall().values()){
            for(String dist:cs.Districts__c.split(',')){
            	csDistQueueMap.put(dist,cs.Queue_Name__c);
            }
        }
        if(!csDistQueueMap.isEmpty()){
            QueueMapByName = new UserHelper().getQueues(csDistQueueMap.values());
        }
        
        Id hnbfCaseRtId = RecordTypeHelper.getRecordType(RT_CASE_HNBF,'Case').getRecordTypeId();
        
        if(sendtoHBMap != null && !sendtoHBMap.isEmpty()){
            oppMap = new Map<Id,Opportunity>([Select Id,OwnerId,Owner.District__c,HNBF_Sales_Type__c,(Select Id, ContactId, OpportunityId, IsPrimary from OpportunityContactRoles order by OpportunityId asc, IsPrimary desc limit 1) from Opportunity where Id in :sendtoHBMap.keySet()]);
            for(Opportunity oppty:sendtoHBMap.values()){
                Case newHNBFCase = new Case(AccountId = oppty.AccountId
                                            ,Opportunity__c = oppty.Id
                                            ,ContactId = oppMap.get(oppty.Id).OpportunityContactRoles != null && !oppMap.get(oppty.Id).OpportunityContactRoles.isEmpty() ? oppMap.get(oppty.Id).OpportunityContactRoles[0].ContactId : null
                                            ,RecordTypeId = hnbfCaseRtId
                                            ,Origin = 'Order'
                                            ,Subject = 'HNBF Onboarding'
                                            ,Status = 'New'
                                            ,Priority = 'Low'
                                            ,Current_Step__c = 'Waiting on Sales & Carrier');
                
                if(oppMap.get(oppty.Id).Owner.District__c != null && csDistQueueMap.containsKey(oppMap.get(oppty.Id).Owner.District__c) && !QueueMapByName.isEmpty() && QueueMapByName.get(csDistQueueMap.get(oppMap.get(oppty.Id).Owner.District__c)) != null)
                	newHNBFCase.OwnerId = QueueMapByName.get(csDistQueueMap.get(oppMap.get(oppty.Id).Owner.District__c)).Id;	
                
                newCases.add(newHNBFCase);
            }
            if(!newCases.isEmpty())
            	DmlHelper.performDML2(newCases, DmlHelper.DML_INSERT, 'OpportunityCreateCase', 'processSendtoHBOpps', 'Inserting new Cases when Oppty moves to 70% and Send to H&B Implementation is Yes', true);
            for(case nc: newCases) {
                newCaseIds.add(nc.Id);
            }
            for(Case newCase:[Select Id,OwnerId,Opportunity__c,Opportunity__r.HNBF_Sales_Type__c,Opportunity__r.OwnerId from Case where Id IN :newCaseIds]){
                Reference_HNBF__c newhnbfrec = new Reference_HNBF__c(Case_Number__c=newCase.Id
                                                ,Current_Step__c = 'Waiting on Sales & Carrier'
                                                ,HNBF_Opportunity__c = newCase.Opportunity__c
                                                ,Submission_Type__c = newCase.Opportunity__r.HNBF_Sales_Type__c
                                                ,Sales_Rep__c = newCase.Opportunity__r.OwnerId
                                                ,OwnerId = newCase.OwnerId
                								);
                newRefHNBFs.add(newhnbfrec);
            }
            if(!newRefHNBFs.isEmpty())
            	DmlHelper.performDML2(newRefHNBFs, DmlHelper.DML_INSERT, 'OpportunityCreateCase', 'processSendtoHBOpps', 'Inserting new Reference HNBFs when Oppty moves to 70% and Send to H&B Implementation is Yes', true);
          }
    }

} // OpportunityCreateCase