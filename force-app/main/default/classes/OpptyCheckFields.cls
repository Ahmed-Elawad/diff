/** Check to see if this is an NSS Opportunity. If it is for Payroll or MMS, make sure
    that the unit indicator is set.
    
  History
  -------
  11/04/2010 Dan Carmen   Created
  03/07/2011 Dan Carmen   Added Core_Setup_Fee_v2__c field.
  05/27/2011 Dan Carmen   Added call to checkPrimaryComp
  09/07/2011 Dan Carmen   Updated primary comp mapping
  11/22/2011 Dan Carmen   Update for Default Product.
  11/28/2012 Dan Carmen   Changes for Primary Competition/Current Method
  12/24/2012 Dan Carmen   Added in check for Zip Tier field
  08/10/2013 Cindy Freeman  Changed class to public without sharing so when opty is created any user can add to Sales Team  
  01/16/2014 Dan Carmen   Added check that a user is active before adding them to the sales team
  07/18/2016 Dan Carmen   Change to properly get the zip tier for the opportunity.
  08/02/2016 Dan Carmen   Remove some old NSS code.
  11/30/2020 Dan Carmen   Store the previous probability when it changes.
  12/10/2020 Karthik Pedditi  Added Created by timeframe field to populate time frame upon creation.
  03/16/2021 Karthik Pedditi  Payroll Client Checkbox Functionality - APR0115826
  04/06/2021 Pujitha Madamanchi TimeFrame code updated to capture hour only
  05/18/2021 Carrie Marciano updated StageNames with OppStage labels
  06/24/2021 Carrie Marciano FY22 updates need to set Sales Cycle End Date for stage of No Decision/Probability 10%  
  09/07/2021 Pujitha Madamanchi APR0123900: Populate Proposal fields
  11/08/2021 Jermaine Stukes    Removed references to external wholesaler owner fields
  04/28/2022 Dan Carmen         Change code to use ZipQueries.getAccountQueryFields
  07/28/2022 Susmitha Somavarapu Commented checkTeamMembers and setWholesalers methods as per US10 Clearslide (Users are no longer automatically added to newly created 401k Opportunities with a Team Role of 'Wholesaler')
  10/18/2022 Jaipal  Added Original_PC_Client_Start_Date__c field to capture the data from Account Client Start Date when Opp is created
  01/25/2023 Dan Carmen         Changed recursion check because wasn't hitting the trigger for internal referrals without the approval process
  06/19/2023 Pujitha Madamanchi Added logging for Original PC Type
  06/21/2023 Dan Carmen         Fixed account query - was getting duplicate fields.
  10/16/2023 Dan Carmen         Updated checkMPSC to be more dynamic
  12/28/2023 Pujitha Madamanchi Move Original PC Type code to execute only on insert
  02/06/2024 Carrie Marciano	added condtion opp.OppSource__c != 'Huckleberry Clone' for oppties autocreated by Huckleberry API User

 */
public without sharing class OpptyCheckFields implements TriggerInterfaceC {

   //public static Set<String> ALREADY_RAN_SET = new Set<String>();
    
   public void handleTrigger(SObject[] p_recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter, Boolean isDelete) {
      SObject[] recs = TriggerMethods.checkRecs('OpptyCheckFields', p_recs, oldMap, isBefore, isAfter, null, null);
      // check what the type of the first record is
      System.debug('OpptyCheckFields.checkAllBeforeTrigger recs='+(recs != null ? recs.size() : -1));
      if (isBefore && recs != null && !recs.isEmpty()) {
         SObjectType recType = TriggerMethods.objType;
         //String recTypeName = recType.getDescribe().getName();
         //System.debug('handleTrigger ALREADY_RAN_SET: '+ALREADY_RAN_SET.size()); 
         //if (!ALREADY_RAN_SET.contains(recTypeName)) {
            checkOppsBefore((Opportunity[])recs, (Map<Id,Opportunity>)oldMap);
            // so we only hit the trigger once per object in the transaction
            //ALREADY_RAN_SET.add(recTypeName);
         //}
      } // if (recs != null
   } // checkAllBeforeTrigger

   // Check the value for primary competition/current method as it comes from NSS.
   //    Also used from AccountMethods
   public static String checkPrimaryComp(String primaryCompValue, String localCompValue) {
      String retVal = primaryCompValue;
      if (primaryCompValue != null) {
         if ((primaryCompValue == '3 SERVICE') &&
             (localCompValue != null)) {
            if (localCompValue == 'ADP') {
               retVal = 'ADP';
            } else if (localCompValue == 'LOC') {
               retVal = 'Local Competitor';
            } else if (localCompValue == 'EE') {
               retVal = 'EE Leasing/PEO';
            } else if (localCompValue == 'BNK') {
               retVal = 'Bank';
            } else if (localCompValue == 'PAX') {
               retVal = 'Paychex';
            } else if (localCompValue == 'CMP') {
               retVal = 'CompuPay';
            } else if (localCompValue == 'PPY') {
               retVal = 'PrimePay/Payroll 1';
            } else if (localCompValue == 'PAC') {
               retVal = 'Paycor';
            } else if (localCompValue == 'CD') {
               retVal = 'Ceridian';
            } else if (localCompValue == 'TPA') {
               retVal = 'TPA';
            } else if (localCompValue == 'WF') {
               retVal = 'Wells Fargo';
            } else if (localCompValue == 'INU') {
               retVal = 'Intuit - Quickbooks Software';
            } else if (localCompValue == 'SUR') {
               retVal = 'SurePayroll';
            } else if (localCompValue == 'UNK') {
               retVal = 'Unknown';
            } else {
               retVal = 'Other';
            }
         } else if (primaryCompValue == 'CPA' || primaryCompValue == '5 CPA') {
            retVal = 'CPA';
         } else if (primaryCompValue == 'COMPUTER' || primaryCompValue == 'MANUALLY' || primaryCompValue == '2 MANUALLY') {
            retVal = 'Manually';
         } else if (primaryCompValue == '1 NONE' || primaryCompValue == '9 NEW BUSINESS/NO COMPETITION' || primaryCompValue == '7 NEW BUSINESS') {
            retVal = 'No Competitor';
         } else if (primaryCompValue == 'PAYCHEX') {
            retVal = 'Paychex';
         } else if (primaryCompValue == 'UNKNOWN') {
            retVal = 'Unknown';
         } // if ((primaryCompValue
      } // if (primaryCompValue != null
      return retVal;
   } // checkPrimaryComp
   
   /* primary competition/current method from NSS

CPA - CPA
5 CPA - CPA
COMPUTER - Manually
MANUALLY - Manually
2 MANUALLY - Manually
1 NONE - No Competitor
9 NEW BUSINESS/NO COMPETITION - No Competitor
7 NEW BUSINESS - No Competitor
PAYCHEX - Unknown
3 SERVICE - translate
UNKNOWN - Unknown

*/

   public static void checkOppsBefore(Opportunity[] opps, Map<Id,Opportunity> oldMap) {
     // Map<Id,Opportunity[]> oppsByAcctIdMap = new Map<Id,Opportunity[]>();
      Opportunity[] oppsToCheck = new Opportunity[]{};
      Set<Id> oppIdOnInsertSet = new Set<Id>();
      Set<Id> acctIdSet = new Set<Id>();
      List<Opportunity> oppsForPayrollList=new List<Opportunity>(); //To store Opps for Payroll clients
       
      Map<Id,Schema.RecordTypeInfo> byIdMap = Opportunity.SObjectType.getDescribe().getRecordTypeInfosById();
      Boolean checkForZip = false;
      for (Opportunity opp : opps) {
         Opportunity oldOpp = (oldMap != null ? oldMap.get(opp.Id) : null);
         Schema.RecordTypeInfo rtInfo = (opp.RecordTypeId != null ? byIdMap.get(opp.RecordTypeId) : null);
         oppBeforeChecks(opp,oldOpp, rtInfo);
         if (opp.AccountId != null && String.isBlank(opp.Zip_Tier__c) ) {
            // if any conditions are met query the account to populate opp.
            
            oppsToCheck.add(opp);
            acctIdSet.add(opp.AccountId);
            
            //Opportunity[] oppsToCheck = (oppsByAcctIdMap.containsKey(opp.AccountId) ? oppsByAcctIdMap.get(opp.AccountId) : new Opportunity[]{});
            //oppsToCheck.add(opp);
            //oppsByAcctIdMap.put(opp.AccountId,oppsToCheck);
            // keep track of this so we only perform the check if needed.
            checkForZip = (checkForZip || String.isBlank(opp.Zip_Tier__c));
         } // if (opp.AccountId != null
         // only do these parts on insert
         if(oldOpp == null && (String.isBlank(opp.Original_PC_Number__c)
                              || String.isBlank(opp.Original_PC_Type__c)
                              || String.isBlank(opp.Frequency__c)
                              || opp.Employees_Paid_Per_Payroll__c == null)){
            oppsToCheck.add(opp);
            oppIdOnInsertSet.add(opp.Id);
            acctIdSet.add(opp.AccountId);
         }
         // if the Probability changes store the previous for easy reference.
          if (oldOpp != null && opp.Probability != oldOpp.Probability) {
              opp.PreviousProbability__c = oldOpp.Probability;
          }
          if(oldOpp==null && opp.AccountId != null){
              oppsForPayrollList.add(opp);
          }
      } // for (Opportunity opp
       if(!oppsForPayrollList.isEmpty()){
           updatePayrollcheckbox(oppsForPayrollList); //To evauate Payroll client on Opps during Opp Creation Only   
       }
       updateTimeframeonOpps(opps); //To update Timeframe on opps
       if (!oppsToCheck.isEmpty()) {
           updateFromAccts(oppsToCheck,acctIdSet,checkForZip, oppIdOnInsertSet);
       }
   } // checkOppsBefore
   
   public static String OPP_NEW='NewOpportunity';
   public static String OPP_CLONED='ClonedOpportunity';
   
   public static void oppBeforeChecks(Opportunity opp, Opportunity oldOpp, Schema.RecordTypeInfo rtInfo) {
      /*
      // uncheck criteria - do we need to check this? We only should have to worry if we're checking?
      ((opp.Employees_Paid_Per_Payroll__c >= 25 && !Flex_Time_Separate_Billing_Override__c)
       || (!Flex_Time_Separate_Billing_Override__c 
              && String.isNotBlank(opp.Product_Summary__c)
              && opp.Product_Summary__c.contains('Flex Admin')
              && opp.Product_Summary__c.contains('Flex Productivity')));
      */
      Boolean billingCheckbox = (opp.Employees_Paid_Per_Payroll__c < 25
          && !opp.Flex_Time_Separate_Billing_Override__c
          && String.isNotBlank(opp.Product_Summary__c)
          && opp.Product_Summary__c.contains('Flex Time')
          && (opp.Product_Summary__c.contains('PNG Admin')
                  || opp.Product_Summary__c.contains('PNG Productivity')));
      if (opp.Flex_Time_Separate_Billing__c != billingCheckbox) {
         opp.Flex_Time_Separate_Billing__c = billingCheckbox;
      }
      
      // save the current and previous ownerid fields.
      // TODO - do we still need to do this??
      if (opp.OwnerId != null && (oldOpp == null || opp.OwnerId != oldOpp.OwnerId)) {
         if (opp.Current_Owner_ID__c  != opp.OwnerId) {
            opp.Current_Owner_ID__c = opp.OwnerId;
         }
         if (oldOpp != null && oldOpp.OwnerId != opp.Previous_Owner_ID__c) {
            opp.Previous_Owner_ID__c = oldOpp.OwnerId;
         }
      }
      
      if (oldOpp == null && rtInfo != null && rtInfo.getName() == OpportunityCreateCase.RT_OPPTY_HNBF && String.isBlank(opp.Service_Location__c)) {
         opp.Service_Location__c = 'No Service Location';
      }
      
      // Replace the Update SLD Revenue workflow
      if (opp.LeadSource == 'Referral-Bank Referral' && opp.Disposition__c == 'SLD' && opp.Bank_Lead_ID__c != null) {
         //opp.recalculateFormulas();
         
         if (opp.SLD_Revenue__c != opp.Total_Estimated_Fee__c) {
            opp.SLD_Revenue__c = opp.Total_Estimated_Fee__c;
         }
      }
      // replace the Opportunity Retirement Services Default Status process builder
      if (opp.LeadSource == 'Referral-Bank Referral' && oldOpp == null && rtInfo != null 
                          && (rtInfo.getName() == OpportunityCreateCase.RT_OPPTY_401K || rtInfo.getName() == OpportunityCreateCase.RT_OPPTY_401K_FSS)
                          && opp.StageName != Label.OppStage_Qualified) {
         opp.StageName = Label.OppStage_Qualified;
      }
      
      // on a cloned opportunity, update the opportunity source to reflect that it's cloned.
      if (oldOpp == null && String.isNotBlank(opp.OpportunityId__c) && opp.OppSource__c != 'Lightning Clone' && opp.OppSource__c != 'Huckleberry Clone') {
         opp.OppSource__c='Opportunity Clone';
      }
      
      // replace the Opportunity Sales Cycle End Date process builder
      System.debug('oppBeforeChecks opp.Probability: '+opp.Probability+' opp.isWon: '+opp.isWon+' opp.IsClosed: '+opp.IsClosed+' opp.Sales_Cycle_End_Date__c: '+opp.Sales_Cycle_End_Date__c);
      if ((opp.Probability == 0 || opp.Probability > 79 || (!opp.isWon && opp.IsClosed)) && opp.Sales_Cycle_End_Date__c == null) {
         opp.Sales_Cycle_End_Date__c = Date.today();
      } else if (opp.Probability < 80 && !opp.IsClosed && opp.Sales_Cycle_End_Date__c != null ) {
         opp.Sales_Cycle_End_Date__c = null;
      }
      checkChat(opp,oldOpp);
      
      // replace the Opportunity - Doc Desk Update process builder
      if ((opp.StageName == 'Sold - Submitted to FSS' || opp.StageName == 'Pending - Submitted to VSS') 
            && !opp.Sent_to_Doc_Desk__c) {
         opp.Sent_to_Doc_Desk__c = true;
      }
      
      // if a new opportunity is created and the Opportunity_ID__c field is blank, populate it with 'NewOpportunity';
      // if an update comes through and the value is NewOpportunity, change it to the opp id.
      if (String.isBlank(opp.OpportunityId__c)) {
         if (oldOpp == null) {
            opp.OpportunityId__c = OPP_NEW;
         } else if (opp.Id != null) {
            opp.OpportunityId__c = opp.Id;
         }
      } else if (opp.OpportunityId__c == OPP_NEW && opp.Id != null) {
         opp.OpportunityId__c = opp.Id; 
      } else if (opp.OpportunityId__c == OPP_NEW && oldOpp == null) {
         // this should be a fringe case but handle this just in case
         opp.OpportunityId__c = OPP_CLONED;
      }

      //APR0123900
      if(opp.Probability >=50 && opp.Probability_greater_than_50__c == null ){
         opp.Probability_greater_than_50__c = system.today();
      }
      
      checkMPSC(opp, oldOpp, rtInfo);
   } // oppBeforeChecks
    
   public static String getServiceLocationKey(User usr) {
      String key = usr.Sales_Org__c+'Zone'+usr.Zone__c;
      return key;
   } // getServiceLocationKey
   
   public static void checkMPSC(Opportunity opp, Opportunity oldOpp, Schema.RecordTypeInfo rtInfo) {
      User runningUser = UserHelper.getRunningUser();
      System.debug('checkMPSC opp='+(opp != null)+' runningUser='+(runningUser != null ? runningUser.Name : 'No Running Usr')+' payrollUnits='+opp.Payroll_Units__c);
      if (oldOpp != null && opp.Payroll_Units__c != null && opp.Payroll_Units__c > 0 && oldOpp.Payroll_Units__c == null && runningUser != null) {
         String key = getServiceLocationKey(runningUser);
         OpptyMapping__c opptyMap = OpptyMapping__c.getInstance(key);
         System.debug('checkMPSC key='+key+' opptyMap='+(opptyMap != null));
         if (opptyMap != null && String.isNotBlank(opptyMap.ServiceLocation__c) && opp.Service_Location__c != opptyMap.ServiceLocation__c) {
            opp.Service_Location__c = opptyMap.ServiceLocation__c;
         }
      }
      /*
      if (oldOpp != null && opp.Payroll_Units__c != null && opp.Payroll_Units__c > 0 && oldOpp.Payroll_Units__c == null
         && runningUser != null && runningUser.Sales_Org__c == UserHelper.SO_MMS 
         && rtInfo != null && (rtInfo.getName() == OpportunityCreateCase.RT_OPPTY_MMS || rtInfo.getName() == OpportunityCreateCase.RT_OPPTY_MMS_DSA)) {
         String serviceLocation = ((runningUser.Zonetxt__c=='MID-ATLANTIC' || runningUser.Zonetxt__c=='EAST') ? 'MPSC Rochester 940'
                      : (runningUser.Zonetxt__c=='SOUTHEAST' ? 'MPSC Nashville 944'
                        : ((runningUser.Zonetxt__c=='SOUTHWEST' || runningUser.Zonetxt__c=='WEST') ? 'MPSC Phoenix 942'
                           : (runningUser.Zonetxt__c=='MIDWEST' ? 'MPSC Indianapolis 943' : null))));
         if (serviceLocation != null && opp.Service_Location__c != serviceLocation) {
            opp.Service_Location__c = serviceLocation;
            
         }
      } // if (oldOpp != null && opp.Payroll_Units__c
      */
   } // checkMPSC
   
   public static String CHAT_CAMP_REACTIVE=Label.Campaign_Chat_Reactive;
   public static String CHAT_CAMP_PROACTIVE=Label.Campaign_Chat_Proactive;

   public static Set<String> CHAT_CAMPAIGNS = new Set<String>{CHAT_CAMP_REACTIVE,CHAT_CAMP_PROACTIVE};

   private static Map<String,Campaign> chatCampaignMap = null;

   public static Map<String,Campaign> getChatCampaignMap() {
      if (chatCampaignMap == null) {
         chatCampaignMap = (Map<String,Campaign>)CacheManager.getOrg('chatCampaignMap');
      }
      if (chatCampaignMap == null) {
         chatCampaignMap = new Map<String,Campaign>();
         Campaign[] camps = [Select Id, Name
                               From Campaign
                              Where IsActive = true
                                and Name in :CHAT_CAMPAIGNS];
         for (Campaign camp : camps) {
            chatCampaignMap.put(camp.Name, camp);
         }
         
         if (!chatCampaignMap.isEmpty()) {
            CacheManager.putOrg('chatCampaignMap',chatCampaignMap);
         }
      }
      return chatCampaignMap;
   } // getChatCampaignMap

   public static void checkChat(Opportunity opp, Opportunity oldOpp) {
      if ((opp.Campaign__c != null && (oldOpp == null || opp.Campaign__c != oldOpp.Campaign__c))
          || (String.isNotBlank(opp.Chat_Type__c) && (oldOpp == null || opp.Chat_Type__c != oldOpp.Chat_Type__c))) {
         String campName = null;
         Map<String,Campaign> campaignMap = getChatCampaignMap();
         if (String.isNotBlank(opp.Chat_Type__c)) {
            campName = (opp.Chat_Type__c == 'Proactive' ? CHAT_CAMP_PROACTIVE : (opp.Chat_Type__c == 'Reactive' ? CHAT_CAMP_REACTIVE : null));
            if (campName != null) {
               Campaign camp = campaignMap.get(campName);
               if (camp != null) {
                  opp.Campaign__c = camp.Id;
               }
            }
         } else if (opp.Campaign__c != null) {
            Campaign reactive = campaignMap.get(CHAT_CAMP_REACTIVE);
            Campaign proactive = campaignMap.get(CHAT_CAMP_PROACTIVE);
            if (reactive != null && opp.Campaign__c == reactive.Id) {
               opp.Chat_Type__c = 'Reactive';
            } else if (proactive != null && opp.Campaign__c == proactive.Id) {
               opp.Chat_Type__c = 'Proactive';
            }
         }
      }
   } // checkChat
   
   public static void updateFromAccts(Opportunity[] opps, Set<Id> acctIdSet, Boolean checkForZip, Set<Id> oppIdOnInsertSet) {
      System.debug('updateFromAccts opps='+opps.size()+' acctIdSet='+acctIdSet.size()+' checkForZip='+checkForZip);
      Set<Id> acctIdSetQuery = new Set<Id>();
      acctIdSetQuery.addAll(acctIdSet);
       
      String acctQuery = (String)CacheManager.getOrg('OpptyCheckFieldsupdateFromAccts');
      if (acctQuery == null) {
         Set<String> fldSet = new Set<String>();
         DmlHelper.addFieldsToSet(Schema.SObjectType.Account.fieldSets.OpptyCheckFields, '', fldSet);
         fldSet.addAll(ZipQueries.getAccountQueryFields());
         acctQuery = DmlHelper.buildQueryFromSet(fldSet,'Account');
         CacheManager.putOrg('OpptyCheckFieldsupdateFromAccts', acctQuery);
      }

      acctQuery += ' where Id in :acctIdSetQuery ';
      Account[] accts = Database.query(acctQuery);
      Map<Id,Account> acctMap = new Map<Id,Account>();
      for (Account acct : accts) {
         acctMap.put(acct.Id, acct);
      }
      Map<String,List<Zip_Assignment__c>> zipAsgnMap = new Map<String,List<Zip_Assignment__c>>();
      if (checkForZip) {
         //checkForZipAssignments(accts,oppsByAcctIdMap);
         zipAsgnMap = checkForZipAssignmentMap(accts);
      } // if (checkForZip
      System.debug('updateFromAccts zipAsgnMap='+zipAsgnMap.size());
      
      User runningUser = UserHelper.getRunningUser();
      CreateOppAndMeeting coam = new CreateOppAndMeeting((runningUser != null ? runningUser.Sales_Org__c : UserHelper.SO_CORE));
      // get the Opportunity record type names since we only have the id passed in from the trigger.
      Map<Id, Schema.RecordTypeInfo> rtByIdMap = Opportunity.getSobjectType().getDescribe().getRecordTypeInfosById();
   
      for (Opportunity opp : opps) {
         Account acct = acctMap.get(opp.AccountId);
         if (acct != null) {
            if(oppIdOnInsertSet.contains(opp.Id)){
              if (String.isBlank(opp.Original_PC_Number__c)) {
                 opp.Original_PC_Number__c = acct.AccountNumber;
              }
               StringHelper.addToProcessNotes(opp, 'Original PC Type is updated based on Acct Type:'+acct.Type);
              if (String.isBlank(opp.Original_PC_Type__c)) {
                 opp.Original_PC_Type__c = acct.Type;
              }
              if (opp.Original_PC_Client_Start_Date__c == null && acct.Client_Start_Date__c!= null) {
                 opp.Original_PC_Client_Start_Date__c = acct.Client_Start_Date__c;
              }
              if (String.isBlank(opp.Frequency__c)) {
                 opp.Frequency__c = coam.convertFrequency(acct.Frequency__c);
              }
              System.debug('updateFromAccts  opp.Employees_Paid_Per_Payroll__c:'+  opp.Employees_Paid_Per_Payroll__c);
              if (opp.Employees_Paid_Per_Payroll__c == null) {
                 opp.Employees_Paid_Per_Payroll__c = acct.NumberOfEmployees;
          System.debug('updateFromAccts  acct.NumberOfEmployees:'+  acct.NumberOfEmployees);
              }  
            }
            if (String.isBlank(opp.Zip_Tier__c)) {
               Zip_Assignment__c[] zipAsgns = (String.isNotBlank(acct.Owner_Zip_Code__c) ? zipAsgnMap.get(acct.Owner_Zip_Code__c) : new Zip_Assignment__c[]{});
               System.debug('checkForZipAssignments opp='+opp.Name+' zipAsgns='+(zipAsgns != null ? zipAsgns.size() : -1)+' acct='+(acct != null ? acct.Name : 'not found'));
               checkForTierMatch(opp,rtByIdMap.get(opp.RecordTypeId),acct,zipAsgns);
            }
         } // if (acct != null
         
      } // for (Opportunity opp
      
   } // updateFromAccts
   
   public static Map<String,List<Zip_Assignment__c>> checkForZipAssignmentMap(Account[] accts) {
      Set<String> zipCodeSet = new Set<String>();
      for (Account acct : accts) {
         if (String.isNotBlank(acct.Owner_Zip_Code__c)) {
            zipCodeSet.add(acct.Owner_Zip_Code__c);
         }
      } // for (Account acct : accts
      
      Map<String,List<Zip_Assignment__c>> zipAsgnMap = (!zipCodeSet.isEmpty() ? ZipCheckOwner.getZipAsgns(zipCodeSet,null) : new Map<String,List<Zip_Assignment__c>>());
      return zipAsgnMap;
   } // checkForZipAssignmentMap
   /*
   public static void checkForZipAssignments(Account[] accts, Map<Id,Opportunity[]> oppsByAcctIdMap) {
      Map<String,Account[]> acctsByZipMap = new Map<String,Account[]>();
      for (Account acct : accts) {
         if (String.isNotBlank(acct.Owner_Zip_Code__c)) {
            Account[] zipAccts = (acctsByZipMap.containsKey(acct.Owner_Zip_Code__c) ? acctsByZipMap.get(acct.Owner_Zip_Code__c) : new Account[]{});
            zipAccts.add(acct);
            acctsByZipMap.put(acct.Owner_Zip_Code__c, zipAccts);
         } // if (String.isNotBlank(acct.Owner_Zip_Code__c
      } // for (Account acct : accts
      
      System.debug('checkForZipAssignments acctsByZipMap='+acctsByZipMap.size());
      if (!acctsByZipMap.isEmpty()) {
         // retrieve the zip code assignments 
         Map<String,List<Zip_Assignment__c>> zipAsgnMap = ZipCheckOwner.getZipAsgns(acctsByZipMap.keySet());
      
         System.debug('checkForZipTier zipCodeSet='+acctsByZipMap.size()+' zipAsgnMap='+zipAsgnMap.size());
      
         // get the Opportunity record type names since we only have the id passed in from the trigger.
         Map<Id, Schema.RecordTypeInfo> rtByIdMap = Opportunity.getSobjectType().getDescribe().getRecordTypeInfosById();
         for (String zipCode : zipAsgnMap.keySet()) {
            Account[] zipAccts = acctsByZipMap.get(zipCode);
            Zip_Assignment__c[] zipAsgns = zipAsgnMap.get(zipCode);
            if (zipAccts != null) {
               for (Account acct : zipAccts) {
                  Opportunity[] opps = oppsByAcctIdMap.get(acct.Id);
                  if (opps != null) {
                     for (Opportunity opp : opps) {
                        System.debug('checkForZipAssignments opp='+opp.Name+' zipAsgns='+(zipAsgns != null ? zipAsgns.size() : -1)+' acct='+(acct != null ? acct.Name : 'not found'));
                        checkForTierMatch(opp,rtByIdMap.get(opp.RecordTypeId),acct,zipAsgns);
                     } // for (Opportunity opp : opps
                  } // if (opps != null
               } // for (Acount acct : zipAcct
            } // if (zipAccts != null
         } // for (String zipCode : zipAsgnMap.keySet
      
      } // if (!acctsByZipMap.isEmpty
   } // checkForZipAssignments
   
   /** On the incoming opportunities, if the Zip Tier field is null, attempt to populate it.
    */
    /*
   public static void checkForZipTier(Opportunity[] opps) {
     // pull out the account ids
     Set<Id> acctIdSet = new Set<Id>();
     for (Opportunity opp : opps) {
        acctIdSet.add(opp.AccountId);
     } // for (Opportunity opp

      String query = 'Select Id, Name, Bis_ID__c, NumberOfEmployees, Owner_Zip_Code__c, X401K_Assets__c, X401k_Large_Market__c ';
      
      query += ZipCheckOwner.getAccountSettingQueryFlds();
      query += ' from Account where Id in :acctIdSet ';
      
      Map<Id,Account> acctMap = new Map<Id,Account>();
      
      for (Account acct : Database.query(query)) {
         acctMap.put(acct.Id, acct);
      }

      // get the zip codes of the accounts
      Set<String> zipCodeSet = new Set<String>();
      for (Account acct : acctMap.values()) {
         if (String.isNotBlank(acct.Owner_Zip_Code__c)) {
            zipCodeSet.add(acct.Owner_Zip_Code__c);
         }
      } // for (Account acct
      
      
      // retrieve the zip code assignments 
      Map<String,List<Zip_Assignment__c>> zipAsgnMap = ZipCheckOwner.getZipAsgns(zipCodeSet);
      
      System.debug('checkForZipTier zipCodeSet='+zipCodeSet.size()+' zipAsgnMap='+zipAsgnMap.size());
      
      // get the Opportunity record type names since we only have the id passed in from the trigger.
      Map<String,Schema.RecordTypeInfo> byId = new Map<String,Schema.RecordTypeInfo>();
      
      RecordTypeHelper.getRecordTypesMap(ObjectHelper.OBJECT_OPPTY, byId, null);
      
      for (Opportunity opp : opps) {
        Account acct = acctMap.get(opp.AccountId);
        List<Zip_Assignment__c> zips = (acct != null && acct.Owner_Zip_Code__c != null ? zipAsgnMap.get(acct.Owner_Zip_Code__c) : null);
        System.debug('checkForZipTier opp='+opp.Name+' zips='+(zips != null ? zips.size() : -1)+' acct='+(acct != null ? acct.Name : 'not found'));
         checkForTierMatch(opp,byId.get(opp.RecordTypeId),acct,zips);
      }
   } // checkForZipTier

   /** The value to set for the large market tier. */
   public static String LARGE_MARKET='LARGE_MARKET';
   
   public static Boolean checkForTierMatch(Opportunity opp, Schema.RecordTypeInfo oppRecType, Account acct, List<Zip_Assignment__c> zips) {
     String salesOrg = null;

     if (oppRecType != null) {
        salesOrg = RecordTypeHelper.getSalesOrgForRecordTypeName(oppRecType.getName());
     }
     System.debug('checkForTierMatch opp='+opp.Name+' salesOrg='+salesOrg+' oppRecType='+oppRecType);
      // if we can't determine the sales org then we can't proceed
      if (String.isNotBlank(salesOrg) && acct != null) {
       // use the large market indicator where we can
       if (salesOrg == UserHelper.SO_401 && acct.X401k_Large_Market__c && acct.Bis_ID__c != null) {
            opp.Zip_Tier__c = LARGE_MARKET;
       } else if (zips != null) {
            Decimal numEmps = (opp.Employees_Paid_Per_Payroll__c != null ? opp.Employees_Paid_Per_Payroll__c : acct.NumberOfEmployees);
          for (Zip_Assignment__c za : zips) {
             if (salesOrg == za.Sales_Org__c && ZipCheckOwner.checkZipCriteria(za, acct, (Integer)numEmps,(Long)acct.X401K_Assets__c)) {
                opp.Zip_Tier__c = za.Segment_Name__c;
                  break;
             }
          } // for (Zip_Assignment__c
        } // if (salesOrg != null
     
      } // if (salesOrg != null
     System.debug('checkForTierMatch opp.Zip_Tier__c='+opp.Zip_Tier__c);
     return (opp.Zip_Tier__c != null);
   } // checkForTierMatch
   
   public static void checkForSalesTeam(Id[] opptyIds) {
      // retrieve the opportunities - only select 401k opportunities and wholesaler team members
      Opportunity[] opps = [Select Id
                                  ,Zip_Tier__c
                                  ,Account.Id
                                  ,Account.Owner_ZipCode__c
                                  ,(Select Id
                                          ,TeamMemberRole
                                          ,UserId
                                      From OpportunityTeamMembers
                                     Where TeamMemberRole in (:ZipCheckOwner.AT_INT_WHOLE, :ZipCheckOwner.AT_EXT_WHOLE))
                              From Opportunity
                             Where Id in :opptyIds
                               and Zip_Tier__c = :OpptyCheckFields.LARGE_MARKET
                               and RecordType.Name in (:OpportunityCreateCase.RT_OPPTY_401K,:OpportunityCreateCase.RT_OPPTY_401K_FSS)];

      Set<String> zipCodeSet = new Set<String>();
      Map<String,List<Opportunity>> oppByZipCodeMap = new Map<String,List<Opportunity>>();
      for (Opportunity opp : opps) {
         if (opp.Account != null && opp.Account.Owner_ZipCode__c != null) {
            zipCodeSet.add(opp.Account.Owner_ZipCode__c);
            List<Opportunity> oppList = oppByZipCodeMap.get(opp.Account.Owner_ZipCode__c);
            if (oppList == null) {
               oppList = new List<Opportunity>();
               oppByZipCodeMap.put(opp.Account.Owner_ZipCode__c,oppList);
            } // if (oppList == null
            oppList.add(opp);
         } // if (opp.Account
      } // for (Opportunity
        
       // this is commented as user story 10 clear slide APR0130103
      // only continue if zip codes were retrieved
   /*   if (!oppByZipCodeMap.isEmpty()) {
         // retrieve the zip code assignments 
         Map<String,List<Zip_Assignment__c>> zipAsgnMap = ZipCheckOwner.getZipAsgns(oppByZipCodeMap.keySet());
         
         // the team members we are creating
         OpportunityTeamMember[] newTeamMembers = new OpportunityTeamMember[]{};
         
         // for (String zipCode : zipAsgnMap.keySet()) {
         //    checkTeamMembers(oppByZipCodeMap.get(zipCode),zipAsgnMap.get(zipCode),newTeamMembers);
         // } this is commented as part of us10 clear slide APR0130103
         
         if (!newTeamMembers.isEmpty()) {
            insert newTeamMembers;
         }  
      } */ // if (!zipCodeSet.isEmpty
      
   }  // checkForSalesTeam
   // this is commented as user story 10 clear slide APR0130103
   // /** Find the wholesalers for the zip code and check the opportunity.
   //  */
   // private static void checkTeamMembers(List<Opportunity> opps, List<Zip_Assignment__c> zipAsgns, OpportunityTeamMember[] newTeamMembers) {
   //    // get the wholesalers (if they exist)
   //    Id internalWholesalerId = null;
   //    Id externalWholesalerId = null;
   //    for (Zip_Assignment__c za : zipAsgns) {6
   //      // only add active users
   //      if (za.Sales_Org__c == UserHelper.SO_WHOLESALER && za.User__c != null && za.User__r != null && za.User__r.IsActive) {
   //         if (za.Segment_Name__c == UserHelper.WHOLESALER_INTERNAL) {
   //             internalWholesalerId = za.User__c;
   //         } /*else if (za.Segment_Name__c == UserHelper.WHOLESALER_EXTERNAL) {
   //             externalWholesalerId = za.User__c;
   //         }*/
   //       } // if (za.Sales_Org__c = UserHelper.SO_WHOLESALER
   //    } // for (Zip_Assignment__c
      
   //    // make sure we have at least one of the wholesalers to proceed
   //    if (internalWholesalerId != null || externalWholesalerId != null) {
   //      setWholesalers(opps,newTeamMembers,internalWholesalerId, externalWholesalerId);
   //    } // if (internalWholesaler)
      
   // } // checkTeamMembers

   // /** Set the wholesalers on the opportunity.
   //  */
   // private static void setWholesalers(List<Opportunity> opps, OpportunityTeamMember[] newTeamMembers, Id internalWholesalerId, Id externalWholesalerId) {
   //    for (Opportunity opp : opps) {
   //       OpportunityTeamMember internalWholesaler = null; 
   //       OpportunityTeamMember externalWholesaler = null;
   //       if (opp.OpportunityTeamMembers != null && !opp.OpportunityTeamMembers.isEmpty()) {
   //          for (OpportunityTeamMember otm : opp.OpportunityTeamMembers) {
   //             if (otm.TeamMemberRole == ZipCheckOwner.AT_INT_WHOLE) {
   //                internalWholesaler = otm;
   //             } else if (otm.TeamMemberRole == ZipCheckOwner.AT_EXT_WHOLE) {
   //                externalWholesaler = otm;
   //             }
   //          }
   //       } // if (opp.OpportunityTeamMembers
            
   //       if (internalWholesalerId != null && internalWholesaler == null) {
   //          OpportunityTeamMember otm = new OpportunityTeamMember(OpportunityId=opp.Id, UserId=internalWholesalerId, TeamMemberRole=ZipCheckOwner.AT_INT_WHOLE);
   //          newTeamMembers.add(otm);
   //       }

   //       if (externalWholesalerId != null && externalWholesaler == null) {
   //          OpportunityTeamMember otm = new OpportunityTeamMember(OpportunityId=opp.Id, UserId=externalWholesalerId, TeamMemberRole=ZipCheckOwner.AT_EXT_WHOLE);
   //          newTeamMembers.add(otm);
   //       }

   //    } // for (Opportunity opp
   // } // setWholesalers
    
  //To populate Created Timeframe field on Opportunity on creation
    public static void updateTimeframeonOpps(List<Opportunity> newOpps) {
        for(opportunity newRec:newOpps){
            if(newRec.Created_by_Timeframe__c == null && newRec.NSS_Source__c!= null && newRec.NSS_Source__c.startsWith('Inbound')){
               newRec.Created_by_Timeframe__c = newRec.CreatedDate!=null ? newRec.CreatedDate.format(Label.CallTime_format,Label.CallTime_TimeZone):DateTime.now().format(Label.CallTime_format,Label.CallTime_TimeZone);
            }
        }
    }
        
    //To determine Payroll client based on Type of Account
    public static void updatePayrollcheckbox(List<Opportunity> newOpps) {
        List<String> payrollClients = new List<String>(); 
        
        //fetching the metadata records
        List<OpptyPayrollClient__mdt> getOpptyPayrollClients = new List<OpptyPayrollClient__mdt>([SELECT label,PayrollClient__c from OpptyPayrollClient__mdt]);
        
        for(OpptyPayrollClient__mdt record :getOpptyPayrollClients ){
            if(record.PayrollClient__c==true){
                payrollClients.add(record.Label);
                //system.debug('payrollClients'+payrollClients); 
            }
        }
        
        set<Id> accIds=new set<Id>();
        for(Opportunity opp:newOpps){
                    accIds.add(opp.AccountId);
          }
        Map<ID, Account> accMap = new Map<ID, Account>([SELECT Id,Type FROM ACCOUNT WHERE Id IN:accIds]);
        for(Opportunity opp:newOpps){
            if(opp.AccountId!=null){
                if(!accMap.isempty() && accMap.containsKey(opp.AccountId)){
                    string typeVal=accMap.get(opp.AccountId).Type;
                    system.debug('typeVal'+typeVal);
                    if(!payrollClients.isEmpty() && payrollClients.contains(typeVal)){
                        opp.Payroll_Client__c=true;
                    }
                }
            }
        }
    }
} // class OpptyCheckFields