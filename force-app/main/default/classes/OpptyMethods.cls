/* Methods for the Opportunity object.

History
-------
11/19/2013 Dan Carmen      Created
03/12/2015 Dan Carmen      Additional methods for linking an opp to an account
12/31/2015 Dan Carmen      catch errors when saving the opportunity team members
01/20/2016 Dan Carmen      Update account from fields on the opportunity (br-clt number, fed id)
03/31/2016 Dan Carmen      Added nssProduct parameter to createNewAudit method.
08/29/2016 Dan Carmen      Added ability to skip trigger to update payment info to referral. 
09/09/2016 Dan Carmen      Fix code to link Referrals and Opportunities
10/13/2016 Dan Carmen      When linking the Opportunity to the referral (based on the entry of the lead id to the referral), delete
any uncoverted lead.
11/03/2016 Dan Carmen        Add additional fields to the queries
05/09/2017 Josh Cartwright  added qualifiedType method to set MQL/SQL 
06/29/2017 Josh Cartwright  added checkCallTime method 
08/02/2017 Jacob Hinds      adding setDefaultRT method.
10/09/2017 Jacob Hinds      adding in Sales Engineer Team Member Sync.
10/24/2017 Dan Carmen       Adjustment for MQL/SQL
10/25/2017 Dan Carmen       Changes for OpportunityType__c
01/23/2018 Dan Carmen       Fix for some test for Opportunity Type
04/04/2018 Jacob Hinds  Adding sync opp forecast category and probability
04/24/2018 Sunnish Annu   Adding Target Field update when an MMS opportunity is created
07/11/2018 Dan Carmen       Modified checkOpportunityType method - to be able to use attributes from the user record.
07/17/2018 Jacob Hinds    Adding checkReferralRunEffective to sync referral run effective to selling run effective
12/07/2018 Lynn Michels  Remove code for Sales_Engineer__c
02/22/2018 Jacob Hinds    Adding payroll platform changed method
03/26/2018 Jacob Hinds    modifying payroll platform to also fire on insert
04/30/2019 Matt Fritschi  Added Switch owner to inactive user test
05/24/2019 Jacob Hinds    Adding account holdout extension method
06/11/2019 Brandon Vidro  Added check for Core/Not Sold/Solo Bundle opportunities and send email to MyCorp.
07/01/2019 Jacob Hinds    Fix for inactive user
09/11/2019 Matt Fritschi  Checks to see if opportunity is created from conversion if a bank referral Lead.
09/11/2019 Matt Fritschi  Fixes error where Bank Referral Opportunities couldn't be cloned.
03/10/2020 Jacob Hinds    Adding PAY and MMS to payroll platform code
03/20/2020 Jacob Hinds    Commenting out PAY and MMS to payroll platform code
05/13/2020 Saketh Mysa    Revert Opportunity Close Date to previous value
06/08/2020 Dan Carmen     Add SoldOppHoldOutReason__c field to HoldOut ExpirationDates
08/27/2020 Jake Hinds    Fix for setDefaultRT to not fire for referrals
11/16/2020 Brandon Vidro  APR0109214 - Added updatePrimaryCompetition()
12/02/2020 Dan Carmen     Refactor code to use TriggerInterface
01/18/2020 Pradeep Garlapaati  Wrote CreateOppTeamMmembers method to create oppty TeamMember from all oppy of that prospect when new oppty is created.
02/08/2021 Matt Fritschi  Account and Oppty owners don't need to match for crossovers to be created.
04/16/2021 Dan Carmen     Fix for CreateOppTeamMmembers - null value was getting added to the where clause if there wasn't a Sales Parent on the account
05/18/2021 Carrie Marciano  Changed to use OppStage Labels
05/20/2021 Josh Cartwright added in defaulting to PEO opp when Peo potential is populated on account and sales org = pas - APR0118271
06/21/2021 Carrie Marciano commented out code that updates recordtype based on payroll plaform for PEO and ASO.  this is now done in OpptyLineItem
07/1/2021  Can Carmen     Fix for INC2712305 where Opportunity Type default was not being set from Referral partner
09/13/2021 Josh Cartwright added logic to checkForReferralsToUpdate to populate referral data from oppty from ecomm 
02/07/2022 Jidesh added logic to sendChecklistUpdateForOwnerChange and sendChecklistUpdateForLostOppty
05/23/2022 Pujitha Madamanchi Populate end date when opp is closed/reopened.
05/11/2022 Jidesh added logic to sendChecklistUpdForOpptyStageChange
06/06/2022 Pujitha Madamanchi Populate end date when opp is moved from close won to lost.
08/19/2022 Reetesh Added APR0135691: Capture Dialsource Action for before insert
09/12/2022 Pujitha Madamanchi  Added allowFuture to make sure it is not already in an async context as the OpptyAutoCloseBatch job was failing.
10/21/2022 Shilpa Govindarajulu   APR0127737 - Added sendChatterToRef to send Chatter Notification to Referring Rep when Opp is Sold/Lost
12/29/2022 Rohit Ranjan Added condition to set Record Type as 'PEO Opportunity Record Type' based on Payroll Platform 
01/19/2023 Jermaine Stukes  Update to process setting opp owner to inactive user
03/16/2023 Jaipal  Moved the block from Opportunity After which was calling the 'DG_OpportunityAcceptDeadline.updateAcceptReminderDeadline method to here because flow was hitting the Apex CPU limit 
04/01/2023 Jaipal Added conditions to update the PEO Hold Out, Reason and PEO Account Owner as per APR: APR0147082 in this method: updateAccountHoldout
06/21/2023 Shilpa APR0151467: Auto create Case, Reference Agency records when HNBF oppty moves to 70% and Send to H&B Implementation is Yes
11/09/2023 Lalan  APR0156837: Consent to text checkbox- Add to Opportunity 
11/14/2023 Eric Porter      APR0161189 Updated oppty's that meet DSM_Reason_Won_Lost_Outcome__c = "Re-Engaged Client Interest"  to update DSM Re-Engaged Client Interest( new field)
11/20/2023 Jidesh Updated logic to check record type before adding to oppsForChecklistCheck map 
12/08/2023 Jaipal APR0152387 removed as part of this APR, not using Primary_Competition_Level_1__c & Primary_Competition_Level_2__c fields
12/11/2023 Dan Carmen        Refactored code for IEUP logic
12/13/2023 Vinay  Added Huckleberry related code (updateReferencePCAndRelatedCase and updateOnboardingFormat methods)
12/27/2023 Carrie Marciano Commented out IEUP logic per INC3599310
01/01/2024 Reetesh Pandey INC3548282: Set Payroll Platform Default to PAY if Opp Type= Payroll
01/29/2024 Lalan Kumar APR0158030: Update to Holdout for Add On Child Accounts
01/31/2024 Dan Carmen         Remove logic for opportunity accept/reject fields
04/10/2024 Jaipal  APR0163688: changed the Opportunity Type to HR Pro when Sales Org is PAS and record type to ASO if both matches
05/27/2024 Shilpa G    APR0168449: Updated method updateAccountHoldout for Virtual Sales HR Services ownership updates
*/
public without sharing class OpptyMethods implements TriggerInterfaceC {
    public static String NOT_SOLD=Label.OppStage_Lost;
    public static String OPP_STAGE_SOLD_REV = 'Sold - Revenue Recognition';
    
    public void handleTrigger(SObject[] recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter, Boolean isDelete) {
        Opportunity[] opps = (Opportunity[])recs;
        if (isBefore) {
            checkOpptyBefore((Opportunity[])recs, (Map<Id,Opportunity>)oldMap);
        } else if (isAfter) {
            checkOpptyAfter((Opportunity[])recs, (Map<Id,Opportunity>)oldMap);
        }
    } // handleTrigger
    
    public static void checkOpptyBefore(Opportunity[] opps, Map<Id,Opportunity> oldMap) {
        
        Map<String,Opportunity> oppsToCheckForRfrlsMap = new Map<String,Opportunity>();
        Map<Id,Opportunity[]> oppsByOwnerMap = new Map<Id,Opportunity[]>();
        Opportunity[] oppStageChanged = new Opportunity[]{};
            Opportunity[] payrollPlatformChanged = new Opportunity[]{};
                Map<Id, Opportunity> oppsPrimCompUpdate = new Map<Id, Opportunity>();
        Opportunity[] DSMReengaged = new Opportunity[]{};
            // Map<Opportunity, Id> opportunitiesToInactiveUser = new Map<Opportunity, Id>();
            Map<Id,Opportunity[]> checkNssSourceMap = new Map<Id,Opportunity[]>();
        Set<id> OpptyIdOwnerChanged = new set<id>();
        Map<Id, Opportunity> peoOppsNotSoldMap = new Map<Id, Opportunity>();   
        Map<Id, Opportunity> peoOppsLost = new Map<Id, Opportunity>();  
        Map<Id, Opportunity> stageChangeList = new Map<Id, Opportunity>();
        List< Opportunity> opptyIdAcceptDeadlineRecalcList = new List<Opportunity>();
        
        Map<Opportunity,Id> oppAccIdMap = new Map<Opportunity,Id>();
        Set<Id> opptyIdSold = new Set<Id>();
        Set<Id> opptyIdLost = new Set<Id>();
        
        List<Opportunity> oppsToUpdateOnboarding = new List<Opportunity>();
        Id PCOppDSARecTypeId = RecordTypeHelper.getRecordType('PC Opportunity DSA Record Type','Opportunity').getRecordTypeId();
        Id PCOppRecTypeId = RecordTypeHelper.getRecordType('PC Opportunity Record Type','Opportunity').getRecordTypeId();
        
        
        
        List<Account> prospectToupdate = new List<Account>(); 
        checkDSMReengagedOpptys(opps);
        for (Opportunity opp : opps) {
            Opportunity oldOpp = (oldMap != null ? (Opportunity)oldMap.get(opp.Id) : null);
            //Vinay - Huckleberry
            if ( oldOpp == null && (opp.RecordTypeId == PCOppDSARecTypeId || opp.RecordTypeId == PCOppRecTypeId) && !String.isBlank(opp.OpportunityType__c)) {
                oppsToUpdateOnboarding.add(opp);
            } else if(oldOpp != null && (opp.RecordTypeId == PCOppDSARecTypeId || opp.RecordTypeId == PCOppRecTypeId) && oldOpp.OpportunityType__c != opp.OpportunityType__c) {
                oppsToUpdateOnboarding.add(opp);
            }          
            // only do updates in the before trigger
            if (String.isNotBlank(opp.Bank_Lead_ID__c) 
                && (opp.ReferralLookup__c == null || (oldOpp == null || opp.Bank_Lead_ID__c != oldOpp.Bank_Lead_ID__c))) {
                    // caveat - if there is more than one opportunity with the same id, the latest one will be in the map. The first one won't be touched.
                    oppsToCheckForRfrlsMap.put(opp.Bank_Lead_Id__c, opp);
                } // if (String.isNotBlank
            
            // check the NSS Source on insert of an opp
            if (oldOpp == null && opp.AccountId != null) {
                Opportunity[] oppList = (checkNssSourceMap.containsKey(opp.AccountId) ? checkNssSourceMap.get(opp.AccountId) : new Opportunity[]{});
                oppList.add(opp);
                checkNssSourceMap.put(opp.AccountId,oppList);
            } // if (oldOpp == null &&
            
            if (String.isBlank(opp.OpportunityType__c)) {
                checkOpportunityType(opp,null,null, null);
            }
            
            // if this is new or the owner changes then evaluate
            if ((oldOpp == null || (opp.OwnerId != oldOpp.OwnerId)) && opp.OpportunityType__c!='Referral'){
                // keep a list by the owner id
                Opportunity[] oppsByOwner = oppsByOwnerMap.containsKey(opp.OwnerId) ? oppsByOwnerMap.get(opp.OwnerId) : new Opportunity[]{};
                    oppsByOwner.add(opp);
                oppsByOwnerMap.put(opp.OwnerId,oppsByOwner);
            } // if (oldOpp == null
            
            if (oldOpp==null || (oldOpp!=null && oldOpp.StageName != opp.StageName)){
                system.debug('checkOpptyBefore insert or stagename change opp: '+opp.Name);
                oppStageChanged.add(opp);
                system.debug('checkOpptyBefore insert or stagename change oppStageChanged: '+oppStageChanged.size());
            }
            
            if (oldOpp==null || (oldOpp!=null && oldOpp.Payroll_Platform__c != opp.Payroll_Platform__c)){
                payrollPlatformChanged.add(opp);
            }            
            
            // copy the client referral to the ReferralAccount field. This is so the counter doesn't have to look at too many fields.
            if (opp.Client_Referral__c != null && opp.ReferralAccount__c == null) {
                opp.ReferralAccount__c = opp.Client_Referral__c;
            }
            
            if (opp.Payroll_Units__c != opp.Payroll_Unit_Currency__c){
                opp.Payroll_Unit_Currency__c = opp.Payroll_Units__c;
            }
            
            if (String.isNotBlank(opp.BranchClientNumber__c) && (oldOpp == null || (oldOpp != null && opp.BranchClientNumber__c != oldOpp.BranchClientNumber__c))) {
                opp.BranchClientNumber__c = opp.BranchClientNumber__c.toUpperCase();
            }
            
            if(oldOpp != null && opp.OwnerId != oldOpp.OwnerId)
            {
                OpptyIdOwnerChanged.add(opp.id);
            }
            
            // if the oppty is a peo/peo prism oppty and the oppty stage is set to a not sold value
            // add the oppty to the peoOppsNotSoldMap map
            id peoOpptyRecTypeId = RecordTypeHelper.getRecordType('PEO Opportunity Record Type','Opportunity').getRecordTypeId();
            //id peoPrismOpptyRecTypeId = RecordTypeHelper.getRecordType('Prism PEO Opportunity Record Type','Opportunity').getRecordTypeId();
            
            //JDA
            //if (opp != null && (opp.StageName == 'Lost' || opp.StageName == 'No Decision' || opp.StageName =='Disqualified') && (opp.RecordTypeId == peoOpptyRecTypeId || opp.RecordTypeId == peoPrismOpptyRecTypeId)) {
            if (opp != null && (opp.StageName == 'Lost' || opp.StageName == 'No Decision' || opp.StageName =='Disqualified') && (opp.RecordTypeId == peoOpptyRecTypeId )) {
                //peoOppsNotSoldMap.put(opp.Id, opp);
                system.debug('opp.StageName:'+opp.StageName);
                peoOppsLost.put(opp.Id, opp);
            }
            //JDA sfdc-10804
            if (opp != null && oldOpp!= null && oldOpp.Probability < 40 && opp.Probability >= 40) {
                system.debug('opp.StageName:'+opp.StageName);
                system.debug('opp.Probability:'+opp.Probability);
                stageChangeList.put(opp.Id, opp);
            }
            //Added Reetesh - APR0135691: Capture Dialsource Action for before insert
            if(oldOpp==null  && opp.AccountId != null){              
                oppAccIdMap.put(opp, opp.AccountId);
            }
            //Shilpa - APR0127737
            if (opp != null && oldOpp!= null && opp.OpportunityType__c!=Label.OppType_Referral && oldOpp.Probability < 80 && opp.Probability >= 80) {
                opptyIdSold.add(opp.id);
            }
            if(opp != null && oldOpp!= null && opp.OpportunityType__c!=Label.OppType_Referral && (opp.IsClosed != oldOpp.IsClosed || opp.IsWon != oldOpp.IsWon) && opp.IsClosed && !opp.IsWon){               
                opptyIdLost.add(opp.id);
            }
            // Jaipal - APR0149770 Moved the block from Opportunity After to here because it was hitting the Apex CPU limit  
            if(opp.AcceptDeadlineRecalc__c || opp.Referral_Partner_Stage__c == opp.StageName && (oldOpp == null || (opp.StageName!= oldOpp.StageName))  
               && opp.Accept_Deadline__c==null && opp.Accept_Reminder_Deadline__c== null){
                   opptyIdAcceptDeadlineRecalcList.add(opp);
               }//if(opp.AcceptDeadlineRecalc__c 
            
            
        } // for (Opportunity opp    
        
        
        if (prospectToupdate.size() > 0) {
            update prospectToupdate; 
        }
        
        if (!opptyIdAcceptDeadlineRecalcList.isEmpty()) {
            DG_OpportunityAcceptDeadline.updateAcceptReminderDeadline(opptyIdAcceptDeadlineRecalcList);
        }
        
        if (!checkNssSourceMap.isEmpty()) {
            checkNssSource(checkNssSourceMap);
        }
        
        if (!oppsToCheckForRfrlsMap.isEmpty()) {
            checkForReferrals(oppsToCheckForRfrlsMap,true);
        }
        if (!oppsByOwnerMap.isEmpty()) {
            setDefaultRt(oppsByOwnerMap);
        }
        if (!oppStageChanged.isEmpty()){
            system.debug('checkOpptyBefore before call setForecastProbabilityFromOppStage');
            setForecastProbabilityFromOppStage(oppStageChanged);
        }
        
        if (!payrollPlatformChanged.isEmpty()){
            evaluatepayrollPlatform(payrollPlatformChanged);
        }      
        
        
        //If an opportunity ownership was changed to an inactive user 
        /*if (!opportunitiesToInactiveUser.isEmpty()){
changeOppOwnershipToInactiveUser(opportunitiesToInactiveUser);
}*/
        
        
        if (!OpptyIdOwnerChanged.isEmpty()){
            InsertOpptyTeamMemWhenOwnerChanged(OpptyIdOwnerChanged);
            sendChecklistUpdateForOwnerChange(OpptyIdOwnerChanged);          
            sendChatterMessageToSDRusers(OpptyIdOwnerChanged);          
        }
        
        //JDA
        if (!peoOppsLost.isEmpty()) {
            System.debug('peoOppsLost.isEmpty = false - OpptId(s): ' + peoOppsLost.keySet());
            // send the future call to update the checklist
            sendChecklistUpdateForLostOppty(peoOppsLost.keySet());
        }
        //JDA sfdc-10804
        if (!stageChangeList.isEmpty()) {
            System.debug('stageChangeList.isEmpty = false - OpptId(s): ' + stageChangeList.keySet());
            //send the future call to update the checklist
            sendChecklistUpdForOpptyStageChange(stageChangeList.keySet());
        }
        //Added Reetesh - APR0135691: Capture Dialsource Action
        if (!oppAccIdMap.isEmpty()) {
            setDSAonOpp(oppAccIdMap);
        }
        //Shilpa - APR0127737
        if(!opptyIdSold.isEmpty()){
            String msg = Label.OpptyRefRep_NotifySold;
            sendChatterToRef(opptyIdSold,msg);
        }
        if(!opptyIdLost.isEmpty()){
            String msg = Label.OpptyRefRep_NotifyLost;
            sendChatterToRef(opptyIdLost,msg);
        }
        //Vinay - Huck
        if(!oppsToUpdateOnboarding.isEmpty()) {
            updateOnboardingFormat(oppsToUpdateOnboarding);
        }
    } // checkOpptyBefore
    
    
    public static String PC_REP_PROF=Label.Profile_PC_Rep;   
    
    static list<opportunityTeamMember> otmToInsert = new list<opportunityTeamMember>();
    public static void InsertOpptyTeamMemWhenOwnerChanged(set<id> OpptyIdOwnerChanged)
    {
        String[] teamRoles = Label.OppyTeamMemberToKeepWhenOwnerChanged.split(',');
        otmToInsert = new list<opportunityTeamMember>([select userid,opportunityid,TeamMemberRole,Demo_date__c,Prospect_Ownership__c,OpportunityAccessLevel from opportunityTeamMember where opportunityid IN : OpptyIdOwnerChanged AND  TeamMemberRole IN : teamRoles ]);
        
        
    }
    
    private static void InsertOpptyTeamMemWhenOwnerChangedAfter() {
        
        list<opportunityTeamMember> otmToInsertNew = new list<opportunityTeamMember>();
        set<id> opptyids = new set<id>();
        for(opportunityTeamMember ot : otmToInsert)
        {
            opptyids.add(ot.OpportunityId); 
        }
        map<id,opportunityTeamMember> OtmsnotDeleted = new map<id,opportunityTeamMember>([select id,userid,teamMemberRole,opportunityid,Demo_date__c,Prospect_Ownership__c,OpportunityAccessLevel from opportunityTeamMember where opportunityid IN :opptyids]);
        
        for(opportunityTeamMember ot : otmToInsert)
        {
            
            if(!OtmsnotDeleted.containskey(ot.id))
            {
                System.debug('ot ='+ot);
                opportunityTeamMember o = new opportunityTeamMember();
                o.UserId = ot.userid;
                o.TeamMemberRole = ot.TeamMemberRole;
                o.OpportunityId = ot.OpportunityId;
                o.Demo_date__c = ot.Demo_date__c;
                o.Prospect_Ownership__c = ot.Prospect_Ownership__c;
                o.OpportunityAccessLevel = ot.OpportunityAccessLevel;
                otmToInsertNew.add(o);
            }
        }
        if(otmToInsertNew.size() > 0) DmlHelper.performDML2(otmToInsertNew, DmlHelper.DML_INSERT, 'OpptyMethods', 'checkOpptyAfter', 'Inserting OpptyTeam back when owner changed', true);  
    }
    
    public static void checkOpptyAfter(Opportunity[] opps, Map<Id,Opportunity> oldMap) {
        
        Map<String,Opportunity> oppsToCheckForRfrlsMap = new Map<String,Opportunity>();
        Id[] wonOppIdsToCheck = new Id[]{};
            /*APR0156837: added oppPhoneandConsentToText Id */
            // Id[] oppPhoneandConsentToText = new Id[]{};
            Id[] opptyIdsForHoldoutUpdates = new Id[]{};
                Map<Id,Opportunity> oppByOppIdForRefMap = new Map<Id,Opportunity>();
        Map<Id,Opportunity> oldOppMap = new Map<Id,Opportunity>();
        Map<Id,Opportunity> oppRunEffectiveMap = new Map<Id,Opportunity>();
        Map<Id, Opportunity> opportunitiesNotSoldSoloMyCorp = new Map<Id, Opportunity>();
        Map<Id, Opportunity> oppsFromBankReferral = new Map<Id, Opportunity>();
        Map<Id,Opportunity> oppsForChecklistCheck = new Map<Id, Opportunity>();
        Map<Id,Opportunity> oppSendtoHBMap = new Map<Id,Opportunity>();
        //Update Owner to Inactive User
        List<String> updateOppOwnerIdList = new List<String>();
        Set<Id> oppsToCloseRefPC = new Set<Id>();
        Id PCOppDSARecTypeId = RecordTypeHelper.getRecordType('PC Opportunity DSA Record Type','Opportunity').getRecordTypeId();
        Id PCOppRecTypeId = RecordTypeHelper.getRecordType('PC Opportunity Record Type','Opportunity').getRecordTypeId();       
        
        for (Opportunity opp : opps) {
            Opportunity oldOpp = (oldMap != null ? oldMap.get(opp.Id) : null);
            System.debug('checkOpptyAfter opp='+opp.Name+' oldOpp is null='+(oldOpp == null)+' stage='+opp.StageName+' isWon='+opp.IsWon+' isClosed='+opp.IsClosed+' OppType='+opp.OpportunityType__c);
            
            if(oldOpp != null && (opp.RecordTypeId == PCOppDSARecTypeId || opp.RecordTypeId == PCOppRecTypeId) && opp.Probability == 100) {
                oppsToCloseRefPC.add(opp.Id);
                System.debug('checkOpptyAfter oppsToCloseRefPC: '+oppsToCloseRefPC);
            }		 
            if (oldOpp == null && String.isNotBlank(opp.Bank_Lead_ID__c)) {
                oppsToCheckForRfrlsMap.put(opp.Bank_Lead_ID__c, opp);
            }
            
            if (opp.isWon && (oldOpp == null || !oldOpp.isWon)) {
                checkWonOppRTSet();
                // only proceed for certain record types
                Boolean rtInSet = wonOppRtIdSet.contains(opp.RecordTypeId);
                System.debug('checkOpptyAfter newOpp isWon rtCheckPass='+rtInSet);
                if (rtInSet) {
                    wonOppIdsToCheck.add(opp.Id);
                }
            } // if
            
            
            String[] holdoutTypeLst = Label.OppTypeAccountHoldout.split(',');
            Boolean holdoutOppType = (String.isNotBlank(opp.OpportunityType__c) && (holdoutTypeLst.contains(opp.OpportunityType__c)));
            //Saketh 36574919
             //APR0168449: Added ReferralLookup criteria to the if
             if ((oldOpp != null && oldOpp.StageName != opp.StageName && opp.isWon && opp.isClosed  // when moves to Sold - Started
                    && String.isNotBlank(opp.OpportunityType__c)
                    && ((holdoutTypeLst.contains(opp.OpportunityType__c) && opp.Payroll_Units__c != null && opp.Payroll_Units__c > 0)
                         || opp.OpportunityType__c=='PEO'))  || (oldOpp == null && opp.ReferralLookup__c!=null)) {   // TODO - this needs to be made more generic
                System.debug('checkOpptyAfter add to opptyIdsForHoldoutUpdates');
                opptyIdsForHoldoutUpdates.add(opp.Id);
                                                                     
             }
            if(oldOpp!=null){          
                // only do this on an update
                // can i add my check here and do the update in checkForReferralsToUpdate
                if ((!SKIP_PAYMENT_TO_REFERRAL  && 
                     (opp.Month_Sale_Reported__c != oldOpp.Month_Sale_Reported__c
                      || opp.Pending_Run_of_Payroll__c != oldOpp.Pending_Run_of_Payroll__c
                      || opp.Actual_Revenue__c != oldOpp.Actual_Revenue__c
                      || opp.Disposition__c != oldOpp.Disposition__c
                      || opp.of_Employees__c != oldOpp.of_Employees__c
                      || opp.BranchClientNumber__c != oldOpp.BranchClientNumber__c
                      || opp.FedIdNumber__c != oldOpp.FedIdNumber__c
                      || (opp.Referral_Contact__c != null &&(opp.Referral_Contact__c != oldOpp.Referral_Contact__c))
                      || (opp.Referral_Account__c != null &&(opp.Referral_Account__c != oldOpp.Referral_Account__c)))) 
                    || (opp.isClosed!= oldOpp.isClosed && opp.isClosed && !opp.isWon)  
                    || (opp.isWon!= oldOpp.isWon && opp.isClosed && !opp.isWon) 
                    || (opp.StageName!= oldOpp.StageName && opp.StageName==Label.OppStage_No_Decision)
                    || (!opp.isClosed && oldOpp.isClosed)){
                        oppByOppIdForRefMap.put(opp.Id,opp);
                        oldOppMap.put(oldOpp.Id,oldOpp);
                    }
            }
            
            //if run effective date changes, update the referring opportunity's run date to match
            if (oldOpp != null && oldOpp.CloseDate != opp.CloseDate && opp.CloseDate!=null 
                && opp.ReferralLookup__c!=null && !opp.OverrideRevenueSplit__c && opp.Probability > 0 && opp.Probability <= 90){
                    oppRunEffectiveMap.put(opp.Id,opp);
                }
            
            id rtID = RecordTypeHelper.getRecordType('Core Opportunity Record Type','Opportunity').getRecordTypeId();
            id rtCoreDSAID = RecordTypeHelper.getRecordType('Core Opportunity DSA Record Type', 'Opportunity').getRecordTypeId();
            if (oldOpp != null && oldOpp.StageName != NOT_SOLD && (opp.RecordTypeId == rtID || opp.RecordTypeId == rtCoreDSAID) && opp.StageName == NOT_SOLD) {
                opportunitiesNotSoldSoloMyCorp.put(opp.Id, opp);
            }
            //If this is new and is owned by an inactive user or the Owner changes to an inactive user
            if (oldOpp != null && oldOpp.Inactive_User_Id__c != opp.Inactive_User_Id__c &&  String.IsNotBlank(opp.Inactive_User_Id__c)){
                updateOppOwnerIdList.add(opp.Id);
            }
            if (oldOpp == null && opp.LeadSource != null && opp.LeadSource == LABEL.LeadSource_ReferralBank && opp.Referral_Contact__c != null && 
                oppsFromBankReferral.isEmpty() && opp.OpportunityId__c!=null && opp.OpportunityId__c == OpptyCheckFields.OPP_NEW && 
                String.isNotBlank(opp.OppSource__c) && !opp.OppSource__c.contains('Clone'))   //If this is a Bank referral created from converting a Lead, create a crossover request for territory rep.
            {
                //Referral Lookup. Get the referral ID and use that as the key, and use the opp as the value
                oppsFromBankReferral.put(opp.ReferralLookup__c, opp);
            }
            
            //JDA
            Id recordTypeId1 = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('PEO Opportunity Record Type').getRecordTypeId();
            Id recordTypeId2 = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Prism PEO Opportunity Record Type').getRecordTypeId();
            if (opp.AccountId != null && (opp.RecordTypeId == recordTypeId1 || opp.RecordTypeId == recordTypeId2)) {
                oppsForChecklistCheck.put(opp.AccountId, opp);
            }
            //Shilpa - APR0151467
            id hnbfDSAOpptyRecTypeId = RecordTypeHelper.getRecordType(Label.HNBF_DSA_Opportunity_Record_Type,'Opportunity').getRecordTypeId();
            id hnbfOpptyRecTypeId = RecordTypeHelper.getRecordType(Label.HNBF_Opportunity_Record_Type,'Opportunity').getRecordTypeId();
            if(opp != null && oldOpp!= null && oldOpp.Probability < Decimal.valueOf(Label.OpptySendtoHBPct) && opp.Probability >= Decimal.valueOf(Label.OpptySendtoHBPct) && opp.Send_to_H_B_Implementation__c == 'Yes' && (opp.RecordTypeId==hnbfOpptyRecTypeId || opp.RecordTypeId==hnbfDSAOpptyRecTypeId)){
                oppSendtoHBMap.put(opp.Id,opp);
            }
        } // for (Opportunity opp : opps
        
        if (!otmToInsert.isEmpty()) {
            InsertOpptyTeamMemWhenOwnerChangedAfter();
        }
        
        if (!oppsToCheckForRfrlsMap.isEmpty()) {
            checkForReferrals(oppsToCheckForRfrlsMap,false);
        }
        
        if (!wonOppIdsToCheck.isEmpty()) {
            checkWonOpportunities(wonOppIdsToCheck);
        }
        /* APR0156837: calling method updateOppPhoneandConsentToText */
        /* if(!oppPhoneandConsentToText.isEmpty())
{
updateOppPhoneandConsentToText(oppPhoneandConsentToText);
}*/
        if(!opptyIdsForHoldoutUpdates.isEmpty()){
            updateExtendHoldout(opptyIdsForHoldoutUpdates);
        }
        
        if (!oppByOppIdForRefMap.isEmpty()) {
            checkForReferralsToUpdate(oppByOppIdForRefMap, oldOppMap);
        }
        
        if (!oppRunEffectiveMap.isEmpty()){
            checkReferralRunEffective(oppRunEffectiveMap);
        } 
        
        // Saketh
        if (!opportunitiesNotSoldSoloMyCorp.isEmpty()) {
            sendNotSoldEmailToMyCorp(opportunitiesNotSoldSoloMyCorp);
        }
        
        if (oppsFromBankReferral.size()==1 && !Test.isRunningTest()) {
            CreateBankReferralCrossover CBRC = new CreateBankReferralCrossover(oppsFromBankReferral);
        } 
        
        //JDA
        if(!oppsForChecklistCheck.isEmpty()){
            system.debug('Calling updateChecklistOpty from opty methods');
            CommunityMethods.updateChecklistOpty(oppsForChecklistCheck);
        }
        
        if(!updateOppOwnerIdList.isEmpty()){
            
            String opptyIdList = String.join(updateOppOwnerIdList,',');
            String emailAddy = Label.OpptyEmailServiceEmail;
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new String[]{emailAddy});
            mail.setSaveAsActivity(false);
            mail.setSubject('Update Opp Owner to Inactive Users');
            mail.setPlainTextBody('Opportunity Ids:'+opptyIdList+'endOfList');
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });         
        }
        //Shilpa - APR0151467
        if(!oppSendtoHBMap.isEmpty()){
            OpportunityCreateCase.processSendtoHBOpps(oppSendtoHBMap);
        }
        
        if(!oppsToCloseRefPC.isEmpty()) {
            updateReferencePCAndRelatedCase(oppsToCloseRefPC);
        }
    } // checkOpptyAfter
    
    public static String ROLE_NSR='NSR';
    
    public static Map<Id,opportunityTeamMember[]> OpptyTeamMemDeleteWhenOwnerChanged = new Map<Id,opportunityTeamMember[]>();
    
    public static Boolean SKIP_OPPTY_TRIGGERS=false;
    
    public static Boolean MYCORP_EMAIL_SENT = false;
    
    //Vinay - Huckleberry
    public static void updateReferencePCAndRelatedCase(Set<Id> opps) {
        system.debug('updateReferencePCAndRelatedCase opps='+opps.size()); 
        Map<Id, Reference_P_C__c> refPCToFilter = new Map<Id, Reference_P_C__c>();
        Map<Id, Reference_P_C__c> refPCListWithDiscrepancies = new Map<Id, Reference_P_C__c>();
        List<Reference_P_C__c> refPCToUpdate = new List<Reference_P_C__c>();
        //Set<Id> caseIdsToUpdate = new Set<Id>();
        //List<Case> casesToUpdate = new List<Case>();
        Id RefPCDiscrepancyRecTypeId = RecordTypeHelper.getRecordType('P&C Discrepancy','Reference_P_C__c').getRecordTypeId();
        //Id pcQueueId = [SELECT id FROM Group WHERE Type = 'Queue' and DeveloperName = 'P_C_Queue'].Id;
        Group pcQueue = new UserHelper().getQueue('P&C Queue');
        //Get Reference P&C Records based on required conditions.
        for(Reference_P_C__c rpc: [
            SELECT Id, Current_Step__c, Case_Lookup__c, OwnerId, Owner.Name
            FROM Reference_P_C__c
            WHERE P_C_Quoted_Tool__c = 'Huckleberry'
            AND Onboarding_Format_Lookup__c = 'Direct Bill'
            //AND Owner.Name='P&C Queue'
            AND OwnerId=:pcQueue.Id
            AND Current_Step__c = 'New'
            AND Opportunity_Lookup__c IN: opps]) {
                //System.debug('updateReferencePCAndRelatedCase owner.Name='+rpc.Owner.Name);
                refPCToFilter.put(rpc.Id, rpc);
            }
        system.debug('updateReferencePCAndRelatedCase refPCToFilter: '+refPCToFilter.size());    
        //Filter the Records which have Discrepancies.
        for (Reference_P_C__c innerRC : [
            SELECT Id, P_C_Onboarding_Lookup__c, Current_Step__c FROM Reference_P_C__c
            WHERE RecordTypeId =: RefPCDiscrepancyRecTypeId
            AND P_C_Onboarding_Lookup__c IN: refPCToFilter.keySet()
        ]) {
            refPCListWithDiscrepancies.put(innerRC.Id, innerRC);   
        }
        system.debug('updateReferencePCAndRelatedCase refPCListWithDiscrepancies: '+refPCListWithDiscrepancies.size());
        Map<Id, Reference_P_C__c> rePCMapToProcess = new Map<Id, Reference_P_C__c>();
        if(!refPCListWithDiscrepancies.isEmpty()) {
            for(Id rcpId : refPCToFilter.keySet()) {
                if(refPCListWithDiscrepancies.containsKey(rcpId)) {
                    refPCToFilter.remove(rcpId);
                }
            }
        }
        
        system.debug('updateReferencePCAndRelatedCase before for loop refPCToFilter: '+refPCToFilter); 
        for (Reference_P_C__c rcToAdd : refPCToFilter.values()) {
            Reference_P_C__c rcpRec = new Reference_P_C__c();
            rcpRec.Id = rcToAdd.Id;
            rcpRec.Current_Step__c = 'Completed';
            refPCToUpdate.add(rcpRec);
        }
        
        system.debug('updateReferencePCAndRelatedCase refPCToUpdate: '+refPCToUpdate.size());
        if(refPCToUpdate.size() > 0) {
            DmlHelper.performDML2(refPCToUpdate, DmlHelper.DML_UPDATE, 'OpptyMethods', 'updateReferencePCAndRelatedCase', 'Updating Reference P&C to Completed', true);
        }
    }
    
    //Vinay - Huckleberry
    public static void updateOnboardingFormat(Opportunity[] opps) {
        for (Opportunity opp : opps) {
            if (opp.OpportunityType__c == 'Auto' ||
                opp.OpportunityType__c == 'BOP (Business Owners Package)' ||
                opp.OpportunityType__c == 'Umbrella' ||
                opp.OpportunityType__c == 'Workers Comp' ||
                opp.OpportunityType__c == 'General Liability'
               ) {
                   opp.Onboarding_Format__c = '';
               } else {
                   opp.Onboarding_Format__c = 'Direct Bill';
               }
            System.debug('Each Opp =========>' + opp);
        }
    }
    
    public static void checkNssSource(Map<Id,Opportunity[]> oppByAcctIdMap) {
        Account[] accts = [Select Id, Hold_Out__c, Permanent_Hold_Out_Description__c 
                           from Account
                           Where Id in :oppByAcctIdMap.keySet()
                           and Hold_Out__c=true
                           and Permanent_Hold_Out_Description__c != null];
        System.debug('checkNssSource oppByAcctIdMap='+oppByAcctIdMap.size()+' accts='+accts.size());
        
        for (Account acct : accts) {
            HoldOut_Dictionary__c hod = HoldOut_Dictionary__c.getInstance(acct.Permanent_Hold_Out_Description__c);
            // if there's an NSS Source for the account's hold out reason, we'll change the NSS Source on the opps
            if (hod != null && String.isNotBlank(hod.NSSSource__c)) {
                Opportunity[] opps = oppByAcctIdMap.get(acct.Id);
                if (opps != null) {
                    for (Opportunity opp : opps) {
                        opp.NSS_Source__c = hod.NSSSource__c;
                    }
                } // if (opps != null
            } // if (hod != null 
        } // for (Account acct
    } // checkNssSource
    
    public static void checkSalesTeamforNSR(Opportunity[] opps) {
        
        // retrieve all commissionable ownership records
        Map<Id,List<Prospect_Ownership__c>> acctOwnerMap = getAcctOwnerMap(opps);
        
        OpportunityTeamMember[] otmToInsert = new OpportunityTeamMember[]{};
            
            // get the opportunity record types - so we can get the name of the record type from the id
            setupRecordTypeMap();
        //Map<String,Schema.RecordTypeInfo> byIdMap = new Map<String,Schema.RecordTypeInfo>();
        
        //RecordTypeHelper.getRecordTypesMap(ObjectHelper.OBJECT_OPPTY, byIdMap, null);
        
        for (Opportunity opp : opps) {
            // if no ownership records do nothing
            List<Prospect_Ownership__c> ownerList = (opp.AccountId != null ? acctOwnerMap.get(opp.AccountId) : null);
            if (ownerList != null && !ownerList.isEmpty()) {
                // check if we need to add to the sales team
                checkAddToSalesTeam(byIdMap.get(opp.RecordTypeId).getName(), opp.Id, opp.CloseDate, ownerList, otmToInsert, null, null);
            }
        } // for (Opportunity opp
        
        if (!otmToInsert.isEmpty()) {
            Database.SaveResult[] results = Database.insert(otmToInsert,false);
        }
    } // checkSalesTeamforNSR
    
    // Check if we need to add an NSR to the Sales Team.
    public static Boolean checkAddToSalesTeam(String recordTypeName, Id opptyId, Date closeDate, List<Prospect_Ownership__c> ownerList, OpportunityTeamMember[] otmToInsert, OpportunityTeamMember[] existingOtms, OpportunityTeamMember[] otmToUpdate) {
        Boolean okay = true;
        // get the type of opportunity (based on record type) so we check the correct ownership.
        String salesOrg = RecordTypeHelper.getSalesOrgForRecordTypeName(recordTypeName);
        // is this a payroll opportunity
        Boolean isPayrollOpp = isPayroll(salesOrg);
        if (String.isNotBlank(salesOrg)) {
            // keep track of all of the users we create opportunity team members for so we only create one per user
            Set<Id> userIdSet = new Set<Id>();
            for (Prospect_Ownership__c po : ownerList) {
                System.debug('checkAddToSalesTeam po='+po.Id+' po.NSR_Name__c='+po.NSR_Name__c+' NSR='+po.NSR_Name__r.Name+' po.NSRIsActive__c='+po.NSRIsActive__c+' po.NSR_Name__r.IsActive='+po.NSR_Name__r.IsActive);
                // if the NSR isn't active, check for the supervisor
                Id otmUserId = (po.NSR_Name__r != null && po.NSR_Name__r.IsActive ? po.NSR_Name__c : (po.NSRSupervisor__c != null ? po.NSRSupervisor__c : null));
                // check that the close date falls within the commission start and end dates
                if (otmUserId != null && po.CommissionStart__c <= closeDate && po.CommissionEnd__c >= closeDate) {
                    OpportunityTeamMember otm = null;
                    // if existing passed in, see if an existing one exists
                    if (existingOtms != null && !existingOtms.isEmpty()) {
                        for (OpportunityTeamMember checkOtm : existingOtms) {
                            if (checkOtm.UserId == otmUserId) {
                                otm = checkOtm;
                                if (otmToUpdate != null && otm.Prospect_Ownership__c == null) {
                                    otm.Prospect_Ownership__c = po.Id;
                                    otmToUpdate.add(otm);
                                    ChangeLog.addToLog(checkOtm.Id, 'Prospect_Ownership__c', po.Id);
                                }
                                break;
                            }
                        } // for (OpportunityTeamMember
                    } // if (existingOtms != null
                    
                    if (otm == null && !userIdSet.contains(otmUserId)) {
                        // is this a payroll ownership object?
                        //Boolean isPayrollOwner = isPayroll(po.NSS_Team__c);
                        // always create for inbound
                        // for outbound - if HRS rep, any opportunity, for Core/MMS, only if payroll opportunity
                        //if ((po.NSS_Source__c == ProspectOwnershipMethods.NSS_INBOUND) 
                        //    || ((po.NSS_Source__c == ProspectOwnershipMethods.NSS_OUTBOUND) 
                        //        && (!isPayrollOwner || (isPayrollOwner && isPayrollOpp)))) 
                        //{
                        otm = new OpportunityTeamMember(OpportunityId=opptyId
                                                        ,UserId=otmUserId
                                                        ,TeamMemberRole=ROLE_NSR
                                                        ,NSS_Source__c=po.NSS_Source__c
                                                        ,NSS_Team__c=po.NSS_Team__c
                                                        ,Prospect_Ownership__c=po.Id);
                        otmToInsert.add(otm);
                        userIdSet.add(otmUserId);
                        ChangeLog.addToLog(opptyId, 'NewOppTeamMember', otmUserId);
                    } // if
                }
            } // for
            
        } // if (String.isNotBlank
        return okay;
    } // checkAddToSalesTeam
    
    /** Is this a value for payroll (PAY or MMS)? */
    public static Boolean isPayroll(String valueToCheck) {
        Boolean isPayroll = (String.IsNotBlank(valueToCheck) && (valueToCheck == UserHelper.SO_CORE || valueToCheck == UserHelper.SO_MMS));
        return isPayroll;
    } // isPayroll
    
    /** Get the map of the team members for each opportunity.
*/
    public static Map<Id,List<OpportunityTeamMember>> getTeamMembersByOpptyIdMap(Id[] opptyIds) {
        Map<Id,List<OpportunityTeamMember>> teamMembersByOpptyIdMap = new Map<Id,List<OpportunityTeamMember>>();
        for (OpportunityTeamMember[] otms : [Select Id, OpportunityAccessLevel, OpportunityId, TeamMemberRole, UserId
                                             ,Prospect_Ownership__c
                                             from OpportunityTeamMember
                                             Where OpportunityId in :opptyIds]) {
                                                 for (OpportunityTeamMember otm : otms) {
                                                     List<OpportunityTeamMember> otmList = teamMembersByOpptyIdMap.get(otm.OpportunityId);
                                                     if (otmList == null) {
                                                         otmList = new List<OpportunityTeamMember>();
                                                         teamMembersByOpptyIdMap.put(otm.OpportunityId,otmList);
                                                     }
                                                     otmList.add(otm);
                                                 } // for (OpportunityTeamMember otm
                                                 
                                             } // for (OpportunityTeamMember[] otms
        return teamMembersByOpptyIdMap;
    } // getTeamMembersByOpptyIdMap
    
    private static List<Id> oppIds;
    private static Set<Id> acctIdSet;
    
    public static Map<Id,List<Prospect_Ownership__c>> getAcctOwnerMap(Opportunity[] opps) {
        acctIdSet = new Set<Id>();
        oppIds = new List<Id>();
        
        // get the lowest and highest close dates to get only ownership records in that range
        Date lowDate = Date.today();
        Date highDate = Date.today();
        
        for (Opportunity opp : opps) {
            if (opp.AccountId != null) {
                acctIdSet.add(opp.AccountId);
                oppIds.add(opp.Id);
                if (opp.CloseDate < lowDate) {
                    lowDate = opp.CloseDate;
                }
                if (opp.CloseDate > highDate) { 
                    highDate = opp.CloseDate; 
                }
            } // if (opp.AccountId != null
        } // for Opportunity opp
        
        // get ownership records
        Map<Id,List<Prospect_Ownership__c>> acctOwnerMap = ProspectOwnershipMethods.getAcctOwnerMap(acctIdSet, false, lowDate, highDate);
        return acctOwnerMap;
    } // getAcctOwnerMap
    
    /** The set of stage names we will check to see if we need to create an audit record. */
    public static final Set<String> AUDIT_STAGENAMES = new Set<String>{'Sold - Started', 'Sold - Run','Sold - Commissioned'};
        
        /** Check if there's an ownership record on the account that matches the opportunity.
*/
        public static void checkForNSSAudit(Opportunity[] opps) {
            // get ownership records
            Map<Id,List<Prospect_Ownership__c>> acctOwnerMap = getAcctOwnerMap(opps);
            // get the account records
            List<Id> acctIds = new List<Id>();
            acctIds.addAll(acctIdSet);
            Map<Id,Account> acctMap = ReferralQueries.selectAcctMap(acctIds);
            // get open audit records
            Map<Id,List<NSSAudit__c>> nssAuditListMap = NSSAuditHelper.getNssAuditListMap(acctIdSet,oppIds,null,true);
            
            if (!acctOwnerMap.isEmpty()) {
                
                ProspectOwnershipMethods.initializeSaveObjects();
                
                processOwnershipRecords(opps,acctMap, acctOwnerMap, nssAuditListMap);
                
                ProspectOwnershipMethods.checkForSaves();
            } // if (!acctOwnerMap.isEmpty()
            
        } // checkForNSSAudit
    
    public static void CreateOppTeamMmembers(set<id> AllNewOpptyAccountIds,list<opportunity> AllNewOpptyList)
    {
        // added check for null sales parent because null values are getting added in affecting the opportunity query
        list<account> ParentAccountsList = new list<account>([select id,SalesParent__c from account where id in : AllNewOpptyAccountIds and SalesParent__c != null]);         
        map<id,id> AccountIdToParentAccIdMap = new map<id,id>();         
        set<id> AllNewOpptyAccountIdsSalesParent = new set<id>();
        for(account acc : ParentAccountsList)
        {
            AccountIdToParentAccIdMap.put(acc.Id, acc.SalesParent__c);
            AllNewOpptyAccountIds.add(acc.SalesParent__c);   
        }
        System.debug('AllNewOpptyAccountIds = '+AllNewOpptyAccountIds);
        String[] teamRoles = Label.OppyTeamMemberToKeepWhenOwnerChanged.split(',');
        list<Opportunity> AllOpportunityList = new list<Opportunity>();
        AllOpportunityList = [select id,AccountId, (select id,userid,TeamMemberRole,opportunity.accountid,opportunity.account.SalesParent__c,Demo_date__c
                                                    from OpportunityTeamMembers  where Demo_date__c >= :Date.today() 
                                                    AND TeamMemberRole IN : teamRoles  order by Demo_date__c) 
                              from opportunity where accountid IN : AllNewOpptyAccountIds order by CreatedDate];
        
        list<OpportunityTeamMember> otm = new list<OpportunityTeamMember>();
        for(opportunity opp: AllOpportunityList)
        {
            if(opp.OpportunityTeamMembers.size()>0) otm.addall(opp.OpportunityTeamMembers);
        }
        
        list<OpportunityTeamMember> otmListToInsert = new list<OpportunityTeamMember>();
        map<id,list<OpportunityTeamMember>> OppToOpportunityTeamMap = new map<id,list<OpportunityTeamMember>>();
        
        for(OpportunityTeamMember oppTM: otm)
        {
            if(OppToOpportunityTeamMap.containsKey(oppTM.opportunity.accountid)) {
                List<OpportunityTeamMember> oppytmList = OppToOpportunityTeamMap.get(oppTM.opportunity.accountid);
                oppytmList.add(oppTM);
                OppToOpportunityTeamMap.put(oppTM.opportunity.accountid, oppytmList);
            } 
            
            else {
                OppToOpportunityTeamMap.put(oppTM.opportunity.accountid, new List<OpportunityTeamMember> { oppTM });
            }
        }
        
        for(opportunity opp : AllNewOpptyList)
        {
            if(OppToOpportunityTeamMap.containsKey(opp.AccountId))
            {
                for(OpportunityTeamMember otms : OppToOpportunityTeamMap.get(opp.AccountId))
                {
                    System.debug('otms = '+otms);
                    OpportunityTeamMember ot = new OpportunityTeamMember();
                    ot.UserId = otms.userid;
                    ot.OpportunityId = opp.Id;
                    ot.TeamMemberRole = otms.TeamMemberRole;
                    ot.Demo_date__c = otms.Demo_date__c;
                    otmListToInsert.add(ot);
                }
            }
            id ParentAccid = AccountIdToParentAccIdMap.get(opp.Accountid);
            System.debug('ParentAccid = '+ParentAccid);
            if(ParentAccid != null && OppToOpportunityTeamMap.containsKey(ParentAccid))
            {
                for(OpportunityTeamMember otms : OppToOpportunityTeamMap.get(ParentAccid))
                {
                    System.debug('otms = '+otms);
                    OpportunityTeamMember ot = new OpportunityTeamMember();
                    ot.UserId = otms.userid;
                    ot.OpportunityId = opp.Id;
                    ot.TeamMemberRole = otms.TeamMemberRole;
                    ot.Demo_date__c = otms.Demo_date__c;
                    otmListToInsert.add(ot);
                }
            }
            
        }
        if(otmListToInsert.size()>0) 
        {  
            DmlHelper.performDML2(otmListToInsert, DmlHelper.DML_INSERT, 'OpptyMethods', 'CreateOppTeamMmembers', 'Inserting OpportunityTeam within 12 months of Demo date', true);
            
        }
    }    
    
    // get the record types by id so we can use the name to match the "type" of opportunity
    public static Map<Id,Schema.RecordTypeInfo> byIdMap;
    
    public static void setupRecordTypeMap() {
        if (byIdMap == null) {
            byIdMap = Opportunity.getSobjectType().getDescribe().getRecordTypeInfosById();
            //RecordTypeHelper.getRecordTypesMap(ObjectHelper.OBJECT_OPPTY, byIdMap, null);
        }
    } // setupRecordTypeMap
    
    public static Schema.RecordTypeInfo getRtInfo(Id recordTypeId) {
        setupRecordTypeMap();
        return byIdMap.get(recordTypeId);
    } // getRtInfo
    
    /** For each opportunity see if there's an existing audit record attached to the opportunity. 
If there is, do nothing.
If not, and there is an ownership record matching the type of the opportunity, create a new audit record. 
*/
    public static void processOwnershipRecords(Opportunity[] opps, Map<Id,Account> acctMap, Map<Id,List<Prospect_Ownership__c>> acctOwnerMap, Map<Id,List<NSSAudit__c>> nssAuditListMap) {
        setupRecordTypeMap();
        
        // new audit records we are creating
        List<NSSAudit__c> newAudits = new List<NSSAudit__c>();
        
        Id firstOppId = null;
        
        for (Opportunity opp : opps) {
            if (firstOppId == null) {
                firstOppId = opp.Id;
            }
            NSSAudit__c foundAudit = null;
            List<NSSAudit__c> auditList = (opp.AccountId != null ? nssAuditListMap.get(opp.AccountId) : null);
            
            if (auditList != null && !auditList.isEmpty()) {
                // search through existing for one matching the opportunity
                for (NSSAudit__c audit : auditList) {
                    if (audit.Opportunity__c == opp.Id) {
                        foundAudit = audit;
                        break;
                    }
                }
            } // if (auditList != null
            
            // check the ownership records and if we need to create a new one.
            checkProspectOwnership(acctMap.get(opp.AccountId), opp, byIdMap.get(opp.RecordTypeId), (foundAudit == null), acctOwnerMap.get(opp.AccountId), newAudits, true, Label.Oppty_Sold_NSS_Sales_Status,'Opportunity Sold');
        } // for (Opportunity opp
        
        if (!newAudits.isEmpty()) {
            try {
                insert newAudits;
            } catch (Exception e) {
                ErrorLog.logError('OpptyMethods', 'processOwnershipRecords', 'Saving newAudits', firstOppId, e, newAudits[0], true);
            }
        }
    } // processOwnershipRecords
    
    public static Prospect_Ownership__c foundPo = null;
    public static NSSAudit__c newNssAudit = null;
    
    /** Check if we will create a new audit record by seeing if there's 1 (or more) appropriate ownership records.
*/
    public static Boolean checkProspectOwnership(Account acct, Opportunity opp, Schema.RecordTypeInfo rt, Boolean createNewAudit, List<Prospect_Ownership__c> ownerList, List<NSSAudit__c> newAudits, Boolean endOwnership, String status, String source) {
        Boolean foundOwnership = false;
        foundPo = null;
        newNssAudit = null;
        System.debug('checkProspectOwnership number of ownership records='+(ownerList == null ? -1 : ownerList.size()));
        // if no ownership records we're not going to do anything.
        if (ownerList != null && !ownerList.isEmpty()) {
            String nssTeam = getNssTeam(rt);
            System.debug('checkProspectOwnership rt='+rt+' nssTeam='+nssTeam);
            if (String.isNotBlank(nssTeam)) {
                // see if there's a matching ownership record
                for (Prospect_Ownership__c po : ownerList) {
                    // if same team and opportunity is within the commission period
                    if (po.NSS_Team__c == nssTeam && po.CommissionStart__c != null && po.CommissionStart__c <= opp.CloseDate && po.CommissionEnd__c >= opp.CloseDate) {
                        foundOwnership = true;
                        foundPo = po;
                        // if the ownership record isn't already ended then end it.
                        if (endOwnership && po.EndDate__c == null) {
                            ProspectOwnershipMethods.setStageExitInfo(po, acct, null, null, null, true, true, true);
                            po.ProcessNotes__c = 'Expired due to sold opportunity';
                        }
                        if (createNewAudit) {
                            // create audit record
                            createNewAudit(acct, opp, rt, po, status, source);
                            //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'newNssAudit='+newNssAudit));
                            if (newAudits != null) {
                                newAudits.add(newNssAudit);
                            }
                        } // if (createNewAudit
                    }
                } // for (Prospect_Ownership__c po
            } // if (String.isNotBlank(nssTeam
            
        } // if (ownerList != null
        
        return foundOwnership;
    } // checkProspectOwnership
    
    // format so that an 8 character client number is returned. This is for NSS.
    public static String formatClientNumber2(String branchClientNbr) {
        String retValue = '';
        if (String.isNotBlank(branchClientNbr)) {
            String branchNbr = '';
            String clientNbr = '';
            Integer dashPos = branchClientNbr.indexOf('-',0);
            // if no dash, assume entire thing is client number
            if (dashPos < 0) {
                clientNbr = branchClientNbr;
            } else {
                branchNbr = branchClientNbr.substring(0,dashPos);
                clientNbr = branchClientNbr.substring(dashPos+1);
            }
            System.debug('formatClientNumber2 branchClientNbr='+branchClientNbr+' branchNbr='+branchNbr+' clientNbr='+clientNbr);
            retValue = formatClientNumber2(branchNbr, clientNbr);
        }
        return retValue;
    } // formatClientNumber2
    
    public static String formatClientNumber2(String branchNbr, String clientNbr) {
        String retValue='';
        if (String.isNotBlank(clientNbr)) {
            retValue = clientNbr;
            if (retValue.length() == 4) {
                // we assume it's a 4 character branch number if less than 4 - we add in the branch nbr
                if (String.isNotBlank(branchNbr)) {
                    retValue = branchNbr + retValue;
                }
            } // if (retValue.length()
            // make sure the return value is 8 characters
            while (retValue.length() < 8) {
                retValue = '0'+retValue;
            }
        } // if (String.isNotBlank
        System.debug('formatClientNumber2 retValue='+retValue);
        return retValue;
    } // formatClientNumber2
    
    public static NSSAudit__c createNewAudit(Account acct, Opportunity opp, Schema.RecordTypeInfo rt, Prospect_Ownership__c po, String status, String source) {
        return createNewAudit(acct, opp, rt, (String)null, po, status, source);
    } // createNewAudit
    
    public static NSSAudit__c createNewAudit(Account acct, Opportunity opp, Schema.RecordTypeInfo rt, String nssProduct, Prospect_Ownership__c po, String status, String source) {
        return createNewAudit(acct, opp, rt, nssProduct, po, status, source, null);
    }
    
    public static NSSAudit__c createNewAudit(Account acct, Opportunity opp, Schema.RecordTypeInfo rt, String nssProduct, Prospect_Ownership__c po, String status, String source, String branchNbr) {
        Schema.RecordTypeInfo rtInfo = RecordTypeHelper.getDefaultRecordType('NSSAudit__c');
        String prodToUse = (String.isNotBlank(nssProduct) ? nssProduct : (rt != null ? NSSAuditHelper.getDefaultAuditProduct(rt.getName()) : null));
        newNssAudit = new NSSAudit__c(Opportunity__c=opp.Id, Account__c=opp.AccountId, Status__c=status
                                      ,Product__c=prodToUse
                                      ,Client_Number2__c=(acct != null ? formatClientNumber2(acct.AccountNumber) : null), Run_Submit_Date__c=opp.CloseDate
                                      ,Source__c=source
                                      ,RecordTypeId = (rtInfo != null ? rtInfo.getRecordTypeId() : null)
                                      ,BranchNumber__c=branchNbr);
        if (po != null) {
            newNssAudit.Prospect_Ownership__c=po.Id;
            newNssAudit.NSS_Team__c=po.NSR_NSS_Team__c;
            newNssAudit.NSS_Source__c=po.NSS_Source__c;
            newNssAudit.OwnerId=po.NSR_Name__c;
            newNssAudit.NSR_Name__c=po.NSR_Name__c;
        }
        //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'newNssAudit='+newNssAudit));
        return newNssAudit;
    } // createNewAudit
    
    public static String getNssTeam(Schema.RecordTypeInfo rt) {
        String nssTeam = null;
        String rtSalesOrg = RecordTypeHelper.getSalesOrgForRecordTypeName(rt != null ? rt.getName() : null);
        if (String.isNotBlank(rtSalesOrg)) {
            if (rtSalesOrg == UserHelper.SO_CORE || rtSalesOrg == UserHelper.SO_MMS || rtSalesOrg == UserHelper.SO_401) {
                nssTeam = rtSalesOrg;
            } else if (rtSalesOrg == UserHelper.SO_PEO_ASO || rtSalesOrg == UserHelper.SO_HNB) {
                nssTeam = UserHelper.SO_401;
            }
        }
        return nssTeam;
    } // getNssTeam
    
    public static final String OPP_TYPE_PAY='Payroll';
    public static final String OPP_TYPE_HRS='HRS';
    
    public static Set<String> VALID_OPP_TYPES = new Set<String>{OPP_TYPE_PAY,OPP_TYPE_HRS};
        
        public static void checkOpportunityType(Opportunity opp, String defaultValue, User usr, Account acct) {
            String oppTypeOnEntry = (opp != null ? opp.OpportunityType__c : null);
            System.debug('checkOpportunityType defaultValue='+defaultValue+' oppTypeOnEntry='+oppTypeOnEntry+' opp rt='+(opp != null ? opp.RecordTypeId : null));
            
            
            //JC this is no longer needed - if we use this method it will set the default from the profile if not passed in 
            /*     if (String.isBlank(opp.OpportunityType__c) && usr != null && usr.Profile != null && String.isNotBlank(usr.Profile.Name)) {
String profName = (usr.Profile.Name).left(Utilities.PROFILE_NAME_SIZE);
Profile_List__c prof = Profile_List__c.getInstance(profName);
if (prof != null && String.isNotBlank(prof.OppTypeDefault__c)) {
opp.OpportunityType__c = prof.OppTypeDefault__c;
}
}*/
            String salesOrg=null;  
            
            if (opp != null && opp.RecordTypeId != null && String.isBlank(opp.OpportunityType__c)) {
                setupRecordTypeMap();
                Schema.RecordTypeInfo rtInfo = byIdMap.get(opp.RecordTypeId);
                //rt info is not populated
                
                if (rtInfo != null) {
                    RecordType__c rtSetting = RecordTypeHelper.getRtSetting(rtInfo.getName());
                    salesOrg = (rtSetting != null ? rtSetting.Sales_Org__c : salesOrg);
                    if (rtSetting != null && String.isNotBlank(rtSetting.OpportunityType__c)) {
                        System.debug('checkOpportunityType setting OpportunityType__c by custom setting: '+rtSetting.OpportunityType__c);
                        opp.OpportunityType__c = rtSetting.OpportunityType__c;
                    }
                    // if not setup in the custom setting, use the legacy setting
                    if (String.isBlank(opp.OpportunityType__c)) {
                        if (salesOrg == null) {
                            salesOrg = RecordTypeHelper.getSalesOrgForRecordTypeName(rtInfo.getName());
                            System.debug('checkOpportunityType rt name='+rtInfo.getName()+' salesOrg='+salesOrg+' oppName='+opp.Name);
                        }
                        if (String.isNotBlank(salesOrg)) {
                            UserHelper uh = new UserHelper();
                            if (uh.isCore(salesOrg) || uh.isMMS(salesOrg)) {
                                opp.OpportunityType__c = OPP_TYPE_PAY;
                            } else if (uh.isHRS(salesOrg) && !uh.isHNB(salesOrg)) {
                                opp.OpportunityType__c = OPP_TYPE_HRS;
                            }
                        }
                    }
                } // if (rtInfo != null
                System.debug('checkOpportunityType OpportunityType__c='+opp.OpportunityType__c);
            } // if (opp != null
            system.debug('checkOpportunityType salesOrg='+ salesOrg); 
            // commented based on requirment US1: APR 0152220
            // if(salesOrg == UserHelper.SO_PEO_ASO && acct!=null && acct.PEO_Potential_Indicator__c !=null){
            //    opp.OpportunityType__c = UserHelper.SO_PEO; 
            // } else if (String.isNotBlank(defaultValue) && String.isBlank(oppTypeOnEntry)) {
            //     // if a default value is passed in then we'll use that. 
            //    System.debug('checkOpportunityType using defaultValue');
            //    opp.OpportunityType__c = defaultValue;
            // }//else 
            //APR0163688 Update Opp Type Default for PAS Reps, changed Oppty Type from PEO to HR Pro
            if(salesOrg == UserHelper.SO_PEO_ASO && acct!=null){
                opp.OpportunityType__c = Label.HR_Pro_Upgrade;
            }
            else  if (String.isNotBlank(defaultValue) && String.isBlank(oppTypeOnEntry)) {
                opp.OpportunityType__c = defaultValue;
            }
            
        } // checkOpportunityType
    
    /*
public static Set<String> PAY_OPP_TYPES = new Set<String>(Label.OppTypes_PAY.split(',')); 
public static Set<String> HRS_OPP_TYPES = new Set<String>(Label.OppTypes_HRS.split(',')); 

// set the latest opps on the accounts
public static void setLatestOpps(Opportunity [] opps, Map<Id,Opportunity> oldMap) {
System.debug('setLatestOpps number opps='+opps.size());
System.debug('setLatestOpps PAY_OPP_TYPES='+PAY_OPP_TYPES+' HRS_OPP_TYPES='+HRS_OPP_TYPES);
Map<Id, Account> acctToUpdateMap = new Map<Id,Account>();
ID mmsOppRecordTypeId = RecordTypeHelper.getRecordType('MMS Opportunity Record Type','Opportunity').getRecordTypeId();
List<Id> mmsOppAccIds = new List<Id>();
Map<Id,Account> mmsOppAccountMap = new Map<Id,Account>();
for (Opportunity opp : opps) {
if(opp.RecordTypeId == mmsOppRecordTypeId){
mmsOppAccIds.add(opp.AccountId);
}
}
if(!mmsOppAccIds.isEmpty()){
mmsOppAccountMap = new Map<Id,Account>([SELECT Id, Target_Field__c, (SELECT Id FROM Opportunities WHERE RecordTypeId=:mmsOppRecordTypeId AND StageName!='Not Sold' AND (NOT(StageName like 'Referred%')) AND (NOT(StageName like 'Sold%'))) FROM Account WHERE Id IN :mmsOppAccIds]);
}            
for (Opportunity opp : opps) {

Account acct = acctToUpdateMap.get(opp.AccountId);
if (acct == null) {
acct = new Account(Id=opp.AccountId);
}
Date notSoldDate = null;
Opportunity oldOpp = oldMap.get(opp.Id);
if (opp.StageName == Label.Oppty_Not_Sold && (oldOpp == null || oldOpp.StageName != opp.StageName)) {
notSoldDate = Date.today();
}
System.debug('setLatestOpps opp='+opp.Name+' type='+opp.OpportunityType__c);
if (PAY_OPP_TYPES.contains(opp.OpportunityType__c)) { // == OPP_TYPE_PAY) {
System.debug('setLatestOpps setting pay info');
acct.LatestPayrollOpp__c = opp.Id;
acct.PayOppCreatedDate__c = opp.CreatedDate;
acct.PayOppNSSSource__c = opp.NSS_Source__c;
acct.PayOppStatus__c = opp.StageName;
acct.PayOppDateNotSold__c = notSoldDate;
acctToUpdateMap.put(acct.Id, acct);
} else if (HRS_OPP_TYPES.contains(opp.OpportunityType__c)) { // == OPP_TYPE_HRS) {
System.debug('setLatestOpps setting hrs info');
acct.LatestHRSOpp__c = opp.Id;
acct.HRSOppCreatedDate__c = opp.CreatedDate;
acct.HRSOppNSSSource__c = opp.NSS_Source__c;
acct.HRSOppStatus__c = opp.StageName;
acct.HRSOppDateNotSold__c = notSoldDate;
acctToUpdateMap.put(acct.Id, acct);
} 

if(mmsOppAccountMap.containsKey(acct.Id) && mmsOppAccountMap.get(acct.Id).Target_Field__c != null && (mmsOppAccountMap.get(acct.Id).Opportunities == null || mmsOppAccountMap.get(acct.Id).Opportunities.size()<=1)){
acct.Target_Field__c = null;
acctToUpdateMap.put(acct.Id, acct);
}
} // for (Opportunity opp

if (!acctToUpdateMap.isEmpty()) {
try {
update acctToUpdateMap.values();
} catch (Exception e) {
ErrorLog.logError('OpptyMethods', 'setLatestOpps', 'Updating acctToUpdateMap', acctToUpdateMap.values()[0].Id, e, acctToUpdateMap.values()[0], true);
}
}
} // setLatestOpps
*/
    public static Opportunity[] getOpportunities(Id acctId, Integer nbrMonths, Integer maxRecords) {
        Date selectDate = Date.today().addMonths(-nbrMonths);
        Opportunity[] opptys = [Select Id
                                ,CloseDate
                                ,CreatedDate
                                ,CreatedById
                                ,CreatedBy.Name
                                ,Name
                                ,OwnerId
                                ,Owner.Name
                                ,NSS_Source__c
                                ,StageName
                                ,Account.AccountNumber
                                From Opportunity
                                Where AccountId = :acctId
                                and CloseDate >= :selectDate
                                order by CloseDate desc
                                limit :maxRecords];
        return opptys;
    } // getOpportunities
    
    public static void checkCommissionableOpps(List<Prospect_Ownership__c> posToCheck) {
        // extract the account ids - organize by account id.
        Map<Id,List<Prospect_Ownership__c>> posByAcctIdMap = new Map<Id,List<Prospect_Ownership__c>>();
        DateWrapper datesToCheck = new DateWrapper();
        
        buildPosByAcctIdMap(posToCheck, posByAcctIdMap, datesToCheck);
        if (posByAcctIdMap.isEmpty()) {
            // nothing to do here
            return;
        }
        
        OpportunityTeamMember[] otmToInsert = new OpportunityTeamMember[]{};
            OpportunityTeamMember[] otmToUpdate = new OpportunityTeamMember[]{};
                
                // get all opportunities that fall in the range
                Map<Id, List<Opportunity>> oppsByAcctIdMap = getOppsByAcctId(posByAcctIdMap.keySet());
        for (Id acctId : posByAcctIdMap.keySet()) {
            List<Opportunity> oppList = oppsByAcctIdMap.get(acctId);
            // make sure there are opportunities to process
            if (oppList != null && !oppList.isEmpty()) {
                List<Prospect_Ownership__c> poList = posByAcctIdMap.get(acctId);
                for (Opportunity opp : oppList) {
                    checkAddToSalesTeam(opp.RecordType.Name, opp.Id, opp.CloseDate, poList, otmToInsert, opp.OpportunityTeamMembers, otmToUpdate);
                } // for
                
            } // if (oppList != null
        } // for (Id acctId
        
        if (!otmToInsert.isEmpty()) {
            DmlHelper.performDML(otmToInsert, DmlHelper.DML_INSERT, 'OpptyMethods', 'checkCommissionableOpps', 'insert otmToInsert', false);
        }
        if (!otmToUpdate.isEmpty()) {
            DmlHelper.performDML(otmToUpdate, DmlHelper.DML_UPDATE, 'OpptyMethods', 'checkCommissionableOpps', 'update otmToUpdate', false);
        }
        ErrorLog.checkSave();
    } // checkCommissionableOpps
    
    public static void buildPosByAcctIdMap(List<Prospect_Ownership__c> posToCheck, Map<Id,List<Prospect_Ownership__c>> posByAcctIdMap, DateWrapper datesToCheck) {
        
        if (posToCheck != null) {
            for (Prospect_Ownership__c po : posToCheck) {
                if (po.Prospect_Client__c != null && po.CommissionStart__c != null && po.CommissionEnd__c != null) {
                    List<Prospect_Ownership__c> poList = posByAcctIdMap.get(po.Prospect_Client__c);
                    if (poList == null) {
                        poList = new List<Prospect_Ownership__c>();
                        posByAcctIdMap.put(po.Prospect_Client__c, poList);
                        datesToCheck.compareStartAndEndDate(po.CommissionStart__c, po.CommissionEnd__c);
                    } // if (poList == null
                    poList.add(po);
                } // if (po.Prospect_Client__c
            } // for (Prospect_Ownership__c po
        } // if (posToCheck != null
    } // buildPosByAcctIdMap
    
    public static Map<Id, List<Opportunity>> getOppsByAcctId(Set<Id> p_acctIdSet) {
        Map<Id, List<Opportunity>> oppsByAcctIdMap = new Map<Id, List<Opportunity>>();
        Map<Id,Opportunity> oppMap = getOppMapById(p_acctIdSet, null);
        
        for (Opportunity opp : oppMap.values()) {
            List<Opportunity> oppList = oppsByAcctIdMap.get(opp.AccountId);
            if (oppList == null) {
                oppList = new List<Opportunity>();
                oppsByAcctIdMap.put(opp.AccountId, oppList);
            }
            oppList.add(opp);
        } // for (Opportunity opp
        
        return oppsByAcctIdMap;
    } // getOppsByAcctId
    
    public static Map<Id,Opportunity> getOppMapById(Set<Id> p_acctIdSet, Set<Id> p_oppIdSet) {
        if (p_acctIdSet == null) {
            p_acctIdSet = new Set<Id>();
        }
        if (p_oppIdSet == null) {
            p_oppIdSet = new Set<Id>();
        }
        Map<Id,Opportunity> oppMap = new Map<Id,Opportunity>([Select Id, Name, AccountId, CloseDate, RecordType.Name, OpportunityType__c
                                                              ,Account.AccountNumber
                                                              ,(Select Id, OpportunityAccessLevel, OpportunityId, TeamMemberRole
                                                                ,UserId, User.HR_Person_Id__c
                                                                ,NSS_Source__c,NSS_Team__c
                                                                ,Prospect_Ownership__c, Prospect_Ownership__r.NSS_Source__c, Prospect_Ownership__r.NSS_Team__c
                                                                from OpportunityTeamMembers)
                                                              From Opportunity
                                                              Where AccountId in :p_acctIdSet
                                                              or Id in :p_oppIdSet]);
        return oppMap;
    } // getOppMapById
    
    public class DateWrapper {
        public Date startDate = Date.today();
        public Date endDate = Date.today();
        
        public void compareStartAndEndDate(Date checkStart, Date checkEnd) {
            if (checkStart < startDate) {
                startDate = checkStart;
            }
            
            if (checkEnd > endDate) {
                endDate = checkEnd;
            }
        } // compareStartAndEndDate
    } // class DateWrapper
    
    public static Set<String> wonOppRtIdSet = null;
    
    public static void checkWonOppRTSet() {
        if (wonOppRtIdSet == null) {
            wonOppRtIdSet = new Set<String>();
            String[] rtNames = Label.Oppty_Create_Asset_RT.split(',');
            System.debug('checkWonOppRTSet label='+Label.Oppty_Create_Asset_RT+' rtNames='+rtNames);
            
            if (rtNames != null && !rtNames.isEmpty()) {
                Map<String,Schema.RecordTypeInfo> byId = new Map<String,Schema.RecordTypeInfo>();
                RecordTypeHelper.getRecordTypesMap(new String[]{ObjectHelper.OBJECT_OPPTY}, rtNames, byId, null);
                wonOppRtIdSet.addAll(byId.keySet());
            } // if (rtNames != null
            
        } 
    } // checkWonOppRTSet
    
    // if we want to skip the check to write the payment information from the opportunity to the referral.
    public static Boolean SKIP_PAYMENT_TO_REFERRAL=false;
    
    // create assets when opportunity is marked as won
    private static void checkWonOpportunities(Id[] wonOppIdsToCheck) {
        Opportunity[] opps = [Select Id, Name, AccountId
                              ,(Select Id, Name, Quantity, ServiceDate
                                ,Product2Id
                                ,Product2.Id
                                ,Product2.Name
                                ,Product2.ProductCode
                                ,TotalPrice
                                From OpportunityLineItems
                                Where Product2.CreateAssetWhenSold__c = true)
                              ,(Select Id, Name
                                ,ContactId
                                ,Product2Id
                                From Assets__r)
                              ,(Select Id, ContactId
                                From OpportunityContactRoles
                                Where IsPrimary = true
                                limit 1)
                              From Opportunity
                              Where Id in :wonOppIdsToCheck];
        System.debug('checkWonOpportunities nbr ids='+wonOppIdsToCheck.size()+' nbr opps='+opps.size());
        
        Asset[] newAssets = new Asset[]{};
            for (Opportunity opp : opps) {
                System.debug('checkWonOpportunities opp='+opp.Name+' nbr assetsnbr olis='+ (opp.OpportunityLineItems != null ? opp.OpportunityLineItems.size() : -1));
                if (opp.OpportunityLineItems != null && !opp.OpportunityLineItems.isEmpty()) {
                    for (OpportunityLineItem oli : opp.OpportunityLineItems) {
                        if (!assetAlreadyExists(oli,opp.Assets__r)) {
                            System.debug('checkWonOpportunities creating a new asset');
                            Id contactId = (!opp.OpportunityContactRoles.isEmpty() ? opp.OpportunityContactRoles[0].ContactId : null);
                            Asset asst = new Asset(Name=oli.Product2.Name, AccountId = opp.AccountId, ContactId = contactId, Opportunity__c=opp.Id
                                                   ,Product2Id =  oli.Product2Id, Quantity = oli.Quantity
                                                   ,InstallDate = oli.ServiceDate, Price=oli.TotalPrice
                                                  );
                            newAssets.add(asst);
                        }
                    } // for (OpportunityLineItem oli
                } // if (opp.OpportunityLineItems != null
            } // for (Opportunity opp
        
        if (!newAssets.isEmpty()) {
            try {
                insert newAssets;
            } catch (Exception ex) {
                ErrorLog.logError('OpptyMethods', 'checkWonOpportunities', 'insert newAssets', wonOppIdsToCheck[0], ex, newAssets[0], true);
            } // try
        }
    } // checkWonOpportunities
    
    private static Boolean assetAlreadyExists(OpportunityLineItem oli, Asset[] assets) {
        Boolean alreadyExists = false;
        if (assets != null && !assets.isEmpty()) {
            for (Asset asst : assets) {
                if (asst.Product2Id == oli.Product2Id) {
                    alreadyExists = true;
                    break;
                } // if
            } // for (Asset asst
        } // if (assets != null
        System.debug('assetAlreadyExists alreadyExists='+alreadyExists);
        return alreadyExists;
    } // assetAlreadyExists
    
    // check the opportunities to see if there's a referral associated with the account that doesn't
    // already have an opportunity and matches the lead source
    public static void checkForReferrals(Map<String,Opportunity> oppsToCheckForRfrlsMap, Boolean allowUpdateOpp) {
        System.debug('checkForReferrals oppsToCheckForRfrlsMap='+oppsToCheckForRfrlsMap.size()+' allowUpdateOpp='+allowUpdateOpp);
        
        // referrals we need to update
        Referral__c[] updateReferrals = new Referral__c[]{};
            // leads that we want to delete
            Lead[] leadsToDelete = new Lead[]{};
                
                // select the referrals
                for (Referral__c rfrl : [Select Id, Name, Account__c,Referral_Id__c
                                         ,SecondaryLeadSource__c
                                         ,SellingLeadSource__c
                                         ,Selling_Opportunity__c
                                         ,SourceLead__c
                                         ,SourceLead__r.Id
                                         ,SourceLead__r.IsConverted
                                         From Referral__c
                                         Where Referral_Id__c in :oppsToCheckForRfrlsMap.keySet() //:referralIds
                                         //and Account__c in :accountIdSet
                                         //and Selling_Opportunity__c = null
                                         //and Id not in :existingRefs
                                        ]) {
                                            String key = rfrl.Referral_Id__c; //rfrl.Account__c+rfrl.Referral_Id__c;
                                            Opportunity opp = oppsToCheckForRfrlsMap.remove(key);
                                            if (opp != null) {
                                                if (opp.Id != null && rfrl.Selling_Opportunity__c == null) {
                                                    rfrl.Selling_Opportunity__c = opp.Id;
                                                    // make sure it's linked up to an opportunity
                                                    if (rfrl.Account__c == null) {
                                                        rfrl.Account__c = opp.AccountId;
                                                    }
                                                    updateReferrals.add(rfrl);
                                                    // if there's an existing unconverted lead on the referral, delete the lead.
                                                    if (rfrl.SourceLead__r != null && !rfrl.SourceLead__r.IsConverted) {
                                                        leadsToDelete.add(rfrl.SourceLead__r);
                                                    }
                                                } // if (opp.Id != null
                                                
                                                if (allowUpdateOpp) {
                                                    opp.ReferralLookup__c = rfrl.Id;
                                                    if (String.isBlank(opp.Level_2__c)) {
                                                        opp.Level_2__c = rfrl.SecondaryLeadSource__c;
                                                    }
                                                }
                                                
                                            } // if (opp != null
                                        } // for (Referral__c rfrl
        
        DmlHelper.performDML2(updateReferrals, DmlHelper.DML_UPDATE, 'OpptyMethods', 'checkForReferrals', 'Update Referrals', false);
        DmlHelper.performDML2(leadsToDelete, DmlHelper.DML_DELETE, 'OpptyMethods', 'checkForReferrals', 'Delete leads', false);
        ErrorLog.checkSave();
    } // checkForReferrals
    
    // update referrals from the opportunity
    public static void checkForReferralsToUpdate(Map<Id,Opportunity> oppByOppIdForRefMap, Map<Id,Opportunity> oldOppMap) {
        Referral__c[] referrals = [select Id
                                   ,OwnerId
                                   ,Name
                                   ,ActualRevenue__c
                                   ,Disposition__c
                                   ,MonthSaleReported__c
                                   ,NbrOfEmployees__c
                                   ,PendingRunOfPayroll__c
                                   ,Referral_Partner__r.Payment_Indicator__c                             
                                   ,ReferringAccountParent__c
                                   ,Referral_Account__c
                                   ,Referral_Contact__c 
                                   ,Referral_Id__c
                                   ,PartnerReferral__r.name                                 
                                   ,ReferralSourceAccount__c
                                   ,ReferralSourceContact__c
                                   ,Selling_Opportunity__c
                                   ,Referral_End_Date__c
                                   ,ProcessNotes__c 
                                   From Referral__c
                                   Where Selling_Opportunity__c in :oppByOppIdForRefMap.keySet()];
        Opportunity[] updateOpps = new Opportunity[]{};  
            //Duplicating map to update referrals not related to opps
            Map<Id,Opportunity> oppsToRefMap = new Map<Id,Opportunity>(oppByOppIdForRefMap);
        for (Referral__c rfrl : referrals) {
            //Update Referral Owner to round robin for ecommerce Selling opps that reach 20% probability
            //check if referral exists in the map to update owner/end date
            Opportunity oppty = oppByOppIdForRefMap.get(rfrl.Selling_Opportunity__c);
            Opportunity oldOpp = oldOppMap.get(rfrl.Selling_Opportunity__c);
            if(oppty != null){
                if(rfrl.Referral_End_Date__c == null 
                   && (((oppty.IsClosed != oldOpp.IsClosed || oppty.IsWon != oldOpp.IsWon) && oppty.IsClosed && !oppty.IsWon)
                       || (oppty.StageName!= null && oppty.StageName == Label.OppStage_No_Decision))){
                           rfrl.Referral_End_Date__c = system.today();
                           StringHelper.addToProcessNotes(rfrl,'End Date:Opp is Closed '+oppty.IsClosed+'Opp is Won '+oppty.IsWon+'Opp Stage Name '+oppty.StageName);
                       }
                else if(oppty.IsClosed != oldOpp.IsClosed && !oppty.IsClosed){
                    rfrl.Referral_End_Date__c = null;
                    StringHelper.addToProcessNotes(rfrl,'End Date is removed:Opp is Closed '+oppty.IsClosed+'Opp is Won '+oppty.IsWon);
                }  
            }// if(oppty != null 
            // If Referral is not associated to opp, update the associated referral 
            Opportunity opp = oppsToRefMap.remove(rfrl.Selling_Opportunity__c);
            if (opp != null) {
                rfrl.ActualRevenue__c = opp.Actual_Revenue__c;
                rfrl.Disposition__c = opp.Disposition__c;
                rfrl.MonthSaleReported__c = opp.Month_Sale_Reported__c;
                rfrl.NbrOfEmployees__c = opp.Of_Employees__c;
                rfrl.PendingRunOfPayroll__c = opp.Pending_Run_Of_Payroll__c;
                rfrl.BranchClientNumber__c  = opp.BranchClientNumber__c;
                rfrl.FedIdNumber__c = opp.FedIdNumber__c;
                
                if(rfrl.Referral_Account__c == null){
                    rfrl.Referral_Account__c = opp.Referral_Account__c;
                }//if
                
                if(rfrl.Referral_Contact__c  == null){
                    rfrl.Referral_Contact__c = opp.Referral_Contact__c;
                }//if
                
                if(rfrl.ReferralSourceAccount__c == null && opp.Referral_Account__r !=null){ 
                    rfrl.ReferralSourceAccount__c = opp.Referral_Account__r.Account__c;
                }//if 
                
                if ( rfrl.ReferralSourceContact__c == null && opp.Referral_Contact__r !=null) {
                    rfrl.ReferralSourceContact__c = opp.Referral_Contact__r.Contact__c;
                }//if
                
                if(rfrl.ReferringAccountParent__c !=null &&opp.Referral_Account__r !=null && opp.Referral_Account__r.Account__r !=null){
                    rfrl.ReferringAccountParent__c = opp.Referral_Account__r.Account__r.ReferralParent__c; 
                }//if 
                
                if(rfrl.Referral_Partner__r !=null && rfrl.Referral_Partner__r.Payment_Indicator__c !=null && (rfrl.Referral_Id__c !=null ||rfrl.Referral_Id__c == rfrl.PartnerReferral__r.name)){
                    rfrl.Referral_Id__c = rfrl.Referral_Id__c += rfrl.Referral_Partner__r.Payment_Indicator__c ;
                } //if
                
                if(opp.ReferralLookup__c==null){
                    updateOpps.add(new Opportunity(Id=opp.Id,ReferralLookup__c = rfrl.Id));
                }
            }
        } // for (Referral__c rfrl
        
        if (!referrals.isEmpty()) {
            ReferralTriggerActions.SKIP_TRIGGER=true;
            DmlHelper.performDML(referrals, DmlHelper.DML_UPDATE, 'OpptyMethods', 'checkForReferralsToUpdate', 'update rfrls from oppty', false);
            ReferralTriggerActions.SKIP_TRIGGER=false;
        }
        if (!updateOpps.isEmpty()) {
            SKIP_OPPTY_TRIGGERS = true;
            DmlHelper.performDML(updateOpps, DmlHelper.DML_UPDATE, 'OpptyMethods', 'checkForReferralsToUpdate', 'update opps with rfrl id', false);
            SKIP_OPPTY_TRIGGERS = false;
        }
        ErrorLog.checkSave();
    } // checkForReferralsToUpdate
    
    //Based on Owner, gets the default opportunity record type from the Sales Org custom setting and set that RT.
    public static void setDefaultRt(Map<Id,Opportunity[]> oppsByOwnerMap) {
        
        //get profile and sales org of all opportunity owners passed in to get the profile name and sales org
        Map<Id,User> ownerMap = new Map<Id,User>([SELECT Id,Profile.Name,Sales_Org__c FROM User WHERE Id in:oppsByOwnerMap.keyset()]);
        
        //get all opportunity record types in a map.  Seems more efficient than grabbing each one individually like above.
        Map<String,Schema.RecordTypeInfo> opptyRTMap = RecordTypeHelper.getRecordTypeByNameMap('Opportunity');
        Id virtualRTId = getRtIdFromMap('Core Virtual Sales',opptyRTMap); 
        
        for(Id userId : oppsByOwnerMap.keySet()){
            User owner = ownerMap.get(userId);
            Boolean ownerIsVirtual = (owner.Profile.Name == Utilities.PROF_CORE_VIRTUAL_SALES);
            for(Opportunity opptyToEvaluate : oppsByOwnerMap.get(userId)){
                
                if(ownerIsVirtual && opptyToEvaluate.RecordTypeId != virtualRTId){
                    opptyToEvaluate.RecordTypeId = virtualRTId;
                    system.debug('setDefaultRt changed to virtual');
                    /*if(opptyToEvaluate.StageName == 'Pending - Cold' && opptyToEvaluate.ReferralLookup__c == null){
opptyToEvaluate.StageName = 'Qualified';
}
else if (opptyToEvaluate.StageName == 'Pending - Cold' && opptyToEvaluate.ReferralLookup__c != null){
opptyToEvaluate.StageName = 'Pre-Qualified';
}*/
                }else if (!ownerIsVirtual && opptyToEvaluate.RecordTypeId == virtualRTId){
                    SalesOrg__c sos = SalesOrg__c.getInstance(owner.Sales_Org__c);
                    Id defaultRTId;
                    if(sos!=null){
                        Schema.RecordTypeInfo defaultRt = opptyRTMap.get(sos.OpptyRecordTypeName__c);
                        //if the default is found, set oppty owner
                        if(defaultRt!=null){
                            opptyToEvaluate.RecordTypeId = defaultRt.getRecordTypeId();
                            
                            system.debug('setDefaultRt changed to sales org Default');
                        }  
                    }//if(sos
                }//if(!ownerIsVirtual
            }//for(Opportunity opptyToEvaluate
        }//for(Id userId : defaultRTOppByOwnerMap.keySet()
        
    }//setDefaultRT
    
    // use this in case the record type doesn't exist yet in this environment
    public static Id getRtIdFromMap(String rtName, Map<String,Schema.RecordTypeInfo> rtMap) {
        Id rtId = null;
        if (rtMap.containsKey(rtName)) {
            rtId = rtMap.get(rtName).getRecordTypeId();
        }
        return rtId;
    } // getIdFromMap
    
    public static void evaluatePayrollPlatform(Opportunity[]opptyList){
        User runningUser = UserHelper.getRunningUser();
        Map<String,Schema.RecordTypeInfo> opptyRTMap = RecordTypeHelper.getRecordTypeByNameMap('Opportunity');
        
        ID payRTId = getRtIdFromMap('Core Opportunity Record Type',opptyRTMap);
        Id payDSARTId = getRtIdFromMap('Core Opportunity DSA Record Type',opptyRTMap);
        Id payRefRTId = getRtIdFromMap('Core Referral Revenue Opportunity Record Type - Rep',opptyRTMap);
        
        ID mmsRTId = getRtIdFromMap('MMS Opportunity Record Type',opptyRTMap);
        Id mmsDSARTId = getRtIdFromMap('MMS Opportunity (DSA) Record Type',opptyRTMap);
        Id mmsRefRTId = getRtIdFromMap('MMS Referral Revenue Opportunity - Rep',opptyRTMap);
        
        Id peoRTId = getRtIdFromMap('PEO Opportunity Record Type',opptyRTMap);
        Id peoFSSRTId = getRtIdFromMap('PEO Opportunity FSS Record Type',opptyRTMap);
        Id peoRefRTId = getRtIdFromMap('PEO Referral Revenue Opportunity',opptyRTMap); 
        
        Id asoRTId = getRtIdFromMap('ASO Opportunity Record Type',opptyRTMap);
        Id asoFSSRTId = getRtIdFromMap('ASO Opportunity FSS Record Type',opptyRTMap);
        Id asoRefRTId = getRtIdFromMap('ASO Referral Revenue Opportunity',opptyRTMap);
        
        // Id prismRTId = getRtIdFromMap('Prism PEO Opportunity Record Type',opptyRTMap);
        // Id prismFSSRTId = getRtIdFromMap('Prism PEO Opportunity FSS Record Type',opptyRTMap); 
        // Id prismRefRTId = getRtIdFromMap('Prism PEO Referral Revenue Opportunity',opptyRTMap);
        
        for(Opportunity oppty:opptyList){
            if(String.isBlank(oppty.Payroll_Platform__c) && oppty.OpportunityType__c == 'Payroll'){
                oppty.Payroll_Platform__c = 'PAY';
            }
            if(/*oppty.Payroll_Platform__c == 'PEO' && (oppty.RecordTypeId == asoRTId || oppty.RecordTypeId == prismRTId)){
oppty.RecordTypeId = peoRTId;
oppty.Service_Location__c = 'PEO Service Center';
}
else if (oppty.Payroll_Platform__c == 'PEO' && (oppty.RecordTypeId == asoFSSRTId || oppty.RecordTypeId == prismFSSRTId)){
oppty.RecordTypeId = peoFSSRTId;
oppty.Service_Location__c = 'PEO Service Center';
}
else if (oppty.Payroll_Platform__c == 'PEO' && (oppty.RecordTypeId == asoRefRTId || oppty.RecordTypeId == prismRefRTId)){
oppty.RecordTypeId = peoRefRTId;
oppty.Service_Location__c = 'PEO Service Center';
}
else if(oppty.Payroll_Platform__c == 'ASO' && (oppty.RecordTypeId == peoRTId || oppty.RecordTypeId == prismRTId || oppty.recordTypeId == mmsRTId)){
oppty.RecordTypeId = asoRTId;
oppty.Service_Location__c = 'ASO Service Center';
}
else if (oppty.Payroll_Platform__c == 'ASO' && (oppty.RecordTypeId == peoFSSRTId || oppty.RecordTypeId == prismFSSRTId || oppty.recordTypeId == mmsDSARTId)){
oppty.RecordTypeId = asoFSSRTId;
oppty.Service_Location__c = 'ASO Service Center';
}
else if (oppty.Payroll_Platform__c == 'ASO' && (oppty.RecordTypeId == peoRefRTId || oppty.RecordTypeId == prismRefRTId || oppty.recordTypeId == mmsRefRTId)){
oppty.RecordTypeId = asoRefRTId;
oppty.Service_Location__c = 'ASO Service Center';
}
else if(*/oppty.Payroll_Platform__c == 'Prism PEO' && (oppty.RecordTypeId == peoRTId || oppty.RecordTypeId == asoRTId)){
    //oppty.RecordTypeId = prismRTId;
    oppty.Service_Location__c = 'Prism Service Center';
}
            else if (oppty.Payroll_Platform__c == 'Prism PEO' && (oppty.RecordTypeId == peoFSSRTId || oppty.RecordTypeId == asoFSSRTId)){
                //oppty.RecordTypeId = prismFSSRTId;
                oppty.Service_Location__c = 'Prism Service Center';
            }
            else if (oppty.Payroll_Platform__c == 'Prism PEO' && (oppty.RecordTypeId == peoRefRTId || oppty.RecordTypeId == asoRefRTId)){
                //oppty.RecordTypeId = prismRefRTId;
                oppty.Service_Location__c = 'Prism Service Center';
            }
            // APR0163688: changed the record type to ASO if Oppty Type is HR Pro and Sales Org is PAS
           else if (oppty.OpportunityType__c == Label.HR_Pro_Upgrade && runningUser.Sales_Org__c == UserHelper.SO_PEO_ASO){
                oppty.RecordTypeId = asoRTId;
           } 
            //R
            else if( runningUser.Sales_Org__c == 'PEO' && (Label.OpptyMethods_PEO_Profiles.contains(runningUser.Profile.Name)) ){
                if(oppty.Payroll_Platform__c == Label.ZipSegment_PEO_C){
                    oppty.RecordTypeId =peoRTId;
                }else if(oppty.Payroll_Platform__c == 'Prism PEO'){
                    //oppty.RecordTypeId =prismRTId;
                }
            }
            /* else if(oppty.Payroll_Platform__c == Label.ZipSegment_PEO_C && userRecord[0].Sales_Org__c == 'PEO' && userRecord[0].Profile.Name == 'HRS Sales Manager - SB' ){
oppty.RecordTypeId = peoRTId;
}*/
            
            /*else if(oppty.Payroll_Platform__c == 'PAY' && (oppty.RecordTypeId == asoRTId || oppty.RecordTypeId == mmsRTId || oppty.RecordTypeId == payRTId)){
if(runningUser.Sales_Org__c == 'PAY' && oppty.RecordTypeId!=payRTId){
oppty.RecordTypeId = payRTId;
}
else if(runningUser.Sales_Org__c == 'MMS' && oppty.RecordTypeId != mmsRTId){
oppty.RecordTypeId = mmsRTId;
}
}
else if (oppty.Payroll_Platform__c == 'PAY' && (oppty.RecordTypeId == asoFSSRTId || oppty.RecordTypeId == mmsDSARTId || oppty.recordTypeId == payDSARTId)){
if(runningUser.Sales_Org__c == 'PAY' && oppty.RecordTypeId!=payDSARTId){
oppty.RecordTypeId = payDSARTId;
}
else if(runningUser.Sales_Org__c == 'MMS' && oppty.RecordTypeId != mmsDSARTId){
oppty.RecordTypeId = mmsDSARTId;
}
}
else if (oppty.Payroll_Platform__c == 'PAY' && (oppty.RecordTypeId == asoRefRTId || oppty.RecordTypeId == mmsRefRTId || oppty.recordTypeId == payRefRTId)){
if(runningUser.Sales_Org__c == 'PAY' && oppty.RecordTypeId!=payDSARTId){
oppty.RecordTypeId = payRefRTId;
}
else if(runningUser.Sales_Org__c == 'MMS' && oppty.RecordTypeId != mmsDSARTId){
oppty.RecordTypeId = mmsRefRTId;
}
}*/
        }
    }//evaluatePayrollPlatform
    
    
    public static final String CACHE_KEY='OpptyMethodsStageMap';
    
    public static Map<String,OpportunityStage> getOppStageMap() {
        Map<String,OpportunityStage> stageMap = (Map<String,OpportunityStage>)CacheManager.getOrg(CACHE_KEY);
        if (stageMap == null) {
            stageMap = new Map<String,OpportunityStage>();
            OpportunityStage[] stages = [SELECT MasterLabel,ForecastCategory,ForecastCategoryName,DefaultProbability FROM OpportunityStage WHERE IsActive = true];
            system.debug('getOppStageMap stages: '+stages);
            for (OpportunityStage os : stages) {
                stageMap.put(os.MasterLabel, os);
            }
            CacheManager.putOrg(CACHE_KEY,stageMap);
        }
        return stageMap;
    } // getOppStageMap
    
    public static void setForecastProbabilityFromOppStage(List<Opportunity> oppList){
        
        Map<String,OpportunityStage> oppStageByStageName = getOppStageMap();
        System.debug('setForecastProbabilityFromOppStage oppStageByStageName='+oppStageByStageName.size());
        
        for(Opportunity opp:oppList){
            OpportunityStage oppStage = oppStageByStageName.get(opp.StageName);
            System.debug('setForecastProbabilityFromOppStage opp='+opp.StageName+' oppStage='+oppStage);
            //if (oppStage!=null && ((opp.Probability != oppStage.DefaultProbability) || (opp.ForecastCategoryName != oppStage.ForecastCategoryName))) {
            if (oppStage!=null) {
                //StringHelper.addToProcessNotes(opp,'setForecastProb stage='+opp.StageName+' curProb='+opp.Probability+' DefProb='+oppStage.DefaultProbability+' oppFore='+opp.ForecastCategoryName+' defFore='+oppStage.ForecastCategoryName);
                opp.Probability = oppStage.DefaultProbability;
                opp.ForecastCategoryName = oppStage.ForecastCategoryName;
                System.debug('Probability='+opp.Probability+' ForecastCategoryName '+opp.ForecastCategoryName);
            }
        }
    }//setForecastProbabilityFromOppStage
    
    //Gets a List of all opportunities that went 'Not Sold' and had Solo Bundle associated/ had an external referral to Solo Bundle Mycorp made previously.  Sends out an email notification to Mycorp.
    public static void sendNotSoldEmailToMyCorp(Map<Id, Opportunity> opportunitiesNotSoldSoloMyCorp){
        Map<Id,Opportunity> oppByAccountId = new Map<Id,Opportunity>();
        Set<Opportunity> oppsWithProducts = new Set<Opportunity>(); 
        Set<Opportunity> oppsWithProductsAndReferrals = new Set<Opportunity>(); 
        List<OpportunityLineItem> olis = [SELECT Id, OpportunityId FROM OpportunityLineItem WHERE OpportunityId in :opportunitiesNotSoldSoloMyCorp.keySet() AND ProductCode = 'PSolo'];
        for(OpportunityLineItem oli: olis){
            Opportunity opp = opportunitiesNotSoldSoloMyCorp.get(oli.OpportunityId);
            if(!oppsWithProducts.contains(opp)){
                oppsWithProducts.add(opp);
                oppByAccountId.put(opp.AccountId,opp);
            }
        }
        List<Referral__c> refs =[SELECT Id, Account__c FROM Referral__c WHERE Account__c in :oppByAccountId.keySet() AND Referral_Partner__r.Name = 'MyCorp (Solo Bundle)'];
        for(Referral__c ref: refs) {
            Opportunity opp = oppByAccountId.get(ref.Account__c);
            oppsWithProductsAndReferrals.add(opp);
        }
        
        EmailTemplate templateId = [SELECT Id FROM EmailTemplate where name = 'MyCorporation Solo Bundle Not Sold'];
        List<Contact> myCorpContactId = new List<Contact>([SELECT Id FROM Contact where name = 'MyCorporation Contact']);
        List<Messaging.SingleEmailMessage> allmsgs = new List<Messaging.SingleEmailMessage>();
        
        if(myCorpContactId != null && !myCorpContactId.isEmpty()) {
            for(Opportunity oppWPR : oppsWithProductsAndReferrals)
            {
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setTemplateId(templateId.Id);
                mail.setTargetObjectId(myCorpContactId[0].Id);
                mail.setSaveAsActivity(false);
                mail.setWhatId(oppWPR.Id);
                allmsgs.add(mail);
            }
        }
        
        Messaging.sendEmail(allmsgs, false);
        MYCORP_EMAIL_SENT = true;
        
    } //sendNotSoldEmailToMyCorp
    
    //Gets a List of all inactive users with that ID and gives them the ownership of the opportunity.
    public static void changeOppOwnershipToInactiveUser(Map<Opportunity, Id> oppMap){
        Map<Id, User>  inactiveUsers = new Map<Id, User>([SELECT Id, Name From User WHERE isActive = false AND Id in : oppMap.values()]);
        User newUser = new User();
        for(Opportunity opp : oppMap.keySet())
        {
            newUser = inactiveUsers.get(opp.Inactive_User_Id__c);
            if(newUser!=null){
                opp.OwnerId = newUser.Id;   
                opp.Inactive_User_Id__c = null;
            }
            
            
        }
    }
    
    public static void checkReferralRunEffective(Map<Id,Opportunity> oppRunEffectiveMap){
        Id[] referralIds = new Id[]{};
            Opportunity[] updateOpptys = new Opportunity[]{};
                for(Opportunity opp:oppRunEffectiveMap.values()){
                    referralIds.add(opp.ReferralLookup__c);
                }
        Referral__c[] refs = [SELECT Id,Referring_Opportunity__c,Referring_Opportunity__r.CloseDate,Referring_Opportunity__r.OverrideRevenueSplit__c,
                              Referring_Opportunity__r.Probability,Referring_Opportunity__r.StageName,Selling_Opportunity__c
                              FROM Referral__c WHERE Id in: referralIds AND Referring_Opportunity__c!=null];
        for(Referral__c ref:refs){
            Opportunity referringOpp = ref.Referring_Opportunity__r;
            Opportunity sellingOpp = oppRunEffectiveMap.get(ref.Selling_Opportunity__c);
            system.debug('checkReferralRunEffective referring: '+referringOpp+' selling: '+sellingOpp);
            if(referringOpp!=null && sellingOpp!=null && referringOpp.CloseDate < sellingOpp.CloseDate && !referringOpp.OverrideRevenueSplit__c 
               && referringOpp.Probability > 0 && referringOpp.Probability <= 90){
                   referringOpp.CloseDate = sellingOpp.CloseDate;
                   updateOpptys.add(referringOpp);
               }
        }
        if(!updateOpptys.isEmpty()){
            DMLHelper.performDML2(updateOpptys,'Update','OpptyMethods','checkReferralRunEffective','updating referring opptys run effective',true);
        }
    }
    
    // so we only manage an account hold out once.
    public static Set<Id> accountIdHoldOutHandled = new Set<Id>();
    
    //updateExtendHoldout(opptyIdsForHoldoutUpdates);
    public static void updateExtendHoldout(Id[] oppIds){
        //if (Utilities.allowFuture()) {
        //    updateAccountHoldoutFuture(oppIds);
        //} else {
        updateAccountHoldout(oppIds);
        //}
    } // updateExtendHoldout
    
    //@future
    //public static void updateAccountHoldoutFuture(Id[] oppIds) {
    //     updateAccountHoldout(oppIds);
    //}
    
    public static void updateAccountHoldout(Id[] oppIds) {
        Map<Id,Account> acctUpdateMap = new Map<Id,Account>();
        Date expDate;
        //Account[] updateAcctList = new Account[]{};
        // TODO - if we want to make this work for other types of opportunities, need to select the other hold out fields.
        // only select the opps that are closed and won
        Opportunity[] opps = [SELECT Id,CloseDate,OwnerId,Owner.Sales_Org__c,AccountId, Probability, RecordTypeId, RecordType.Name, isClosed, isWon, Type, StageName, OpportunityType__c, Owner.IsActive
                                    ,Account.Name, Account.Client_Start_Date__c, Account.OwnerId,Account.Hold_Out__c,Account.Hold_Out_Expiration__c, Account.Permanent_Hold_Out_Description__c 
                                    ,Account.OasisPEOHoldOut__c,Account.OasisPEOHoldOutExpiration__c,Account.OasisPEOHoldOutReason__c, Account.OasisPEOAccountOwner__c 
                                    ,Account.HRS_Hold_Out__c,Account.HRS_Hold_Out_Expiration__c,Account.HRS_Permanent_Hold_Out_Description__c, Account.HRS_Account_Owner__c 
                                    ,Account.HNBF_Hold_Out__c,Account.HNBF_Hold_Out_Expiration__c,Account.HNBF_Permanent_Hold_Out_Description__c, Account.HNBF_Account_Owner__c 
                                    ,Account.Premier_PBS_Hold_Out__c,Account.Premier_PBS_Hold_Out_Expiration__c,Account.PEO_ASO_Permanent_Hold_Out_Description__c, Account.Premier_PBS_Account_Owner__c,Account.SalesParent__c
                                  ,ReferralLookup__c,ReferralLookup__r.Referral_Partner__c,ReferralLookup__r.Referral_Partner__r.Name
                              FROM Opportunity 
                              WHERE Id IN : oppIds]; 
                              //AND IsClosed=true and IsWon=true];    //APR0168449: Removed isClosed and isWon criteria from query and added it in oppty for loop
        System.debug('updateAccountHoldout oppIds='+oppIds.size()+' opps='+opps.size());
        for(Opportunity opp : opps){
            // don't pull in the account again if it's already been handled
            Account acct = (accountIdHoldOutHandled.contains(opp.AccountId) ? null : (acctUpdateMap.containsKey(opp.AccountId) ? acctUpdateMap.get(opp.AccountId) : opp.Account));
            // should we be using the sales org of the opp record type or the owner? 
            RecordType__c rtSetting = RecordTypeHelper.getRtSetting(opp.RecordType.Name);
            String salesOrg = (rtSetting != null && String.isNotBlank(rtSetting.Sales_Org__c) ? rtSetting.Sales_Org__c : opp.Owner.Sales_Org__c);
            
            HoldOut_ExpirationDates__c hod = HoldOut_ExpirationDates__c.getInstance(salesOrg);
            // SalesOrg__c.getInstance(salesOrg).Default_Run_Effective_Date__c
            System.debug('updateAccountHoldout salesOrg='+salesOrg+' has hod='+(hod != null));
            if (acct != null && hod != null) {
                Boolean hasHoldOut = (Boolean)acct.get(hod.Account_Hold_Out__c);
                System.debug('updateAccountHoldout hasHoldOut='+hasHoldOut+' Account_Hold_Out__c='+hod.Account_Hold_Out__c+' probability='+opp.Probability);
                Id ownerId = (Id)acct.get(hod.Account_Owner__c);
                system.debug('updateAccountHoldout ownerId='+ownerId);
               if(opp.IsClosed && opp.IsWon){
                   if (hod.Sold_Oppty_Hold_Out_Expiration_Duration__c != null) {
                    if (ownerId != opp.OwnerId) {
                        acct.put(hod.Account_Owner__c,opp.OwnerId);
                        system.debug('updateAccountHoldout updating account owner '+hod.Account_Owner__c+' to '+opp.OwnerId);
                    }
                    Date hoStartDate = (hasHoldOut ? opp.CloseDate : Date.today());
                    acct.put(hod.Account_Hold_Out__c,true);
                    /*APR0158030: Upadating Oppty Hold out as 90 days for Oppty Type Add on Ids*/
                    if(acct.SalesParent__c!= null && (opp.RecordType.Name == Label.MMS_Opportunity_DSA_Record_Type ||opp.RecordType.Name == Label.Core_Opportunity_DSA_Record_Type)){
                        expDate = hoStartDate.addDays(Integer.valueOf(Label.Opportunity_Hold_Out_Days));  
                    }  
                    else{
                        expDate = hoStartDate.addDays(Integer.valueOf(hod.Sold_Oppty_Hold_Out_Expiration_Duration__c));
                    }
                    acct.put(hod.Account_Hold_Out_Date__c,expDate);
                    acct.put(hod.HoldOutReasonFld__c,hod.SoldOppHoldOutReason__c);
                    system.debug('updateAccountHoldout acct'+acct.Name);
                    acctUpdateMap.put(acct.Id,acct);
                } 
                else if (hasHoldOut && hod.SoldStartedClearsHO__c) {
                    System.debug('updateAccountHoldout remove sold started holdout');
                    acct.put(hod.Account_Hold_Out__c,false);
                    acct.put(hod.Account_Hold_Out_Date__c,null);
                    acct.put(hod.HoldOutReasonFld__c,null);
                    acctUpdateMap.put(acct.Id,acct);
                }
                // BAU Jaipal APR0147082: PEO Client ownership: US1-US3, assigning hold outs and owner
                //if(opp!= null &&opp.OpportunityType__c == Label.ZipSegment_PEO_C && (opp.RecordType.Name == Label.PEO_Opportunity_FSS_Record_Type || opp.RecordType.Name == Label.RT_Oppty_PeoC_FSS) && opp.Owner.Isactive== true  /*&&acct.Isactive== true*/ 
                if(opp!= null &&opp.OpportunityType__c == Label.ZipSegment_PEO_C && (opp.RecordType.Name == Label.PEO_Opportunity_FSS_Record_Type ) && opp.Owner.Isactive== true  /*&&acct.Isactive== true*/ 
                   && opp.StageName == OPP_STAGE_SOLD_REV) // && opp.OwnerId!= acct.OasisPEOAccountOwner__c)
                {
                    System.debug('Opp'+opp+'Record Type:'+opp.RecordTypeId+ 'oppty Owner'+opp.Owner+'oppty StageName'+opp.StageName+opp.OwnerId+'acct.OwnerId'+acct.OwnerId);
                    acct.OasisPEOAccountOwner__c = opp.OwnerId; 
                    acct.OasisPEOHoldOut__c = true; 
                    acct.OasisPEOHoldOutExpiration__c = null; 
                    acct.OasisPEOHoldOutReason__c = 'PEO Client'; 
                    acctUpdateMap.put(acct.Id, acct);
                   }
                }
                //APR0168449: Added else if for Virtual Sales HR Services ownership
                else if(opp.ReferralLookup__c != null && opp.ReferralLookup__r.Referral_Partner__c!=null && Label.VS_HRS_Virtual.contains(opp.ReferralLookup__r.Referral_Partner__r.Name)){
            		expDate = Date.today().addDays(Integer.valueOf(Label.VS_HRS_Holdout_Days));
                    acct.Premier_PBS_Account_Owner__c = opp.OwnerId;
                    acct.Premier_PBS_Hold_Out__c = true;
                    acct.Premier_PBS_Hold_Out_Expiration__c = expDate;
                    acct.PEO_ASO_Permanent_Hold_Out_Description__c = Label.VS_HRS_Holdout_Reason;
                    acctUpdateMap.put(acct.Id,acct);
                 }
            	}
            /*
if(acct != null && opp.OwnerId == acct.OwnerId && hod != null && hod.Sold_Oppty_Hold_Out_Expiration_Duration__c != null) {
Date hoStartDate = (opp.Account.Hold_Out__c ? opp.CloseDate : Date.today());
acct.Hold_Out__c=true;
Date expDate = hoStartDate.addDays(Integer.valueOf(hod.Sold_Oppty_Hold_Out_Expiration_Duration__c));
acct.Hold_Out_Expiration__c =expDate;
acct.Permanent_Hold_Out_Description__c = hod.SoldOppHoldOutReason__c;
updateAcctList.add(acct);
}
*/
        }
        if(!acctUpdateMap.isEmpty()){
            accountIdHoldOutHandled.addAll(acctUpdateMap.keySet());
            DMLHelper.performDML2(acctUpdateMap.values(),DmlHelper.DML_UPDATE,'OpptyMethods','updateAccountHoldout','updating hold out expiration',true);
        }
        System.debug('updateAccountHoldout accountIdHoldOutHandled='+accountIdHoldOutHandled.size());
    } // updateAccountHoldout
    
    public static void revertRunEffectiveDate(Map<Opportunity, Opportunity> mapOppsToUpdateRunEffectiveDate){
        List<Opportunity> opptoUpdate = new List<Opportunity>();
        for(Opportunity opp : mapOppsToUpdateRunEffectiveDate.keySet()){
            
            //opp.CloseDate = mapOppsToUpdateRunEffectiveDate.get(opp).CloseDate;
            System.debug('mapOppsToUpdateRunEffectiveDate.get(opp).CloseDate; : ' + mapOppsToUpdateRunEffectiveDate.get(opp).CloseDate);
            opptoUpdate.add(new Opportunity(Id=opp.Id, CloseDate = mapOppsToUpdateRunEffectiveDate.get(opp).CloseDate));
        }
        
        if (!opptoUpdate.isEmpty()) {
            SKIP_OPPTY_TRIGGERS = true;
            DmlHelper.performDML(opptoUpdate, DmlHelper.DML_UPDATE, 'OpptyMethods', 'revertRunEffectiveDate', 'revert Opp close date ', false);
            SKIP_OPPTY_TRIGGERS = false;
        }   
    }// revertRunEffectiveDate
    
    
    
    
    //JDA
    public static void sendChecklistUpdateForLostOppty(Set<Id> opptyIds) {
        System.debug('JDA sendChecklistUpdateForLostOppty');
        // passing in the oppty IDs will get each checklist and update their status as a single DML request
        // Added allowFuture to make sure it is not already in an async context.
        if (Utilities.allowFuture()) {
            communityMethods.updateChecklistStepForLostOppty(opptyIds, 'OpptyMethods');
        }
    }
    //JDA sfdc-10804
    public static void sendChecklistUpdForOpptyStageChange(Set<Id> opptyIds) {
        System.debug('JDA sendChecklistUpdForOpptyStageChange');
        // passing in the oppty IDs will get each checklist and update their status as a single DML request
        communityMethods.updChecklistForOpptyStageChange(opptyIds, 'OpptyMethods');
    }
    
    // Send a future method call to update the peo UW checklist sales rep for each oppty in the list when owner changed
    public static void sendChecklistUpdateForOwnerChange(Set<Id> opptyIds) {
        System.debug('JDA sendChecklistUpdateForOwnerChange');
        // passing in the oppty IDs will get each checklist and update their status as a single DML request
        communityMethods.updateChecklistOwnerWithOptyOwner(opptyIds, 'OpptyMethods');
    }
    
    /**BAU Changes**/
    //Sending chatter message to SDR and hismanager if SDR is removed from Opportunity Team Member
    static List<opportunityTeamMember>  lstOTMs= new list<opportunityTeamMember>();
    public static void sendChatterMessageToSDRusers(Set<Id> opptyIds){
        system.debug('MAcheck2'+opptyIds);
        lstOTMs=[select userid,opportunityid,TeamMemberRole,Demo_date__c,Prospect_Ownership__c,OpportunityAccessLevel,user.name,User.ManagerId,Opportunity.Name,user.Manager.Name  from opportunityTeamMember where opportunityid IN : opptyIds AND  TeamMemberRole='Oasis SDR'];
        system.debug('MAcheck3'+lstOTMs);
        for(opportunityTeamMember oppt:lstOTMs){
            if(oppt.TeamMemberRole == 'Oasis SDR'){
                //system.debug('MA1'+oppt.User.Manager.Name);
                list<id> userids = new list<id>();
                userids.add(OPPT.UserId);
                userids.add(oppt.User.ManagerId);
                //String postText ='\n'+oppt.user.name+' has been removed from this Opportunity Team.'+'\n'+'Opportunity Name:'+oppt.Opportunity.Name+'\n'+'Opportunity URL:'+Url.getOrgDomainUrl().toExternalForm()+'/'+oppt.opportunityid;
                String postText ='\n'+' This Opportunity has been reassigned. '+oppt.user.name+' please verify you are still on the Team.'+'\n'+'Opportunity Name:'+oppt.Opportunity.Name+'\n'+'Opportunity URL:'+Url.getOrgDomainUrl().toExternalForm()+'/'+oppt.opportunityid;
                ChatterMentionPost.createChatterMentionPost(oppt.OpportunityId,userids ,  new String[]{ postText},true,false);
            }
        }
        ChatterMentionPost.postBatchFeedElements(); 
        
    }
    /**BAU Changes**/
    
    /**BAU Changes**/
    //Creating OTMs while SDR is creating opportunity 
    public static List<OpportunityTeamMember> CreateSDROppTeamMmembers(Map<Id,Id> mapOpportunityidAccountid){
        List<OpportunityTeamMember> otms=new List<OpportunityTeamMember>();
        Set<id> setAccountid=new Set<Id>();
        //getting all the account ids
        if(mapOpportunityidAccountid!=null && !mapOpportunityidAccountid.isEmpty()){
            for(Id accId:mapOpportunityidAccountid.values()){
                setAccountid.add(accId);
            }
        }
        
        //getting the ATMs
        List<AccountTeamMember> lstATMs=new List<AccountTeamMember>();
        if(setAccountid!=null && !setAccountid.isEmpty()){
            lstATMs=[Select id,TeamMemberRole,userid,user.NSS_Team__c,AccountId,Opportunity_Team_End_Date__c from AccountTeamMember where AccountId In:setAccountid and TeamMemberRole='Oasis SDR' and Opportunity_Team_End_Date__c>Today];
        }
        //Creating a map for accountid and related ATMS
        system.debug('MACheck1'+lstATMs);
        Map<Id,List<AccountTeamMember>> mapAccountIdListatms=new Map<Id,List<AccountTeamMember>>();
        for(AccountTeamMember atm:lstATMs){
            if(mapAccountIdListatms.containsKey(atm.AccountId)){
                List<AccountTeamMember> lstATMsforsingleaccount=mapAccountIdListatms.get(atm.AccountId);
                lstATMsforsingleaccount.add(atm);
            }
            else{
                List<AccountTeamMember> lstATMsforsingleaccount=new List<AccountTeamMember>();
                lstATMsforsingleaccount.add(atm);
                mapAccountIdListatms.put(atm.AccountId,lstATMsforsingleaccount);
            }
        }
        system.debug('MACheck2'+mapAccountIdListatms);
        //Compairing  mapOpportunityidAccountid and mapAccountIdListatms, and creating a map of opportunityid and List of ATMs
        Map<Id,List<AccountTeamMember>> mapOpportunityidListATMs=new Map<Id,List<AccountTeamMember>>();
        for(Id oppid:mapOpportunityidAccountid.keyset()){
            for(id accId:mapAccountIdListatms.keyset()){
                if(mapOpportunityidAccountid.get(oppid)==accId){
                    List<AccountTeamMember> lstATM=mapAccountIdListatms.get(accId);
                    mapOpportunityidListATMs.put(oppid,lstATM);
                }
            }
        }
        
        system.debug('MACheck3'+mapOpportunityidListATMs);
        //creating OTMs
        if(mapOpportunityidListATMs!=null && !mapOpportunityidListATMs.isEmpty()){
            system.debug('MACheck4'+mapOpportunityidListATMs);
            for(Id oppid:mapOpportunityidListATMs.keyset()){
                for(AccountTeamMember atm:mapOpportunityidListATMs.get(oppid)){
                    OpportunityTeamMember otm=new OpportunityTeamMember(OpportunityId=oppid,UserId=atm.userid,TeamMemberRole='Oasis SDR');
                    //otm.NSS_Source__c=mapUseridOpportunityteammember.get(uid).NSS_Source__c;
                    otm.NSS_Team__c=atm.user.NSS_Team__c;
                    //otm.OpportunityAccessLevel=mapUseridOpportunityteammember.get(uid).OpportunityAccessLevel;
                    otms.add(otm);
                }
            }
            
        }
        system.debug('MACheck5'+otms);
        //insert otms;
        return otms;
    }
    /**BAU Changes**/
    
    /**BAU Changes**/
    public static void InsertOTMs(List<OpportunityTeamMember> otms){
        try{
            DmlHelper.performDML2(otms, DmlHelper.DML_INSERT, 'OpptyMethods', 'InsertOTMs', 'Insert otms', false);
        }
        catch(Exception ex){
            system.debug('Exception on OTMs creation:'+ex);
        }
        
    }
    /**BAU Changes**/
    
    //Added Reetesh
    public static void setDSAonOpp(Map<Opportunity,Id> oppAccIdMap) {
        DateTime checkDate = System.now().addHours(-1 * Integer.valueOf(System.Label.Number_Of_Hours));
        List<DS_Denali__DialSource_Action__c> dsaList =[select id,DS_Denali__Account__c,DS_Denali__Account__r.Id,DS_Denali__Contact__c , DS_Denali__Contact__r.AccountId From DS_Denali__DialSource_Action__c where (DS_Denali__Account__r.Id in : oppAccIdMap.Values()  OR DS_Denali__Contact__r.AccountId in : oppAccIdMap.Values())and createdDate >=: checkDate];
        Map<Id,Id> dsaAccIdMap = new Map<Id,Id>();
        for(DS_Denali__DialSource_Action__c ds:dsaList){
            if(ds.DS_Denali__Account__c != null){
                dsaAccIdMap.put(ds.DS_Denali__Account__r.Id,ds.Id);
            }
            else if(ds.DS_Denali__Contact__c != null){
                dsaAccIdMap.put(ds.DS_Denali__Contact__r.AccountId,ds.Id);
            }
        }
        for(Opportunity op:oppAccIdMap.keyset()){
            if(dsaAccIdMap.get(oppAccIdMap.get(op)) != null){            
                op.DialSource_Action__c = dsaAccIdMap.get(oppAccIdMap.get(op));
            }
        }
        
    }
    //Shilpa - APR0127737: notify the referring rep when the selling Opp is marked Sold/not sold for Internal Referrals
    static List<Referral__c>  lstRef = new list<Referral__c>();
    public static void sendChatterToRef(Set<Id> opptyIdSold, String msgText){
        lstRef=[Select Id,PartnerType__c,Selling_Opportunity__c,User__c,Referring_User__c,Referring_User__r.Name,Referring_User__r.ManagerId,Referring_User__r.DSA_FSS__c from Referral__c where Selling_Opportunity__c IN : opptyIdSold];
        if(lstRef != null && !lstRef.isEmpty()){
            for(Referral__c ref:lstRef){                    
                if(ref.PartnerType__c == ReferralController.REF_INTERNAL){
                    list<id> userids = new list<id>();
                    if(ref.Referring_User__c != null){
                        userids.add(ref.Referring_User__c);
                        if(ref.Referring_User__r.ManagerId != null)
                            userids.add(ref.Referring_User__r.ManagerId);
                       /* if(ref.Referring_User__r.DSA_FSS__c != null)
                            userids.add(ref.Referring_User__r.DSA_FSS__c);*/
                    }
                    if(ref.User__c != null)
                        userids.add(ref.User__c);
                    String postText = 'Hello ' + ref.Referring_User__r.Name +','+'\n'+'\n'+ msgText +'\n'+'\n';
                    ChatterMentionPost.createChatterMentionPost(ref.Selling_Opportunity__c,userids ,  new String[]{ postText},false,false);
                }                   
            }
            ChatterMentionPost.postBatchFeedElements();
        }
    }
    //APR0161189 automation logic of setting DSM_Re_Engaged_Client_Interest__c if never been set
    public static void checkDSMReengagedOpptys(Opportunity[] opps){
        for(Opportunity op: opps){
            if(op.DSM_Reason_Won_Lost_Outcome__c == 'Re-Engaged Client Interest' && op.DSM_Re_Engaged_Client_Interest__c == false){
                op.DSM_Re_Engaged_Client_Interest__c = true;
            }
        }
    }
    
    /*APR0156837: Added below method to copy phone and consent to text from contact role to oppty */
    /* public static void updateOppPhoneandConsentToText(Id[] oppPhoneandConsentToText){
Boolean isChanged = false;
List<Opportunity> updateOpp = new List<Opportunity>();
Opportunity[] opps = [Select Id, Name,Phone__c,Consent_to_Text__c
,(Select Id, ContactId,Contact.MobilePhone,Contact.Consent_to_Text__c
From OpportunityContactRoles
Where IsPrimary = true limit 1)
From Opportunity Where Id in :oppPhoneandConsentToText];

for(Opportunity opp: opps){
for(OpportunityContactRole oppContactRoles: opp.OpportunityContactRoles){
if(oppContactRoles.Contact.MobilePhone!=null && oppContactRoles.Contact.MobilePhone!=opp.Phone__c){
opp.Phone__c = oppContactRoles.Contact.MobilePhone; 
isChanged = true;
}
// opp.Phone__c = oppContactRoles.Contact.MobilePhone!=null && oppContactRoles.Contact.MobilePhone!=opp.Phone__c? oppContactRoles.Contact.MobilePhone:null;
if(oppContactRoles.Contact.Consent_to_Text__c!=null && oppContactRoles.Contact.Consent_to_Text__c!=opp.Consent_to_Text__c){
opp.Consent_to_Text__c = oppContactRoles.Contact.Consent_to_Text__c;
isChanged = true;
}
//opp.Consent_to_Text__c = oppContactRoles.Contact.Consent_to_Text__c!=null && oppContactRoles.Contact.Consent_to_Text__c!=opp.Consent_to_Text__c? oppContactRoles.Contact.Consent_to_Text__c:null;
if(isChanged == true) {
updateOpp.add(opp);
}   


}    
} //End -for(Opportunity opp: opps) 
if(!updateOpp.isEmpty()){
SKIP_OPPTY_TRIGGERS=true;
DmlHelper.performDML2(updateOpp, DmlHelper.DML_UPDATE, 'OpptyMethods', 'updateOppPhoneandConsentToText', 'Update Oppty Phone and Consent to text', false);
SKIP_OPPTY_TRIGGERS=false;
}
}//End - updateOppPhoneandConsentToText */
    
} // OpptyMethods