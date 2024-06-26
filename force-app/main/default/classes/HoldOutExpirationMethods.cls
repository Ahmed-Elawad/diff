/* 
 * A class to contain all methods needed to recalc Hold Out Expiration Dates
 * History
 * -------
 * 08/11/2015 Cindy Freeman     Created
 * 12/07/2015 Cindy Freeman	  	Added code to handle Core Event linked to opty but not to account or contact
 * 09/29/2016 Dan Carmen        Added check for exception
 * 01/03/2018 Cindy Freeman		Added logic and a new method to edit hold outs based on Permanent Hold Out Description
 * 02/15/2019 Cindy Freeman		Fix to prevent permanent HO description from getting cleared
 * 03/06/2019 Cindy Freeman		Fix to only clear Hold Out when Opty marked Not Sold and opty owned by Virtual Micro NSS rep
 * 03/12/2019 Cindy Freeman		Fix to look up from opty to Referral Partner to edit Hold Outs, added ProcessNotes
 * 07/17/2019 Dan Carmen        Added workflow functionality into the code
 * 02/08/2021 Matt Fritschi		Added new Hold Out rules for SMB Channel Not Sold Opptys
   02/10/2021 Brandon Vidro     Update to reviseTaskExpiration to include HRS 
   05/19/2021 Dan Carmen        Updated to use IsClosed=true and IsWon=false for not sold opps.
   05/27/2021 Josh Cartwright	APR0116141 add check for opportunity lead source = channel before extending holdouts on not sold oppty
   02/22/2022 Carrie Marciano   Added BenAdmin Holdout fields
   01/23/2023 Dan Carmen        Change Interface, increment API version
   02/12/2024 Carrie Marciano	added P_C_Hold_Out__c, P_C_Permanent_Hold_Out_Description__c and P_C_Hold_Out_Expiration__c to reviseHoldOutExpiration method

 */ 
public without sharing class HoldOutExpirationMethods implements TriggerInterfaceC {
   
   // for recursion
   public static Set<String> ALREADY_RAN_SET = new Set<String>();
    
   public void handleTrigger(SObject[] p_recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter, Boolean isDelete) {
      SObject[] recs = TriggerMethods.checkRecs('CallCenterHelper', p_recs, oldMap, isBefore, isAfter, null, null);
      System.debug('HoldOutExpirationMethods.handleTrigger recs='+(recs != null ? recs.size() : -1));

      if (recs==null || recs.isEmpty()) {
         return;
      }
      SObjectType objType = TriggerMethods.objType;
      if (isBefore) {
         if (objType == Contact.sObjectType) {
            checkContactsBefore((Contact[])recs,(Map<Id,Contact>)oldMap);
         } else if (objType == Account.sObjectType) {
            checkAccountsBefore((Account[])recs,(Map<Id,Account>)oldMap);
         } else if (objType == Lead.sObjectType) {
            checkLeadsBefore((Lead[])recs,(Map<Id,Lead>)oldMap);
         }
      } else if (isAfter) {
          if (objType == Opportunity.sObjectType) {
             checkOppsAfter((Opportunity[])recs,(Map<Id,Opportunity>)oldMap);
          }
      }
   } // checkAllBeforeTrigger

   public static void checkLeadsBefore(Lead[] lds, Map<Id,Lead> oldMap) {
      // only on update right now
      if (oldMap == null) {
         return;
      }
      for (Lead ld : lds) {
         Lead oldLd = (oldMap != null ? oldMap.get(ld.Id) : null);
         // if the hold out is removed, make sure the date is cleared
         // workflow: Clear Contact Hold out Exp
         if (oldLd != null && oldLd.Hold_Out__c && !ld.Hold_Out__c) {
            if (ld.Hold_Out_Expiration__c != null) {
               StringHelper.addToProcessNotes(ld,'Clear Hold Out Expiration '+ld.Hold_Out_Expiration__c);
               ld.Hold_Out_Expiration__c = null;
            }
            if (ld.Hold_Out_Reason__c != null) {
               StringHelper.addToProcessNotes(ld,'Clear Hold Out Reason '+ld.Hold_Out_Reason__c);
               ld.Hold_Out_Reason__c = null;
            }
         }
      } // for (Lead ld : lds
   } // checkLeadsBefore
   
   public static void checkContactsBefore(Contact[] ctcts, Map<Id,Contact> oldMap) {
      // only on update right now
      if (oldMap == null) {
         return;
      }
      for (Contact ctct : ctcts) {
         Contact oldCtct = (oldMap != null ? oldMap.get(ctct.Id) : null);
         // if the hold out is removed, make sure the date is cleared
         // workflow: Clear Contact Hold out Exp
         if (oldCtct != null && oldCtct.Hold_Out__c && !ctct.Hold_Out__c) {
            if (ctct.Hold_Out_Expiration__c != null) {
               StringHelper.addToProcessNotes(ctct,'Clear Hold Out Expiration '+ctct.Hold_Out_Expiration__c);
               ctct.Hold_Out_Expiration__c = null;
            }
            if (ctct.Hold_Out_Reason__c != null) {
               StringHelper.addToProcessNotes(ctct,'Clear Hold Out Reason '+ctct.Hold_Out_Reason__c);
               ctct.Hold_Out_Reason__c = null;
            }
         }
      } // for (Contact ctct : ctcts
   } // checkContactsBefore
   
   public static void checkAccountsBefore(Account[] accts, Map<Id,Account> oldMap) {
      for (Account acct : accts) {
         Account oldAcct = (oldMap != null ? oldMap.get(acct.Id) : null);
         checkAcctHoldOutFlds(acct,oldAcct);
      } // for (Account acct
   } // checkAccountsBefore
   
   public static void checkAcctHoldOutFlds(Account acct, Account oldAcct) {
      
      Date earliestDate = null;
      Set<String> holdOutCheckSet = new Set<String>();
      for (HoldOut_ExpirationDates__c hoe : HoldOut_ExpirationDates__c.getAll().values()) {
         //if (hoe.UseForOwnershipChange__c && String.isNotBlank(hoe.Account_Hold_Out__c)) {
         if (String.isNotBlank(hoe.Account_Hold_Out__c) && !holdOutCheckSet.contains(hoe.Account_Hold_Out__c)) {
            holdOutCheckSet.add(hoe.Account_Hold_Out__c);
            Boolean curHoldOut = (Boolean)acct.get(hoe.Account_Hold_Out__c);
            Boolean prevHoldOut = (oldAcct != null ? (Boolean)oldAcct.get(hoe.Account_Hold_Out__c) : false);
            // if the hold out field is unchecked
            if (prevHoldOut && !curHoldOut) {
               if (String.isNotBlank(hoe.Account_Hold_Out_Date__c) && acct.get(hoe.Account_Hold_Out_Date__c) != null) {
                  StringHelper.addToProcessNotes(acct,'Cleared '+hoe.Account_Hold_Out_Date__c);
                  acct.put(hoe.Account_Hold_Out_Date__c,null);
               }
               if (String.isNotBlank(hoe.HoldOutReasonFld__c) && acct.get(hoe.HoldOutReasonFld__c) != null) {
                  StringHelper.addToProcessNotes(acct,'Cleared '+hoe.HoldOutReasonFld__c);
                  acct.put(hoe.HoldOutReasonFld__c,null);
               }
            }
            
            // get the earliest date
            Date holdOutDate = (String.isNotBlank(hoe.Account_Hold_Out_Date__c) ? (Date)acct.get(hoe.Account_Hold_Out_Date__c) : null);
            if (holdOutDate != null && (earliestDate == null || earliestDate > holdOutDate)) {
               earliestDate = holdOutDate;
            }
         }
      } // for (HoldOut_ExpirationDates__c hoe
      
      System.debug('checkAcctHoldOutFlds acct='+acct.Name+' earliestDate='+earliestDate);
      if (earliestDate != acct.HoldOutCheckDate__c) {
         StringHelper.addToProcessNotes(acct,'Set HO CheckDate='+earliestDate);
         acct.HoldOutCheckDate__c = earliestDate;
      }
   } // checkAcctHoldOutFlds
    
   public static Decimal SOLD_PCT=Decimal.valueOf(Label.HoldOutExpiration_SoldPct);
    
   public static void checkOppsAfter(Opportunity[] recs, Map<Id,Opportunity> oldMap) {
      Set<Id> checkSoldHoldOutSet = new Set<Id>();
      Set<Id> checkNotSoldHoldOutSet = new Set<Id>();
      Set<Id> newOppsToCheckSet = new Set<Id>();
      Schema.RecordTypeInfo coreRt = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_CORE, 'Opportunity');
      Id coreRtId = (coreRt != null ? coreRt.getRecordTypeId() : null);

      for (Opportunity opp : recs) {
         Opportunity oldOpp = (oldMap != null ? oldMap.get(opp.Id) : null);
         if (oldOpp != null) {
            if (opp.Probability >= SOLD_PCT && oldOpp.Probability < SOLD_PCT) {
               System.debug('checkOppsAfter opp='+opp.Name+' crossed the sold Probability of '+SOLD_PCT);
               // only check when we cross the threshhold
               // if a hold out reason doesn't match it won't do anything.
               checkSoldHoldOutSet.add(opp.Id);
            } else if (opp.IsClosed && !opp.isWon && !oldOpp.isClosed) {
               checkNotSoldHoldOutSet.add(opp.Id);
            }
         } else if (oldOpp == null) {
            
         } // if (oldOpp != null
          
      } // for (Opportunity opp : recs
       
      System.debug('checkOppsAfter checkSoldHoldOutSet='+checkSoldHoldOutSet.size()+' checkNotSoldHoldOutSet='+checkNotSoldHoldOutSet.size());
      if (!checkSoldHoldOutSet.isEmpty() || !checkNotSoldHoldOutSet.isEmpty()) {
         reviseHoldOutExpiration(checkSoldHoldOutSet,checkNotSoldHoldOutSet);
      }
   } // checkOppsAfter

    /* opportunity Ids that have been processed */
    public static Set<Id> idsProcessedSet = new Set<Id>();
    
    public static Integer PROCESS_NOTES_LENGTH = Account.ProcessNotes__c.getDescribe().getLength();
    
    /* take incoming DateTime + number of Days and returning a new Date field
    */
    public static Date calcHODate(Date beginDate, String salesOrg) {         
        beginDate = (beginDate == null ? Date.today() : beginDate);
        HoldOut_ExpirationDates__c hoDates = HoldOut_ExpirationDates__c.getInstance(salesOrg);
        System.debug('calcHODate hoDates='+hoDates);
        Date futureDate = beginDate.addDays(hoDates != null && hoDates.InitialNumberOfDays__c != null ? (Integer)hoDates.InitialNumberOfDays__c : 90);     
        
        return futureDate;              
    } // calcHODate
    
     //APR0116141 - JC custom label to store oppty lead sources that are Referred by Channel
    public static set<string> referralLS = new set<string> (Label.Referred_by_Channel_Lead_Sources.split(','));    
    
   // bring in Sold Optys and look up if Account had Hold Out, may need to revise Expiration date
   public static void reviseHoldOutExpiration(Set<Id> soldCheckHoldOutSet, Set<Id> checkNotSoldHoldOutSet) {
      // read custom setting into a map
      List<HoldOut_Dictionary__c> hoDictionary = HoldOut_Dictionary__c.getall().values();
      HoldOut_Dictionary__c virtualSoldHO;
      Map<String, HoldOut_Dictionary__c> hoMap = new Map<String, HoldOut_Dictionary__c>();
      for (HoldOut_Dictionary__c ho:hoDictionary) {
         hoMap.put(ho.Name, ho);     
      }
        
      Set<Id> queryIds = new Set<Id>();
      queryIds.addAll(soldCheckHoldOutSet);
      queryIds.addAll(checkNotSoldHoldOutSet);
       
      Map<Id,Account> acctUpdateMap = new Map<Id,Account>();            
      List<Opportunity> soldOptyList = [select Id, Name, StageName, CloseDate, Type, RecordTypeId, RecordType.Name, OpportunityType__c
        			   ,OwnerId
        			   ,Owner.Title
                       ,Owner.Sales_Division__c
                       ,Account.Id
                       ,Account.isChild__c
                       ,Account.ProcessNotes__c
                       ,Account.First_Run_Date__c
                       ,Account.Hold_Out_Expiration__c
                       ,Account.Hold_Out__c
                       ,Account.Permanent_Hold_Out_Description__c
                       ,Account.HRS_Hold_Out_Expiration__c
                       ,Account.HRS_Hold_Out__c
                       ,Account.HRS_Permanent_Hold_Out_Description__c
                       ,Account.HNBF_Hold_Out_Expiration__c
                       ,Account.HNBF_Hold_Out__c
                       ,Account.BenAdmin_Hold_Out_Reason__c
                       ,Account.BenAdmin_Hold_Out_Expiration__c
                       ,Account.BenAdmin_Hold_Out__c
                       ,Account.HNBF_Permanent_Hold_Out_Description__c  
                       ,Account.P_C_Hold_Out__c
                       ,Account.P_C_Hold_Out_Expiration__c
                       ,Account.P_C_Permanent_Hold_Out_Description__c                 
                       ,Account.Premier_PBS_Hold_Out_Expiration__c
                       ,Account.Premier_PBS_Hold_Out__c 
                       ,Account.PEO_ASO_Permanent_Hold_Out_Description__c
                       ,Account.OasisPEOHoldOutExpiration__c
                       ,Account.OasisPEOHoldOut__c
                       ,Account.OasisPEOHoldOutReason__c
                       ,Account.NumberOfEmployees
                       ,Account.OwnerId
                       ,Leadsource                 
                       ,ReferralLookup__c
                       ,ReferralLookup__r.Referral_Partner__c
                       ,ReferralLookup__r.Referral_Partner__r.Name
                       ,ReferralLookup__r.Referral_Partner__r.Permanent_Hold_Out_Description__c
                       from Opportunity
                       where Id in :queryIds ];
      
       //Grab all Accounts for the Payroll Opportunities being set to Not Sold
       List<Id> notSoldPayrollOpptyAccountIds = new List<Id>();
       Map<Id,Opportunity> mostRecentAccountPayrollOppty = new Map<Id,Opportunity>();
       for(Opportunity oppty : soldOptyList)
       {
           if(checkNotSoldHoldOutSet.contains(oppty.Id) && oppty.OpportunityType__c == 'Payroll')
           {
               notSoldPayrollOpptyAccountIds.add(oppty.AccountId);
           }
       }
       
	   //Get the most recently created Payroll Opportunity for each Account
       for(Account acct: [SELECT Id ,(SELECT Id, Name, OpportunityType__c FROM Opportunities WHERE OpportunityType__c = 'Payroll' ORDER BY CreatedDate DESC LIMIT 1) FROM Account WHERE Id IN :notSoldPayrollOpptyAccountIds])
       {
           if(!acct.opportunities.isEmpty())
           {
				mostRecentAccountPayrollOppty.put(acct.id, acct.opportunities[0]);
			}
       }
       
      for (Opportunity opty: soldOptyList) {
         // technically could just check the Probabilty...
         Boolean checkSold = soldCheckHoldOutSet.contains(opty.Id);
         Boolean checkNotSold = checkNotSoldHoldOutSet.contains(opty.Id);
         System.debug('reviseHoldOutExpiration opty='+opty.Name+' checkSold='+checkSold+' checkNotSold='+checkNotSold);
         String notes = 'HoldOutExpMethods revising HoldOut ';
         Boolean acctUpdated = false;
         boolean hasRefLS = (opty.LeadSource!=null && referralLS.contains(opty.LeadSource));         

    	 String salesOrg = RecordTypeHelper.getSalesOrgForRecordTypeName(opty.RecordType.Name);
         // Get the hold out settings for the sales org - should always exist
         HoldOut_ExpirationDates__c hoDates = HoldOut_ExpirationDates__c.getInstance(salesOrg); 
         System.debug('HoldOutExpirationMethods.reviseSoldExpiration hoDates='+hoDates);
         // if hoDates is null, then continue the loop
         if (hoDates == null) {
            System.debug('reviseHoldOutExpiration HoldOut_ExpirationDates__c not found for '+salesOrg);
            continue;
         } 
         // does the account have a holdout on the field?
         Boolean hasHoldOut = (Boolean)opty.Account.get(hoDates.Account_Hold_Out__c);
         
          //If this is an SMB Channel Oppty, is the most recently created Payroll oppty for the account, and has been set to Not Sold, extend the hold out for 12 months.
         if(checkNotSold && hasRefLS && (opty.Owner.Sales_Division__c.contains('SMB') && opty.Owner.Sales_Division__c.contains('Channel')) && opty.OpportunityType__c == 'Payroll' && !opty.Account.isChild__c && mostRecentAccountPayrollOppty.get(opty.Account.Id) != null && mostRecentAccountPayrollOppty.get(opty.Account.Id).Id == opty.Id)
         {
             HoldOut_Dictionary__c hod = hoMap.get('Not Sold Opportunity');
             if(hod != null && opty.Account.NumberOfEmployees >= hod.Min_Employees__c && opty.Account.NumberOfEmployees <= hod.Max_Employees__c)
             {
                 opty.Account.put(hoDates.Account_Hold_Out__c,true);
                 
                 Integer initialDays = Integer.valueOf(hod.InitialNbrDays__c);
                 if (((Date)opty.Account.get(hoDates.Account_Hold_Out_Date__c) == null) || ((Date)opty.Account.get(hoDates.Account_Hold_Out_Date__c) != null && initialDays != null && (Date)opty.Account.get(hoDates.Account_Hold_Out_Date__c) <=System.Date.today().addDays(initialDays))) 
                 {
                  	 Date newDate = System.Date.today() + initialDays;
                  	 opty.Account.put(hoDates.Account_Hold_Out_Date__c, newDate);                                  
               	 }
                 
            	 opty.Account.put(hoDates.HoldOutReasonFld__c,hod.Name);
                 opty.Account.OwnerId = opty.OwnerId; 
            	 acctUpdated=true;
                 hasHoldOut = true;
                 System.debug('Hold Out was extended for Not Sold Opportunity.');
             }
         }
          
         // if there isn't a hold out, we don't need to do anything in a not sold situation (at this time anyway!)
         if (!hasHoldOut && checkNotSold) {
            System.debug('reviseHoldOutExpiration not sold opp without a holdout');
            continue;
         }
         String holdOutReason = (String.isNotBlank(hoDates.HoldOutReasonFld__c) ? (String)opty.Account.get(hoDates.HoldOutReasonFld__c) : null);
         if (!hasHoldOut && opty.ReferralLookup__c != null && opty.ReferralLookup__r.Referral_Partner__c != null && String.isNotBlank(opty.ReferralLookup__r.Referral_Partner__r.Permanent_Hold_Out_Description__c)) {
            holdOutReason = opty.ReferralLookup__r.Referral_Partner__r.Permanent_Hold_Out_Description__c;
         }
         HoldOut_Dictionary__c hod = (holdOutReason != null ? hoMap.get(holdOutReason) : null);
         System.debug('reviseHoldOutExpiration holdOutReason='+holdOutReason+' hod='+hod);
         // if there isn't a hold out dictionary entry, we don't need to proceed
         if (hod == null) {
            System.debug('reviseHoldOutExpiration HoldOut_Dictionary__c not found for '+holdOutReason);
            continue;
         }
          
         // process for sold opps
         if (checkSold) {
            // if we need to recalculate the hold out date, get the date information.
            Date beginDate = null;
            // the default number of days for the sales org.
            Integer nbrDaysToExtend = (Integer)hoDates.OptySoldNumberOfDays__c;
            System.debug('reviseHoldOutExpiration 1 nbrDaysToExtend='+nbrDaysToExtend);
            if (hod.Sold_clears_Expiration_Date__c) {
               // we will clear out the expiration date and not extend it.
               nbrDaysToExtend = null;
            } else if (hod.SoldExtendsHoldout__c != null) {
               nbrDaysToExtend = (Integer)hod.SoldExtendsHoldout__c;
            }
            System.debug('reviseHoldOutExpiration 2 nbrDaysToExtend='+nbrDaysToExtend);
            if (nbrDaysToExtend != null && nbrDaysToExtend > 0) {
               if (hoDates.Account_Date_Field__c != null) {
                  beginDate = (Date)opty.Account.get(hoDates.Account_Date_Field__c);
               }
               if (beginDate == null && hoDates.Opportunity_Date__c != null) {
                  beginDate = (Date)opty.get(hoDates.Opportunity_Date__c);
               }
            }
            System.debug('reviseHoldOutExpiration beginDate='+beginDate);
               
            Date newDate = (beginDate != null ? beginDate.addDays(nbrDaysToExtend) : null);
            notes += '; set '+hoDates.Account_Hold_Out_Date__c+' to '+newDate;                
            opty.Account.put(hoDates.Account_Hold_Out_Date__c, newDate);
            if (!hod.Permanent__c) {
               opty.Account.put(hoDates.HoldOutReasonFld__c, hod.Next_HO_reason__c);
               notes += '; set holdout reason to '+hod.Next_HO_reason__c;
            }
            Boolean hasReason = (opty.Account.get(hoDates.HoldOutReasonFld__c) != null);
            Boolean hasDate = (opty.Account.get(hoDates.Account_Hold_Out_Date__c) != null);
            hasHoldOut = (Boolean)opty.Account.get(hoDates.Account_Hold_Out__c);
               
            // if there is a reason or a date, the holdout should be set
            if ((hasReason || hasDate) && !hasHoldOut) {
               notes += '; set '+hoDates.Account_Hold_Out__c+' to true';
               opty.Account.put(hoDates.Account_Hold_Out__c, true);
            } else if (!hasReason && !hasDate && hasHoldOut) {
               notes += '; set '+hoDates.Account_Hold_Out__c+' to false';
               opty.Account.put(hoDates.Account_Hold_Out__c, false);
            }
            acctUpdated=true;
         } else if (checkNotSold && hod.Not_Sold_clears_Hold_Out__c) {
            notes += '; removed the '+hod.Name+' holdout';
            opty.Account.put(hoDates.Account_Hold_Out__c,false);
            opty.Account.put(hoDates.Account_Hold_Out_Date__c,null);
            opty.Account.put(hoDates.HoldOutReasonFld__c,null);
            acctUpdated=true;
         }

          /*
            if (hoDates != null && (Boolean)opty.Account.get(hoDates.Account_Hold_Out__c) == true) {
	           // reset date and set permanent reason based on HoldOut dictionary
	           //String holdOutReason = (String)opty.Account.get(hoDates.HoldOutReasonFld__c);
               //HoldOut_Dictionary__c hod = (holdOutReason != null ? hoMap.get(holdOutReason) : null);
               if (hod != null) {
                  // if the sold opp clears the hold out date or there is a next reason
		          if (hod.Sold_clears_Expiration_Date__c || String.isNotBlank(hod.Next_HO_reason__c)) {
                     // clear the date
                     opty.Account.put(hoDates.Account_Hold_Out_Date__c, null);
                     notes += '; cleared holdout date';
                     // if it's not permanent, set the next hold out reason
                     if (!hod.Permanent__c) {
                        opty.Account.put(hoDates.HoldOutReasonFld__c, hod.Next_HO_reason__c);
                        notes += '; set holdout reason to '+hod.Next_HO_reason__c;
                     }
                     acctUpdated = true;
                     System.debug('HoldOutExpirationMethods.reviseSoldExpiration opty.Account.permHOdescrip='+opty.Account.Permanent_Hold_Out_Description__c);
                  } else {                     	
                     // extend hold out date based on HoldOut Expiration Dates
                     Date beginDate = null;
                     if (hoDates.Account_Date_Field__c != null) {
		    	        beginDate = (Date)opty.Account.get(hoDates.Account_Date_Field__c);
                     } else if (hoDates.Opportunity_Date__c != null) {
		                beginDate = (Date)opty.get(hoDates.Opportunity_Date__c);
                     }
                     if (beginDate != null) {
		                Date newDate = beginDate.addDays((Integer)hoDates.OptySoldNumberOfDays__c);
                        notes += '; added '+hoDates.OptySoldNumberOfDays__c+' to HoldOut Date '+newDate;
				        opty.Account.put(hoDates.Account_Hold_Out_Date__c, newDate);
                        acctUpdated = true;
                     } // if (beginDate != null
	        	  } // else
               } // if (hod != null)
            } else if (opty.ReferralLookup__c != null && String.isNotBlank(opty.ReferralLookup__r.Referral_Partner__r.Permanent_Hold_Out_Description__c)) {
               // need to update accounts with no hold out but Virtual Micro opty was marked sold
               //HoldOut_Dictionary__c hod = hoMap.get(opty.ReferralLookup__r.Referral_Partner__r.Permanent_Hold_Out_Description__c);
               if (hod != null && (hod.Sold_clears_Expiration_Date__c || String.isNotBlank(hod.Next_HO_reason__c))) {
                  opty.Account.Hold_Out__c = true;
        	      opty.Account.Hold_Out_Expiration__c = null;
                  opty.Account.Permanent_Hold_Out_Description__c = hod.Next_HO_reason__c;
                  acctUpdated = true;
                  System.debug('HoldOutExpirationMethods.reviseSoldExpiration opty.Account.permHOdescrip='+opty.Account.Permanent_Hold_Out_Description__c);
               }
        	} // else
            */
           // idsProcessedSet.add(opty.Id);
         if (acctUpdated) {
            StringHelper.addToProcessNotes(opty.Account,notes);
            acctUpdateMap.put(opty.Account.Id,opty.Account);
         }
         //} // if (!idsProcessedSet.contains(opty.Id))
      } // for
		
      if (!acctUpdateMap.isEmpty()) {
         DmlHelper.performDML2(acctUpdateMap.values(), DmlHelper.DML_UPDATE, 'HoldOutExpirationMethods', 'reviseHoldOutExpiration', 'Update Account hold outs ', true);
      }
        
   } // reviseHoldOutExpiration
    
    /* bring in Core Initial Presentation Tasks and look up if Account had Hold Out, may need to revise Expiration date
    */
    public static void reviseTaskExpiration(List<Id> idEventList) {
        List <Account> updateAcctList = new List<Account>();
        List <Account> acctList = new List<Account>();
        
        String prefix = ((String)idEventList.get(0)).left(3);
       
        if (prefix == ObjectHelper.PREFIX_CONTACT)
        {	List<Contact> ctctList = [Select Id, Name
                       ,Account.Id
                       ,Account.First_Run_Date__c
                       ,Account.Hold_Out_Expiration__c
                       ,Account.Hold_Out__c                    
                       ,Account.HRS_Hold_Out_Expiration__c
                       ,Account.HRS_Hold_Out__c
                       ,Account.HNBF_Hold_Out_Expiration__c
                       ,Account.HNBF_Hold_Out__c
                       ,Account.BenAdmin_Hold_Out_Expiration__c
                       ,Account.BenAdmin_Hold_Out__c                
                       ,Account.Premier_PBS_Hold_Out_Expiration__c
                       ,Account.Premier_PBS_Hold_Out__c from Contact 
                       where Id in :idEventList 
                       and (Account.Hold_Out__c = True 
                            Or Account.HRS_Hold_Out__c = True 
                            Or Account.HNBF_Hold_Out__c = True 
                            Or Account.Premier_PBS_Hold_Out__c = True) ];         	
         	for (Contact ct: ctctList)
            {	acctList.add(ct.Account);	}       
        } // prefix=Contact
        else if (prefix == ObjectHelper.PREFIX_OPPTY)
        {	List<Opportunity> opptyList = [Select Id, Name
                       ,Account.Id
                       ,Account.First_Run_Date__c
                       ,Account.Hold_Out_Expiration__c
                       ,Account.Hold_Out__c                    
                       ,Account.HRS_Hold_Out_Expiration__c
                       ,Account.HRS_Hold_Out__c
                       ,Account.HNBF_Hold_Out_Expiration__c
                       ,Account.HNBF_Hold_Out__c
                       ,Account.BenAdmin_Hold_Out_Expiration__c
                       ,Account.BenAdmin_Hold_Out__c                    
                       ,Account.Premier_PBS_Hold_Out_Expiration__c
                       ,Account.Premier_PBS_Hold_Out__c from Opportunity 
                       where Id in :idEventList 
                       and (Account.Hold_Out__c = True 
                            Or Account.HRS_Hold_Out__c = True 
                            Or Account.HNBF_Hold_Out__c = True 
                            Or Account.Premier_PBS_Hold_Out__c = True) ];         	
         	for (Opportunity oppty: opptyList)
            {	acctList.add(oppty.Account);	}       
        } // prefix=Opportunity
        else
        {   if (prefix == ObjectHelper.PREFIX_ACCOUNT)
        	{	acctList = [Select Id, Name
                       ,First_Run_Date__c
                       ,Hold_Out_Expiration__c
                       ,Hold_Out__c                    
                       ,HRS_Hold_Out_Expiration__c
                       ,HRS_Hold_Out__c
                       ,HNBF_Hold_Out_Expiration__c
                       ,HNBF_Hold_Out__c
                       ,Account.BenAdmin_Hold_Out_Expiration__c
                       ,Account.BenAdmin_Hold_Out__c
                       ,Premier_PBS_Hold_Out_Expiration__c
                       ,Premier_PBS_Hold_Out__c from Account 
                       where Id in :idEventList 
                       and (Hold_Out__c = True Or HRS_Hold_Out__c = True Or HNBF_Hold_Out__c = True Or Premier_PBS_Hold_Out__c = True) ];
            }
        } // else

        // should this be able to handle different sales orgs?
        HoldOut_ExpirationDates__c hoDates = HoldOut_ExpirationDates__c.getInstance('PAY');
        for (Account acct : acctList) {
           Date curHoldoutDate = (hoDates != null && String.isNotBlank(hoDates.Account_Hold_Out_Date__c) ? (Date)acct.get(hoDates.Account_Hold_Out_Date__c) : null);
           // see if there's currently a hold out date and it's in the future.
           if (curHoldoutDate != null && curHoldoutDate > System.Today()) {
               Integer initialDays = Integer.valueOf(hoDates.InitialNumberofDays__c);
               // if the current holdout is farther in the future than the InitialNumberofDays__c, then it was probably set somewhere else and we won't extend it here.
               if (initialDays != null && curHoldoutDate <= Date.today().addDays(initialDays)) {
                  // subtract initial number of days given to hold out to get approval date, then add days due to scheduling event                
                  date newDate = curHoldoutDate.addDays(-initialDays);
                  // add the new days 
                  newDate = newDate.addDays((Integer)hoDates.TaskNumberOfDays__c);
                  acct.put(hoDates.Account_Hold_Out_Date__c, newDate);                                  
                  updateAcctList.add(acct);
               }
            } // if hold out  = true
            if(acct.HRS_Hold_Out__c) {
                HoldOut_ExpirationDates__c hoDatesHRS = HoldOut_ExpirationDates__c.getInstance('HRS');
                Date curHoldoutDateHRS = (hoDatesHRS != null && String.isNotBlank(hoDatesHRS.Account_Hold_Out_Date__c) ? (Date)acct.get(hoDatesHRS.Account_Hold_Out_Date__c) : null);
                if (curHoldoutDateHRS != null && curHoldoutDateHRS >= System.Today()) {
                    Integer taskDays = Integer.valueOf(hoDatesHRS.TaskNumberOfDays__c);
                    if(taskDays != null) {
                        date newDate = curHoldoutDateHRS.addDays(taskDays);
                        acct.put(hoDatesHRS.Account_Hold_Out_Date__c, newDate);                                  
                        updateAcctList.add(acct);
                    }
                }
            }
        } // for

        if (!updateAcctlist.isEmpty()) {
           ZipCheckOwner.SKIP_TRIGGERS=true;
           DmlHelper.performDML2(updateAcctList, DmlHelper.DML_UPDATE, 'HoldOutExpirationMethods', 'reviseTaskExpiration', 'Update Account holdout expirations', true);
           ZipCheckOwner.SKIP_TRIGGERS=false;
        }
        
    } // reviseTaskExpiration
    
     /* bring in Not Sold Optys and look up if Account had Hold Out, may need to revise Expiration date
        BUT only if opty owned by Virtual Sales Micro rep
    
    public static void reviseNotSoldExpiration2(Set<Id> notsoldCheckHoldOutSet) {
        List<HoldOut_Dictionary__c> hoDictionary = HoldOut_Dictionary__c.getall().values();
        Map<String, HoldOut_Dictionary__c> hoMap = new Map<String, HoldOut_Dictionary__c>();
        for (HoldOut_Dictionary__c ho:hoDictionary)
        {    hoMap.put(ho.Name, ho);  }
        List <Account> updateNotSoldAcctList = new List<Account>();        
        
        String dateStamp;
        String knotes;
        String notes;
        
        List<Opportunity> notsoldOptyList = [select Id, StageName, CloseDate, RecordTypeId, RecordType.Name, ReferralLookup__c
        			   ,Owner.userRoleId
        			   ,Owner.Title
                       ,Account.Id
                       ,Account.First_Run_Date__c
                       ,Account.Hold_Out_Expiration__c
                       ,Account.Hold_Out__c     
                       ,Account.Permanent_Hold_Out_Description__c
                       ,Account.ProcessNotes__c               
                       from Opportunity 
                       where Id in :notsoldCheckHoldOutSet 
                       and Account.Hold_Out__c = True
					   and Owner.Title like '%SMB Inbound%' 
                       and ReferralLookup__c != null ];                                             
                       //and Owner.Title like 'Virtual%'
                       //and Owner.title like '%Micro%' ];

	    HoldOut_ExpirationDates__c hoDates = HoldOut_ExpirationDates__c.getInstance('PAY');
    
        for (Opportunity opty: notsoldOptyList)
        {	if (!idsProcessedSet.contains(opty.Id))  
          	{  if (opty.Account.get(hoDates.Account_Hold_Out__c) == true)
          	   {	// clear HO flag and fields based on HoldOut dictionary
	                if (hoMap.get(opty.Account.Permanent_Hold_Out_Description__c) != null)
	                {  if (hoMap.get(opty.Account.Permanent_Hold_Out_Description__c).Not_Sold_clears_Hold_Out__c)
    		           {	dateStamp = Datetime.now().format('M/d/yyyy H:mm:ss');
                			knotes = opty.Account.ProcessNotes__c;
                			notes = (dateStamp+' HoldOutExpMethods revising HO when Not Sold' + (String.isNotBlank(knotes) ? '\n'+knotes : '')).left(PROCESS_NOTES_LENGTH);     	
    		           		opty.Account.put(hoDates.Account_Hold_Out_Date__c, null);
    	        	        opty.Account.put('Permanent_Hold_Out_Description__c', null);
        	        	    opty.Account.put(hoDates.Account_Hold_Out__c, false);
        	        	    opty.Account.put('ProcessNotes__c', notes);
	        	            updateNotSoldAcctList.add(opty.Account);
              		   } // if (...Not_Sold_clears_Hold_Out__c)
                	} // if (hoMap.get(opty.Account.Permanent_Hold_Out_Description__c) != null)
            	} // if hold out  = true
            	idsProcessedSet.add(opty.Id);
          	} // if (!idsProcessedSet.contains(opty.Id))  
        } // for
        
		System.debug('HoldOutExpirationMethods.reviseNotSoldExpiration updateNotSoldAcctList='+updateNotSoldAcctlist.size());
        if (!updateNotSoldAcctlist.isEmpty())
        {   //update updateNotSoldAcctList;  
        	DmlHelper.performDML2(updateNotSoldAcctList, DmlHelper.DML_UPDATE, 'HoldOutExpirationMethods', 'reviseNotSoldExpiration', 'Update Account hold outs', true);
        }
        
    } // reviseNotSoldExpiration2
    */

    /* bring in Not Sold Optys and clear Hold Outs if owned by Micro NSS Virtual rep
    */
    /* Not called from anywhere - 7/17/2019
    public static void reviseNotSoldExpiration(Set<Id> notsoldCheckHoldOutSet) {
    	List<HoldOut_Dictionary__c> hoDictionary = HoldOut_Dictionary__c.getall().values();
        Map<String, HoldOut_Dictionary__c> hoMap = new Map<String, HoldOut_Dictionary__c>();       
        for (HoldOut_Dictionary__c ho:hoDictionary)
        {    hoMap.put(ho.Name, ho);     }        
        List <Account> updateNotSoldAcctList = new List<Account>();
        String dateStamp;
        String knotes;
        String notes;
        
        Referral__c[] refList = [Select Id, Name, Selling_Opportunity__c, Selling_Opportunity__r.OwnerId,
                     Account__c, Account__r.OwnerId, 
                     Account__r.Hold_Out__c, Account__r.Permanent_Hold_Out_Description__c, Account__r.Hold_Out_Expiration__c,
                     Account__r.ProcessNotes__c,
                     Referral_Partner__c, Referral_Partner__r.Name, Referral_Partner__r.Permanent_Hold_Out_Description__c 
                     from Referral__c 
                     where Selling_Opportunity__c in :notsoldCheckHoldOutSet];
                     
        for (Referral__c ref : refList)
        {	// look up reason in custom setting to see if can be overwritten
            if (ref.Account__r.Hold_Out__c && String.isNotBlank(ref.Account__r.Permanent_Hold_Out_Description__c)
              		&& hoMap.containsKey(ref.Account__r.Permanent_Hold_Out_Description__c) && hoMap.get(ref.Account__r.Permanent_Hold_Out_Description__c).Permanent__c) 
            {  continue;  }	
            if (String.isNotBlank(ref.Referral_Partner__r.Permanent_Hold_Out_Description__c)
                    && hoMap.containsKey(ref.Referral_Partner__r.Permanent_Hold_Out_Description__c)
                    && hoMap.get(ref.Referral_Partner__r.Permanent_Hold_Out_Description__c).Not_Sold_clears_Hold_Out__c)
    		{	dateStamp = Datetime.now().format('M/d/yyyy H:mm:ss');
             	knotes = ref.Account__r.ProcessNotes__c;
             	notes = (dateStamp+' HoldOutExpMethods clearing HO when Not Sold' + (String.isNotBlank(knotes) ? '\n'+knotes : '')).left(PROCESS_NOTES_LENGTH);               
                Account updateAcct = new Account(Id=ref.Account__c, Hold_Out__c=false, Permanent_Hold_Out_Description__c=null,
                                                 Hold_Out_Expiration__c=null, ProcessNotes__c = notes);
    			updateNotSoldAcctList.add(updateAcct);
    		}                      	
        } // for
        
        System.debug('HoldOutExpirationMethods.reviseNotSoldExpiration updateNotSoldAcctList='+updateNotSoldAcctlist.size());
        if (!updateNotSoldAcctlist.isEmpty())
        {   DmlHelper.performDML2(updateNotSoldAcctList, DmlHelper.DML_UPDATE, 'HoldOutExpirationMethods', 'reviseNotSoldExpiration', 'Update Account hold outs', true);
        }
    	
    } // reviseNotSoldExpiration
    */
    
}