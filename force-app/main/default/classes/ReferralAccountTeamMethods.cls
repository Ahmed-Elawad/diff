/** Methods for RAT


 * History
 * -------
   04/27/2020 Jake Hinds       Created
   05/26/2020 Jake Hinds       Adding Method for duplicate check
   10/09/2020 Jake Hinds       Adding without sharing per PMD
   12/29/2021 Dan Carmen       Moved trigger code to main class

*/
public without sharing class ReferralAccountTeamMethods {
    
   public static void handleTrigger(Referral_Account_Team__c[] recs, Map<Id,Referral_Account_Team__c> oldMap, Boolean isBefore, Boolean isAfter, Boolean isDelete) {
      Set<Id> referralAcctsToCheckDedicatedRep = new Set<Id>();
      // duplicates by Role by Referral Account
      Map<Id,Map<String,Referral_Account_Team__c>> allRoleMap = new Map<Id,Map<String,Referral_Account_Team__c>>();
      // duplicates by Rep by Referral Account
      Map<Id,Map<String,Referral_Account_Team__c>> allRepMap = new Map<Id,Map<String,Referral_Account_Team__c>>();
       

      if (!isDelete) {
         for (Referral_Account_Team__c rat : recs) {
            System.debug('rat rep='+rat.Team_Member_Name__c+' role='+rat.Team_Member_Role__c);
            Referral_Account_Team__c oldRat = (oldMap != null ? oldMap.get(rat.Id) : null);
            if (Trigger.IsBefore && Trigger.isInsert) {
               Map<String,Referral_Account_Team__c> roleMap = (allRoleMap.containsKey(rat.Referral_Account__c) ? allRoleMap.get(rat.Referral_Account__c) : new Map<String,Referral_Account_Team__c>());
               Map<String,Referral_Account_Team__c> repMap = (allRepMap.containsKey(rat.Referral_Account__c) ? allRepMap.get(rat.Referral_Account__c) : new Map<String,Referral_Account_Team__c>());
               if (roleMap.containsKey(rat.Team_Member_Role__c) || repMap.containsKey(rat.Team_Member_Name__c)) {
                  // don't add if they're in the insert list more than once
                  rat.addError('A team member with this name or role is in the insert list more than once for this Referral Account');
               } else {
                  roleMap.put(rat.Team_Member_Role__c,rat);
                  repMap.put(rat.Team_Member_Name__c,rat);
                  allRoleMap.put(rat.Referral_Account__c,roleMap);
                  allRepMap.put(rat.Referral_Account__c,repMap);
               }
            }
            if (Trigger.isAfter) {
               if (oldRat == null || oldRat.Team_Member_Name__c != rat.Team_Member_Name__c) {
                  referralAcctsToCheckDedicatedRep.add(rat.Referral_Account__c);
               }
            }//if(Trigger.isAfter 
         }//for(
      } else {
         for (Referral_Account_Team__c rat : (Referral_Account_Team__c[])Trigger.old) {
            referralAcctsToCheckDedicatedRep.add(rat.Referral_Account__c);
         }
      }
      if (!allRoleMap.isEmpty() || !referralAcctsToCheckDedicatedRep.isEmpty()) {
         checkForDuplicates(allRoleMap,allRepMap, referralAcctsToCheckDedicatedRep);
      }
   } // handleTrigger

   public static void checkForDuplicates(Map<Id,Map<String,Referral_Account_Team__c>> allRoleMap, Map<Id,Map<String,Referral_Account_Team__c>> allRepMap, Set<Id> refAcctIds) {
      if (!allRoleMap.isEmpty()) {
         refAcctIds.addAll(allRoleMap.keySet());
      }
      Boolean hasErrors = false;
      Referral_Account__c[] refAccts = [SELECT Id, Name, DedicatedRepChanged__c
                                           ,(SELECT Id,Team_Member_Name__c,Team_Member_Role__c FROM Referral_Account_Teams__r)
                                         from Referral_Account__c WHERE Id in :refAcctIds ];
      Referral_Account__c[] updateAccts = new Referral_Account__c[]{};
      for (Referral_Account__c refAcct : refAccts) {
         Map<String,Referral_Account_Team__c> roleMap = allRoleMap.get(refAcct.Id);
         Map<String,Referral_Account_Team__c> repMap = allRepMap.get(refAcct.Id);
         System.debug('checkForDuplicates refAcct='+refAcct.Name+' acct teams='+refAcct.Referral_Account_Teams__r.size());
         if (roleMap != null) {
            for (Referral_Account_Team__c rat : refAcct.Referral_Account_Teams__r) {
               Referral_Account_Team__c checkRole = roleMap.get(rat.Team_Member_Role__c);
               Referral_Account_Team__c checkRep = repMap.get(rat.Team_Member_Name__c);
               checkRole = (checkRole != null ? checkRole : checkRep);
               if (checkRole != null) {
                  checkRole.addError('A team member with this name or role already exists for this Referral Account');
                  hasErrors=true;
                  break;
               }
            } // for (Referral_Account_Team__c rat

         } // if (roleMap != null
         if (refAcct.DedicatedRepChanged__c == false) {
            refAcct.DedicatedRepChanged__c=true;
            updateAccts.add(refAcct);
         }
      } // for (Referral_Account__c refAcct
      System.debug('checkForDuplicates refAccts='+refAccts.size()+' hasErrors='+hasErrors);
      if (!hasErrors && !updateAccts.isEmpty()) {
         ReferralAccountMethods.SKIP_TRIGGERS=true;
         DmlHelper.performDML2(updateAccts, DmlHelper.DML_Update, 'ReferralAccountTeamMethods', 'checkDedicatedRepChanged', 'Checking Dedicated Rep Changed', true);
      }

    } // checkForDuplicates
    
} // class ReferralAccountTeamMethods