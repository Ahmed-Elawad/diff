/* 
* Controller for the Cadence work queue lightning components
*
* History
* ------------------
05/21/2019  Jermaine Stukes     Created
08/09/2019  Dan Carmen          ParentZipCode__c field
08/21/2019  Jermaine Stukes     Updated Cadence History
09/03/2019  Jermaine Stukes     Added generateStepList Method
09/13/2019  Jermaine Stukes     Added method to get open touchpoint on account
10/14/2019  Jermaine Stukes     Added generateCloseReasonList
01/09/2020  Dan Carmen          Set the Significant on the parent object (account or lead company)
04/06/2020  Dan Carmen          Add ability to bypass/log BCC
07/22/2020  Dan Carmen          Change for setting the Latest Touchpoint.
09/01/2020  Jermaine Stukes     Added Time Zone filter
10/15/2020  Jermaine Stukes     Add Email Insights
11/04/2020  Jermaine Stukes     Updated Email Insights method
11/19/2020  Jermaine Stukes     Changed email insight process to trigger off a button
04/28/2020  Jermaine Stukes     Add sendEmailList method
05/05/2020  Jermaine Stukes     Update sendEmailList to return Wrapper
06/23/2021  Jermaine Stukes     Update skipThisTouchpoint logic to address INC2701936 
08/01/2021  Dan Carmen          Changes for SMB Channel Expansion
09/21/2021 Pujitha Madamanchi   APR0119247: open touchpoints to running user 
09/23/2021 Eric Porter          Removal of Time constraint on Email touchpoint filter
11/03/2021 Dan Carmen           Fix the sort order of the Today list
11/17/2021 Dan Carmen           Add debugging
01/04/2021 Pujitha Madamanchi   APR0130190: When car is closed, update Lead Stage
06/01/2022 Pujitha Madamanchi   APR0130779 : Remove Significant Lead/Contact
04/20/2022 Susmitha Somavarapu US27 ClearSlide (Existing Touchpoint main screen is updated for Prospects and Referral Contacts)
10/17/2023 Jaipal              APR0148811: Touchpoint Enhancement Added Consent_To_Text__c, TextEligible__c to query(ctcts)
01/17/2024 Reetesh Pandey	  	Update Sales contact from Service user
02/15/2024 Shilpa G				APR0166019/INC3635890: Updated method 'getOpenTouchpoints' to add additional check of Cadence Type Group of Sales-All Inbound
05/14/2024 Pratik Das	        APR0159917/APR0169069: New functionality in Touchpoint to indicate action required with an accept function
05/29/2024 Dan Carmen			Update to address INC3712493
*/

public without sharing class WorkQueueController {
    //Wrapper returned to work queue component
    public class TouchpointWrapper{
        @AuraEnabled public List<String> filterListCadence = new List<String>();
        @AuraEnabled public List<String> filterListTargetType = new List<String>();
        @AuraEnabled public List<String> filterListType = new List<String>();
        @AuraEnabled public List<String> filterTypeSalesProgram = new List<String>();
        @AuraEnabled public List<String> filterTypeZip = new List<String>();
        @AuraEnabled public List<String> filterTargetList = new List<String>();
        @AuraEnabled public List<String> filterStepList = new List<String>();
        @AuraEnabled public List<String> filterTimeZoneList = new List<String>();
        @AuraEnabled public String lastFilterCadence;
        @AuraEnabled public String lastFilterTouchpoint;
        @AuraEnabled public String lastFilterSalesProgram;
        @AuraEnabled public String lastFilterZip;
        @AuraEnabled public String lastFilterTarget;
        @AuraEnabled public String lastFilterStep;
        @AuraEnabled public String lastFilterTimeZone;
        @AuraEnabled public String lastFilterTargetType;
        @AuraEnabled public String emailLimit = Label.CadenceSendEmailLimit;
        @AuraEnabled public Boolean hasCallback=false;
        @AuraEnabled public Boolean pocUser=false;
        @AuraEnabled public List<Cadence_Touchpoint__c> touchpointList = new List<Cadence_Touchpoint__c>();
        @AuraEnabled public List<Cadence_Touchpoint__c> emailList = new List<Cadence_Touchpoint__c>();
        @AuraEnabled public Cadence_Touchpoint__c currentTouchpoint;
    }
    // class TouchpointTypeWrapper
    public class CarWrapper{
        public Cadence_Touchpoint__c touchpoint;
        Public String notes;
        //public Boolean repClosed = false;
        public Boolean started=false;
        public String ActivityUpdate;
        public String repCloseReason;        
        public String processNotes;
    }
   
    //Email Insight Wrappers
    public class InsightWrapper{
        @AuraEnabled public Id emailStatusId;
        @AuraEnabled public String contactName;
        @AuraEnabled public String templateName;
        @AuraEnabled public Boolean emailBounced;
        @AuraEnabled public DateTime dateSent;
        @AuraEnabled public Boolean opened;
        @AuraEnabled public DateTime lastOpenDate;
        @AuraEnabled public Integer timesOpened;
        @AuraEnabled public String emailAddress;
        @AuraEnabled public String fromName;
        @AuraEnabled public String subject;
    }

    public class ObjectInsightsWrapper{
        @AuraEnabled public List<Contact> contactList = new List<Contact>();
        @AuraEnabled public List<Lead> leadList = new List<Lead>();
        @AuraEnabled public List<InsightWrapper> insightsList;
    }

    public class EmailResponseWrapper{
        @AuraEnabled public String toastType;
        @AuraEnabled public String emailResponse;
    }
    
    @AuraEnabled
    public static String getCurrentUserId(){
        String currentUserId = Userinfo.getUserId();
        return currentUserId;
    }
    @AuraEnabled 
    public static TouchpointWrapper getTouchpointsList(String displayType, Cadence_Touchpoint__c returnTouchpoint){
        TouchpointWrapper returnWrapper = new TouchpointWrapper();
        List<PermissionSetAssignment> psa = [Select Id from PermissionSetAssignment where PermissionSet.Name='Cadence_Multi_Send_Email' and AssigneeId =:getCurrentUserId() limit 1];
        returnWrapper.pocUser = psa.isEmpty() ? false : true;
        List<Cadence_Touchpoint__c> openTouchList = getOpenTps(new Id[]{}, new Id[]{}, new Id[]{getCurrentUserId()}, null,displayType);
        getUserDefaults(returnWrapper);
        // the parent ids we've added to the list already.
        Set<Id> parentIdSet = new Set<Id>();
        System.debug('getTouchpointsList openTouchList='+openTouchList.size()+' displayType='+displayType);
        
        for(Cadence_Touchpoint__c touchpoint : openTouchList){   
            // get an id for this touchpoint. We only want to add 1 record per parentId to the list.
            Id parentId = (touchpoint.CarRecord__r.AccountId__c != null ? touchpoint.CarRecord__r.AccountId__c
                           : (touchpoint.CarRecord__r.LeadId__c != null ? touchpoint.CarRecord__r.LeadId__c
                               : (touchpoint.CarRecord__r.ReferralAccount__c != null ? touchpoint.CarRecord__r.ReferralAccount__c : null)));
            Boolean parentIdOkay = (parentId != null && !parentIdSet.contains(parentId));
            System.debug('getTouchpointsList parentIdSet='+parentIdSet+' parentIdOkay='+parentIdOkay+' parentIdSet='+parentIdSet.size());
            // callback notification if due today or earlier
            returnWrapper.hasCallback = (returnWrapper.hasCallback || (touchpoint.Due_Date__c != null && touchpoint.Due_Date__c.date() <= Date.today() && touchpoint.TypeFilter__c == 'Callback'));
            Boolean cadenceFilter = returnWrapper.lastFilterCadence == null || touchpoint.Cadence__r.Name == returnWrapper.lastFilterCadence ? true : false;
            //Boolean TouchpointFilter = returnWrapper.lastFilterTouchpoint == null || touchpoint.Cadence_Touchpoint_Step__r.Touchpoint_Type__c == returnWrapper.lastFilterTouchpoint ? true : false;
            Boolean touchpointFilter = returnWrapper.lastFilterTouchpoint == null || touchpoint.TypeFilter__c == returnWrapper.lastFilterTouchpoint ? true : false;
            Boolean SalesProgramFilter = returnWrapper.lastFilterSalesProgram == null || touchpoint.CarRecord__r.Sales_Program__c == returnWrapper.lastFilterSalesProgram ? true : false;
            Boolean ZipFilter = returnWrapper.lastFilterZip == null || touchpoint.CarRecord__r.ParentZipCode__c == returnWrapper.lastFilterZip ? true : false;
            Boolean targetFilter = returnWrapper.lastFilterTarget == null || touchpoint.CarRecord__r.TargetList__c == returnWrapper.lastFilterTarget ? true : false;
            Boolean targetFilterType = returnWrapper.lastFilterTargetType == null || touchpoint.Cadence__r.TargetType__c == returnWrapper.lastFilterTargetType ? true : false;
            

            Boolean stepFilter = returnWrapper.lastFilterStep == null || String.valueOf(touchpoint.Cadence_Touchpoint_Step__r.Step_Number__c) == returnWrapper.lastFilterStep ? true : false;
            Boolean timeZoneFilter = returnWrapper.lastFilterTimeZone == null || String.valueOf(touchpoint.CarRecord__r.TimeZoneAbbrev__c) == returnWrapper.lastFilterTimeZone ? true : false;
            //Boolean autoEmailFilter = !(touchpoint.Cadence_Touchpoint_Step__r.Automated_Email__c) || (touchpoint.Cadence_Touchpoint_Step__r.Automated_Email__c && touchpoint.Automated_Email_Process_Date__c != null) ? true : false;
            //
            if(parentIdOkay && cadenceFilter && touchpointFilter && SalesProgramFilter && ZipFilter && targetFilter && stepFilter && timeZoneFilter && targetFilterType){
                System.debug('getTouchpointsList adding '+parentId+' to the list');
                parentIdSet.add(parentId);
                //Update Touchpoint List
                returnWrapper.touchpointList.add(touchpoint);
                //Update Email List
                DateTime dueDatedt = touchpoint.Due_Date__c;
                Date dueDate = Date.newInstance(dueDatedt.year(),dueDatedt.month(),dueDatedt.day());
                if(touchpoint.Cadence_Touchpoint_Step__r.Touchpoint_Type__c == 'Email' && touchpoint.Due_Date__c != null && dueDate<= DateTime.now().date() && touchpoint.SignificantEmailEligible__c && touchpoint.Cadence_Touchpoint_Step__r.EmailTemplateIds__c != null){
                   returnWrapper.emailList.add(touchpoint);
                }
            }
            if(returnTouchpoint!=null && returnTouchpoint.id == touchpoint.Id){
                returnWrapper.currentTouchpoint = touchpoint;
            }
            //Update Filters
            //checkAddFilterValues(returnWrapper, touchpoint.Cadence_Touchpoint_Step__r.Touchpoint_Type__c, touchpoint.Cadence__r.Name, touchpoint.CarRecord__r.Sales_Program__c
            //                     ,touchpoint.CarRecord__r.ParentZipCode__c, touchpoint.CarRecord__r.TargetList__c);
            // updated filter added target type US 18 Clear Slide 
            checkAddFilterValues(returnWrapper, touchpoint.TypeFilter__c, touchpoint.Cadence__r.Name, touchpoint.CarRecord__r.Sales_Program__c
                                 ,touchpoint.CarRecord__r.ParentZipCode__c, touchpoint.CarRecord__r.TargetList__c, String.valueOf(touchpoint.Cadence_Touchpoint_Step__r.Step_Number__c), touchpoint.CarRecord__r.TimeZoneAbbrev__c, touchpoint.Cadence__r.TargetType__c);
        } // for(Cadence_Touchpoint__c touchpoint : openTouchList
        if(returnWrapper.currentTouchpoint == null){
            returnWrapper.currentTouchpoint = returnWrapper.touchpointList.isEmpty() ? null : returnWrapper.touchpointList[0];
        }
        returnWrapper.filterListCadence.sort();
        returnWrapper.filterListType.sort();
        returnWrapper.filterTypeSalesProgram.sort();
        returnWrapper.filterTypeZip.sort();
        returnWrapper.filterTargetList.sort();
        returnWrapper.filterStepList.sort();
        returnWrapper.filterTimeZoneList.sort();
        return returnWrapper;
    } // getTouchpointsList
    
    public static void checkAddFilterValues(TouchpointWrapper returnWrapper, String tpType, String cadenceName, String salesProgram, String zip, String targetList, String stepNbr, String timeZone, String trageType) {
        checkList(returnWrapper.filterListType, tpType);
        checkList(returnWrapper.filterListTargetType, trageType);
        checkList(returnWrapper.filterListCadence, cadenceName);
        checkList(returnWrapper.filterTypeSalesProgram, salesProgram);
        checkList(returnWrapper.filterTypeZip, zip);
        checkList(returnWrapper.filterTargetList, targetList);
        checkList(returnWrapper.filterStepList, stepNbr);
        checkList(returnWrapper.filterTimeZoneList, timeZone);
    } // checkAddFilterValues
    
    public static void checkList(String[] listValues, String valueToCheck) {
       if (String.isNotBlank(valueToCheck) && !listValues.contains(valueToCheck)) {
          listValues.add(valueToCheck);
       }
    } // checkList
       
    public static void getUserDefaults(TouchpointWrapper retWrapper) {
        CadenceUserSettings__c cus = getUserSettings();
        if (cus != null) {
            //UserSettingWrapper usw = new UserSettingWrapper(cus);
            retWrapper.lastFilterCadence = cus.FilterCadence__c; //checkFilterValue(usw, 'FilterCadence__c', retWrapper.filterListCadence);
            retWrapper.lastFilterTouchpoint = cus.FilterTouchpoint__c; //checkFilterValue(usw, 'FilterTouchpoint__c', retWrapper.filterListType);
            retWrapper.lastFilterSalesProgram = cus.FilterSalesProgram__c; //checkFilterValue(usw, 'FilterSalesProgram__c', retWrapper.filterTypeSalesProgram);
            retWrapper.lastFilterZip = cus.FilterZip__c; //checkFilterValue(usw, 'FilterZip__c', retWrapper.filterTypeZip);
            retWrapper.lastFilterTarget = cus.FilterTargetList__c;
            retWrapper.lastFilterStep = cus.FilterStep__c;
            retWrapper.lastFilterTimeZone = cus.FilterTimeZone__c;
            retWrapper.lastFilterTargetType = cus.FilterTargetType__c;
            // make sure the filter values are in the lists for consistency.
            checkAddFilterValues(retWrapper, retWrapper.lastFilterTouchpoint, retWrapper.lastFilterCadence, retWrapper.lastFilterSalesProgram
                                  ,retWrapper.lastFilterZip, retWrapper.lastFilterTarget, retWrapper.lastFilterStep, retWrapper.lastFilterTimeZone, retWrapper.lastFilterTargetType);
            /*if (usw.changed) {
                Database.update(usw.cus,false);
            }
            system.debug(retWrapper);*/
        } // if (cus != null
    } // setUserDefaults

    public static Cadence_Touchpoint__c[] getOpenTps(Id[] queryIds, Id[] queryIdOwners, Id[] allByOwnerId, Boolean onlyByPrimaryKey, String displayType) {
        queryIds = (queryIds == null ? new Id[]{} : queryIds);
        queryIdOwners = (queryIdOwners == null ? new Id[]{} : queryIdOwners);
        allByOwnerId = (allByOwnerId == null ? new Id[]{} : allByOwnerId);
        
         //APR0130779 : Remove Significant Lead/Contact
        String whereClause = '';
        Id queryId = null;
        if (!queryIds.isEmpty() && queryIds.size()==1 && queryIds[0].getSObjectType() == Cadence_Touchpoint__c.getSObjectType()) {
           queryId = queryIds[0];
           whereClause = ' Where Id=:queryId ';
        } else if (!queryIds.isEmpty() && onlyByPrimaryKey) {
           whereClause = ' Where Id in :queryIds ';
        } else if (!queryIds.isEmpty()) {
           whereClause = ' Where Status__c=\'Open\' '
               +' and (CarRecord__r.AccountId__c in :queryIds '
                    +' or CarRecord__r.ContactId__c in :queryIds '
                    +' or CarRecord__r.LeadId__c in :queryIds '
                    +' or CarRecord__r.ReferralAccount__c in :queryIds) ';
        } else if (!allByOwnerId.isEmpty()) {
            whereClause = ' Where Status__c=\'Open\' and OwnerId in :allByOwnerId';
        }
        if(displayType =='All Open Touchpoints'){
            Date thisDay = Date.today();
            DateTime queryDate = Datetime.newInstance(thisDay.year(), thisDay.month(), thisDay.day(), 23, 59, 59);
            String whereUpdate = (whereClause == '' ? ' Due_Date__c <= :queryDate' : ' and Due_Date__c <= :queryDate Order By Cadence__r.Priority__c DESC NULLS LAST, Due_Date__c ASC');
            whereClause += whereUpdate;
        }else 
        if(displayType=='Recent Touchpoints'){
            whereClause+=' And EmailLastOpenedDate__c != null Order By Cadence__r.Priority__c DESC NULLS LAST, EmailLastOpenedDate__c DESC';

        }else if(displayType =='Today\'s List'){
            Date thisDay = Date.today();
            DateTime queryDate = Datetime.newInstance(thisDay.year(), thisDay.month(), thisDay.day(), 23, 59, 59);
            whereClause+=' And Due_Date__c <= :queryDate Order By Cadence__r.Priority__c DESC NULLS LAST, Due_Date__c ASC';
        
        }else if(displayType =='Open Engagements'){
            whereClause+=' And EmailLastOpenedDate__c != null Order By Cadence__r.Priority__c DESC NULLS LAST, Number_of_Opens__c DESC';
        }
        if(Label.TouchpointRequestLimit!=null){
            Integer limitNumber = Integer.valueOf(Label.TouchpointRequestLimit);
            whereClause+=' Limit '+limitNumber;
        }
        String tpQuery = (String.isNotBlank(whereClause) ? getTpQuery()+whereClause : null);
        System.debug('getAllOpenTouchpoints tpQuery='+tpQuery);
        
        Cadence_Touchpoint__c[] touchpoints = (tpQuery != null ? Database.query(tpQuery) : new Cadence_Touchpoint__c[]{});
        //for (Cadence_Touchpoint__c tp : touchpoints) {
        //   System.debug('tp='+tp.Name+' Contact='+tp.CarRecord__r.ContactId__r);
        //}

        System.debug('getAllOpenTouchpoints queryIds='+queryIds.size()+' queryIdOwners='+queryIdOwners.size()+' allByOwnerId='+allByOwnerId.size()+' touchpoints='+touchpoints.size());
        return touchpoints;
    } // getOpenTps
    
    public static Cadence_Touchpoint__c[] getAllOpenTouchpoints(Id[] queryIds, Id[] queryIdOwners, Id[] allByOwnerId) {
        return (getOpenTps(queryIds, queryIdOwners, allByOwnerId, false,'All Open Touchpoints'));
    } // getAllOpenTouchpoints

    public static Cadence_Touchpoint__c[] getAllOpenTouchpoints(Id[] queryIds, Id[] queryIdOwners, Id[] allByOwnerId, Boolean onlyByPrimaryKey) {
        return (getOpenTps(queryIds, queryIdOwners, allByOwnerId, onlyByPrimaryKey,'All Open Touchpoints'));
    } // getAllOpenTouchpoints
    
    public static String extraFlds = '';
    public static String touchpointQuery=null;
    public static String TP_CACHEKEY='WorkQueueControllerTPCacheKey';
    public static String getTpQuery() {
        if (touchpointQuery == null) {
            touchpointQuery = (String)CacheManager.getOrg(TP_CACHEKEY);
        }
        if (touchpointQuery == null) {
            Set<String> fldSet = new Set<String>();
            // add fields from the touchpoint
            DmlHelper.addFieldsToSet(Schema.SObjectType.Cadence_Touchpoint__c.fieldSets.WorkQueueQuery, '', fldSet);
            DmlHelper.addFieldsToSet(Schema.SObjectType.Cadence_Touchpoint__c.fieldSets.WorkQueueQuery2, '', fldSet);
            DmlHelper.addFieldsToSet(Schema.SObjectType.Cadence_Assignment_Record__c.fieldSets.WorkQueueQuery, 'CarRecord__r.', fldSet);
            DmlHelper.addFieldsToSet(Schema.SObjectType.Referral_Account__c.fieldSets.WorkQueueQuery, 'CarRecord__r.ReferralAccount__r.', fldSet);
        fldSet.add('CarRecord__r.AccountId__r.Type'); 
            fldSet.add('CarRecord__r.AccountId__r.SignificantContact__c'); 
            fldSet.add('CarRecord__r.AccountId__r.SignificantContact__r.Name'); 
            fldSet.add('CarRecord__r.Cadence__r.TargetType__c'); 
         //APR0130779 : Remove Significant Lead/Contact
            DmlHelper.addFieldsToSet(Schema.SObjectType.Contact.fieldSets.WorkQueueQuery, 'CarRecord__r.ContactId__r.', fldSet);
            DmlHelper.addFieldsToSet(Schema.SObjectType.Lead.fieldSets.WorkQueueQuery, 'CarRecord__r.LeadId__r.', fldSet);
            touchpointQuery = DmlHelper.buildQueryFromSet(fldSet, 'Cadence_Touchpoint__c');
            CacheManager.putOrg(TP_CACHEKEY,touchpointQuery);
        
        }
        return touchpointQuery;
    } // getTpQuery
    
    public static Cadence_Touchpoint__c[] getOpenTouchpoints(Id ownerId) {
        Cadence_Touchpoint__c[] touchpoints = getAllOpenTouchpoints(new Id[]{}, new Id[]{}, new Id[]{ownerId});
        
        return touchpoints;
    } // getOpenTouchpoints

    @AuraEnabled
    public static ObjectInsightsWrapper getInsightList(Cadence_Touchpoint__c touchpoint, Boolean onlyQueryContacts){
        return generateInsightList(touchpoint,onlyQueryContacts);
    } // ObjectInsightsWrapper

    public static ObjectInsightsWrapper generateInsightList(Cadence_Touchpoint__c touchpoint, Boolean onlyQueryContacts){
        ObjectInsightsWrapper oiwrap = new ObjectInsightsWrapper();
        Map<Id, sObject> recMap = new Map<Id, sObject>();
        //Limit the number of Email Statuses retrieved
        Integer emailStatusLimit = Integer.valueOf(Label.CadenceEmailStatusLimit);
        Integer ListQueryLimit = Integer.valueOf(Label.CadenceListQueryLimit);
        Date dateForQuery = System.Today().addDays(Integer.valueOf(Label.CadenceEmailStatusDaystoQuery));
        Boolean queryEmailStatus = Boolean.valueOf(Label.CadenceTurnOnStatusLogic);
        EmailStatus[] statusList = new EmailStatus[]{};
        Id acctId = touchpoint.AccountId__c;
        // if it's a referral account, we'll select the contacts linked to the mirrored account
        if (acctId == null && touchpoint.ReferralAccount__c != null) {
           acctId = touchpoint.CarRecord__r.ReferralAccount__r.Account__c;
        }
        
        String[] SECONDARYOWNER_MANAGER_PROFS=Label.CadenceManager_SecondaryMngrProfiles.split(',');
        String[] SECONDARYOWNER_USER_PROFS=Label.CadenceManager_SecondaryUsrProfiles.split(',');
        Set<String> profileSet = new Set<String>();
        profileSet.addAll(SECONDARYOWNER_MANAGER_PROFS);
        profileSet.addAll(SECONDARYOWNER_USER_PROFS);
        User runningUser = UserHelper.getRunningUser();        
        Boolean chkUser = profileSet.contains(runningUser.Profile.Name);
        
        if (acctId != null) {
           Contact[] ctcts = [Select Id, Name, Title, Email, EmailBouncedDate, EmailBouncedReason, Consent_To_Text__c, TextEligible__c
                                    ,FirstName, HasOptedOutOfEmail, LastName, Phone, MobilePhone, Decision_Maker__c,LastModifiedDate,Sales_Contact__c
                                    ,(Select Id, TaskId, CreatedDate, TimesOpened, FirstOpenDate, LastOpenDate, EmailTemplateName, WhoId 
                                        from EmailStatuses 
                                       where CreatedDate >:dateForQuery order by CreatedDate desc limit :emailStatusLimit)                                   
                                from Contact
                               where AccountId=:acctId
                                // and Sales_Contact__c=true
                                 and No_Longer_With_Company__c =false
                                 and DoNotCall = false
                               order by Decision_Maker__c desc, LastModifiedDate desc//,LastName, FirstName
                               limit :ListQueryLimit];
           for (Contact ctct : ctcts) {
              if ((queryEmailStatus && !onlyQueryContacts ) && (ctct.Sales_Contact__c || (!ctct.Sales_Contact__c && chkUser))) {
                 recMap.put(ctct.id,ctct);
                 statusList.addAll(ctct.EmailStatuses);
              } // if (queryEmailStatus && !onlyQueryContacts
              // we don't need to save these in the object - less to transport back
              ctct.EmailStatuses.clear();
              //APR0130779 : Remove Significant Lead/Contact
              //if (ctct.Id != touchpoint.CarRecord__r.SignificantContact__c){
              if (ctct.Id != touchpoint.CarRecord__r.ContactId__c && (ctct.Sales_Contact__c || (!ctct.Sales_Contact__c && chkUser))){
                 oiwrap.contactList.add(ctct);
              }
           } // for (Contact ctct : ctcts
            
        } else if (touchpoint.LeadId__c != null && touchpoint.CarRecord__r.LeadCompanyId__c != NULL) {
           Lead[] leads = [Select Id, Name, Title, Email, EmailBouncedDate, EmailBouncedReason, FirstName
                                 ,HasOptedOutOfEmail, LastName, Phone, MobilePhone, Lead_Company__c, LastModifiedDate
                                 ,(Select Id, TaskId, CreatedDate, TimesOpened, FirstOpenDate, LastOpenDate, EmailTemplateName, WhoId  
                                     from emailStatuses 
                                    where CreatedDate >:dateForQuery order by CreatedDate desc limit :emailStatusLimit)
                             from Lead
                            where Lead_Company__c =: touchpoint.CarRecord__r.LeadCompanyId__c
                              and No_Longer_With_Company__c =false
                              and DoNotCall = false
                            order by LastName, FirstName
                            limit :ListQueryLimit];
           for (Lead ld : leads) {
              if (queryEmailStatus && !onlyQueryContacts) {
                 recMap.put(ld.id,ld);
                 statusList.addAll(ld.EmailStatuses);
              } // if (queryEmailStatus && !onlyQueryContacts
              // we don't need to save these in the object - less to transport back
              ld.EmailStatuses.clear();
              //APR0130779 : Remove Significant Lead/Contact
              //if (ld.Id != touchpoint.CarRecord__r.SignificantLead__c){
              if (ld.Id != touchpoint.CarRecord__r.LeadId__c){
                 oiwrap.leadList.add(ld);
              }
           } // for (Lead ld : leads
        } // if (touchpoint.LeadId__c != null
  
        if (!recMap.isEmpty() && !statusList.isEmpty()) {
           oiwrap.insightsList = generateInsightList(recMap,statusList);
        }
          
        return oiwrap;
     } // generateInsightList
  
  public static List<InsightWrapper> generateInsightList(Map<Id, sObject> recMap, List<EmailStatus> statusList){
    List<InsightWrapper> insightWrapList = new List<InsightWrapper>();
        Integer ListQueryLimit = Integer.valueOf(Label.CadenceListQueryLimit);
        List<Id> emailIdList = new List<Id>();
        Map<Id, EmailMessage> messageMap = new Map<Id, EmailMessage>();
        List<EmailMessageRelation> emrList = [Select Id,EmailMessageId,RelationId from EmailMessageRelation where RelationId in :recMap.keySet() ];
        for(EmailMessageRelation emr : emrList){
            emailIdList.add(emr.EmailMessageId);
        }
        List<EmailMessage> emList = [Select Id, ActivityId, ToAddress, FromAddress, FromName, Status, Subject from EmailMessage where Id in:emailIdList ];
        for(EmailMessage em : emList){
            messageMap.put(em.ActivityId,em);
        }
        for(EmailStatus emailInsights : statusList){
            if(ListQueryLimit > insightWrapList.size()){
                InsightWrapper insightWrap = new InsightWrapper();
                sObject rec = recMap.get(emailInsights.whoId);
                EmailMessage message =  messageMap.get(emailInsights.TaskId);
                insightWrap.subject = message.Subject;
                insightWrap.fromName = message.FromName;
                insightWrap.emailStatusId = emailInsights.Id;
                insightWrap.contactName = (String)rec.get('FirstName')+' '+(String)rec.get('LastName');
                insightWrap.emailAddress = (String)rec.get('Email');
                insightWrap.templateName = emailInsights.EmailTemplateName;
                insightWrap.opened = emailInsights.FirstOpenDate == null ? false :true;
                insightWrap.timesOpened = emailInsights.TimesOpened;
                insightWrap.lastOpenDate = emailInsights.LastOpenDate;
                insightWrap.dateSent = emailInsights.CreatedDate;
                insightWrapList.add(insightWrap);
            }
            else{
                break;
            }
        }
        return insightWrapList;
    } // generateInsightList

    @AuraEnabled
    public static Contact queryContact(Id p_ctctId) {
       Contact ctct=null;
       try {
          Id ctctId = p_ctctId;
          Set<String> fldSet = new Set<String>();
          DmlHelper.addFieldsToSet(Schema.SObjectType.Contact.fieldSets.WorkQueueQuery, '', fldSet);
          String query = DmlHelper.buildQueryFromSet(fldSet,'Contact')+' where Id=:ctctId';
          ctct = Database.query(query);
       } catch (Exception e) {
          System.debug('queryContact e='+e.getMessage());
       }
       return ctct;
    } // queryContact
    
    @AuraEnabled
    public static Lead queryLead(Id p_leadId) {
        Lead ld = null;
        try {
          Id leadId = p_leadId;
          Set<String> fldSet = new Set<String>();
          DmlHelper.addFieldsToSet(Schema.SObjectType.Lead.fieldSets.WorkQueueQuery, '', fldSet);
          String query = DmlHelper.buildQueryFromSet(fldSet,'Lead')+' where Id=:leadId';
          //  ld = [Select Id, Name, Phone, MobilePhone, Company, Street, City, State, PostalCode, LeadGroupId__c,Lead_Company__c  
          //              ,SignificantLead__c, NumberOfEmployees, Current_Prior_Method__c,Industry,X401K_Assets__c
          //          from Lead where Id=:leadId];
          ld = Database.query(query);
        } catch (Exception e) {
            System.debug('queryLead e='+e.getMessage());
        }
        return ld;
    } // queryLead
    
    @AuraEnabled 
    public static List<Cadence_Step__c> generateStepList(Id CadId){
        List<Cadence_Step__c> cadStepList = [Select Id, Name, Step_Number__c from Cadence_Step__c where CadenceId__c =:CadId Order by Step_Number__c];
        return cadStepList;
    }
    
    // retrieve a touchpoint for a specific record (account/contact/lead)
    @AuraEnabled
    public static Cadence_Touchpoint__c retrieveOpenTouchpoint(String parentId) {
         Cadence_Touchpoint__c openTouchpoint = null;
      if (String.isNotBlank(parentId)) {
         System.debug('retrieveOpenTouchpoint parentId='+parentId);
        Id parentAsId = (Id)parentId;
         // if we enter for a referral contact, find the referral account id
         if (parentAsId.getSObjectType() == Referral_Contact__c.sObjectType) {
            System.debug('retrieveOpenTouchpoint retrieving referral contact to get referral account id');
            try {
               Referral_Contact__c refCtct = [Select Id, Referral_Account__c from Referral_Contact__c where Id=:parentAsId];
               parentAsId = (refCtct.Referral_Account__c != null ? refCtct.Referral_Account__c : parentAsId);
            } catch (Exception e) {
               System.debug('retrieveOpenTouchpoint exception: '+e.getMessage());
            }
         }
        
         Map<Id,Cadence_Touchpoint__c> tpMap = getOpenTouchpoints(new Id[]{parentAsId}, new Id[]{UserInfo.getUserId()});
         openTouchpoint = tpMap.get(parentAsId);
      } // if (String.isNotBlank(parentId
        return openTouchpoint;
    } // retrieveOpenTouchpoint
    
    public static Boolean checkQueueOwner(Id queueId, Id[] ownerIds) {
       System.debug('checkQueueOwner queueId='+queueId+' ownerIds='+ownerIds);
       Boolean ownerOkay = false;
       Set<Id> queueUserSet = GroupMemberHelper.getActiveUserIds(queueId);
       for (Id checkid : ownerIds) {
          ownerOkay = (ownerOkay || queueUserSet.contains(checkId));
       }
       System.debug('checkQueueOwner ownerOkay='+ownerOkay);
       return ownerOkay;
    } // checkQueueOwner
    
    public static Map<Id,Cadence_Touchpoint__c> getOpenTouchpoints(Id[] queryIds, Id[] ownerIds) {
        checkForContactIds(queryIds);
        Cadence_Touchpoint__c[] touchpoints = getAllOpenTouchpoints(queryIds, ownerIds, new Id[]{});
         //APR0119247
        Set<String> cadenceTypeSet = new Set<String>();
        runningUser = UserHelper.getRunningUser();
        if (!ownerIds.isEmpty()) {
            User[] checkUsers = [Select Id, Email, User_Cadence_Type__c from User where Id in :ownerIds and User_Cadence_Type__c != null];  
            for (User usr :checkUsers ) {
                cadenceTypeSet.add(usr.User_Cadence_Type__c);
            }
            
        }
        System.debug('getOpenTouchpoints touchpoints='+touchpoints.size()+' cadenceTypeSet='+cadenceTypeSet.size());
        Map<Id,Cadence_Touchpoint__c> tpMap = new Map<Id,Cadence_Touchpoint__c>();
        for (Cadence_Touchpoint__c tp : touchpoints) {
            // check for if owner is a queue and cadence type matches running user or owner matches passed in ownerIds
            Boolean ownedByQueue = ((String)tp.OwnerId).left(3) == ObjectHelper.PREFIX_GROUP ? true : false;
            Set<Id> queueUserIds = new Set<Id>();
            // we're only doing this check if it comes from an object page. If we wanted to check for more than one record at a time,
            // this would have to be pulled out of the loop
            Boolean queueOwnerOkay = false;
            if (ownedByQueue && queryIds != null && queryIds.size() == 1) {
               queueOwnerOkay = checkQueueOwner(tp.OwnerId, ownerIds);
            }
            //if (objPrefix == ObjectHelper.PREFIX_CONTACT) {
           //APR0119247
           if ((ownerIds == null || ownerIds.isEmpty()) 
                || ownerIds.contains(tp.OwnerId)
                //|| ownerIds.contains(tp.CarRecord__r.CreatedById)
                || queueOwnerOkay
                || (ownedByQueue && cadenceTypeSet.contains(tp.Cadence__r.Cadence_Type__c))
                || (tp.Cadence__r.CadenceTypeGroup__c == runningUser.User_Cadence_Type_Group__c && Label.Sales_Inbound_Cadence_Type.contains(tp.Cadence__r.CadenceTypeGroup__c))) 
               {
                    // save the touchpoint in the map for reference
                    tpMap.put(tp.Id,tp);
                    if (tp.CarRecord__r.AccountId__c != null && !tpMap.containsKey(tp.CarRecord__r.AccountId__c)) {
                        tpMap.put(tp.CarRecord__r.AccountId__c,tp);
                    }
             //APR0130779 : Remove Significant Lead/Contact
                    if (tp.CarRecord__r.ContactId__c != null && !tpMap.containsKey(tp.CarRecord__r.ContactId__c)) {
                        tpMap.put(tp.CarRecord__r.ContactId__c,tp);
                    }
                    if (tp.CarRecord__r.LeadId__c != null && !tpMap.containsKey(tp.CarRecord__r.LeadId__c)) {
                        tpMap.put(tp.CarRecord__r.LeadId__c,tp);
                    }
                    if (tp.CarRecord__r.ReferralAccount__c != null && !tpMap.containsKey(tp.CarRecord__r.ReferralAccount__c)) {
                        tpMap.put(tp.CarRecord__r.ReferralAccount__c,tp);
                    }
                } // if (ownerIds
        } // for (Cadence_Touchpoint__c tp
        System.debug('getOpenTouchpoints queryIds='+queryIds.size()+' touchpoints='+touchpoints.size()+' tpMap='+tpMap.size());
        return tpMap;
    } // getOpenTouchpoints
    
    // if we have contact ids, also retrieve the account ids
    public static void checkForContactIds(Id[] queryIds) {
        Id[] ctctIds = new Id[]{};
            for (Id chkId : queryIds) {
                if (((String)chkId).startsWith(ObjectHelper.PREFIX_CONTACT)) {
                    ctctIds.add(chkId);
                }
            } // for (Id chkId : queryIds
        Contact[] ctcts = (ctctIds.isEmpty() ? new Contact[]{}
                           : [Select Id, Name, AccountId from Contact where Id in :ctctIds]);
        
        for (Contact ctct : ctcts) {
            if (ctct.AccountId != null && !queryIds.contains(ctct.AccountId)) {
                queryIds.add(ctct.AccountId);
            }
        } // for (Contact ctct : ctcts
    } // checkForContactIds
    
    @AuraEnabled
    public static ActivityHelper.ActWrap[] getActivity(Cadence_Touchpoint__c touchpoint) {
        Id recId = null;
        if (touchpoint != null && touchpoint.CarRecord__r != null) {
            recId = (touchpoint.CarRecord__r.AccountId__c != null ? touchpoint.CarRecord__r.AccountId__c : touchpoint.CarRecord__r.LeadId__c);
        }
        if (recId != null) {
            return ActivityHelper.getLatestActivity(recId);
        }
        return new ActivityHelper.ActWrap[]{};
    } // getActivity
    
    @AuraEnabled
    public static SObject generateParentData(Cadence_Touchpoint__c touchpoint){
        SObject retRecord = null;
        //System.debug('generateParentData touchpoint='+touchpoint);
        //System.debug('generateParentData car='+touchpoint.CarRecord__r);
        
        try {
            if (touchpoint != null && touchpoint.CarRecord__r != null && touchpoint.CarRecord__r.AccountId__c != null) {
                Account acct = [Select Id, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode
                                ,NumberOfEmployees, Employees__c, Industry, Current_Prior_Method__c, Type, X401K_Assets__c
                                //,(Select Id, Subject, ActivityDate, ActivityDateTime, Status, Priority, ActivityType, Description, WhoId, Who.Name, WhatId 
                                //    from OpenActivities Order By ActivityDate DESC, LastModifiedDate DESC limit 1)
                                //,(Select Id, Subject, ActivityDate, ActivityDateTime, Status, Priority, ActivityType, Description, WhoId, Who.Name, WhatId 
                                //    from ActivityHistories Order By ActivityDate DESC, LastModifiedDate DESC limit 1) 
                                from Account where Id =:touchpoint.CarRecord__r.AccountId__c];        
                System.debug('generateParentData acct='+ acct);
                retRecord = acct;
            } else if (touchpoint != null && touchpoint.CarRecord__r != null && touchpoint.CarRecord__r.LeadId__c != null) {
                Lead ld = [Select Id, Name, Company, Street, City, State, PostalCode
                           ,NumberOfEmployees, Industry, Current_Prior_Method__c, Status, X401K_Assets__c
                           //,(Select Id, Subject, ActivityDate, ActivityDateTime, Status, Priority, ActivityType, Description, WhoId, Who.Name, WhatId 
                           //    from OpenActivities Order By ActivityDate ASC, LastModifiedDate DESC limit 1)
                           //,(Select Id, Subject, ActivityDate, ActivityDateTime, Status, Priority, ActivityType, Description, WhoId, Who.Name, WhatId 
                           //    from ActivityHistories Order By ActivityDate DESC, LastModifiedDate DESC limit 1) 
                           from Lead where Id =:touchpoint.CarRecord__r.LeadId__c]; 
                System.debug('generateParentData ld='+ld);
                retRecord = ld;
            }
        } catch (Exception e) {
            System.debug('generateParentData touchpoint='+touchpoint);
            System.debug('generateParentData Exception: '+e.getMessage());
        }
        return retRecord;
    } // generateParentData
    
    @AuraEnabled
    public static void apexUpdateSignificant(Cadence_Touchpoint__c touchpoint, String recordIdStr) {
        Id recordId = null;
        try {
           recordId = (Id)recordIdStr;
        } catch (Exception e) {
           System.debug('apexUpdateSignificant e='+e.getMessage());
           return;
        }
        //APR0130779 : Remove Significant Lead/Contact
        Cadence_Assignment_Record__c carRec = [Select Id
                                               ,AccountId__c
                                               ,AccountId__r.Id
                                               ,AccountId__r.SignificantContact__c
                                               ,LeadId__c
                                               ,LeadId__r.Id
                                               ,LeadId__r.Lead_Company__r.Id
                                               ,LeadId__r.Lead_Company__r.SignificantLead__c
                                               ,ContactId__c
                                               /*,SignificantContact__c
                                               ,SignificantLead__c */
                                               from Cadence_Assignment_Record__c 
                                               where Id=:touchpoint.CarRecord__c limit 1]; 
        System.debug('updateSignificant recordIdStr='+recordIdStr); 
        String objPrefix = recordIdStr.left(3);
        if (objPrefix == ObjectHelper.PREFIX_CONTACT) {
            //APR0130779 : Remove Significant Lead
            //carRec.SignificantContact__c = recordId;
            carRec.ContactId__c = recordId;
            CadenceHelper.SKIP_TRIGGERS=true;
            update carRec;
            if (carRec.AccountId__c != null && carRec.AccountId__r != null
                && carRec.AccountId__r.SignificantContact__c != recordId) {
                    carRec.AccountId__r.SignificantContact__c = recordId;
                    ZipCheckOwner.SKIP_TRIGGERS=true;
                    update carRec.AccountId__r;
                }
            Contact updateCon = [Select id,Sales_Contact__c from Contact where id =:recordId limit 1];               
            if(!(updateCon.Sales_Contact__c)){
                 updateCon.Sales_Contact__c =true; 
                 update updateCon;
             }
        } 
       //APR0130779 : Remove Significant Lead 
        else if (objPrefix == ObjectHelper.PREFIX_LEAD) {
            //carRec.SignificantLead__c = recordId; 
            carRec.LeadId__c = recordId; 
            CadenceHelper.SKIP_TRIGGERS=true;
            update carRec;
            // update the value on the lead company
            if (carRec.LeadId__c != null && carRec.LeadId__r != null 
                && carRec.LeadId__r.Lead_Company__r != null 
                && carRec.LeadId__r.Lead_Company__r.SignificantLead__c != recordId) {
                    Lead_Company__c leadComp = carRec.LeadId__r.Lead_Company__r;
                    leadComp.SignificantLead__c = recordId;
                    LeadCompanyMethods.SKIP_TRIGGER = true;
                    update leadComp;
                } 
        }
    } // apexUpdateSignificant
    
    @AuraEnabled
    public static void updateOwner(Cadence_Touchpoint__c touchpoint, Boolean updateAll){
        touchpoint.OwnerId = Userinfo.getUserId();
        update touchpoint;
        if(updateAll){
            touchpoint.CarRecord__r.OwnerId = Userinfo.getUserId();
            update touchpoint.CarRecord__r;
        }
        String activityDetail = updateAll ? Userinfo.getName()+' has taken ownership of all cadence touchpoints' : Userinfo.getName()+' has taken ownership of Touchpoint: '+touchpoint.Cadence_Touchpoint_Step__r.Name;
        CarWrapper updateWrapper = new CarWrapper();
        updateWrapper.touchpoint = touchpoint;
        updateWrapper.ActivityUpdate = activityDetail;
        updateCarRecord(updateWrapper, true);        
    }
    
    @AuraEnabled
    public static void updateSigContact(Cadence_Touchpoint__c touchpoint, String conToUpdate){
        //APR0130779 : Remove Significant Lead/Contact
        Cadence_Assignment_Record__c carRec = [Select Id, ContactId__c, LeadId__c from Cadence_Assignment_Record__c where Id=:touchpoint.CarRecord__c limit 1]; 
        if(touchpoint.TouchpointObject__c == 'Lead'){
            if(conToUpdate != carRec.LeadId__c){
                carRec.LeadId__c = conToUpdate;
                update carRec;
            }
        }else{
            if(conToUpdate != carRec.ContactId__c){
                carRec.ContactId__c = conToUpdate;
                update carRec;
            }
        }       
    }
    
    public static Boolean ALLOW_BCC=(Label.CadenceAllowBCC == 'Y');
    
    // ability to preview an email template
    @AuraEnabled
    public static String previewEmailWithTargetId(Cadence_Touchpoint__c touchpoint, String targetId, String emailTemplateId, String emailExtra) {
       System.debug('previewEmail targetId='+targetId+' emailTemplateId='+emailTemplateId);
       // needs to save this so it displays on the template.
       checkEmailExtra(touchpoint, emailExtra);

       EmailTemplate template = null;
       System.debug('previewEmail emailTemplateId='+emailTemplateId);
       try {
          template = [Select Id, Name from EmailTemplate where Id=:emailTemplateId];
       } catch (Exception e) {
          // what do we need to do here? Can't preview without a template
          System.debug('previewEmail could not find a template for id='+emailTemplateId+' e='+e.getMessage());
          return null;
       }
       System.debug('previewEmail targetId='+targetId+' template='+template);
       Messaging.SingleEmailMessage emailPreview = Messaging.renderStoredEmailTemplate(emailTemplateId, targetId, touchpoint.Id);
       //String emailBody = emailPreview.getPlainTextBody();
       String emailBody = emailPreview.getHtmlBody();
       if (String.isBlank(emailBody)) {
          emailBody = emailPreview.getPlainTextBody();
       }
       System.debug('previewEmail emailBody='+emailBody);
       return emailBody;
    } // previewEmailWithTargetId
     
    // ability to preview an email template
    @AuraEnabled
    public static String previewEmail(String mMail ,Cadence_Touchpoint__c touchpoint, String emailTemplateId, String emailExtra) {
       checkEmailExtra(touchpoint, emailExtra);
       EmailTemplate template = null;
       System.debug('previewEmail emailTemplateId='+emailTemplateId);
       try {
          template = [Select Id, Name from EmailTemplate where Id=:emailTemplateId];
       } catch (Exception e) {
          // what do we need to do here? Can't preview without a template
          System.debug('previewEmail could not find a template for id='+emailTemplateId+' e='+e.getMessage());
          return null;
       }
       SObject target = getTarget(touchpoint, mMail);
       String targetId = (target != null ? target.Id : null);
       System.debug('previewEmail targetId='+targetId+' template='+template);
       Messaging.SingleEmailMessage emailPreview = Messaging.renderStoredEmailTemplate(emailTemplateId, targetId, touchpoint.Id);
       //String emailBody = emailPreview.getPlainTextBody();
       String emailBody = emailPreview.getHtmlBody();
       if (String.isBlank(emailBody)) {
          emailBody = emailPreview.getPlainTextBody();
       }
       System.debug('previewEmail emailBody='+emailBody);
       return emailBody;
    } // previewEmail
    
    @AuraEnabled
    public static List<Cadence_Touchpoint__c> getPastDueEmailTps(List<Cadence_Touchpoint__c> currentTpList){
        List<Cadence_Touchpoint__c> emailList = new List<Cadence_Touchpoint__c>();
        for(Cadence_Touchpoint__c tp : currentTpList){
            if(tp.Cadence_Touchpoint_Step__r.Touchpoint_Type__c == 'Email' && tp.Due_Date__c <= DateTime.now() && tp.SignificantEmailEligible__c){
                emailList.add(tp);
            }
        }
        return emailList;
    } // getPastDueEmailTps
    
    // send emails to multiple contacts off multiple touchpoints
    @AuraEnabled
     public static EmailResponseWrapper sendEmailList(List<Cadence_Touchpoint__c> tpList){
        //List of emails to send
        System.debug('sendEmailList tpList='+tpList.size());
        List<Messaging.SingleEmailMessage> msgsToSend = new List<Messaging.SingleEmailMessage>();
        List<Cadence_Touchpoint__c> tpUpdateList = new List<Cadence_Touchpoint__c>();
        //List of CAR records to update
        List<Id> carsUpdateList = new List<Id>();
        //Max number of emails to add to msgsToSend list
        Integer emailLimit = Integer.valueOf(Label.CadenceSendEmailLimit);
        //Number of emails sent successfully
        Integer numSuccessfulEmails = 0;
        List<String> errorMessages = new List<String>();
        for(Cadence_Touchpoint__c touchpoint : tpList){ 
            //Limit the number of emails sent at one time
            if( touchpoint !=null){
                touchpoint.isEmailBatch__c = true;
                List<String> emailTemplateIdList =  touchpoint.Cadence_Touchpoint_Step__r.EmailTemplateIds__c.split(',');
                List<String> emailTemplateNameList =  touchpoint.Cadence_Touchpoint_Step__r.EmailTemplateNames__c.split(',');
                if(touchpoint.Status__c == 'Open'){
                    touchpoint.EmailToAddress__c = touchpoint.CarRecord__r.SignificantContactEmail__c;
                    touchpoint.EmailTemplateIdUsed__c = emailTemplateIdList[0];
                    touchpoint.EmailTemplateNameUsed__c = emailTemplateNameList[0];
                    //APR0130779 : Remove Significant Lead/Contact
                    //sObject target = (touchpoint.CarRecord__r.SignificantContact__r != null ? (SObject)touchpoint.CarRecord__r.SignificantContact__r : (SObject)touchpoint.CarRecord__r.SignificantLead__r);
                    sObject target = (touchpoint.CarRecord__r.ContactId__r != null ? (SObject)touchpoint.CarRecord__r.ContactId__r : (SObject)touchpoint.CarRecord__r.LeadId__r);
                    String targetId = (target != null ? target.Id : null);
                    if (targetId.startsWith(ObjectHelper.PREFIX_CONTACT)) {
                        touchpoint.EmailToContact__c = targetId;
                    } else if (targetId.startsWith(ObjectHelper.PREFIX_LEAD)) {
                        touchpoint.EmailToLead__c = targetId;
                    }
                    touchpoint.EmailSentMethod__c = 'sendEmailList';
                    sendMailNow(touchpoint, targetId, null, null, null, emailTemplateIdList[0], msgsToSend);
                }
            }
        }
        EmailResponseWrapper responseWrapper = new EmailResponseWrapper();
        responseWrapper.toastType = 'success';
        String emailSendResults;
        if (!msgsToSend.isEmpty()) {
            ZipCheckOwner.SKIP_TRIGGERS=true;
            TriggerMethods.SKIP_TRIGGERS=true;
            ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING=true;
            ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING=true;
            Messaging.SendEmailResult[] results = Messaging.sendEmail(msgsToSend, false);
            ZipCheckOwner.SKIP_TRIGGERS=false;
            TriggerMethods.SKIP_TRIGGERS=false;
            ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING=false;
            ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING=false;
            
            for(Integer cnt=0;cnt <results.size();cnt++){
                Messaging.SendEmailResult result = results[cnt];
                Cadence_Touchpoint__c tp = tpList[cnt];
                if(result.isSuccess()){
                    tp.Status__c = 'Closed';
                    tp.LastUpdateMethod__c='WorkQueueController.sendEmailList';
                    tp.Close_Date__c = Date.today();                      
                    tp.CloseDateTime__c = Datetime.now();
                    carsUpdateList.add(tp.CarRecord__c);
                    numSuccessfulEmails++;
                }else{
                    //Add error message to Touchpoint
                    Integer fldLength=Cadence_Touchpoint__c.EmailException__c.getDescribe().getLength();
                    tp.EmailException__c=(result.getErrors().get(0).getMessage()).left(fldLength);
                    errorMessages.add('\nError sending email to '+ tp.CarRecord__r.SignificantContactEmail__c + '. Details: ' + result.getErrors().get(0).getMessage());
                }
                tpUpdateList.add(tp);
            }
            
            DmlHelper.performDML2(tpUpdateList, DmlHelper.DML_UPDATE, 'WorkQueueController', 'sendEmailList', 'sendEmailList', true);
            emailSendResults = numSuccessfulEmails + ' of '+msgsToSend.size()+' email messages sent successfully';
            if(numSuccessfulEmails != msgsToSend.size()){
                if(numSuccessfulEmails == 0){
                    responseWrapper.toastType = 'error';
                    emailSendResults = 'Oops! Looks like the contact selected cannot be emailed. Review your contact details or use Swap Contact select a different recipient.';
                }else{
                    responseWrapper.toastType = 'warning';
                }
                if(!errorMessages.isEmpty()){
                    String concatErrorMessages;
                    for(String em : errorMessages){
                        concatErrorMessages+='\nError Message: '+em;
                    }
                    //emailSendResults+=concatErrorMessages;
                }
            }
            if(!carsUpdateList.isEmpty()){
                updateCarList(carsUpdateList,'Email Sent',true);
            }
        }
        responseWrapper.emailResponse = emailSendResults;
        return responseWrapper;
    } //sendEmailList
    
    public static void updateCarList(List<Id> carList, String log, Boolean updateStarted){
        List<Cadence_Assignment_Record__c> cars = [Select Id, Activity_Log__c,Closed__c, CloseReason__c, LatestTouchpoint__c, Rep_Closed__c, ProcessNotes__c, Started__c, Start_Date__c, Status__c, SignificantContactEmail__c 
                                                     ,LatestTouchpointCompletedByRep__c,(Select Id, Close_Date__c,StepCompletedByRep__c from Cadence_Touchpoints__r Order By StepCounter__c desc nulls last, CreatedDate desc)  // the last one created should be the latest one.
                                                 from Cadence_Assignment_Record__c where Id in:carList];
        for(Cadence_Assignment_Record__c carRec : cars){
            String activityText = (log == 'Email Sent' ? 'Email sent to '+ carRec.SignificantContactEmail__c : log);
            if (!carRec.Started__c && updateStarted) {
                carRec.Started__c = true;
                if (carRec.Start_Date__c == null) {
                    carRec.Start_Date__c = Date.today();
                }
            }
            Cadence_Touchpoint__c latestTp = (!carRec.Cadence_Touchpoints__r.isEmpty() ? carRec.Cadence_Touchpoints__r[0] : null);
            if (latestTp != null && carRec.LatestTouchpoint__c != latestTp.Id) {
                carRec.LatestTouchpoint__c=latestTp.Id;
            }
            if(!carRec.Cadence_Touchpoints__r.isEmpty()){
                for(Cadence_Touchpoint__c tp: carRec.Cadence_Touchpoints__r){
                    if(tp.StepCompletedByRep__c =='Complete' && carRec.LatestTouchpointCompletedByRep__c != tp.Id){
                        carRec.LatestTouchpointCompletedByRep__c = tp.Id;
                        break;
                    }

                }

            }

            addToActivityLog(carRec, activityText);
        }
        DmlHelper.performDML2(cars, DmlHelper.DML_UPDATE, 'WorkQueueController', 'updateCarRecord', 'updateCarRecord', true);
    } // updateCarList

   public static final Integer TARGET_IDS_LENGTH = Cadence_Touchpoint__c.EmailTargetIds__c.getDescribe().getLength();
    
   public static void checkEmailExtra(Cadence_Touchpoint__c touchpoint, String emailExtra) {
      if (String.isNotBlank(emailExtra) || (String.isBlank(emailExtra) && String.isNotBlank(touchpoint.EmailExtraText__c))) {
         touchpoint.EmailExtraText__c = emailExtra;
         // save so template can use
         CadenceHelper.SKIP_TRIGGERS=true;
         update touchpoint;
         CadenceHelper.SKIP_TRIGGERS=false;
      }
   } // checkEmailExtra

   public static Integer nbrSuccess=0;
   // targetIds should be a list of lead or contact ids where EligibleToEmail__c = true. The assumption is that all emails are using the same template
   // send emails to multiple contacts off of one touchpoint
   @AuraEnabled 
   public static String sendMailWithTargetIds(Cadence_Touchpoint__c touchpoint, String[] targetIds, String emailTemplateId, String emailExtra) {
      touchpoint.EmailTemplateIdUsed__c = emailTemplateId;
      touchpoint.EmailTargetIds__c = String.join(targetIds,', ').left(TARGET_IDS_LENGTH);
      touchpoint.EmailSentMethod__c='sendMailWithTargetIds';
      touchpoint.LastUpdateMethod__c = 'WorkQueueController.sendMailWithTargetIds';
      checkEmailExtra(touchpoint, emailExtra);
      String subject = null;
      try {
         EmailTemplate et = [Select Id, Name, Subject from EmailTemplate where Id=:emailTemplateId];
         subject = 'Email: '+et.Subject;
      } catch (Exception e) {
         System.debug('Could not select template for Id='+emailTemplateId);
      }
      String emailResponse = 'Unable To Send Email';
      SObject[] targets = getTargets(targetIds);
      nbrSuccess=0;
       
      if (!targets.isEmpty()) {
         // log the first id for the fun of it
         String firstTargetId = targets[0].Id;
         if (firstTargetId.startsWith(ObjectHelper.PREFIX_CONTACT)) {
            touchpoint.EmailToContact__c = firstTargetId;
         } else if (firstTargetId.startsWith(ObjectHelper.PREFIX_LEAD)) {
            touchpoint.EmailToLead__c = firstTargetId;
         }
         Messaging.SingleEmailMessage[] msgsToSend = new Messaging.SingleEmailMessage[]{};
         Boolean emailOkay = false;
         emailResponse = 'Success';
         for (String targetId : targetIds) {
            emailOkay = createMailMsg(touchpoint, targetId, emailTemplateId, msgsToSend);
         }
         String activityMsg = 'Email Sent to ';
         String errorMsg = '';
         if (!msgsToSend.isEmpty()) {
            Messaging.SendEmailResult[] results = Messaging.sendEmail(msgsToSend, false);
            for (Integer cnt=0;cnt <results.size(); cnt++) {
               Messaging.SendEmailResult result = results[cnt];
               SObject target = targets[cnt];
               activityMsg += (String)target.get('Email')+'('+(result.isSuccess() ? 'Success' : 'Fail')+')';
               //Cadence_Touchpoint__c tp = tpList[cnt];
               if(result.isSuccess()) {
                  nbrSuccess++;
               } else {
                  errorMsg += result.getErrors().get(0).getMessage()+'; ';
                  if (emailResponse == 'Success') {
                      emailResponse = getEmailResponse(errorMsg);
                   }
                }
            } // for (Integer cnt=0;cnt <results.size
            if (String.isNotBlank(errorMsg)) {
               Integer fldLength=Cadence_Touchpoint__c.EmailException__c.getDescribe().getLength();
               touchpoint.EmailException__c = errorMsg.left(fldLength);
            }
        } // if (!msgsToSend.isEmpty

        setEmailClose(touchpoint, emailOkay, activityMsg, subject);
      } // if (!targets.isEmpty
      System.debug('sendMailWithTargetIds targetIds='+targetIds.size()+' targets='+targets.size()+' nbrSuccess='+nbrSuccess);
      if (nbrSuccess == 0 && emailResponse == 'Success') {
         emailResponse = 'Failed to Send Email';
      }
      return emailResponse;        
   } // sendMailWithTargetIds   
    
   public static void setEmailClose(Cadence_Touchpoint__c touchpoint, Boolean emailOkay, String activityMsg, String subject) {
      if (emailOkay) {
         touchpoint.Status__c = 'Closed';
         touchpoint.LastUpdateMethod__c = 'WorkQueueController.setEmailClose';
         touchpoint.Close_Date__c = Date.today();
         // if coming from a ReferralAccount log an activity
         if (touchpoint.CarRecord__r.IsReferralSource__c) {
            // don't save the touchpoint in the activity method because we're saving it here.
            saveTouchpoint=false;
            createTouchpointActivity2(touchpoint, activityMsg, null, subject);
            saveTouchpoint=true;
         } // if (touchpoint.CarRecord__r.IsReferralSource__c
         update touchpoint;
            
         CarWrapper emailCarWrapper = new CarWrapper();
         emailCarWrapper.touchpoint = touchpoint;
         emailCarWrapper.ActivityUpdate = activityMsg;
         updateCarRecord(emailCarWrapper, true);
            
      } // if (emailOkay
   } // setEmailClose

    // TODO - move away from this method to only send from targetIds and emailTemplates
    // Send one email to one email address off one touchpoint.
    @AuraEnabled 
    public static String sendMailMethod(String mMail ,String mSubject ,String mbody, Cadence_Touchpoint__c touchpoint, String emailTemplateId, String emailTemplateName, String emailExtra){
        touchpoint.EmailToAddress__c = mMail;
        touchpoint.EmailTemplateIdUsed__c = emailTemplateId;
        touchpoint.EmailTemplateNameUsed__c = emailTemplateName;
        touchpoint.EmailExtraText__c = emailExtra;
        touchpoint.LastUpdateMethod__c = 'WorkQueueController.sendMailMethod';
        
        // first look for the lead/contact 
        SObject target = getTarget(touchpoint, mMail);
        String targetId = (target != null ? target.Id : null);
        
        String bounceReason = null;
        // check for bounce
        if (target != null) {
           String sfBounce = (String)target.get('EmailBouncedReason');
           String otherBounce = (String)target.get('Email_Verification__c');
           Date otherBounceDate = (Date)target.get('Email_Verification_Date__c');
           // if we get a bounce notice from Salesforce, or our custom bounce field has a value with a bounce date within the past 12 months
           bounceReason = (String.isNotBlank(sfBounce) ? sfBounce : (String.IsNotBlank(otherBounce) && otherBounceDate != null && otherBounceDate > Date.today().addMonths(-12) ? otherBounce : null));
        }
        
        if (String.isBlank(bounceReason) && targetId != null) {
            if (targetId.startsWith(ObjectHelper.PREFIX_CONTACT)) {
               touchpoint.EmailToContact__c = targetId;
             } else if (targetId.startsWith(ObjectHelper.PREFIX_LEAD)) {
               touchpoint.EmailToLead__c = targetId;
            }
        }
        
        Boolean emailOkay = false;
        String emailResponse = 'Success';
        // if plain text is sent in, we will just send an email from here. 
        // or if we don't have a lead/contact to send the template to we will send from here.
        Messaging.SingleEmailMessage[] msgsToSend = new Messaging.SingleEmailMessage[]{};
        if (String.isNotBlank(bounceReason)) {
           touchpoint.EmailSentMethod__c='Email Bounce Found';
           Integer fldLength=Cadence_Touchpoint__c.EmailException__c.getDescribe().getLength();
           touchpoint.EmailException__c=bounceReason.left(fldLength);
           emailResponse = getEmailResponse('EMAIL_ADDRESS_BOUNCED');
        } else if ((String.isBlank(targetId) && String.isNotBlank(mMail)) || (emailTemplateId == null && String.isNotBlank(mbody))) {
           touchpoint.EmailSentMethod__c = (targetId != null ? 'Sent By Email Address' : 'Sent Plain Email');
           emailOkay = sendMailNow(touchpoint, targetId, mMail, mSubject, mbody, emailTemplateId, msgsToSend);
        } else if (String.isNotBlank(targetId) && String.isNotBlank(emailTemplateId)) {
           touchpoint.EmailSentMethod__c = 'Sent Using Template and TargetId';
           emailOkay = sendMailNow(touchpoint, targetId, null, null, null, emailTemplateId, msgsToSend);
        } else {
           touchpoint.EmailSentMethod__c = 'Not Enough Email Information';
        }
        System.debug('sendMailMethod touchpoint.EmailSentMethod__c='+touchpoint.EmailSentMethod__c);
        update touchpoint;
        if (!msgsToSend.isEmpty()) {
           try {
               Messaging.sendEmail(msgsToSend);
           } catch (Exception e) {
               emailOkay = false;
               Integer fldLength=Cadence_Touchpoint__c.EmailException__c.getDescribe().getLength();
               touchpoint.EmailException__c=(e.getMessage()).left(fldLength);
               System.debug('sendMailMethod touchpoint.EmailException__c='+touchpoint.EmailException__c);
               update touchpoint;
               emailResponse = getEmailResponse(touchpoint.EmailException__c);
              return emailResponse;
           }
        }
        setEmailClose(touchpoint, emailOkay, 'Email Sent to ' + mMail, null);

        return emailResponse;
    } // sendMailMethod

    @AuraEnabled
    public static List<Referral_Contact__c> getRefCtctEmailList(Id refActId){
       return CadenceTouchpointExtension.getReferralContactsEmailList(refActId);
    }
    @AuraEnabled
    public static List<Id> getEmailContactList(List<Referral_Contact__c> refctcts){
        return CadenceTouchpointExtension.getEmailContactIds(refctcts);
    }
    // @AuraEnabled
    // public static List<String> getEmailContactNamesList(List<Referral_Contact__c> refctcts){
    //     return CadenceTouchpointExtension.getEmailContactNames(refctcts)
    // }
    @AuraEnabled
    public static List<Referral_Contact__c> getReferralContactswithAcctId(Id refActId){
       return CadenceTouchpointExtension.getReferralContactswithAcctId(refActId);
    }
    @AuraEnabled
    public static Referral_Contact__c getReferralContact(Id refctctId){
       return CadenceTouchpointExtension.getReferralContact(refctctId);
    } 
    @AuraEnabled
    public static List<CadenceTouchpointExtension.CAOption> getCAContactNames(Id refActId){
        return CadenceTouchpointExtension.getCAOptionList(refActId);
    }
    public static String getEmailResponse(String msgToCheck) {
       String emailResponse = null;
       for (EmailErrorMessages__c eem : EmailErrorMessages__c.getAll().values()) {
          if (msgToCheck.contains(eem.ErrorCode__c)) {
             emailResponse = eem.ErrorMessage__c;
          }
       } // for (EmailErrorMessages__c eem : EmailErrorMessages__c.getAll().values
       // in case it's not handled push back a generic message.
       if (String.isBlank(emailResponse)) {
          emailResponse = 'There was an error trying to send the email! If this is for an email template a contact or lead for the email address might not have been found.';
       }
       return emailResponse;
    } // getEmailResponse
    
    public class WorkQueueException extends Exception {}

    private static User runningUser = null;
    private static void checkBCC(Cadence_Touchpoint__c touchpoint, Messaging.SingleEmailMessage emailToSend) {
       runningUser = (runningUser == null ? [Select Id, Email, SenderEmail, SenderName, EmailPreferencesAutoBcc, User_Cadence_Type__c, Securities_License__c from User where Id=:UserInfo.getUserId()] : runningUser);
                   
                   if (ALLOW_BCC || (runningUser != null && runningUser.Securities_License__c== True)) {
           if (runningUser.EmailPreferencesAutoBcc) {
              emailToSend.setBccAddresses(new String[]{runningUser.Email});
              touchpoint.BCCSent__c = true;
           }
        } // if (ALLOW_BCC

     } // checkBCC

     
     private static Boolean createMailMsg(Cadence_Touchpoint__c touchpoint, String targetId, String emailTemplateId, Messaging.SingleEmailMessage[] msgsToSend) {
        Messaging.SingleEmailMessage emailToSend = new Messaging.SingleEmailMessage();
        if (String.isNotBlank(targetId) && String.isNotBlank(emailTemplateId)) {
           emailToSend.setSaveAsActivity(String.isNotBlank(targetId));
           emailToSend.setTemplateId(emailTemplateId);
           emailToSend.setTargetObjectId(targetId);
           // do not set if a lead? SendEmail failed. First exception on row 0; first error: INVALID_ID_FIELD, WhatId is not available with saveAsActivity for sending emails to Leads.
           if (String.isBlank(targetId) || !targetId.startsWith(ObjectHelper.PREFIX_LEAD)) {
              emailToSend.setWhatId(touchpoint.Id);
           }
           checkBCC(touchpoint,emailToSend);
           msgsToSend.add(emailToSend);
        }
        return true;
     } // createMailMsg

     // we should be moving away from this because we want to use only templates and targetIds, not emails
    private static Boolean sendMailNow(Cadence_Touchpoint__c touchpoint, String targetId, String mMail, String mSubject, String mbody, String emailTemplateId, Messaging.SingleEmailMessage[] msgsToSend) {
       Messaging.SingleEmailMessage emailToSend = new Messaging.SingleEmailMessage();
       emailToSend.setSaveAsActivity(String.isNotBlank(targetId));
       if (emailTemplateId != null) {
          emailToSend.setTemplateId(emailTemplateId);
       }
       if(String.isBlank(targetId)){
          emailToSend.setToAddresses(new String[]{mMail});
       } else {
          emailToSend.setTargetObjectId(targetId);
       }
       // do not set if a lead? SendEmail failed. First exception on row 0; first error: INVALID_ID_FIELD, WhatId is not available with saveAsActivity for sending emails to Leads.
       if (String.isBlank(targetId) || !targetId.startsWith(ObjectHelper.PREFIX_LEAD)) {
          emailToSend.setWhatId(touchpoint.Id);
       }
       checkBCC(touchpoint,emailToSend);

       if (emailTemplateId == null){
          emailToSend.setSubject(mSubject);
          emailToSend.setHtmlBody(mbody);
       }
            
       msgsToSend.add(emailToSend);
       return true;
    } // sendMailNow
    
    private static SObject[] getTargets(String[] targetIds) {
      // assumption is all ids are for the same object type
      SObject[] returnRecs = new SObject[]{};
      if (targetIds != null && !targetIds.isEmpty()) {
         String firstTargetId = targetIds[0];
         if (firstTargetId.startsWith(ObjectHelper.PREFIX_CONTACT)) {
            returnRecs = [Select Id, Name, FirstName, LastName, AccountId, Email, EligibleToEmail__c from Contact where Id in :targetIds and EligibleToEmail__c=true];
         } else if (firstTargetId.startsWith(ObjectHelper.PREFIX_LEAD)) {
            returnRecs = [Select Id, Name, FirstName, LastName, Lead_Company__c, Email, EligibleToEmail__c from Lead where Id in :targetIds and EligibleToEmail__c=true];
         }
      } // if (targetIds != null
      return returnRecs;
   } // getTargets
    
    private static SObject getTarget(Cadence_Touchpoint__c touchpoint, String emailAddress){
        SObject target = null;
        // first look for the lead/contact 
        if (emailAddress == touchpoint.CarRecord__r.SignificantContactEmail__c) {
            //APR0130779 : Remove Significant Lead/Contact
           // target = (touchpoint.CarRecord__r.SignificantContact__r != null ? (SObject)touchpoint.CarRecord__r.SignificantContact__r : (SObject)touchpoint.CarRecord__r.SignificantLead__r);
            target = (touchpoint.CarRecord__r.ContactId__r != null ? (SObject)touchpoint.CarRecord__r.ContactId__r : (SObject)touchpoint.CarRecord__r.LeadId__r);
        } else {

           if (touchpoint.CarRecord__r.AccountId__c != null) {
               List<Contact> ctcts = [Select Id, AccountId, Email, EmailBouncedDate, EmailBouncedReason, Email_Verification__c, Email_Verification_Date__c from Contact where Email=:emailAddress and AccountId=:touchpoint.CarRecord__r.AccountId__c];
               target = (!ctcts.isEmpty() ? ctcts[0] : null);
           } // if (touchpoint.CarRecord__r.AccountId__c
           else if (touchpoint.CarRecord__r.LeadCompanyId__c != null){
               Lead[] leads = [Select Id, Lead_Company__c, Email, EmailBouncedDate, EmailBouncedReason, Email_Verification__c, Email_Verification_Date__c from Lead where Email=:emailAddress and Lead_Company__c=:touchpoint.CarRecord__r.LeadCompanyId__c];
               target = (!leads.isEmpty() ? leads[0] : null);
           } // if (touchpoint.CarRecord__r.LeadCompanyId__c != null
        }
        return target;
    } // getTarget
    
    public static Boolean saveTouchpoint=true;
    
    @AuraEnabled
    public static void createTouchpointActivity(Cadence_Touchpoint__c touchpoint, String descript){
       createTouchpointActivity2(touchpoint, descript, null, null);
    } // createTouchpointActivity
    
    public static Integer ATTENDEES_SIZE=Task.Meeting_Attendees__c.getDescribe().getLength();

    @AuraEnabled
    public static void createTouchpointActivity2(Cadence_Touchpoint__c touchpoint, String descript, String attendees, String subject){
        System.debug('createTouchpointActivity2 Descript='+Descript);
        Task newTouchpointTask = new Task();
        Id rtId = RecordTypeHelper.getDefaultRecordType('Task').getRecordTypeId();
        newTouchpointTask.WhatId = (touchpoint.CarRecord__r.AccountId__c != null ? touchpoint.CarRecord__r.AccountId__c : touchpoint.CarRecord__r.ReferralAccount__c);
        newTouchpointTask.CAR__c = touchpoint.CarRecord__c;
        newTouchpointTask.RecordTypeId = rtId;
        newTouchpointTask.Status = 'Completed';
        newTouchpointTask.Subject = (String.isNotBlank(subject) ? subject 
                                       : (touchpoint.Cadence__r.name+'-'+touchpoint.Cadence_Touchpoint_Step__r.Touchpoint_Type__c
                                          +'-'+ (touchpoint.CarRecord__r.SignificantContactName__c !=null ? touchpoint.CarRecord__r.SignificantContactName__c : '')));
        newTouchpointTask.Lead_Source_WAR_Call_Type__c = (touchpoint.Cadence_Touchpoint_Step__r.Activity_Call_Type__c != null ? touchpoint.Cadence_Touchpoint_Step__r.Activity_Call_Type__c 
        //                                                  : (touchpoint.Cadence_Touchpoint_Step__r.Touchpoint_Type__c == 'Call' ? 'Call' : null));
                                                          : (touchpoint.TypeFilter__c == 'Call' ? 'Call' : null));
        newTouchpointTask.Type = (touchpoint.Cadence_Touchpoint_Step__r.Activity_Type__c != null ? touchpoint.Cadence_Touchpoint_Step__r.Activity_Type__c 
        //                          : (touchpoint.Cadence_Touchpoint_Step__r.Touchpoint_Type__c == 'Call' ? 'Call' : null));
                                  : (touchpoint.TypeFilter__c == 'Call' ? 'Call' : null));
        //newTouchpointTask.WhoId = touchpoint.TouchpointObject__c == 'Lead' ? touchpoint.CarRecord__r.SignificantLead__c : touchpoint.CarRecord__r.SignificantContact__c;
        //APR0130779 : Remove Significant Lead/Contact
        //newTouchpointTask.WhoId = (touchpoint.CarRecord__r.SignificantContact__c != null ? touchpoint.CarRecord__r.SignificantContact__c : touchpoint.CarRecord__r.SignificantLead__c);
        newTouchpointTask.WhoId = (touchpoint.CarRecord__r.ContactId__c != null ? touchpoint.CarRecord__r.ContactId__c : touchpoint.CarRecord__r.LeadId__c);
        newTouchpointTask.ActivityDate = Date.today();
        if (String.isNotBlank(attendees)) {
           descript = 'Attendees: '+attendees+(String.isNotBlank(descript) ? '\n'+descript : '');
        }
        newTouchpointTask.Description = descript;
        newTouchpointTask.Meeting_Attendees__c = (String.isNotBlank(attendees) ? attendees.left(ATTENDEES_SIZE) : null);
        insert newTouchpointTask;
        touchpoint.ActivityId__c = newTouchpointTask.Id;
        if (saveTouchpoint) {
           CadenceHelper.SKIP_TRIGGERS=true;
           update touchpoint;
        }
        System.debug('createTouchpointActivity2 newTouchpointTask='+newTouchpointTask.Id);
    } // createTouchpointActivity2
    
    public static void addAutoSkipLog(List<Id> CarIdList, String SkipReason){
        List<Cadence_Assignment_Record__c> carList = [Select Id, Activity_Log__c from Cadence_Assignment_Record__c where id in:CarIdList];
        for(Cadence_Assignment_Record__c car :carList ){
            addToActivityLog(car,SkipReason);
        }
        DmlHelper.performDML2(carList, DmlHelper.DML_UPDATE, 'CadenceUpdate', 'addAutoSkipLog', 'addAutoSkipLog', true);
    }

    @AuraEnabled
    public static void skipThisTouchpoint(Cadence_Touchpoint__c touchpoint, String skipReason){
        //APR0159917--Start--Checking last step
        boolean lastStep=CadenceTouchpointExtension.isLastStep(touchpoint.Cadence__c,Integer.ValueOf(touchpoint.Step_Number__c));
        if(!lastStep){
        touchpoint.Status__c = 'Skipped';
        touchpoint.LastUpdateMethod__c='WorkQueueController.skipThisTouchpoint1';
        touchpoint.Close_Date__c = Date.today();
        touchpoint.CloseDateTime__c = Datetime.now();
        touchpoint.Skip_Reason__c = skipReason;
        update touchpoint;
        }
        String activityDetail = 'Touchpoint \"' + touchpoint.TypeFilter__c + '\" skipped. Reason: '+skipReason;
        CarWrapper skipWrapper = new CarWrapper();
        skipWrapper.touchpoint = touchpoint;
        //skipWrapper.repCloseReason = 'Skipped';
        skipWrapper.ActivityUpdate = activityDetail;
        updateCarRecord(skipWrapper, true);
    }  
    
    public static void skipThisTouchpoint(List<Cadence_Touchpoint__c> touchpointList, String skipReason, Boolean isBeforeTrig){
        List<Id> carIdList = new List<Id>();
        for(Cadence_Touchpoint__c touchpoint : touchpointList){
            touchpoint.Status__c = 'Auto Skipped';
            touchpoint.LastUpdateMethod__c='WorkQueueController.skipThisTouchpoint2';
            touchpoint.Skip_Reason__c = skipReason;
            touchpoint.Close_Date__c = Date.today();
            touchpoint.CloseDateTime__c = Datetime.now();
            carIdList.Add(touchpoint.CarRecord__c);
        }
        if(!isBeforeTrig){
            update touchpointList;
            if(!carIdList.isEmpty()){
                updateCarList(carIdList,skipReason, true);
                //addAutoSkipLog(carIdList, skipReason);
            }
        }
   }  
    
   @AuraEnabled
   public static void logStep(Cadence_Touchpoint__c touchpoint, String logType, String repNote, DateTime dueDate, String repeatReason, String closeReason, String attendees) {
       if(dueDate==null){
           dueDate = Datetime.now();
       }
      System.debug('logStep logType='+logType);
       //APR0159917--Start
      //system.debug('MA Check1'+touchpoint.Cadence__c+'MA Check2'+touchpoint.Step_Number__c);
      boolean lastStep=CadenceTouchpointExtension.isLastStep(touchpoint.Cadence__c,Integer.ValueOf(touchpoint.Step_Number__c));
      system.debug('MA Check3'+lastStep);
      //APR0159917--End	
      CarWrapper carWrap = new CarWrapper();
      // in case we're repeating the step.
      Cadence_Touchpoint__c newTp = touchpoint.clone();
      newTp.Status__c = 'Open';
      newTp.LastUpdateMethod__c='WorkQueueController.logStep';
      // all three statuses will close the touchpoint
      touchpoint.Close_Date__c = Date.today();
      touchpoint.CloseDateTime__c = Datetime.now();
      //APR0159917--Added if condition --Checking whether it is the last step and Outcome_Required__c is true
      if(lastStep && logType=='Complete Step'){
        //Do nothing
      }
       else{
           touchpoint.Status__c = (logType == 'Repeat Step' ? 'Repeated' : 'Closed');
       }
      
      touchpoint.LastUpdateMethod__c='logStep';
      User newU2 = UserHelper.getRunningUser();
      
      // skip the triggers except when Completing the step because we don't want the new touchpoints creating automatically.
      CadenceHelper.SKIP_TRIGGERS=(logType != 'Complete Step');
      carWrap.ActivityUpdate = newU2.Name+ ': Touchpoint Type ' + touchpoint.Cadence_Touchpoint_Step__r.Name + ' completed';

      if (String.isNotBlank(touchpoint.CarRecord__r.SignificantContactName__c)) {
         carWrap.ActivityUpdate += ' against '+touchpoint.CarRecord__r.SignificantContactName__c+'. ';
      }
      
      carWrap.processNotes='logStep logType='+logType+' SKIP_TRIG1='+CadenceHelper.SKIP_TRIGGERS;
      update touchpoint;
      carWrap.touchpoint = touchpoint;
      carWrap.processNotes += '; SKIP_TRIG2='+CadenceHelper.SKIP_TRIGGERS+'. ';
      if (logType == 'Repeat Step') {
         newTp.Id = null;
         newTp.Due_Date__c = dueDate;
         newTp.RepeatCount__c = (touchpoint.RepeatCount__c != null ? touchpoint.RepeatCount__c : 0)+ 1;
         System.debug('logStep newTp.RepeatCount__c='+newTp.RepeatCount__c);
         newTp.PreviousTouchpoint__c = touchpoint.Id;
         insert newTP;
          
         carWrap.touchpoint = newTp;
         String OldDate = touchpoint.Due_Date__c.format('M/d/yyyy H:mm');
         String NewDate = dueDate.format('M/d/yyyy H:mm');
         carWrap.ActivityUpdate += '; Repeat Step: new Due Date '+NewDate+', Reason: '+repeatReason;
         carWrap.processNotes += ' Repeat Step: old Due Date: '+oldDate+' new Due Date '+NewDate;
      } else if (logType == 'Complete Step') {
         // nothing special for this?
      } else if (logType == 'Complete and Remove') {
         carWrap.repCloseReason = closeReason;
      }
      
      String activityNotes = (String.isNotBlank(attendees) ? 'Attendees: '+attendees+'\n' : '') + (String.isNotBlank(repNote) ? 'Notes: '+repNote : '');
      if (String.isNotBlank(activityNotes)) {
         carWrap.ActivityUpdate += activityNotes;
      }

    //   carWrap.started=true;
      CadenceHelper.SKIP_TRIGGERS=false;
      updateCarRecord(carWrap, true);
      if (touchpoint.Cadence_Touchpoint_Step__r.Generate_Activity__c) {
          createTouchpointActivity2(touchpoint, repNote, attendees,null);
      }
   } // logStep
    /*
    @AuraEnabled
    public static void processTouchpoint(Cadence_Touchpoint__c touchpoint, String repNote){
        System.debug('processTouchpoint repNote='+repNote);
        touchpoint.Status__c = 'Closed';
        update touchpoint;
        String activityDetail = 'Touchpoint Type \"' + touchpoint.Cadence_Touchpoint_Step__r.Touchpoint_Type__c + '\" completed. ';
        if(repNote!=null){
            activityDetail+='Notes: '+repNote;
        }
        CarWrapper processTPWrapper = new CarWrapper();
        processTPWrapper.touchpoint = touchpoint;
        processTPWrapper.ActivityUpdate = activityDetail;
        updateCarRecord(processTPWrapper);
        System.debug('processTouchpoint Generate_Activity__c='+touchpoint.Cadence_Touchpoint_Step__r.Generate_Activity__c);
        if (touchpoint.Cadence_Touchpoint_Step__r.Generate_Activity__c) {
            createTouchpointActivity(touchpoint, repNote);
        }
    } // processTouchpoint
    
    // for the "log and repeat" option on the form. Close the current touchpoint. Create a new one with the due date.
    @AuraEnabled
    public static void updateDD(Cadence_Touchpoint__c touchpoint, DateTime dueDate, String reason){
        String OldDate = touchpoint.Due_Date__c.format('MM/dd/yyyy HH:mm');
        String NewDate = dueDate.format('MM/dd/yyyy HH:mm');
        Cadence_Touchpoint__c newTp = touchpoint.clone();
        touchpoint.Close_Date__c = Date.today();
        touchpoint.Status__c='Closed';
        CadenceHelper.SKIP_TRIGGERS=true;
        update touchpoint;
        newTp.Id = null;
        newTp.Due_Date__c = dueDate;
        newTp.RepeatCount__c = (touchpoint.RepeatCount__c != null ? touchpoint.RepeatCount__c : 0)+ 1;
        System.debug('updateDD newTp.RepeatCount__c='+newTp.RepeatCount__c);
        newTp.PreviousTouchpoint__c = touchpoint.Id;
        insert newTP;
        String activityDetail = 'Due Date for Touchpoint Step ' 
            + touchpoint.Cadence_Touchpoint_Step__r.Name + ' Changed from '+OldDate+' to '+NewDate+'.  Reason: '+reason;
        CarWrapper updateDateWrapper = new CarWrapper();
        updateDateWrapper.touchpoint = newTp;
        updateDateWrapper.ActivityUpdate = activityDetail;
        updateCarRecord(updateDateWrapper);
    }
    */
    @AuraEnabled
    public static void removeFromCadence(Cadence_Touchpoint__c touchpoint, String closeReason){
        touchpoint.Status__c = 'Canceled By Rep';
        touchpoint.LastUpdateMethod__c='WorkQueueController.removeFromCadence';
        touchpoint.Close_Date__c = Date.today();
        //APR0130190: Skipping Touchpoint trigger to avoid setting car close reason.
        CadenceHelper.SKIP_TRIGGERS=true;
        update touchpoint;
        //APR0130190: Do not skip CAR triggers -- when car is closed, lead stage will be updated based on car closed reason in CAR trigger.
        CadenceHelper.SKIP_TRIGGERS=false;
        //checkForRejectRecycle(touchpoint, closeReason);
        CarWrapper removeWrapper = new CarWrapper();
        removeWrapper.touchpoint = touchpoint;
        removeWrapper.repCloseReason = closeReason;
        updateCarRecord(removeWrapper, true);
    } // removeFromCadence
    

    public class OppWrap {
        public OppWrap(Opportunity p_opp) {
            opp = p_opp;
        }
        
        @AuraEnabled
        public Opportunity opp{get;set;}
        @AuraEnabled
        public String oppName{
            get {return (opp != null ? opp.Name : null);}
        }
        
        @AuraEnabled
        public String status{
            get {return (opp != null ? opp.StageName : null);}
        }
        
        @AuraEnabled
        public String owner{
            get {return (opp != null ? opp.Owner.Name : null);}
        }
        
        @AuraEnabled
        public Date closeDate{
            get {return (opp != null ? opp.CloseDate : null);}
        }
    } // class OppWrap
    
    @AuraEnabled
    public static OppWrap[] generateOpptyList(Cadence_Touchpoint__c touchpoint){
        OppWrap[] oppWraps = new OppWrap[]{};
            if (touchpoint != null && touchpoint.CarRecord__r != null && touchpoint.CarRecord__r.AccountId__c != null) {
                Opportunity[] opps = [Select Id, Name, StageName, CloseDate, OwnerId, Owner.Name
                                      from Opportunity
                                      Where AccountId = :touchpoint.CarRecord__r.AccountId__c
                                      order by CloseDate desc];
                for (Opportunity opp : opps) {
                    oppWraps.add(new OppWrap(opp));
                }
            }
        //Account tpAcct = [Select Id, (Select Id, Name, StageName, Net_Revenue__c from Opportunities) from Account where Id=:touchpoint.CarRecord__r.ParentAccountId__c];
        // List<Opportunity> oppList = tpAcct.Opportunities;
        return oppWraps;
    } // generateOpptyList
    
    public class AssetWrap{
        public AssetWrap(Asset asst) {
            Id = asst.Id;
            assetName = asst.Name;
            startDate = asst.Start_Date__c;
            endDate = asst.Plan_Cancel_Date__c;
            lostReason = asst.Plan_Lost_Reason__c;
        }
        @AuraEnabled public Id Id;
        @AuraEnabled public String assetName;
        @AuraEnabled public Date startDate;
        @AuraEnabled public Date endDate;
        @AuraEnabled public String lostReason;
        
    } // class AssetWrap
    
    @AuraEnabled
    public static AssetWrap[] getAssets(Cadence_Touchpoint__c touchpoint) {
        Id acctId = (touchpoint != null && touchpoint.CarRecord__r != null ? touchpoint.CarRecord__r.AccountId__c : null);
        AssetWrap[] wraps = getAssets(acctId);
        return wraps;
    } // getAssets
    
    public static AssetWrap[] getAssets(Id acctId) {
        AssetWrap[] wraps = new AssetWrap[]{};
            if (acctId != null) {
                Asset[] assts = [Select Id, Name, ProductCode, Plan_Cancel_Date__c, Start_Date__c, Plan_Lost_Reason__c
                                 From Asset
                                 Where AccountId = :acctId
                                 Order by Plan_Cancel_Date__c DESC NULLS FIRST, Name ASC
                                 limit 50];
                for (Asset asst : assts) {
                    AssetWrap wrap = new AssetWrap(asst);
                    wraps.add(wrap);
                }
            } // if (acctId != null
        System.debug('getAssets acctId='+acctId+' wraps='+wraps.size());
        return wraps;
    } // getAssets
    
    public static String CACHE_KEY='WorkQueueControllerCloseReaonMap';
    
    // if any of the associated records change clear the cache so it will requery the data    
    public static void clearCache() {
        CacheManager.removeOrg(CACHE_KEY);
    } // clearCache
    
    // for testing purposes
    public static Integer REASONS_QUERY_CNT = 0;
    
    // Cadence_Close_Reasons__c contains default as well as cadence type specific
    public static Map<String,String[]> getCloseReasonMap() {
        Map<String,String[]> closeReasonMap = (Map<String,String[]>)CacheManager.getOrg(CACHE_KEY);
        if (closeReasonMap == null) {
            REASONS_QUERY_CNT++;
            closeReasonMap = new Map<String,String[]>();
            Map<String,Set<String>> queryMap = new Map<String,Set<String>>();
            Cadence_Close_Reasons__c defReasons = null;
            // retrieve all of the Cadence_Close_Reasons records
            Cadence_Close_Reasons__c[] closeReasons = [Select Id, Name, Cadence_Type__c, CloseReason__c, OnlyUseCustomCloseReasons__c
                                                       from Cadence_Close_Reasons__c
                                                       Where Active__c=true];
            Set<String> defaultReasons = new Set<String>();
            // first find the default reasons
            for (Cadence_Close_Reasons__c closeReason : closeReasons) {
                if (String.isNotBlank(closeReason.CloseReason__c) && closeReason.Cadence_Type__c == 'Default') {
                    System.debug('setupCloseReasons default='+closeReason.CloseReason__c);
                    defaultReasons.addAll(closeReason.CloseReason__c.split(','));
                }
            } // for (Cadence_Close_Reasons__c closeReason
            System.debug('setupCloseReasons defaultReasons='+defaultReasons.size());
            // TODO - if there is nothing here - do we want to have some hardcoded defaults?
            for (Cadence_Close_Reasons__c closeReason : closeReasons) {
                if (closeReason.Cadence_Type__c != 'Default') {
                    // in theory there should only be one record per cadence type - but just in case we'll handle it like this.
                    Set<String> reasonSet = (queryMap.containsKey(closeReason.Cadence_Type__c) ? queryMap.get(closeReason.Cadence_Type__c) : new Set<String>());
                    if (String.isNotBlank(closeReason.CloseReason__c)) {
                        reasonSet.addAll(closeReason.CloseReason__c.split(','));
                    }
                    if (!closeReason.OnlyUseCustomCloseReasons__c || reasonSet.isEmpty()) {
                        reasonSet.addAll(defaultReasons);
                    }
                    queryMap.put(closeReason.Cadence_Type__c, reasonSet);
                    System.debug('setupCloseReasons Cadence_Type__c='+closeReason.Cadence_Type__c+' reasonSet='+reasonSet.size());
                } // if (String.isNotBlank(closeReason.CloseReason__c
            } // for (Cadence_Close_Reasons__c
            System.debug('setupCloseReasons queryMap='+queryMap.size());
            // retrieve all of the active Cadences
            Cadence__c[] cadences = [Select Id, Name, CloseReasons__c, OnlyUseCustomCloseReasons__c, Cadence_Type__c
                                     from Cadence__c
                                     Where Active__c=true];
            for (Cadence__c cad : cadences) {
                Set<String> cadReasons = new Set<String>();
                if (String.isNotBlank(cad.CloseReasons__c)) {
                    cadReasons.addAll(cad.CloseReasons__c.split(','));
                }
                // if there are no close reasons or it's okay to inherit the existing reasons
                if ((!cad.OnlyUseCustomCloseReasons__c || cadReasons.isEmpty()) && String.isNotBlank(cad.Cadence_Type__c)) {
                    Set<String> reasonSet = queryMap.get(cad.Cadence_Type__c);
                    //System.debug('Cadence_Type__c='+cad.Cadence_Type__c+' reasonSet='+reasonSet);
                    if (reasonSet != null) {
                        cadReasons.addAll(reasonSet);
                    } else if (!cad.OnlyUseCustomCloseReasons__c) {
                        cadReasons.addAll(defaultReasons);
                    }
                        
                } // if ((!cad.OnlyUseCustomCloseReasons__c
                // add the default reasons if nothing else is present.
                if (cadReasons.isEmpty()) {
                    cadReasons.addAll(defaultReasons);
                }
                String[] reasonsSorted = new String[]{};
                    reasonsSorted.addAll(cadReasons);
                reasonsSorted.sort();
                System.debug('setupCloseReasons cad.Id='+cad.Id+' Cadence_Type__c='+cad.Cadence_Type__c+' reasonsSorted='+reasonsSorted.size());
                closeReasonMap.put(cad.Id,reasonsSorted);
            } // for (Cadence__c cad : cadences
            CacheManager.putOrg(CACHE_KEY,closeReasonMap);
        } // if (closeReasonMap == null
        System.debug('closeReasonMap closeReasonMap='+closeReasonMap.size()+' REASONS_QUERY_CNT='+REASONS_QUERY_CNT);
        return closeReasonMap;
    } // getCloseReasonMap
    
    @AuraEnabled
    public static String[] generateCloseReasonList(Cadence_Touchpoint__c touchpoint) {
        Id cadenceId = (touchpoint != null ? touchpoint.Cadence__c : null);
        Map<String,String[]> closeReasonMap = getCloseReasonMap();
        Boolean inMap = (cadenceId != null && closeReasonMap.containsKey(cadenceId));
        System.debug('generateCloseReasonList cadenceId='+cadenceId+' inMap='+inMap);
        String[] closeReasons = (inMap ? closeReasonMap.get(cadenceId) : new String[]{});
        System.debug('generateCloseReasonList cadenceId='+cadenceId+' closeReasons='+closeReasons.size());
        return closeReasons;
    } // generateCloseReasonList
    
    //public static Integer ACTIVITY_LOG_SIZE=Cadence_Assignment_Record__c.Activity_Log__c.getDescribe().getLength();
    
    // when only sales notes are updated
    @AuraEnabled
    public static void updateCar(Cadence_Touchpoint__c touchpoint, String notes){
        CarWrapper updateWrapper = new CarWrapper();
        User newU = UserHelper.getRunningUser();
        updateWrapper.touchpoint = touchpoint;
        updateWrapper.notes = newU.Name+': Sales Note: '+notes;
        updateCarRecord(updateWrapper, true);
    }
    @AuraEnabled
    public static void updateCarRecord(CarWrapper carWrap, Boolean updateStarted){
        Cadence_Assignment_Record__c carRec = [Select Id, Activity_Log__c,Closed__c, CloseReason__c, LatestTouchpoint__c, Rep_Closed__c, ProcessNotes__c, Started__c, Start_Date__c, Status__c,LatestTouchpointCompletedByRep__c 
                                                     ,(Select Id, Close_Date__c,StepCompletedByRep__c from Cadence_Touchpoints__r Order by StepCounter__c desc nulls last, CreatedDate desc)  // the latest step counter should be the latest one.
                                                 from Cadence_Assignment_Record__c where Id=:carWrap.touchpoint.CarRecord__c limit 1]; 
        addToActivityLog(carRec, carWrap.notes);
        if (!carRec.Started__c && updateStarted) {
            carRec.Started__c = true;
            if (carRec.Start_Date__c == null) {
                carRec.Start_Date__c = Date.today();
            }
        }
        if(!carRec.Cadence_Touchpoints__r.isEmpty()){
            for(Cadence_Touchpoint__c tp: carRec.Cadence_Touchpoints__r){
                if(tp.StepCompletedByRep__c =='Complete' && carRec.LatestTouchpointCompletedByRep__c != tp.Id){
                    carRec.LatestTouchpointCompletedByRep__c = tp.Id;
                    break;
                }

            }

        }
        Cadence_Touchpoint__c latestTp = (!carRec.Cadence_Touchpoints__r.isEmpty() ? carRec.Cadence_Touchpoints__r[0] : null);
        if (latestTp != null && carRec.LatestTouchpoint__c != latestTp.Id) {
            carRec.LatestTouchpoint__c=latestTp.Id;
        }

        addToActivityLog(carRec, carWrap.ActivityUpdate);
        StringHelper.addToProcessNotes(carRec,carWrap.processNotes);
        
        System.debug('updateCarRecord repCloseReason='+carWrap.repCloseReason);
        if(carWrap.repCloseReason != null){
            if (String.isBlank(carRec.CloseReason__c) || carRec.CloseReason__c == 'Cadence Completed') {
                carRec.CloseReason__c = carWrap.repCloseReason;
            }
            carRec.Closed__c = true;
            carRec.Close_Date__c = Date.today();
        }
        DmlHelper.performDML2(new Cadence_Assignment_Record__c[]{carRec}, DmlHelper.DML_UPDATE, 'WorkQueueController', 'updateCarRecord', 'updateCarRecord', true);
    } // updateCarRecord

    public static Integer ACTIVITY_LOG_SIZE=Cadence_Assignment_Record__c.Activity_Log__c.getDescribe().getLength();

    public static void addToActivityLog(Cadence_Assignment_Record__c car, String value) {
       StringHelper.addNotesToField(car, 'Activity_Log__c', ACTIVITY_LOG_SIZE, value, true);
    } // addToActivityLog

    public static CadenceUserSettings__c getUserSettings() {
        CadenceUserSettings__c cus = null;
        try {
            cus = [Select Id, Name, UserId__c
                   ,FilterCadence__c, FilterTouchpoint__c, FilterSalesProgram__c, FilterZip__c, FilterTargetList__c, FilterStep__c,FilterTimeZone__c, FilterTargetType__c
                   From CadenceUserSettings__c
                   Where UserId__c = :UserInfo.getUserId()];
        } catch (Exception e) {
            System.debug('getUserSettings e='+e.getMessage());
        }
        return cus;
    } // getUserSettings
    
    @AuraEnabled
    public static void updateFilterSettings(String filterCadence, String filterTouchpoint, String filterSalesProgram, String filterZip, String filterTargetList, String filterStepNbr, String filterTimeZone, String TargetType ) {
        System.debug('updateFilterSettings filterCadence='+filterCadence+' filterTouchpoint='+filterTouchpoint+' filterSalesProgram='+filterSalesProgram+' filterZip='+filterZip+' filterTargetList='+filterTargetList+' filterStepNbr='+filterStepNbr+' filterTimeZone='+filterTimeZone);
        CadenceUserSettings__c cus = new CadenceUserSettings__c(Name=UserInfo.getName(),OwnerId=UserInfo.getUserId(),UserId__c=UserInfo.getUserId());
        cus.FilterCadence__c = (String.isNotBlank(filterCadence) && filterCadence != 'None' ? filterCadence : null);
        cus.FilterTouchpoint__c = (String.isNotBlank(filterTouchpoint) && filterTouchpoint != 'None' ? filterTouchpoint : null);
        cus.FilterSalesProgram__c = (String.isNotBlank(filterSalesProgram) && filterSalesProgram != 'None' ? filterSalesProgram : null);
        cus.FilterZip__c = (String.isNotBlank(filterZip) && filterZip != 'None' ? filterZip : null);
        cus.FilterTargetList__c = (String.isNotBlank(filterTargetList) && filterTargetList != 'None' ? filterTargetList : null);
        cus.FilterStep__c = (String.isNotBlank(filterStepNbr) && filterStepNbr != 'None' ? filterStepNbr : null);
        cus.FilterTimeZone__c = (String.isNotBlank(filterTimeZone) && filterTimeZone != 'None' ? filterTimeZone : null);
        cus.FilterTimeZone__c = (String.isNotBlank(filterTimeZone) && filterTimeZone != 'None' ? filterTimeZone : null);
        cus.FilterTargetType__c = (String.isNotBlank(TargetType) && TargetType != 'None' ? TargetType : null);
        Database.upsert(cus,CadenceUserSettings__c.Fields.UserId__c,false);
    } // updateFilterSettings
    
     //APR0159917--Start
    @AuraEnabled
    public static Boolean isLastStep(Id cadenceId,Integer stepNumber){
        try {
            system.debug('MA'+cadenceId+'Inside WorkQueueController'+stepNumber);
            return CadenceTouchpointExtension.isLastStep(cadenceId,stepNumber);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    //APR0159917--End
    
} // class WorkQueueController