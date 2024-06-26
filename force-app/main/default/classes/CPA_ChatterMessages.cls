/*
 *
 * History
 * --------
 * 12/15/2022  Jidesh               created
 * 03/10/2023  Vinay   APR0147143   Added logic to mutualClientNewTierNotification to send notifiction when
 *                                  Referral Account Tier is updated. Cleaned up the code to split
 *                                  it into different methods and avoid SOQL in for loop.
 * 05/10/2023  Jidesh   SFDC-17885   Added mutualClientMoveDownTierNotification method to fire chatter while moving down the tier
 */

global without sharing class CPA_ChatterMessages {
  public static void mutualClientNewTierNotification( list<Referral_Account__c> newRecsList, Map<Id, Referral_Account__c> oldMap, Boolean isInsert, Boolean isUpdate) {
    Boolean sendChatter = false;
    List<Referral_Account__c> chatterSendAccs = new List<Referral_Account__c>();
    List<Referral_Account__c> ReferralAccountsTierChange = new List<Referral_Account__c>();
    if (newRecsList.size() > 0) {
      for (Referral_Account__c refAcc : newRecsList) {
        if (Test.isRunningTest()) {
          System.debug('Test.isRunningTest');
          sendChatter = true;
          chatterSendAccs.add(refAcc);
          ReferralAccountsTierChange.add(refAcc);
        }
        if (refAcc.MutualClientNextTier__c != null && refAcc.MutualClientNextTier__c == 1 && refAcc.CPA_Program_status__c == 'Enrolled') {
          if (isUpdate && oldMap.get(refAcc.Id) != null && refAcc.MutualClientNextTier__c != oldMap.get(refAcc.Id).MutualClientNextTier__c) {
            sendChatter = true;
            chatterSendAccs.add(refAcc);
          } else if (isInsert) {
            sendChatter = true;
            chatterSendAccs.add(refAcc);
          } else {
            String dml = isInsert ? 'Insert.' : 'Update.';
            System.debug('CPA_ChatterMessages: Doesnt satisy the criteria for ' + dml);
          }
        } else {
          System.debug('CPA_ChatterMessages: Doesnot satisfy the criteria for mutual client new tier notification.');
        }

        if ( refAcc.CPA_Program_Status__c != null &&
          refAcc.CPA_Program_Status__c != 'Invited' &&
          refAcc.CPA_Program_Status__c != 'No Longer In Program' ) {
          if (isUpdate && oldMap.get(refAcc.Id) != null && (oldMap.get(refAcc.Id).MutualClientTier__c == 'Core' &&
            (refAcc.MutualClientTier__c == 'Signature' || refAcc.MutualClientTier__c == 'Elite')) ||
            (oldMap.get(refAcc.Id).MutualClientTier__c == 'Signature' && refAcc.MutualClientTier__c == 'Elite') ||
            ((oldMap.get(refAcc.Id).MutualClientTier__c == '' || oldMap.get(refAcc.Id).MutualClientTier__c == null) && 
            refAcc.MutualClientTier__c == 'Core')
          ) {
            ReferralAccountsTierChange.add(refAcc);
          }
          sendChatter = true;
        }
      }
    }

      Map<Id, Id> ownerAndManagerMap = new Map<Id, Id>();
      List<Id> uersToMentionForTierChange = new List<Id>();
      List<Id> referralAccountOwners = new List<Id>();

      //Get the list of Referral Account Owners
      for (Referral_Account__c ra : [
        SELECT OwnerId
        FROM Referral_Account__c
        WHERE Id IN :newRecsList
      ]) {
        referralAccountOwners.add(ra.OwnerId);
      }

      //For each Referral Account Owner, populate the map with Owner Id and their Manager Id.
      for (User salesRep : [
        SELECT Id, LastName, ManagerId
        FROM User
        WHERE Id IN :referralAccountOwners
      ]) {
        ownerAndManagerMap.put(salesRep.Id, salesRep.ManagerId);
      }

      //Add corresponding Manager Id for each Owner Id to a List.
      for (Referral_Account__c refAcc : ReferralAccountsTierChange) {
        if (refAcc.OwnerId != null) {
          uersToMentionForTierChange.add(refAcc.OwnerId);
          if (ownerAndManagerMap.get(refAcc.OwnerId) != null) {
            uersToMentionForTierChange.add(
              ownerAndManagerMap.get(refAcc.OwnerId)
            );
          }
        }
      } 

    if (sendChatter && chatterSendAccs.size() > 0) {
      sendOneClinetAwayChatter(uersToMentionForTierChange, chatterSendAccs);
    }

    if (sendChatter && ReferralAccountsTierChange.size() > 0) {
      sendTierChangeChatter( uersToMentionForTierChange, ReferralAccountsTierChange);
    }
  }

  /* ----------------------------------------------------------------------------------------
  * Method to send chatter notification when there is only 1 Clinet for next level.
  * ------------------------------------------------------------------------------------------
  * @param userToMentionIdList   List of user Ids to metion on chatter post.
  * @param chatterSendAccs       List of Parent Ids to associate the post.
  * -----------------------------------------------------------------------------------------
  **/
  public static void sendOneClinetAwayChatter( List<Id> userToMentionIdList, List<Referral_Account__c> chatterSendAccs) {
    for (Referral_Account__c refAcc : chatterSendAccs) {
      if (userToMentionIdList.size() > 0) {
        //Append CPA_RA- to differentiate between normal chatters and CPA chatters
        String postText = 'CPA_RA- is 1 mutual current client away from moving up to the next tier in the Paychex Accountant Program. Please reach out to review the benefits and extract a referral. ';
        ChatterMentionPost.createChatterMentionPost(
          refAcc.Id,
          userToMentionIdList,
          new List<String>{ postText },
          true,
          true
        );
        ChatterMentionPost.postBatchFeedElements();
      }
    }
  }

  /* ----------------------------------------------------------------------------------------
  * Method to send chatter notification when Account moves up a tier.
  * ------------------------------------------------------------------------------------------
  * @param userToMentionIdList   List of user Ids to metion on chatter post.
  * @param chatterSendAccs       List of Parent Ids to associate the post.
  * -----------------------------------------------------------------------------------------
  **/
  public static void sendTierChangeChatter( List<Id> userToMentionIdList, List<Referral_Account__c> chatterSendAccs) {
    for (Referral_Account__c refAcc : chatterSendAccs) {
      if (userToMentionIdList.size() > 0) {
        //Append CPA_RA- to differentiate between normal chatters and CPA chatters
        String postText = 'CPA_RA- has reached the next tier in the Paychex Accountant Program, Congratulations! Please reach out to review the benefits and extract a referral.';
        ChatterMentionPost.createChatterMentionPost(
          refAcc.Id,
          userToMentionIdList,
          new List<String>{ postText },
          true,
          true
        );
        ChatterMentionPost.postBatchFeedElements();
      }
    }
  }
   
    /* ----------------------------------------------------------------------------------------
  * Method to send chatter notification when Account moves down a tier.
  * ------------------------------------------------------------------------------------------
  * @param userToMentionIdList   List of user Ids to metion on chatter post.
  * @param chatterSendAccs       List of Parent Ids to associate the post.
  * -----------------------------------------------------------------------------------------
  **/
  public static void mutualClientMoveDownTierNotification(list<Referral_Account__c> newRecsList) {
        System.debug('CPA_ChatterMessages: mutualClientMoveDownTierNotification');
        Boolean sendChatter = false;
        List<Referral_Account__c> chatterSendAccs = new List<Referral_Account__c>();
        Referral_Account__c[] updateRefAccts = new Referral_Account__c[]{};
            if(newRecsList.size()>0){
                for(Referral_Account__c refAcc: newRecsList){
                    chatterSendAccs.add(refAcc);
                    updateRefAccts.add(refAcc);
                    sendChatter = true;
                }
            }
        
        if(sendChatter && chatterSendAccs.size()>0){
            List<Id> accOwners = new List<Id>();
            List<User> salesReps = new List<User>();
            for(Referral_Account__c refAcc: chatterSendAccs ){
                if(refAcc.OwnerId != null){
                    accOwners.add(refAcc.OwnerId);
                }
            }
            if(accOwners.size()>0){
                salesReps = [SELECT FirstName,Full_Name__c,Id,LastName, ManagerId FROM User WHERE Id IN: accOwners]; 
            }
            if(salesReps.size()>0){
                for(Referral_Account__c refAcc: chatterSendAccs ){
                    List<Id> userToMentionIdList = new List<Id>();
                    for(User sRep: salesReps ){
                        if(sRep.Id == refAcc.OwnerId){
                            userToMentionIdList.add(sRep.Id);
                        }
                        if(sRep.ManagerId != null){
                            userToMentionIdList.add(sRep.ManagerId);
                        }
                    }
                    if(userToMentionIdList.size()>0)
                    {
                        System.debug('CPA_ChatterMessages: Users exist to be mentioned.');
                        System.debug('CPA_ChatterMessages: Building the Chatter.');
                        //Append CPA_RA- to differentiate between normal chatters and CPA chatters
                        String postText = 'CPA_RA- has fallen below the required mutual current clients to maintain their tier at the conclusion of the evaluation year. Please reach out to review the benefits of their tier, that would change on 5/26 and extract a referral.';
                        ChatterMentionPost.createChatterMentionPost(refAcc.Id, userToMentionIdList, new String[]{postText}, true,true);
                        ChatterMentionPost.postBatchFeedElements();
                    }
                }
            }
        }
        System.debug('updateRefAccts:'+updateRefAccts);
        if (!updateRefAccts.isEmpty()) {
            ReferralObjectsSync.SKIP_SYNC = true;
            DmlHelper.performDML2(updateRefAccts, DmlHelper.DML_UPDATE, 'CPA_ChatterMessages', 'mutualClientMoveDownTierNotification', 'update referral accounts', false);
            ReferralObjectsSync.SKIP_SYNC = false;
        }
    }  
}