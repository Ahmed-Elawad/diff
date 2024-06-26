/*  
 * Helper methods for creating the NSS View of the data
 * 
 * History
 * -------
   08/05/2014 Dan Carmen            Created
   12/10/2014 Dan Carmen            Change field mapped to start date for assets
   11/03/2016 Dan Carmen            Changes to the form to make it more usable
   11/21/2017 Dan Carmen            Fix for if there isn't a lead company associated with a lead.
   12/11/2018 Dan Carmen            Replace qbdialer__Call_Date_Time__c with CallDateTime__c
   12/27/2018 Dan Carmen            Add in changes for qbdialer__Callback_Date_Time__c to move to DialSource
   02/04/2019 Dan Carmen            Add sort order for Activity to make sure we get latest.
   11/14/2019 Dan Carmen            Remove qbdialer references

 */
public with sharing class NSSViewHelper {

   // the maximum number of records to display initially on the form
   public static Integer NUM_TO_DISPLAY=5;

   public NSSViewWrapper[] allRecords = new NSSViewWrapper[]{};
   
   public Integer numRecsToDisplay = NUM_TO_DISPLAY;
   
   public NSSViewWrapper[] displayRecs{
      get {
        NSSViewWrapper[] toDisplay = new NSSViewWrapper[]{};
        if (numRecsToDisplay > allRecords.size()) {
           numRecsToDisplay = allRecords.size();
        }
        for (Integer cnt=0; cnt < numRecsToDisplay; cnt++) {
           toDisplay.add(allRecords[cnt]);
        }
        return toDisplay;
      } // get
   } // displayRecs
   
   // what is the total number of records?
   public Integer nbrRecords{
      get { return (allRecords != null ? allRecords.size() : 0); }
   }
   
   // do we have any records
   public Boolean hasRecords{
      get { return (allRecords != null && !allRecords.isEmpty()); }
   }

   // are there more records to display that aren't currently on the screen.
   public Boolean hasMoreRecords{
      get { return (hasRecords && allRecords.size() > numRecsToDisplay); }
   } // hasMoreRecords
   
   // display more records on the form
   public void displayMore() {
      numRecsToDisplay += NUM_TO_DISPLAY;
   } // displayMore
   

   public static Integer MAX_RECS=20;

   public static Lead primaryLead=null;

   // get the other leads besides the one you came from (attached via the Lead Company)
   public static NSSViewWrapper[] getLeads(Id leadId) {
      NSSViewWrapper[] otherLeads = new NSSViewWrapper[]{};
      if (leadId == null) {
         return otherLeads;
      }
      Id leadCompanyId = null;
      try {
        // find the lead company id so we can select all leads
         Lead selectLead = [Select Id, Lead_Company__c from Lead where Id=:leadId];
         leadCompanyId = selectLead.Lead_Company__c;
      } catch (Exception e) {}
      if (leadCompanyId == null) {
         leadCompanyId = leadId;
      }
      Lead[] leads = [Select Id
                            ,Name
                            ,City
                            ,Company
                            ,Current_Prior_Method__c
                            ,Description
                            ,DoNotCall
                            ,Email
                            ,FirstName
                            ,Frequency__c
                            ,HasOptedOutOfEmail
                            ,LastActivityDate
                            ,LastModifiedDate
                            ,LatestCampaign__c
                            ,LatestCampaign__r.Id
                            ,LatestCampaign__r.LeadSource__c
                            ,LatestCampaign__r.EndDate
                            ,LatestCampaign__r.IsActive
                            ,LatestCampaign__r.Name
                            ,LatestCampaign__r.StartDate
                            ,LatestCampaignDate__c
                            ,LastName
                            ,Lead_Company__c
                            ,LeadGroupId__c
                            ,No_Longer_With_Company__c
                            ,NumberOfEmployees
                            ,Phone
                            ,PostalCode
                            ,Referral_Contact__c
                            ,Referral_Contact__r.Sensitivity_List__c
                            ,Referral_National_Account__c
                            ,Referral_National_Account__r.Sensitivity_List__c
                            ,Salutation
                            ,SignificantLead__c
                            ,State
                            ,Street
                            ,Title
                        From Lead
                       Where No_Longer_With_Company__c = false
                          and (Id = :leadId
                             or Lead_Company__c = :leadCompanyId)
                           order by SignificantLead__c desc, LastModifiedDate desc
                         limit :MAX_RECS];
      for (Lead ld : leads) {
         if (ld.Id == leadId) {
            primaryLead = ld;
         } else {
            NSSViewWrapper viewWrap = new NSSViewWrapper(ld);
            otherLeads.add(viewWrap);
         }
      } // for (Lead ld
         
      return otherLeads;
   } // getLeads
  

   public static NSSViewWrapper[] getCampaigns(Id leadOrContactId, Id acctId) {
      CampaignMember[] campaignMembers = null;
    if (leadOrContactId != null) {
       campaignMembers = CampaignMethods.getCampaignMembers(new Id[]{leadOrContactId},MAX_RECS);
    } else if (acctId != null) {
       campaignMembers = CampaignMethods.getCampaignMembersForAccounts(new Id[]{acctId},MAX_RECS);
    }
    NSSViewWrapper[] campaignWrappers = new NSSViewWrapper[]{};
    if (campaignMembers != null) {
        for (CampaignMember campMember : campaignMembers) {
           campaignWrappers.add(new NSSViewWrapper(campMember));
        }
    } // if (campaignMembers
    return campaignWrappers;
   } // getCampaigns
   
   public static final String MY_ACTIVITY='My Activity';
   public static final String OTHER_ACTIVITY='Other Activity';
      
   public static Map<String,List<NSSViewWrapper>> getActivity(Id[] whoIds, Id[] acctIds, Id runningUserId, Integer numberOfMonths, Integer maxRecords) {
      Map<String,List<NSSViewWrapper>> activityMap = new Map<String,List<NSSViewWrapper>>();

      List<NSSViewWrapper> myActivity = new List<NSSViewWrapper>();
      List<NSSViewWrapper> otherActivity = new List<NSSViewWrapper>();
      
      activityMap.put(MY_ACTIVITY,myActivity);
      activityMap.put(OTHER_ACTIVITY,otherActivity);
      
      Date selectFromDate = Date.today().addMonths(-numberOfMonths);
      if (maxRecords == null) {
         maxRecords = MAX_RECS;
      }

      getTasks(whoIds,acctIds,runningUserId, selectFromDate,maxRecords,myActivity,otherActivity);
      getEvents(whoIds,acctIds,runningUserId, selectFromDate,maxRecords,myActivity,otherActivity);

      myActivity.sort();
      otherActivity.sort();
      
      return activityMap;
   } // getActivity

   // keep track of open callbacks
   public static Task[] callbackTasks = new Task[]{};
   
  
   public static void getTasks(Id[] whoIds, Id[] acctIds, Id runningUserId, Date selectDate, Integer maxRecords
                                 ,List<NSSViewWrapper> myActivity, List<NSSViewWrapper> otherActivity) {
      callbackTasks.clear();
      Task[] tasks = [Select Id
                            ,ActivityDate
                            ,CallDisposition
                            ,CallType
                            ,Description
                            ,IsClosed
                            ,OwnerId
                            ,Owner.Name
                            ,CallDateTime__c
                            ,DS_Denali__DialSource_Action__c
                            ,RecordTypeId
                            ,RecordType.Name
                            ,ReminderDateTime
                            ,Status
                            ,Subject
                            ,Type
                            ,WhoId
                        From Task
                       Where (WhoId in :whoIds or AccountId in :acctIds)
                         and ActivityDate >= :selectDate
                       order by ActivityDate desc
                        limit :maxRecords];
      for (Task tsk : tasks) {
         // clear description on all non-nss activity - this isn't saved, just for display purposes
         if (tsk.DS_Denali__DialSource_Action__c == null && tsk.Type != TaskHelper.CT_CALLBACK && tsk.CallDateTime__c == null) {
            tsk.Description = null;
         }
         if (!tsk.isClosed && tsk.Type == TaskHelper.CT_CALLBACK) {
            // save callbacks separately
            callbackTasks.add(tsk);
         } else if (tsk.OwnerId == runningUserId) {
            myActivity.add(new NSSViewWrapper(tsk));
         } else {
            otherActivity.add(new NSSViewWrapper(tsk));
         }
      } // for (Task tsk
   } // getTasks
   
   public static void getEvents(Id[] whoIds, Id[] acctIds, Id runningUserId, Date selectDate, Integer maxRecords
                                 ,List<NSSViewWrapper> myActivity, List<NSSViewWrapper> otherActivity) {
      Date checkDate = Date.today();
      Event[] evnts = [Select Id
                            ,ActivityDate
                            ,ActivityDateTime
                            ,DurationInMinutes
                            ,OwnerId
                            ,CallDateTime__c
                            ,RecordTypeId
                            ,RecordType.Name
                            ,Subject
                            ,Type
                            ,WhoId
                           // ,Description
                        From Event
                       Where (WhoId in :whoIds or AccountId in :acctIds)
                         and ActivityDate >= :selectDate
                       order by ActivityDate desc
                        limit :maxRecords];
      for (Event evnt : evnts) {
         // clear description on all non-nss activity - this isn't saved, just for display purposes
         //if (evnt.CallDateTime__c == null) {
         //   evnt.Description = null;
         //}
         if (evnt.OwnerId == runningUserId) {
            myActivity.add(new NSSViewWrapper(evnt));
         } else {
            otherActivity.add(new NSSViewWrapper(evnt));
         }
      } // for (Event evnt
   } // getEvents

/*
   public static NSSViewWrapper[] getOpportunities(Id acctId) {
      NSSViewWrapper[] opptys = new NSSViewWrapper[]{};
      if (acctId != null) {
         Opportunity[] allOpps = OpptyMethods.getOpportunities(acctId,NSSViewController.NBR_MONTHS, MAX_RECS);
         for (Opportunity opp : allOpps) {
            opptys.add(new NSSViewWrapper(opp));
         }
      } // if (acctId != null
      
      return opptys;
   } // getOpportunities
*/ 
   // does the account id passed in have any assets?
   public static Boolean hasAssets(Id acctId) {
      return ([select count() from Asset where AccountId = :acctId limit 1] > 0);
   } // hasAssets
   
/*
   public static NSSViewWrapper[] getAssets(Id acctId, Integer maxRecords) {
      NSSViewWrapper[] assets = new NSSViewWrapper[]{};
      if (acctId != null) {
        for (Asset asst : [select Id, Name, Product_Plan_Code__c
                                 ,Start_Date__c
                                 ,UsageEndDate
                                 ,Plan_Cancel_Date__c
                                 ,Plan_Lost_Reason__c
                                 ,Nbr_Participants__c
                                 ,Description
                                 ,Bundle_Code__c
                                 ,Bundle_Description__c
                             From Asset
                            Where AccountId = :acctId
                              //and Plan_Lost_Reason__c = null
                            Order by Name 
                            limit :maxRecords]) {
           assets.add(new NSSViewWrapper(asst));
         } // for (Asset
      } // if (acctId != null
      
      return assets;
   } // getAssets
*/
   public static final String assetQuery = 'select Id, Name, Product_Plan_Code__c'
                                 +',Start_Date__c'
                                 +',UsageEndDate'
                                 +',Plan_Cancel_Date__c'
                                 +',Plan_Lost_Reason__c'
                                 +',Nbr_Participants__c'
                                 +',Description'
                                 +',Bundle_Code__c'
                                 +',Bundle_Description__c'
                             +' From Asset ';
   
   public static Asset[] getAssets(Id acctId, String activeOrInactive) {
      String query = '';
      if (activeOrInactive == NSSViewController.ACTIVE) {
         query = assetQuery + 'where AccountId=:acctId and Plan_Cancel_Date__c=null Order By Name';
      } else if (activeOrInactive == NSSViewController.INACTIVE) {
         query = assetQuery + 'where AccountId=:acctId and Plan_Cancel_Date__c!=null Order By Name';
      }
      
      Asset[] assets = null;
      if (String.IsNotBlank(query)) {
         assets = Database.query(query);
      } else {
         assets = new Asset[]{};
      }
      return assets;
   } // getAssets
   
} // NSSViewHelper