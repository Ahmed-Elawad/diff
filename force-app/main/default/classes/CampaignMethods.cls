/* 
   Methods for the Campaigns.
   
   History
   -------
   06/13/2014 Dan Carmen   	   Created
   01/27/2020 Cindy Freeman    added new method - createCampMemberFromRefCntlr - to create campaign member from referral form real time not in the future 
   01/23/2023 Dan Carmen       Change to InterfaceC, increment API
   12/11/2023 Dan Carmen       Moved trigger logic to CampaignMethods, clear cache on change

 */
public without sharing class CampaignMethods implements TriggerInterfaceC {

   public void handleTrigger(SObject[] p_recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter, Boolean isDelete) {
      System.debug('CampaignMethods.handleTrigger p_recs='+(p_recs != null ? p_recs.size() : -1)+' isBefore='+isBefore+' isAfter='+isAfter+' isDelete='+isDelete+' Trigger.old='+(Trigger.old != null ? Trigger.old.size() : -1));
      SObject[] recs = TriggerMethods.checkRecs('CampaignMethods', p_recs, oldMap, isBefore, isAfter, isDelete, null, null);
      if (recs == null || recs.isEmpty()) {
         System.debug('handleTrigger trigger already ran');
         return;
      }
      SObjectType objType = TriggerMethods.objType;
      System.debug('CampaignMethods.handleTrigger objTypeName='+TriggerMethods.objectTypeName+' recs='+(recs != null ? recs.size() : -1)+' isBefore='+isBefore+' isAfter='+isAfter);

      if (isBefore) {
         if (objType == Contact.sObjectType || objType == Lead.sObjectType) {
            checkRecsBefore(recs,oldMap);
         } else if (objType == Campaign.sObjectType) {
            checkCampaignBefore((Campaign[])recs,(Map<Id,Campaign>)oldMap);
         }
      } else if (isAfter) {
         if (objType == Contact.sObjectType || objType == Lead.sObjectType) {
            checkRecsAfter(recs,oldMap);
         } else if (objType == Campaign.sObjectType) {
            checkCampaignAfter((Campaign[])recs,(Map<Id,Campaign>)oldMap);
         }         
      }
   } // checkAllBeforeTrigger
    
   public static void checkCampaignBefore(Campaign[] recs, Map<Id,Campaign> oldMap) {
      // evaluate if we meet certain criteria
      Campaign[] evaluateParent = new Campaign[]{};
      for (Campaign camp : recs) {
   	     Campaign oldCamp = (oldMap != null ? oldMap.get(camp.id) : null);
   	     if (CampaignMethods.weNeedToEvaluateParent(camp,oldCamp)) {
            evaluateParent.add(camp);
         }
      } // for (Campaign camp
   
      if (!evaluateParent.isEmpty()) {
         CampaignMethods.checkParentCampaign(evaluateParent);
      }

   } // checkCampaignBefore
    
   public static void checkCampaignAfter(Campaign[] recs, Map<Id,Campaign> oldMap) {
      // TODO - this logic will have to change with any additional functionality.
      for (Campaign camp : recs) {
   	     Campaign oldCamp = (oldMap != null ? oldMap.get(camp.id) : null);
         if (camp.Strategic_Account_Partner__c != null && (oldMap == null || (camp.Strategic_Account_Partner__c != oldCamp.Strategic_Account_Partner__c))) {
             CacheManager.removeOrg(TrackRecordEntry.CAMP_CACHE_KEY);
             break;
         }
      } // for (Campaign camp
   } // checkCampaignAfter
   
   public static void checkRecsBefore(SObject[] recs, Map<Id,SObject> oldMap) {
      SObject[] checkCampParents = new SObject[]{};
      for (SObject rec : recs) {
         SObject oldRec = (oldMap != null ? oldMap.get(rec.Id) : null);
         String latestCampaignId = (String)rec.get('LatestCampaign__c');
         String prevLatestCampaignId = (oldRec != null ? (String)oldRec.get('LatestCampaign__c') : null);
         if (latestCampaignId != null && (oldRec == null || latestCampaignId != prevLatestCampaignId)) {
            rec.put('LatestCampaignDate__c',Datetime.now());
            checkCampParents.add(rec);
         }
         if (rec.get('LatestCampaign__c') == null && rec.get('LatestCampaignParent__c') != null) {
            rec.put('LatestCampaignParent__c',null);
         }
      } // for (SObject rec
      if (!checkCampParents.isEmpty()) {
         checkForCampaignParent(checkCampParents, CampaignMethods.CAMPAIGN_FIELD, CampaignMethods.CAMPAIGN_PARENT_FIELD);
      }
   } // checkRecsBefore
    
   public static Integer MAX_SECONDS=120;
   
   public static void checkRecsAfter(SObject[] recs, Map<Id,SObject> oldMap) {
      Map<Id,Id> recCampMap = new Map<Id,Id>();
      for (SObject rec : recs) {
         SObject oldRec = (oldMap != null ? oldMap.get(rec.Id) : null);
         String latestCampaignId = (String)rec.get('LatestCampaign__c');
         String prevLatestCampaignId = (oldRec != null ? (String)oldRec.get('LatestCampaign__c') : null);
         Datetime latestCampaignDate = (Datetime)rec.get('LatestCampaignDate__c');
         // trigger off the latest campaign date too, just in case.
         Integer timeBetween = (latestCampaignDate != null ? Integer.valueOf((Datetime.now().getTime() - latestCampaignDate.getTime())/1000) : -1);
         Boolean timeCheck = (timeBetween >= 0 && timeBetween < MAX_SECONDS);
         
         if ((latestCampaignId != null && (oldRec == null || latestCampaignId != prevLatestCampaignId)) || timeCheck) {
            recCampMap.put(rec.Id,latestCampaignId);
         }
      } // for (SObject rec
      System.debug('checkRecsAfter recs='+recs.size()+' recCampMap='+recCampMap.size());
      if (!recCampMap.isEmpty()) {
         checkToCreateCampaignMembers(recCampMap);
      }
   } // checkRecsAfter

   public static Boolean weNeedToEvaluateParent(Campaign newCamp, Campaign oldCamp) {
      Boolean evaluate=(oldCamp == null);
      if (!evaluate) {
         evaluate = ((newCamp.IsParent__c != oldCamp.IsParent__c)
             || (newCamp.ParentId != oldCamp.ParentId));
      } // if 
      return evaluate;
   } // weNeedToEvaluateParent
   
   /** Look for the parent campaigns of the passed in children.
    */
   public static void checkParentCampaign(List<Campaign> campaigns) {
   	
   	CampaignIdWrapper[] wrappers = new CampaignIdWrapper[]{};
   	
   	// extract all of the campaign ids
   	
   	for (Campaign camp : campaigns) {
   	   if (camp.IsParent__c) {
   	      camp.ParentCampaign__c = null;
   	   } else if (camp.ParentId != null ) {
   	      CampaignIdWrapper wrapper = new CampaignIdWrapper();
   	      wrapper.camp = camp;
   	      wrapper.childId = camp.Id;
   	      wrapper.lastQueryId = camp.ParentId;
   	      wrappers.add(wrapper);
   	   }
   	}
   	
   	if (!wrappers.isEmpty()) {
   	   checkForParent(wrappers);
   	}
   } // checkParentCampaign
   
   public static void checkForParent(CampaignIdWrapper[] wrappers) {
   	Set<Id> queryIds = new Set<Id>();
   	for (CampaignIdWrapper wrapper : wrappers) {
  	      queryIds.add(wrapper.lastQueryId);
   	} // for 
   	
      Campaign[] campaigns = [Select Id, IsParent__c, ParentId
                                    ,Parent.Id,Parent.IsParent__c, Parent.ParentId
                                    ,Parent.Parent.Id,Parent.Parent.IsParent__c, Parent.Parent.ParentId
                                    ,Parent.Parent.Parent.Id,Parent.Parent.Parent.IsParent__c, Parent.Parent.Parent.ParentId
                                    ,Parent.Parent.Parent.Parent.Id,Parent.Parent.Parent.Parent.IsParent__c, Parent.Parent.Parent.Parent.ParentId
                                    ,Parent.Parent.Parent.Parent.Parent.Id,Parent.Parent.Parent.Parent.Parent.IsParent__c, Parent.Parent.Parent.Parent.Parent.ParentId
                                From Campaign
                               Where Id in :queryIds];
      
      CampaignIdWrapper[] notCompleteWrappers = new CampaignIdWrapper[]{};
      for (CampaignIdWrapper wrapper : wrappers) {
         for (Campaign camp : campaigns) {
            if (wrapper.lastQueryId == camp.Id) {
            	checkForParent(wrapper,camp);
            	// Based on current salesforce limits will not need this recursive call. However if the limits change the code
            	// is still here "just in case"
               //if (!checkForParent(wrapper,camp)) {
               //   notCompleteWrappers.add(wrapper);
               //}
            } // if (wrapper.lastQueryId
         } // for (Campaign camp
      } // for (CampaignIdWrapper
      
      //if (!notCompleteWrappers.isEmpty()) {
      //   checkForParent(notCompleteWrappers);
      //}
   } // checkForParent
   
   public static Boolean checkForParent(CampaignIdWrapper wrapper, Campaign camp) {
   	if (!useForParent(camp, wrapper) 
   	    && !useForParent(camp.Parent, wrapper)
          && !useForParent(camp.Parent.Parent, wrapper)
          && !useForParent(camp.Parent.Parent.Parent, wrapper)
          && !useForParent(camp.Parent.Parent.Parent.Parent, wrapper)
          && !useForParent(camp.Parent.Parent.Parent.Parent.Parent, wrapper)) {
         // we cannot reach this statement under the current salesforce setup
         //wrapper.lastQueryId = camp.Parent.Parent.Parent.Parent.Parent.ParentId;
      }

      return wrapper.parentFound;
   } // checkForParent
   
   public static Boolean useForParent(Campaign checkCampaign, CampaignIdWrapper wrapper) {
      if (checkCampaign.IsParent__c || checkCampaign.ParentId == null) {
         wrapper.camp.ParentCampaign__c = checkCampaign.Id;
         wrapper.parentFound = true;
         return true;
      }
      return false;
   } // useForParent
   
   public class CampaignIdWrapper {
      public Id childId = null;
      public Id lastQueryId = null;
      public Campaign camp = null;
      
      public Boolean parentFound = false;
   } // CampaignIdWrapper
   
   
   public static final String CAMPAIGN_FIELD='LatestCampaign__c';
   public static final String CAMPAIGN_PARENT_FIELD='LatestCampaignParent__c';
   
   public static void checkForCampaignParent(SObject[] recs, String campaignFieldName, String parentCampaignFieldName) {
      // the campaign ids to retrieve
      Set<Id> campaignIdSet = new Set<Id>();
      try {
         for (SObject rec : recs) {
      	
            Id campaignId = (Id)rec.get(campaignFieldName);
            if (campaignId != null) {
               campaignIdSet.add(campaignId);
            } else {
               // clear out the parent field name
               rec.put(parentCampaignFieldName,null);
            }
         } // for (Lead ld
      
      } catch (Exception e) {
         throw new CampaignException('Error updating Campaign Fields (step 1). One of the following might not be valid: '+campaignFieldName+', '+parentCampaignFieldName);
      }
      if (campaignIdSet.isEmpty()) {
         return;
      }
      Map<Id,Campaign> campaignMap = new Map<Id,Campaign>([Select Id, Name, LeadSource__c, ParentId, IsParent__c, ParentCampaign__c from Campaign where Id in :campaignIdSet]);
      System.debug('checkForCampaignParent nbrIds='+campaignIdSet.size()+' nbr in campaignMap='+campaignMap.size());
      try {
         for (SObject rec : recs) {
            Id campaignId = (Id)rec.get(campaignFieldName);
            if (campaignId != null) {
               Campaign camp = campaignMap.get(campaignId);
               System.debug('checkForCampaignParent trying to set parent camp='+camp);
               if (camp != null) {
                  Id parentCampId = (camp.ParentCampaign__c != null ? camp.ParentCampaign__c : camp.Id); //(camp.IsParent__c ? camp.Id : null));
                  System.debug('checkForCampaignParent parentCampaignFieldName='+parentCampaignFieldName+' parentCampId='+parentCampId);
                  rec.put(parentCampaignFieldName, parentCampId);
                  if (String.isNotBlank(camp.LeadSource__c) && rec.get('LeadSource') == null) {
                     rec.put('LeadSource',camp.LeadSource__c);
                  }
               }
            } // if (campaignId != null
         } // for (Lead ld 
      } catch (Exception e) {
         throw new CampaignException('Error updating Campaign Fields (step 2). One of the following might not be valid: '+campaignFieldName+', '+parentCampaignFieldName);
      }
      
   } // checkForLeadCampaignParent
   
   public static void addToCampaignMap(Id memberId, Id campaignId, Map<Id,Set<Id>> campaignIdMemberIdMap) {
      if (memberId != null && campaignId != null) {
         Set<Id> memberIds = campaignIdMemberIdMap.get(campaignId);
         if (memberIds == null) {
            memberIds = new Set<Id>();
            campaignIdMemberIdMap.put(campaignId,memberIds);
         }
         memberIds.add(memberId);
      }
   } // addToCampaignMap
   
   public class CampaignException extends Exception {}
   
   public static void checkToCreateCampaignMembers(Map<Id,Id> campaignMemberMap) {
   	if (!campaignMemberMap.isEmpty()) {
         if (System.isFuture() || System.isBatch() || System.isQueueable() ||Test.isRunningTest()) {
            createCampMembers(campaignMemberMap);
         } else {
            createCampMembersFuture(campaignMemberMap);
         }
   	} // if 
   } // checkToCreateCampaignMembers
   
   // only called from ReferralController when campaign is populated on form, we dont want it to run in the future
   public static void createCampMemberFromRefCntlr(Map<Id,Id> campaignMemberMap) {
     if (!campaignMemberMap.isEmpty()) {
        createCampMembers(campaignMemberMap);
     }      
   } // createCampMemberFromRef
    
   @future
   private static void createCampMembersFuture(Map<Id,Id> campaignMemberMap) {
      createCampMembers(campaignMemberMap);
   } // createCampMembersFuture
   
   private static void createCampMembers(Map<Id,Id> campaignMemberMap) {
   	// pull out all of the member ids to see if they already exist
   	List<Id> memberIdList = new List<Id>();
   	// create a map by campaign id
   	Map<Id,Set<Id>> campaignIdMemberIdMap = new Map<Id,Set<Id>>();
   	
   	String campaignMemberField = null;
   	
   	for (Id memberId : campaignMemberMap.keySet()) {
   	   if (String.IsBlank(campaignMemberField)) {
            String objectPrefix = ((String)memberId).left(3);
            campaignMemberField = (objectPrefix == ObjectHelper.PREFIX_CONTACT ? 'ContactId' : 'LeadId');
   	   }
   	   memberIdList.add(memberId);
   	   addToCampaignMap(memberId, campaignMemberMap.get(memberId), campaignIdMemberIdMap);
   	} // for (Id memberId
   	
   	// select the campaigns to make sure they exist
   	Map<Id,Campaign> campaignMap = new Map<Id,Campaign>([Select Id, Name, IsActive, StartDate, EndDate
   	                                                           ,(Select Id, CampaignId, ContactId, LeadId
   	                                                               From CampaignMembers
   	                                                              Where ContactId in :memberIdList
   	                                                                 or LeadId in :memberIdList)
   	                                                       From Campaign
   	                                                      Where Id in :campaignIdMemberIdMap.keySet()]);
   	                                                      
      CampaignMember[] campMembersToInsert = new CampaignMember[]{};

      for (Campaign camp : campaignMap.values()) {
         Set<Id> memberIdSet = campaignIdMemberIdMap.get(camp.Id);
         if (camp.CampaignMembers != null && !camp.CampaignMembers.isEmpty()) {
            // remove any existing campaign members from the set
            for (CampaignMember campMember : camp.CampaignMembers) {
               Id memberId = (Id)campMember.get(campaignMemberField);
               if (memberId != null) {
                  memberIdSet.remove(memberId);
               }
            }
         } // if (camp.CampaignMembers
         
         createCampMembers(camp.Id, campaignMemberField, memberIdSet, campMembersToInsert);
      } // for (Campaign camp
      
      if (!campMembersToInsert.isEmpty()) {
         Database.insert(campMembersToInsert,false);
      }
   } // createCampMembers
   
   public static void createCampMembers(Id campaignId, String campaignMemberField, Set<Id> memberIdSet, CampaignMember[] campMembersToInsert) {
      if (!memberIdSet.isEmpty()) {
         for (Id memberId : memberIdSet) {
            CampaignMember newCampMember = new CampaignMember(CampaignId=campaignId);
            newCampMember.put(campaignMemberField,memberId);
            campMembersToInsert.add(newCampMember);
         }
      } // if (!memberSet.isEmpty
   } // createCampMembers
   
   public static CampaignMember[] getCampaignMembersForAccounts(Id[] accountIds, Integer maxRecords) {
      Map<Id,Contact> ctctMap = new Map<Id,Contact>([Select Id from Contact 
                                                      where AccountId in :accountIds]);
      if (!ctctMap.isEmpty()) {
         Id[] contactids = new Id[]{};
         contactIds.addAll(ctctMap.keySet());
         return getCampaignMembers(contactIds, maxRecords);
      }
      // return an empty list if no contacts found.
      return null;
   } // getCampaignMembersForAccounts
    
   public static Integer MAX_RECS=10;
   
   public static CampaignMember[] getCampaignMembers(Id[] checkIds, Integer maxRecords) {
   	if (maxRecords == null) {
   	   maxRecords = MAX_RECS;
   	}
   	CampaignMember[] campMembers = new CampaignMember[]{};
   	if (checkIds != null && !checkIds.isEmpty()) {
   	   campMembers = [Select Id
   	                                      ,LastModifiedDate
   	                                      ,Status
   	                                      ,CampaignId
   	                                      ,Campaign.Id
   	                                      ,Campaign.Name
   	                                      ,Campaign.EndDate
   	                                      ,Campaign.StartDate
   	                                      ,Campaign.IsActive
   	                                      ,Campaign.ParentCampaign__c
   	                                      ,Campaign.IsParent__c
   	                                      ,Campaign.Product__c
   	                                  From CampaignMember
   	                                 Where Campaign.IsActive=true
   	                                   and (LeadId in :checkIds 
   	                                        or ContactId in :checkIds)
   	                               order by LastModifiedDate desc
   	                                limit :maxRecords
   	                                 ];
   	} // if (checkIds != null
      return campMembers;
   } // getCampaignMembers
   

} // class CampaignMethods