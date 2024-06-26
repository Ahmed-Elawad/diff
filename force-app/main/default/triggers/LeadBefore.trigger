/* 
*  A trigger to handle before update/insert operations.
*   
* History
* -------

* 09/19/2012 Cindy Freeman      created
10/02/2013 Dan Carmen         Added logic from LeadCheckOwner trigger
* 05/02/2014 Cindy Freeman     Added Lead Company logic
* 06/11/2014 Cindy Freeman     populating RecordtypeId and DoNotCall fields if blank from LeadLoader
* 08/12/2014 Cindy Freeman     set CALCULATE_SIGNIFICANCE = false when flopping lead 
02/16/2015 Dan Carmen         Changes for the NSS Call Disposition Field
03/25/2015 Dan Carmen         Set Latest Campaign Date
08/05/2015 Dan Carmen         Log time between web lead coming and and dialed.
02/15/2016 Dan Carmen         Make sure dialed is set on a call
08/25/2016 Dan Carmen         Ability to always check owner on insert based only on lead source.
01/20/2017 Dan Carmen   Add call to TriggerMethods
05/11/2017 Dan Carmen      Add additional call to TriggerMethods
06/20/2018 Cindy Freeman     Added code for PEO Centric rules
09/07/2018 Jacob Hinds        Clearing dnc/eoo when no phone or email exists
09/21/2018 Dan Carmen         Added extra debug statement
10/11/2018 Jacob Hinds       Re-adding DNC code that got overwritten
12/06/2018 Dan Carmen      Replace qbdialer__LastCallTime__c with LatestCallTime__c
04/22/2019 Dan Carmen         Add more logging
05/22/2019 Dan Carmen         Add handling for DuplicateCheckStatus__c
07/08/2019 Dan Carmen         Add debugging for trigger tracking
10/31/2019 Matt Fritschi	  Strategic Account Partner is set on Leads with source of Referral - Strategic Partner.
12/03/2019 Matt Fritschi	Fixed SOQL Query Limit from setting Strategic Account Partner
06/02/2020 Dan Carmen         Remove code that calls PeoHelper
09/09/2020 Dan Carmen         Use the OwnedBy__c field as the key for "lead loader"
03/29/2021 Karthik Pedditi    Update City and State based on ZIPCODE
01/10/2021 Pujitha Madamanchi APR0129320 Removed LeadState code - moved to TrackRecordEntry
12/29/2022 Dan Carmen         Commented out Copy Lead logic
09/28/2023 Dan Carmen          Remove "Lead Flopper" code that isn't being used.

*/

trigger LeadBefore on Lead (before insert, before update) {
    // should be able to remove this eventually...
    for (Lead ld : Trigger.new) {
        //StringHelper.addToprocessNotes(ld,'LeadBefore DupeStatus='+ld.DuplicateCheckStatus__c+' OwnedBy='+ld.OwnedBy__c+' TrigExecuting='+LeadMethods.LEAD_BEFORE_EXECUTING+' usr='+UserInfo.getUserName());
        StringHelper.addToprocessNotes(ld,'LeadBefore WebLead='+ld.WebLead__c+' OwnedBy='+ld.OwnedBy__c+' TrigExecuting='+LeadMethods.LEAD_BEFORE_EXECUTING+' usr='+UserInfo.getUserName()+' AMP lookup='+(ld.amp_dev__Referral__c));
        // this is a "temporary" fix for the value keeping on getting reverted
        if (LeadMethods.LEAD_BEFORE_EXECUTING && Trigger.isUpdate) {
            Lead oldLd = Trigger.oldMap.get(ld.id);
            // once the value changes from pending, we want to prevent it from changing to something else.
            // if it changes back to pending, we'll put it back to the old value 
            if (String.isNotBlank(ld.DuplicateCheckStatus__c) && (ld.DuplicateCheckStatus__c != oldLd.DuplicateCheckStatus__c)
                && (ld.DuplicateCheckStatus__c == 'Pending')
                && String.isNotBlank(oldLd.DuplicateCheckStatus__c)) {
                    StringHelper.addToProcessNotes(ld,'LeadBefore changed DuplicateCheckStatus__c from '+ld.DuplicateCheckStatus__c+' to '+oldLd.DuplicateCheckStatus__c);
                    ld.DuplicateCheckStatus__c = oldLd.DuplicateCheckStatus__c;
                }
        }
    } // for (Lead ld : Trigger.new
    if (TriggerMethods.DISABLE_CHECKRECS && LeadMethods.LEAD_BEFORE_EXECUTING) {
        System.debug('LeadBefore exiting because of recursion1');
        return;
    }
    SObject[] recs = TriggerMethods.checkRecs('LeadBefore', Trigger.new, Trigger.oldMap, Trigger.isBefore, Trigger.isAfter, null, Schema.SObjectType.Lead.fieldSets.LeadBeforeFlds);
    if (recs == null || recs.isEmpty()) {
        System.debug('LeadBefore exiting because of recursion2');
        return;
    }
    Lead[] lds = (Lead[])recs;
    
    LeadMethods.LEAD_BEFORE_EXECUTING = true;
    
    UserHelper.setRunningUserAttributes();
    Boolean isSfdcDataUser = UserHelper.runningUserIsSfdcData;
    Boolean isRJDBuser = UserHelper.runningUserIsRelationalJunction;
    Boolean isLeadLoader = UserHelper.runningUserIsLeadLoader;
    Boolean isIsdcApi = UserHelper.runningUserIsIsdcApi;
    
    User runningUser = UserHelper.getRunningUser();
    
    // save record type id for later  
    Schema.RecordTypeInfo rtPEOInfo = RecordTypeHelper.getRecordType(Label.RT_PEO_Lead, ObjectHelper.OBJECT_LEAD);
    
    Set <String> pickLS = new Set<String>();
    
    // set the ownership for both Marketo and Relational Junction
    Boolean checkZipOwner = ((UserInfo.getName() == UserHelper.MARKETO) || isRJDBuser || isLeadLoader);
    System.debug('LeadBefore checkZipOwner='+checkZipOwner);
    Boolean isSysAdminUser = false;
    if (Trigger.isInsert) {
        // this only needs to be set on insert
        isSysAdminUser = (!checkZipOwner && UserHelper.isRunningUserSystemAdmin());
    }
    Id runningUsrId = UserInfo.getUserId();
    
    
    // only do the lead source check if the Relational Junction user
    if (isRJDBuser) {
        // populate set of LeadSource picklist values
        Schema.DescribeFieldResult F = Lead.LeadSource.getDescribe();
        List<Schema.Picklistentry> P = F.getPicklistValues();
        for (integer i = 0; i < P.size(); i ++)
        {   Picklistentry px = P.get(i);
         pickLS.add(px.getValue());
        }
    } // if (isRJDBUser
    
    // the lead sources we'll always check the owner on if it's a new record.
    Set<String> alwaysCheckOwnerLeadSourceSet = new Set<String>();
    alwaysCheckOwnerLeadSourceSet.addAll(Label.LeadAlwaysCheckOwner.split(','));
    // the job names to exclude from always setting the owner.
    Set<String> excludeJobNamesForLeadSource = new Set<String>();
    excludeJobNamesForLeadSource.addAll(Label.LeadAlwaysCheckExcludeJobs.split(','));
    
    // a collection of all the leads we are going to check the owner for
    Lead[] checkOwnerLeads = new Lead[]{};
        
        // check the leads where the owned by field is populated
        Lead[] checkOwnedByLeads = new Lead[]{};
            
            
            if (!CheckDataGovernance.ONLY_DATA_GOVERNANCE) {
                TriggerMethods.checkBeforeLoop('LeadBefore', lds, Trigger.oldMap, Trigger.IsBefore, Trigger.IsAfter);
            }
    
    if (Trigger.isUpdate) {
        CheckDataGovernance.checkData(lds, Trigger.oldMap);//As per the Data Goverance doc      
    }
    
    // if we're only doing the data governance check stop here.
    if (CheckDataGovernance.ONLY_DATA_GOVERNANCE) {
        return;
    }  
    Boolean hasOnlineSetup=false;
    
    Map<Lead, Id> setStrategicAccount = new Map<Lead, Id>();
        
    System.debug('isLeadLoader='+isLeadLoader+' isRJDBuser='+isRJDBuser );
    for (Lead newL : lds) {
        System.debug('LeadBefore 1 newL='+newL.Company+' OwnedBy='+newL.OwnedBy__c+' id='+newL.Id+' isUpdate='+Trigger.isUpdate);       
        // do nothing for the records that we've already processed
        if (!LeadMethods.leadIdsProcessed.contains(newL.Id)) {
            // because the new "lead loader" isn't running as the lead loader user.
            isLeadLoader = (isLeadLoader || String.isNotBlank(newL.OwnedBy__c ));
            
            Boolean checkOwner = false;
            Lead oldL = (Trigger.isUpdate ? Trigger.oldMap.get(newL.id) : null);
            
            TriggerMethods.checkInLoop('LeadBefore', newL, oldL, Trigger.IsBefore, Trigger.IsAfter);
            
            Boolean leadHandled = LeadOnlineSetup.checkOnlineSetup(newL,oldL);
            hasOnlineSetup = (hasOnlineSetup || leadHandled);
            
            //StringHelper.addToProcessNotes(newL, 'LeadBefore leadHandled='+leadHandled);
            if (!leadHandled) {
                LeadMethods.checkLeadBeforeActions(newL, oldL);
                String oldOwnedBy = (oldL != null ? oldL.OwnedBy__c : null);
                if (String.isNotBlank(newL.OwnedBy__c)) {
                    StringHelper.addToProcessNotes(newL, 'runningUser='+UserInfo.getUserId()+' OwnedBy__c='+newL.OwnedBy__c+' isLeadLoader='+isLeadLoader+' oldOwnedBy='+oldOwnedBy);
                    // if not the lead loader just clear out the field?
                    if (!isLeadLoader) {
                        StringHelper.addToProcessNotes(newL,'Not LeadLeader, clearing OwnedBy__c');
                        newL.OwnedBy__c = null;
                    } else { 
                        // 8/5/2015 put the start date on incoming web leads
                        NSSMethods.checkWebLeadStart(newL,oldL);
                        if (Trigger.isUpdate) {
                            // process the update from the before trigger - have to do the insert from the after trigger because the id won't exist yet.
                            checkOwnedByLeads.add(newL);
                            StringHelper.addToProcessNotes(newL, 'LeadBefore added to checkOwnedByLeads');
                            System.debug('LeadBefore adding Lead to checkOwnedByLeads newL='+newL.Company);
                        }
                    } // else
                } // if (String.isNotBlank
                
                // if not dialed but the last call time changes, assume there's been a dial
                if (!newL.Dialed__c && !isIsdcApi && Label.PO_DateCheck == 'Y' && newL.LatestCallTime__c != null && (oldL == null || newL.LatestCallTime__c != oldL.LatestCallTime__c)) {
                    newL.Dialed__c = true;
                }
                
                if (newL.Dialed__c && (oldL == null || !oldL.Dialed__c)) {
                    // 8/5/2015 log that the record was dialed if necessary
                    NSSMethods.checkWebLeadDialed(newL,oldL);
                } // if (newL.Dialed__c
                
                System.debug('LeadBefore newL.UseZipAssignmentRules='+newL.UseZipAssignmentRules__c);                      
                if (newL.UseZipAssignmentRules__c) {
                    newL.UseZipAssignmentRules__c = false;
                    checkOwner = true;
                }
                
                if (isRJDBuser) {
                    if (String.isNotBlank(newL.LeadSource)) {
                        // if LeadSource isnt in the picklist, dont update it
                        if (!pickLS.Contains(newL.LeadSource)) { 
                            newL.LeadSource = (oldL != null ? oldL.LeadSource : null);
                        }
                    } // if (String.isBlank
                } // if (isRJDBUser
                
                if (isLeadLoader) {
                    LeadMethods.checkLeadLoaderValidations(newL,oldL);
                }
                
                if (Trigger.isInsert) {
                    
                    String leadSource = (newL.LeadSource != null ? newL.LeadSource.trim() : '');
                    
                    Boolean checkOwnerBasedOnLeadSource = (alwaysCheckOwnerLeadSourceSet.contains(leadSource)
                                                           && runningUser != null 
                                                           && (runningUser.Job_Name__c == null 
                                                               || (runningUser.Job_Name__c != null && !excludeJobNamesForLeadSource.contains(runningUser.Job_Name__c)))
                                                          );
                    
                    // PEO Centric just in case lead loader starts using the Product Division field
                    if (String.isBlank(newL.OwnedBy__c) && String.isBlank(newL.LatestCampaign__c) && newL.Product_Division__c == 'PEOCentric' && isLeadLoader) {   
                       newL.RecordTypeId = rtPEOInfo.getRecordTypeId();
                       newL.PEOLeasing__c = true;
                       checkOwner = true;          
                    }
                    System.debug('LeadBefore after PEO check newL='+newL.Company+' checkOwner='+checkOwner);
                    // if the checkbox is set always check the owner
                    if (checkZipOwner
                        || checkOwnerBasedOnLeadSource 
                        ||  (isSysAdminUser && 
                             !newL.Hold_Out__c &&
                             newL.OwnerID == runningUsrId && 
                             newL.LeadSource != null &&
                             newL.LeadSource.equals(Label.LeadSource_ReferralBank)
                            )
                       ) {
                           checkOwner = true;
                       }
                    System.debug('LeadBefore after checkZipOwner newL='+newL.Company+' checkOwner='+checkOwner);
                    if (!checkOwner) {
                        checkOwner = LeadCheckOwner.doWeCheckOwner(newL);
                    }
                    System.debug('LeadBefore in insert 2 checkOwner='+checkOwner);
                    
                    //Check for setting Strategic Account Partner
                    System.debug('Checking Strategic Account Partner');

                    if(newL.Referral_Contact__c != null && String.isNotBlank(newL.LeadSource) && newL.LeadSource.equals('Referral-Strategic Account'))
                    {
                        System.debug('Setting Strategic Account Partner');
                        //System.debug('newL.Id='+newL.Id+' newL.Referral_Contact__c='+newL.Referral_Contact__c);
                        setStrategicAccount.put(newL, newL.Referral_Contact__c);
                    }
                    
                    
                    
                    
                } // isInsert
                else if (Trigger.isUpdate) {
                    
                    // check the ownership if the holdout flag is unchecked.
                    if (!newL.Hold_Out__c && newL.LeadSource != null && newL.LeadSource.equals(Label.LeadSource_ReferralBank) && newL.Hold_Out__c != oldL.Hold_Out__c) {
                        checkOwner = true;
                    }
                    if(newL.Phone==null && newL.MobilePhone==null && (newL.DoNotCall || newL.Consent_to_Text__c)){
                        newL.DoNotCall = false;
                        newL.Consent_to_Text__c = false;
                        newL.ProcessNotes__c = newL.ProcessNotes__c+'\n'+system.now()+' Clearing Do Not Call/Text Opt In because there were no phone numbers on the record';
                    }
                    if(newL.Email==null && newL.HasOptedOutOfEmail){
                        newL.HasOptedOutOfEmail = false;
                        newL.ProcessNotes__c = newL.ProcessNotes__c+'\n'+system.now()+' Clearing Email Opt Out because there was no email address on the record';
                    }
                    
                } // else if (Trigger.isUpdate)
                
                
            } // if (!leadHandled
            System.debug('LeadBefore final '+newL.Company+' checkOwner='+checkOwner);           
            if (checkOwner) {
                checkOwnerLeads.add(newL);
            }
        } // if (!LeadMethods.leadIdsProcessed.contains(newL.Id
    } // for newL
    
    TriggerMethods.checkOutsideLoop('LeadBefore', Trigger.isBefore, Trigger.isAfter);
    
    if (hasOnlineSetup) {
        LeadOnlineSetup.handleOnlineSetupRecords();
    }
    
    LeadMethods.processBeforeActions();
    
    System.debug('LeadBefore checkOwnerLeads='+checkOwnerLeads.size()+' checkOwnedByLeads='+checkOwnedByLeads.size());    
    if (!checkOwnerLeads.isEmpty()) {
        LeadCheckOwner.processLeads(checkOwnerLeads,false);
    }
    
    if (!checkOwnedByLeads.isEmpty()) {
        LeadMethods.checkOwnedBy(checkOwnedByLeads);
    }
    
    if(!setStrategicAccount.isEmpty())
    {
        LeadMethods.setStrategicAccountPartner(setStrategicAccount);
    }
    
    // so the triggers only execute once and we don't break test methods
    if (Test.isRunningTest()) {
        LeadMethods.LEAD_BEFORE_EXECUTING = false;
    }
} // trigger LeadBefore