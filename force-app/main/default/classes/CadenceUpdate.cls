/* 
 * Class used to create Cadence touchpoints and update the Cadance Assignment Records
 *
 * History
 * -------
    05/15/2019  Jermaine Stukes     Created
    08/05/2019  Dan Carmen          Changed to without sharing to see if it gets past an error
    09/25/2019  Jermaine Stukes     Update validateCarList and getCadTypesList
    10/14/2019  Jermaine Stukes     Add closeCar
    11/18/2019  Jake Hinds          Add call to queueable to evaluate ownership
    01/27/2020  Jermaine Stukes     Updated CreateNextTouchpoint
    01/28/2020  Dan Carmen          Add Wait Minutes 
    01/30/2020  Jermaine Stukes     Add updateCarRecords, updateCars, getCadenceTypes
    01/30/2020  Jermaine Stukes     Removed updateParentInfo, validateCarList,getCadTypesList, updateCarLookups
    02/04/2020  Jermaine Stukes     Update for Send to NSS
    02/10/2020  Jake Hinds          Small fix for setting owner
    03/23/2020  Dan Carmen          Checks around CAR and TP Name field
    04/06/2020  Dan Carmen          Added close reasons for exceptions
    08/07/2020  Dan Carmen          Fix for the expiration dates calculating properly.
    09/20/2020  Jermaine Stukes     Commented out Started__c logic
    11/04/2020  Jermaine Stukes     Updated to resolve extra step issue
    11/27/2020  Brandon Vidro       Add check to match Cadence Owner to Owner
    04/06/2020  Jermaine Stukes     Added checkEmailEligibility and verifyEligibleContact methods
    04/23/2021  Dan Carmen          Add code for Referral_Account__c
    06/20/2021 Pujitha Madamanchi   APR0119247: Set SLA Deadline to null for cadence
    08/31/2021  Dan Carmen          Break out EMAIL_AUTOSKIP_REASON
    11/16/2021 Pujitha Madamanchi   APR0119247: Add overwritten code 
    11/17/2021 Dan Carmen           Add debugging
    01/20/2022 Pujitha Madamanchi   APR0130779 Reject/Recycle Lead/Contact on CAR instead of SignificantLead/SignificantContact0    
    05/20/2022 Susmitha Somavarapu  Added so that users are able to have more than one CAR open for different Opportunity Types
    06/01/2022 Pujitha Madamanchi   APR0130779 Remove SignificantLead/SignificantContact
    06/20/2022 Dan Carmen           Update to Send to Partner routing
    02/10/2023 Pujitha Madamanchi   APR0131508 Recycle Lead/Contact when last step is closed with reason cadence completed
    03/06/2023 Pujitha Madamanchi   APR0148879 - Stamp Latest Campaign on Car record upon creation
    04/25/2023 Pujitha Madamanchi   APR0150818 - Update Lead/Contact Recycle reason when reason is Touchpoint Expired.
    07/20/2023 Jaipal               APR0148811 - Added new method(verifyEligibleContactsForText) to accomodate the auto skip the text reason to log same like Email error reason
    09/26/2023 Pujitha Madamanchi   Close TP steps when DNC is set on Lead; Populate override fields while creating new touchpoint
    12/08/2023 Pujitha Madamanchi  Populate Override cars on car on creation from Cadence
    01/10/2024 Pujitha Madamanchi  Add error logs when lead is set to Reject/Recycle
    01/17/2024 Reetesh Pandey    Update for Secondary User Chatter Notification
    03/05/2024 Jaipal               Fix for INC3640328 | Touchpoint step is not executing in some scenarios, added text step differently
    04/01/2024 Jaipal APR0158122 Added extra condition(Cadence Owner = Current SMS Owner) in checkTpText method to skip the text step for the user
 */
public without sharing class CadenceUpdate {
   
   public static String STATUS_INCOMPLETE='Incomplete';
   public static String[] CADENCE_COMPLETED=Label.CadenceUpdate_CloseReason.split(',');
   public static String MQL_STAGE='MQL';
   public static String TAL_STAGE='TAL';

   public static Id[] evaluateCarTouchpoints = new Id[]{};
   public static Boolean queueableRan = false;

   public static final Integer TARGET_LIST_SIZE = Cadence_Assignment_Record__c.TargetList__c.getDescribe().getLength();
   
   public static ErrorLog__c errLog = new ErrorLog__c();
   public static String logDetail;
   
   public static void checkCarsBefore(Cadence_Assignment_Record__c[] cars, Map<Id,Cadence_Assignment_Record__c> oldMap) {
      System.debug('checkCarsBefore CadenceHelper.SKIP_TRIGGERS='+CadenceHelper.SKIP_TRIGGERS);
      if (CadenceHelper.SKIP_TRIGGERS) {
         return;
      }
      evaluateCarTouchpoints.clear();
      Cadence_Assignment_Record__c[] carList = new Cadence_Assignment_Record__c[]{};
      Cadence_Assignment_Record__c[] carCloseList = new Cadence_Assignment_Record__c[]{};
      // once the cadence lookup is set, perform these checks on the records
      Cadence_Assignment_Record__c[] checkCadenceSet = new Cadence_Assignment_Record__c[]{};
      
      for (Cadence_Assignment_Record__c carRecord : cars) {  
         Cadence_Assignment_Record__c oldRec = (oldMap != null ? oldMap.get(carRecord.Id) : null);
         if (carRecord.Cadence__c != null && (oldRec == null || carRecord.Cadence__c != oldRec.Cadence__c)) {
            checkCadenceSet.add(carRecord);
         }
         if(Trigger.isInsert){
            carList.add(carRecord);
        } else if(Trigger.isUpdate){
            if((carRecord.Status__c == 'Closed' && (carRecord.Status__c != oldRec.Status__c)) || (carRecord.Closed__c && (carRecord.Closed__c != oldRec.Closed__c))){
                System.debug('CadenceUpdate-checkCarsBefore Car Closed List Updated');
                carCloseList.add(carRecord);
            }
            /*if (carRecord.Rep_Closed__c && !carRecord.Started__c) {
               // if the rep closed it then it should always be started
               carRecord.Started__c=true;
            }*/
            if (carRecord.EvaluateTouchpoints__c) {
               evaluateCarTouchpoints.add(carRecord.Id);
               carRecord.EvaluateTouchpoints__c = false;
            }
            if (carRecord.OwnerId != null && String.valueOf(carRecord.OwnerId).startsWith('005') && carRecord.Cadence_Owner__c != carRecord.OwnerId && carRecord.OwnerId != oldRec.OwnerId) {
               carRecord.Cadence_Owner__c = carRecord.OwnerId;
            }
         }
      } // for (Cadence_Assignment_Record__c carRecord
      if(!carList.isEmpty()){
         updateCarRecords(carList);
      }
      if (!checkCadenceSet.isEmpty()) {
         // this needs to be called after the lookups are populated.
         checkWhenCadenceSet(checkCadenceSet);
      }
      if(!carCloseList.isEmpty()){
         closeCars(carCloseList);
      }
   } // checkCarsBefore
   
   public static void checkCarsAfter(Cadence_Assignment_Record__c[] cars, Map<Id,Cadence_Assignment_Record__c> oldMap) {
      System.debug('checkCarsAfter CadenceHelper.SKIP_TRIGGERS='+CadenceHelper.SKIP_TRIGGERS+' cars='+cars.size());
      if (CadenceHelper.SKIP_TRIGGERS) {
         return;
      }
      List <Id>carIdList = new List<Id>();
      //Cadence_Assignment_Record__c[] carsForOwnershipQueueable = new Cadence_Assignment_Record__c[]{};
      Id[] carIdsForOwnershipQueueable = new Id[]{};
      List<String> parentObjectList = new List<String>();
      List<String> carCloseList = new List<String>();
      Id[] checkMarketingStage = new Id[]{};
      Cadence_Assignment_Record__c[] checkStage = new Cadence_Assignment_Record__c[]{};
      //Reetesh
      Id[] sendChatterforSecondaryUser = new Id[]{};    

      for(Cadence_Assignment_Record__c carRecord : cars){
         Cadence_Assignment_Record__c oldRec = (oldMap != null ? oldMap.get(carRecord.Id) : null);
         String parentObjectId = (carRecord.AccountId__c != null ? carRecord.AccountId__c : (carRecord.ReferralAccount__c != null ? carRecord.ReferralAccount__c : carRecord.LeadId__c));
         if (carRecord.Touchpoint_Created_Successfully__c) {
            if (carRecord.Cadence__c != null && (oldRec == null || carRecord.Cadence__c != oldRec.Cadence__c)) {
               carIdList.add(carRecord.Id);
               parentObjectList.add(parentObjectId);
            }
            if(Trigger.isUpdate){
                system.debug('CadenceUpdate checkCarsAfter carRecord.Cadence__c: '+carRecord.Cadence__c + 'oldRec.Cadence__c:'+oldRec.Cadence__c);
                logDetail+= '\nTrigger isUpdate: Status='+carRecord.Status__c+ ' old Status'+oldRec.Status__c + ' Car Close Reason='+carRecord.CloseReason__c;
                if(carRecord.Status__c != oldRec.Status__c){
                    parentObjectList.add(parentObjectId);
                    if(carRecord.Status__c == 'Closed'){
                        System.debug('CadenceUpdate-checkCarsAfter Car Closed List Updated');
                        carCloseList.add(carRecord.Id);
                        if (String.isNotBlank(carRecord.CloseReason__c)){
                           checkMarketingStage.add(carRecord.Id);
                           logDetail+= '\ncheckMarketingStage size= '+checkMarketingStage.size();
                        }
                        //Reetesh
                        if(carRecord.LatestTouchpoint__c != null){
                        sendChatterforSecondaryUser.add(carRecord.Id);
                        }
                    }
                } // if(carRecord.Status__c != oldRec.Status__c
            }
         } // if (carRecord.Touchpoint_Created_Successfully__c
        
         if(carRecord.SendToPartnerStatus__c == CAROwnershipQueueable.STATUS_PENDING) {
            system.debug('CadenceUpdate checkCarsAfter carRecord.Id: '+carRecord.Id);
            carIdsForOwnershipQueueable.add(carRecord.Id);
        }
        
          
     } // for(Cadence_Assignment_Record__c carRecord
     
     System.debug('checkCarsAfter carIdList='+carIdList.size()+' carIdsForOwnershipQueueable='+carIdsForOwnershipQueueable.size()+' carCloseList='+carCloseList.size()+' parentObjectList='+parentObjectList.size()+' evaluateCarTouchpoints='+evaluateCarTouchpoints.size());
     if(!carIdList.isEmpty()){
           CadenceUpdate.createTouchPoint(carIdList);
     }
     if(!carIdsForOwnershipQueueable.isEmpty() && !queueableRan){
            CAROwnershipQueueable carOQ = new CAROwnershipQueueable(carIdsForOwnershipQueueable);
            system.enqueueJob(carOQ);
            queueableRan = true;
     }
        
     if(!carCloseList.isEmpty()){
        CadenceUpdate.closeTouchpoints(carCloseList);
     }
     if (!checkMarketingStage.isEmpty()) {
        checkForRejectRecycle(checkMarketingStage);
     }
     if (!evaluateCarTouchpoints.isEmpty()) {
        CadenceHelper.checkCarTouchpoints(evaluateCarTouchpoints);
     }

     System.debug('checkCarsAfter parentObjectList='+parentObjectList.size());
     if(!parentObjectList.isEmpty()){
        //Run Queuable job to update Parent Object
        CadenceQueueable cadQueue = new CadenceQueueable(parentObjectList);
        CadenceQueueable.launchQueueable(cadQueue);
     }
     //Reetesh
     if(!sendChatterforSecondaryUser.isEmpty()) {       
        CadenceHelper.sendChatterNotification(sendChatterforSecondaryUser);
     }
   } // checkCarsAfter
    
    public static void createTouchPoint(List<Id> carIdList){
        system.debug('CadenceUpdate checkCarsAfter carRecord.Id: CREATE TOUCHPOINT CALLED');
        Cadence_Touchpoint__c[] newTouchpointList = new Cadence_Touchpoint__c[]{};
        Id[] cadenceCloseList = new Id[]{};
        List<Cadence_Assignment_Record__c> newTPList = new List<Cadence_Assignment_Record__c>();
        List<Cadence_Touchpoint__c> nextTouchPointList = new List<Cadence_Touchpoint__c>();
        Map<Id,Cadence_Assignment_Record__c> carMap = new  Map<Id,Cadence_Assignment_Record__c>();
        List<Id> cadenceIdList = new List<Id>();
        // reselect the cars and get their latest touchpoint
        Cadence_Assignment_Record__c[] carList = [Select Id, Name, OwnerId, TimeZoneAbbrev__c, Cadence__c, Cadence_Owner__c, Cadence_Owner__r.Id, Cadence_Owner__r.TimeZoneSidKey
                                                      ,Status__c, AccountId__c,LeadId__c,OpportunityId__c,ContactId__c,CadenceObject__c,ReferralAccount__c
                                                      ,Start_Date__c, Override_Call__c, Override_Email__c, Secondary_User__c
                                                      ,(Select Id, AccountId__c, Cadence__c, Cadence_Touchpoint_Step__c
                                                              ,Cadence_Touchpoint_Step__r.Step_Number__c
                                                              ,CarRecord__c, CloseDateTime__c, Close_Date__c
                                                              ,ContactId__c, LeadId__c, Name, OpportunityId__c, OwnerId
                                                              ,ReferralAccount__c, ContactId__r.Current_SMS_Owner__c
                                                              ,Status__c, StepCounter__c, Step_Number__c, TouchpointObject__c ,Cadence_Touchpoint_Step__r.Assigned_Team__c
                                                          from Cadence_Touchpoints__r Order By StepCounter__c desc nulls last, CreatedDate desc limit 1) 
                                                      from Cadence_Assignment_Record__c where id in :carIdList];

        Cadence_Assignment_Record__c[] carsToCheckTp = new Cadence_Assignment_Record__c[]{};

        // get the cadence ids. see if
        for (Cadence_Assignment_Record__c carRec : carList) {
           // if the car is open and there are no touchpoint or the latest touchpoint is closed
           if (carRec.Status__c != 'Closed' && (carRec.Cadence_Touchpoints__r.isEmpty() 
                    || carRec.Cadence_Touchpoints__r[0].Close_Date__c != null)) {
              cadenceIdList.add(carRec.Cadence__c);
              carsToCheckTp.add(carRec);
           }
        } // for(Cadence_Assignment_Record__c carRec : carList
        Map<Id,Cadence__c> cadenceMap = (cadenceIdList.isEmpty() ? new Map<Id,Cadence__c>()
                                         : new Map<Id,Cadence__c>([select Id, Name ,Sales_Org__c ,Acct_Owner_Field__c, Cadence_Type__c, TargetType__c, OngoingCadence__c
                                                                         ,ReferralSourceBusinessType2__c
                                                                         ,ReferralType__c
                                                                         ,CPARotation__c,NotAllow_Secondary_user_to_close_Cadence__c
                                                                   ,(Select Id, Name, CadenceId__c, CadenceId__r.Sales_Org__c, CadenceId__r.Acct_Owner_Field__c
                                                                      ,EmailExtraTextAllowed__c, EmailExtraTextDefault__c
                                                                     , Step_Number__c, Touchpoint_Type__c, Wait_Days__c, Wait_Hours__c, WaitMinutes__c
                                                                     , WeekStart__c, WeekEnd__c,Assigned_Team__c
                                                                     from Cadence_Steps__r order by Step_Number__c)
                                                                   from Cadence__c Where Id in :cadenceIdList]));
        
        for (Cadence_Assignment_Record__c carRec : carsToCheckTp) {
           if (createTouchpoint(carRec, cadenceMap.get(carRec.Cadence__c), newTouchpointList) == false) {
              cadenceCloseList.add(carRec.Id);
           }
        } // for (Cadence_Assignment_Record__c carRec
        System.debug('newTouchpointList='+newTouchpointList.size());
        if(!newTouchpointList.isEmpty()){
            DmlHelper.performDML(newTouchpointList, DmlHelper.DML_INSERT, 'CadenceUpdate', 'createTouchPoint', 'Inserting new touchpoint records', true);
            CadenceHelper.updateCarsForTouchpoints(newTouchpointList);
        }
        if(!cadenceCloseList.isEmpty()){
            system.debug('CadenceUpdate checkCarsAfter carRecord.Id: UPDATE CAR RECS CALLED');
            updateCarRecs(cadenceCloseList, true);
        }
    } // createTouchPoint
    
   public class Week {
      public Date startDate;
      public Date endDate;
      public Boolean dateInWeek(Date dateToCheck) {
         return (dateToCheck != null && dateToCheck >= startDate && dateToCheck <= endDate);
      } // dateInWeek
   } // class Week
    
   public class Month {
      public Date startDate;
      public Date endDate;
      public Week[] weeks = new Week[]{};
      public Boolean dateInMonth(Date dateToCheck) {
          return (dateToCheck != null && dateToCheck >= startDate && dateToCheck <= endDate);
      } // dateInMonth
   } // class Month
    
   // this is primarily for testing purposes so we can control the results returned.
   public static Date CUR_DATE=Date.today();
    
   public class WeekNumbers {
      // so we can check and re-retrieve these every day
      public Date dateRetrieved = CUR_DATE;
      public Month[] months = new Month[]{};
      public Month getMonth(Date dateToCheck) {
         for (Month mnth : months) {
            if (mnth.dateInMonth(dateToCheck)) {
               return mnth;
            }
         } // for (Month mnth : months
         return null;
      } // getMonth
       
      // get the week number of the passed in date
      public Integer getWeekNbr(Date dateToCheck) {
         Integer weekNbr = 0;
         Month mnth = getMonth(dateToCheck);
         if (mnth != null) {
            for (Integer cnt=0; cnt<mnth.weeks.size(); cnt++) {
               Week wk = mnth.weeks[cnt];
               if (wk.dateInWeek(dateToCheck)) {
                  weekNbr = (cnt+1);
                  break;
               }
            }
         } // if (mnth != null
         return weekNbr;
      } // getWeekNbr
       
      // get the week object of a month that is equal to or greater than today's date. 
      // If we're in the 2nd week of the month and week 1 is asked for, then we'll return week 1 of the next month.
      // If we're in week 2 and they ask for week 2, we'll return the current week.
      // If we're in week 1 and they ask for week 2, we'll return week 2 of the current month (the next week)
      public Week getWeek(Integer weekNbr) {
         Week wk = null;
         if (weekNbr <= 0) {
            return wk;
         }
         // see what the current week is (so we know if to use the current month or next month)
         Integer curWeek = getWeekNbr(CUR_DATE);
         System.debug('getWeek weekNbr='+weekNbr+' curWeek='+curWeek);
         for (Month mnth : months) {
             // the first month should be the current month, the next month is the next month.
             // if the current month and the current week is less than or equal to the requested week number.
             if ((mnth.dateInMonth(CUR_DATE) && curWeek <= weekNbr) 
                 || (!mnth.dateInMonth(CUR_DATE) && curWeek > weekNbr)) {     // this is the next month
                System.debug('getWeek found month='+mnth);
                // if they ask for week 5 and it's a 4 week month should return null
                wk = (weekNbr <= mnth.weeks.size() ? mnth.weeks[weekNbr-1] : null);
                break;
             }
         } // for (Month mnth : months
         System.debug('getWeek wk='+wk);
         return wk;
      } // getWeek
   } // class WeekNumbers
    
   public static WeekNumbers v_wkNbrs = null;
    
   public static String CACHEKEY='CadenceUpdateWeekNumbers';
    
   // make sure we've retrieved the fiscal dates
   public static WeekNumbers checkFiscalDates() {
      if (v_wkNbrs == null) {
         v_wkNbrs = (WeekNumbers)CacheManager.getOrg(CACHEKEY);
      }
      // we want to retrieve this at least once per day
      if (v_wkNbrs == null || v_wkNbrs.dateRetrieved != CUR_DATE) {
         v_wkNbrs = new WeekNumbers();
         Date queryStart = CUR_DATE;
         // make sure we're getting this month and the next one.
         Date queryEnd = CUR_DATE.addDays(32);
         Period[] perMonths = [Select Id, Type, StartDate, EndDate, Number
                            From Period
                           Where Type = 'Month'
                             and StartDate <= :queryEnd
                             and EndDate >= :queryStart
                            order by StartDate];
         System.debug('checkFiscalDates queryStart='+queryStart+' queryEnd='+queryEnd+' perMonths='+perMonths.size());
         for (Period month : perMonths) {
             Month mnth = new Month();
             mnth.startDate = month.StartDate;
             mnth.endDate = month.EndDate;
             System.debug('checkFiscalDates month='+month);
             if (month.StartDate < queryStart) {
                queryStart = month.StartDate;
             }
             if (month.EndDate > queryEnd) {
                queryEnd = month.EndDate;
             }
             v_wkNbrs.months.add(mnth);
         } // for (Period per

         Period[] weeks = [Select Id, Type, StartDate, EndDate, Number
                            From Period
                           Where Type = 'Week'
                             and StartDate >= :queryStart
                             and EndDate <= :queryEnd
                            order by StartDate];
         System.debug('checkFiscalDates queryStart='+queryStart+' queryEnd='+queryEnd+' weeks='+weeks.size());
         for (Period perWk : weeks) {
             Week wk = new Week();
             wk.startDate = perWk.StartDate;
             wk.endDate = perWk.EndDate;
             // find the month for the week
             for (Month month : v_wkNbrs.months) {
                // see if this week is in this month
                if (perWk.StartDate >= month.startDate && perWk.EndDate <= month.endDate) {
                   month.weeks.add(wk);
                   break;
                }
             } // or (Month month : months
             System.debug('checkFiscalDates perWk='+perWk);
          } // for (Period week : weeks
       
          //for (Month month : wkNbrs.months) {
          //   System.debug('checkFiscalDates month start='+month.startDate+' end='+month.endDate);
          //   for (Integer cnt=0; cnt<month.weeks.size(); cnt++) {
          //      System.debug('checkFiscalDates week='+(cnt+1)+' startDate='+month.weeks[cnt].startDate+' endDate='+month.weeks[cnt].endDate);
          //   }
          //}
         CacheManager.putOrg(CACHEKEY,v_wkNbrs);
      } // if (wkNbrs == null || wkNbrs.dateRetrieved != Date.today()
      return v_wkNbrs;
   } // checkFiscalDates
    
   public static Integer getWeekNbr(Date dateToCheck) {
      WeekNumbers wkNbrs = checkFiscalDates();
      return (wkNbrs != null ? wkNbrs.getWeekNbr(dateToCheck) : 0);
   } // getWeekNbr
    
   // get the start and end dates of a fiscal week.
   public static Week getWeek(Integer weekNbr) {
      WeekNumbers wkNbrs = checkFiscalDates();
      return (wkNbrs != null ? wkNbrs.getWeek(weekNbr) : null);
   } // getWeek
    
   // If there is a start week and end week on the step.
   // If this is the first touchpoint, use the start date on the car to determine the week number we're starting with. 
   // If there is an existing touchpoint, see if the next touchpoint is in the same week. If not, get the next week number. Get the start date 
    
   public static final Integer TP_NAME_SIZE = Cadence_Touchpoint__c.Name.getDescribe().getLength();
   // the number of minutes we'll cushion the end of the week before we assume we'll go into the next week
   public static Integer END_OF_WEEK_CUSHION=-60;

   private static Boolean createTouchpoint(Cadence_Assignment_Record__c carRec, Cadence__c cad, Cadence_Touchpoint__c[] newTouchpointList) {
      BusinessHours busHours = DG_LMF_Service.getBusinessHours(carRec.TimeZoneAbbrev__c, (carRec.Cadence_Owner__r != null ? carRec.Cadence_Owner__r.TimeZoneSidKey : null));
       
      Boolean tpCreated = false;
      Cadence_Step__c stepToUse = null;
      // if the list is empty, then only the latest touchpoint should be retrieved.
      Cadence_Touchpoint__c curTp = (carRec.Cadence_Touchpoints__r.isEmpty() ? null : carRec.Cadence_Touchpoints__r[0]);
      // needed for the ongoing cadences. 
      Integer curWeek = getWeekNbr(Date.today()); 
      if (cad.OngoingCadence__c) {
         // make sure we're not at the very end of the week. If within an hour of the end, 
         Week wk = getWeek(curWeek);
         Datetime endDateTime = Datetime.newInstance(wk.endDate,busHours.ThursdayEndTime).addMinutes(END_OF_WEEK_CUSHION);
         if (Datetime.now() > endDateTime) {
            // move the current week into the next week since we're at the end of the current.
            curWeek = getWeekNbr(Date.today().addDays(1));
         }
      } // if (cad.OngoingCadence__c
       
      // the week dates for the step we're using
      CadenceUpdate.Week stepWeek = null;
      for (Cadence_Step__c step : cad.Cadence_Steps__r) {
         // if there isn't a current touchpoint, and it's not an ongoing cadence, pull out the first step.
         // if it's ongoing, find the first step that's closest to the current date. if the current week is week 1, and there isn't a week 1 step, then go to week 2, etc.
         if (!cad.OngoingCadence__c && ((curTp != null && step.Step_Number__c > curTp.Cadence_Touchpoint_Step__r.Step_Number__c)
                                        || (curTp == null))) {
            // if it's not an ongoing cadence, just pull out the next step number. 
            stepToUse = step;
            break;
         } else if (cad.OngoingCadence__c && ((curTp != null && step.Step_Number__c > curTp.Cadence_Touchpoint_Step__r.Step_Number__c)
                                        || (curTp == null))) {
            // if it is the ongoing cadence, see if we're still in the same week for the next step. If we're at the end of week 1, and the next step we find is also week 1, we'll
            // want to look for the next step that is not the current week.
            Integer weekStart = Integer.valueOf(step.WeekStart__c);
            Integer weekEnd = Integer.valueOf(step.WeekEnd__c);
            // if 1 <= 1 and 1 <= 2  if 1 <= 3 and 1 <= 3
            System.debug('createTouchpoint curWeek='+curWeek+' weekStart='+weekStart+' weekEnd='+weekEnd);
            if (curWeek <= weekStart && curWeek <= weekEnd) {
               stepToUse = step;
               break;
            }
         }
      } // for (Cadence_Step__c step : cad.Cadence_Steps__r
      
      if (cad.OngoingCadence__c && stepToUse == null) {
         // if we've looped through the rest of the steps and we didn't find a match we'll assume we start back at the beginning with an ongoing cadence
         stepToUse = cad.Cadence_Steps__r[0];
      }
       
      if (stepToUse != null) {
         Cadence_Touchpoint__c touchpoint = new Cadence_Touchpoint__c(Status__c = 'Open', Cadence_Touchpoint_Step__c = stepToUse.Id, Cadence__c = cad.Id, Step_Number__c = stepToUse.Step_Number__c);
         touchpoint.Name = (carRec.Name+'-'+stepToUse.Step_Number__c).left(TP_NAME_SIZE);
         touchpoint.AccountId__c = carRec.AccountId__c;
         touchpoint.LeadId__c = carRec.LeadId__c;
         touchpoint.OpportunityId__c = carRec.OpportunityId__c;
         touchpoint.ContactId__c = carRec.ContactId__c;
         touchpoint.ReferralAccount__c = carRec.ReferralAccount__c;
         System.debug('carRec.Cadence_Owner__c='+carRec.Cadence_Owner__c);
         if(stepToUse.Assigned_Team__c == 'Secondary Owner' && carRec.Secondary_User__c != null){
             touchpoint.OwnerId = carRec.Secondary_User__c;              
          }else{
              touchpoint.OwnerId = carRec.OwnerId;
          } 
        // touchpoint.OwnerId = carRec.OwnerId;// carRec.Cadence_Owner__c;
         touchpoint.CarRecord__c = carRec.Id;
         //Populate override fields while creating new touchpoint
         touchpoint.Override_Email__c = carRec.Override_Email__c;
         touchpoint.Override_Call__c = carRec.Override_Call__c;
         touchpoint.TouchpointObject__c = ObjectHelper.getObjectLabelFromId(carRec.CadenceObject__c);
         // keep track of the order because we can't count on created date
         touchpoint.StepCounter__c = (curTp != null && curTp.StepCounter__c != null ? curTp.StepCounter__c+1 : 1);
         if (stepToUse.EmailExtraTextAllowed__c && String.isNotBlank(stepToUse.EmailExtraTextDefault__c)) {
            touchpoint.EmailExtraText__c = stepToUse.EmailExtraTextDefault__c;
         }
         // look at start date on the car if there is one. If it's after today then use that (use now for the time component) else use now()
         Datetime startTime = Datetime.now();
         // if this is the first touchpoint on a new car, base the start date on what's on the car (if it's populated)
         if (curTp == null && carRec.Start_Date__c != null && carRec.Start_Date__c > Date.today()) {
            Integer nbrDays = Date.today().daysBetween(carRec.Start_Date__c);
            startTime = startTime.addDays(nbrDays);
         }
         setTouchpointDueDate(touchPoint, stepToUse, carRec,startTime, busHours);
         newTouchpointList.add(touchpoint);
         tpCreated = true;
   
      } // if (stepToUse != null
      System.debug('createTouchpoint tpCreated='+tpCreated+' newTouchpointList='+newTouchpointList.size());
      return tpCreated;
   } // createTouchpoint

   // how many minutes are we going to define for a business day?
   public static Integer busMinutesInDay = Integer.valueOf(Label.BusinessMinutesInDay);
   // push back the end of the business day to account for the last job not running exactly at the end. 
   public static Integer endOfDayOffset = -5;
    
   public static void setTouchpointDueDate(Cadence_Touchpoint__c currentTouchpoint, Cadence_Step__c nextStep, Cadence_Assignment_Record__c tzCarRec, Datetime startTime, BusinessHours busHours) {
      Datetime dueDate = startTime;
//      BusinessHours busHours = DG_LMF_Service.getBusinessHours(tzCarRec.TimeZoneAbbrev__c, (tzCarRec.Cadence_Owner__r != null ? tzCarRec.Cadence_Owner__r.TimeZoneSidKey : null));
      if (busHours == null) {
          return;
      }

      Week endWeek = null;
      Datetime endDateTime = null;

      if (nextStep.WeekStart__c != null && nextStep.WeekEnd__c != null) {
         Integer curWeek = getWeekNbr(Date.today()); 
         Integer weekStart = Integer.valueOf(nextStep.WeekStart__c);
         Integer weekEnd = Integer.valueOf(nextStep.WeekEnd__c);
         Week startWeek = getWeek(weekStart);
         endWeek = getWeek(weekEnd);
         // to account for a 4 vs 5 week month
         if (endWeek == null && weekend == 5) {
            endWeek = getWeek(4);
         }
         System.debug('setTouchpointDueDate endWeek='+endWeek);
         // if it's a different week set the start time to 1:00am and let the code get the start time.
         Datetime checkDT = (curWeek != weekStart ? Datetime.newInstance(startWeek.startDate,Time.newInstance(1,0,0,0)) : dueDate);
         dueDate = BusinessHours.nextStartDate(busHours.Id, checkDT);
         // if the due date is after end of business then go to the next business day
         //endDateTime = currentTouchpoint.ExpirationDate__c = Datetime.newInstance(endWeek.endDate,busHours.ThursdayEndTime).addMinutes(endOfDayOffset);
         endDateTime = Datetime.newInstance(endWeek.endDate,busHours.ThursdayEndTime).addMinutes(endOfDayOffset);
         if (dueDate >= endDateTime) {
            // if this is the case, we're going into the next business week
            dueDate = BusinessHours.nextStartDate(busHours.Id, checkDT);
         }
      } // if (nextStep.WeekStart__c != null
       

      long nbrMinutes = 0;
      if (nextStep.Wait_Days__c != null && nextStep.Wait_Days__c > 0) {
          // add the number of days to the current day
          //dueDate = dueDate.addDays(Integer.valueOf(nextStep.Wait_Days__c));
          // make sure that date is a business day
          //dueDate = BusinessHours.nextStartDate(busHours.id,dueDate);
          nbrMinutes = (busMinutesInDay * Integer.valueOf(nextStep.Wait_Days__c));
      }
      System.debug('setTouchpointDueDate dueDate='+dueDate+' nextStep.Wait_Days__c='+nextStep.Wait_Days__c);
      if (nextStep.Wait_Hours__c != null && nextStep.Wait_Hours__c > 0) {
          nbrMinutes = nbrMinutes + (Integer.valueof(nextStep.Wait_Hours__c * 60));
          //dueDate = BusinessHours.add(busHours.id , dueDate, Integer.valueof(nextStep.Wait_Hours__c * 60) * 60000);
      }
      if (nextStep.WaitMinutes__c != null && nextStep.WaitMinutes__c > 0) {
          nbrMinutes = nbrMinutes + (Integer.valueof(nextStep.WaitMinutes__c));
      }
      dueDate = BusinessHours.add(busHours.id , dueDate, (nbrMinutes * 60000));
      //Long differenceInMinutes = (BusinessHours.diff(busHours.Id, Datetime.now(), dueDate)/1000);
      //currentTouchPoint.TotalWaitTime__c = differenceInMinutes;
      currentTouchPoint.TotalWaitTime__c = nbrMinutes;
      System.debug('setTouchpointDueDate dueDate='+dueDate+' nextStep.Wait_Hours__c='+nextStep.Wait_Hours__c+' nbrMinutes='+nbrMinutes);
      currentTouchPoint.Due_Date__c = dueDate;
      if (endWeek != null) {
         // expiration is at the end of day. Going off the business hours but subtracting 5 minutes to make sure it's picked up by the batch.
         currentTouchpoint.ExpirationDate__c = endDateTime;
         System.debug('setTouchpointDueDate expiration set to '+currentTouchpoint.ExpirationDate__c);
      }
   } // setTouchpointDueDate
    
    public static void updateCarRecs(List<Id> carList, Boolean closeCar){
        List<Cadence_Assignment_Record__c> carRecs = [Select Status__c, Started__c, Start_Date__c, Closed__c, Close_Date__c, CloseReason__c 
                                                            ,LatestTouchpoint__c,LatestTouchpointCompletedByRep__c
                                                            ,(Select Id, Close_Date__c,StepCompletedByRep__c
                                                                from Cadence_Touchpoints__r
                                                               Order by StepCounter__c desc nulls last, CreatedDate desc)  // the last one created should be the latest one.
                                                        from Cadence_Assignment_Record__c where Id in:carList];
        System.debug('updateCarRecs closeCar='+closeCar+' carList='+carList.size()+' carRecs='+carRecs.size());
        List<Cadence_Assignment_Record__c> updateCars = new List<Cadence_Assignment_Record__c>();
        for (Cadence_Assignment_Record__c car : carRecs) {
            Boolean recUpdated = false;
            Cadence_Touchpoint__c latestTp = (!car.Cadence_Touchpoints__r.isEmpty() ? car.Cadence_Touchpoints__r[0] : null);
            if (latestTp != null && car.LatestTouchpoint__c != latestTp.Id) {
               car.LatestTouchpoint__c = latestTp.Id;
               recUpdated = true;
            }
            if(!car.Cadence_Touchpoints__r.isEmpty()){
               for(Cadence_Touchpoint__c tp: car.Cadence_Touchpoints__r){
                   if(tp.StepCompletedByRep__c =='Complete' && car.LatestTouchpointCompletedByRep__c != tp.Id){
                       car.LatestTouchpointCompletedByRep__c = tp.Id;
                       recUpdated = true;
                       break;
                   }

               }

           }
            /*if(!car.Started__c){
                car.Started__c = true;
                if (car.Start_Date__c == null) {
                   car.Start_Date__c = Date.today();
                }
                recUpdated = true;
            }*/
            if(closeCar){
                if(car.Status__c !='Closed'){
                    car.Status__c = 'Closed';
                    car.Closed__c = true;
                    car.Close_Date__c = Date.today();
                    recUpdated = true;
                    if (String.isBlank(car.CloseReason__c)) {
                       car.CloseReason__c = 'Cadence Completed';
                    }
                    // TODO - do we need a reason it closed?                   
                }
            }
            if(recUpdated){
                updateCars.add(car);
            }
        }
          DmlHelper.performDML(updateCars, DmlHelper.DML_UPDATE, 'CadenceUpdate', 'updateCarRecs', 'update car records', true);  
    }
    public static void closeTouchpoints(List<String> carList){
        system.debug('CadenceUpdate checkCarsAfter CLOSE TOUCHPOINT CALLED');
        List<Cadence_Touchpoint__c> touchptList = [Select Id, Status__c, LastUpdateMethod__c from Cadence_Touchpoint__c where CarRecord__c in :carList and Status__c ='Open'];
        for(Cadence_Touchpoint__c tp : touchptList){
            tp.Status__c = 'Closed';
            tp.LastUpdateMethod__c = 'CadenceUpdate.closeTouchpoints';
        }
        DmlHelper.performDML2(touchptList, DmlHelper.DML_UPDATE, 'CadenceUpdate', 'closeTouchpoints', 'closeTouchpoints', true);
    } // closeTouchpoints

    // called when a new CAR is created, or the ObjectId changes
    public static void updateCarRecords(List<Cadence_Assignment_Record__c> carList){
        System.debug('updateCarRecords carList='+carList.size());
        //Map<Id, Cadence_Assignment_Record__c> objectMap = new Map<Id, Cadence_Assignment_Record__c>();
        Map<Id, Boolean> acctDncMap = new Map<Id, Boolean>();
        Map<Id,Cadence_Assignment_Record__c[]> leadCarMap = new Map<Id,Cadence_Assignment_Record__c[]>();
        Map<Id,Cadence_Assignment_Record__c[]> oppCarMap = new Map<Id,Cadence_Assignment_Record__c[]>();
        Map<Id,Cadence_Assignment_Record__c[]> acctCarMap = new Map<Id,Cadence_Assignment_Record__c[]>();
        Map<Id,Cadence_Assignment_Record__c[]> ctctCarMap = new Map<Id,Cadence_Assignment_Record__c[]>();
        Map<Id,Cadence_Assignment_Record__c[]> refAcctCarMap = new Map<Id,Cadence_Assignment_Record__c[]>();
        List<Cadence_Assignment_Record__c> badCarList = new List<Cadence_Assignment_Record__c>();
        // collect all of the ids we will use to look for open CAR records.
        List<Id> carCadenceTypeIdList = new List<Id>();
        Set<Id> cadenceIdSet = new Set<Id>();
        
        for (Cadence_Assignment_Record__c carRec : carList){
            // allow to proceed for Send to Cadence
            if(carRec.Cadence__c == null && String.isBlank(carRec.SendToPartnerStatus__c)){
                carRec.Description__c = 'Exception Caught: No cadence selected for CAR record';
                carRec.CloseReason__c = 'Error: No Cadence Selected';
                badCarList.add(carRec);
            }
            else{
                if(carRec.Status__c != 'Closed'){
                    carRec.Status__c = 'Open';
                }
                try{
                    String cadenceObjectName = ObjectHelper.getObjectNameFromId(carRec.CadenceObject__c);
                    System.debug('CadenceUpdate updateCarRecords cadenceObjectName='+cadenceObjectName+' carRec.CadenceObject__c '+carRec.CadenceObject__c);
                    switch on cadenceObjectName{
                        when 'Contact'{
                            addToMap(carRec.CadenceObject__c, carRec, ctctCarMap);
                        }
                        when 'Opportunity'{
                            addToMap(carRec.CadenceObject__c, carRec, oppCarMap);
                        }
                        when 'Account'{
                            addToMap(carRec.CadenceObject__c, carRec, acctCarMap);
                        }
                        when 'Lead'{
                            addToMap(carRec.CadenceObject__c, carRec, leadCarMap);
                        }
                        when 'Referral_Account__c'{
                            addToMap(carRec.CadenceObject__c, carRec, refAcctCarMap);
                        }
                        when else{
                            carRec.Description__c = 'Exception Caught: Issue with Cadence Object Id. Touchpoint not created';
                            carRec.CloseReason__c = 'Error: Invalid Object Id';
                            badCarList.add(carRec);
                        }
                    }
                    //objectMap.put(carRec.CadenceObject__c, carRec);
                    if(carRec.Cadence__c != null){
                        cadenceIdSet.add(carRec.Cadence__c);
                    }
                }
                catch(exception ex) {
                    carRec.Description__c = 'Exception Caught: '+ex.getMessage();
                    carRec.CloseReason__c = 'Error: Generic Exception';
                    badCarList.add(carRec);
                    System.debug('updateParentInfo ex='+ex.getMessage()+'; '+ex.getStackTraceString());
                }   
            }
        }
        
        Map<Id, Cadence__c> cadenceMap = (!cadenceIdSet.isEmpty()
                                          ? new Map<Id,Cadence__c>([Select Id, Name, Sales_Org__c, Cadence_Type__c, Opportunity_Type__c, CadenceTypeGroup__c
                                                                    , ReferralSourceBusinessType2__c, TargetType__c, Ignore_DNC_DNE__c, OverrideOtherCARs__c 
                                                                    from Cadence__c where id in :cadenceIdSet]) 
                                          : new Map<Id,Cadence__c>());
        //Close Invalid CARs
        if(!badCarList.isEmpty()){
            closeInvalidCars(badCarList);
        }
        //Update CARs
        //updateCars(leadIdList, oppIdList, acctIdList, contactIdList, carCadenceTypeIdList, objectMap, cadenceMap, acctDncMap);
        updateCars(leadCarMap, oppCarMap, acctCarMap, ctctCarMap, refAcctCarMap, carCadenceTypeIdList, cadenceMap, acctDncMap);
        System.debug('updateCarRecords carCadenceTypeIdList='+carCadenceTypeIdList.size()+' cadenceIdSet='+cadenceIdSet.size());
        if(!cadenceIdSet.isEmpty()){
            //List<String> CadenceTypesList = getCadenceTypes(carCadenceTypeIdList);
            Map<String,Cadence_Assignment_Record__c> cadTypeMap = getCadenceTypes(carCadenceTypeIdList);
            //Verify CAR List
            //validateCars(CadenceTypesList, carList, cadenceMap, acctDncMap);
            validateCars(cadTypeMap, carList, cadenceMap, acctDncMap);
        }
    } // updateCarRecords
    
    public static void addToMap(Id recId, Cadence_Assignment_Record__c carRec, Map<Id,Cadence_Assignment_Record__c[]> recCarMap) {
       Cadence_Assignment_Record__c[] cars = (recCarMap.containsKey(recId) ? recCarMap.get(recId) : new Cadence_Assignment_Record__c[]{});
       cars.add(carRec);
       recCarMap.put(recId,cars);
    } // addToMap

    //public static void validateCars(List<String> cadenceTypesList, List<Cadence_Assignment_Record__c> carList, Map<Id, Cadence__c> cadenceMap, Map<Id, Boolean> acctDncMap){
    public static void validateCars(Map<String,Cadence_Assignment_Record__c> cadTypeMap, List<Cadence_Assignment_Record__c> carList, Map<Id, Cadence__c> cadenceMap, Map<Id, Boolean> acctDncMap){
        System.debug('validateCars cadTypeMap='+cadTypeMap.size());
        List<Cadence_Assignment_Record__c> invalidCarList = new List<Cadence_Assignment_Record__c>();
        Map<Id,Cadence_Assignment_Record__c> updateCarMap = new Map<Id,Cadence_Assignment_Record__c>();
        Cadence_Touchpoint__c[] updateTPs = new Cadence_Touchpoint__c[]{};
        
        //List<String> currentCadenceTypes = updateCarRecords(carList, cadenceMap);
        for(Cadence_Assignment_Record__c carWreck : carList){
            if(carWreck.Status__c != 'Closed'){
                Cadence__c currentCadence = cadenceMap.get(carWreck.Cadence__c) != null ? cadenceMap.get(carWreck.Cadence__c) : null;
                // exclude referral accounts from this check - we are currently allowing them to have an unlimited number of cars
                //String parentObjectId = (carWreck.AccountId__c != null ? carWreck.AccountId__c 
                //                             : (carWreck.ReferralAccount__c != null ? carWreck.ReferralAccount__c : carWreck.LeadId__c));
                String parentObjectId = (carWreck.AccountId__c != null ? carWreck.AccountId__c 
                                             : (carWreck.LeadId__c != null ? carWreck.LeadId__c : null));
                String carKey = (currentCadence!=null && parentObjectId != null ? parentObjectId+'_'+currentCadence.Cadence_Type__c: null);
                System.debug('validateCars carKey='+carKey);
                Boolean valid = true;
                String targetKey = null;
                System.debug(' CadenceUpdate validateCars acctDncMap:'+acctDncMap);
                Boolean dnc = acctDncMap.get(parentObjectId);
                //set ignore DNE
                carWreck.Ignore_DNE__c = currentCadence!=null? currentCadence.Ignore_DNC_DNE__c: false;
                
                if (dnc != null && dnc && currentCadence!=null && !currentCadence.Ignore_DNC_DNE__c) {
                   //Check for DNC Accounts
                   addToDescription(carWreck,'Exception Caught: Do Not Contact Company. Touchpoint not created');
                   carWreck.CloseReason__c = 'Error: Do Not Contact';
                   System.debug('validateCars dnc for touchpoint - not complete');
                   valid = false;
                }
                
                if (valid && carKey != null) {
                   Cadence_Assignment_Record__c dupeCar = checkForDuplicate(carKey, carWreck, currentCadence, cadTypeMap);
                   if (dupeCar != null && carwreck.OverrideOtherCARs__c && dupeCar.Id != null) {
                      closeForOverride(dupeCar, updateCarMap, updateTPs);
                      addToDescription(carWreck,'This lead was also part of '+dupeCar.Cadence__r.Name+'.');
                   } else if (dupeCar != null) {
                      addToDescription(carWreck,'Exception Caught: Open Cadence with Cadence Type: '+ currentCadence.Cadence_Type__c+' already exists on parent object.');
                      carWreck.CloseReason__c = 'Error: Already In Cadence';
                      System.debug('validateCars Open Cadence with Cadence Type: '+ currentCadence.Cadence_Type__c+' already exists on parent object');
                      valid = false;
                      carKey = dupeKey;
                   }
                }
                if (valid) {
                   targetKey = getTargetKey(parentObjectId, currentCadence);
                   Cadence_Assignment_Record__c dupeCar = checkForDuplicate(targetKey, carWreck, currentCadence, cadTypeMap);
                   if (targetKey != null && dupeCar != null && carwreck.OverrideOtherCARs__c && dupeCar.Id != null) {
                      closeForOverride(dupeCar, updateCarMap, updateTPs);
                      addToDescription(carWreck,'This lead was also part of '+dupeCar.Cadence__r.Name+'.');
                   } else if (targetKey != null && dupeCar != null) {
                      addToDescription(carWreck,'Exception Caught: Open Cadence with Target Type: '+ currentCadence.TargetType__c+' already exists on parent object.');
                      carWreck.CloseReason__c = 'Error: Already In Cadence';
                      System.debug('validateCars Open Cadence with Target Type: '+ currentCadence.TargetType__c+' already exists on parent object');
                      valid = false;
                      targetKey = dupeKey;
                   }
                }
/*
                if (carKey != null) {
                    
                   targetKey = getTargetKey(parentObjectId, currentCadence);
                   Boolean dnc = acctDncMap.get(parentObjectId);
                   if (dnc != null && dnc) {
                       //Check for DNC Accounts
                       addToDescription(carWreck,'Exception Caught: Do Not Contact Company. Touchpoint not created');
                       carWreck.CloseReason__c = 'Error: Do Not Contact';
                       System.debug('validateCars dnc for touchpoint - not complete');
                       valid = false;
                   } else if (cadTypeMap.containsKey(carKey) && (carWreck.Id == null || cadTypeMap.get(carKey).Id != carWreck.Id)) {
                       //Check for Duplicate Cadence Type
                       if (carwreck.OverrideOtherCARs__c && cadTypeMap.get(carKey).Id != null) {
                          Cadence_Assignment_Record__c closeCar = cadTypeMap.get(carKey);
                          closeForOverride(closeCar, updateCarMap, updateTPs);
                          addToDescription(carWreck,'This lead was also part of '+closeCar.Cadence__r.Name+'.');
                       } else {
                          addToDescription(carWreck,'Exception Caught: Open Cadence with Cadence Type: '+ currentCadence.Cadence_Type__c+' already exists on parent object.');
                          carWreck.CloseReason__c = 'Error: Already In Cadence';
                          System.debug('validateCars Open Cadence with Cadence Type: '+ currentCadence.Cadence_Type__c+' already exists on parent object');
                          valid = false;
                       }
                   } else if (targetKey != null && cadTypeMap.containsKey(targetKey) && (carWreck.Id == null || cadTypeMap.get(targetKey).Id != carWreck.Id)) {
                       // duplicate by Target Type
                       if (carwreck.OverrideOtherCARs__c && cadTypeMap.get(targetKey).Id != null) {
                          Cadence_Assignment_Record__c closeCar = cadTypeMap.get(targetKey);
                          closeForOverride(closeCar, updateCarMap, updateTPs);
                          addToDescription(carWreck,'This lead was also part of '+closeCar.Cadence__r.Name+'.');
                       } else {
                          String msg = 'Open Cadence with Target Type: '+ currentCadence.TargetType__c+' already exists on parent object.';
                          addToDescription(carWreck,'Exception Caught: '+msg);
                          carWreck.CloseReason__c = 'Error: Already In Cadence';
                          System.debug('validateCars '+msg);
                          valid = false;
                       }
                   }
                } // if (carKey != null
*/
                if (valid) {
                    carWreck.Touchpoint_Created_Successfully__c = true;
                    if (carKey != null) {
                       cadTypeMap.put(carKey,carWreck);
                    }
                    if (targetKey != null) {
                       cadTypeMap.put(targetKey,carWreck);
                    }
                } else {
                    invalidCarList.add(carWreck);
                }
            } // if (carWreck.Status__c != 'Closed'
        } // for(Cadence_Assignment_Record__c carWreck : carList
        if(!invalidCarList.isEmpty()){
            closeInvalidCars(invalidCarList);
        }
        if (!updateCarMap.isEmpty()) {
           CadenceHelper.SKIP_TRIGGERS=true;
           DmlHelper.performDML2(updateCarMap.values(), DmlHelper.DML_UPDATE, 'CadenceUpdate', 'validateCars', 'updateCarRecord', true);
           DmlHelper.performDML2(updateTPs, DmlHelper.DML_UPDATE, 'CadenceUpdate', 'validateCars', 'updateTouchpoint', true);
           CadenceHelper.SKIP_TRIGGERS=false;
        }
    } // validateCars
    
    public static String dupeKey=null;
    public static Cadence_Assignment_Record__c checkForDuplicate(String key, Cadence_Assignment_Record__c car, Cadence__c cad, Map<String,Cadence_Assignment_Record__c> cadTypeMap) {
       Cadence_Assignment_Record__c dupeCar = null; 
       dupeKey = key;
       if (String.isNotBlank(cad.Opportunity_Type__c)) {
          for (String oppType : cad.Opportunity_Type__c.split(';')) {
             String checkKey = key+'_'+oppType;
             if (cadTypeMap.containsKey(checkKey) && (car.Id == null || cadTypeMap.get(checkKey).Id != car.Id)) {
                dupeCar=cadTypeMap.get(checkKey);
                dupeKey=checkKey;
                break;
             }
          }
       } else {
          dupeCar = ((cadTypeMap.containsKey(key) && (car.Id == null || cadTypeMap.get(key).Id != car.Id)) ? cadTypeMap.get(key) : null);
       }
       return dupeCar;
    } // checkForDuplicate
    
   public static void closeForOverride(Cadence_Assignment_Record__c car, Map<Id,Cadence_Assignment_Record__c> updateCarMap, Cadence_Touchpoint__c[] updateTPs) {
      if (!updateCarMap.containsKey(car.Id)) {
         WorkQueueController.addToActivityLog(car,'Closed due to new record entered with Override set by an Admin');
         car.Closed__c = true;
         car.Status__c = 'Closed';
         car.Close_Date__c = Date.today();
         car.CloseReason__c = 'Campaign Override';
         if (car.LatestTouchpoint__c != null && car.LatestTouchpoint__r != null) {
            car.LatestTouchpoint__r.Close_Date__c=Date.today();
            car.LatestTouchpoint__r.Status__c='Closed';
            car.LatestTouchpoint__r.LastUpdateMethod__c='CadenceUpdate.closeForOverride';
            updateTPs.add(car.LatestTouchpoint__r);
         }
         updateCarMap.put(car.Id,car);
      } // if (!updateCarMap.containsKey
   } // closeForOverride
    
    public static String getTargetKey(String parentObjectId, Cadence__c cad) {
       String targetKey = null;
       if (cad != null && String.isNotBlank(cad.TargetType__c) && cad.TargetType__c.contains('Prospect')) {
          targetKey = parentObjectId+'_'+cad.TargetType__c;
       }
       return targetKey;
    } // getTargetKey
    
   public static final Integer CAR_NAME_SIZE = Cadence_Assignment_Record__c.Name.getDescribe().getLength();

    //public static void updateCars(List<Id> leadIdList, List<Id> oppIdList, List<Id> acctIdList, List<Id> contactIdList, List<Id> carCadenceTypeIdList, Map<Id, Cadence_Assignment_Record__c> objectMap, Map<Id, Cadence__c> cadenceMap,Map<Id, Boolean> acctDncMap){
    // populate all of the related fields on the CAR record.
    public static void updateCars(Map<Id,Cadence_Assignment_Record__c[]> leadCarMap, Map<Id,Cadence_Assignment_Record__c[]> oppCarMap
                                   ,Map<Id,Cadence_Assignment_Record__c[]> acctCarMap, Map<Id,Cadence_Assignment_Record__c[]> ctctCarMap
                                   ,Map<Id,Cadence_Assignment_Record__c[]> refAcctCarMap
                                   ,List<Id> carCadenceTypeIdList, Map<Id, Cadence__c> cadenceMap
                                  ,Map<Id, Boolean> acctDncMap) {
        System.debug('updateCars acctCarMap='+acctCarMap.size());
        Cadence_Assignment_Record__c[] badCars = new Cadence_Assignment_Record__c[]{};

        if(!acctCarMap.isEmpty()){
            List<Account> acctList = [Select Id, Name, OwnerId, BillingPostalCode, Do_Not_Call__c, SignificantContact__c,HRS_Account_Owner__c, Premier_PBS_Account_Owner__c,HNBF_Account_Owner__c, OasisPEOAccountOwner__c
                                            ,Hold_Out__c, Hold_Out_Expiration__c, Permanent_Hold_Out_Description__c, Owner_Zip_Code__c
                                      from Account where Id in:acctCarMap.keySet()];
            for(Account acct : acctList){
                Cadence_Assignment_Record__c[] cars = acctCarMap.get(acct.Id);
                if (cars != null) {
                    for (Cadence_Assignment_Record__c acctCar : cars) {
                       //Cadence_Assignment_Record__c acctCar = objectMap.get(acct.Id);
                       //Cadence__c cad = cadenceMap.get(acctCar.Cadence__c);
                       System.debug('updateCars acct='+acct.Name+' hasCad='+(cadenceMap.containsKey(acctCar.Cadence__c)));
                       //if (cad != null && acctCar.Cadence_Owner__c == null && String.valueOf(acctCar.OwnerId).startsWith('005')){
                       //   acctCar.Cadence_Owner__c = acctCar.CurrentUserIsOwner__c ? UserInfo.getUserId() : getOwnerId(acct, ObjectHelper.OBJECT_ACCOUNT, cadenceMap.get(acctCar.Cadence__c));
                       //}
                
                       setCARFields(acctCar, acct, null, null, null, cadenceMap, getOwnerId(acct, ObjectHelper.OBJECT_ACCOUNT, cadenceMap.get(acctCar.Cadence__c)));
                       //acctCar.RecordName__c = acct.Name;
                       //APR0130779 : Remove Significant Lead/Contact
                       //acctCar.SignificantContact__c = acct.SignificantContact__c;
                       acctCar.ContactId__c = acct.SignificantContact__c;
                       carCadenceTypeIdList.add(acctCar.AccountId__c);
                       acctDncMap.put(acct.Id, acct.Do_Not_Call__c);
                    } // for (Cadence_Assignment_Record__c acctCar
                } // if (cars != null
            }
        } // if(!acctCarMap.isEmpty
                                      
        if(!leadCarMap.isEmpty()){
            List<Lead> leadList = [Select Id, Company, DoNotCall, Lead_Company__c, Name, OwnerId, PostalCode , Lead_Company__r.SignificantLead__c
                                         ,Hold_Out__c, Hold_Out_Expiration__c, Hold_Out_Reason__c, LatestCampaign__c, LatestCampaignDate__c
                                   from Lead where Id in:leadCarMap.keySet()];
            for (Lead l1 : leadList) {
                Cadence_Assignment_Record__c[] cars = leadCarMap.get(l1.Id);
                if (cars != null) {
                    for (Cadence_Assignment_Record__c leadCar : cars) {
                       //Cadence_Assignment_Record__c leadCar = objectMap.get(l1.Id);
                       setCARFields(leadCar, null, null, l1, null, cadenceMap, getOwnerId(l1, ObjectHelper.OBJECT_LEAD, cadenceMap.get(leadCar.Cadence__c)));
                       //if(cadenceMap.containsKey(leadCar.Cadence__c) && leadCar.Cadence_Owner__c == null && String.valueOf(leadCar.OwnerId).startsWith('005')){
                              //leadCar.Cadence_Owner__c = leadCar.CurrentUserIsOwner__c ? UserInfo.getUserId() : l1.OwnerId;
                       //   leadCar.Cadence_Owner__c = leadCar.CurrentUserIsOwner__c ? UserInfo.getUserId() : getOwnerId(l1, ObjectHelper.OBJECT_LEAD, cadenceMap.get(leadCar.Cadence__c));
                       //}
                       //leadCar.RecordName__c = l1.Name;
                       //leadCar.ParentZip__c = l1.PostalCode;
                       leadCar.LeadCompanyId__c = l1.Lead_Company__c;
                       leadCar.LeadId__c = l1.Id;
                       //APR0130779 : Remove Significant Lead/Contact
                       //if (l1.Lead_Company__r != null && l1.Lead_Company__r.SignificantLead__c != null) {
                       //   leadCar.SignificantLead__c = l1.Lead_Company__r.SignificantLead__c;
                       //} else {
                       //   leadCar.SignificantLead__c = l1.Id;
                       //}
                       carCadenceTypeIdList.add(leadCar.LeadId__c);
                       acctDncMap.put(leadCar.LeadId__c,l1.DoNotCall);
                    } // for (Cadence_Assignment_Record__c leadCar
                } // if (cars != null
            }
        } // if(!leadCarMap.isEmpty
                                      
        if(!oppCarMap.isEmpty()){
            List<Opportunity> oppList = [Select Id, AccountId, Name, OwnerId
                                              ,Account.Id, Account.OwnerId, Account.Name,Account.SignificantContact__c, Account.Do_Not_Call__c, Account.OasisPEOAccountOwner__c
                                              ,Account.Hold_Out__c, Account.Hold_Out_Expiration__c, Account.Permanent_Hold_Out_Description__c, Account.Owner_Zip_Code__c
                                         ,(Select Id, ContactId From OpportunityContactRoles Where IsPrimary=true)
                                         from Opportunity where Id in:oppCarMap.keySet()];
            for(Opportunity opp1 : oppList){
                Cadence_Assignment_Record__c[] cars = oppCarMap.get(opp1.Id);
                if (cars != null) {
                    for (Cadence_Assignment_Record__c oppCar : cars) {
                       //Cadence_Assignment_Record__c oppCar = objectMap.get(opp1.Id);
                       setCARFields(oppCar, opp1.Account, null, null, null, cadenceMap, opp1.OwnerId);
                       //if (oppCar.Cadence_Owner__c == null) {
                       //   oppCar.Cadence_Owner__c = oppCar.CurrentUserIsOwner__c ? UserInfo.getUserId() : opp1.OwnerId;
                       //}
                       oppCar.OpportunityId__c = opp1.Id;
                       //oppCar.RecordName__c = opp1.Name;
                       if (!opp1.OpportunityContactRoles.isEmpty()) {
                          oppCar.ContactId__c = opp1.OpportunityContactRoles[0].ContactId;
                          //APR0130779 : Remove Significant Lead/Contact
                          //oppCar.SignificantContact__c = opp1.OpportunityContactRoles[0].ContactId;
                       } else if (opp1.Account != null && opp1.Account.SignificantContact__c != null) {
                          oppCar.ContactId__c = opp1.Account.SignificantContact__c;
                          //oppCar.SignificantContact__c = opp1.Account.SignificantContact__c;
                       }
                       carCadenceTypeIdList.add(oppCar.AccountId__c);
                       acctDncMap.put(oppCar.AccountId__c, opp1.Account.Do_Not_Call__c);
                    } // for (Cadence_Assignment_Record__c oppCar
                } // if (cars != null
            } // for(Opportunity opp1
        } // if(!oppCarMap.isEmpty
                                      
        if(!ctctCarMap.isEmpty()){
            List<Contact> contactList = [Select Id, Name, OwnerId, AccountId ,HRS_Contact_Owner__c ,Premier_PBS_Contact_Owner__c,HNBF_Contact_Owner__c, OasisPEOOwner__c, LatestCampaignDate__c, 
                                                LatestCampaign__c, Account.Id, Account.Name, Account.OwnerId, Account.Do_Not_Call__c, Account.SignificantContact__c, Account.OasisPEOAccountOwner__c
                                               ,Account.Hold_Out__c, Account.Hold_Out_Expiration__c, Account.Permanent_Hold_Out_Description__c, Account.Owner_Zip_Code__c
                                         from Contact where Id in:ctctCarMap.keySet()];
            for(Contact con1 : contactList){
                Cadence_Assignment_Record__c[] cars = ctctCarMap.get(con1.Id);
                if (cars != null) {
                    for (Cadence_Assignment_Record__c contactCar : cars) {
                       //Cadence_Assignment_Record__c contactCar = objectMap.get(con1.Id);
                       setCARFields(contactCar, con1.Account, con1, null, null, cadenceMap, getOwnerId(con1, ObjectHelper.OBJECT_CONTACT, cadenceMap.get(contactCar.Cadence__c)));
                       //if(cadenceMap.containsKey(contactCar.Cadence__c) && contactCar.Cadence_Owner__c == null && String.valueOf(contactCar.OwnerId).startsWith('005')){
                       //   contactCar.Cadence_Owner__c = contactCar.CurrentUserIsOwner__c ? UserInfo.getUserId() : getOwnerId(con1, ObjectHelper.OBJECT_CONTACT, cadenceMap.get(contactCar.Cadence__c));
                       //}
                       //contactCar.RecordName__c = con1.Name;
                       contactCar.ContactId__c = con1.Id;
                       //APR0130779 : Remove Significant Lead/Contact
                       //contactCar.SignificantContact__c = con1.Id;
                       carCadenceTypeIdList.add(contactCar.AccountId__c);
                       acctDncMap.put(contactCar.AccountId__c, con1.Account.Do_Not_Call__c);
                    } // for (Cadence_Assignment_Record__c contactCar
                } // if (cars != null
            } // for(Contact con1 : contactList
        } // if(!ctctCarMap.isEmpty
        if (!refAcctCarMap.isEmpty()) {
           Referral_Account__c[] refAccts = [Select Id, Name, End_Date__c, OwnerId, HRS_Account_Owner__c ,Premier_PBS_Account_Owner__c,HNBF_Account_Owner__c
                                                  ,Internal_Wholesaler_Account_Owner__c
                                                  ,Referral_Source_Business_Type__c
                                               , Zip_Postal_Code__c
                                         from Referral_Account__c where Id in:refAcctCarMap.keySet()];
           for (Referral_Account__c refAcct : refAccts) {
              Cadence_Assignment_Record__c[] cars = refAcctCarMap.get(refAcct.Id);
              System.debug('updateCars refAcct='+refAcct.Name+' cars='+(cars != null ? cars.size() : -1)+' end date='+refAcct.End_Date__c);
              if (cars != null) {
                 for (Cadence_Assignment_Record__c car : cars) {
                    Cadence__c cad = cadenceMap.get(car.Cadence__c);
                    car.ReferralAccount__c = refAcct.Id;
                    setCARFields(car, null, null, null, refAcct, cadenceMap, getOwnerId(refAcct, ObjectHelper.OBJECT_REF_ACCOUNT, cad));
                    if (refAcct.End_Date__c != null) {
                       car.Description__c = 'Exception Caught: Firm End Dated. Touchpoint not created';
                       car.CloseReason__c = 'Firm End Dated';
                       badCars.add(car);
                    } else if (cad != null && String.isNotBlank(cad.ReferralSourceBusinessType2__c ) 
                               && !cad.ReferralSourceBusinessType2__c.contains(refAcct.Referral_Source_Business_Type__c)) {
                       car.Description__c = 'Exception Caught: Referral Source Business Type does not match Cadence. Touchpoint not created';
                       car.CloseReason__c = 'Business Type Mismatch';
                       badCars.add(car);
                    } else {
                       System.debug('updateCars refAcct='+refAcct.Name+' add to carCadenceTypeIdList');
                       carCadenceTypeIdList.add(car.ReferralAccount__c);
                    }
                 } // for (Cadence_Assignment_Record__c car : cars
              } // if (cars != null)
           } // for (Referral_Account__c refAcct : refAccts
        } // if (!refAcctCarMap.isEmpty()
        if (!badCars.isEmpty()) {
            closeInvalidCars(badCars);                             
        }
    } // updateCars
    public static Integer DATE_RANGE = Integer.valueOf(Label.CadenceUpdate_Campaign_Check);

    public static void setCARFields(Cadence_Assignment_Record__c car, Account acct, Contact ctct, Lead ld, Referral_Account__c refAcct, Map<Id, Cadence__c> cadenceMap, Id recOwnerId) {
       Schema.DescribeSObjectResult r = Cadence_Assignment_Record__c.sObjectType.getDescribe();
       String keyPrefix = r.getKeyPrefix();
       DateTime latestCampaignDate;
       if (String.isBlank(car.Name) || car.name.startsWith(keyPrefix)) {
          car.Name = (acct != null ? acct.Name : (ld != null ? ld.Company : (refAcct != null ? refAcct.Name : 'CAR Record'))).left(CAR_NAME_SIZE);
       }
       if (acct != null) {
          car.AccountId__c = acct.Id;
       }
       if(ctct!=null){
         latestCampaignDate = ctct.LatestCampaignDate__c;
       }
       if (ld != null) {
          car.LeadId__c = ld.Id;
          latestCampaignDate = ld.LatestCampaignDate__c;
       }
       if (refAcct != null) {
          car.ReferralAccount__c = refAcct.Id;
       }
       Cadence__c cad = cadenceMap.get(car.Cadence__c);
       //if (cad != null) {
       //   car.Name = (car.Name+'-'+cad.Name).left(CAR_NAME_SIZE);
       //}
       // The cadence should exist, just to show that it's an active cadence.
       if (cad != null && car.Cadence_Owner__c == null && (car.OwnerId == null || String.valueOf(car.OwnerId).startsWith('005'))) {
          car.Cadence_Owner__c = (car.CurrentUserIsOwner__c ? UserInfo.getUserId() : recOwnerId);
       }
       if (car.Cadence_Owner__c != null) {
          car.OwnerId = car.Cadence_Owner__c;
       }
       if(latestCampaignDate!=null && latestCampaignDate.addHours(DATE_RANGE) > DateTime.now()) {
         car.Latest_Campaign__c = ld!=null ? ld.LatestCampaign__c   : ctct.LatestCampaign__c;
        }
        if(cad!=null && cad.OverrideOtherCARs__c){
           car.OverrideOtherCARs__c = cad.OverrideOtherCARs__c;
       } 
    } // setCARFields
    
    public static Map<String,Cadence_Assignment_Record__c> getCadenceTypes(List<Id> carIdList){
        // key is the record id + cadence Type, or record Id + Target Type. 
        // The Value is the ID of the CAR record so we can know if we're checking against itself
        Map<String,Cadence_Assignment_Record__c> curKeyMap = new Map<String,Cadence_Assignment_Record__c>();
        //Query all open cadence 
        // exclude ongoing and referral source cadences for now. 
        // We are allowing unlimited cars against referral sources 
        List<Cadence_Assignment_Record__c> currentCARList = [Select Id, AccountId__c, Cadence__c, Cadence__r.Cadence_Type__c, Cadence__r.Name, LeadId__c
                                                                   ,LastModifiedDate, Status__c, Cadence__r.TargetType__c
                                                                   ,Cadence__r.ReferralSourceCadence__c, Cadence__r.OngoingCadence__c, Cadence__r.Opportunity_Type__c
                                                                   ,Activity_Log__c, Closed__c, Close_Date__c, ProcessNotes__c, ReferralAccount__c
                                                                   ,LatestTouchpoint__c
                                                                   ,LatestTouchpoint__r.Id, LatestTouchpoint__r.Close_Date__c, LatestTouchpoint__r.Status__c
                                                                   ,LatestTouchpoint__r.LastUpdateMethod__c
                                                             from Cadence_Assignment_Record__c 
                                                             where Status__c = 'Open' 
                                                               and Cadence__r.OngoingCadence__c = false
                                                               and Cadence__r.ReferralSourceCadence__c = false
                                                               and (AccountId__c in :carIdList or LeadId__c in :carIdList or ReferralAccount__c in :carIdList)];
        System.debug('getCadenceTypes carIdList='+carIdList.size()+' currentCARList='+currentCARList.size());
        //Map each CAR record to a Cadence Type
        for (Cadence_Assignment_Record__c carRec : currentCARList) {
            if(carRec.Cadence__r.Cadence_Type__c!=null){
                String parentObjectId = (carRec.AccountId__c != null ? carRec.AccountId__c : (carRec.ReferralAccount__c != null ? carRec.ReferralAccount__c : carRec.LeadId__c));
                String key = parentObjectId+'_'+carRec.Cadence__r.Cadence_Type__c;
                System.debug('getCadenceTypes key='+key);
                if (!curKeyMap.containsKey(key)) {
                    curKeyMap.put(key,carRec);
                }
                checkAddOppTypes(carRec, key, curKeyMap);
                String targetKey = getTargetKey(parentObjectId, carRec.Cadence__r);
                if (targetKey != null && !curKeyMap.containsKey(targetKey)) {
                    curKeyMap.put(targetKey,carRec);
                }
                checkAddOppTypes(carRec, targetKey, curKeyMap);
            }       
        } // for (Cadence_Assignment_Record__c carRec : currentCARList
        System.debug('CadenceUpdate getCadenceTypes curKeyMap: '+curKeyMap.size());
        //return keyList;
        return curKeyMap;
    } // getCadenceTypes
    
    public static void checkAddOppTypes(Cadence_Assignment_Record__c car, String keyPrefix, Map<String,Cadence_Assignment_Record__c> curKeyMap) {
       if (String.isNotBlank(keyPrefix) && String.isNotBlank(car.Cadence__r.Opportunity_Type__c)) {
          for (String oppType : car.Cadence__r.Opportunity_Type__c.split(';')) {
              String key = keyPrefix+'_'+oppType;
              if (!curKeyMap.containsKey(key)) {
                 curKeyMap.put(key,car);
              }
           }
        } // if (String.isNotBlank(car.Cadence__r.Opportunity_Type__c

    } // checkAddOppTypes
    
    public static void closeCars(List<Cadence_Assignment_Record__c> carCloseList){
        for (Cadence_Assignment_Record__c carRec : carCloseList) {
            carRec.Closed__c = true;
            carRec.Status__c = 'Closed';
            if (carRec.Close_Date__c == null) {
               carRec.Close_Date__c = Date.today();
            }
        }
    } // closeCar
    
    public static void closeInvalidCars(List<Cadence_Assignment_Record__c> carCloseList){
        System.debug('closeInvalidCars carCloseList='+carCloseList.size());
        for(Cadence_Assignment_Record__c carRec : carCloseList){
            carRec.Touchpoint_Created_Successfully__c = false;
            carRec.Closed__c = true;
            carRec.Status__c = 'Closed';
            carRec.Started__c = false;
            if (carRec.Close_Date__c == null) {
                carRec.Close_Date__c = Date.today();
            }
        }
    } // closeInvalidCars
    public static Id getOwnerId(SObject rec, String objectType, Cadence__c cad) {
       // TODO - change to use Cadence_Type__c instead of Sales_Org__c
       String ownerField = (cad != null ? ObjectHelper.getOwnerFieldName(objectType, translateCadenceType(cad.Cadence_Type__c)) : ObjectHelper.OWNER_FIELD);
       System.debug('getOwnerId ownerField='+ownerField+' cadence type='+(cad != null ? cad.Cadence_Type__c : 'null'));
       Id ownerId = ((ownerField != null && rec != null) ? (Id)rec.get(ownerField) : null);
       if (ownerId == null) {
          // default to this to get a value - should always be a value in OwnerId
          ownerId = (rec != null ? (Id)rec.get(ObjectHelper.OWNER_FIELD) : null);
          System.debug('getOwnerId using default option');
       }
       System.debug('getOwnerId ownerId='+ownerId);
       return ownerId;
    } // getOwnerId
    
    // Get the sales org equivalent (to use for ownership field)
    public static String translateCadenceType(String cadenceType) {
       String salesOrg = UserHelper.SO_CORE;
       if (String.isNotBlank(cadenceType)) {
          if (cadenceType == '401k') {
             salesOrg = UserHelper.SO_401;
          } else if (cadenceType == 'ASO') {
             salesOrg = UserHelper.SO_PEO_ASO;
          } else if (cadenceType == 'HNB') {
             salesOrg = UserHelper.SO_HNB;
          } else if (cadenceType == 'PEO') {
             salesOrg = UserHelper.SO_PEO;
          }
       } // if (String.isNotBlank(cadenceType
       return salesOrg;
    } // translateCadenceType
    
    public static RejectRecycleReasons getReasons() {
       RejectRecycleReasons reasons = (RejectRecycleReasons)CacheManager.getOrg('CadenceUpdateRejectRecycleReasons');
       if (reasons == null) {
          // pull the reasons from the picklist fields so we don't have to maintain them separately.
          reasons = new RejectRecycleReasons();
          Schema.DescribeFieldResult fieldResult = Lead.Recycle_Reason__c.getDescribe();
          List<Schema.PicklistEntry> entries = fieldResult.getPicklistValues();
        
          for( Schema.PicklistEntry entry : entries) {
             reasons.recycleReasons.add(entry.getLabel());
          }
          
          fieldResult = Lead.Reject_Reason__c.getDescribe();
          entries = fieldResult.getPicklistValues();
        
          for( Schema.PicklistEntry entry : entries) {
             reasons.rejectReasons.add(entry.getLabel());
          }
          CacheManager.putOrg('CadenceUpdateRejectRecycleReasons',reasons);
       } // if (reasons == null
       return reasons;
    } // getReasons
    
    public class RejectRecycleReasons {
       public Set<String> rejectReasons = new Set<String>();
       public Set<String> recycleReasons = new Set<String>();
    } // RejectRecycleReasons
    
   // TODO - what do we need to do here for Referral_Account__c? 
   // I don't think we need to do anything since we don't have reject/recycle fields on the Referral Account
   public static void checkForRejectRecycle(List<Id> carIds) {
      RejectRecycleReasons reasons = getReasons();
      Lead[] leadsToUpdate = new Lead[]{};
      Contact[] ctctsToUpdate = new Contact[]{};
       
      Map<Id,Cadence_Assignment_Record__c[]> carLeadMap = new Map<Id,Cadence_Assignment_Record__c[]>();
      Map<Id,Cadence_Assignment_Record__c[]> carCtctMap = new Map<Id,Cadence_Assignment_Record__c[]>();
      
      List<Cadence_Assignment_Record__c> cars = [Select Id, Status__c, CloseReason__c, ContactId__c, LeadId__c, Cadence__c, Cadence__r.Recycle_Lead_Contact__c
                                                      from Cadence_Assignment_Record__c where Id in:carIds];
      logDetail+= '\ncheckForRejectRecycle cars size= '+cars.size();
      for (Cadence_Assignment_Record__c car : cars) {
         logDetail+= '\ncheckForRejectRecycle cars CloseReason__c= '+car.CloseReason__c;
         if (String.isNotBlank(car.CloseReason__c)
              && ((reasons.recycleReasons.contains(car.CloseReason__c) || reasons.rejectReasons.contains(car.CloseReason__c))
                  || (CADENCE_COMPLETED.contains(car.CloseReason__c)
                     && car.Cadence__c!=null && car.Cadence__r.Recycle_Lead_Contact__c))) {
                 
            if (car.ContactId__c != null) {
               Cadence_Assignment_Record__c[] carList = (carCtctMap.containsKey(car.ContactId__c) ? carCtctMap.get(car.ContactId__c) : new Cadence_Assignment_Record__c[]{});
               carList.add(car);
               carCtctMap.put(car.ContactId__c,carList);
            } else if (car.LeadId__c != null) {
               Cadence_Assignment_Record__c[] carList = (carLeadMap.containsKey(car.LeadId__c) ? carLeadMap.get(car.LeadId__c) : new Cadence_Assignment_Record__c[]{});
               carList.add(car);
               carLeadMap.put(car.LeadId__c,carList);
            }
         }
      } // for (Cadence_Assignment_Record__c car : cars
      logDetail+= '\n checkForRejectRecycle carLeadMap='+carLeadMap.size() + 'carCtctMap= '+carCtctMap.size();
      if (!carLeadMap.isEmpty()) {
         checkRejectRecycleLeads(carLeadMap, reasons);
      }
      if (!carCtctMap.isEmpty()) {
         checkRejectRecycleCtcts(carCtctMap, reasons);
      }
   } // checkForRejectRecycle

  
    public static void checkRejectRecycleLeads(Map<Id,Cadence_Assignment_Record__c[]> carMap, RejectRecycleReasons reasons) {
       Lead[] lds = [Select Id, Recycle_Reason__c, Recycle_Stage_Date__c, Reject_Reason__c, Reject_Stage_Date__c, Lead_Stage__c from Lead where Id in :carMap.keySet()];
       logDetail += '\n checkRejectRecycleLeads lds size' + lds.size();
       for (Lead ld : lds) {
         logDetail+= '\n ld.Id='+ld.Id;
          Cadence_Assignment_Record__c[] cars = carMap.get(ld.Id);
          logDetail+= '\n Cars Size ='+cars.size();
          if (cars != null && !cars.isEmpty()) {
             // we will only use the first one even if there are multiple (which there shouldn't be)
             Cadence_Assignment_Record__c car = cars[0];
             logDetail+= '\n Lead_Stage__c ='+ ld.Lead_Stage__c+ ' carId ='+ car.Id+' CloseReason__c='+ car.CloseReason__c
                                 + ' Cadence Recycle lead/con ='+ car.Cadence__r.Recycle_Lead_Contact__c;
             
            if (reasons.recycleReasons.contains(car.CloseReason__c)) {
               logDetail+= '\n Enter setRecycleFields';
               setRecycleFields(ld, 'Lead_Stage__c', car.CloseReason__c);
            } else if (reasons.rejectReasons.contains(car.CloseReason__c)) {
               logDetail+= '\n Enter setRejectFields';
               setRejectFields(ld, 'Lead_Stage__c', car.CloseReason__c);
            }
            //if car closed is 'Cadence Completed' and stage is either MQL/TAL, recycle the lead
            if ((ld.Lead_Stage__c==MQL_STAGE || ld.Lead_Stage__c==TAL_STAGE) && CADENCE_COMPLETED.contains(car.CloseReason__c) && car.Cadence__r.Recycle_Lead_Contact__c){
               logDetail+= '\n Enter setRecycleFields for Cadence Completed';
                setRecycleFields(ld, 'Lead_Stage__c', car.CloseReason__c);
            }
          } // if (cars != null && !cars.isEmpty
       } // for (Lead ld : lds
       errLog = ErrorLog.logError('CadenceUpdate', 'checkRejectRecycleLeads', 'LOG_DATA', null, logDetail, null, false);
       // make sure the triggers fire
       TriggerMethods.forceTriggerSet.add('LeadBefore');
       TriggerMethods.forceTriggerSet.add('LeadAfter');
       DG_LMF_Service.ALREADY_RAN_SET.clear();
       DmlHelper.performDml2(lds, DmlHelper.DML_UPDATE, 'CadenceUpdate', 'checkRejectRecycleLeads', 'Update Leads', true);
       TriggerMethods.forceTriggerSet.clear();
       ErrorLog.checkSave();
    } // checkRejectRecycleLeads
    
    public static void checkRejectRecycleCtcts(Map<Id,Cadence_Assignment_Record__c[]> carMap, RejectRecycleReasons reasons) {
       Contact[] ctcts = [Select Id, Recycle_Reason__c, Recycle_Stage_Date__c, Reject_Reason__c, Reject_Stage_Date__c, Contact_Stage__c from Contact where Id in :carMap.keySet()];
       for (Contact ctct : ctcts) {
          Cadence_Assignment_Record__c[] cars = carMap.get(ctct.Id);
          if (cars != null && !cars.isEmpty()) {
             // we will only use the first one even if there are multiple (which there shouldn't be)
             Cadence_Assignment_Record__c car = cars[0];
             
            if (reasons.recycleReasons.contains(car.CloseReason__c)) {
               setRecycleFields(ctct, 'Contact_Stage__c', car.CloseReason__c);
            } else if (reasons.rejectReasons.contains(car.CloseReason__c)) {
               setRejectFields(ctct, 'Contact_Stage__c', car.CloseReason__c);
            }
            
            //if car closed is 'Cadence Completed' and stage is either MQL/TAL, recycle the Contact
            if ((ctct.Contact_Stage__c==MQL_STAGE || ctct.Contact_Stage__c==TAL_STAGE) && CADENCE_COMPLETED.contains(car.CloseReason__c) && car.Cadence__r.Recycle_Lead_Contact__c){
               setRecycleFields(ctct, 'Contact_Stage__c', car.CloseReason__c);
            }
          } // if (cars != null && !cars.isEmpty
       } // for (Lead ld : lds
       // make sure the triggers fire
       ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING=false;
       ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING=false;
       DG_LMF_Service.ALREADY_RAN_SET.clear();
       DmlHelper.performDml2(ctcts, DmlHelper.DML_UPDATE, 'CadenceUpdate', 'checkRejectRecycleCtcts', 'Update Leads', true);
    } // checkRejectRecycleCtcts
    
    public static void setRejectFields(SObject rec, String stageFldName, String closeReason) {
       rec.put(stageFldName,'Reject');
       rec.put('Reject_Stage_Date__c',Datetime.now());
       rec.put('Reject_Reason__c',closeReason);
    } // setRejectFields
    
    public static void setRecycleFields(SObject rec, String stageFldName, String closeReason) {
       rec.put(stageFldName,'Recycle');
       rec.put('Recycle_Stage_Date__c',Datetime.now());
       rec.put('Recycle_Reason__c',closeReason);
    } // setRecycleFields
    
    public static void checkWhenCadenceSet(Cadence_Assignment_Record__c[] cars) {
       Set<Id> cadenceIdSet = new Set<Id>();
       // collect the leads and contacts to check for TAL date (if it exists)
       // by default the expiration will be based off of that date.
       // TODO - this should probably be an option on the Cadence itself. 
       Set<Id> leadIdSet = new Set<Id>();
       Set<Id> ctctIdSet = new Set<Id>();
       
       for (Cadence_Assignment_Record__c car : cars) {
          if (car.Cadence__c != null) {
             cadenceIdSet.add(car.Cadence__c);
             if (car.ContactId__c != null) {
                ctctIdSet.add(car.ContactId__c);
             }
             if (car.LeadId__c != null) {
                leadIdSet.add(car.LeadId__c);
             }
          }
       } // for (Cadence_Assignment_Record__c car
        
       Map<Id,Cadence__c> cadenceMap = CadenceHelper.getCadences(cadenceIdSet);
        
       Boolean allOkay = true;
       // TODO - I think we're going to have to make changes here for Referral Accounts
       if (PERFORM_EXTRA_CHECK && Trigger.isInsert) {
           // if it's a sales rep entering a record on an insert, make sure the cadence type matches 
           User runningUser = UserHelper.getRunningUser();
           if (runningUser.Job_Name__c==UserHelper.JOB_REP) {
              for (Cadence_Assignment_Record__c car : cars) {
                 Cadence__c cad = cadenceMap.get(car.Cadence__c);
                 // do not enter this logic for Referral Accounts.
                 if (car.ReferralAccount__c == null && String.isNotBlank(cad.Cadence_Type__c) && cad.Cadence_Type__c != runningUser.User_Cadence_Type__c) {
                    car.Cadence__c.addError('You can only add a Cadence of type '+runningUser.User_Cadence_Type__c);
                    allOkay = false;
                 }
              }
           } // if (runningUser.Job_Name__c
       } // if (PERFORM_EXTRA_CHECK && Trigger.isInsert
       
       System.debug('checkWhenCadenceSet allOkay='+allOkay);
       if (!allOkay) {
          return;
       }
       
       Map<Id,Lead> leadMap = (leadIdSet.isEmpty() ? new Map<Id,Lead>()
                                : new Map<Id,Lead>([Select Id, Lead_stage__c, TAL_Stage_Date__c, TimeZoneAbbrev__c
                                                          ,(Select Id, CreatedDate
                                                                  ,Exited_Date_Time__c
                                                                  ,Expiration_Deadline__c
                                                                  ,ExpirationMinutes__c
                                                                  ,ExpirationProcessed__c
                                                                  ,ProcessNotes__c
                                                              From Stage_History__r
                                                             Where New_Stage__c='TAL'
                                                               and StageIsCurrent__c=true
                                                               and Expired__c=false)
                                                      from Lead
                                                     Where Id in :leadIdSet]));
                                                     
       Map<Id,Contact> ctctMap = (ctctIdSet.isEmpty() ? new Map<Id,Contact>()
                                : new Map<Id,Contact>([Select Id, Contact_Stage__c, TAL_Stage_Date__c, Account.TimeZoneAbbrev__c
                                                          ,(Select Id, CreatedDate
                                                                  ,Exited_Date_Time__c
                                                                  ,Expiration_Deadline__c
                                                                  ,ExpirationMinutes__c
                                                                  ,ExpirationProcessed__c
                                                                  ,ProcessNotes__c
                                                              From Stage_History__r
                                                             Where New_Stage__c='TAL'
                                                               and StageIsCurrent__c=true
                                                               and Expired__c=false)
                                                      from Contact
                                                     Where Id in :ctctIdSet]));
       
       System.debug('checkWhenCadenceSet cars='+cars.size()+' cadenceIdSet='+cadenceIdSet.size()+' cadenceMap='+cadenceMap.size());
       Map<Id,Stage_History__c> updateHistoryMap = new Map<Id,Stage_History__c>();
       
       // TODO - do we need to update calculateExpiration for Referral Account?
       for (Cadence_Assignment_Record__c car : cars) {
          Cadence__c cad = cadenceMap.get(car.Cadence__c);
          if (cad == null) {
             car.Cadence__c.addError('An Active Cadence could not be found for '+car.Cadence__c);
             continue;
          }
          if (String.isNotBlank(cad.Sales_Campaign_Name__c) && String.isBlank(car.Sales_Program__c)) {
             car.Sales_Program__c = cad.Sales_Campaign_Name__c;
          }
          System.debug('checkWhenCadenceSet car='+car.Name+' found cad='+(cad != null));
          if (cad != null && cad.DaysUntilExpiration__c != null && cad.DaysUntilExpiration__c > 0 && car.ExpirationDate__c == null) {
             calculateExpiration(car,cad,(car.LeadId__c != null ? leadMap.get(car.LeadId__c) : null)
                                        ,(car.ContactId__c != null ? ctctMap.get(car.ContactId__c) : null)
                                        ,updateHistoryMap);
          }
       } // for (Cadence_Assignment_Record__c car
       
       if (!updateHistoryMap.isEmpty()) {
          DmlHelper.performDml2(updateHistoryMap.values(), DmlHelper.DML_UPDATE, 'CadenceUpdate', 'checkWhenCadenceSet', 'Update Stage History Expiration', true);
       }
    } // checkWhenCadenceSet
    public static Boolean PERFORM_EXTRA_CHECK=(Label.CadenceUpdate_CheckCadenceType == 'Y');

   public static void calculateExpiration(Cadence_Assignment_Record__c car, Cadence__c cad, Lead ld, Contact ctct
                                         ,Map<Id,Stage_History__c> updateHistoryMap) {
      Stage_History__c hist = ((ctct != null && !ctct.Stage_History__r.isEmpty()) ? ctct.Stage_History__r[0]
                               : ((ld != null && !ld.Stage_History__r.isEmpty()) ? ld.Stage_History__r[0] : null));
      
      String recStage = (ctct != null ? ctct.Contact_Stage__c : (ld != null ? ld.Lead_Stage__c : null));
      Datetime talDate = (ctct != null ? ctct.TAL_Stage_Date__c : (ld != null ? ld.TAL_Stage_Date__c : null));
      String timeZoneAbbrev = (ctct != null ? ctct.Account.TimeZoneAbbrev__c : (ld != null ? ld.TimeZoneAbbrev__c : null));
       
      Datetime startDate = (cad.StartsWithTAL__c ? (hist != null ? hist.CreatedDate : (talDate != null) ? talDate : Datetime.now()) : Datetime.now());
      // if the start date is future dated, base the start date on that.
      if (car.Start_Date__c != null && car.Start_Date__c > Date.today()) {
          Integer daysBetween = Date.today().daysBetween(car.Start_Date__c);
          startDate = startDate.addDays(daysBetween);
      }
      
      BusinessHours busHours = DG_LMF_Service.getBusinessHours(timeZoneAbbrev, null);
      if (busHours == null) {
          return;
      }
      long nbrMinutes = Integer.valueOf(busMinutesInDay * cad.DaysUntilExpiration__c);
      car.ExpirationDate__c = BusinessHours.add(busHours.id , startDate, (nbrMinutes * 60000));
      String carNotes = 'Expire Start Date: '+startDate.format('M/d/yyyy H:mm')+' nbrMinutes='+nbrMinutes+' expireDate='+car.ExpirationDate__c.format('M/d/yyyy H:mm');
      StringHelper.addToProcessNotes(car, carNotes);
      //System.debug('hist:::'+hist);
      if (hist != null) {
          //System.debug('hist inside:::'+hist);
         car.StageHistory__c=hist.Id;
         //System.debug('hist.Expiration_Deadline__c:::'+hist.Expiration_Deadline__c);
         //System.debug(' car.ExpirationDate__c:::'+ car.ExpirationDate__c);
         if (hist.Expiration_Deadline__c != car.ExpirationDate__c) {
             //System.debug('hist inside if:::'+hist);
            String notes = 'Update Expiration from '+(hist.Expiration_Deadline__c != null ? hist.Expiration_Deadline__c.format('M/d/yyyy H:mm a') : 'null')+' to '+car.ExpirationDate__c.format('M/d/yyyy H:mm a');
            hist.Expiration_Deadline__c=car.ExpirationDate__c;
             //APR0119247
             hist.SLA_Deadline__c=null;
            StringHelper.addToProcessNotes(hist,notes);
            updateHistoryMap.put(hist.Id,hist);
         }
      } // if (hist != null                                            
   } // calculateExpiration

   public static final Integer DESCRIP_SIZE = Cadence_Assignment_Record__c.Description__c.getDescribe().getLength();
    
   public static void addToDescription(Cadence_Assignment_Record__c car, String valueToAdd) {
      // add the passed in value to the end of the description field
      String curValue = car.Description__c;
      String newValue = ((String.isNotBlank(curValue) ? curValue+'\n' : '') + valueToAdd).left(DESCRIP_SIZE);
      car.Description__c = newValue;
   } // addToDescription
    
    //Use this method to map Touchpoints to Account or Lead Company
    public static Set<Id> tpContactIds = new Set<Id>();
    public static Set<Id> tpLeadIds = new Set<Id>();
    public static void checkForEligibleContacts(List<Cadence_Touchpoint__c> tpList){
        Id[] acctIds = new Id[]{};
        Id[] leadIds = new Id[]{};
        Id[] refAcctIds = new Id[]{};
          Map<Id, Cadence_Touchpoint__c> touchpointMap = new Map<Id, Cadence_Touchpoint__c>();
        for (Cadence_Touchpoint__c tp : tpList) {
            if(tp.ContactId__c!=null){
                tpContactIds.add(tp.ContactId__c);
            }
            if(tp.AccountId__c!=null){
                acctIds.add(tp.AccountId__c);
                touchpointMap.put(tp.AccountId__c, tp);
            } else if (tp.LeadId__c != null && tp.LeadCompany__c!= null) {
                leadIds.add(tp.LeadId__c);
                tpLeadIds.add(tp.LeadId__c);
                touchpointMap.put(tp.LeadCompany__c, tp);
            } else if (tp.ReferralAccount__c != null) {
                refAcctIds.add(tp.ReferralAccount__c);
                touchpointMap.put(tp.ReferralAccount__c, tp);
            }
        } // for (Cadence_Touchpoint__c tp : tpList
        system.debug(tpList[0]+'tplist===');
        System.debug('checkForEligibleContacts acctIds='+acctIds.size()+' leadIds='+leadIds.size()+' refAcctIds='+refAcctIds.size());
        if(!acctIds.isEmpty() || !leadIds.isEmpty() || !refAcctIds.isEmpty()){
            if(tpList[0].StepType__c == 'Email' || tpList[0].StepType__c == 'Automated Email'){
            verifyEligibleContacts(acctIds, leadIds, refAcctIds, touchpointMap);
            }
            else if(tpList[0].StepType__c == 'Text'){
             verifyEligibleContactsForText(acctIds, leadIds, refAcctIds, touchpointMap);
            }
        }
    } //checkForEligibleContacts
    
    public static String EMAIL_AUTOSKIP_REASON='Auto Skipped Email: No eligible contacts were available to email';

    public static void verifyEligibleContacts(Id[] acctIds, Id[] leadIds, Id[] refAcctIds, Map<Id, Cadence_Touchpoint__c> touchpointMap){
        Account[] acctList = (acctIds.isEmpty() ? new Account[]{}
                                      : [Select Id, (Select Id from Contacts where EligibleToEmail__c = true limit 1) from Account where Id in :acctIds]);
        Lead_Company__c[] lcList = (leadIds.isEmpty() ? new Lead_Company__c[]{}
                                  : [Select Id, (Select Id from Leads__r where EligibleToEmail__c = true limit 1) 
                                       from Lead_Company__c where Id in (Select Lead_Company__c from Lead where Id in :leadIds)]);
        Referral_Account__c[] refAccts = (refAcctIds.isEmpty() ? new Referral_Account__c[]{}
                                    : [Select Id, (Select Id from Referral_Contacts__r where Contact__r.EligibleToEmail__c = true limit 1) 
                                         From Referral_Account__c where Id in :refAcctIds]);
        System.debug('verifyEligibleContacts acctIds='+acctIds.size()+' leadIds='+leadIds.size()+' refAcctIds='+refAcctIds.size());
        Cadence_Touchpoint__c[] skipTpList = new List<Cadence_Touchpoint__c>();
        for (Account acct : acctList) {
            checkTp(acct.Contacts.isEmpty(), touchpointMap.get(acct.Id), skipTpList);
        } // for(Account acct : acctList
        for (Lead_Company__c lc : lcList) {
            checkTp(lc.Leads__r.isEmpty(), touchpointMap.get(lc.Id), skipTpList);
        } // for (Lead_Company__c lc : lcList)
        
        for (Referral_Account__c refAcct : refAccts) {
            checkTp(refAcct.Referral_Contacts__r.isEmpty(), touchpointMap.get(refAcct.Id), skipTpList);
        } // for (Referral_Account__c refAcct
        System.debug('SKIP TP LIST: '+skipTpList);
        if(!skipTpList.isEmpty()){
         WorkQueueController.skipThisTouchpoint(skipTpList, EMAIL_AUTOSKIP_REASON,true);
      }
    } // verifyEligibleContacts
    
    public static String TEXT_AUTOSKIP_REASON;
	public static Map<Id, Cadence_Touchpoint__c> tpMap = new Map<Id, Cadence_Touchpoint__c>();
    public static Map<Id,Contact> tpContactMap;
    public static Map<Id,Lead> tpLeadMap;
    public static void verifyEligibleContactsForText(Id[] acctIds, Id[] leadIds, Id[] refAcctIds, Map<Id, Cadence_Touchpoint__c> touchpointMap){
        //APR0158122   
        /*for(Cadence_Touchpoint__c tp:[Select id,LeadId__c,ContactId__c,LeadId__r.Current_SMS_Owner__c,ContactId__r.Current_SMS_Owner__c from Cadence_Touchpoint__c where Id IN:tpIds]){
            tpMap.put(tp.id,tp);
        }*/
        Account[] acctList = (acctIds.isEmpty() ? new Account[]{}
                                      : [Select Id, (Select Id, SignificantContact__c,Current_SMS_Owner__c from Contacts where Consent_to_Text__c = true) from Account where Id in :acctIds]);
        Lead_Company__c[] lcList = (leadIds.isEmpty() ? new Lead_Company__c[]{}
                                  : [Select Id, (Select Id, SignificantLead__c,Current_SMS_Owner__c from Leads__r where Consent_to_Text__c = true) 
                                       from Lead_Company__c where Id in (Select Lead_Company__c from Lead where Id in :leadIds)]);
        Referral_Account__c[] refAccts = (refAcctIds.isEmpty() ? new Referral_Account__c[]{}
                                    : [Select Id, (Select Id, Contact__r.SignificantContact__c,Contact__r.Current_SMS_Owner__c from Referral_Contacts__r where Contact__r.Consent_to_Text__c = true) 
                                         From Referral_Account__c where Id in :refAcctIds]);
        if(tpContactIds!= null && !tpContactIds.isEmpty()){
            tpContactMap = new Map<Id,Contact>([Select Id,Current_SMS_Owner__c from Contact where Id IN:tpContactIds]);
        }
        if(tpLeadIds!= null && !tpLeadIds.isEmpty()){
            tpLeadMap = new Map<Id,Lead>([Select Id,Current_SMS_Owner__c from Lead where Id IN:tpLeadIds]);
        }
      /*  for(Contact cnt:[Select Id,Current_SMS_Owner__c from Contact where Id IN:tpContactIds]){
            tpContactMap.put(cnt.id,cnt);
        }
        
        for(Lead ld:[Select Id,Current_SMS_Owner__c from Lead where Id IN:tpLeadIds]){
            tpLeadMap.put(ld.id,ld);
        }*/
        System.debug('verifyEligibleContacts acctIds='+acctIds.size()+' leadIds='+leadIds.size()+' refAcctIds='+refAcctIds.size()+'lcList'+lcList.size());
        
        Cadence_Touchpoint__c[] skipTpList = new List<Cadence_Touchpoint__c>();
        for (Account acct : acctList) {
            checkTpText(acct.Contacts, touchpointMap.get(acct.Id), skipTpList);
        } // for(Account acct : acctList
        for (Lead_Company__c lc : lcList) {
            checkTpText(lc.Leads__r, touchpointMap.get(lc.Id), skipTpList);
        } // for (Lead_Company__c lc : lcList)
        
        for (Referral_Account__c refAcct : refAccts) {
            checkTpText(refAcct.Referral_Contacts__r, touchpointMap.get(refAcct.Id), skipTpList);
        } // for (Referral_Account__c refAcct
        System.debug('SKIP TP LIST: '+skipTpList+'lcList'+lcList);
        if(!skipTpList.isEmpty()){
         WorkQueueController.skipThisTouchpoint(skipTpList, TEXT_AUTOSKIP_REASON, true);
      }
    } // verifyEligibleContactsForText
    
    public static void checkTp(Boolean noContacts, Cadence_Touchpoint__c tp, Cadence_Touchpoint__c[] skipTpList) {
        if (tp != null) {
            tp.NoEmailEligibleContacts__c = tp.Ignore_DNE__c ? FALSE : noContacts;
            Boolean dueDateIsNow = tp.Due_Date__c <= DateTime.now();
            System.debug('checkTp noContacts='+noContacts+' tp.Cadence_Auto_Skip__c='+tp.Cadence_Auto_Skip__c+' dueDateIsNow='+dueDateIsNow+' tp.NoEmailEligibleContacts__c='+tp.NoEmailEligibleContacts__c);
             System.debug('tp.Override_Email__c='+tp.Override_Email__c);
        //    if (noContacts && tp.Cadence_Auto_Skip__c && dueDateIsNow) {
         if ((tp.NoEmailEligibleContacts__c && tp.Cadence_Auto_Skip__c && dueDateIsNow) ||  tp.Override_Email__c){
               skipTpList.add(tp);
            }
        } // if (tp != null
    } // checkTp
    public static String CALL_AUTOSKIP_REASON='Auto Skipped CALL: No eligible contacts were available to call';

   public static void checkCallSteps(List<Cadence_Touchpoint__c> tps){
   System.debug('checkCallSteps method entry'+tps);
      Cadence_Touchpoint__c[] skipTpList = new List<Cadence_Touchpoint__c>();
      if(!tps.isEmpty()){
         for(Cadence_Touchpoint__c tp: tps){
            System.debug('checkCallSteps before override check '+tp.Override_Call__c);
            if(tp.Override_Call__c){
               skipTpList.add(tp);
            }
         }    
      }
       System.debug('skipTpList '+skipTpList);
      if(!skipTpList.isEmpty()){
         WorkQueueController.skipThisTouchpoint(tps, CALL_AUTOSKIP_REASON,true);
      }
   } 
    //APR0158122 Added extra condition(Cadence Owner = Current SMS Owner) in checkTpText method to skip the text step for the user
    public static void checkTpText(sObject[] sObj, Cadence_Touchpoint__c tp, Cadence_Touchpoint__c[] skipTpList) {
        String significantField;
     
        if (tp != null) {
            //APR0158122
            Boolean skiptextSMSUser = false;
            Boolean isSignificantContactEligible = false;
            system.debug('tp.Cadence__r.Auto_Skip_Text_Steps__c'+tp.Cadence_Auto_Skip_Text_Steps__c);
            if(sObj.isEmpty()){
                TEXT_AUTOSKIP_REASON=tp.Cadence_Auto_Skip_Text_Steps__c == 'Evaluate All Contacts'?'Auto Skipped Text: No eligible contacts were available to text':'Auto Skipped Text: Significant contact not eligible to text';
                tp.NoTextEligibleContacts__c = true;
           
            }  //if(sObj.isEmpty
            if(tp.SignificantTextEligible__c == false && tp.Cadence_Auto_Skip_Text_Steps__c == 'Evaluate Significant Contact/Lead Only'){
                   TEXT_AUTOSKIP_REASON = 'Auto Skipped Text: Significant contact not eligible to text';
                    tp.NoTextEligibleContacts__c = true;
                 //   isSignificantContactEligible = true;
            }
       //     system.debug('tpContactMap = '+tpContactMap+''+'tpLeadMap = '+tpLeadMap);
       //     string txt = ([Select ContactId__r.Current_SMS_Owner__c from Cadence_Touchpoint__c Where id = :tp.id limit 1]).ContactId__r.Current_SMS_Owner__c;
       //     system.debug('ContactId__r111=='+tp.ContactId__r+'txt'+txt); 
        //   system.debug('UserInfo.getName()'+UserInfo.getUserId()+'tp.TypeFilter__c'+tp.TypeFilter__c+'tp.ContactId__r.Current_SMS_Owner__c'+(tpContactMap.get(tp.ContactId__c).Current_SMS_Owner__c)+'tp.ContactId__c'+tp.ContactId__c+'tpMap = '+tpContactMap); 
            if ( tp.TypeFilter__c == 'Text' &&
                    ((tp.LeadId__c != null && tpLeadMap!= null && !tpLeadMap.isEmpty() && tpLeadMap.containsKey(tp.LeadId__c) && String.isNotBlank(tpLeadMap.get(tp.LeadId__c).Current_SMS_Owner__c) && tpLeadMap.get(tp.LeadId__c).Current_SMS_Owner__c != UserInfo.getUserId()) ||
                (tp.ContactId__c != null && tpContactMap!= null && !tpContactMap.isEmpty() && tpContactMap.containsKey(tp.ContactId__c) && String.isNotBlank(tpContactMap.get(tp.ContactId__c).Current_SMS_Owner__c) && tpContactMap.get(tp.ContactId__c).Current_SMS_Owner__c != UserInfo.getUserId())
                )
               ) {
                   skiptextSMSUser = true;
               }
     
            System.debug('checkTp noContacts='+sObj.isEmpty() +' tp.Cadence__r.Auto_Skip_Text_Steps__c='+tp.Cadence__r.Auto_Skip_Text_Steps__c+ 'skiptextSMSUser='+ skiptextSMSUser);
             if((String.isNotBlank(tp.Cadence_Auto_Skip_Text_Steps__c) && ((tp.Cadence_Auto_Skip_Text_Steps__c == 'Evaluate All Contacts' && sObj.isEmpty()) || (tp.Cadence_Auto_Skip_Text_Steps__c == 'Evaluate Significant Contact/Lead Only' && tp.SignificantTextEligible__c == false))) || skiptextSMSUser) { 
               skipTpList.add(tp);
            }
        } // if (tp != null
    } // checkTpText  
    
       public static void closeTp(Map<Id, SObject> newMap, Map<Id, SObject> oldMap, Boolean isLead, Boolean isContact){
       Map<Id,Cadence_Touchpoint__c> tpToUpdate = new Map<Id,Cadence_Touchpoint__c>();
       Map<Id,Cadence_Assignment_Record__c> carsToUpdate = new Map<Id,Cadence_Assignment_Record__c>();

      Cadence_Touchpoint__c[] tps = [Select Id, 
                                                LeadId__c, 
                                                ContactId__c,
                                                Ignore_DNE__c, 
                                                Status__c, 
                                                StepType__c,
                                                Override_Call__c,
                                                Override_Email__c,
                                                CarRecord__c,
                                                CarRecord__r.Id,
                                                CarRecord__r.Status__c,
                                                CarRecord__r.Override_Call__c,
                                                CarRecord__r.Override_Email__c,
                                                LeadId__r.DoNotCall,
                                                LeadId__r.HasOptedOutOfEmail,
                                                ContactId__r.DoNotCall,
                                                ContactId__r.HasOptedOutOfEmail
                                             FROM Cadence_Touchpoint__c
                                             WHERE (LeadId__c IN: newMap.keyset()
                                                      or ContactId__c IN: newMap.keyset())];
     
      for(Cadence_Touchpoint__c tp: tps){
         SObject rec = isLead ? newMap.get(tp.LeadId__c): newMap.get(tp.ContactId__c);
         SObject oldRec= isLead ? oldMap.get(tp.LeadId__c): oldMap.get(tp.ContactId__c);
         Cadence_Assignment_Record__c car = new Cadence_Assignment_Record__c ();
        if(tp.Status__c!='Closed'){
            System.debug('tpclose::'+rec.get('HasOptedOutOfEmail'));
            System.debug(oldRec.get('HasOptedOutOfEmail'));
             System.debug(rec.get('DoNotCall'));
            System.debug(oldRec.get('DoNotCall'));
            System.debug(tp.StepType__c);
            
             if(rec.get('HasOptedOutOfEmail')==true && rec.get('DoNotCall')==true){                   
               tp.Status__c = 'Closed - Cadence Ended';
               tp.Skip_Reason__c = 'Do Not Contact is set during Cadence';
               car.Id = tp.CarRecord__c;
               tp.Override_Email__c = true;
               tp.Override_Call__c= true;
               car.Override_Email__c = true;
               car.Override_Call__c= true;
               String carNotes = 'Override Call & Email is set';
               StringHelper.addToProcessNotes(car, carNotes);

               tpToUpdate.put(tp.Id, tp);
               carsToUpdate.put(car.Id, car);
               break;
            }
             if (rec.get('DoNotCall') !=oldRec.get('DoNotCall') && rec.get('DoNotCall')==true ){
               if(tp.StepType__c =='Call'){
                  tp.Status__c = 'Closed';
                  tp.Skip_Reason__c = 'Do not Call is set during Cadence';
               }
               tp.Override_Call__c= true;
               car.Id = tp.CarRecord__c;
               car.Override_Call__c = true;
               String carNotes = 'Override Call is set';
               StringHelper.addToProcessNotes(car, carNotes);
               tpToUpdate.put(tp.Id, tp);
               carsToUpdate.put(car.Id, car);
            }
            if(rec.get('HasOptedOutOfEmail')!= oldRec.get('HasOptedOutOfEmail')&& rec.get('HasOptedOutOfEmail')==true){
               if(tp.StepType__c =='Email'){
                  tp.Status__c = 'Closed';
                  tp.Skip_Reason__c = 'Do not Email is set during Cadence';
               }
               tp.Override_Email__c = true;
               car.Id = tp.CarRecord__c;
               car.Override_Email__c = true;
               String carNotes = 'Override Email is set';
               StringHelper.addToProcessNotes(car, carNotes);
               tpToUpdate.put(tp.Id, tp);
               carsToUpdate.put(car.Id, car);
            }
         } 
       } 
       System.debug('CadenceUpdate closeTP carsToUpdate'+carsToUpdate);
       if(!carsToUpdate.isEmpty()){
           CadenceHelper.SKIP_TRIGGERS = true;
           DmlHelper.performDML(carsToUpdate.values(), DmlHelper.DML_UPDATE, 'CadenceUpdate', 'updateCars', 'update car checks based on DNC', true);
           CadenceHelper.SKIP_TRIGGERS = false;
       }
       if(!tpToUpdate.isEmpty()){
           DmlHelper.performDML(tpToUpdate.values(), DmlHelper.DML_UPDATE, 'CadenceUpdate', 'closeTp', 'Closing tps based on DNC', true);
       }
   }
    
} // class CadenceUpdate