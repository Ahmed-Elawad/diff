/* 
  CAR Ownership Queueable job
   
  History
  -------
  11/18/2019 Jake Hinds         Created
  05/19/2020 Jake Hinds         Fix for chatter to not send if car auto rejected and ensure chatter post recipient
  06/20/2022 Dan Carmen         Update to Send to Partner routing

 */
public without sharing class CAROwnershipQueueable implements Queueable{
    
    public static String STATUS_PENDING='Pending';
    public static String STATUS_COMPLETE='Complete';
    public static String STATUS_USER='Assigned To User';
    public static String STATUS_QUEUE='Assigned To Queue';
    public static String STATUS_FAILED='Failed';
    public static String STATUS_SELF='Self';
    public static String CLOSE_NO_CADENCE='No Queue Found';
    // on a successful creation of a record, will have one of these statuses
    public static String[] STATUS_SUCCESS = new String[]{STATUS_USER,STATUS_QUEUE};
    
    public static String FAIL_DNC='Do Not Call';
       
    public Id[] carIds;
    
    public CAROwnershipQueueable(Id[] p_carIds){
        system.debug('CAROwnershipQueueable execute p_carIds: '+p_carIds);
        carIds = p_carIds;
    } // CAROwnershipQueueable
    
    public void execute(QueueableContext context) {
        system.debug('CAROwnershipQueueable execute carIds: '+carIds);
        processRecs();
    } // execute
    
    
    public Cadence_Assignment_Record__c[] queryCars(){
        Cadence_Assignment_Record__c[] carList = [SELECT Id,Name
                         ,AccountId__c,AccountId__r.Name,AccountId__r.NumberOfEmployees,AccountId__r.CurrentClient__c
                         ,AccountId__r.Do_Not_Call__c, AccountId__r.NSS_WorkableHRS__c // this is the current client field
                         ,AccountId__r.NSS_Workable_HRS2__c, AccountId__r.NSS_WorkablePayroll__c
                         ,CadenceObject__c
                         ,Cadence_Owner__c
                         ,Close_Date__c
                         ,Closed__c
                         ,CloseReason__c
                         ,ContactId__c,ContactId__r.Name
                         ,CreatedById
                         ,CreatedBy.Email, CreatedBy.Name
                         ,CreatedBy.User_Cadence_Type__c, CreatedBy.User_Cadence_Type_Group__c, CreatedBy.Profile.Name
                         ,Description__c
                         ,Destination_Detail__c
                         ,LeadId__c,LeadId__r.Name,LeadId__r.NumberOfEmployees, LeadId__r.DoNotCall
                         ,LeadId__r.NSS_WorkableHRS__c, LeadId__r.NSS_WorkablePayroll__c
                         ,OwnerId
                         ,OverrideOtherCARs__c
                         ,ProcessNotes__c
                         ,ReferralAccount__c, ReferralAccount__r.Name, ReferralAccount__r.Referral_Source_Business_Type__c
                         ,ReferralAccount__r.Group__c, ReferralAccount__r.Referral_Type__c
                         ,SendToPartnerStatusDetail__c
                         ,SendToPartnerStatus__c
                         ,Status__c
                         ,Suggested_User__c,Suggested_User__r.Name,Suggested_User__r.NSR_Tier__c
                         ,Touchpoint_Created_Successfully__c
                     FROM Cadence_Assignment_Record__c WHERE Id in:carIds];
       return carList;
    } // queryCars
    
    public Cadence__c[] getSendToPartnerCadences() {
       Cadence__c[] cads = [Select Id, Name
                                  ,Cadence_Type__c
                                  ,CadenceTypeGroup__c
                                  ,CPARotation__c
                                  ,EmpsMax__c
                                  ,EmpsMin__c
                                  ,IsClientCadence__c
                                  ,IsProspectCadence__c
                                  ,LastActivityDays__c
                                  ,Priority__c
                                  ,ReferralSourceBusinessType2__c
                                  ,ReferralSourceCadence__c
                                  ,ReferralType__c
                                  ,SendToPartnerQueue__c
                                  ,SendToPartnerQueueId__c
                                  ,TargetType__c
                                  ,WorkableCurrentClient__c
                                  ,WorkableHRS__c
                                  ,WorkablePayroll__c
                              From Cadence__c
                             Where Active__c=true
                               and SendToPartner__c=true
                             order by Priority__c desc, CreatedDate desc];
        return cads;
    } // getSendToPartnerCadences

    public void processRecs() {
       Cadence_Assignment_Record__c[] cars = queryCars();
       Cadence__c[] cads = getSendToPartnerCadences();
        
       Map<Id,Cadence_Assignment_Record__c> carsByLeadId = new Map<Id,Cadence_Assignment_Record__c>();
       Map<Id,Cadence_Assignment_Record__c> carsByAcctId = new Map<Id,Cadence_Assignment_Record__c>();
       Map<Id,Cadence_Assignment_Record__c> carsByRfrlAcctId = new Map<Id,Cadence_Assignment_Record__c>();
       
       for (Cadence_Assignment_Record__c car : cars) {
          if (!car.Closed__c) {
             if ((car.AccountId__c != null && car.AccountId__r.Do_Not_Call__c)
                 || (car.LeadId__c != null && car.LeadId__r.DoNotCall)) {
                // can't proceed with DNC
                closeCar(car,FAIL_DNC,null);
             } else if (car.AccountId__c != null) {
                carsByAcctId.put(car.AccountId__c, car);
             } else if (car.LeadId__c != null) {
                carsByLeadId.put(car.LeadId__c, car);
             } else if (car.ReferralAccount__c != null) {
                carsByRfrlAcctId.put(car.ReferralAccount__c, car);
             }
          }
       } // for (Cadence_Assignment_Record__c
        
       //order of checkboxes:  Boolean isAcct, Boolean isLead, Boolean isRfrlAcct)
       checkToProcess(carsByAcctId, true, false, false, cads);
       checkToProcess(carsByLeadId, false, true, false, cads);
       checkToProcess(carsByRfrlAcctId, false, false, true, cads);
        
       // save the records
       DmlHelper.performDML2(cars, DmlHelper.DML_UPDATE, 'CAROwnershipQueueable', 'processRecs', 'update CARS', true);
        
       // send notifications
       createOutput(cars);
    }//processRecs
    
    // perform checks to see if we don't need to process the records further
    public void checkToProcess(Map<Id,Cadence_Assignment_Record__c> carMap, Boolean isAcct, Boolean isLead, Boolean isRfrlAcct, Cadence__c[] cads) {
       System.debug('checkToProcess1 carMap='+carMap.size()+' isAcct='+isAcct+' isLead='+isLead+' isRfrlAcct='+isRfrlAcct);
       if ((isAcct || isLead) && !carMap.isEmpty()) {
          handleProspectOwnership(carMap);
       }
       System.debug('checkToProcess2 carMap='+carMap.size());
       if (!carMap.isEmpty()) {
          handleOpenCars(carMap);
       }
       System.debug('checkToProcess3 carMap='+carMap.size());
       if (isAcct && !carMap.isEmpty()) {
          handleOpenOpps(carMap);
       }
       System.debug('checkToProcess4 carMap='+carMap.size());
        
       // if we get to this point we have to search against the cadences to find a matching record
       if (!carMap.isEmpty()) {
          findMatchingCadence(carMap, cads);
       }
       System.debug('checkToProcess5 carMap='+carMap.size());
    } // checkToProcess
    
    public void findMatchingCadence(Map<Id,Cadence_Assignment_Record__c> carMap,  Cadence__c[] cads) {
       Integer nbrDays = 0;
       // see what's in the cadences to determine if we have to look for activity
       for (Cadence__c cad : cads) {
          if (cad.LastActivityDays__c != null && cad.LastActivityDays__c > nbrDays) {
             nbrDays = Integer.valueOf(cad.LastActivityDays__c);
          }
       } // for (Cadence__c cad
        
       System.debug('findMatchingCadence nbrDays='+nbrDays);
       Set<Id> usedKeys = new Set<Id>();
       Map<Id,Date> lastActivityDateMap = getLastActivityDateMap(nbrDays, carMap.keySet());
       for (Id keyId : carMap.keySet()) {
          Cadence_Assignment_Record__c car = carMap.get(keyId);
          if (car != null) {
             findMatchingCadence(keyId, car, cads, lastActivityDateMap.get(keyId));
          }
       }
       
    } // findMatchingCadence
    
    public void findMatchingCadence(Id keyId, Cadence_Assignment_Record__c car, Cadence__c[] cads, Date lastActivityDate) {
       Boolean creatorIsSysAdmin = UserHelper.isSystemAdmin(car.CreatedBy);
       Boolean isClient = (car.AccountId__c != null && car.AccountId__r.CurrentClient__c);
       Boolean isProspect = (!isClient && car.ReferralAccount__c == null);
       Boolean isRefSource = (car.ReferralAccount__c != null);
       Integer carEmployees = (car.AccountId__c != null ? Integer.valueOf(car.AccountId__r.NumberOfEmployees)
                                       : (car.LeadId__c != null ? Integer.valueOf(car.LeadId__r.NumberOfEmployees) : 0));
       String recName =  (car.AccountId__c != null ? car.AccountId__r.Name
                                       : (car.LeadId__c != null ? car.LeadId__r.Name : (car.ReferralAccount__c != null ? car.ReferralAccount__r.Name : 'NoName')));
       System.debug('findMatchingCadence recName='+recName);
       carEmployees = (carEmployees != null ? carEmployees : 0);
       String carNotes = 'findMatchingCadence keyId='+keyId+' isClient='+isClient+' isProspect='+isProspect+' isRefSource='+isRefSource+' lastActivityDate='+lastActivityDate+' carEmployees='+carEmployees;
       Cadence__c cadMatch = null;
       for (Cadence__c cad : cads) {
          Boolean okayToUse = (creatorIsSysAdmin || car.CreatedBy.User_Cadence_Type__c == cad.Cadence_Type__c || car.CreatedBy.User_Cadence_Type_Group__c == cad.CadenceTypeGroup__c);
          Boolean cadIsClient=cad.IsClientCadence__c;
          Boolean cadIsProspect=cad.IsProspectCadence__c;
          Boolean cadIsRefSource=cad.ReferralSourceCadence__c;

          carNotes += '\n cad='+cad.Name+' okayToUse='+okayToUse+' cadIsClient='+cadIsClient+' cadIsProspect='+cadIsProspect+' cadIsRefSource='+cadIsRefSource;
          // if the cadence type does not match, then we'll skip the record
          if (!okayToUse) {
             continue;
          }
          Boolean typeOkay = false;
          Boolean activityOkay = true;
          Boolean empsOkay = true;
          Boolean workable = true;
           
          
           
          if (cad.WorkableCurrentClient__c && !cadIsRefSource) {
             workable = (car.AccountId__c != null && car.AccountId__r.NSS_WorkableHRS__c);
          }
          carNotes += ', workable cad.CurClient='+cad.WorkableCurrentClient__c+' workable='+workable;
          if (workable && !cadIsRefSource && cad.WorkableHRS__c) {
             workable = ((car.AccountId__c != null && car.AccountId__r.NSS_Workable_HRS2__c)
                         || (car.LeadId__c != null && car.LeadId__r.NSS_WorkableHRS__c));
          }
          carNotes += ' HRS='+cad.WorkableHRS__c+' workable='+workable;
          if (workable && !cadIsRefSource && cad.WorkablePayroll__c) {
             workable = ((car.AccountId__c != null && car.AccountId__r.NSS_WorkablePayroll__c)
                         || (car.LeadId__c != null && car.LeadId__r.NSS_WorkablePayroll__c));
          }
          carNotes += ' Payroll='+cad.WorkablePayroll__c+' workable='+workable;
          if (workable) {
             // if there's activity within a certain number of days, then it will not be eligible for this cadence. 
             if (cad.LastActivityDays__c != null && cad.LastActivityDays__c > 0) {
                Date checkDate = Date.today().addDays(-((Integer)cad.LastActivityDays__c));
                activityOkay = (lastActivityDate == null || lastActivityDate < checkDate);
                carNotes += ', activityOkay='+activityOkay+' checkDate='+checkDate;
             }
             if (activityOkay && ((isClient && cadIsClient) || (isProspect && cadIsProspect))) {
                typeOkay = true;
                if (cad.EmpsMin__c != null && cad.EmpsMax__c != null) {
                   empsOkay = (carEmployees >= cad.EmpsMin__c && carEmployees <= cad.EmpsMax__c);
                   carNotes += ', empsOkay='+empsOkay+' EmpsMin='+cad.EmpsMin__c+' EmpsMax='+cad.EmpsMax__c;
                }
             } else if (activityOkay && (isRefSource && cadIsRefSource)) {
                Set<String> busTypeSet = new Set<String>();
                if (String.isNotBlank(cad.ReferralSourceBusinessType2__c)) {
                   busTypeSet.addAll(cad.ReferralSourceBusinessType2__c.split(';'));
                }
                
                typeOkay = (String.isNotBlank(car.ReferralAccount__r.Referral_Source_Business_Type__c) 
                                 && busTypeSet.contains(car.ReferralAccount__r.Referral_Source_Business_Type__c));
                Boolean hasCadRefType = String.isNotBlank(cad.ReferralType__c);
                carNotes += ', refSource typeOkay='+typeOkay+' hasCadRefType='+hasCadRefType;
                if (typeOkay && String.isNotBlank(cad.ReferralType__c)) {
                   String[] refTypes = cad.ReferralType__c.split(';');
                   typeOkay = (String.isNotBlank(car.ReferralAccount__r.Referral_Type__c) && refTypes.contains(car.ReferralAccount__r.Referral_Type__c));
                }
             }
             carNotes += ', typeOkay='+typeOkay+' activityOkay='+activityOkay+' empsOkay='+empsOkay;
             if (typeOkay && activityOkay && empsOkay) {
                cadMatch = cad;
                break;
             }
          } // if (workable
       } // for (Cadence__c cad : cads
       StringHelper.addToProcessNotes(car,carNotes);
       if (cadMatch != null) {
          StringHelper.addToProcessNotes(car,'Criteria matched to the following Cadence: '+cadMatch.name);
          car.Cadence__c = cadMatch.Id;
          car.Touchpoint_Created_Successfully__c = true;
          System.debug('findMatchingCadence car.Cadence__c='+car.Cadence__c);
          // if a user is indicated, see if the user is part of the group indicated by the queue
          if (car.Suggested_User__c == null) {
             addToStatusDetail(car,'Assigned to Queue '+cadMatch.SendToPartnerQueue__c);
             //car.Cadence_Owner__c = cadMatch.SendToPartnerQueueId__c;
             car.OwnerId = cadMatch.SendToPartnerQueueId__c;
             car.SendToPartnerStatus__c = STATUS_QUEUE;
          } else {
             isUserInQueue(car,cadMatch);            
          }
       } else {
          // we didn't find anything, close the car
          StringHelper.addToProcessNotes(car,'Could not find a Cadence matching the criteria');
          closeCar(car,CLOSE_NO_CADENCE,null);
       }
    } // findMatchingCadence
    
    /* this should be handled when adding the records. So I'll probably delete this. 
    public Integer nsrReceiveLimit {
       get {
          if (nsrReceiveLimit == null) {
             TouchpointSetup__c tpSetup = TouchpointSetup__c.getOrgDefaults();
             nsrReceiveLimit = (tpSetup != null && tpSetup.NbrNSRCanReceive__c != null ? Integer.valueOf(tpSetup.NbrNSRCanReceive__c) : 50);
          }
          return nsrReceiveLimit;
       } // get
       private set;
    } // nsrReceiveLimit
    
    // if there's a suggested user, get the number of records they've received in this process
    public Integer getSuggestedUserReceivedCnt(Id userId) {
       Integer nbrReceived = 0;
       if (userId != null) {
          nbrReceived = [Select count() from Cadence_Assignment_Record__c 
                          where OwnerId=:userId and CreatedDate = TODAY and SendToPartnerStatus__c in :CAROwnershipQueueable.STATUS_SUCCESS
                            and Source__c=:AddToCadenceController.CLASSNAME];
       }
       return nbrReceived; 
    } // getSuggestedUserReceivedCnt
    */
    
    public static final Integer CAR_DETAIL_SIZE = Cadence_Assignment_Record__c.SendToPartnerStatusDetail__c.getDescribe().getLength();
    public static void addToStatusDetail(Cadence_Assignment_Record__c car, String detailToAdd) {
       String detail = detailToAdd + (String.isNotBlank(car.SendToPartnerStatusDetail__c) ? '; '+car.SendToPartnerStatusDetail__c : '');
       car.SendToPartnerStatusDetail__c = detail.left(CAR_DETAIL_SIZE);
    } // addToStatusDetail

    
    public static Map<String,Set<Id>> queueMemberSetMap = new Map<String,Set<Id>>();
    
    // Assignment_Group_Name__c (Assignment Group) - Main Group information
    // Assignment_Groups__c (Group Member) Active__c flag, Group_Name__c -> Assignment_Group_Name__c.Id, User__c='True', User_Active__c='True'
    // Assignment_Group_Queues__c (AG-Queue) Name (queue name), QueueId__c, Assignment_Group_Name__c -> Assignment_Group_Name__c.Id
    public Boolean isUserInQueue(Cadence_Assignment_Record__c car, Cadence__c cad) {
       Boolean userInQueue = false;
       Set<Id> userIdSet = queueMemberSetMap.get(cad.SendToPartnerQueueId__c);
       System.debug('isUserInQueue queue='+cad.SendToPartnerQueue__c+' userIdSet='+(userIdSet != null ? userIdSet.size() : -1));
       if (userIdSet == null) {
          userIdSet = new Set<Id>();
          Assignment_Group_Queues__c[] queues = [Select Id, Name, QueueId__c, Assignment_Group_Name__c 
                                                   from Assignment_Group_Queues__c 
                                                  where QueueId__c=:cad.SendToPartnerQueueId__c
                                                  order by CreatedDate desc limit 1];
          System.debug('isUserInQueue queues='+queues.size());
          if (queues.size() == 0) {
                // should never get here because we'll do this check on the cadence.
          } else if (queues.size() > 0) {
             Assignment_Groups__c[] members = [Select Id, User__c
                                                 From Assignment_Groups__c
                                                Where Active__c='True' and User_Active__c='True'
                                                  and Group_Name__c = :queues[0].Assignment_Group_Name__c];
             System.debug('isUserInQueue members='+members.size());
             for (Assignment_Groups__c member : members) {
                userIdSet.add(member.User__c);
             }
          }
          queueMemberSetMap.put(cad.SendToPartnerQueueId__c,userIdSet);
       } // if (userIdSet == null
       userInQueue = userIdSet.contains(car.Suggested_User__c);
       if (!userInQueue) {
          addToStatusDetail(car,'Assigned to Queue '+cad.SendToPartnerQueue__c+'. '+car.Suggested_User__r.Name+' is not an active member of this call queue. ');
          car.OwnerId = cad.SendToPartnerQueueId__c;
          car.SendToPartnerStatus__c = STATUS_QUEUE;
       } else {
          addToStatusDetail(car,'Assigned to '+car.Suggested_User__r.Name);
          car.Cadence_Owner__c = car.Suggested_User__c;
          car.OwnerId = car.Suggested_User__c;
          car.SendToPartnerStatus__c = STATUS_USER;
       }
       return userInQueue;
    } // isUserInQueue
    
    public Map<Id,Date> getLastActivityDateMap(Integer nbrDays, Set<Id> keyIds) {
       System.debug('getLastActivityDateMap nbrDays='+nbrDays);
       Map<Id,Date> lastActivityDateMap = new Map<Id,Date>();
       if (nbrDays > 0) {
          Date compareDate = Date.today().addDays(-nbrDays);
          System.debug('getLastActivityDateMap compareDate='+compareDate);
          // get recent activity just in case the Cadence is looking for it.
          Task[] openTasks = [Select Id, ActivityDate, WhoId, AccountId, WhatId
                                From Task
                               Where ActivityDate >= :compareDate
                                 and (WhoId in :keyIds
                                  or WhatId in :keyIds
                                  or AccountId in :keyIds)
                               order by ActivityDate desc];
          for (Task tsk : openTasks) {
             checkAddDate(tsk.WhoId, tsk.ActivityDate, lastActivityDateMap);
             checkAddDate(tsk.WhatId, tsk.ActivityDate, lastActivityDateMap);
             checkAddDate(tsk.AccountId, tsk.ActivityDate, lastActivityDateMap);
          } // for (Task tsk : openTasks
            
          Event[] openEvents = [Select Id, ActivityDate
                                From Event
                               Where ActivityDate >= :compareDate
                                 and (WhoId in :keyIds
                                  or WhatId in :keyIds
                                  or AccountId in :keyIds)
                               order by ActivityDate desc];
          for (Event evt : openEvents) {
             checkAddDate(evt.WhoId, evt.ActivityDate, lastActivityDateMap);
             checkAddDate(evt.WhatId, evt.ActivityDate, lastActivityDateMap);
             checkAddDate(evt.AccountId, evt.ActivityDate, lastActivityDateMap);
          } // for (Event evt : openEvents

       } // if (nbrDays > 0
       return lastActivityDateMap;
    } // getLastActivityDateMap
    
    public void checkAddDate(Id checkId, Date checkDate, Map<Id,Date> lastActivityDateMap) {
       if (checkId != null && checkDate != null && !lastActivityDateMap.containsKey(checkId)) {
          System.debug('checkAddDate adding '+checkId+'='+checkDate);
          lastActivityDateMap.put(checkId, checkDate);
       }
    } // checkAddDate


    public void handleProspectOwnership(Map<Id,Cadence_Assignment_Record__c> carMap) {
       String[] ownershipStatus = new String[]{ProspectOwnershipMethods.STAGE_PROSPECTING,ProspectOwnershipMethods.STAGE_LOCKOUT};
       TouchpointSetup__c tpSetup = TouchpointSetup__c.getOrgDefaults();
       String prospectReason = (tpSetup != null && String.isNotBlank(tpSetup.ATCPOProspect__c) 
                                   ? tpSetup.ATCPOProspect__c : 'NSR/SDR Already Working');
       String lockoutReason = (tpSetup != null && String.isNotBlank(tpSetup.ATCPOLockout__c) 
                                   ? tpSetup.ATCPOLockout__c : 'NSR with Lockout');
           
       Prospect_Ownership__c[] pos = [SELECT Id,Ownership_Status__c,NSR_Name__c,NSR_Name__r.User_Cadence_Type__c,NSS_Team__c,Segment__c,NSS_Source__c,Lead__c,Prospect_Client__c 
                                       FROM Prospect_Ownership__c 
                                       WHERE Ownership_Status__c in :ownershipStatus 
                                        AND (Prospect_Client__c in :carMap.keySet()
                                             OR Lead__c in :carMap.keySet())];
       System.debug('handleProspectOwnership pos='+pos.size()+' prospectReason='+prospectReason+' lockoutReason='+lockoutReason);
       for (Prospect_Ownership__c po : pos) {
          Id keyId = (po.Prospect_Client__c != null ? po.Prospect_Client__c : po.Lead__c);
          // if we find an open prospect ownership, then the we cannot work the record
          Cadence_Assignment_Record__c car = carMap.remove(keyId);
          if (car != null) {
             String closeReason = (po.Ownership_Status__c == ProspectOwnershipMethods.STAGE_PROSPECTING ? prospectReason 
                                  : (po.Ownership_Status__c == ProspectOwnershipMethods.STAGE_LOCKOUT ? lockoutReason : null ));
             System.debug('handleProspectOwnership closeReason='+closeReason);
             // it should never be null since those are the only two statuses being selected but just in case.
             if (closeReason != null) {
                closeCar(car,closeReason,po.Id);
             }
          }
       } // for (Prospect_Ownership__c po
    } // handleProspectOwnership
    
    public void handleOpenCars(Map<Id,Cadence_Assignment_Record__c> carMap) {
       TouchpointSetup__c tpSetup = TouchpointSetup__c.getOrgDefaults();
       // retrieve the values from the custom setting if available
       String[] targetTypes = (tpSetup != null && String.isNotBlank(tpSetup.ATCTargetTypes__c) 
                                   ? tpSetup.ATCTargetTypes__c.split(',') : new String[]{'Prospect','Inbound Prospect'});
       String closeReason = (tpSetup != null && String.isNotBlank(tpSetup.ATCOpenCarReason__c) 
                                   ? tpSetup.ATCOpenCarReason__c : 'Already In Cadence');
        
       Cadence_Assignment_Record__c[] openCars = [Select Id, Name
                                                        ,AccountId__c
                                                        ,LeadId__c
                                                        ,ReferralAccount__c
                                                    From Cadence_Assignment_Record__c
                                                   Where Cadence__r.TargetType__c in :targetTypes
                                                     and Closed__c = false
                                                     and Id not in :carIds
                                                     and (AccountId__c in :carMap.keySet()
                                                            or LeadId__c in :carMap.keySet()
                                                            or ReferralAccount__c in :carMap.keySet())];
       for (Cadence_Assignment_Record__c openCar : openCars) {
          Id keyId = (openCar.AccountId__c != null ? openCar.AccountId__c
                         : (openCar.LeadId__c != null ? openCar.LeadId__c : openCar.ReferralAccount__c));
          Cadence_Assignment_Record__c car = carMap.remove(keyId);
          if (car != null) {
             closeCar(car,closeReason,openCar.Id);
          }
       } // for (Cadence_Assignment_Record__c openCar
                       
    } // handleOpenCars
    
    public void handleOpenOpps(Map<Id,Cadence_Assignment_Record__c> carMap) {
       TouchpointSetup__c tpSetup = TouchpointSetup__c.getOrgDefaults();
       String closeReason = (tpSetup != null && String.isNotBlank(tpSetup.ATCOpenOpp__c) 
                                   ? tpSetup.ATCOpenOpp__c : 'Open Opportunity');
        
       Opportunity[] opps = [Select Id, Name, AccountId
                                   ,OwnerId, Owner.User_Cadence_Type__c, Owner.User_Cadence_Type_Group__c
                               From Opportunity
                              Where IsClosed = false
                                and AccountId in :carMap.keySet()];
       for (Opportunity opp : opps) {
          Cadence_Assignment_Record__c car = carMap.get(opp.AccountId);
          // if there's an open opportunity with the same User Cadence Type or Group of the Creator of the CAR, then we don't proceed
          if (car != null && (car.CreatedBy.User_Cadence_Type__c == opp.Owner.User_Cadence_Type__c
                              || car.CreatedBy.User_Cadence_Type_Group__c == opp.Owner.User_Cadence_Type_Group__c)) {
             // remove it because it's handled
             carMap.remove(opp.AccountId);
             closeCar(car,closeReason,opp.Id);
          }
       } // for (Opportunity opp
    } // handleOpenOpps
    
    public void closeCar(Cadence_Assignment_Record__c car, String closeReason, Id failedId) {
       if (car != null && String.isNotBlank(closeReason)) {
          StringHelper.addToProcessNotes(car,'SendToPartner closeReason='+closeReason+' Id='+failedId);
          System.debug('closeCar car='+car.Name+' closeReason='+closeReason);
          car.SendToPartnerStatusDetail__c = closeReason;
          car.Status__c = 'Closed';
          car.Closed__c = true;
          car.CloseReason__c = closeReason;
          car.Close_Date__c = Date.today();
          car.SendToPartnerStatus__c = STATUS_FAILED;
          car.SendToPartnerFailedId__c = failedId;
       }
    } // closeCar
    
    public static String tableHeader='<table><tr><td>Name</td><td>Status</td><td>Close Reason</td><td>Detail</td><td>Sent By</td></tr>';
    public static String fileHeader='Name,Status,Close Reason,Detail,Sent By\n';
    
    public void createOutput(Cadence_Assignment_Record__c[] cars) {
       Map<Id,String> userFileMap = new Map<Id,String>();
       Map<Id,String> userTableMap = new Map<Id,String>();
       Map<Id,Integer> nbrSentMap = new Map<Id,Integer>();
       Map<Id,Integer> nbrFailedMap = new Map<Id,Integer>();
       // to keep track of creators vs recipients
       Set<Id> creatorIds = new Set<Id>();
       Set<Id> recipientIds = new Set<Id>();
        
       for (Cadence_Assignment_Record__c car : cars) {
          String closeReason = (String.isNotBlank(car.CloseReason__c) ? car.CloseReason__c : '');
          String statusDetail = (String.isNotBlank(car.SendToPartnerStatusDetail__c) ? car.SendToPartnerStatusDetail__c : '');
          String tableRow='<tr><td>'+car.Name+'</td><td>'+car.SendToPartnerStatus__c+'</td><td>'+closeReason+'</td><td>'+statusDetail+'</td><td>'+car.CreatedBy.Name+'</td></tr>';
          // quote the strings in case there are commas
          String carName = checkIfNeedsQuotes(car.Name);
          closeReason = checkIfNeedsQuotes(closeReason);
          statusDetail = checkIfNeedsQuotes(statusDetail);
          String fileRow=carName+','+car.SendToPartnerStatus__c+','+closeReason+','+statusDetail+','+car.CreatedBy.Name+'\n';
          creatorIds.add(car.CreatedById);
          recipientIds.add(car.CreatedById);
          addToMaps(car.CreatedById, true, !car.Closed__c, tableRow, fileRow, userFileMap, userTableMap, nbrSentMap, nbrFailedMap);
          // if this was assigned directly to a user and it's successful
          if (car.Cadence_Owner__c != null && !car.Closed__c) {
             recipientIds.add(car.Cadence_Owner__c);
             addToMaps(car.Cadence_Owner__c, false, !car.Closed__c, tableRow, fileRow, userFileMap, userTableMap, nbrSentMap, nbrFailedMap);
          } // if (car.Cadence_Owner__c != null
       }
       //table += '</table>';
        
       Messaging.SingleEmailMessage[] emails = new Messaging.SingleEmailMessage[]{};
       for (Id recipientId : recipientIds) {
          Boolean isCreator = creatorIds.contains(recipientId);
          Integer nbrSuccess = nbrSentMap.get(recipientId);
          Integer nbrFailed = nbrFailedMap.get(recipientId);
          String msgBodyTable = userTableMap.get(recipientId) + '</table>';
          System.debug('createOutput msgBodyTable='+msgBodyTable);
          String fileTable = userFileMap.get(recipientId);
          System.debug('createOutput fileTable='+fileTable);
          String msg = '';
          if (isCreator) {
             AddToCadenceController atcc = new AddToCadenceController();
             Integer dailyLimit = atcc.referToOtherLimit;
             Integer nbrSent = atcc.getOtherDailyCount(recipientId);
             msg = 'Your Send to Partner Request is Complete! You have successfully sent a total of '+nbrSent+' out of the '+dailyLimit+' you are allowed to send per day.';  
          } else {
             msg = 'Your partner just sent '+nbrSuccess+' records to you!';
          }
          msg += '<br/><br/>';
          if (isCreator && nbrSuccess != null && nbrSuccess > 0) {
             msg += 'A total of '+nbrSuccess+' record(s) were successfully sent by you. ';
          }
          if (nbrFailed != null && nbrFailed > 0) {
             msg += 'A total of '+nbrFailed+' records(s) could not be sent to a partner or queue. ';
          }
          msg += '<br/><br/>Additional details are below.<br/><br/>';
          msg += msgBodyTable;
          String subject = (isCreator ? 'Your Send To Partner Request Completed' : 'You have received leads from your partner');
          emails.add(createEmail(recipientId, subject, msg, fileTable));
       } // for (Id recipientId

       Messaging.sendEmail(emails);
    } // createOutput
    
    public void addToMaps(Id checkId, Boolean isCreator, Boolean isSuccess, String tableRow, String fileRow
                          ,Map<Id,String> userFileMap, Map<Id,String> userTableMap, Map<Id,Integer> nbrSentMap, Map<Id,Integer> nbrFailedMap) {
       String userTable = userTableMap.containsKey(checkId) ? userTableMap.get(checkId) : tableHeader;
       userTable += tableRow;
       userTableMap.put(checkId,userTable);
       String userFile = userFileMap.containsKey(checkId) ? userFileMap.get(checkId) : fileHeader;
       userFile += fileRow;
       userFileMap.put(checkId,userFile);
       if (isSuccess) {
          Integer nbrSent = (nbrSentMap.containsKey(checkId) ? nbrSentMap.get(checkId) : 0) + 1;
          nbrSentMap.put(checkId, nbrSent);
       }
       if (isCreator && !isSuccess) {
          Integer nbrFailed = (nbrFailedMap.containsKey(checkId) ? nbrFailedMap.get(checkId) : 0) + 1;
          nbrFailedMap.put(checkId, nbrFailed);
       }
    } // addToMaps
    
    public Messaging.SingleEmailMessage createEmail(Id recipientId, String subject, String msgBody, String fileTxt) {
       Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
       mail.setSaveAsActivity(false);
       mail.setTargetObjectId(recipientId);
       mail.setSubject(subject);
       mail.setHtmlBody (msgBody);
       if (String.isNotBlank(fileTxt)) {
          Blob fileBlob = Blob.valueOf(fileTxt);
          Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
          efa.setFileName('SendToPartnerResults.csv');
          efa.setBody(fileBlob);
          mail.setFileAttachments(new Messaging.EmailFileAttachment[] {efa});
       }
       return mail;
    } // createEmail
    
    public String checkIfNeedsQuotes(String checkValue) {
       String returnValue = (String.isNotBlank(checkValue) && checkValue.contains(',') ? '"'+checkValue+'"' : checkValue);
       return returnValue;
    } // checkIfNeedsQuotes
    
} // class CAROwnershipQueueable