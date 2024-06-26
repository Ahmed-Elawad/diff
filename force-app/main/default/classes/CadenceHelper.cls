/* Helper methods for Cadence
   Some code is called from SLAHelperBatch

   TestMethods for coverage: CadenceHelperTest, SLAHelperBatchTest

 * History
 * -------
  09/05/2019 Dan Carmen           Created
  10/10/2019 Jermaine Stukes      Update
  02/28/2020 Dan Carmen           Add additional criteria to match opp to touchpoint
  04/08/2020 Dan Carmen           Fix issue when multiple opps are saved at the same time (that all match to the same touchpoint)
  04/14/2020 Dan Carmen           Ability to link opps to closed touchpoints.
  09/03/2021 Dan Carmen           Fix for setting the latest touchpoint
  10/21/2021 Dan Carmen           Fix cache setting
  11/17/2021 Dan Carmen           Add debugging
  12/29/2021 Dan Carmen           Add CadenceTypeGroup__c to check for opportunity match
  05/06/2022 Susmitha Somavarapu  Closes CAR record when OpptyType value on Opp obj equals to OpptyType value on Cadence obj
  06/21/2022 Dan Carmen           Clone steps when Cadence cloned
  08/17/2022 Dan Carmen           Change for setting the Close Reason on referring opps
  10/06/2022 Dan Carmen           Commented out SKIP_TRIGGERS in handleTouchpoints
  12/10/2022 Dan Carmen           Added ability to match an opp to a cadence based ONLY on opportunity type
  01/24/2023 Dan Carmen           Update to checkTouchpoint to save the latest touchpoint 
  01/17/2024 Reetesh Pandey		  Update for Secondary User Chatter Notification
  03/15/2024 Eric Porter          Update for Secondary User chatter Notification(Link to Account vs CAR record)
  03/21/2024 Shilpa G			  INC3642808/APR0167787: Updated method checkTouchpoint to comment Effective Date populating logic
*/
public without sharing class CadenceHelper implements TriggerInterfaceC {
   public static final String CLASSNAME='CadenceHelper';
   public static Boolean SKIP_TRIGGERS=false;

   public void handleTrigger(SObject[] p_recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter, Boolean isDelete) {
      System.debug('CadenceHelper.handleTrigger p_recs='+(p_recs != null ? p_recs.size() : -1)+' isBefore='+isBefore+' isAfter='+isAfter+' isDelete='+isDelete+' Trigger.old='+(Trigger.old != null ? Trigger.old.size() : -1));
      SObject[] recs = TriggerMethods.checkRecs(CLASSNAME, p_recs, oldMap, isBefore, isAfter, isDelete, null, null);
      if (recs == null || recs.isEmpty()) {
         System.debug('handleTrigger trigger ran');
         return;
      }
      //if (TriggerMethods.didTriggerRun(CLASSNAME,recs,oldMap,isBefore,isAfter,isDelete)) {
      //    System.debug('handleTrigger trigger ran');
      //   return;
      //}
      SObjectType objType = TriggerMethods.objType;
      if (isBefore) {
         if (isDelete) {
            if (objType == Cadence_Step__c.sObjectType) {
               handleCadenceStepBeforeDelete((Cadence_Step__c[])recs,(Map<Id,Cadence_Step__c>)oldMap);
            }
         } else {
            if (objType == Account.sObjectType && Trigger.isUpdate) {
               handleAcctsBefore((Account[])recs,(Map<Id,Account>)oldMap);
            } else if (objType == Lead.sObjectType && Trigger.isUpdate) {
               handleLeadsBefore((Lead[])recs,(Map<Id,Lead>)oldMap);
            } else if (objType == Cadence_Step__c.sObjectType) {
               handleCadenceStepBefore((Cadence_Step__c[])recs,(Map<Id,Cadence_Step__c>)oldMap);
            } else if (objType == Opportunity.sObjectType) {
               handleOppsBefore((Opportunity[])recs,(Map<Id,Opportunity>)oldMap);
            } else if (objType == Referral_Account__c.sObjectType) {
               handleRefAcctsBefore((Referral_Account__c[])recs,(Map<Id,Referral_Account__c>)oldMap);
            } else if (objType == Cadence__c.sObjectType) {
               handleCadenceBefore((Cadence__c[])recs, (Map<Id,Cadence__c>)oldMap);
            }
         }
      } else if (isAfter) {
         if (objType == Opportunity.sObjectType) {
            handleOppsAfter((Opportunity[])recs,(Map<Id,Opportunity>)oldMap);
         } else if (objType == Cadence_Close_Reasons__c.sObjectType) {
            // clear the cache if the object updates
            WorkQueueController.clearCache();
         } else if (objType == Cadence__c.sObjectType) {
            checkCadenceAfter((Cadence__c[])recs, (Map<Id,Cadence__c>)oldMap);
            // clear the cache on any change to the Cadence object
            clearCadenceMapCache();
         } else if (objType == Cadence_Step__c.sObjectType) {
            clearCadenceMapCache();
         } else if (objType == Referral_Account__c.sObjectType) {
            handleRefAcctsAfter((Referral_Account__c[])recs,(Map<Id,Referral_Account__c>)oldMap);
         }
      } // if (isAfter

   } // handleTrigger
    
   public static void handleCadenceBefore(Cadence__c[] recs, Map<Id,Cadence__c> oldMap) {
      String[] queueNames = new String[]{};
      Cadence__c[] checkQueues = new Cadence__c[]{};

      for (Cadence__c cad : recs) {
         Cadence__c oldCad = (oldMap != null ? oldMap.get(cad.Id) : null);
         if (String.isNotBlank(cad.SendToPartnerQueue__c) && (oldCad == null || (cad.SendToPartnerQueue__c != oldCad.SendToPartnerQueue__c))) {
            cad.SendToPartnerQueueId__c = null;
            queueNames.add(cad.SendToPartnerQueue__c);
            checkQueues.add(cad);
         } else if (String.isBlank(cad.SendToPartnerQueue__c) && String.isNotBlank(cad.SendToPartnerQueueId__c)) {
            cad.SendToPartnerQueueId__c = null;
         }
      }
             
      if (!checkQueues.isEmpty()) {
         checkQueueNames(queueNames, checkQueues);
      }
   } // handleCadenceBefore
             
   public static void checkQueueNames(String[] queueNames, Cadence__c[] checkQueues) {
      // make sure the queues exist.
      Group[] queryQueues = [Select Id, Type, OwnerId, Name, Email from Group 
                                  where Type = 'Queue'
                                  and Name in :queueNames];
      //Map<Id,Group> grpByIdMap = new Map<Id,Group>(queryQueues);
      Id[] queueIds = new Id[]{};
      Map<String,Group> grpByNameMap = new Map<String,Group>();
      for (Group grp : queryQueues) {
         queueIds.add(grp.Id);
         grpByNameMap.put(grp.Name, grp);
      }
      Assignment_Group_Queues__c[] agQueues = [Select Id, Name, QueueId__c, Assignment_Group_Name__c from Assignment_Group_Queues__c where QueueId__c in :queueIds];
      Map<String,Assignment_Group_Queues__c> agMap = new Map<String,Assignment_Group_Queues__c>();
      for (Assignment_Group_Queues__c agQueue : agQueues) {
          agMap.put(agQueue.QueueId__c,agQueue);
      }
      for (Cadence__c cad : checkQueues) {
         // should be both a queue and an Assignment Group record for a queue.
         Group grp = grpByNameMap.get(cad.SendToPartnerQueue__c);
         if (grp == null) {
            cad.SendToPartnerQueue__c.addError('Could not find a queue with this name!');
         } else {
            Assignment_Group_Queues__c agQueue = agMap.get(grp.Id);
            if (agQueue == null) {
               cad.SendToPartnerQueue__c.addError('The queue was found, but the Assignment Group setup was not found.');
            } else {
               cad.SendToPartnerQueueId__c = grp.Id;
            }
         }
      } // for (Cadence__c cad : checkQueues
   } // checkQueueNames
    
   public static void handleCadenceStepBeforeDelete(Cadence_Step__c[] steps, Map<Id,Cadence_Step__c>oldMap) {
      System.debug('handleCadenceStepBeforeDelete steps='+(steps != null ? steps.size() : -1)+' oldMap='+(oldMap != null ? oldMap.size() : -1));
      // before a Cadence Step can be deleted, make sure it's not attached to any touchpoints.
      // put into a map to get the ids
      //Map<Id,Cadence_Step__c> stepMap = new Map<Id,Cadence_Step__c>(steps);
      AggregateResult[] results = [Select Cadence_Touchpoint_Step__c recId, count(Id) nbrRecs 
                                     From Cadence_Touchpoint__c
                                    Where Cadence_Touchpoint_Step__c in :oldMap.keySet()
                                     group by Cadence_Touchpoint_Step__c];
      System.debug('handleCadenceStepBeforeDelete steps='+oldMap.size()+' results='+results.size());
      for (AggregateResult result : results) {
          Id recId = (Id)result.get('recId');
          if (recId != null) {
              Cadence_Step__c step = oldMap.get(recId);
              if (step != null) {
                 step.addError('This record cannot be deleted since it is linked to Touchpoints!');
              }
          }
      } // for (AggregateResult
   } // handleCadenceStepBeforeDelete
   
   public static void handleCadenceStepBefore(Cadence_Step__c[] steps, Map<Id,Cadence_Step__c>oldMap) {
      Cadence_Step__c[] stepsToUpdate = new Cadence_Step__c[]{};
      List<String> emailTemplateList = new List<String>();
      // we need to make sure each name has a unique name
      Map<Id,Cadence_Step__c[]> uniqueNameMap = new Map<Id,Cadence_Step__c[]>();
      Id[] templateIds = new Id[]{};
      Cadence_Step__c[] stepsForTemplates = new Cadence_Step__c[]{};
      
      for (Cadence_Step__c step : steps) {
         Cadence_Step__c oldRec = (oldMap != null ? oldMap.get(step.Id) : null);
         // add a value for the step name so it doesn't default to the Id if loaded through the API.
         if (oldRec == null && String.isBlank(step.Name) && String.isNotBlank(step.Touchpoint_Type__c)) {
            step.Name=step.Touchpoint_Type__c+(step.Step_Number__c != null ? '-'+String.valueOf(step.Step_Number__c) : '');
         }
         if (String.isNotBlank(step.EmailTemplateIds__c) && (oldRec == null || step.EmailTemplateIds__c != oldRec.EmailTemplateIds__c)) {
            // get a list of ids
            String[] idList = step.EmailTemplateIds__c.split(',');
            Boolean idsOkay = true;
            String[] newIds = new String[]{};
            for (String thisId : idList) {
                try {
                   Id templateId = (Id)thisId;
                   newIds.add(templateId);
                } catch (Exception e) {
                   idsOkay = false;
                   step.EmailTemplateIds__c.addError('The value '+thisId+' is not a valid Id!');
                }
            } // for (String thisId : idList
            if (idsOkay) {
               step.EmailTemplateIds__c=String.join(newIds,',');
               templateIds.addAll(newIds);
               stepsForTemplates.add(step);
            }
         } // if (String.isNotBlank(step.EmailTemplateIds__c
         if (oldRec == null || (step.Name != oldRec.Name)) {
            // we need to make sure the names are unique within a cadence
            addToNameMap(step,uniqueNameMap);
         }
      } // for (Cadence_Step__c step
      System.debug('handleCadenceStepBefore uniqueNameMap='+uniqueNameMap.size()+' stepsForTemplates='+stepsForTemplates.size());
      if (!uniqueNameMap.isEmpty()) {
         checkExistingSteps(uniqueNameMap);
      }
      if (!stepsForTemplates.isEmpty() && !templateIds.isEmpty()) {
         checkForTemplates(stepsForTemplates,templateIds);
      }
   } // handleCadenceStepBefore
    
   public static void checkForTemplates(Cadence_Step__c[] stepsForTemplates, Id[] p_templateIds) {
       Map<Id,EmailTemplate> templateMap = new Map<Id,EmailTemplate>([Select Id, Name from EmailTemplate where Id in :p_templateIds]);
       System.debug('checkForTemplates p_templateIds='+p_templateIds.size()+' templateMap='+templateMap.size());
       for (Cadence_Step__c step : stepsForTemplates) {
          String[] templateIds = step.EmailTemplateIds__c.split(',');
          String[] templateNames = new String[]{};
          Boolean idsOkay = true;
          for (String templateId : templateIds) {
             EmailTemplate template = templateMap.get((Id)templateId);
             System.debug('checkForTemplates templateId='+templateId+' template found='+(template != null));
              if (template != null) {
                 templateNames.add(template.Name);
              } else {
                 System.debug('checkForTemplates added error!');
                 step.EmailTemplateIds__c.addError('Could not find template for '+templateId);
                 idsOkay = false;
              }
          }
          System.debug('checkForTemplates templateIds='+templateIds.size()+' templateNames='+templateNames.size());
          if (idsOkay) {
             step.EmailTemplateNames__c = String.join(templateNames,',');
          }
       } // for (Cadence_Step__c step : stepsForTemplates
   } // checkForTemplates
   
   public static Boolean checkExistingSteps(Map<Id,Cadence_Step__c[]> uniqueNameMap) {
      // check to make sure that step names are unique within a cadence.
      Map<Id,Cadence__c> cadenceMap = getCadences(uniqueNameMap.keySet());
      System.debug('checkExistingSteps uniqueNameMap='+uniqueNameMap.size()+' cadenceMap='+cadenceMap.size());
      Boolean errorFound = false;
      for (Cadence__c cad : cadenceMap.values()) {
         //System.debug('checkExistingSteps cad='+cad.Name+' steps='+cad.Cadence_Steps__r.size());
         Set<String> stepNameSet = getStepNameSet(cad.Cadence_Steps__r);
         Cadence_Step__c[] stepsToCheck = uniqueNameMap.get(cad.Id);
         if (stepsToCheck != null && !stepNameSet.isEmpty()) {
            for (Cadence_Step__c step : stepsToCheck) {
               if (stepNameSet.contains(step.Name)) {
                  step.Name.addError('The name '+step.Name+' already exists for this Cadence! Step names must be unique!');
                  errorFound = true;
               }
            }
         }
      } // for (Cadence__c cad : cadenceMap
      return errorFound;
   } // checkExistingSteps
   
   public static Set<String> getStepNameSet(Cadence_Step__c[] steps) {
      Set<String> stepNameSet = new Set<String>();
      for (Cadence_Step__c step : steps) {
         stepNameSet.add(step.Name);
      }
      return stepNameSet;
   } // getStepNameSet
   
   public static void addToNameMap(Cadence_Step__c step, Map<Id,Cadence_Step__c[]> uniqueNameMap) {
      // add a step to the map, making sure the name isn't already in the map for that cadence (if it's a bulk operation)
      Cadence_Step__c[] steps = (uniqueNameMap.containsKey(step.CadenceId__c) ? uniqueNameMap.get(step.CadenceId__c) : new Cadence_Step__c[]{});
      Boolean found=false;
      System.debug('addToNameMap step='+step.Name+' steps='+steps.size());
      for (Cadence_Step__c checkStep : steps) {
         if (checkStep.Name == step.Name) {
            step.Name.addError('The name '+step.Name+' is used more than once for this Cadence! Step names must be unique!');
            found = true;
            break;
         }
      }
      System.debug('addToNameMap found='+found);
      if (!found) {
         steps.add(step);
         uniqueNameMap.put(step.CadenceId__c,steps);
      }
   } // addToNameMap
   
   public static void handleAcctsBefore(Account[] accts, Map<Id,Account> oldMap) {
      Account[] evaluateAccts = new Account[]{};
      for (Account acct : accts) {
         if (acct.EvaluateCadence__c) {
            acct.EvaluateCadence__c=false;
            evaluateAccts.add(acct);
         }
      } // for (Account acct : accts
      if (!evaluateAccts.isEmpty()) {
         new CadenceQueueable().checkAccts(evaluateAccts);
      }
   } // handleAcctsBefore
   
   public static void handleLeadsBefore(Lead[] leads, Map<Id,Lead> oldMap) {
      Lead[] evaluateLeads = new Lead[]{};
      for (Lead ld : leads) {
         if (ld.EvaluateCadence__c) {
            ld.EvaluateCadence__c=false;
            evaluateLeads.add(ld);
         }
      } // for (Account acct : accts
      if (!evaluateLeads.isEmpty()) {
         system.debug('handleLeadsBefore evaluateLeads is not empty calling CadenceQueueable');
         new CadenceQueueable().checkLeads(evaluateLeads);
      }
   } // handleLeadsBefore
    
   public static void handleRefAcctsBefore(Referral_Account__c[] refAccts, Map<Id,Referral_Account__c> oldMap) {
      Referral_Account__c[] evaluateAccts = new Referral_Account__c[]{};
      for (Referral_Account__c acct : refAccts) {
         if (acct.EvaluateCadence__c) {
            acct.EvaluateCadence__c=false;
            evaluateAccts.add(acct);
         }
      }
      if (!evaluateAccts.isEmpty()) {
         new CadenceQueueable().checkRefAccts(evaluateAccts);
      }
   } // handleRefAcctsBefore
   
   public static void handleRefAcctsAfter(Referral_Account__c[] refAccts, Map<Id,Referral_Account__c> oldMap) {
      // ids of Referral Accounts where we need to do extra checking for the CARs. 
      Map<Id,Referral_Account__c> refAcctCheckCarMap = new Map<Id,Referral_Account__c>();
          
      for (Referral_Account__c refAcct : refAccts) {
         Referral_Account__c oldRefAcct = (oldMap != null ? oldMap.get(refAcct.Id) : null);
         System.debug('handleRefAcctsAfter has oldRefAcct='+(oldRefAcct != null)+' Business_Type__c='+refAcct.Referral_Source_Business_Type__c+' old bus type='+(oldRefAcct != null ? oldRefAcct.Referral_Source_Business_Type__c : ''));
         if ((oldRefAcct == null && String.isNotBlank(refAcct.Group__c))   // if this is a new Ref Acct with the CPA Rotation filled out
             || (oldRefAcct != null && ((refAcct.End_Date__c != null && oldRefAcct.End_Date__c == null) // the Acct gets ended
                                       || (refAcct.Group__c != oldRefAcct.Group__c)  // the CPA Rotation field changes
                                       || (refAcct.Referral_Source_Business_Type__c != oldRefAcct.Referral_Source_Business_Type__c)  // the Referral Source Business Type changes
                                       || (refAcct.Referral_Type__c != oldRefAcct.Referral_Type__c)))  // the Referral Type field changes
            ) {
               refAcctCheckCarMap.put(refAcct.Id,refAcct);
         } // if ((oldRefAcct == null && String.isNotBlank
      } // for (Referral_Account__c refAcct : refAccts
      System.debug('handleRefAcctsAfter refAccts='+refAccts.size()+' refAcctCheckCarMap='+refAcctCheckCarMap.size());
      if (!refAcctCheckCarMap.isEmpty()) {
         checkRefAcctCars(refAcctCheckCarMap);
      }
   } // handleRefAcctsAfter
    
   public static void checkRefAcctCars(Map<Id,Referral_Account__c> refAcctMap) {
      Map<Id,Cadence_Touchpoint__c> updateTpMap = new Map<Id,Cadence_Touchpoint__c>();
      Map<Id,Cadence_Assignment_Record__c> updateCarMap = new Map<Id,Cadence_Assignment_Record__c>();
      Cadence_Assignment_Record__c[] newCars = new Cadence_Assignment_Record__c[]{};
      // if the cadence changed on a referral account and we have to re-evaluate
      Id[] refAcctsCadenceChanged = new Id[]{};

      // if there's an end date we'll close all open CARs
      // if no end date we'll assume the Group__c changed
      // get all open car records
      Id[] refAcctIds = new Id[]{};
      refAcctIds.addAll(refAcctMap.keySet());
      Cadence_Touchpoint__c[] openTps = WorkQueueController.getOpenTps(refAcctIds, null, null, false,'All Open Touchpoints');
      for (Cadence_Touchpoint__c tp : openTps) {
         // remove from the map so we know which ones we processed.
         Referral_Account__c refAcct = refAcctMap.remove(tp.CarRecord__r.ReferralAccount__c);
         if (refAcct != null) {
            Boolean cadenceChanged = false;
            Boolean ongoingFound = false;
            if (refAcct.End_Date__c != null) {
               // close the car - doesn't matter if ongoing or not.
               closeTouchpoints(tp, tp.CarRecord__r, 'Firm End Dated' , updateTpMap, updateCarMap);
               cadenceChanged = true;
            } else if (tp.Cadence__r.OngoingCadence__c) {
               // if this is an ongoing cadence, see if the ref acct matches the cadence criteria
               // if any of the criteria doesn't match 
               String[] referralTypes = (tp.Cadence__r.ReferralType__c != null ? tp.Cadence__r.ReferralType__c.split(';') : new String[]{});
               List<String> tpcadRfe = new List<String>(); 
               if(tp.Cadence__r.ReferralSourceBusinessType2__c != null ){
                  tpcadRfe = tp.Cadence__r.ReferralSourceBusinessType2__c.split(';');
               }
               
               
               if (!tpcadRfe.contains(refAcct.Referral_Source_Business_Type__c)
                   || tp.Cadence__r.CPARotation__c != refAcct.Group__c
                   || (!referralTypes.isEmpty() && !referralTypes.contains(refAcct.Referral_Type__c))
                   ) {
                  // end date this cadence
                  closeTouchpoints(tp, tp.CarRecord__r, 'Ongoing Criteria Changed' , updateTpMap, updateCarMap);
                  cadenceChanged = true;
               } else {
                  // the criteria matches so we found our car record.
                  ongoingFound = true;
               }
            }
            if (refAcct.End_Date__c == null && !ongoingFound) {
               // see if there's a cadence record that matches this referral account
               if (checkToAddOngoing(refAcct, newCars)) {
                  cadenceChanged = true;
               }
            } // if (refAcct.End_Date__c == null && !ongoingFound
            if (cadenceChanged) {
                refAcctsCadenceChanged.add(refAcct.Id); 
            }
         } // if (refAcct != null
      } // for (Cadence_Touchpoint__c tp : openTps
      
      // if there are any remaining, see if we need to add to a car.
      for (Referral_Account__c refAcct : refAcctMap.values()) {
         checkToAddOngoing(refAcct, newCars);
      }
       
      CadenceHelper.SKIP_TRIGGERS=true;
      DmlHelper.performDML2(updateCarMap.values(), DmlHelper.DML_UPDATE, CLASSNAME, 'checkRefAcctCars', 'Update CAR records', false);
      DmlHelper.performDML2(updateTpMap.values(), DmlHelper.DML_UPDATE, CLASSNAME, 'checkRefAcctCars', 'Update touchpoints', false);
      CadenceHelper.SKIP_TRIGGERS=false;
      DmlHelper.performDML2(newCars, DmlHelper.DML_INSERT, CLASSNAME, 'checkRefAcctCars', 'Insert new CARs', false);
      ErrorLog.checkSave();
      if (!refAcctsCadenceChanged.isEmpty()) {
         CadenceQueueable caq = new CadenceQueueable(refAcctsCadenceChanged);
         CadenceQueueable.RUN_INLINE=true;
         CadenceQueueable.launchQueueable(caq);
      }

   } // checkRefAcctCars
    
   public static Boolean checkToAddOngoing(Referral_Account__c refAcct, Cadence_Assignment_Record__c[] newCars) {
      Boolean cadFound = false;
      Cadence__c[] cadences = getOngoingCadences();
      for (Cadence__c cad : cadences) {
         String[] referralTypes = (String.isNotBlank(cad.ReferralType__c) ? cad.ReferralType__c.split(';') : new String[]{});
         List<String> refrlBusinesTypeList = new List<String>(); 
         if (cad.ReferralSourceBusinessType2__c != null) {
            refrlBusinesTypeList = cad.ReferralSourceBusinessType2__c.split(';');
         }
         
         if (refrlBusinesTypeList.CONTAINS(refAcct.Referral_Source_Business_Type__c)
             && (!referralTypes.isEmpty() && referralTypes.contains(refAcct.Referral_Type__c))
             && cad.CPARotation__c == refAcct.Group__c) {
            Cadence_Assignment_Record__c newCar = new Cadence_Assignment_Record__c(Name=refAcct.Name,Cadence__c=cad.Id, Status__c='Open'
                                                             ,CadenceObject__c=refAcct.Id, Cadence_Owner__c=refAcct.OwnerId);
            newCars.add(newCar);
            cadFound = true;
            break;
         }
      } // for (Cadence__c cad
      return cadFound;
   } // checkToAddOngoing
    
   public static Cadence__c[] v_ongoingCadences = null;
    
   public static Cadence__c[] getOngoingCadences() {
      if (v_ongoingCadences == null) {
         v_ongoingCadences = [Select Id, Name, Cadence_Type__c, TargetType__c, ReferralSourceCadence__c, OngoingCadence__c
                                  ,ReferralSourceBusinessType2__c
                                  ,ReferralType__c
                                  ,CPARotation__c
                              From Cadence__c
                             Where Active__c=true
                               and OngoingCadence__c=true];  
      }
      return v_ongoingCadences;
   } // getOngoingCadences
    
   public static void closeTouchpoints(Cadence_Touchpoint__c tp, Cadence_Assignment_Record__c car, String closeReason
                                       ,Map<Id,Cadence_Touchpoint__c> updateTpMap, Map<Id,Cadence_Assignment_Record__c> updateCarMap) {
      tp.Close_Date__c = Date.today();
      tp.Status__c = closeReason;
      tp.LastUpdateMethod__c='CadenceHelper.closeTouchpoints';
      car.Closed__c=true;
      car.Status__c='Closed';
      car.CloseReason__c = closeReason;
      car.Close_Date__c = Date.today();
      updateTpMap.put(tp.Id, tp);
      updateCarMap.put(car.Id,car);
   } // closeTouchpoints

   public static void checkCadenceAfter(Cadence__c[] cads, Map<Id,Cadence__c> oldMap) {
      Boolean closeReasonsChanged = false;
      Id[] cadsToUpdateClonedField = new Id[]{};
      Map<Id,Cadence__c> cadsToCloneSteps = new Map<Id,Cadence__c>();
      for (Cadence__c cad : cads) {
         Cadence__c oldRec = (oldMap != null ? oldMap.get(cad.Id) : null);
         // if this is an insert and if it was cloned from another record, copy the cadence steps.
         if (oldRec == null && String.isNotBlank(cad.IsThisCloned__c) && cad.IsThisCloned__c != cad.Id) {
            try {
               Id oldCadId = (Id)cad.IsThisCloned__c;
               cadsToCloneSteps.put(oldCadId,cad);
            } catch (Exception e) {
               System.debug('checkCadenceAfter exception setting id; '+e.getMessage());
            }
            cadsToUpdateClonedField.add(cad.Id);            
         } else if (String.isBlank(cad.IsThisCloned__c) || cad.IsThisCloned__c != cad.Id) {
            cadsToUpdateClonedField.add(cad.Id);            
         }
         if ((oldRec == null && String.isNotBlank(cad.CloseReasons__c))
             || (oldRec != null && cad.CloseReasons__c != oldRec.CloseReasons__c)) {
            closeReasonsChanged = true;
            break;
         }
      } // for (Cadence__c cad : cads
      System.debug('checkCadenceAfter cadsToCloneSteps='+cadsToCloneSteps.size()+' cadsToUpdateClonedField='+cadsToUpdateClonedField.size());
      if (!cadsToCloneSteps.isEmpty()) {
         cloneSteps(cadsToCloneSteps);
      }
      if (closeReasonsChanged) {
         WorkQueueController.clearCache();
      }
      if (!cadsToUpdateClonedField.isEmpty()) {
         updateClonedField(cadsToUpdateClonedField);
      }
   } // checkCadenceAfter
    
   public static void updateClonedField(Id[] cadIds) {
      Cadence__c[] updateCads = new Cadence__c[]{};
      for (Id cadId : cadIds) {
         updateCads.add(new Cadence__c(Id=cadId, IsThisCloned__c=cadId));
      }
      SKIP_TRIGGERS=true;
      DmlHelper.performDML2(updateCads, DmlHelper.DML_UPDATE, CLASSNAME, 'updateClonedField', 'updateClonedField', true);
      SKIP_TRIGGERS=false;
   } // updateClonedField
    
   public static void cloneSteps(Map<Id,Cadence__c> cadMap) {
      String stepQuery = ObjectHelper.getSOQLQuery('Cadence_Step__c', null, true, true, true, false, true);
      Set<Id> cadIdSet = cadMap.keySet();
      stepQuery += ' Where CadenceId__c in :cadIdSet ';
      // get the cadence steps from the old cadences
      Cadence_Step__c[] steps = Database.query(stepQuery);
      Cadence_Step__c[] newSteps = new Cadence_Step__c[]{};
      for (Cadence_Step__c step : steps) {
         Cadence__c newCad = cadMap.get(step.CadenceId__c);
         System.debug('cloneSteps step='+step.Name+' newCad='+(newCad != null ? newCad.Name : 'Not Found'));
         if (newCad != null) {
            Cadence_Step__c newStep = step.clone(false,false,false,false);
            newStep.CadenceId__c = newCad.Id;
            newSteps.add(newStep);
         }
      }
      DmlHelper.performDML2(newSteps, DmlHelper.DML_INSERT, CLASSNAME, 'cloneSteps', 'Create new Steps', true);

   } // cloneSteps

   public static Id[] oppIdsToEvaluateTouchpoints = new Id[]{};
   public static void handleOppsBefore(Opportunity[] opps, Map<Id,Opportunity> oldMap) {
       oppIdsToEvaluateTouchpoints.clear();
        for (Opportunity opp : opps) {
           Opportunity oldOpp = (oldMap != null ? oldMap.get(opp.Id) : null);
            if (oldMap != null && opp.EvaluateTouchpoints__c) {
               oppIdsToEvaluateTouchpoints.add(opp.Id);
               opp.EvaluateTouchpoints__c = false;
            }
        }
    } // handleOppsBefore
    
   public static void handleOppsAfter(Opportunity[] opps, Map<Id,Opportunity> oldMap) {
      // if an opportunity is created, check to see if attached to a cadence and then link and update the cadence
      Id[] oppsToCheckCadence = new Id[]{};
      oppsToCheckCadence.addAll(oppIdsToEvaluateTouchpoints);
      oppIdsToEvaluateTouchpoints.clear();
       
      for (Opportunity opp : opps) {
         Opportunity oldOpp = (oldMap != null ? oldMap.get(opp.Id) : null);
         // check all opportunities on insert except for referrals
         //if (oldOpp == null && opp.OpportunityType__c != Label.OppType_Referral) {
         // check all opportunities on insert as long as they don't have the field campaign already populated.
         if (oldOpp == null && String.isBlank(opp.Field_Campaign__c)) {
            oppsToCheckCadence.add(opp.Id);
         }
      } // for (Opportunity opp
      System.debug('handleOppsAfter opps='+opps.size()+' oppsToCheckCadence='+oppsToCheckCadence.size());
      if (!oppsToCheckCadence.isEmpty()) {
         if (Utilities.allowFuture()) {
            checkOppCadenceFuture(oppsToCheckCadence) ;
         } else {
            checkOppCadenceNow(oppsToCheckCadence);
         }
      }
   } // handleOppsAfter
   
   @future
   public static void checkOppCadenceFuture(Id[] oppIds) {
      checkOppCadenceNow(oppIds);
   } // checkOppCadenceFuture
    
   // when an opp is created, see if there's a touchpoint associated with it.
   // If coming from ReferralController (initiated by Touchpoint) then the touchpoint Id should have already been set.
   // If linked to a referral source, see if the referral account is in a cadence. If the account directly 
   public static void checkOppCadenceNow(Id[] oppIds) {
      ErrorLog__c log = ErrorLog.getLog(CLASSNAME);
      // set the first id to the log
      log.ObjectId__c=oppIds[0];
      log.ObjectAPIName__c='Opportunity';
      log.BatchSize__c=oppIds.size();
       
      System.debug('checkOppCadenceNow oppIds='+oppIds.size());
      // query the Opportunities
      Opportunity[] opps = [Select Id, Name, OwnerId, Owner.User_Cadence_Type__c, Owner.User_Cadence_Type_Group__c
                                  ,AccountId, OpportunityType__c
                                  ,Cadence_Touchpoint__c
                                  ,Cadence_Touchpoint__r.CarRecord__c
                                  ,Field_Campaign__c, LeadSourceCategory__c
                                  ,Referral_Contact__c
                                  ,Referral_Contact__r.Referral_Account__c
                                  ,ReferralLookup__c
                                  ,ReferralLookup__r.Id
                                  ,ReferralLookup__r.Cadence_Touchpoint__c
                                  ,ReferralLookup__r.ProcessNotes__c
                                  ,CreatedById, CreatedBy.User_Cadence_Type__c, CreatedBy.User_Cadence_Type_Group__c
                                  ,CreatedDate
                              from Opportunity where Id in :oppIds];
       

      // select touchpoint ids to make sure we get what's linked.
      Id[] touchpointIds = new Id[]{};
      Map<Id,Opportunity[]> oppByAcctIdMap = new Map<Id,Opportunity[]>();
      for (Opportunity opp : opps) {
         //if (opp.Cadence_Touchpoint__c == null &&  opp.AccountId != null) {
         if (opp.AccountId != null) {
            Opportunity[] oppsByAcct = (oppByAcctIdMap.containsKey(opp.AccountId) ? oppByAcctIdMap.get(opp.AccountId) : new Opportunity[]{});
            oppsByAcct.add(opp);
            oppByAcctIdMap.put(opp.AccountId,oppsByAcct);
            //acctIds.add(opp.AccountId);
         } 
         // look to see if there's a cadence attached to the referral account
         if (opp.Cadence_Touchpoint__c == null && opp.Referral_Contact__c != null && opp.Referral_Contact__r.Referral_Account__c != null) {
            Opportunity[] oppsByAcct = (oppByAcctIdMap.containsKey(opp.Referral_Contact__r.Referral_Account__c) ? oppByAcctIdMap.get(opp.Referral_Contact__r.Referral_Account__c) : new Opportunity[]{});
            oppsByAcct.add(opp);
            oppByAcctIdMap.put(opp.Referral_Contact__r.Referral_Account__c,oppsByAcct);
         } 
         if (opp.Cadence_Touchpoint__c != null) {
            touchpointIds.add(opp.Cadence_Touchpoint__c);
         }
      } // for
       
      ErrorLog.addToDescription(log,'oppIds='+oppIds.size()+' opps='+opps.size()+' touchpointIds='+touchpointIds.size());
      
   
      Cadence_Touchpoint__c[] touchpoints = [Select Id, AccountId__c
                                                   ,Close_Date__c
                                                   ,IsLatestTouchpoint__c
                                                   ,LastUpdateMethod__c
                                                   ,OpportunityId__c
                                                   ,OwnerId
                                                   ,Status__c
                                                   ,Cadence__r.Id
                                                   ,Cadence__r.Active__c
                                                   ,Cadence__r.Opportunity_Type__c
                                                   ,Cadence__r.Cadence_Type__c
                                                   ,Cadence__r.CadenceTypeGroup__c
                                                   ,Cadence__r.DaysUntilExpiration__c
                                                   ,Cadence__r.MatchReferringOpp__c
                                                   ,Cadence__r.OngoingCadence__c
                                                   ,Cadence__r.OppClosesCAR__c
                                                   ,Cadence__r.OppMatchesCarCloseReason__c
                                                   ,Cadence__r.OppTypeOnlyClosesCAR__c
                                                   ,Cadence__r.Priority__c
                                                   ,Cadence__r.Sales_Campaign_Name__c
                                                   ,CarRecord__r.Id
                                                   ,CarRecord__r.AccountId__c
                                                   ,CarRecord__r.OwnerId
                                                   ,CarRecord__r.Closed__c
                                                   ,CarRecord__r.Close_Date__c
                                                   ,CarRecord__r.CloseReason__c
                                                   ,CarRecord__r.LatestTouchpoint__c
                                                   ,CarRecord__r.LatestTouchpoint__r.Id
                                                   ,CarRecord__r.LatestTouchpoint__r.Close_Date__c
                                                   ,CarRecord__r.LatestTouchpoint__r.LastUpdateMethod__c
                                                   ,CarRecord__r.LatestTouchpoint__r.Status__c
                                                   ,CarRecord__r.LatestCadenceActivityDate__c
                                                   ,CarRecord__r.OpportunityId__c
                                                   ,CarRecord__r.OpportunityCreatedFromCadence__c
                                                   ,CarRecord__r.ReferralAccount__c
                                                   ,CarRecord__r.Rep_Closed__c
                                                   ,CarRecord__r.Sales_Program__c
                                                   ,CarRecord__r.Start_Date__c
                                                   ,CarRecord__r.Started__c
                                                   ,CarRecord__r.Status__c
                                               From Cadence_Touchpoint__c
                                              Where Cadence__r.Active__c = true
                                                and ((CarRecord__r.AccountId__c in :oppByAcctIdMap.keySet() and IsLatestTouchpoint__c=true)   // pull the latest touchpoints from the cars only
                                                     or (CarRecord__r.ReferralAccount__c  in :oppByAcctIdMap.keySet() and IsLatestTouchpoint__c=true)
                                                     or (Id in :touchpointIds))  // or if we have the specific ids pull those - might not be the latest?
                                              order by CarRecord__r.LatestCadenceActivityDate__c desc nulls last, Cadence__r.Priority__c desc nulls last, CreatedDate desc];
       
      Map<Id,Cadence_Touchpoint__c[]> tpByAcctMap = new Map<Id,Cadence_Touchpoint__c[]>();
      // group all of the touchpoints by account id
      for (Cadence_Touchpoint__c tp : touchpoints) {
         if (tp.CarRecord__r.AccountId__c != null) {
            Cadence_Touchpoint__c[] tps = (tpByAcctMap.containsKey(tp.CarRecord__r.AccountId__c) ? tpByAcctMap.get(tp.CarRecord__r.AccountId__c) : new Cadence_Touchpoint__c[]{});
            tps.add(tp);
            tpByAcctMap.put(tp.CarRecord__r.AccountId__c,tps);
         }
         if (tp.CarRecord__r.ReferralAccount__c != null) {
            Cadence_Touchpoint__c[] tps = (tpByAcctMap.containsKey(tp.CarRecord__r.ReferralAccount__c) ? tpByAcctMap.get(tp.CarRecord__r.ReferralAccount__c) : new Cadence_Touchpoint__c[]{});
            tps.add(tp);
            tpByAcctMap.put(tp.CarRecord__r.ReferralAccount__c,tps);
         }
      } // for (Cadence_Touchpoint__c
      ErrorLog.addToDescription(log,'oppByAcctIdMap='+oppByAcctIdMap.size()+' touchpoints='+touchpoints.size()+' tpByAcctMap='+tpByAcctMap.size());
       
      System.debug('checkOppCadenceNow oppByAcctIdMap='+oppByAcctIdMap.size()+' touchpoints='+touchpoints.size());
      Map<Id,Cadence_Touchpoint__c> updateTpMap = new Map<Id,Cadence_Touchpoint__c>();
      Map<Id,Cadence_Assignment_Record__c> updateCarMap = new Map<Id,Cadence_Assignment_Record__c>();
      Map<Id,Opportunity> updateOppMap = new Map<Id,Opportunity>();
      Map<Id,Referral__c> updateRefMap = new Map<Id,Referral__c>();

      for (Id acctId : tpByAcctMap.keySet()) {
         Opportunity[] oppsByAcct = oppByAcctIdMap.get(acctId);
         Cadence_Touchpoint__c[] tps = tpByAcctMap.get(acctId);
         ErrorLog.addToDescription(log,'acctId='+acctId+' oppsByAcct='+(oppsByAcct != null ? oppsByAcct.size() : -1)+' tps='+(tps != null ? tps.size() : -1));
         if (oppsByAcct != null && tps != null) {
            for (Opportunity opp : oppsByAcct) {
                if (checkTouchpoint(opp, tps, updateTpMap, updateCarMap, updateOppMap,log, updateRefMap)) {
                    // once we find one that matches stop for this opp.
                    break;
                }
            } // for (Opportunity opp : oppsByAcct
         } // if (opps != null && tps != null
      } // for (Id acctId : tpByAcctMap

      ErrorLog.addToDescription(log,'updateCarMap='+updateCarMap.size()+' updateTpMap='+updateTpMap.size()+' updateOppMap='+updateOppMap.size());
      System.debug('checkOppCadenceNow updateTpMap='+updateTpMap.size()+' updateCarMap='+updateCarMap.size());
      CadenceHelper.SKIP_TRIGGERS=true;
      OpptyMethods.SKIP_OPPTY_TRIGGERS=true;
      ReferralTriggerActions.SKIP_TRIGGER=true;
      log.NbrSuccess__c=updateCarMap.size();
      DmlHelper.performDML2(updateCarMap.values(), DmlHelper.DML_UPDATE, CLASSNAME, 'checkOppCadenceNow', 'Update CAR records', false);
      DmlHelper.performDML2(updateTpMap.values(), DmlHelper.DML_UPDATE, CLASSNAME, 'checkOppCadenceNow', 'Update touchpoints', false);
      DmlHelper.performDML2(updateOppMap.values(), DmlHelper.DML_UPDATE, CLASSNAME, 'checkOppCadenceNow', 'Update Opportunity', false);
      DmlHelper.performDML2(updateRefMap.values(), DmlHelper.DML_UPDATE, CLASSNAME, 'checkOppCadenceNow', 'Update Referrals', false);
      
      ErrorLog.checkSave();
      ReferralTriggerActions.SKIP_TRIGGER=false;

      if (!updateCarMap.isEmpty()) {
         Id[] acctIds = new Id[]{};
         for (Cadence_Assignment_Record__c car : updateCarMap.values()) {
            if (car.AccountId__c != null) {
               acctIds.add(car.AccountId__c);
            } else if (car.ReferralAccount__c != null) {
               acctIds.add(car.ReferralAccount__c);
            }
         } // for (Cadence_Assignment_Record__c car
         if (!acctIds.isEmpty()) {
            CadenceQueueable caq = new CadenceQueueable(acctIds);
            CadenceQueueable.RUN_INLINE=true;
            CadenceQueueable.launchQueueable(caq);
         }
       } // if (!updateCars
       ErrorLog.saveLog(log);
   } // checkOppCadenceNow
    
   public static boolean checkTouchpoint(Opportunity opp, Cadence_Touchpoint__c[] tpsToCheck
                                            ,Map<Id,Cadence_Touchpoint__c> updateTpMap
                                            , Map<Id,Cadence_Assignment_Record__c> updateCarMap, Map<Id,Opportunity> updateOppMap
                                            ,ErrorLog__c log
                                            ,Map<Id,Referral__c> updateRefMap) {
      Boolean handled=false;
      Boolean isReferralOpp = (opp.OpportunityType__c == Label.OppType_Referral);
      String chkLog = 'checkTouchpoint opp='+opp.Name+' opp owner='+opp.OwnerId+' opp createdby='+opp.CreatedById+' isReferralOpp='+isReferralOpp;
      for (Cadence_Touchpoint__c touchpoint : tpsToCheck) {
         Boolean isReferralCadence = (touchpoint.Cadence__r.MatchReferringOpp__c);
         chkLog += '\ntp='+touchpoint.Id+' tp owner='+touchpoint.OwnerId+' isReferralCadence='+isReferralCadence;
         if (isReferralOpp && !isReferralCadence) {
            continue;
         }
         // if we only need to match using the opportunity type (for special reasons, like ERTC)
         Boolean onlyUseOppType = (touchpoint.Cadence__r.OppTypeOnlyClosesCAR__c && String.isNotBlank(touchpoint.Cadence__r.Opportunity_Type__c));
         Boolean oppTypeMatches = false;
         if (String.isNotBlank(touchpoint.Cadence__r.Opportunity_Type__c) && String.isNotBlank(opp.OpportunityType__c)) {
             chkLog += ', Cadence Opp Types='+touchpoint.Cadence__r.Opportunity_Type__c+'; opp OppType='+opp.OpportunityType__c;
             System.debug('touchpoint.Cadence__r.Opportunity_Type__c='+touchpoint.Cadence__r.Opportunity_Type__c);
             Set<String> cadOppTypes = new Set<String>(touchpoint.Cadence__r.Opportunity_Type__c.split(';'));
             oppTypeMatches = cadOppTypes.contains(opp.OpportunityType__c);
         }
         chkLog += '; onlyUseOppType='+onlyUseOppType+' oppTypeMatches='+oppTypeMatches;
         if (onlyUseOppType && !oppTypeMatches) {
            continue;
         }
         // for right now we're going to assume that the first open one owned by the opp owner is the one we need to use
         Boolean matchesOpp = (opp.Cadence_Touchpoint__c != null && opp.Cadence_Touchpoint__c == touchpoint.Id);
         Boolean tpIdMatched = matchesOpp;
         Boolean dateCheckOkay = matchesOpp;
         if (!matchesOpp) {
            if (touchpoint.Close_Date__c != null) {
               if (touchpoint.IsLatestTouchpoint__c) {
                  Integer nbrDays = (touchpoint.Cadence__r.DaysUntilExpiration__c != null ? Integer.valueOf(touchpoint.Cadence__r.DaysUntilExpiration__c) : 0);
                  Date closeDateCheck = Date.today().addDays(-nbrDays);
                  System.debug('checkTouchpoint closeDate='+touchpoint.Close_Date__c+' closeDateCheck='+closeDateCheck);
                  dateCheckOkay = touchpoint.Close_Date__c >= closeDateCheck;
               } else {
                 dateCheckOkay = false;
               }
            } else {
               dateCheckOkay = true;
            }
         } // if (!matchesOpp

         chkLog += ', matchesOpp 1='+matchesOpp+' tp active='+(touchpoint.Close_Date__c == null)+' opp.Cadence_Touchpoint__c='+opp.Cadence_Touchpoint__c+' dateCheckOkay='+dateCheckOkay;
         // only do these checks if the touchpoint is active
         if (dateCheckOkay && opp.Cadence_Touchpoint__c == null) {
            if (!onlyUseOppType && !matchesOpp) {
                matchesOpp = (touchpoint.OwnerId == opp.OwnerId || touchpoint.OwnerId == opp.CreatedById);
            }
            chkLog += ', matchesOpp 2='+matchesOpp;
            if (!onlyUseOppType && !matchesOpp) {
                matchesOpp = (touchpoint.CarRecord__r.OwnerId == opp.OwnerId || touchpoint.CarRecord__r.OwnerId == opp.CreatedById);
            }
            chkLog += ', matchesOpp 3='+matchesOpp;
            if (!onlyUseOppType && !matchesOpp && touchpoint.Cadence__r != null && touchpoint.Cadence__r.Active__c) {
                matchesOpp = ((touchpoint.Cadence__r.Cadence_Type__c == opp.Owner.User_Cadence_Type__c)
                              || (touchpoint.Cadence__r.Cadence_Type__c == opp.CreatedBy.User_Cadence_Type__c)
                              || (touchpoint.Cadence__r.CadenceTypeGroup__c == opp.Owner.User_Cadence_Type_Group__c)
                              || (touchpoint.Cadence__r.CadenceTypeGroup__c == opp.CreatedBy.User_Cadence_Type_Group__c));
            }
            chkLog += ', matchesOpp 4='+matchesOpp;

            // checking cadence opp touchpoint cadence type if there's a value there.
            if ((matchesOpp || onlyUseOppType) && String.isNotBlank(touchpoint.Cadence__r.Opportunity_Type__c)) {
               //chkLog += ', Cadence Opp Types='+touchpoint.Cadence__r.Opportunity_Type__c;
               //System.debug('touchpoint.Cadence__r.Opportunity_Type__c='+touchpoint.Cadence__r.Opportunity_Type__c);
               //Set<String> cadOppTypes = new Set<String>(touchpoint.Cadence__r.Opportunity_Type__c.split(';'));
               matchesOpp = oppTypeMatches;
            }
            chkLog += ', matchesOpp 5='+matchesOpp;

             
         } // if (touchpoint.Close_Date__c == null
          
         if (matchesOpp 
             && (touchpoint.OpportunityId__c == null || !touchpoint.Cadence__r.OppClosesCAR__c)
             && !updateTpMap.containsKey(touchpoint.Id)) {
            Boolean isSelfGen = (isReferralOpp || opp.LeadSourceCategory__c == 'Self Generated');
            String salesProgram = (touchpoint.Cadence__r.OngoingCadence__c ? touchpoint.Cadence__r.Sales_Campaign_Name__c : touchpoint.CarRecord__r.Sales_Program__c);
            chkLog += ', tp='+touchpoint.Id+' match isSelfGen='+isSelfGen+' salesProgram='+salesProgram;
            // link the touchpoint to the opp
            Opportunity updateOpp = new Opportunity(Id=opp.Id, Cadence_Touchpoint__c=touchpoint.Id);
            updateOppMap.put(updateOpp.Id, updateOpp);
            if (opp.ReferralLookup__c != null && opp.ReferralLookup__r.Cadence_Touchpoint__c == null) {
               opp.ReferralLookup__r.Cadence_Touchpoint__c = touchpoint.Id;
               StringHelper.addToProcessNotes(opp.ReferralLookup__r,'Setting touchpoint Id due to Opp creation '+touchpoint.Id);
               updateRefMap.put(opp.ReferralLookup__r.Id,opp.ReferralLookup__r);
            }
            if ((tpIdMatched || isSelfGen || touchpoint.CarRecord__r.ReferralAccount__c != null)
                      && String.isNotBlank(salesProgram) && opp.Field_Campaign__c != salesProgram) {
            //if (String.isNotBlank(salesProgram) && opp.Field_Campaign__c != salesProgram) {
               // if this is self generated update the Field Campaign on the opp.
               updateOpp.Field_Campaign__c=salesProgram;
               chkLog += ', updating opp field campaign';
            }
            Cadence_Assignment_Record__c car = new Cadence_Assignment_Record__c(Id=touchpoint.CarRecord__r.Id);
            Cadence_Touchpoint__c updateTP = new Cadence_Touchpoint__c(Id=touchpoint.Id);
            updateTP.OpportunityId__c = opp.Id;
            // if not already closed, then close
            if (touchpoint.Close_Date__c == null && touchpoint.Cadence__r.OppClosesCAR__c) {
               updateTP.Close_Date__c = Date.today();
               updateTP.Status__c = (opp.Cadence_Touchpoint__c != null ? 'Closed - Cadence Ended' : 'Closed');
               updateTp.LastUpdateMethod__c='CadenceHelper.checkTouchpoint1';

            }
            if (!touchpoint.IsLatestTouchpoint__c && touchpoint.Cadence__r.OppClosesCAR__c) {
               Cadence_Touchpoint__c updateTP2 = touchpoint.CarRecord__r.LatestTouchpoint__r;
               updateTP2.Close_Date__c = Date.today();
               updateTP2.Status__c = (opp.Cadence_Touchpoint__c != null ? 'Closed - Cadence Ended' : 'Closed');
               updateTP2.LastUpdateMethod__c='CadenceHelper.checkTouchpoint2';
               updateTpMap.put(updateTP2.Id, updateTP2);
            } 
            updateTpMap.put(updateTP.Id, updateTP);
            if (touchpoint.Cadence__r.OppClosesCAR__c) {
               car.OpportunityId__c = opp.Id;
               car.Closed__c = true;
               car.Status__c = 'Closed';
               if (isSelfGen) {
                  car.Rep_Closed__c = true;
                  car.OpportunityCreatedFromCadence__c = opp.Id;
                  car.Started__c = True;
                  /*if (car.Start_Date__c == null) {
                     car.Start_Date__c = Date.Today();
                  }*/
               }
               String closeReason = (isReferralOpp && String.isNotBlank(touchpoint.Cadence__r.OppMatchesCarCloseReason__c) ? touchpoint.Cadence__r.OppMatchesCarCloseReason__c
                                       : (isSelfGen ? 'Opportunity Created Outside Touchpoint' : 'Unrelated Opportunity Created'));
               car.CloseReason__c = (opp.Cadence_Touchpoint__c != null ? 'Opportunity Created in Touchpoint' : closeReason);
                                        
               car.Close_Date__c = Date.today();
               // this is needed in order to call the queueable
               car.AccountId__c = opp.AccountId;
               updateCarMap.put(car.Id, car);
            } // if (touchpoint.Cadence__r.OppClosesCAR__c
         } // if (touchpoint.OwnerId
         if (matchesOpp) {
            handled = matchesOpp;
            break; 
         }
      } // for (Cadence_Touchpoint__c touchpoint                                    
      ErrorLog.addToDescription(log,chkLog);
      return handled;
   } // checkTouchpoint
    
   public static void updateCarsForTouchpoints(Cadence_Touchpoint__c[] tpsToCheck) {
      Id[] carIds = new Id[]{};
      for (Cadence_Touchpoint__c tp : tpsToCheck) {
         if (tp.CarRecord__c != null) {
            carIds.add(tp.CarRecord__c);
         }
      } // for (Cadence_Touchpoint__c tp
      if (!carIds.isEmpty()) {
         checkCarTouchpoints(carIds);
      }
   } // updateCarsForTouchpoints
   
   // check all of the touchpoints on a car
   public static void checkCarTouchpoints(Id[] carIds) {
      Cadence_Assignment_Record__c[] cars = [Select Id, Name, Cadence__c, Closed__c, Close_Date__c
                                                   ,EvaluateTouchpoints__c, LatestTouchpoint__c, NbrOfTouchpoints__c
                                                   ,Rep_Closed__c, CloseReason__c
                                                   ,Status__c,LatestTouchpointCompletedByRep__c, Start_Date__c
                                                   ,(Select Id, Close_Date__c, Status__c,StepCompletedByRep__c
                                                       From Cadence_Touchpoints__r
                                                      Order by StepCounter__c desc nulls last, CreatedDate desc)
                                               From Cadence_Assignment_Record__c
                                              Where Id in :carIds];
      Cadence_Assignment_Record__c[] updateCars = new Cadence_Assignment_Record__c[]{};
      for (Cadence_Assignment_Record__c car : cars) {
         Boolean carUpdated = false;
         Integer nbrTPs = car.Cadence_Touchpoints__r.size();
         Id latestTPId = (nbrTPs > 0 ? car.Cadence_Touchpoints__r[0].Id : null);
         if (car.NbrOfTouchpoints__c != nbrTPs || car.LatestTouchpoint__c != latestTPId 
              || car.EvaluateTouchpoints__c) {
            car.EvaluateTouchpoints__c = false;
            car.NbrOfTouchpoints__c = nbrTPs;
            car.LatestTouchpoint__c = latestTPId;
            carUpdated = true;
         }
         if(!car.Cadence_Touchpoints__r.isEmpty()){
            for(Cadence_Touchpoint__c tp: car.Cadence_Touchpoints__r){
                if(tp.StepCompletedByRep__c =='Complete' && car.LatestTouchpointCompletedByRep__c != tp.Id){
                    car.LatestTouchpointCompletedByRep__c = tp.Id;
                    car.Started__c = True;
                    if (car.Start_Date__c == null) {
                       car.Start_Date__c = Date.Today();
                    }
                    carUpdated = true;
                    break;
                }

            }

        }
        if (carUpdated) {
           updateCars.add(car);
        }
      } // for
      DmlHelper.performDML2(updateCars, DmlHelper.DML_UPDATE, CLASSNAME, 'checkCarTouchpoints', 'Update Cars', true);
   } // checkCarTouchpoints
   
   
   //public static final String CADENCE_CACHE_KEY='CadenceHelperCadenceMap';
   
   public static Map<Id,Cadence__c> getActiveCadenceMap() {
      String query = getCadenceQuery();
      Cadence__c[] cadences = Database.query(query);
      Map<Id,Cadence__c> cadenceMap = new Map<Id,Cadence__c>(cadences);
      /*
      Map<Id,Cadence__c> cadenceMap = (Map<Id,Cadence__c>)CacheManager.getOrg(CADENCE_CACHE_KEY);
      System.debug('getActiveCadenceMap cadenceMap found in cache='+(cadenceMap != null));
      if (cadenceMap == null) {
         // build the query dynamically
         String[] flds = new String[]{};
         Schema.FieldSet cadenceStepFS = Schema.SObjectType.Cadence_Step__c.fieldSets.CadenceHelper_Query;
         for (Schema.FieldSetMember fsm : cadenceStepFS.getFields()) {
            flds.add(fsm.getFieldPath());
         } // for (Schema.FieldSetMember fsm

         //ObjectHelper.getSOQLQuery('Cadence_Step__c', null, true, false, true, false);
         //String[] flds = new String[]{};
         //flds.addAll(ObjectHelper.latestSoqlWrapper.flds);
         String subQuery = ',(Select '+String.join(flds,',')+' From Cadence_Steps__r)';
         
         Schema.FieldSet cadenceFS = Schema.SObjectType.Cadence__c.fieldSets.CadenceHelper_Query;
         //ObjectHelper.getSOQLQuery('Cadence__c', null, true, false, true, false);
         flds = new String[]{};
         for (Schema.FieldSetMember fsm : cadenceFS.getFields()) {
            flds.add(fsm.getFieldPath());
         } // for (Schema.FieldSetMember fsm
         //flds.addAll(ObjectHelper.latestSoqlWrapper.flds);
         String query = 'Select '+String.join(flds,',')+' '+subQuery+' From Cadence__c where Active__c=true';
         System.debug('getActiveCadenceMap query='+query);
         Cadence__c[] cadences = Database.query(query);
         cadenceMap = new Map<Id,Cadence__c>(cadences);
         CacheManager.putOrg(CADENCE_CACHE_KEY,cadenceMap);
      } // if (cadenceMap == null  
      */
      return cadenceMap;
   } // getActiveCadenceMap
    
   public static final String CADENCE_QUERY_CACHE_KEY='CadenceHelperCadenceQueryKey';
   public static String getCadenceQuery() {
      String query = (String)CacheManager.getOrg(CADENCE_QUERY_CACHE_KEY);
      if (query == null) {
         // build the query dynamically
         String[] flds = new String[]{};
         Schema.FieldSet cadenceStepFS = Schema.SObjectType.Cadence_Step__c.fieldSets.CadenceHelper_Query;
         for (Schema.FieldSetMember fsm : cadenceStepFS.getFields()) {
            flds.add(fsm.getFieldPath());
         } // for (Schema.FieldSetMember fsm

         //ObjectHelper.getSOQLQuery('Cadence_Step__c', null, true, false, true, false);
         //String[] flds = new String[]{};
         //flds.addAll(ObjectHelper.latestSoqlWrapper.flds);
         String subQuery = ',(Select '+String.join(flds,',')+' From Cadence_Steps__r)';
         
         Schema.FieldSet cadenceFS = Schema.SObjectType.Cadence__c.fieldSets.CadenceHelper_Query;
         //ObjectHelper.getSOQLQuery('Cadence__c', null, true, false, true, false);
         flds = new String[]{};
         for (Schema.FieldSetMember fsm : cadenceFS.getFields()) {
            flds.add(fsm.getFieldPath());
         } // for (Schema.FieldSetMember fsm
         //flds.addAll(ObjectHelper.latestSoqlWrapper.flds);
         query = 'Select '+String.join(flds,',')+' '+subQuery+' From Cadence__c where Active__c=true';
         CacheManager.putOrg(CADENCE_QUERY_CACHE_KEY,query);
      }
      return query;
   } // getCadenceQuery
   
   public static void clearCadenceMapCache() {
      System.debug('clearCadenceMapCache called');
      //CacheManager.removeOrg(CADENCE_CACHE_KEY);
      CacheManager.removeOrg(CADENCE_QUERY_CACHE_KEY);
   } // clearCadenceMapCache
   
   public static Map<Id,Cadence__c> getCadences(Set<Id> p_cadenceIdSet) {
      String query = getCadenceQuery();
      Set<Id> cadenceIdSet = new Set<Id>();
      cadenceIdSet.addAll(p_cadenceIdSet);
      query += ' and Id in :cadenceIdSet';
      Cadence__c[] cadences = Database.query(query);
      Map<Id,Cadence__c> returnMap = new Map<Id,Cadence__c>(cadences);
      System.debug('getCadences cadenceIdSet='+cadenceIdSet.size()+' cadences='+cadences.size()+' returnMap='+returnMap.size());
      //Map<Id,Cadence__c> returnMap = new Map<Id,Cadence__c>();
      //Map<Id,Cadence__c> allCadenceMap = getActiveCadenceMap();
      //for (Id cadenceId : cadenceIdSet) {
      //   if (allCadenceMap.containsKey(cadenceId)) {
      //      returnMap.put(cadenceId,allCadenceMap.get(cadenceId));
      //   }
      //} // for (Id cadenceId : cadenceIdSet
      return returnMap;
   } // getCadences
    
   // called from SLAHelperBatch
   public static void handleExpiredTPs(Cadence_Touchpoint__c[] recs) {
      System.debug('handleExpiredTPs recs='+recs.size());
      Cadence_Touchpoint__c[] updateTps = new Cadence_Touchpoint__c[]{};
      for (Cadence_Touchpoint__c rec : recs) {
         rec.Close_Date__c = Date.today();
         rec.CloseDateTime__c = Datetime.now();
         rec.Status__c =  CadenceUpdate.STATUS_INCOMPLETE;
         updateTps.add(rec);
      } // for (Cadence_Touchpoint__c rec
      // we want the trigger to fire here so it will create the next touchpoint.
      DmlHelper.performDML(updateTps, DmlHelper.DML_UPDATE, 'SLAHelperBatch', 'handleTouchpoints', 'Updating Touchpoints', false);
   } // handleExpiredTPs
    
   // called from SLAHelperBatch
   public static void handleTouchpoints(Cadence_Touchpoint__c[] recs) {
      Cadence_Assignment_Record__c[] updateCars = new Cadence_Assignment_Record__c[]{};
      Cadence_Touchpoint__c[] updateTps = new Cadence_Touchpoint__c[]{};
      for (Cadence_Touchpoint__c rec : recs) {
         rec.Close_Date__c = Date.today();
         rec.CloseDateTime__c = Datetime.now();
         rec.Status__c = 'Closed - Expired';
         updateTps.add(rec);
         Cadence_Assignment_Record__c car = rec.CarRecord__r;
         if (car != null) {
            car.Closed__c = true;
            car.Close_Date__c = Date.today();
            car.CloseReason__c = 'Touchpoint Expired';
            car.Rep_Closed__c = false;
            car.Status__c = 'Closed';
            String notes = 'Reached the Expiration Date - Expired!';
            StringHelper.addNotesToField(car, 'Activity_Log__c', WorkQueueController.ACTIVITY_LOG_SIZE, notes, true);
            updateCars.add(car);
         }
 
      } // for (Cadence_Touchpoint__c rec
      //CadenceHelper.SKIP_TRIGGERS=true;
      DmlHelper.performDML(updateTps, DmlHelper.DML_UPDATE, 'SLAHelperBatch', 'handleTouchpoints', 'Updating Touchpoints', false);
      DmlHelper.performDML(updateCars, DmlHelper.DML_UPDATE, 'SLAHelperBatch', 'handleTouchpoints', 'Updating CARS', false);
      ErrorLog.checkSave();
      //CadenceHelper.SKIP_TRIGGERS=false;
   } // handleTouchpoints
   
   public static void sendChatterNotification(Id[] carIds) {     
       Cadence_Assignment_Record__c[] cars = [Select Id, AccountId__c, Name,ownerId,Owner.Name, Secondary_User__c,LatestTouchpoint__c,Secondary_User__r.Name,AccountId__r.Name, Cadence__r.Name,CloseReason__c,LatestTouchpoint__r.ownerId, LatestTouchpoint__r.Status__c                                        
                                               From Cadence_Assignment_Record__c
                                              Where Id in :carIds ];
       
       String textMessage ='';
       List<ID> mentionIds = new List<ID>();
       for(Cadence_Assignment_Record__c carRec :cars){
           mentionIds = new List<ID>();
           if(carRec.Secondary_User__c == carRec.LatestTouchpoint__r.ownerId){           
               textMessage =' Your partner, '+carRec.Secondary_User__r.Name +' has removed '+carRec.AccountId__r.Name +' from the touchpoint cadence '+ carRec.Cadence__r.Name +' with a closed reason of '+ carRec.CloseReason__c +' . Please navigate to '+URL.getOrgDomainURL().toExternalForm() +'/'+carRec.AccountId__c + ' and take appropriate action.';
               mentionIds.add(carRec.ownerId);
               ChatterMentionPost.createChatterMentionPost(carRec.Id,mentionIds,new String[]{textMessage},true,true);
           }
       }
       
   }
   
} // class CadenceHelper