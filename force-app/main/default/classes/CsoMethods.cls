/** CSO Process Methods
  On creation of the Opportunity, we want to look at the attributes of the owner to know if they can use CSO. Set an attribute on the opp for further checks.
      If this is not a primary Opportunity (not cloned or split - or do we want to send through splits??), we don't want to go through this. Primary_Opportunity__c = false
  On update of the Opportunity, we want to look at the attributes 

  New Opp Created
     In the before trigger: Check based on record type and opportunity type if the opportunity is eligible for CSO and/or Enterprise registration
        for the Beta period, we will be using custom permissions to be able to identify if the owner qualifies
     If the opp qualifies for either, then a tracking record is created

 * 
 * History
 * -------
   04/27/2022 Jermaine Stukes   Created
   07/15/2022 Dan Carmen        Added functionality for non-CSO
   10/25/2022 Dan Carmen        Additional changes for CSO/Enterprise registraion
   11/18/2022 Dan Carmen        Code for multiple opps with one tracker
   01/05/2023 Bindu Madhavi     Spelling Change in CSO Message  
   01/30/2023 Dan Carmen        Make sure opp name isn't too long for tracker name
   03/17/2023 Dan Carmen        Add Opportunity Lead Source as a knock out.
   09/11/2023 Dan Carmen        Add more logging

 */
public without sharing class CsoMethods implements TriggerInterfaceC {
    
    public static final String CLASSNAME='CsoMethods';
    public static Boolean SKIP_TRIGGERS=false;
    // if this is the production instance
    public static String ENV_PROD='Production';
    
    //public static Boolean hasPermSet = null;

    //Add Trigger Information
    public void handleTrigger(SObject[] p_recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter, Boolean isDelete) {
        //System.debug('CsoMethods.handleTrigger SKIP_TRIGGERS='+SKIP_TRIGGERS+' isBefore='+isBefore+' isAfter='+isAfter);
        System.debug('CsoMethods.handleTrigger SKIP_TRIGGERS='+SKIP_TRIGGERS+' p_recs='+(p_recs != null ? p_recs.size() : -1)+' isBefore='+isBefore+' isAfter='+isAfter+' isDelete='+isDelete+' Trigger.old='+(Trigger.old != null ? Trigger.old.size() : -1));
        if (SKIP_TRIGGERS) {
            return;
        }
        SObject[] recs = TriggerMethods.checkRecs(CLASSNAME, p_recs, oldMap, isBefore, isAfter, isDelete, null, null);

        //if (SKIP_TRIGGERS || TriggerMethods.didTriggerRun(CLASSNAME,recs,oldMap,isBefore,isAfter,isDelete)) {
        if (recs == null || recs.isEmpty()) {
            System.debug('CsoMethods - handleTrigger - trigger ran');
            return;
        }
        SObjectType objType = TriggerMethods.objType;

        System.debug('CsoMethods.handleTrigger objType='+objType);
        if (isBefore) {
            if (objType == Opportunity.sObjectType) {
                handleOpptyBefore((Opportunity[])recs, (Map<Id,Opportunity>) oldMap);
            } else if (Trigger.isUpdate && objType == CSO_Tracking__c.sObjectType){
                handleCSOUpdate((CSO_Tracking__c[])recs, (Map<Id,CSO_Tracking__c>) oldMap);
            }
        } else if (isAfter) {
            //Boolean hasPermSet = (label.csoPermissionSetOn != 'True' || [Select count() from PermissionSetAssignment where PermissionSet.Name='EZ_Onboarding' and AssigneeId =:Userinfo.getUserId() limit 1] > 0);
            //if(hasPermSet){
            if (objType == Opportunity.sObjectType) {
               handleOpptyAfter((Opportunity[])recs, (Map<Id,Opportunity>) oldMap);
               evalCheckTrackerOpp((Opportunity[])recs, (Map<Id,Opportunity>) oldMap);
            }else if (Trigger.isUpdate && objType == Account.sObjectType){
               handleAfterAcctUpdate((Account[])recs, (Map<Id,Account>) oldMap);
            }else if (Trigger.isUpdate && objType == Contact.sObjectType){
               handleAfterCtctUpdate((Contact[])recs, (Map<Id,Contact>) oldMap);
            }else if (objType == CSO_Tracking__c.sObjectType){
               handleCsoAfter((CSO_Tracking__c[])recs, (Map<Id,CSO_Tracking__c>) oldMap);
            }
 
       }
    } // handleTrigger
    
    public static String csoPerm = Label.csoPermissionSetOn;
    // in case we need to release the code without the client registration portion
    public static Boolean cltRegAvail = (Label.PermSet_ClientReg != 'Not Available');
    public static String cltRegPerm = Label.PermSet_ClientReg;
    
    public static String TYPE_CSO='CSO Eligible';
    public static String TYPE_ENT='Enterprise Eligible';
    public static String TYPE_NONE='Not Eligible';
    public static String TYPE_CLIENT='Enterprise Client';
    public static String PERM_ALL='ALL';
   
    public static String[] CLT_REG_TYPES=new String[]{TYPE_CSO,TYPE_ENT};
    
    // TODO - should we add this to the Profile List custom setting and make it more generic?    
    public static String[] csoProfList = label.SMB_Profiles.Split(',');
    // Opportunity types to exclude from the client registration/cso process
    //public static String[] oppTypesExcluded = Label.ClientRegistration_ExcludeOppTypes.split(',');
    public static Set<String> oppTypesExcludedSet = new Set<String>(Label.ClientRegistration_ExcludeOppTypes.split(','));
    public static Boolean allOppTypes = (Label.ClientRegistration_IncludeOppTypes == 'All');
    public static Set<String> oppTypesIncludedSet = new Set<String>(Label.ClientRegistration_IncludeOppTypes.split(','));
    // TODO - define which opportunity types to create for
    
    public static Map<Id,Schema.RecordTypeInfo> byIdMap;
   
    // get the custom setting for the record type id
    public static RecordType__c getRtSetting(Id rtId) {
      if (byIdMap == null) {
         byIdMap = Opportunity.getSobjectType().getDescribe().getRecordTypeInfosById();
      }
      Schema.RecordTypeInfo rtInfo = byIdMap.get(rtId);
      RecordType__c rtSetting = (rtInfo != null ? RecordType__c.getInstance(RecordTypeHelper.cleanRtName(rtInfo.getName())) : null);
      System.debug('getRtSetting rtId='+rtId+' byIdMap='+byIdMap.size()+' rtInfo='+(rtInfo != null)+' rtSetting='+(rtSetting != null));
      return rtSetting;
    } // getRtSetting
    
    // is there at least one record that needs to be checked for client registration?
    public static Boolean hasOppsWithCltReg = false;
    // we need to run the after trigger if we're creating a new tracking record or it's a CSO opp. Right now we're not doing opportunity/product validation 
    // for client registration ** could change **
    public static Boolean runAfterTrigger = false;
    public static Boolean checkOppProds = false;
    // do we re-evaluate the client registration? 
    public static Set<Id> evaluateClientValidationSet = new Set<Id>();
    // if something changes on the opp where we have to re-evaluate the relationship to the tracker record
    public static Id[] evaluateTrackerOppRltn = new Id[]{};
        
    public static Boolean v_runUserHasPermCso=false;
    public static Boolean v_runUserHasPermEnt=false;
    public static void checkUserPerms() {
        // Also checks record type / opportunity types to see if opps qualify
        v_runUserHasPermCso = (csoPerm == PERM_ALL || FeatureManagement.checkPermission(csoPerm));
        v_runUserHasPermEnt = (cltRegAvail && (cltRegPerm == PERM_ALL || FeatureManagement.checkPermission(cltRegPerm)));
    } // checkUserPerms

    public static Map<Id,Account> v_acctMap = new Map<Id,Account>();    
    // these sales divisions will only be allowed to create trackers once there's a subscription quote
    public static String[] subscriptionOnlySalesDivs = Label.ClientReg_OnlySubscriptSalesDiv.split(',');
    
    // determine if the opportunity/owner have permissions for following CSO or Enterprise registration
    public static void handleOpptyBefore(Opportunity[] opps, Map<Id,Opportunity> oldMap) {
       System.debug('CsoMethods.handleOpptyBefore opps='+opps.size());
       hasOppsWithCltReg = false;
       checkOppProds = false;
       v_acctMap.clear();
       evaluateClientValidationSet.clear();
       
       Id[] ownerIds = new Id[]{};
       // used to check if any existing open CSO recs
       Id[] acctIds = new Id[]{};
       Opportunity[] checkOpps = new Opportunity[]{};
       Id runningUserId = UserInfo.getUserId();
       // if there's an opportunity where the running user is not the owner, then we need to query to check permissions.
       Boolean hasUserNotRunningUser = false;
       // get the ids of the primary quotes to see if they're subscription quotes
       Id[] quoteIds = new Id[]{};

       for (Opportunity opp : opps) {
          Opportunity oldOpp = (oldMap != null ? oldMap.get(opp.Id) : null);
          System.debug('handleOpptyBefore opp='+opp.Name+' id='+opp.Id+' AccountId='+opp.AccountId);
          if (oldOpp != null && opp.RecordTypeId != oldOpp.RecordTypeId && opp.Probability <= 40) {
             // TODO - have to re-evaluate the tracker record. 
          }
          hasOppsWithCltReg = (hasOppsWithCltReg || opp.ClientTracking__c != null);
          checkOppProds = (checkOppProds || opp.ClientRegistrationType__c == TYPE_CSO);
          if (String.isBlank(opp.ClientRegistrationType__c) && (oldOpp == null || opp.Probability <= 40 || opp.ClientRegistrationForce__c)) {
             opp.ClientRegistrationForce__c = false;
             // should only enter this method when the Opportunity is first created. 
             RecordType__c rtSetting = getRtSetting(opp.RecordTypeId);
             Boolean rtCSOOkay = (rtSetting != null && rtSetting.CSORegistration__c);
             Boolean rtEntOkay = (cltRegAvail && rtSetting != null && rtSetting.EnterpriseRegistration__c);
             // are we going to have different opportunity types for enterprise registration/subscription billing?
             Boolean oppTypeOkay1 = (String.isNotBlank(opp.OpportunityType__c) && !oppTypesExcludedSet.contains(opp.OpportunityType__c));
             Boolean oppTypeOkay2 = (allOppTypes || oppTypesIncludedSet.contains(opp.OpportunityType__c));
             System.debug('handleOpptyBefore  rtCSOOkay='+rtCSOOkay+' rtEntOkay='+rtEntOkay+' oppTypeOkay1='+oppTypeOkay1+' oppTypeOkay2='+oppTypeOkay2);
             // handle record type and Opportunity Type knockouts
             // TODO - have to be able to handle children different than the parents
             // if there isn't an oracle quote, we're not going to allow anything
             if ((opp.Primary_Opportunity__c != null && opp.Primary_Oracle_Quote__c == null) || (!rtCSOOkay && !rtEntOkay) || !oppTypeOkay1 || !oppTypeOkay2) {
                StringHelper.addToProcessNotes(opp,'Client Registration not available Primary Opp='+opp.Primary_Opportunity__c+' rtCSOOkay='+rtCSOOkay+' rtEntOkay='+rtEntOkay+' oppTypeOkay1='+oppTypeOkay1+' oppTypeOkay2='+oppTypeOkay2);
                opp.ClientRegistrationType__c = TYPE_NONE;
             } else if ((rtCSOOkay || rtEntOkay) && oppTypeOkay1 && oppTypeOkay2 && opp.AccountId != null) {
                StringHelper.addToProcessNotes(opp,'Passed Initial Client Registration Check rtCSOOkay='+rtCSOOkay+' rtEntOkay='+rtEntOkay+' oppTypeOkay1='+oppTypeOkay1+' oppTypeOkay2='+oppTypeOkay2);
                acctIds.add(opp.AccountId);
                ownerIds.add(opp.OwnerId);
                if (opp.Primary_Oracle_Quote__c != null) {
                   quoteIds.add(opp.Primary_Oracle_Quote__c);
                }
                checkOpps.add(opp);
                hasUserNotRunningUser = (hasUserNotRunningUser || (opp.OwnerId != runningUserId)) ;
                runAfterTrigger = true;
             }
          } // if (String.isBlank(opp.ClientRegistrationType__c
          if (opp.Id != null && opp.AccountId != null && opp.Evaluate_Client_Validation__c) {
             if (String.isNotBlank(opp.ClientRegistrationType__c) && CLT_REG_TYPES.contains(opp.ClientRegistrationType__c)) {
                 evaluateClientValidationSet.add(opp.AccountId);
             }
             opp.Evaluate_Client_Validation__c = false;
          } // if (opp.Id != null &&
          runAfterTrigger = (runAfterTrigger || opp.IsEnterpriseRegEligible__c);
       } // for (Opportunity opp : opps
        
       System.debug('handleOpptyBefore ownerIds='+ownerIds.size()+' hasUserNotRunningUser='+hasUserNotRunningUser+' cltRegAvail='+cltRegAvail+' evaluateClientValidationSet='+evaluateClientValidationSet.size());
       if (!ownerIds.isEmpty()) {
          // these are mainly for checking Beta users. Eventually this functionality will become obsolete I believe.
          // Also checks record type / opportunity types to see if opps qualify
          checkUserPerms();
          Boolean runUserHasPermCso = v_runUserHasPermCso;
          Boolean runUserHasPermEnt = v_runUserHasPermEnt;
          // get the accounts to see if the client registration has already happened. Also get any recent CSO Records to link to this Opp if they already exist
          String acctQuery = getQuery(QUERY_ACCT_OPP_CHECK);
          Account[] accts = Database.query(acctQuery);
          Map<Id,Account> acctMap = new Map<Id,Account>(accts);

          // for updating the Client Registration Status on the Account
          Map<Id,Account> acctUpdateMap = new Map<Id,Account>();
           
          // we always need to query the users to check the profile because only certain profiles can submit to CSO
          // TODO - this should be replaced with record type check
          Map<Id,User> userSet = new Map<Id,User>([Select Id, Profile.Name, Sales_Division__c from User where IsActive=true and Id in :ownerIds]);
          // we only need to query if there's at least one owner who is not the running user
          Set<String> havePermsSet = (hasUserNotRunningUser ? doesUserHavePermission(ownerIds, new String[]{csoPerm,cltRegPerm}) : new Set<String>());
          System.debug('handleOpptyBefore csoPerm='+csoPerm+' cltRegPerm='+cltRegPerm+' userSet='+userSet.size()+' havePermsSet='+havePermsSet.size()+
                             ' runUserHasPermCso='+runUserHasPermCso+' runUserHasPermEnt='+runUserHasPermEnt+' cltRegAvail='+cltRegAvail);
           
          for (Opportunity opp : checkOpps) {
             Account acct = acctMap.get(opp.AccountId);
             if (acct != null) {
                //if (acct.ClientRegistrationStatus__c == TYPE_CLIENT) {
                //   StringHelper.addToProcessNotes(opp,'Account is a Client.');
                   // we don't need to do anything else for this type, proceed to the next iteration
                //   opp.ClientRegistrationType__c = TYPE_CLIENT;
                //   continue;
                //} else 
                if (!acct.CSO_Recs__r.isEmpty()) {
                   // TODO - do we need to check if it's a recent/open CSO or just reuse?
                   // if there's an open CSO rec, evaluate the record type if it's CSO, else Enterprise
                   // We've only gotten to this point because it's either CSO or Enterprise
                   RecordType__c rtSetting = getRtSetting(opp.RecordTypeId);
                   Boolean rtCSOOkay = (rtSetting != null && rtSetting.CSORegistration__c);
                   Boolean rtEntOkay = (cltRegAvail && rtSetting != null && rtSetting.EnterpriseRegistration__c);
                   opp.ClientRegistrationType__c = (rtCSOOkay ? TYPE_CSO : TYPE_ENT);
                   opp.CSO_Eligible__c = rtCSOOkay;
                   opp.IsEnterpriseRegEligible__c = rtEntOkay;
                   opp.ClientTracking__c = acct.CSO_Recs__r[0].Id;
                   StringHelper.addToProcessNotes(opp,'Existing Tracking Record Found. Registration Type='+opp.ClientRegistrationType__c);
                   checkAcctRegistration(acct, opp.ClientRegistrationType__c, acctUpdateMap);
                   continue;
                }
             } // if (acct != null
             // will get here if not handled at the Account level
             User owner = userSet.get(opp.OwnerId);
             // is this user subscription only based on their Sales Division?
             // If so, that means we don't create a tracker unless there's a subscription quote
             Boolean subOnly = (owner != null && String.isNotBlank(owner.Sales_Division__c) && subscriptionOnlySalesDivs.contains(owner.Sales_Division__c));
             Boolean hasSubQuote = false;
             // make sure the quote is for this specific opportunity
             for (cafsl__Oracle_Quote__c quote : acct.cafsl__Oracle_Quotes__r) {
                if (quote.cafsl__Opportunity__c == opp.Id) {
                   hasSubQuote=true;
                   break;
                }
             } // for (cafsl__Oracle_Quote__c quote
             // if there isn't a primary opp, or there is a primary opp but this opp has a subscription quote
             Boolean primOppOkay = (opp.Primary_Opportunity__c == null || (opp.Primary_Opportunity__c != null && hasSubQuote));
             System.debug('handleOpptyBefore subOnly='+subOnly+' hasSubQuote='+hasSubQuote+' primOppOkay='+primOppOkay);
              
             RecordType__c rtSetting = getRtSetting(opp.RecordTypeId);
             Boolean rtCSOOkay = (rtSetting != null && rtSetting.CSORegistration__c);
             Boolean rtEntOkay = (cltRegAvail && rtSetting != null && rtSetting.EnterpriseRegistration__c) || (rtCSOOkay && subOnly && hasSubQuote);
             Boolean runningUserIsOwner = (opp.OwnerId == UserInfo.getUserId());
              
             String ownerKey = opp.OwnerId+cltRegPerm;
             Boolean hasOwnerKey = (havePermsSet != null && havePermsSet.contains(ownerKey));
             Boolean hasCsoPerm = (rtCSOOkay && (csoPerm == PERM_ALL 
                                                 || (runningUserIsOwner && runUserHasPermCso)
                                                 || havePermsSet.contains(opp.OwnerId+csoPerm)));
             Boolean hasCltRegPerm = (cltRegAvail && rtEntOkay && primOppOkay &&
                                                 (cltRegPerm == PERM_ALL 
                                                      || (runningUserIsOwner && runUserHasPermEnt)
                                                      || havePermsSet.contains(ownerKey)));
             System.debug('handleOpptyBefore opp='+opp.Name+' hasCsoPerm='+hasCsoPerm+' hasCltRegPerm='+hasCltRegPerm+' runningUserIsOwner='+runningUserIsOwner+' ownerKey='+ownerKey+' hasOwnerKey='+hasOwnerKey+' havePermsSet='+(havePermsSet != null ? havePermsSet.size() : -1)+' runUserHasPermCso='+runUserHasPermCso);
             // default it to NONE - should never stay this because it should hit one of the other cases
             opp.ClientRegistrationType__c=TYPE_NONE;
             // the profile check should be handled at the record type level instead?
             if (hasCsoPerm && !subOnly && owner != null && csoProfList.contains(owner.Profile.Name)) {
                // the owner of the opp has to have a particular profile in order to use CSO - TODO - can this be replaced with just the permission/record type check?
                opp.ClientRegistrationType__c=TYPE_CSO;
                opp.CSO_Eligible__c = rtCSOOkay;
                checkOppProds = true;
                checkAcctRegistration(acct, opp.ClientRegistrationType__c, acctUpdateMap);
             } else if (hasCltRegPerm && (!subOnly || (subOnly && hasSubQuote))) {
                opp.ClientRegistrationType__c=TYPE_ENT;
                opp.IsEnterpriseRegEligible__c = rtEntOkay;
                checkAcctRegistration(acct, opp.ClientRegistrationType__c, acctUpdateMap);
                v_acctMap.put(acct.Id, acct);
             }
             StringHelper.addToProcessNotes(opp, 'ClientRegistrationType='+opp.ClientRegistrationType__c+' hasCsoPerm='+hasCsoPerm+' hasCltRegPerm='+hasCltRegPerm+' runningUserIsOwner='+runningUserIsOwner+' ownerKey='+ownerKey+' hasOwnerKey='+hasOwnerKey
                                            +' havePermsSet='+(havePermsSet != null ? havePermsSet.size() : -1)+' runUserHasPermCso='+runUserHasPermCso+' subOnly='+subOnly
                                            +' hasSubQuote='+hasSubQuote+' primOppOkay='+primOppOkay);
             hasOppsWithCltReg = (hasOppsWithCltReg || CLT_REG_TYPES.contains(opp.ClientRegistrationType__c));
          } // for (Opportunity opp : checkOpps
          System.debug('handleOpptyBeforeInsert acctUpdateMap='+acctUpdateMap.size()+' hasOppsWithCltReg='+hasOppsWithCltReg);
          if (!acctUpdateMap.isEmpty()) {
             SKIP_TRIGGERS=true;
             ZipCheckOwner.SKIP_TRIGGERS=true;
             DmlHelper.performDML2(acctUpdateMap.values(), DmlHelper.DML_UPDATE, CLASSNAME, 'handleOpptyBeforeInsert', 'Update Account Client Registration', true); 
             ZipCheckOwner.SKIP_TRIGGERS=false;
             SKIP_TRIGGERS=false;
          }
       } // if (!ownerIds.isEmpty
       //doesUserHavePermission(Id[] userIds, String[] permNames)
    } // handleOpptyBeforeInsert
    
    public static void checkAcctRegistration(Account acct, String regType, Map<Id,Account> acctUpdateMap) {
       System.debug('checkAcctRegistration acct='+acct.Name+' acct.reg='+acct.ClientRegistrationStatus__c+' regType='+regType);
       if (acct != null && acct.ClientRegistrationStatus__c != TYPE_CLIENT) {
          // make sure if there's already one in the map we use that.
          acct = (acctUpdateMap.containsKey(acct.Id) ? acctUpdateMap.get(acct.Id) : new Account(Id=acct.Id, ClientRegistrationStatus__c=acct.ClientRegistrationStatus__c));
          // TODO - if already CSO, don't move back to Enterprise?
          if (String.isBlank(acct.ClientRegistrationStatus__c) || (acct.ClientRegistrationStatus__c != regType)) {
             acct.ClientRegistrationStatus__c = regType;
             acctUpdateMap.put(acct.Id,acct);
          }
       } // if (acct != null && acct.ClientRegistrationStatus__c != TYPE_CLIENT
    } // checkAcctRegistration
    
    public static Decimal probSoldSubmit = Decimal.valueOf(Label.OppProbSoldSubmitted);

    public static void handleOpptyAfter(Opportunity[] opps, Map<Id,Opportunity> oldMap) {
       System.debug('handleOpptyAfter hasOppsWithCltReg='+hasOppsWithCltReg+' runAfterTrigger='+runAfterTrigger+' checkOppProds='+checkOppProds+' opps='+opps.size()+' evaluateClientValidationSet='+evaluateClientValidationSet.size());
       // if there aren't any opps we need to process we can skip this method
       if (!runAfterTrigger && !checkOppProds) {
          return;
       }
       Map<Id, CSO_Tracking__c> csoAcctMap = new Map<Id, CSO_Tracking__c>();
       Map<Id, Opportunity> oppUpdateMap = new Map<Id, Opportunity>();
       Id[] trackerIds = new Id[]{};
       // cso tracker is the key - account for multiple opps with one tracker
       Map<Id,Opportunity[]> csoRecMap = new Map<Id,Opportunity[]>();
       Map<Id,Opportunity> opptyMap = new Map<Id,Opportunity>();
       // gather the primary quote ids so we can query them later
       Id[] primaryQuoteIds = new Id[]{};
       Id[] cpqTrackerIds = new Id[]{};
       CSO_Tracking__c[] updateTrackers = new CSO_Tracking__c[]{};
       
       // loop through and create new recs if needed
       for (Opportunity opp : opps) {
          Opportunity oldOpp = (oldMap != null ? oldMap.get(opp.Id) : null);
          if (opp.AccountId != null) {
             System.debug('handleOpptyAfter ClientRegistrationType__c='+opp.ClientRegistrationType__c+' Primary_Oracle_Quote__c='+opp.Primary_Oracle_Quote__c+' ClientTracking__c='+opp.ClientTracking__c);
             if (opp.Primary_Oracle_Quote__c != null) {
                primaryQuoteIds.add(opp.Primary_Oracle_Quote__c);
             } // if (opp.Primary_Oracle_Quote__c
             // collect tracker ids if changed to Sold-Submitted in order to start the subscription in OSS via CPQ
             if (opp.IsEnterpriseRegEligible__c && opp.IsPrimaryQuoteSubscription__c && oldOpp != null && opp.ClientTracking__c != null
                      && opp.Probability != oldOpp.Probability && opp.Probability >= probSoldSubmit && oldOpp.Probability < probSoldSubmit) {
                cpqTrackerIds.add(opp.ClientTracking__c);
                CSO_Tracking__c updateTracker = new CSO_Tracking__c(Id=opp.ClientTracking__c, CPQProcessing__c=true, OppStagePreCPQ__c=oldOpp.StageName);
                updateTrackers.add(updateTracker);
             }
             if (opp.ClientRegistrationType__c == TYPE_CSO && opp.ClientTracking__c != null) {
                addToMap(opp.ClientTracking__c, opp, csoRecMap);
             } else if (opp.ClientTracking__c == null && String.isNotBlank(opp.ClientRegistrationType__c) && CLT_REG_TYPES.contains(opp.ClientRegistrationType__c)) {
                // if there isn't a tracker but the Opp should have one
                // check to see if one is in the map (if there were multiple )
                CSO_Tracking__c csoRec = csoAcctMap.get(opp.AccountId);
                if (csoRec == null) {
                   // the opportunity name field is larger than the tracker name field
                   Integer trackerNameSize = CSO_Tracking__c.Name.getDescribe().getLength();
                   csoRec = new CSO_Tracking__c(Name = opp.Name.left(trackerNameSize), AccountId__c = opp.AccountId, Opportunity__c = opp.Id);
                   csoRec.CanUseCSO__c = (opp.ClientRegistrationType__c == TYPE_CSO);
                   csoRec.IsOppCso__c = opp.CSO_Eligible__c;
                   csoRec.IsOppEnterprise__c = opp.IsEnterpriseRegEligible__c;
                   String sandboxName = Utilities.checkForProduction();
                   csoRec.Environment__c = (String.isBlank(sandboxName) ? ENV_PROD : Label.EnterpriseSandboxDefaultEnvironment);
                   // if in a sandbox, try to set it to the right environment based on if it's in the name
                   if (csoRec.Environment__c != ENV_PROD) {
                      Schema.DescribeFieldResult fieldResult = CSO_Tracking__c.Environment__c.getDescribe();
                      Schema.PicklistEntry[] entries = fieldResult.getPicklistValues();
                      for (Schema.PicklistEntry entry : entries) {
                         if (csoRec.Name.contains(entry.getLabel())) {
                            System.debug('handleOpptyAfter Setting environment based on attribute in Name '+entry.getLabel());
                            csoRec.Environment__c = entry.getLabel();
                            break;
                         }
                      }
                   }
                   csoAcctMap.put(csoRec.AccountId__c, csoRec);
                   if (v_acctMap.containsKey(csoRec.AccountId__c)) {
                      Account acct = v_acctMap.get(csoRec.AccountId__c);
                      if (acct.SalesParent__c != null && String.isNotBlank(acct.SalesParent__r.Paychex_CEID__c)) {
                         // the parent was already registered, fill out the parent info
                         csoRec.ParentAccount__c = acct.SalesParent__c;
                         String[] validTypes = EZOnboardingRegistration.getValidChildTypes();
                         csoRec.ChildType__c = (!acct.Account_Junctions__r.isEmpty() && validTypes.contains(acct.Account_Junctions__r[0].Type__c) 
                                                   ? acct.Account_Junctions__r[0].Type__c : validTypes[0]);
                      }
                      if (String.isNotBlank(acct.Paychex_CEID__c) && String.isNotBlank(acct.Paychex_CAID__c)) {
                         csoRec.ExistingEnterpriseClient__c = true;
                         csoRec.CAID__c = acct.Paychex_CAID__c;
                         csoRec.CEID__c = acct.Paychex_CEID__c;
                         csoRec.ClientNumber__c = acct.EnterpriseClientNumber__c;
                         // if we already have a ceid and caid, if we have the required field, push through the registration.
                         if (checkEntRegRequiredFlds(csoRec, acct)) {
                            // kick off the client registration to verify address(es)
                            csoRec.EntRegTest__c = true;
                         }
                         //csoRec.RegistrationStarted__c = true;
                         //csoRec.RegistrationStatusCode__c = '200';
                         // have the tracker automatically try to get the keys
                         //csoRec.TestOSSKeys__c = true;
                      }
                   }
                }
                Opportunity updateOpp = new Opportunity(Id=opp.Id, ClientTracking__r = csoRec, ClientRegistrationType__c=opp.ClientRegistrationType__c);
                oppUpdateMap.put(updateOpp.Id, updateOpp);
                // need to store this version for use later
                opptyMap.put(opp.Id, opp);
             }
          } // if (opp.AccountId != null
       } // for (Opportunity opp : opps
       System.debug('handleOpptyAfter csoAcctMap='+csoAcctMap.size()+' oppUpdateMap='+oppUpdateMap.size()+' cpqTrackerIds='+cpqTrackerIds.size()+' updateTrackers'+updateTrackers.size());
       if (!updateTrackers.isEmpty()) {
          CsoMethods.SKIP_TRIGGERS=true;
          DmlHelper.performDML2(updateTrackers, DmlHelper.DML_UPDATE, CLASSNAME, 'handleOpptyAfter', 'Update Trackers for CPQ', false); 
       }
       if (!csoAcctMap.isEmpty()) {
          // these are inserts
          CsoMethods.SKIP_TRIGGERS=false;
          DmlHelper.performDML2(csoAcctMap.values(), DmlHelper.DML_INSERT, CLASSNAME, 'handleOpptyAfter', 'Insert CSO Tracking Record', false); 
          for (Opportunity opp : oppUpdateMap.values()) {
             if (opp.ClientTracking__r != null && opp.ClientTracking__r.Id != null) {
                System.debug('handleOpptyAfter setting ClientTracking ClientRegistrationType__c='+opp.ClientRegistrationType__c);
                opp.ClientTracking__c = opp.ClientTracking__r.Id;
                opp.ClientTracking__r = null;
                trackerIds.add(opp.ClientTracking__c);
                if (opp.ClientRegistrationType__c == TYPE_CSO) {
                   addToMap(opp.ClientTracking__c, opptyMap.get(opp.Id), csoRecMap);
                }
             }
          } // for (Opportunity opp : updateOpp.values
          OpptyMethods.SKIP_OPPTY_TRIGGERS=true;
          DmlHelper.performDML2(oppUpdateMap.values(), DmlHelper.DML_UPDATE, CLASSNAME, 'handleOpptyAfter', 'Update Opportunities', false); 
          OpptyMethods.SKIP_OPPTY_TRIGGERS=false;
       } // if (!csoAcctMap.isEmpty
       System.debug('handleOpptyAfter csoRecMap='+csoRecMap.size());
       if (checkOppProds) {
          checkForOpptyCsoUpdates(csoRecMap, primaryQuoteIds);
       }
       // get the cso records to evaluate
       if (!evaluateClientValidationSet.isEmpty()) {
          Id[] acctIds = new Id[]{};
          acctIds.addAll(evaluateClientValidationSet);
          Map<Id, CSO_Tracking__c> csoMap = getCsoRecs(acctIds);
          System.debug('handleOpptyAfter in evaluateClientValidationSet csoMap='+csoMap.size());
          for (Id acctId : csoMap.keySet()) {
              csoAcctMap.put(acctId, csoMap.get(acctId));
          }
       } // if (!evaluateClientValidationSet
       System.debug('handleOpptyAfter before calling validateAccounts csoAcctMap='+csoAcctMap.size());
       if (!csoAcctMap.isEmpty()) {
          // do the account validation on inserts or if manually triggered
          Id[] acctIds = new Id[]{};
          acctIds.addAll(csoAcctMap.keySet());
          String queryString = getQuery(QUERY_ACCT)+' where Id in :acctIds ';
          Account[] acctList = Database.query(queryString);
          validateAccounts(acctList, null, csoAcctMap,null, evaluateClientValidationSet);
       }
       if (!cpqTrackerIds.isEmpty()) {
          EnterpriseRegistration entReg = new EnterpriseRegistration(EnterpriseRegistration.MODE_CPQ_KEYS, cpqTrackerIds);
          EnterpriseRegistration.launchJob(entReg);
       }
       ErrorLog.checkSave();
    } // handleOpptyAfter
    
    
    public static Boolean checkEntRegRequiredFlds(CSO_Tracking__c tracker, Account acct) {
       String[] missingFlds = new String[]{};
       Schema.FieldSet fieldSet = Schema.SObjectType.Account.fieldSets.EntRegReqFlds;
       for (Schema.FieldSetMember fsm : fieldSet.getFields()) {
           String fldName = fsm.getFieldPath();
           if(acct.get(fldName) == null){
               missingFlds.add(fsm.getLabel());
           }
       } // for (Schema.FieldSetMember fsm : fieldSet.getFields
       tracker.RequiredFlds__c = (!missingFlds.isEmpty() ? String.join(missingFlds,', ') : null);
       return missingFlds.isEmpty();
    } // checkEntRegRequiredFlds
    
    public static void addToMap(Id csoId, Opportunity opp, Map<Id,Opportunity[]> csoRecMap) {
       Opportunity[] csoOpps = (csoRecMap.containsKey(csoId) ? csoRecMap.get(csoId) : new Opportunity[]{});
       csoOpps.add(opp);
       csoRecMap.put(csoId, csoOpps);
    } // addToMap
    
    // if existing tracker record, make sure it's connected to the most "relevant" opp
    // Most relevant:
    //     Highest Probability with Revenue
    //     
    public static void evalCheckTrackerOpp(Opportunity[] opps, Map<Id,Opportunity> oldMap) {
       Id[] acctIds = new Id[]{};
       for (Opportunity opp : opps) {
          if (opp.AccountId != null && opp.ClientTracking__c != null && String.isNotBlank(opp.ClientRegistrationType__c) && CLT_REG_TYPES.contains(opp.ClientRegistrationType__c)) {
             Opportunity oldOpp = (oldMap != null ? oldMap.get(opp.Id) : null);
             // if anything pertinent changes we'll re-evaluate
             if (oldOpp == null || (opp.isClosed && !oldOpp.IsClosed) || (opp.Probability != oldOpp.Probability) || (opp.Amount != oldOpp.Amount)) {
                acctIds.add(opp.AccountId);
             }
             
          }
       } // for (Opportunity opp
       System.debug('evalCheckTrackerOpp opps='+opps.size()+' acctIds='+acctIds.size()+' oldMap='+(oldMap != null));
       if (!acctIds.isEmpty()) {
          checkTrackerOpp(acctIds);
       }
    } // evalCheckTrackerOpp
    
    public static void checkTrackerOpp(Id[] acctIds) {
       Account[] accts = [Select Id, Name, ClientRegistrationStatus__c, Paychex_CEID__c, Paychex_CAID__c
                                ,(Select Id, AccountId__c, Contact__c, Opportunity__c, CanUseCSO__c 
                                    from CSO_Recs__r order by CreatedDate desc limit 1)
                                ,(Select Id, Name, Amount, Probability, CreatedDate, ClientRegistrationType__c
                                    From Opportunities
                                   Where ClientRegistrationType__c in :CLT_REG_TYPES
                                     And IsClosed = false
                                   order by Probability desc, Amount desc nulls last, CreatedDate desc limit 1)
                            From Account
                           Where Id in :acctIds];
       Map<Id,CSO_Tracking__c> trackerUpdateMap = new Map<Id,CSO_Tracking__c>();
       for (Account acct : accts) {
          CSO_Tracking__c tracker = (acct.CSO_Recs__r.isEmpty() ? null : acct.CSO_Recs__r[0]);
          System.debug('checkTrackerOpp acct='+acct.Name+' tracker='+(tracker != null)+' opps='+acct.Opportunities.size());
          if (tracker != null) {
             // the first opp selected should be the most relevant
             if (!acct.Opportunities.isEmpty()) {
                if (tracker.Opportunity__c != acct.Opportunities[0].Id) {
                   tracker.Opportunity__c = acct.Opportunities[0].Id;
                   trackerUpdateMap.put(tracker.Id, tracker);
                }
             }
          } // if (tracker != null
       } // for (Account acct
       System.debug('checkTrackerOpp trackerUpdateMap='+trackerUpdateMap.size());
       if (!trackerUpdateMap.isEmpty()) {
          SKIP_TRIGGERS=true;
          DmlHelper.performDML2(trackerUpdateMap.values(), DmlHelper.DML_UPDATE, CLASSNAME, 'checkTrackerOpp', 'Update CSO Record', true); 
          SKIP_TRIGGERS=false;
       }
    } // checkTrackerOpp
    
    // this is for testing purposes
    public static Boolean includeQueryReg=true;
    
    public static Map<Id, CSO_Tracking__c> getCsoRecs(Id[] p_queryIds) {
       return getCsoRecs(p_queryIds, true);
    } // getCsoRecs
    
    public static Map<Id, CSO_Tracking__c> getCsoRecs(Id[] p_queryIds, Boolean checkReg) {
       Id[] queryIds = p_queryIds;
       Map<Id, CSO_Tracking__c> csoMap = new Map<Id, CSO_Tracking__c>();
       String queryString = getQuery(QUERY_CSO)+' where (Id in :queryIds or AccountId__c in :queryIds) '+(includeQueryReg && checkReg ? ' and RegistrationStarted__c = false ' : '')+' order by CreatedDate desc ';
       CSO_Tracking__c[] csos = Database.query(queryString);
       System.debug('getCsoRecs queryIds='+queryIds.size()+' csos='+csos.size());
       for (CSO_Tracking__c cso : csos) {
          if (queryIds.contains(cso.Id) && !csoMap.containsKey(cso.Id)) {
             csoMap.put(cso.Id,cso);
          }
          if (cso.AccountId__c != null && queryIds.contains(cso.AccountId__c) && !csoMap.containsKey(cso.AccountId__c)) {
             csoMap.put(cso.AccountId__c,cso);
          }
       }
       System.debug('getCsoRecs csoMa='+csoMap.size());
       return csoMap;
    } // getCsoRecs
    
    public static void checkForOpptyCsoUpdates(Map<Id,Opportunity[]> csoRecMap, Id[] primaryQuoteIds) {
       System.debug('checkForOpptyCsoUpdates csoRecMap='+csoRecMap.size()+' primaryQuoteIds='+primaryQuoteIds.size());
       // query the CSO recs
       Id[] csoIds = new Id[]{};
       csoIds.addAll(csoRecMap.keySet());
       
       Map<Id, CSO_Tracking__c> csoMap = getCsoRecs(csoIds);
       Map<Id, CSO_Tracking__c> csoUpdateMap = new Map<Id, CSO_Tracking__c>();
        
       // get the quote and quote lines for product validation
       Map<Id, cafsl__Oracle_Quote__c> quoteMap = getQuotes(primaryQuoteIds);
        
       System.debug('checkForOpptyCsoUpdates csoRecMap='+csoRecMap.size()+' primaryQuoteIds='+primaryQuoteIds.size()+' quoteMap='+quoteMap.size());
       for (Id csoId : csoRecMap.keySet()) {
          Opportunity[] opps = csoRecMap.get(csoId);
          CSO_Tracking__c cso = csoMap.get(csoId);
          System.debug('checkForOpptyCsoUpdates csoId='+csoId+' opps='+(opps != null)+' cso='+(cso != null));
          if (cso != null && opps != null) {
             //cso.OpportunityLastChecked__c=Datetime.now();
             csoUpdateMap.put(cso.Id,cso);
             for (Opportunity opp : opps) {
                // extra validation with CSO
                System.debug('checkForOpptyCsoUpdates RegType='+opp.ClientRegistrationType__c);
                if (opp.ClientRegistrationType__c == TYPE_CSO) {
                   checkForKnockouts(null, opp, cso, null);
                }
                if (opp.ClientRegistrationType__c == TYPE_CSO || opp.ClientRegistrationType__c == TYPE_ENT) {
                   checkForProductKnockouts(cso, (opp.Primary_Oracle_Quote__c != null ? quoteMap.get(opp.Primary_Oracle_Quote__c) : null), opp.ClientRegistrationType__c);
                } // if (opp.ClientRegistrationType__c == TYPE_CSO
            } // for (Opportunity opp : opps
          } // if (csoRec != null && opps != null
       } // for (Id csoId : csoRecMap
       DmlHelper.performDML2(csoUpdateMap.values(), DmlHelper.DML_UPDATE, CLASSNAME, 'checkForOpptyCsoUpdates', 'Update CSO Record', false); 

    } // checkForOpptyCsoUpdates
    
    public static void isOppEligible(CSO_Tracking__c cso) {
       System.debug('isOppEligible ProductsValidated__c='+cso.ProductsValidated__c+' OpportunityFieldsValidated__c='+cso.OpportunityFieldsValidated__c+' Account_Eligible__c='+cso.Account_Eligible__c);
       Boolean oppEligible = (cso.ProductsValidated__c && cso.OpportunityFieldsValidated__c && cso.Account_Eligible__c);
//       Boolean oppEligible = (cso.ProductsValidated__c && cso.OpportunityFieldsValidated__c);
       if (cso.Opportunity_Eligible__c != oppEligible) {
          StringHelper.addToProcessNotes(cso,'isOppEligible changing Opp Eligible='+oppEligible+' ProductsValidated='+cso.ProductsValidated__c+' OpportunityFieldsValidated='+cso.OpportunityFieldsValidated__c+' Account_Eligible='+cso.Account_Eligible__c);
          cso.Opportunity_Eligible__c = oppEligible; 
       }
    } // isOppEligible
    
    public static Map<Id, cafsl__Oracle_Quote__c> getQuotes(Id[] recordIds) {
        
       Map<Id, cafsl__Oracle_Quote__c> quoteMap = (recordIds.isEmpty() ? new Map<Id,cafsl__Oracle_Quote__c>()
                                                   : new Map<Id,cafsl__Oracle_Quote__c>([Select Id, Name, IsSubscriptionQuote__c
                                                                                               ,(Select Id,BillingType__c,Prospect_Client__c
                                                                                                       ,TestPackage__c,TestProductName__c
                                                                                                       ,cafsl__Oracle_Quote__r.cafsl__Opportunity__c 
                                                                                                       ,cafsl__Product__c,cafsl__Product__r.CSO_Eligible__c
                                                                                                       ,cafsl__Product__r.Is_Package__c
                                                                                                       ,cafsl__Product__r.CSO_Required__c, cafsl__Product__r.Name 
                                                                                                       ,cafsl__Product__r.CSOOnly__c
                                                                                                       ,cafsl__Product__r.UseSST__c
                                                                                                       ,cafsl__Product__r.DoNotDisplay__c
                                                                                                       ,cafsl__Product__r.ProductCode
                                                                                                   from cafsl__Oracle_Quote_Line_Items1__r)
                                                                                           From cafsl__Oracle_Quote__c
                                                                                          Where Id in :recordIds or cafsl__Opportunity__c in :recordIds]));
       System.debug('getQuotes recordIds='+recordIds.size()+' quoteMap='+quoteMap.size());
       return quoteMap;
    } // getQuotes
    
    public static Boolean validateAddress=(Label.EZOnboarding_ValidateAddress=='Y');
    
    public static void handleAfterAcctUpdate(List <Account> accountList, Map<Id,Account> oldMap){
        List<Id> parentList = new List<Id>();
        List<Id> parentUpdateList = new List<Id>();
        Map<Id, Account> acctsToValidateMap = new Map<Id, Account>();
        for (Account acct : accountList) {
            Account oldAcct = (oldMap != null ? oldMap.get(acct.Id) : null);
            // these records should have CSO recs - we'll check later
            if (String.isNotBlank(acct.ClientRegistrationStatus__c) && CLT_REG_TYPES.contains(acct.ClientRegistrationStatus__c)) {
               acctsToValidateMap.put(acct.Id, acct);
            }
            //Check for Sales Parent Account added
            if(oldAcct != null && acct.SalesParent__c != oldAcct.SalesParent__c) {
                if(acct.SalesParent__c!=null){
                    System.debug('CSO METHODS - Parent Account found: '+acct.SalesParent__c);
                    parentUpdateList.add(acct.SalesParent__c);
                    parentList.add(acct.SalesParent__c);
                }else{
                    parentList.add(oldMap.get(acct.Id).SalesParent__c);
                }
            }
        } // for (Account acct : accountList
        if (!parentList.isEmpty()) {
            // see if any of the parents are in the registration process
            String parentAcctQuery = getQuery(QUERY_ACCT)+' where Id in :parentList and ClientRegistrationStatus__c in :CLT_REG_TYPES ';
            Account[] accts = Database.query(parentAcctQuery);
            for (Account acct : accts) {
                acctsToValidateMap.put(acct.Id, acct);
            }
        } // if (!parentList.isEmpty())
        
        //Only validate if CSO record exists
        System.debug('handleAfterAcctUpdate acctsToValidateMap='+acctsToValidateMap.size());
        if (!acctsToValidateMap.isEmpty()) {
           // for the cso validation
           Account[] acctValidateList = new Account[]{};
           // for the subscription address validation
           Id[] validTrackerIds = new Id[]{};
           Id[] shippingIds = new Id[]{};
           Id[] billingIds = new Id[]{};
               
           Id[] acctQueryIds = new Id[]{};
           acctQueryIds.addAll(acctsToValidateMap.keySet());
            
           Map<Id, CSO_Tracking__c> csoMap = getCsoRecs(acctQueryIds);
           for (Account acct : acctsToValidateMap.values()) {
              Account oldAcct = (oldMap != null ? oldMap.get(acct.Id) : null);

              CSO_Tracking__c tracker = csoMap.get(acct.Id);
              if (tracker != null) {
                 Boolean isCso = ((tracker.CanUseCSO__c || tracker.IsOppCso__c) && !tracker.RegistrationStarted__c);
                 Boolean isSub = (tracker.HasSubscriptionQuote__c && !tracker.RegistrationStarted__c);
                 Boolean shipChanged = (isSub && oldAcct != null && EZOnboardingRegistration.checkShipping(acct,oldAcct));
                 Boolean billChanged = (isSub && oldAcct != null && EZOnboardingRegistration.checkBilling(acct,oldAcct));
                 if (isCso) {
                    acctValidateList.add(acct);
                 }
                 if (isSub && (shipChanged || billChanged)) {
                    validTrackerIds.add(tracker.Id);
                    if (shipChanged) {
                       shippingIds.add(tracker.Id);
                    }
                    if (billChanged) {
                       billingIds.add(tracker.Id);
                    }
                 }
              }
          } // for (Account acct : acctsToValidateMap.values
          System.debug('handleAfterAcctUpdate acctValidateList='+acctValidateList.size()+ 'csoMap='+csoMap.size()+' parentUpdateList='+parentUpdateList.size());
          if (!acctValidateList.isEmpty()) {
             validateAccounts(acctValidateList, oldMap, csoMap,parentUpdateList, null);
          }
          if (!validTrackerIds.isEmpty()) {
             EnterpriseRegistration entReg = new EnterpriseRegistration(EZOnboardingRegistration.CLT_VALIDATE, validTrackerIds, new Id[]{}, shippingIds, billingIds);
             EnterpriseRegistration.launchJob(entReg);
          }
            
       } // if (!acctsToValidate.isEmpty
    } // handleAfterAcctUpdate
    
    public static void handleAfterCtctUpdate(List <Contact> contactList, Map<Id,Contact> oldMap){
        System.debug('handleAfterCtctUpdate contactList='+contactList.size());
        List<Id> acctIdList = new List<Id>();
        for(Contact con : contactList){
            Contact oldContact = oldMap.get(con.Id);
            if(con.Email != oldContact.Email){
                acctIdList.add(con.AccountId);
            }
        }
        if(!acctIdList.isEmpty()){
            List<Id> csoAcctIds = new List<Id>();
            String queryString = getQuery(QUERY_CSO)+' where AccountId__c in:acctIdList and RegistrationStarted__c = false';
            Map<Id, CSO_Tracking__c> csoMap = new Map<Id, CSO_Tracking__c>();
            List<CSO_Tracking__c> csoList = Database.query(queryString);
            if(!csoList.isEmpty()){
                
                for(CSO_Tracking__c csoRec : csoList){
                    csoRec.User_Validated__c = false;
                    isOppEligible(csoRec);
                    //csoRec.Opportunity_Eligible__c = false;
                    csoMap.put(csoRec.AccountId__c,csoRec);
                    csoAcctIds.add(csoRec.AccountId__c);
                }
                update csoList;               
            }
            //Validate Accounts
            if(!csoAcctIds.isEmpty()){
                String acctQueryString = getQuery(QUERY_ACCT)+' where Id in:csoAcctIds';
                List<Account> acctList = Database.query(acctQueryString);
                Set<Id> acctIdSet = new Set<Id>();
                acctIdSet.addAll(acctIdList);
                validateAccounts(acctList, null, csoMap, null, acctIdSet);
            }
        }
    } // handleAfterCtctUpdate
    
    public static void handleAfterQuoteUpdate(List<cafsl__Oracle_Quote__c> quoteList){
        List<Id> opptyIdList = new List<Id>();
        // keep track of the quotes for subscription. Make sure there are trackers for those. If there aren't, reset the fields on the opp and try to retrigger
        Set<Id> subscriptionQuoteOppIds = new Set<Id>();
        for (cafsl__Oracle_Quote__c quote : quoteList) {
            opptyIdList.add(quote.cafsl__Opportunity__c);
            if (quote.IsSubscriptionQuote__c) {
               subscriptionQuoteOppIds.add(quote.cafsl__Opportunity__c);
            }
        } // for (cafsl__Oracle_Quote__c quote
        
        // if a subscription quote is set, check the non-legal addresses
        Id[] trackersForAddrValidation = new Id[]{};

        //Does the Opportunity have a tracker?
        System.debug('handleAfterQuoteUpdate opptyIdList='+opptyIdList);
        List<CSO_Tracking__c> csoList = [Select id,Opportunity__c,Opportunity__r.Primary_Oracle_Quote__c, Opportunity__r.ClientRegistrationType__c
                                                ,ProductsValidated__c,ProductKnockout__c,ProductKnockoutDetail__c,ProductKnockoutMessage__c
                                                ,OpportunityFieldsValidated__c, ProcessNotes__c, RegistrationStarted__c
                                                ,Account_Eligible__c, AccountLastChecked__c, HasSubscriptionQuote__c
                                                ,User_Validated__c,Opportunity_Eligible__c, OpportunityLastChecked__c
                                                ,CSOOnlyProds__c, Product_Bundle__c
                                           from CSO_Tracking__c where Opportunity__c in:opptyIdList];
        System.debug('handleAfterQuoteUpdate quoteList='+quoteList.size()+' csoList='+csoList.size());
        if (!csoList.isEmpty()) {
           // see if there are any quotes on the opp that are subscription quotes
           AggregateResult[] results = [Select count(Id) nbrRecs, cafsl__Opportunity__c oppId
                                          From cafsl__Oracle_Quote__c
                                         Where IsSubscriptionQuote__c=true
                                           and cafsl__Opportunity__c in :opptyIdList
                                      group by cafsl__Opportunity__c];
           Map<Id,Boolean> subscriptionMap = new Map<Id,Boolean>();
           for (AggregateResult result : results) {
              Id oppId = (Id)result.get('oppId');
              Integer nbrRecs = Integer.valueOf(result.get('nbrRecs'));
              if (nbrRecs > 0) {
                 subscriptionMap.put(oppId,true);
              }
           } // for (AggregateResult result
            
            Map<Id, CSO_Tracking__c> csoMap = new Map<Id, CSO_Tracking__c>();
            List<CSO_Tracking__c> csoUpdateList = new List<CSO_Tracking__c>();
            //List<Id> csoOpptyIdList = new List<Id>();
            Id[] quoteIds = new Id[]{};
            
            // get the actual primary quotes
            for (CSO_Tracking__c cso : csoList) {
                if (cso.Opportunity__r != null && cso.Opportunity__r.Primary_Oracle_Quote__c != null) {
                   quoteIds.add(cso.Opportunity__r.Primary_Oracle_Quote__c);
                }
            } // for (CSO_Tracking__c cso
            Map<Id, cafsl__Oracle_Quote__c> quoteMap = getQuotes(quoteIds);

            for (CSO_Tracking__c cso : csoList) {
               Boolean changed = false;
               cafsl__Oracle_Quote__c quote = (cso.Opportunity__c != null && cso.Opportunity__r.Primary_Oracle_Quote__c != null ? quoteMap.get(cso.Opportunity__r.Primary_Oracle_Quote__c) : null);
               Boolean hasSubscription = subscriptionMap.containsKey(cso.Opportunity__c);
               if (cso.HasSubscriptionQuote__c != hasSubscription) {
                  cso.HasSubscriptionQuote__c = hasSubscription;
                  changed = true;
                  if (cso.HasSubscriptionQuote__c) {
                     trackersForAddrValidation.add(cso.Id);
                  }
               }
               if (cso.Opportunity__c != null) {
                  subscriptionQuoteOppIds.remove(cso.Opportunity__c);
               }
               if (cso.Opportunity__c != null 
                      && (cso.Opportunity__r.ClientRegistrationType__c == TYPE_CSO || cso.Opportunity__r.ClientRegistrationType__c == TYPE_ENT)
                      && !cso.RegistrationStarted__c) {
                  changed = (checkForProductKnockouts(cso, quote, cso.Opportunity__r.ClientRegistrationType__c) || changed);
               }
               if (changed) {
                  csoUpdateList.add(cso);
               }
            } // for (CSO_Tracking__c cso : csoList
            CsoMethods.SKIP_TRIGGERS=true;
            DmlHelper.performDML2(csoUpdateList, DmlHelper.DML_UPDATE, CLASSNAME, 'handleAfterQuoteUpdate', 'Update CSO Tracking Record', true); 
        } // if(!csoList.isEmpty
        
        System.debug('handleAfterQuoteUpdate subscriptionQuoteOppIds='+subscriptionQuoteOppIds);
        if (!subscriptionQuoteOppIds.isEmpty()) {
           // we want to re-trigger these opportunities to see if it will create a tracker
           Opportunity[] opps = new Opportunity[]{};
           for (Id oppId : subscriptionQuoteOppIds) {
              Opportunity opp = new Opportunity(Id=oppId, ClientRegistrationType__c=null, ClientRegistrationForce__c=true);
              opps.add(opp);
           }
           OpptyMethods.SKIP_OPPTY_TRIGGERS=false;
           // we need the cso code to fire for the opp
           CsoMethods.SKIP_TRIGGERS=false;
           TriggerMethods.clearVariables();
           DmlHelper.performDML2(opps, DmlHelper.DML_UPDATE, CLASSNAME, 'handleAfterQuoteUpdate', 'Update Opportunities to trigger tracker', true); 

        } // if (!subscriptionQuoteOppIds.isEmpty
       if (!trackersForAddrValidation.isEmpty()) {
          EnterpriseRegistration entReg = new EnterpriseRegistration(EZOnboardingRegistration.CLT_VALIDATE, trackersForAddrValidation, new Id[]{}, trackersForAddrValidation, trackersForAddrValidation);
          EnterpriseRegistration.launchJob(entReg);
       }

    } // handleAfterQuoteUpdate
    
    // all checked in the before trigger but executed in the after trigger
    public static Id[] entRegTrackerIds = new Id[]{};
    public static Id[] ossKeyIds = new Id[]{};
    public static Id[] cpqKeyIds = new Id[]{};
    public static Id[] cpqSubIds = new Id[]{};
    public static Set<Id> legalUpdateSet = new Set<Id>();
    public static Id[] legalNameIds = new Id[]{};
    public static Id[] legalAddrIds = new Id[]{};
    public static Set<Id> validateUpdateSet = new Set<Id>();
    public static Id[] shipAddrIds = new Id[]{};
    public static Id[] billAddrIds = new Id[]{};
    public static Id[] cltLegalIds = new Id[]{};
    
    public void handleCSOUpdate(List <CSO_Tracking__c> csoList, Map<Id,CSO_Tracking__c> oldMap){
        System.debug('handleCSOUpdate csoList='+csoList.size());
        entRegTrackerIds.clear();
        ossKeyIds.clear();
        cpqKeyIds.clear();
        cpqSubIds.clear();
        legalUpdateSet.clear();
        legalNameIds.clear();
        legalAddrIds.clear();
        validateUpdateSet.clear();
        shipAddrIds.clear();
        billAddrIds.clear();
        cltLegalIds.clear();
        
        for (CSO_Tracking__c csoRecord : csoList) {
           if (csoRecord.SkipTriggers__c) {
              SKIP_TRIGGERS=true;
              csoRecord.SkipTriggers__c = false;
           }
           if (!SKIP_TRIGGERS) {
            CSO_Tracking__c oldRec = oldMap.get(csoRecord.Id);
            if(csoRecord.CsoException__c && !oldRec.CsoException__c){
                csoRecord.CsoExceptionDate__c = Date.today();
            }
            if (String.isBlank(csoRecord.Environment__c)) {
                // is this prod?
                // if not, set to default environment in the Label
                String sandboxName = Utilities.checkForProduction();
                csoRecord.Environment__c = (String.isBlank(sandboxName) ? ENV_PROD : Label.EnterpriseSandboxDefaultEnvironment);
            } // if (String.isBlank(csoRecord.Environment__c
            if (String.isBlank(csoRecord.TrackerUUID__c)) {
               csoRecord.TrackerUUID__c = System.UUID.randomUUID().toString();
            }
            // increment the counter so we can see that multiple exceptions were logged
            if (oldRec != null && csoRecord.ExceptionStatus__c == 'Pending' && csoRecord.ExceptionStatus__c != oldRec.ExceptionStatus__c) {
               csoRecord.ExceptionCount__c = (csoRecord.ExceptionCount__c != null ? csoRecord.ExceptionCount__c + 1 : 1);
            }
            System.debug('handleCSOUpdate cso id='+csoRecord.Id+' EntRegTest__c='+csoRecord.EntRegTest__c);
            // right now only handle 1 for testing - will update eventually to handle more
            if (csoRecord.Id != null && csoRecord.EntRegTest__c && entRegTrackerIds.isEmpty()) {
               entRegTrackerIds.add(csoRecord.Id);
               csoRecord.EntRegTest__c = false;
            //} else if (csoRecord.Id != null && csoRecord.TestOSSKeys__c && ossKeyIds.isEmpty()) {
            } else if (csoRecord.Id != null && csoRecord.TestOSSKeys__c) {
               ossKeyIds.add(csoRecord.Id);
               csoRecord.TestOSSKeys__c = false;
               // reset the value so we don't have to do it manually.
               csoRecord.OSSKeysNbrTries__c = 0;
               csoRecord.OSSKeysMaxTries__c = false;
               // TODO - this should happen as the result of a successful registration
            } else if (csoRecord.Id != null && csoRecord.TestCPQKeys__c && cpqKeyIds.isEmpty()) {
               csoRecord.CPQProcessing__c = true;
               cpqKeyIds.add(csoRecord.Id);
               csoRecord.TestCPQKeys__c = false;
            } else if (csoRecord.Id != null && csoRecord.TestCPQSub__c && cpqSubIds.isEmpty()) {
               cpqSubIds.add(csoRecord.Id);
               csoRecord.TestCPQSub__c = false;
            }
            if (csoRecord.Id != null && csoRecord.TestLegalNameUpdate__c) {
               legalUpdateSet.add(csoRecord.Id);
               legalNameIds.add(csoRecord.Id);
               csoRecord.TestLegalNameUpdate__c=false;
            }
            if (csoRecord.Id != null && csoRecord.TestLegalAddressUpdate__c) {
               legalUpdateSet.add(csoRecord.Id);
               legalAddrIds.add(csoRecord.Id);
               csoRecord.TestLegalAddressUpdate__c=false;
            }
            if (csoRecord.Id != null && csoRecord.TestLegalNameUpdate__c) {
               legalUpdateSet.add(csoRecord.Id);
               legalNameIds.add(csoRecord.Id);
               csoRecord.TestLegalNameUpdate__c=false;
            }
            if (csoRecord.Id != null && csoRecord.TestBillingValidation__c) {
               validateUpdateSet.add(csoRecord.Id);
               billAddrIds.add(csoRecord.Id);
               csoRecord.TestBillingValidation__c=false;
            }
            if (csoRecord.Id != null && csoRecord.TestShippingValidation__c) {
               validateUpdateSet.add(csoRecord.Id);
               shipAddrIds.add(csoRecord.Id);
               csoRecord.TestShippingValidation__c=false;
            }
            if (csoRecord.Id != null && csoRecord.TestClientValidation__c) {
               validateUpdateSet.add(csoRecord.Id);
               cltLegalIds.add(csoRecord.Id);
               csoRecord.TestClientValidation__c=false;
            }
          } // if (!SKIP_TRIGGERS
        } // for (CSO_Tracking__c csoRecord : csoList
        System.debug('handleCSOUpdate entRegTrackerIds='+entRegTrackerIds.size()+' cpqKeyIds='+cpqKeyIds.size()+' cpqSubIds='+cpqSubIds.size()
                     +' legalUpdateSet='+legalUpdateSet.size()+' legalNameIds='+legalNameIds.size()+' legalAddrIds='+legalAddrIds.size()
                     +' validateUpdateSet='+validateUpdateSet.size()+' billAddrIds='+billAddrIds.size()+' shipAddrIds='+shipAddrIds.size()
                     +' cltLegalIds='+cltLegalIds.size());
    } // handleCSOUpdate
    
    public void handleCsoAfter(CSO_Tracking__c[] trackers, Map<Id,CSO_Tracking__c> oldMap) {
       // to create onboarding recs
       Map<Id,CSO_Tracking__c> onboardTrackerMap = new Map<Id,CSO_Tracking__c>();
       Id[] trackerIds = new Id[]{};
       Id[] cttAcctIds = new Id[]{};
       Id[] cttOppIds = new Id[]{};
       Onboarding_Tool__c[] newOnboardings = new Onboarding_Tool__c[]{};
       CSO_Tracking__c[] updateTrackers = new CSO_Tracking__c[]{};
       // map by Onboarding record id
       Map<Id,CSO_Tracking__c> checkMultiIdMap = new Map<Id,CSO_Tracking__c>();
       for (CSO_Tracking__c tracker : trackers) {
          CSO_Tracking__c oldRec = (oldMap != null ? oldMap.get(tracker.Id) : null);
          System.debug('handleCsoAfter tracker.IsOppEnterprise__c='+tracker.IsOppEnterprise__c);
          if (tracker.Onboarding_Tool__c == null && tracker.IsOppEnterprise__c) {
             // if a tracker for an enterprise tracker, always create an onboarding record.
             //Onboarding_Tool__c newOnboardingRec = new Onboarding_Tool__c(Opportunity_Id__c = tracker.Opportunity__c , AccountId__c = tracker.AccountId__c
             //                                                           , ClientTracking__c=tracker.Id);
             //newOnboardingRec.Company_Contact__c = tracker.Contact__c;
             //newOnboardingRec.Sales_Parent__c = (acct != null ? acct.SalesParent__c : null);
             //Integer onboardingNameSize = Onboarding_Tool__c.Name.getDescribe().getLength();
             //newOnboardingRec.Name = tracker.Name.left(onboardingNameSize);
             Onboarding_Tool__c newOnboardingRec = createOnboarding(tracker);
             newOnboardings.add(newOnboardingRec);
             CSO_Tracking__c updateTracker = new CSO_Tracking__c(Id=tracker.Id, Onboarding_Tool__r=newOnboardingRec);
             updateTrackers.add(updateTracker);
          } else if (tracker.Onboarding_Tool__c != null && tracker.RegistrationStarted__c && oldRec != null && !oldRec.RegistrationStarted__c && tracker.ParentTracker__c == null) {
             // once the onboarding tool lookup is populated, create a reference and case record
             onboardTrackerMap.put(tracker.Onboarding_Tool__c, tracker);
             cttAcctIds.add(tracker.AccountId__c);
             cttOppIds.add(tracker.Opportunity__c);
             trackerIds.add(tracker.Id);
          }
          if (oldRec != null && tracker.Onboarding_Tool__c != null && tracker.ChildType__c != oldRec.ChildType__c) {
             checkMultiIdMap.put(tracker.Onboarding_Tool__c, tracker);
          }
       } // for (CSO_Tracking__c tracker : trackers
            
       System.debug('handleCsoAfter entRegTrackerIds='+entRegTrackerIds.size()+' cpqKeyIds='+cpqKeyIds.size()+' cpqSubIds='+cpqSubIds.size()
                       +' onboardTrackerMap='+onboardTrackerMap.size()+' newOnboardings='+newOnboardings.size()+' checkMultiIdMap='+checkMultiIdMap.size());
       if (!checkMultiIdMap.isEmpty()) {
          checkMultiIdSettings(checkMultiIdMap);
       }
       if (!entRegTrackerIds.isEmpty()) {
          EZOnboardingRegistration.startEntRegRequestNow(entRegTrackerIds[0], false);
       } // 
       if (!ossKeyIds.isEmpty()) {
          EZOnboardingRegistration.startOssKeysRequestNow(ossKeyIds[0]);
       } // 
       if (!cpqKeyIds.isEmpty()) {
          EnterpriseRegistration entReg = new EnterpriseRegistration(EnterpriseRegistration.MODE_CPQ_KEYS, cpqKeyIds);
          EnterpriseRegistration.launchJob(entReg);
       } // if (!cpqKeyIds.isEmpty
       if (!cpqSubIds.isEmpty()) {
          EnterpriseRegistration entReg = new EnterpriseRegistration(EnterpriseRegistration.MODE_CPQ_SUB, cpqSubIds);
          EnterpriseRegistration.launchJob(entReg);
       }
       if (!legalUpdateSet.isEmpty()) {
          Id[] legalTrackerIds = new Id[]{};
          legalTrackerIds.addAll(legalUpdateSet);
          EnterpriseRegistration entReg = new EnterpriseRegistration(EZOnboardingRegistration.REG_CLT_UPDATE, legalTrackerIds, legalNameIds, legalAddrIds);
          EnterpriseRegistration.launchJob(entReg);
       }
       if (!validateUpdateSet.isEmpty()) {
          Id[] validateTrackerIds = new Id[]{};
          validateTrackerIds.addAll(validateUpdateSet);
          EnterpriseRegistration entReg = new EnterpriseRegistration(EZOnboardingRegistration.CLT_VALIDATE, validateTrackerIds, cltLegalIds, shipAddrIds, billAddrIds);
          EnterpriseRegistration.launchJob(entReg);
       }
       
       if (!newOnboardings.isEmpty()) {
          DmlHelper.performDML2(newOnboardings, DmlHelper.DML_INSERT, CLASSNAME, 'handleCsoAfter', 'Create Onboarding Records', true); 
          for (CSO_Tracking__c updateTracker : updateTrackers) {
              updateTracker.Onboarding_Tool__c =  updateTracker.Onboarding_Tool__r.Id;
              updateTracker.Onboarding_Tool__r = null;
          }
          CsoMethods.SKIP_TRIGGERS=true;
          DmlHelper.performDML2(updateTrackers, DmlHelper.DML_UPDATE, CLASSNAME, 'handleCsoAfter', 'Update trackers with Onboarding Tool', true); 
       }
       if (!onboardTrackerMap.isEmpty()) {
          createCaseRefCtt(onboardTrackerMap, cttAcctIds, cttOppIds, trackerIds);
       }
    } // handleCsoAfter
    //END TRIGGER METHODS
    
    public static void checkMultiIdSettings(Map<Id,CSO_Tracking__c> trackerByOnboardingMap) {
       Onboarding_Tool__c[] onboardings =  [Select Id, AccountId__c, AccountId__r.Federal_ID_Number__c
                                                  ,Combo__c, ClientTracking__c, ClientTracking__r.ChildType__c
                                                  ,ClientTracking__r.IsSameFEIN__c
                                                  ,Parent_Onboarding_Record__c
                                                  ,Parent_Onboarding_Record__r.Id, Parent_Onboarding_Record__r.Combo__c
                                                  ,Parent_Onboarding_Record__r.AccountId__r.Federal_ID_Number__c
                                                  ,Parent_Onboarding_Record__r.ClientTracking__c
                                                  ,Parent_Onboarding_Record__r.ClientTracking__r.IsSameFEIN__c
                                              From Onboarding_Tool__c
                                             Where Id in :trackerByOnboardingMap.keySet()];
       Map<Id,Onboarding_Tool__c> updateOnboardMap = new Map<Id,Onboarding_Tool__c>();
       for (Onboarding_Tool__c onboard : onboardings) {
          Boolean isCombo = (onboard.ClientTracking__c != null && onboard.ClientTracking__r.IsSameFEIN__c);
          if (isCombo && onboard.Combo__c != 'Yes') {
             Onboarding_Tool__c updateRec = new Onboarding_Tool__c(Id=onboard.Id, Combo__c='Yes');
             updateOnboardMap.put(updateRec.Id, updateRec);
          }
          // if a child is a combo, we'll mark the parent as a combo. This might not be 100% correct, but we'll try.
          if (isCombo && onboard.Parent_Onboarding_Record__c != null && onboard.Parent_Onboarding_Record__r.Combo__c != 'Yes') {
             Onboarding_Tool__c updateRec = new Onboarding_Tool__c(Id=onboard.Parent_Onboarding_Record__c, Combo__c='Yes');
             updateOnboardMap.put(updateRec.Id, updateRec);
          }
       } // for (Onboarding_Tool__c onboard
       OnboardingToolHelper.SKIP_TRIGGERS = true;
       DmlHelper.performDML2(updateOnboardMap.values(), DmlHelper.DML_UPDATE, CLASSNAME, 'checkMultiIdSettings', 'Update onboarding recs', true); 
    } // checkMultiIdSettings
    
    public static Onboarding_Tool__c createOnboarding(CSO_Tracking__c tracker) {
       Onboarding_Tool__c newOnboardingRec = new Onboarding_Tool__c(Opportunity_Id__c = tracker.Opportunity__c , AccountId__c = tracker.AccountId__c
                                                                        , ClientTracking__c=tracker.Id);
       newOnboardingRec.Combo__c = (tracker.ChildType__c == 'Combo' ? 'Yes' : null);
       newOnboardingRec.Company_Contact__c = tracker.Contact__c;
       Integer onboardingNameSize = Onboarding_Tool__c.Name.getDescribe().getLength();
       newOnboardingRec.Name = tracker.Name.left(onboardingNameSize);
       return newOnboardingRec;
    } // createOnboarding
    
    public static Boolean createCase = (Label.CTT_Create_Case == 'true');
    public static String cttEmail = (Label.CTT_MMS_Email);
    public static Decimal cttProb = Decimal.valueOf(Label.OppStage_SoldSubmitCTT_Prob);
    public static String cttStatus = Label.OppStage_SoldSubmitCTT;
    
    public static void createCaseRefCtt(Map<Id,CSO_Tracking__c> onboardTrackerMap, Id[] acctIds, Id[] oppIds, Id[] trackerIds) {
       System.debug('createCaseRefCtt onboardTrackerMap='+onboardTrackerMap.size()+' createCase='+createCase+' acctIds='+acctIds.size()+' oppIds='+oppIds.size()+' trackerIds='+trackerIds.size());
       if (!createCase) {
          return;
       }
       // see how many children
       AggregateResult[] results = [Select count(Id) children, ParentTracker__c
                                      From CSO_Tracking__c
                                     Where Id in :trackerIds
                                     Group By ParentTracker__c];
       Map<Id,Integer> childCountMap = new Map<Id,Integer>();
       for (AggregateResult result : results) {
           Id parentId = (Id)result.get('ParentTracker__c');
           Integer nbrChildren = Integer.valueOf(result.get('children'));
           childCountMap.put(parentId, nbrChildren);
       }
       // see if a reference record already exists
       Reference_CTT__c[] existingRefCtts = [Select Id, Onboarding_Tool__c from Reference_CTT__c where Onboarding_Tool__c in :onboardTrackerMap.keySet()];
       System.debug('createCaseRefCtt existingRefCtts='+existingRefCtts.size());
       for (Reference_CTT__c refCtt : existingRefCtts) {
          // remove if there's an existing reference record
          onboardTrackerMap.remove(refCtt.Onboarding_Tool__c);
       }
       if (onboardTrackerMap.isEmpty()) {
          return;
       }
       // get the opportunities, see if we need to change the stage and create the 
       Map<Id,Opportunity> oppMap = new Map<Id,Opportunity>([Select Id, Name, StageName, Probability, LeverageSST__c 
                                                                   ,AccountId, Account.Name, ProcessNotes__c
                                                               from Opportunity 
                                                              Where Id in :oppIds]);

       // query the accounts just to get the account name for the email
       //Map<Id,Account> acctMap = new Map<Id,Account>([Select Id, Name from Account where Id in :acctIds]);
       Group ownerQueue = new UserHelper().getQueue(Label.CTT_Queue);
       Map <String,Schema.RecordTypeInfo> rtMap = Case.sObjectType.getDescribe().getRecordTypeInfosByName();
       Schema.RecordTypeInfo caseRtInfo = rtMap.get(Label.CTT_Case_RecordType);
       Case[] newCases = new Case[]{};
       Reference_CTT__c[] newRefs = new Reference_CTT__c[]{};
       Opportunity[] updateOpps = new Opportunity[]{};
       CSO_Tracking__c[] updateTrackers = new CSO_Tracking__c[]{};
           
       Messaging.SingleEmailMessage[] emails = new Messaging.SingleEmailMessage[]{};
           
       for (CSO_Tracking__c tracker : onboardTrackerMap.values()) {
          Opportunity opp = oppMap.get(tracker.Opportunity__c);
          if (opp != null && opp.LeverageSST__c) {
             String notes = 'LeverageSST__c is set';
             Integer nbrChildren = childCountMap.get(tracker.Id);
             Integer nbrIds = (nbrChildren != null ? nbrChildren : 0) + 1;
             Case newCase = new Case(OwnerId=ownerQueue.Id, AccountId=tracker.AccountId__c, ContactId=tracker.Contact__c, RecordTypeId=caseRtInfo.getRecordTypeId());
             newCase.Opportunity__c = tracker.Opportunity__c;
             newCase.Priority = 'Medium';
             newCases.add(newCase);
             System.debug('createCaseRefCtt newCase='+newCase);

             Reference_CTT__c refCtt = new Reference_CTT__c(OwnerId=ownerQueue.Id, Case__r=newCase, Opportunity__c=tracker.Opportunity__c
                                                     ,Prospect_Client__c=tracker.AccountId__c, Sales_Rep__c=tracker.RegistrationStartedBy__c);
             refCtt.Status__c = 'Submitted to CTT';
             refCtt.Number_of_Ids__c = tracker.NumberOfIds__c;
             refCtt.Ready_to_be_Worked__c = true;
             refCtt.Onboarding_Tool__c = tracker.Onboarding_Tool__c;
             newRefs.add(refCtt);
             System.debug('createCaseRefCtt refCtt='+refCtt+' opp.Probability='+opp.Probability+' cttProb='+cttProb);
             notes += '; Probability='+opp.Probability;
              
             if (opp.Probability < cttProb) {
                notes += '; Setting StageName to '+cttStatus;
                opp.Probability = cttProb;
                opp.StageName = cttStatus;
                StringHelper.addToProcessNotes(opp,'Changing StageName to '+cttStatus+' due to LeverageSST__c=true');
                updateOpps.add(opp);
             }
           
             //Account acct = acctMap.get(tracker.AccountId__c);
             Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
             email.setSaveAsActivity(false);
             //Integer nbrIds = (tracker.NumberOfIds__c != null ? Integer.valueOf(tracker.NumberOfIds__c) : 0);
             String prodBundle = (String.isNotBlank(tracker.Product_Bundle__c) ? tracker.Product_Bundle__c : '');
             email.setSubject('Completed '+(nbrIds > 0 ? nbrIds+' ' : '')+prodBundle+' NCP for your review '+(opp.AccountId != null ? opp.Account.Name : ''));
             String textBody = 'A '+(nbrIds > 0 ? nbrIds+' ' : '')+prodBundle+' submission has been submitted for your approval. '+Url.getOrgDomainURL().toExternalForm()+'/'+tracker.Opportunity__c;
             String htmlBody = 'A '+(nbrIds > 0 ? nbrIds+' ' : '')+prodBundle+' submission has been submitted for your approval.<br/> '
              +'<a href="'+Url.getOrgDomainURL().toExternalForm()+'/'+tracker.Opportunity__c+'">Click this link to review the Opportunity and submission</a>';
             email.setPlainTextBody(textBody);
             email.setHtmlBody(htmlBody);
             if (cttEmail != 'NOEMAIL') {
                notes += '\nCreated email';
                email.setToAddresses(new String[]{cttEmail});
                emails.add(email);
             }
             CSO_Tracking__c updateTracker = new CSO_Tracking__c(Id=tracker.Id, ProcessNotes__c=tracker.ProcessNotes__c);
             StringHelper.addToProcessNotes(updateTracker,notes);
             updateTrackers.add(updateTracker);
          } // if (opp != null && opp.LeverageSST__c
       } // for (CSO_Tracking__c tracker
        
       System.debug('createCaseRefCtt newCases='+newCases.size()+' newRefs='+newRefs.size()+' updateOpps='+updateOpps.size());
       TriggerMethods.SKIP_TRIGGERS=true;
       insert newCases;
        
       for (Reference_CTT__c refCtt : newRefs) {
          if (refCtt.Case__r != null && refCtt.Case__r.Id != null) {
             refCtt.Case__c = refCtt.Case__r.Id;
             refCtt.Case__r = null;
          }
       }
       insert newRefs;
        
       if (!updateOpps.isEmpty()) {
          DmlHelper.performDML2(updateOpps, DmlHelper.DML_UPDATE, CLASSNAME, 'createCaseRefCtt', 'Update opportunities', true); 
       }
       if (!updateTrackers.isEmpty()) {
          SKIP_TRIGGERS=true;
          DmlHelper.performDML2(updateTrackers, DmlHelper.DML_UPDATE, CLASSNAME, 'createCaseRefCtt', 'Update trackers', true); 
          SKIP_TRIGGERS=false;
       }

       System.debug('createCaseRefCtt emails='+emails);
       if (!emails.isEmpty()) {
          Messaging.SendEmailResult[] emailResults = Messaging.sendEmail(emails);
          for (Messaging.SendEmailResult emailResult : emailResults) {
              if (!emailResult.isSuccess()) {
                 String errorMsg = '';
                 for (Messaging.SendEmailError see : emailResult.getErrors()) {
                    System.debug('createCaseRefCtt email error see='+see);
                    errorMsg += see.getMessage();
                 }
                 ErrorLog.logError(CLASSNAME, 'createCaseRefCtt', 'Sending Email', trackerIds[0], errorMsg, null, true);
              }
          } // for (Messaging.SendEmailResult emailResult
       } // if (!emails.isEmpty
       
    } // createCaseRefCtt

    // Account_Eligible__c is only going to be based on the knockouts
    // If there's a ValidationStatusCode__c (indicating it already went through once), then we're not going to run through the validation here, unless Evaluate_Client_Validation__c is checked
    //      on the Opportunity, in which case we will push it through
    
    public static void validateAccounts(List<Account> acctList, Map<Id,Account> oldMap, Map<Id, CSO_Tracking__c> csoMap,List<Id> parentList, Set<Id> forceValidateSet){
        System.debug('validateAccounts acctList='+acctList.size()+' oldMap='+(oldMap != null ? oldMap.size() : -1)+' csoMap='+csoMap.size()+' parentList='+(parentList != null ? parentList.size() : -1));
        //List<Account> acctValidateList = new List<Account>();
        CSO_Tracking__c[] csoUpdates = new CSO_Tracking__c[]{};
        CsoQueueable csoQue = new CsoQueueable();
        
        //Loop through accounts check for knockouts
        for (Account acct : acctList) {
            String accountKnockout = null;
            CSO_Tracking__c csoRec = csoMap.get(acct.Id);
            Boolean forceValidate =  (forceValidateSet != null && forceValidateSet.contains(acct.Id));
            System.debug('validateAccounts acct='+acct.Name+' hasCso='+(csoRec != null)+' forceValidate='+forceValidate+' ClientDataValidated__c='+(csoRec != null ? csoRec.ClientDataValidated__c : false));
            //Registration has not started and all of the verification fields are complete
            if (csoRec != null && csoRec.IsOppCso__c && !csoRec.RegistrationStarted__c && !csoRec.CsoException__c) {
                Account oldAccount = (oldMap !=null ? oldMap.get(acct.Id) : null);
                //Have eligiblility fields been updated
                Boolean fieldsChanged = fieldChanged(acct, oldAccount);
                //Boolean fieldsChanged = (oldAccount == null || TriggerMethods.checkForFldChange(acct,oldAccount,Schema.SObjectType.Account.fieldSets.CsoAccountFields));
                //See if we need to reevaluate based on field changes or if we're forcing it
                if ((csoRec.ClientDataValidated__c && validationfieldChanged(acct,oldAccount)) || forceValidate) {
                    
                    csoRec.ClientDataValidated__c = false;
                }
                //Check for Knockouts
                System.debug('validateAccounts acct='+acct.Name+' fieldsChanged='+fieldsChanged+' forceValidate='+forceValidate+' csoRec.ClientDataValidated__c='+csoRec.ClientDataValidated__c);
                if (fieldsChanged || forceValidate) {
                    //Check for knockout
                    checkForKnockouts(acct, null, csoRec, parentList);
                    //accountKnockout = checkForKnockouts(acct, null, csoRec, parentList);
                    //Add Parent Knockout
                    //if(parentList!=null && parentList.contains(acct.Id)){
                    //    accountKnockout = accountKnockout!=null? accountKnockout +=', This is a parent account' : 'This is a parent account';
                    //}
                    Boolean clientValidationVerified = csoRec.ValidationStatusCode__c == null || csoRec.ValidationStatusCode__c == '200' ? true : false;
                    Boolean userValidationVerified = csoRec.ValidationUserStatusCode__c == null || csoRec.ValidationUserStatusCode__c == '200' ? true : false;
                    //csoRec.Account_Eligible__c = !csoRec.AccountKnockout__c && clientValidationVerified && userValidationVerified ? true : false;
                    // only validate if never validated before - if we validate once, subsequent validations will occur as part of the registration form.
                    //Boolean validateFields = (forceValidate || (String.isBlank(csoRec.ValidationStatusCode__c) && String.isBlank(csoRec.ValidationUserStatusCode__c)));
                    System.debug('validateAccounts AccountKnockout__c='+csoRec.AccountKnockout__c+' forceValidate='+forceValidate+' csoRec.ClientDataValidated__c='+csoRec.ClientDataValidated__c+' csoRec.User_Validated__c='+csoRec.User_Validated__c);
                    if (!csoRec.AccountKnockout__c && (forceValidate || !csoRec.ClientDataValidated__c || !csoRec.User_Validated__c )) {
                        //if(!csoRec.ClientDataValidated__c || !csoRec.User_Validated__c){
                            //if(validationFieldsCompleted(acct,csoRec)){
                            if (String.isBlank(csoRec.RequiredFlds__c)) {
                                csoQue.addRecsToProcess(acct,csoRec);
                                //acctValidateList.add(acct);
                            }
                   } // if (csoRec.AccountKnockout__c == false
                } // if (fieldsChanged
                isOppEligible(csoRec);
                csoUpdates.add(csoRec);
            } // if (!csoRec.RegistrationStarted__c
        } // for (Account acct : acctList
        
        if(!csoUpdates.isEmpty()){
            DmlHelper.performDML2(csoUpdates, DmlHelper.DML_UPDATE, CLASSNAME, 'validateAccounts', 'Update CSO Tracking Record', true); 
        }
        CsoQueueable.checkLaunchQueueable(csoQue);
        
    } // validateAccounts
    
    public static String QUERY_CSO='CSO';
    public static String QUERY_ACCT='Account';
    public static String QUERY_ACCT_MULTI='AccountMultiId';
    public static String QUERY_ACCT_MULTI_QUOTE='AccountMultiIdQuote';
    public static String QUERY_ACCT_OPP_CHECK='AccountAcctOppCheck';
    
    public static String getQuery(String objectKey) {
       String key='CSOMethodsQuery'+objectKey;
       String query = (String)CacheManager.getOrg(key);
       System.debug('getQuery key='+key+' foundInCache='+(String.isNotBlank(query)));
       if (query == null) {
          String objApiName = (objectKey == QUERY_CSO ? 'CSO_Tracking__c' : objectKey);
          Set<String> fldSet = getFields(objectKey);
          if (objectKey == QUERY_ACCT_MULTI || objectKey == QUERY_ACCT_MULTI_QUOTE) {
             query = DmlHelper.buildQueryFromSet(fldSet,'');
             fldSet.clear();
             DmlHelper.addFieldsToSet(Schema.SObjectType.CSO_Tracking__c.fieldSets.TrackingFlds, '', fldSet);
             String subQuery1 = ' ,('+DmlHelper.buildQueryFromSet(fldSet,'CSO_Recs__r')+' order by CreatedDate desc limit 1 )';
             fldSet.clear();
             DmlHelper.addFieldsToSet(Schema.SObjectType.Account_Junction__c.fieldSets.TrackingFlds, '', fldSet);
             String subQuery2 = ' ,('+DmlHelper.buildQueryFromSet(fldSet,'Account_Junctions__r')+' order by CreatedDate desc limit 1 )';
             query += subQuery1+subQuery2;
             
             query += ' From Account ';
             if (objectKey == QUERY_ACCT_MULTI_QUOTE) {
                // going off the quote is the main selection criteria for the children.
                query += 'Where Id in (Select Prospect_Client__c '+
                   ' from cafsl__Oracle_Quote_Line_Item__c '+
	               ' Where cafsl__Oracle_Quote__c = :quoteId '+
	               ' and Prospect_Client__c != null '+
	               ' and Prospect_Client__c != :acctId)';
             } else {
                // this is used mostly for testing purposes
                query += 'Where Id in (Select AccountId__c from CSO_Tracking__c where ParentTracker__c=:trackerId) ';
             }
             // for registering a client before the quote exists - mostlhy for testing
             // Maybe take this out before going live?
             //query += ' or Id in (Select AccountId__c from CSO_Tracking__c where ParentTracker__c=:trackerId) ';
             //fldSet.clear();
             //DmlHelper.addFieldsToSet(Schema.SObjectType.Account.fieldSets.CsoAccountFields, '', fldSet);
             // subquery for the child accounts if the query is a parent
             //String subQuery = DmlHelper.buildQueryFromSet(fldSet,'Sales_Parent__r');
             //query += ',('+subQuery+') from Account ';
          } else if (objectKey == QUERY_ACCT_OPP_CHECK) {
             query = DmlHelper.buildQueryFromSet(fldSet,'');
             fldSet.clear();
             String sub1 = ' ,(Select Id, Parent_Account__c, Type__c from Account_Junctions__r order by CreatedDate desc limit 1) ';
             String sub2 = ' ,(Select Id, AccountId__c, Contact__c, Opportunity__c, CanUseCSO__c '+
                                 ' from CSO_Recs__r Where Opportunity__c != null and Opportunity__r.IsClosed=false order by CreatedDate desc limit 1)';
             String sub3 = ' ,(Select Id, cafsl__Opportunity__c '+
                             ' from cafsl__Oracle_Quotes__r where IsSubscriptionQuote__c=true and cafsl__Syncing__c=true and cafsl__Opportunity__r.IsClosed=false order by CreatedDate desc limit 10)';
             query += (sub1 + sub2+ sub3);
             query += ' From Account Where Id in :acctIds';
          } else {
             query = DmlHelper.buildQueryFromSet(fldSet,objApiName);
          }
          System.debug('getQuery built query and put in cache query='+query);
          if (String.isNotBlank(query)) {
             CacheManager.putOrg(key,query);
          }
       } // if (query == null
       return query;
    } // getQuery
    
    public static Set<String> getFields(String objectType){
        //Schema.FieldSet objectFieldSet;
        Set<String> fldSet = new Set<String>();
        if (objectType == QUERY_CSO) {
           ObjectHelper.getSOQLQuery('CSO_Tracking__c', null, true, false, false, false, true);
           if (ObjectHelper.latestSoqlWrapper != null) {
             fldSet.addAll(ObjectHelper.latestSoqlWrapper.flds);
           }
           DmlHelper.addFieldsToSet(Schema.SObjectType.CSO_Tracking__c.fieldSets.csoMethods_ParentFlds, '', fldSet);
           DmlHelper.addFieldsToSet(Schema.SObjectType.Account.fieldSets.CsoAccountFields, 'AccountId__r.', fldSet);
           DmlHelper.addFieldsToSet(Schema.SObjectType.Opportunity.fieldSets.CsoQueryFlds, 'Opportunity__r.', fldSet);
           DmlHelper.addFieldsToSet(Schema.SObjectType.Contact.fieldSets.CsoQueryFlds, 'Contact__r.', fldSet);
        } else if (objectType == QUERY_ACCT || objectType == QUERY_ACCT_OPP_CHECK) {
           DmlHelper.addFieldsToSet(Schema.SObjectType.Account.fieldSets.CsoAccountFields, '', fldSet);
           DmlHelper.addFieldsToSet(Schema.SObjectType.Account.fieldSets.CsoAccountValidationFields, '', fldSet);
           // check in the custom setting to make sure we have all the fields.
           for (CsoKnockouts__c ck : CsoKnockouts__c.getAll().values()) {
              if (ck.Active__c && ck.Account_Knockout__c && String.isNotBlank(ck.ApiName__c)) {
                  fldSet.add(ck.ApiName__c);
              }
           }
        } else if (objectType==QUERY_ACCT_MULTI || objectType==QUERY_ACCT_MULTI_QUOTE) {
           DmlHelper.addFieldsToSet(Schema.SObjectType.Account.fieldSets.CsoAccountFields, '', fldSet);
           // pull in the parent fields if this is a child
           //DmlHelper.addFieldsToSet(Schema.SObjectType.Account.fieldSets.CsoAccountFields, 'SalesParent__r.', fldSet);
        }
        System.debug('getFields objectType='+objectType+' fldSet='+fldSet.size());
        return fldSet;
    } // getFields
    
    public static Boolean fieldChanged(Account acct, Account oldRec){//Use TriggerMethods checkForFldChange
        Boolean fieldsChanged = (oldRec == null);
        System.debug('fieldChanged 1 fieldsChanged='+fieldsChanged);
        fieldsChanged = fieldsChanged || checkForChanges(acct, oldRec, Schema.SObjectType.Account.fieldSets.EnterpriseRegFldsChanged);
        System.debug('fieldChanged 2 fieldsChanged='+fieldsChanged);
        fieldsChanged = fieldsChanged || checkForChanges(acct, oldRec, Schema.SObjectType.Account.fieldSets.CsoAccountValidationFields);
        if (!fieldsChanged) {
           // check the custom setting for knockout fields
           for (CsoKnockouts__c ko : CsoKnockouts__c.getAll().Values()) {
              if (ko.Active__c && ko.Account_Knockout__c && String.isNotBlank(ko.ApiName__c)) {
                 try {
                    if (acct.get(ko.ApiName__c) != oldRec.get(ko.ApiName__c)) {
                       fieldsChanged = true;
                       break;
                    }
                 } catch (Exception e) {
                    System.debug('fieldChanged e='+e.getMessage());
                 }
              } // if (ko.Active__c
           } // for (CsoKnockouts__c ko : CsoKnockouts__c
        } // f (!fieldsChanged
        System.debug('fieldChanged 3 fieldsChanged='+fieldsChanged);
        return fieldsChanged;
    } // fieldChanged
    
    public static Boolean checkForChanges(SObject rec, SObject oldRec, Schema.FieldSet fldSet) {
       Boolean changed = (oldRec == null);
       if (!changed && fldSet != null) {
          for (Schema.FieldSetMember fsm : fldSet.getFields()) {
             if (rec.get(fsm.getFieldPath()) != oldRec.get(fsm.getFieldPath())) {
                changed = true;
                break;
             }
          }

       } // if (!changed && fldSet != null
       return changed;
    } // checkForChanges
    
    //Temporary Method
    public static Boolean validationfieldChanged(Account acct, Account oldRec){//Use TriggerMethods checkforfieldchange
        //System.debug('validationfieldChanged acct.Federal_ID_Number__c='+acct.Federal_ID_Number__c+' oldRec.Federal_ID_Number__c='+(oldRec != null ? oldRec.Federal_ID_Number__c : 'No Old Rec'));
        Boolean fieldsChanged = (oldRec!=null && (acct.Federal_ID_Number__c != oldRec.Federal_ID_Number__c || acct.ShippingAddress != oldRec.ShippingAddress));
        System.debug('validationfieldChanged fieldsChanged='+fieldsChanged);
        return fieldsChanged;
    } // validationfieldChanged
    
    public static String[] excludeFromKnockouts = Label.CSO_ExcludeKnockouts.split(',');
    public static String[] leadSourceKOs = Label.CSOLeadSourceKO.split(',');
    
    public static String checkForKnockouts(Account acctRec, Opportunity oppRec, CSO_Tracking__c cso, Id[] parentIds) {
        System.debug('checkForKnockouts acctRec='+(acctRec != null ? acctRec.Name : 'NoAcct')+' oppRec='+(oppRec != null ? oppRec.Name : 'NoOpp')+' excludeFromKnockouts='+excludeFromKnockouts);
        Boolean checkAcct = (acctRec != null);
        Boolean checkOpp = (oppRec != null);
        String[] knockouts = new String[]{};
        //Verify necessary fields are complete
        if (checkAcct) {
            // check if the required fields are filled out
            validationFieldsCompleted(acctRec, cso);
            if (parentIds != null && acctRec.Id != null && parentIds.contains(acctRec.Id)) {
               knockouts.add('This is a parent account');
            }
        } // if(acctRec!=null
        //Check for additional knockouts - Get Custom setting records
        for (CsoKnockouts__c ko : CsoKnockouts__c.getAll().Values()) {
            //Verify active knockout
            if (ko.Active__c && ((checkAcct && ko.Account_Knockout__c) || (checkOpp && ko.Opportunity_Knockout__c))) {
                try {
                   String checkValue = (checkAcct ? String.valueOf(acctRec.get(ko.ApiName__c)) : String.valueOf(oppRec.get(ko.ApiName__c)));
                   System.debug('checkForKnockouts checkOpp='+checkOpp+' fld='+ko.ApiName__c+' checkValue='+checkValue);
                   // kind of hardcoding this for now
                   if (checkOpp && ko.ApiName__c == 'LeadSource') {
                      if (String.isNotBlank(checkValue) && leadSourceKOs.contains(checkValue)) {
                         knockouts.add(ko.Outcome__c);
                      }
                   } else {
                      //Check for knock out
                      if ((ko.FieldValue__c !=null && checkValue == ko.FieldValue__c)
                         || (ko.IsNull__c && checkValue == null)
                         || (ko.NotNull__c && checkValue != null)){
                             //Knockout found, update return string
                             knockouts.add(ko.Outcome__c);
                      }
                   }
                } catch (Exception e) {
                   // in case the field doesn't exist on the object.
                   knockouts.add('Exception: '+e.getMessage());
                   System.debug('checkForKnockouts exception: '+e.getMessage());
                }
            } // if ((acctRec!= null && ko.Account_Knockout__c
        } // for (CsoKnockouts__c ko : CsoKnockouts__c.getAll().Values())
        String knockoutFound = (!knockouts.isEmpty() ? String.join(knockouts,', ') : null);
        if (checkAcct) {
           cso.AccountLastChecked__c = Datetime.now();
           //cso.Account_Eligible__c = (cso.ClientDataValidated__c && knockoutFound == null);
           cso.Account_Eligible__c = (knockoutFound == null);
           //if (!cso.Account_Eligible__c) {
           if (knockoutFound != null) {
              cso.Opportunity_Eligible__c = false;
              cso.InitialValidationDetail__c = null;
           }
           cso.AccountKnockout__c = (knockoutFound != null);
           cso.AccountKnockoutDetail__c = knockoutFound;

        } else if (checkOpp) {
           cso.OpportunityLastChecked__c = Datetime.now();
           Boolean oppFldsValidated = (knockoutFound == null);
           if (cso.OpportunityEligibilityDetail__c != knockoutFound || cso.OpportunityFieldsValidated__c != oppFldsValidated) {
              cso.OpportunityEligibilityDetail__c = knockoutFound;
              cso.OpportunityFieldsValidated__c = oppFldsValidated;
              //csoUpdateMap.put(cso.Id,cso);
           }

        }
        System.debug('checkForKnockouts checkAcct='+checkAcct+' checkOpp='+checkOpp+' knockouts='+knockouts.size()+' knockoutFound='+knockoutFound);
        return knockoutFound;
    } // checkForKnockouts
    
    public static Boolean validationFieldsCompleted(Account acctRec, CSO_Tracking__c cso) {
        String addressToUse = CsoQueueable.addrToUse(acctRec);
        System.debug('validationFieldsCompleted addressToUse='+addressToUse);
        String[] missingFlds = new String[]{};
        Schema.FieldSet fieldSet = Schema.SObjectType.Account.fieldSets.CsoAccountValidationFields;
        for (Schema.FieldSetMember fsm : fieldSet.getFields()) {
            String fldName = fsm.getFieldPath();
            String acctFldName = CsoQueueable.checkFieldName(fldName, addressToUse);

            String fieldValue = String.valueOf(acctRec.get(acctFldName));
            System.debug('validationFieldsCompleted fld='+fldName+' acctFldName='+acctFldName+' fieldValue='+fieldValue);
            //Verify Fields Complete
            if(fieldValue == null && !excludeFromKnockouts.contains(fldName)){
                missingFlds.add(fsm.getLabel());
            }
        } // for (Schema.FieldSetMember fsm : fieldSet.getFields
        cso.RequiredFlds__c = (!missingFlds.isEmpty() ? String.join(missingFlds,', ') : null);
        Boolean fieldsComplete = missingFlds.isEmpty();
        System.debug('validationFieldsCompleted fieldsComplete='+fieldsComplete+' missingFlds='+missingFlds.size()+' cso.RequiredFlds__c='+cso.RequiredFlds__c);
        return fieldsComplete;
    }// validationFieldsCompleted
    
    public static String REQ_PROD_MESSAGE=Label.CsoMethods_ReqProdMessage;
                                
    public static Boolean checkForProductKnockouts(CSO_Tracking__c cso, cafsl__Oracle_Quote__c primaryQuote, String regType){
        Boolean changed = false;
        System.debug('checkForProductKnockouts cso='+(cso != null)+' primaryQuote='+(primaryQuote != null));
        if (cso != null && primaryQuote == null && cso.ProductsValidated__c) {
           changed = true;
           cso.ProductsValidated__c = false;
        } else if (cso != null && primaryQuote != null) {
           //changed = true;
           Boolean hasRequiredPackage = false;
           String[] knockouts = new String[]{};
           String[] csoOnlyProds = new String[]{};
           String packageSelectedName = null;
           Boolean isCso = (regType == TYPE_CSO);
           System.debug('checkForProductKnockouts isCso='+isCso);
            
           for (cafsl__Oracle_Quote_Line_Item__c qoli : primaryQuote.cafsl__Oracle_Quote_Line_Items1__r) {
              System.debug('checkForProductKnockouts prod='+qoli.cafsl__Product__r.Name+' Eligibility='+qoli.cafsl__Product__r.CSO_Eligible__c);
              if (qoli.cafsl__Product__r.Is_Package__c) {
                 packageSelectedName = qoli.cafsl__Product__r.Name;
              }
              if (qoli.cafsl__Product__r.CSOOnly__c) {
                 csoOnlyProds.add(qoli.cafsl__Product__r.Name);
              }
              // these checks only need to be made if it's actually cso
              if (isCso) {
                 if(qoli.cafsl__Product__r.CSO_Required__c){
                    hasRequiredPackage = true;
                 }
                 if(!qoli.cafsl__Product__r.CSO_Eligible__c){
                   knockouts.add(qoli.cafsl__Product__r.Name);
                 }
              } // if (isCso
           } // for (cafsl__Oracle_Quote_Line_Item__c qoli
            
           // these are cso specific checks
           if (isCso) {
              String knockoutDetail = (!hasRequiredPackage && packageSelectedName != null ? packageSelectedName
                                       : (!knockouts.isEmpty() ? String.join(knockouts,', ') : null));
              String knockoutMessage = (String.isNotBlank(knockoutDetail) ? (!hasRequiredPackage ? REQ_PROD_MESSAGE : 'Products not eligible for CSO: '+ knockoutDetail) : null);
         
              Boolean prodValidated = (knockoutDetail == null);
              if (cso.ProductsValidated__c != prodValidated || cso.ProductKnockoutDetail__c != knockoutDetail || cso.ProductKnockoutMessage__c != knockoutMessage) {
                 StringHelper.addToProcessNotes(cso,'Product info ProductsValidated__c='+cso.ProductsValidated__c+' hasRequiredPackage='+hasRequiredPackage+' knockouts='+knockouts.size());
                 changed = true;
                 cso.ProductsValidated__c = (knockoutDetail == null);
                 cso.ProductKnockout__c = (knockoutDetail != null);
                 cso.ProductKnockoutDetail__c = knockoutDetail;
                 cso.ProductKnockoutMessage__c = knockoutMessage;
              }
           } // if (isCso
           if (cso.Product_Bundle__c != packageSelectedName) {
              changed = true;
              cso.Product_Bundle__c = packageSelectedName;
           }
           if (EZOnboardingRegistration.checkCsoOnlyProds(cso, csoOnlyProds)) {
              changed = true;
           }

           //StringHelper.addToProcessNotes(cso,'Product info ProductsValidated__c='+cso.ProductsValidated__c+' hasRequiredPackage='+hasRequiredPackage+' knockouts='+knockouts.size());
           //}
       } // if (primaryQuote != null
        
        isOppEligible(cso);
       return changed;
   } // checkForProductKnockouts
    
   public class PermCache {
      public Map<Id,CustomPermission> permMap = null;
      Map<Id,SetupEntityAccess[]> seaMap = new Map<Id,SetupEntityAccess[]>();
      
      public PermCache() {
         String[] permNames = new String[]{csoPerm,cltRegPerm};
         permMap = new Map<Id,CustomPermission>([Select Id, DeveloperName from CustomPermission where DeveloperName in :permNames]);
         System.debug('PermCache permNames='+permNames+' permMap='+permMap.size());
         if (!permMap.isEmpty()) {
            SetupEntityAccess[] seas = [Select Id, SetupEntityId, ParentId
                                       From SetupEntityAccess
                                      Where SetupEntityType = 'CustomPermission'
                                        and SetupEntityId in :permMap.keySet()];
            for (SetupEntityAccess sea : seas) {
               SetupEntityAccess[] checkSeas = (seaMap.containsKey(sea.ParentId) ? seaMap.get(sea.ParentId) : new SetupEntityAccess[]{});
               checkSeas.add(sea);
               seaMap.put(sea.ParentId, checkSeas);
            } // for (SetupEntityAccess sea
            System.debug('PermCache seas='+seas.size()+' seaMap='+seaMap.size());

         } // if (!permMap.isEmpty
      } // public PermCache
   } // class PermCache
   
   public static Set<String> doesUserHavePermission(Id[] userIds, String[] permNames) {
      Set<String> permSet = new Set<String>();
      Boolean checkPerms = false;
      // if all of them are All we don't need to do anything
      for (String permName : permNames) {
         if (permName != PERM_ALL) {
            checkPerms=true;
            break;
         }
      } // for (String permName : permNames
      System.debug('doesUserHavePermission checkPerms='+checkPerms);
      if (checkPerms) {
         PermCache permInfo = (PermCache)CacheManager.getOrg('doesUserHavePermission');
         System.debug('doesUserHavePermission permInfo='+(permInfo != null));
         if (permInfo == null) {
            permInfo = new PermCache(); 
            CacheManager.putOrg('doesUserHavePermission',permInfo);
         }
         PermissionSetAssignment[] psas = [Select Id, AssigneeId, PermissionSetId, PermissionSetGroupId
                                             From PermissionSetAssignment
                                            Where AssigneeId in :userIds
                                              and (PermissionSetId in :permInfo.seaMap.keySet() or PermissionSetGroupId in :permInfo.seaMap.keySet())];
         System.debug('doesRunningUserHavePermission psas='+psas.size());
         for (PermissionSetAssignment psa : psas) {
            SetupEntityAccess[] checkSeas = (psa.PermissionSetId != null ? permInfo.seaMap.get(psa.PermissionSetId) 
                                              : (psa.PermissionSetGroupId != null ? permInfo.seaMap.get(psa.PermissionSetGroupId) : null));
            for (SetupEntityAccess sea : checkSeas) {
               CustomPermission cp = (sea != null ? permInfo.permMap.get(sea.SetupEntityId) : null);
               System.debug('doesRunningUserHavePermission psa='+psa.AssigneeId+' sea='+(sea != null)+' cp='+(cp != null));
               if (sea != null && cp != null) {
                  permSet.add(psa.AssigneeId+cp.DeveloperName);
               }
            } // for (SetupEntityAccess sea : checkSeas
         } // for (PermissionSetAssignment psa

      } // if (checkPerms
      /*
      Map<Id,CustomPermission> permMap = null;
      if (checkPerms) {
         permMap = new Map<Id,CustomPermission>([Select Id, DeveloperName from CustomPermission where DeveloperName in :permNames]);
      }
      if (permMap != null && !permMap.isEmpty()) {
         SetupEntityAccess[] seas = [Select Id, SetupEntityId, ParentId
                                       From SetupEntityAccess
                                      Where SetupEntityType = 'CustomPermission'
                                        and SetupEntityId in :permMap.keySet()];
         Map<Id,SetupEntityAccess[]> seaMap = new Map<Id,SetupEntityAccess[]>();
         for (SetupEntityAccess sea : seas) {
            SetupEntityAccess[] checkSeas = (seaMap.containsKey(sea.ParentId) ? seaMap.get(sea.ParentId) : new SetupEntityAccess[]{});
            checkSeas.add(sea);
            seaMap.put(sea.ParentId, checkSeas);
         } // for (SetupEntityAccess sea
       
         PermissionSetAssignment[] psas = [Select Id, AssigneeId, PermissionSetId, PermissionSetGroupId
                                             From PermissionSetAssignment
                                            Where AssigneeId in :userIds
                                              and (PermissionSetId in :seaMap.keySet() or PermissionSetGroupId in :seaMap.keySet())];
         for (PermissionSetAssignment psa : psas) {
            SetupEntityAccess[] checkSeas = (psa.PermissionSetId != null ? seaMap.get(psa.PermissionSetId) 
                                              : (psa.PermissionSetGroupId != null ? seaMap.get(psa.PermissionSetGroupId) : null));
            for (SetupEntityAccess sea : checkSeas) {
               CustomPermission cp = (sea != null ? permMap.get(sea.SetupEntityId) : null);
               System.debug('doesRunningUserHavePermission psa='+psa.AssigneeId+' sea='+(sea != null)+' cp='+(cp != null));
               if (sea != null && cp != null) {
                  permSet.add(psa.AssigneeId+cp.DeveloperName);
               }
            } // for (SetupEntityAccess sea : checkSeas
         } // for (PermissionSetAssignment psa
           
      } // if (!permMap.isEmpty())
      */
      System.debug('permSet='+permSet);

      return permSet;
   } // doesUserHavePermission
        
} // class CsoMethods