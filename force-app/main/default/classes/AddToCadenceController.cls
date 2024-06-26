/* Controller for AddToCadence component
* History
 * -------
   10/10/2019 Jake Hinds        Created
   04/27/2020 Dan Carmen        Add Target List to the form
   04/30/2020 Dan Carmen        Change so Refer To Self does not go through the queueable
   05/10/2020 Dan Carmen        Modify for the controller to work directly off the component. Simplified parameters.
   05/28/2020 Dan Carmen        If no cadences are available, display a message to the user
   10/13/2021 Dan Carmen        Add a limit for how many active CARs you can add for yourself.
   06/20/2022 Dan Carmen        Update to Send to Partner routing

 */
public without sharing class AddToCadenceController {
    
    public static final String CLASSNAME='AddToCadenceController';
    
    public SObject rec{get;
          set {
              if (!initDone && value != null) {
                 rec = value;
                 recId = rec.Id;
                 system.debug('AddToCadenceController recId='+recId);
                 recIds = new Id[]{recId};
                 setStartAttributes();
              }
              }}
    public SObject[] recs{get;
          set {
             if (value != null) {
                recs = value;
                recIds = new Id[]{};
                for(Sobject so:recs){
                   system.debug('AddToCadenceController recs recId='+recId);
                   recIds.add((Id)so.get('Id'));
                }
                setStartAttributes();
             }
             }}
    

    //when coming from record
    public Id recId{get;set;}
    //when coming from list view
    public Id[] recIds{get;set;}
    public String startedFrom{get;
              set{
                 system.debug('AddToCadenceController startedFrom='+value+' initDone='+initDone);
                 if (!initDone && (String.isBlank(startedFrom) || value != startedFrom)) {
                    startedFrom=value;
                    //setStartAttributes();
                 }
              }}
    public String objectType{get;set;}

    //public static Integer REFER_TO_OTHER_LIMIT=Integer.valueOf(Label.CAR_Daily_Limit);
    //public static Integer REFER_TO_SELF_LIMIT=Integer.valueOf(Label.CAR_R2S_Daily_Limit);
    
    public Integer referToSelfLimit {
       get {
          if (referToSelfLimit == null) {
             TouchpointSetup__c tpSetup = TouchpointSetup__c.getOrgDefaults();
             referToSelfLimit = (tpSetup != null && tpSetup.NbrRepCanHaveOpen__c != null ? Integer.valueOf(tpSetup.NbrRepCanHaveOpen__c) : 500);
          }
          return referToSelfLimit;
       } // get
       private set;
    } // referToSelfLimit
    
    public Integer referToOtherLimit {
       get {
          if (referToOtherLimit == null) {
             TouchpointSetup__c tpSetup = TouchpointSetup__c.getOrgDefaults();
             referToOtherLimit = (tpSetup != null && tpSetup.NbrRepCanSend__c != null ? Integer.valueOf(tpSetup.NbrRepCanSend__c) : 25);
          }
          return referToOtherLimit;
       } // get
       private set;
    } // referToOtherLimit
    
    public String limitText{
        get {
           String output = '';
           if (referToSelf) {
              output = 'You are allowed to have a total of '+referToSelfLimit+' open CAR records. You currently have '+getSelfOpenCarCount()+' open.';
           } else if (referToElse) {
              checkRunningUser();
              output = 'You are only permitted to send '+referToOtherLimit+' records per day via Send to Partner. So far today, you have sent '+getOtherDailyCount(runningUser.Id)+' records.';
           }
           return output;
        }
    } // limitText
    
    public Boolean isRfrlAcct{get;set;}
    
    //number of records created by the rep today + currently being sent into form
    public Integer totalRecCount;
    //private ApexPages.StandardController stdC;
    //private ApexPages.StandardSetController stdSetC;
    
    //PAGE CONSTANTS
    public static String REFER_SELF = 'Add to My Cadence';
    public static String REFER_ELSE = 'Send to a Partner or Queue';
    //public static String REFER_QUEUE = 'Queue';
    //public static String REFER_Rep = 'Rep';
    public static String STEP_START = 'Start';
    public static String STEP_COMPLETE = 'Complete';
    public static String STEP_CANNOT_START = 'Cannot Start';
    
    public static String ERROR_NO_RECORDS = 'No records selected';
    public static String ERROR_NO_CADENCE = 'You must choose a cadence when assigning to yourself!';
    //public static String ERROR_NO_DESTINATION = 'You must choose a destination when not assigning to self!';
    //public static String ERROR_NO_REP = 'You must choose a partner when not assigning to self!';
    //public static String ERROR_TOO_MANY_RECORDS = 'You cannot send more than '+Label.CAR_Daily_Limit +' records per day!';
    //public static String ERROR_MISMATCH = 'The destination you have chosen does not match the division of the selected rep!';
    
    
    public String errorDescription {get;set;}
    
    //type of owner for CAR
    public String referTo{get;set;}
    //options of who can receive the car
    public SelectOption[] referToOptions{get;set;}
    public Boolean hasReferOptions {
      get {return (referToOptions != null && referToOptions.size() > 1); }
    } // hasReferOptions
    public Boolean referToSelf {
      get {return (String.isNotBlank(referTo) != null && referTo == REFER_SELF); }
    } // referToSelf
    public Boolean referToElse {
      get {return (String.isNotBlank(referTo) != null && referTo == REFER_ELSE); }
    } // referToElse
    
    //cadence to add to
    public String selectedCadence{get;set;}
    public SelectOption[] cadenceOptions{get;set;}
    
    public SelectOption[] destinationOptions{get;set;}
    //map of destination type by destination from custom setting
    Map<String,String> destinationTypeByDestination;
    
    //temporary car record to choose a single cadence for the group
    public Cadence_Assignment_Record__c tempCar{get;set;}
    
    public String pageStep{get;set;}
    public Boolean isStepStart {
      get {return (String.isNotBlank(pageStep) != null && pageStep == STEP_START); }
    } // referToRep
    public Boolean isStepCompleted {
      get {return (String.isNotBlank(pageStep) != null && pageStep == STEP_COMPLETE); }
    } // referToRep
    public Boolean isStepCannotStart {
      get {return (String.isNotBlank(pageStep) != null && pageStep == STEP_CANNOT_START); }
    } // referToRep
    
   public Boolean hasCadenceOptions {
       get {return (cadenceOptions != null && cadenceOptions.size() > 1);}
   }
        
    public User runningUser;
    
   public void checkRunningUser() {
      if (runningUser == null) {
         runningUser = UserHelper.getRunningUser();
      }
   } // checkRunningUser
    
    // this is the constructor used by the component - doesn't need to do anything
    public AddToCadenceController() {
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'rec2='+rec)); 
    } // AddToCadenceController

    // this comes from a single record VF page
    public AddToCadenceController(ApexPages.StandardController stdController){
        rec = stdController.getRecord();
        system.debug('AddToCadenceController in constructor stdController rec='+rec);
        //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'rec1='+rec));
    } // AddToCadenceController
    
    // this is only used when coming from a list view VF page.
    public AddToCadenceController(ApexPages.StandardSetController setController){
        system.debug('AddToCadenceController in constructor setController size'+setController.getRecords().size());
        recs = setController.getSelected();
        
        //String filterList = System.currentPageReference().getParameters().get('filterName');
        String retUrl = System.currentPageReference().getParameters().get('retURL');
        //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'retUrl='+retUrl));
     } // AddToCadenceControlle2
    
    public Boolean initDone=false;
    
    public void setStartAttributes() {
       if (initDone || recids==null) {
           // do nothing until both are set
           return;
       }
       //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'setStartAttributes recIds='+recIds+' initDone='+initDone));
       if (recIds.isEmpty()) {
          pageStep = STEP_CANNOT_START;
          errorDescription = ERROR_NO_RECORDS;
          return;
       }
       initDone=true;
       referTo = REFER_SELF;
       isRfrlAcct = recIds[0].getSObjectType() == Referral_Account__c.sObjectType;
       System.debug('setStartAttributes isRfrlAcct='+isRfrlAcct);
       tempCar = new Cadence_Assignment_Record__c();
       tempCar.Start_Date__c = date.today();
       if (checkRunningUserOptions()) {
          pageStep = STEP_START;
       }
    }  // setStartAttributes
    
    public String referOptionLabel {
       get {
          String label='';
          Integer nbrRecs = (recIds != null ? recIds.size() : 0);
          String extension = (nbrRecs > 1 ? 's' : '');
          if (referTo == REFER_SELF) {
             label='Select a Cadence to add '+nbrRecs+' record'+extension+' to';
          } else {
             label='Where would you like to send '+nbrRecs+' record'+extension+'?';
          }
          return label;
       }
    } // referOptionLabel
    
    public String buttonLabel {
        get {
          String label = 'Return To ';
          if (startedFrom=='List') {
             String objectName = objectType;
             try {
                objectName = (String)Schema.getGlobalDescribe().get(objectType).getDescribe().getLabel();    
             } catch (Exception e) {System.debug('buttonLabel exception: '+e.getMessage());}
              
             label += objectName+' List';
          } else if (recId != null) {
              try {
                 if (rec.getSObjectType() == Account.sObjectType) {
                    Account acct = [Select id, Name from Account where Id=:recId];
                    label += acct.Name;
                 } else if (rec.getSObjectType() == Contact.sObjectType) {
                    Contact ctct = [Select Id, Name from Contact where Id=:recId];
                    label += ctct.Name;
                 } else if (rec.getSObjectType() == Lead.sObjectType) {
                    Lead ld = [Select Id, FirstName, LastName from Lead where Id=:recId];
                    label += ld.FirstName+' '+ld.LastName;
                 } else if (rec.getSObjectType() == Referral_Account__c.sObjectType) {
                    Referral_Account__c refAcct = [Select Id, Name from Referral_Account__c where Id=:recId];
                    label += refAcct.Name;
                 }
                  
              } catch (Exception e) {}
          }
          return label;
        }} // buttonLabel
    
    public void changeReferTo() {
        referTo = (referTo == REFER_SELF ? REFER_ELSE : REFER_SELF);
        //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'changeReferTo referTo='+referTo));
    }
    
    public Boolean checkExistingCars(Integer recCount){
        runningUser = UserHelper.getRunningUser();
        Boolean canCreateAdditional = true;
        if (referToSelf) {
           Integer existingRecs = getSelfOpenCarCount();
           if ((existingRecs + recCount) > referToSelfLimit) {
               errorDescription = 'Adding '+recCount+' to your existing '+existingRecs+' will bring you over your limit of '+referToSelfLimit+' CARs!';
               canCreateAdditional = false;
           }
        } else if (referToElse) {
           checkRunningUser();
           Integer existingRecs = getOtherDailyCount(runningUser.Id);
           if ((existingRecs + recCount) > referToOtherLimit) {
               errorDescription = 'Adding '+recCount+' to your existing '+existingRecs+' will bring you over your limit of '+referToOtherLimit+' CARS!';
               canCreateAdditional = false;
           }
        }
        System.debug('checkExistingCars canCreateAdditional='+canCreateAdditional);
        return canCreateAdditional;
    } // checkExistingCars
    
    public Integer getOtherDailyCount(Id userId) {
       Integer todaysCount = [Select count() from Cadence_Assignment_Record__c where CreatedById=:userId and CreatedDate = TODAY and SendToPartnerStatus__c in :CAROwnershipQueueable.STATUS_SUCCESS];
       System.debug('getOtherDailyCount todaysCount='+todaysCount);
       return todaysCount;
    } // getOtherDailyCount
    
    public Integer getSelfOpenCarCount() {
       runningUser = UserHelper.getRunningUser();
       Integer carCount = [Select count() from Cadence_Assignment_Record__c where OwnerId=:runningUser.Id and Closed__c=false];
       System.debug('getSelfOpenCarCount carCount='+carCount);
       return carCount;
    } // getSelfOpenCarCount
    
    public Boolean allowReferToElse{get;set;}
    
    public static String[] OK_SALES_DIVISIONS = Label.Cadence_ReferToElseDivisions.split(',');
    public static String[] OK_PROFILES = Label.Cadence_ReferToElseProfiles.split(',');
    
    public Boolean checkRunningUserOptions(){
        runningUser = UserHelper.getRunningUser();
        Boolean isSysAdmin = UserHelper.isRunningUserSystemAdmin();
        System.debug('checkRunningUserOptions isRfrlAcct='+isRfrlAcct);
        String userCadenceType = runningUser.User_Cadence_Type__c;
        String cadenceQuery = 'Select Id, Name, ReferralSourceBusinessType2__c, Opportunity_Type__c, SendToPartner__c, RepAdd__c From Cadence__c where Active__c = true '+
                              '  AND (RepAdd__c=true OR SendToPartner__c=true) AND ReferralSourceCadence__c = :isRfrlAcct ';
        if (!isSysAdmin) {
            cadenceQuery += ' AND Cadence_Type__c = :userCadenceType ';
        }
        cadenceQuery += ' order by Name ASC LIMIT 200 ';
        Cadence__c[] cadenceList = Database.query(cadenceQuery);
        String[] userOppTypes = (String.isNotBlank(runningUser.Cadence_Opportunity_Type__c) ? runningUser.Cadence_Opportunity_Type__c.split(',') : new String[]{});
        
        checkCadenceOppTypes(userOppTypes,cadenceList);
        referTo = REFER_SELF;
        if (cadenceOptions.size() <= 1) {
           if (!allowReferToElse) {
              errorDescription = 'Unable to Add Record(s) to Cadence - No available Cadences were found';
              pageStep = STEP_CANNOT_START;
              return false;
           } else {
              referTo = REFER_ELSE;
           }
           //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'You do not have any cadences available!'));
        }
        //for(Cadence__c ca: cadenceList){
            //if(ca.Custom_Permission__c==null ||(ca.Custom_Permission__c!=null && FeatureManagement.checkPermission(ca.Custom_Permission__c))){
        //        cadenceOptions.add(new SelectOption(ca.Id,ca.Name));
            //}
        //}
                
        referToOptions = new SelectOption[]{};
        if (cadenceOptions.size() > 1) {
           referToOptions.add(new SelectOption(REFER_SELF,REFER_SELF));
        }
        if(allowReferToElse){
            referToOptions.add(new SelectOption(REFER_ELSE,REFER_ELSE));
        }
        return true;
    } // checkRunningUserOptions
        
   public void checkCadenceOppTypes(String[] userOppTypes, Cadence__c[] tempCadenceList) {
      cadenceOptions = new SelectOption[]{};
      cadenceOptions.add(new SelectOption('','--None--'));
      allowReferToElse = false;
      System.debug('checkCadenceOppTypes userOppTypes='+userOppTypes+' tempCadenceList='+tempCadenceList.size());
      for (Cadence__c ca : tempCadenceList) {
         if (ca.SendToPartner__c) {
             allowReferToElse = true;
         } else if (ca.RepAdd__c) {
             // if the user has opportunity types, see if the cadence does too, and then only add if they intersect.
             if (!userOppTypes.isEmpty()) {
                Set<String> cadOppTypes = (String.isNotBlank(ca.Opportunity_Type__c) ? new Set<String>(ca.Opportunity_Type__c.split(';')) : new Set<String>());
                System.debug('checkCadenceOppTypes checkCad='+ca.Name+' cadOppTypes='+cadOppTypes);
                if (cadOppTypes.isEmpty()) {
                   System.debug('checkCadenceOppTypes no cadOppTypes adding to list');
                   //cadenceList.add(checkCad);
                   cadenceOptions.add(new SelectOption(ca.Id,ca.Name));
                } else {
                   for (String userOppType : userOppTypes) {
                       if (cadOppTypes.contains(userOppType)) {
                          System.debug('checkCadenceOppTypes found match on '+userOppType);
                          //cadenceList.add(checkCad);
                          cadenceOptions.add(new SelectOption(ca.Id,ca.Name));
                          break;
                       }
                   } // for (String userOppType : userOppTypes
                } // if (cadOppTypes.isEmpty
                 
             } else {
                //cadenceList.add(checkCad);
                System.debug('checkCadenceOppTypes checkCad='+ca.Name+' adding, no user types');
                cadenceOptions.add(new SelectOption(ca.Id,ca.Name));
             }
         } // if (checkCad.hasSendToPartner
          
      } // for (Cadence__c checkCad

      System.debug('checkCadenceOppTypes allowReferToElse='+allowReferToElse+' cadenceOptions='+cadenceOptions.size());
      //return cadenceList;
   } // checkCadenceOppTypes
    
    public void next(){
        system.debug('referToSelf: '+referToSelf+' tempCar '+tempCar);
        Cadence_Assignment_Record__c[] cars = new Cadence_Assignment_Record__c[]{};
            
        Boolean canCreateAdditionalCARS = checkExistingCars(recIds.size());
        
        //validation referToSelf
        if (!canCreateAdditionalCARS) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, errorDescription));
        } else if (referToSelf && String.isBlank(selectedCadence)) {
            errorDescription = ERROR_NO_CADENCE;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, errorDescription));
        } else if (referToSelf && String.isNotBlank(selectedCadence)) {
            cars = handleReferTo(cars);
        //} else if(referToElse && (string.isBlank(tempCar.Telemarketing_Rep__c) || (string.isNotBlank(tempCar.Telemarketing_Rep__c) && String.valueOf(tempCar.Telemarketing_Rep__c).length()<15))) {
        //    errorDescription = ERROR_NO_REP;
        //    ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, errorDescription));
        //} else if (referToElse && string.isBlank(tempCar.Save_Destination__c)) {
        //    errorDescription = ERROR_NO_DESTINATION;
        //    ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, errorDescription));
        //} else if (referToElse && string.isNotBlank(tempCar.Save_Destination__c)&& string.isNotBlank(tempCar.Telemarketing_Rep__c)) {
        } else if (referToElse) {
            system.debug('AddToCadenceController next referToElse');
            Boolean okToHandle = checkNsrLimit();
        //    String destinationType = destinationTypeByDestination.get(tempCar.Save_Destination__c);
        //    if(String.isNotBlank(destinationType)){
        //        User u = [SELECT Id,User_Cadence_Type__c FROM User WHERE Id = :tempCar.Telemarketing_Rep__c LIMIT 1];
        //        if(u!=null && u.User_Cadence_Type__c != destinationType){
        //            okToHandle = false;
        //            errorDescription = ERROR_MISMATCH;
        //            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,  errorDescription+' Expected: '+u.User_Cadence_Type__c+'. Actual: '+destinationType));
        //        }
        //        system.debug('AddToCadenceController next okToHandle'+okToHandle+' destinationType: '+destinationType+' u.User_Cadence_Type__c: '+u.User_Cadence_Type__c);
        //    }
        //    system.debug('AddToCadenceController next okToHandle'+okToHandle+' destinationType: '+destinationType);
            if(okToHandle){
                cars = handleReferTo(cars);
            }
        }
        //save
        if(cars!=null && !cars.isEmpty()){
            saveCARS(cars);
        }
        //return null;
    }
    
   public Boolean checkNsrLimit() {
      Boolean limitOkay = (tempCar.Telemarketing_Rep__c == null);
      System.debug('checkNsrLimit 1 limitOkay='+limitOkay);
      if (!limitOkay) {
         // if they've indicated a user, check the limit
         Integer nbrReceived = getSuggestedUserReceivedCnt(tempCar.Telemarketing_Rep__c);
         limitOkay = ((nbrReceived + recIds.size()) <= nsrReceiveLimit);
         System.debug('checkNsrLimit 2 limitOkay='+limitOkay+' nbrReceived='+nbrReceived+' nsrReceiveLimit='+nsrReceiveLimit);
         if (!limitOkay) {
            User usr = [Select Id, Name from User where Id=:tempCar.Telemarketing_Rep__c];
            errorDescription = usr.Name+' is only allowed '+nsrReceiveLimit+' records per day. They currently have '+nbrReceived+' and you are trying to send '+recIds.size();
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, errorDescription));
         }
      } // if (!limitOkay
      return limitOkay;
   } // checkNsrLimit
    
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
       System.debug('getSuggestedUserReceivedCnt nbrReceived='+nbrReceived);
       return nbrReceived; 
    } // getSuggestedUserReceivedCnt

    public PageReference done(){
        PageReference pg;
        if (startedFrom=='List') {
            pg = new PageReference('/lightning/o/'+objectType+'/home');
        } else {
            pg = new PageReference('/lightning/r/'+objectType+'/'+recId+'/view');
        }
        pg.setRedirect(true);
        return pg;        
    } // done
    
    public PageReference gotoWorkQueue() {
        PageReference pg = new PageReference('/lightning/n/My_Sale_Actions');
        pg.setRedirect(true);
        return pg;        
    } // gotoWorkQueue
    
    public static final Integer TARGET_LIST_SIZE = Cadence_Assignment_Record__c.TargetList__c.getDescribe().getLength();

    public Cadence_Assignment_Record__c[] handleReferTo(Cadence_Assignment_Record__c[]cars){
        system.debug('AddToCadenceController handleReferTo referToSelf='+referToSelf+' referToElse='+referToElse+' recIds'+recIds.size());
        User runningUser = UserHelper.getRunningUser();
        if (recIds!=null) {
            for (Id recId:recIds) {
              	Cadence_Assignment_Record__c car = new Cadence_Assignment_Record__c();
                car.CadenceObject__c = string.valueOf(recId);
                car.Start_Date__c = tempCar.Start_Date__c;
                car.TargetList__c = tempCar.TargetList__c;
                car.Description__c = tempCar.Description__c;
                car.Source__c=CLASSNAME;

                if(referToSelf){
                    car.Suggested_User__c = runningUser.Id;
                    //car.Save_Destination__c = 'Self';
                    car.Cadence__c = selectedCadence;
                    car.Cadence_Owner__c = runningUser.Id;
                    car.SendToPartnerStatus__c = CAROwnershipQueueable.STATUS_SELF;
                    //car.Destination_Detail__c = CAROwnershipQueueable.DESTINATION_DETAIL_SELF;
                }  else if(referToElse){
                    car.Telemarketing_Rep__c = tempCar.Telemarketing_Rep__c;
                	car.Suggested_User__c = tempCar.Telemarketing_Rep__c;
                    car.SendToPartnerStatus__c = CAROwnershipQueueable.STATUS_PENDING;
                    car.TargetList__c=(runningUser.Name).left(TARGET_LIST_SIZE);
                    //car.Save_Destination__c = tempCar.Save_Destination__c;
                    //car.Save_Destination_Cadence_Type__c = destinationTypeByDestination.get(tempCar.Save_Destination__c);
                    //car.Cadence__c = cadenceOptions[1].getValue();
                }
                cars.add(car);  
            }
        }
        return cars;
    } 
    
    public Boolean shouldRedirect{get;set;}
    public String redirectUrl{get;set;}
    
    public void saveCARS(Cadence_Assignment_Record__c[] cars){
        pageStep = STEP_COMPLETE;
        //shouldRedirect=true;
        //PageReference refPage = new PageReference('/'+recId);
        //errorDescription = 'This is just a test message.';
        //redirectUrl =  refPage.getUrl();
        
        system.debug('AddToCadenceController saveCARS cars'+cars);
        system.debug('AddToCadenceController saveCARS cars'+cars[0].ownerid);
        try{
            //DmlHelper.performDML2(cars, DmlHelper.DML_INSERT, 'AddToCadenceController', 'saveCARS', 'inserting cars', true);
            insert cars;
            if (referToSelf) {
               checkCarResultsForSelf(cars);
            } else {
               ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.CONFIRM, 'Your request for '+cars.size()+' record(s) was submitted! You will receive an email shortly summarizing the results of each record selected.'));
            }
            pageStep = STEP_COMPLETE;
        }
        catch(Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, e.getMessage()));
        }
        
    } // saveCARS
    
    public void checkCarResultsForSelf(Cadence_Assignment_Record__c[] cars) {
       Cadence_Assignment_Record__c[] checkCars = [Select Id, Name, Status__c, CloseReason__c
                                                     From Cadence_Assignment_Record__c
                                                    Where Id in :cars];
       String errMsg = '';
       for (Cadence_Assignment_Record__c car : checkCars) {
          if (car.Status__c != 'Open') {
             errMsg += '; '+car.Name+': '+car.CloseReason__c;
          }
       }
       String status = 'Record(s) saved: '+cars.size()+errMsg;
       ApexPages.addMessage(new ApexPages.Message((String.isBlank(errMsg) ? ApexPages.severity.CONFIRM : ApexPages.Severity.WARNING), status));
       
    } // checkCarResultsForSelf
    
} // class AddToCadenceController