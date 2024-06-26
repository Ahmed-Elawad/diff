/** Methods on the Lead object
*
* History
* -------
* 10/11/2013 Dan Carmen        Created.
* 06/27/2014 Cindy Freeman     added method for Lead Flopper for NSS
* 07/07/2014 Cindy Freeman     Added methods to test DataFlux field changes
   12/19/2014 Dan Carmen        Consolidated methods coming from the lead
   02/16/2015 Dan Carmen         Changes for Call Disposition
   07/09/2015 Cindy Freeman      set Segment when new prospect ownership is created
   07/30/2015 Jacob Hinds        Added in Round Robin calls.
   02/15/2016 Dan Carmen         Added check for EndOwnership
   03/07/2016 Jacob Hinds        Adding nss bypass for virtual sales in checkOwnedBy
   04/13/2016 Dan Carmen         Fix for NPE
   10/31/2016 Jacob Hinds       Moving the check for prospect ownership up before virtual and round robin checks in checkOwnedBy.
   02/09/2017 Jacob Hinds       Removing a couple lines from the Master Partner referral section
   05/02/2017 Jacob Hinds       Adding line for Partner Referral Description
   07/12/2017 Dan Carmen        Add additional logging
   07/14/2017 Lynn Michels      Replace "na5" in urls
   08/09/2018 Rick Segura(DG)   Added logic to populate Time Zone fields from Area Code lookup if not available from zip code
   03/15/2019 Dan Carmen        Added more logging to track the ownedBy field
   03/19/2019 Jake Hinds    Removing PEOC code re: campaign routing
   10/24/2019 Dan Carmen        Move all LatestCampaign__c code to CampaignMethods
   10/31/2019 Matt Fritschi    Added method to set the Leads Strategic Account Partner.
   11/14/2019 Dan Carmen        Remove ISDC code
   12/03/2019 Matt Fritschi   Fixed SOQL Query Limit from setStrategicAccountPartner
   04/13/2021 Brandon Vidro   Added handleReferralOwnershipDriftLeads()
   10/24/2022 Pujitha Madamanchi  APR0142376 - reassign Record/Queue Assignment
   09/28/2023 Dan Carmen          Remove "Lead Flopper" code that isn't being used.

*/
public without sharing class LeadMethods {
    
    /** Ids that have already been processed in the trigger that we do not want to process again. */
    public static Set<Id> leadIdsProcessed = new Set<Id>();
    
    public static Set<Id> doNotCheckOwnedIdSet = new Set<Id>();
    
    public static String NSS_PENDING_QUEUE='NSS Pending Queue';
    
    // we don't want to get recursively buried in the triggers. Make sure we can't enter them again.
    // is the lead before trigger executing?
    public static Boolean LEAD_BEFORE_EXECUTING=false;
    // is the lead after trigger executing? 
    public static Boolean LEAD_AFTER_EXECUTING=false;
    // make sure round robin doesn't run recursively from trigger.
    public static Boolean LEAD_WAS_PROCESSED_ROUND_ROBIN = false;
    
    public static Boolean DISABLE_DIAL_CHECKBOX = (Label.OwnershipDisableDial == 'Y');
    
    // save record type id for later  
    public static Schema.RecordTypeInfo rtPEOInfo = RecordTypeHelper.getRecordType(Label.RT_PEO_Lead, ObjectHelper.OBJECT_LEAD);
    
    // check leads coming from the after trigger. 
    // if dialed, or call disposition, check the ownership records
    public static void checkLeadAfterTrigger(Set<Id> dialedIdSet, Set<Id> ownerIdChangedSet, Set<Id> callDispositionSet) {
        System.debug('checkLeadAfterTrigger DISABLE_DIAL_CHECKBOX='+DISABLE_DIAL_CHECKBOX+' dialedIdSet='+dialedIdSet+' ownerIdChangedSet='+ownerIdChangedSet+' callDispositionSet='+callDispositionSet);
        Set<Id> allLeadIdSet = new Set<Id>();
        if (DISABLE_DIAL_CHECKBOX) {
            dialedIdSet.clear();
            System.debug('checkLeadAfterTrigger dialedIdSet='+dialedIdSet.size());
        }
        allLeadIdSet.addAll(dialedIdSet);
        allLeadIdSet.addAll(ownerIdChangedSet);
        allLeadIdSet.addAll(callDispositionSet);
        
        leadIdsProcessed.addAll(allLeadIdSet);
        
        Lead[] leads = ReferralQueries.selectLeads(allLeadIdSet, null); //oldOwnerIdMap.keySet());
        
        Set<Id> ownerIdSet = new Set<Id>();
        // add the running user
        ownerIdSet.add(UserInfo.getUserId());
        
        Set<Id> leadCompanyIdSet = new Set<Id>();
        
        // get the lead company and owner ids
        for (Lead ld : leads) {
            if (ld.Lead_Company__c != null) {
                leadCompanyIdSet.add(ld.Lead_Company__c);
            }
            //if (ld.DialedUserId__c != null) {
            //    ownerIdSet.add(ld.DialedUserId__c);
            //}
            // always add the owner id
            ownerIdSet.add(ld.OwnerId);
        } // for (Lead ld)
        
        // get a map of the users
        Map<Id,User> nsrUserMap = ProspectOwnershipMethods.getNsrUserMap(ownerIdSet);
        // get the most relevant ownership records per lead
        Map<Id,Prospect_Ownership__c> ownerMap = checkLeadOwners(leads, leadCompanyIdSet);
        
        // right now this is only going to be executed from a trigger - use the running user if they're an NSR
        User runningUser = nsrUserMap.get(UserInfo.getUserId());
        System.debug('checkLeadAfterTrigger runningUser='+runningUser);
        
        // the source of the running user
        String runningUserSource = (runningUser != null ? ProspectOwnershipMethods.getNSS_Source(runningUser) : null);
        
        ProspectOwnershipMethods.initializeSaveObjects();
        
        for (Lead ld : leads) {
            User nsrOwner = nsrUserMap.get(ld.OwnerId);
            // default to the running user if dialed checkbox is set
            User dialedUser = (dialedIdSet.contains(ld.Id) ? runningUser : null);
            System.debug('checkLeadAfterTrigger ld='+ld.Name+' nsrOwner='+nsrOwner+' dialedUser='+dialedUser);
            String ownershipSource = null;
            
            Boolean endOwnership = false;
            String newOwnershipStatus = null;
            // this will be true if 1) not actually dialed or 2) dialed and the user is an NSR
            Boolean dialedOkay = true;
            /* 9/28/2023 Dan Carmen - dont' believe this is being used.
            if (String.isNotBlank(ld.DialedUserId__c)) {
                Id dialedUserId = (Id)ld.DialedUserId__c;
                User checkUser = nsrUserMap.get(dialedUserId);
                System.debug('checkLeadAfterTrigger ld.DialedUserId__c='+ld.DialedUserId__c+' checkUser='+checkUser);
                if (checkUser != null) {
                    ownershipSource = 'DialedUserId';
                    dialedUser = checkUser;
                    dialedOkay = (dialedUser != null);
                } // if (checkUser != null
            } // if (String.isNotBlank
            System.debug('checkLeadAfterTrigger ld='+ld.Name+' dialedOkay='+dialedOkay+' dialedUser='+dialedUser);
            */
            
            if (!DISABLE_DIAL_CHECKBOX && ld.Dialed__c) {
                //dialedUser = runningUser;
                // we'll assume prospecting if this record is dialed.
                newOwnershipStatus = ProspectOwnershipMethods.STAGE_PROSPECTING;
                dialedOkay = (dialedUser != null);
                System.debug('checkLeadAfterTrigger checking dialed for '+ld.Name+' dialedOkay='+dialedOkay+' dialedUser='+dialedUser);
                // change the owner of the lead
            } // if (ld.Dialed__c
            
            LeadCallDisposition__c lcd = null;
            
            if (callDispositionSet.contains(ld.Id)) {
                lcd = findCallDisposition(ld.NSSCallDisposition__c, ld.Status);
                System.debug('checkLeadAfterTrigger disposition='+ld.NSSCallDisposition__c+' lcd='+lcd);
                if (lcd != null && String.isNotBlank(lcd.NewOwnershipStatus__c)) {
                    // we'll be setting ownership in this case
                    newOwnershipStatus = lcd.NewOwnershipStatus__c;
                    if (dialedUser == null) {
                        dialedUser = nsrOwner;
                        dialedOkay = (dialedUser != null);
                    }
                }
            } // if (callDispositionSet.contains
            
            if (dialedOkay && dialedUser != null && ld.OwnerId != dialedUser.Id) {
                System.debug('checkLeadAfterTrigger changed owner for '+ld.Name);
                nsrOwner = dialedUser;
                ld.OwnerId = dialedUser.Id;
                // if the user changes recheck the NSS Source
                ProspectOwnershipMethods.saveLeadMap.put(ld.Id,ld);
            }
            
            String[] nssTeams = ProspectOwnershipMethods.getNSSTeams(nsrOwner, ld.Products__c,ld.RecordType.Name, null, UserHelper.SO_CORE, ld.NumberOfEmployees);
            // use the first one returned in the array - should always be at least one returned
            String nssTeam = nssTeams[0];
            
            String nssSource = (nsrOwner != null ? ProspectOwnershipMethods.getNSS_Source(nsrOwner) : ProspectOwnershipMethods.NSS_OUTBOUND);
            
            if (ownerIdChangedSet.contains(ld.Id)) {
                System.debug('checkLeadAfterTrigger ownerIdChangedSet nsrOwner='+nsrOwner);
                // if the owner changed, and the new owner is not an NSR, we want to end any open ownership.
                if (nsrOwner == null) {
                    System.debug('checkLeadAfterTrigger no nsr for owner, ending ownership.');
                    endOwnership = true;
                    newOwnershipStatus = null;
                    //} else {
                    //   newOwnershipStatus = ProspectOwnershipMethods.STAGE_PROSPECTING;
                }
            } // if (ownerIdChangedSet
            
            
            // get the existing prospect ownership record (if any)         
            Prospect_Ownership__c po = ownerMap.get(ld.Id);
            System.debug('checkLeadAfterTrigger newOwnershipStatus='+newOwnershipStatus+' po='+po);
            
            String newLeadStatus = null;
            
            // is this record in here because of a call disposition change?
            //if (callDispositionSet.contains(ld.Id)) {
            //   lcd = findCallDisposition(ld.NSSCallDisposition__c, ld.Status);
            //   System.debug('checkLeadAfterTrigger disposition='+ld.NSSCallDisposition__c+' lcd='+lcd);
            if (lcd != null) {
                Boolean changed = false;
                //if (String.isNotBlank(lcd.NewOwnershipStatus__c)) {
                // we'll be setting ownership in this case
                //   newOwnershipStatus = lcd.NewOwnershipStatus__c;
                
                System.debug('checkLeadAfterTrigger ld.Status='+ld.Status+' lcd.NewLeadStatus__c='+lcd.NewLeadStatus__c+' newOwnershipStatus='+newOwnershipStatus);
                endOwnership = lcd.EndOwnership__c;
                // if we're ending ownership, we don't need to set a next status.
                if (endOwnership) {
                    newOwnershipStatus = null;
                }
                
                if (lcd.SetDoNotCall__c && !ld.DoNotCall) {
                    ld.DoNotCall = true;
                    changed = true;
                } // if (SetDoNotCall__c
                
                System.debug('checkLeadAfterTrigger lead changed due to call disposition='+changed);
                if (changed) {
                    ProspectOwnershipMethods.saveLeadMap.put(ld.Id,ld);
                }
            } // if (lcd != null
            
            //} // if (callDispositionSet.contains(ld.Id
            
            Boolean createNewOwnership = false;
            
            if (po == null && endOwnership) {
                // do nothing - we will not create an ownership record if it will be immediately ended
            } else if (po == null && String.isNotBlank(newOwnershipStatus) && dialedOkay) {
                // create a new ownership record if one doesn't currently exist
                createNewOwnership = true;
            } // if (po == null
            
            System.debug('checkLeadAfterTrigger newOwnershipStatus='+newOwnershipStatus+' endOwnership='+endOwnership+' createNewOwnership='+createNewOwnership+' dialedOkay='+dialedOkay);
            
            if (po != null && !endOwnership) {
                // compare what the current ownership is. If they're the same, do nothing
                if (nssSource != po.NSS_Source__c) {
                    // if the new one is inbound, they're allowed to take ownership from outbound
                    if (nssSource == ProspectOwnershipMethods.NSS_INBOUND) {
                        // end the existing record
                        ProspectOwnershipMethods.setStageExitInfo(po, null, null, null, ld, true, true, true);
                        ProspectOwnershipMethods.addToNotes(po,'Ownership ended due to Inbound NSR taking ownership from Outbound.');
                        System.debug('checkLeadAfterTrigger ended ownership due to inbound po:'+po);
                        // clear out the variable so a new one is created
                        po = null;
                        createNewOwnership = true;
                    } // if (newUserType == NSS_INBOUND
                } else if (nssSource == po.NSS_Source__c) {
                    // evaluate the nssTeam to see if it's different - account for the products changing.
                    if (nssTeam != po.NSS_Team__c) {
                        po.NSS_Team__c = nssTeam;
                        // update with the new ownership.
                        ProspectOwnershipMethods.addToUpsertMap(po, false);
                    }
                    // make sure the lead is the same
                    if (po.Lead__c != ld.Id) {
                        System.debug('checkLeadAfterTrigger changing the lead');
                        po.Lead__c = ld.Id;
                        ProspectOwnershipMethods.addToUpsertMap(po, false);
                    }
                } // if (newUserType != po.NSS_Team__c
            } // if (po != null
            
            if (po != null) {
                // do we need to set a new status?
                Boolean hasNewStatus = (!endOwnership && String.isNotBlank(newOwnershipStatus) && po.Ownership_Status__c != newOwnershipStatus);
                Boolean useThisOwnership = !hasNewStatus;
                System.debug('checkLeadAfterTrigger hasNewStatus='+hasNewStatus+' newOwnershipStatus='+newOwnershipStatus+' po.Ownership_Status__c='+po.Ownership_Status__c);
                
                // do we need to create a new ownership record, or can we reuse the one we have?
                if (dialedOkay && !endOwnership && hasNewStatus) {
                    // if we have a new ownership status - can we use the existing record
                    LifeOfLeadSettings__c thisSetting = ProspectOwnershipMethods.getSetting(po);
                    useThisOwnership = (thisSetting != null && thisSetting.NextOwnershipStage__c == newOwnershipStatus);
                    System.debug('checkLeadAfterTrigger dialedOkay useThisOwnership='+useThisOwnership);
                    
                    // if it's not the next stage in the current ownership, see if the settings for the next status allow us to use the same one.
                    if (!useThisOwnership) {
                        // clone the original one so we can get the setting without having to worry about the parameters
                        Prospect_Ownership__c po2 = po.clone(false,true);
                        po2.Ownership_Status__c = newOwnershipStatus;
                        LifeOfLeadSettings__c newSetting = ProspectOwnershipMethods.getSetting(po2);
                        useThisOwnership = (newSetting != null && newSetting.AlwaysAllowAsNext__c);
                    } // if (!useThis
                    // we will create new ownership if we cannot use the existing ownership record
                    createNewOwnership = !useThisOwnership;
                } // if (!endOwnership && hasNewStatus
                
                // if we need to end ownership, end it here
                if (endOwnership || !useThisOwnership || !dialedOkay) {
                    System.debug('checkLeadAfterTrigger force end ownership ld='+ld.Name+' endOwnership='+endOwnership+' useThisOwnership='+useThisOwnership+' dialedOkay='+dialedOkay);
                    
                    Boolean endOnlyRunningUser = (lcd != null ? lcd.EndOnlyRunningUser__c : false);
                    // check to make sure they're able to end the ownership.
                    if (!endOnlyRunningUser || (endOnlyRunningUser && dialedUser != null && po.NSR_Name__c == dialedUser.Id)) {
                        // force the expiration of the ownership record
                        ProspectOwnershipMethods.setStageExitInfo(po, null, null, null, ld, true, true, true);
                    }
                } else if (hasNewStatus) {
                    System.debug('checkLeadAfterTrigger hasNewStatus ld='+ld.Name+' newOwnershipStatus='+newOwnershipStatus);
                    ProspectOwnershipMethods.addToProcessTracker(po,'checkLeadAfterTrigger change status from '+po.Ownership_Status__c+' to '+newOwnershipStatus);
                    ProspectOwnershipMethods.setStageExitInfo(po, null, null, null, ld, false, true, false);
                    po.Ownership_Status__c = newOwnershipStatus;
                    ProspectOwnershipMethods.setStageEntryInfo(po, null, null, null, ld, true, false);
                } // if (String.isNotBlank
                
            } // if (po != null
            
            System.debug('checkLeadAfterTrigger createNewOwnership='+createNewOwnership+' nsrOwner='+nsrOwner);
            if (createNewOwnership && nsrOwner != null) {
                Id nsrId = null;
                
                // if there an existing ownership record use the data from that record
                if (po != null) {
                    nsrId = po.NSR_Name__c;
                } else {
                    nssSource = ProspectOwnershipMethods.getNSS_Source(nsrOwner);
                    nsrId = nsrOwner.Id;
                } // if (po != null
                
                System.debug('checkLeadAfterTrigger creating new ownership'); 
                String newSegment = ProspectOwnershipMethods.determineSegment(ld.PostalCode, nssTeam, ld);            
                Prospect_Ownership__c newPo = new Prospect_Ownership__c(Lead__c=ld.Id, Lead_Company__c=ld.Lead_Company__c
                                                                        ,NSR_Name__c=nsrId,OwnerId=nsrId, NSS_Team__c=nssTeam, NSS_Source__c=nssSource
                                                                        ,StartDate__c = Date.today()
                                                                        ,Segment__c = newSegment                                           
                                                                        ,Ownership_Status__c = newOwnershipStatus, Source__c = ownershipSource);
                ProspectOwnershipMethods.addToProcessTracker(newPo, 'Created from LeadMethods lcd='+(lcd != null ? lcd.Name : 'null'));
                ProspectOwnershipMethods.setStageEntryInfo(newPo, null, null, null, ld, true, false);
                
            } // if (createNewOwnership && nsrOwner
            
            // have to do this here in case the setStageExitInfo changes ownership/status
            if (lcd != null) {
                Boolean changed = (!lcd.QueueOnlyForReferral__c ? assignQueueToLead(lcd.AssignToQueue__c,ld) : false);
                if (String.isNotBlank(lcd.NewLeadStatus__c) && ld.Status != lcd.NewLeadStatus__c) {
                    System.debug('checkLeadAfterTrigger changing lead status to '+lcd.NewLeadStatus__c);
                    ld.Status = lcd.NewLeadStatus__c;
                    changed = true;
                } // if (ld.Status != lcd.NewLeadStatus__c
                
                System.debug('checkLeadAfterTrigger has lcd changed='+changed);
                if (changed) {
                    ProspectOwnershipMethods.saveLeadMap.put(ld.Id,ld);
                }
            } // if (lcd != null
            
            if (ld.DialedUserId__c != null) {
                ld.DialedUserId__c = null;
                ProspectOwnershipMethods.saveLeadMap.put(ld.Id,ld);
            }
            if (ld.Dialed__c) {
                System.debug('checkLeadAfterTrigger reseting Dialed checkbox');
                // uncheck the dialed flag
                ld.Dialed__c = false;
                ld.DialedLastUsed__c = DateTime.now();
                // make sure we're saving the record
                ProspectOwnershipMethods.saveLeadMap.put(ld.Id,ld);
            }
            if (String.isNotBlank(ld.NSSCallDisposition__c)) {
                System.debug('checkLeadAfterTrigger setting last NSS Call Disposition, clearing current field');
                // save the old value and clear the new value so the field can be triggered again.
                ld.LastNSSCallDisposition__c = ld.NSSCallDisposition__c;
                ld.DialedLastUsed__c = DateTime.now();
                ld.NSSCallDisposition__c = null;
                // make sure we're saving the record
                ProspectOwnershipMethods.saveLeadMap.put(ld.Id,ld);
            } // if (String.isNotBlank(
            
        } // for (Lead ld
        
        // don't execute the lead triggers again if the lead is updated
        Boolean leadBeforeStatus = LEAD_BEFORE_EXECUTING;
        Boolean leadAfterStatus = LEAD_AFTER_EXECUTING;
        LEAD_BEFORE_EXECUTING=true;
        LEAD_AFTER_EXECUTING=true;
        
        ProspectOwnershipMethods.checkForSaves();
        // revert status
        LEAD_BEFORE_EXECUTING = leadBeforeStatus;
        LEAD_AFTER_EXECUTING = leadAfterStatus;
        
    } // checkLeadAfterTrigger
    
    private static UserHelper uh = new UserHelper();
    
    public static Boolean assignQueueToLead(String queueName, Lead ld) {
        Boolean ownerAssigned = false;
        if (String.isNotBlank(queueName)) {
            Group queue = uh.getQueue(queueName);
            System.debug('queue='+queue);
            if (queue != null && ld.OwnerId != queue.Id) {
                CheckDataGovernance.SKIP_DATA_GOVERNANCE = true;
                System.debug('assignQueueToLead Changing to the queue owner and removing the ownership start date');
                ld.OwnerId = queue.Id;
                // we don't want the email generated
                Database.DMLOptions dlo = new Database.DMLOptions();
                dlo.EmailHeader.triggerAutoResponseEmail = false;
                dlo.EmailHeader.triggerUserEmail = false;
                dlo.EmailHeader.triggerOtherEmail = false;
                ld.setOptions(dlo);
                
                ld.NSS_Ownership_Start_Date__c = null;
                ownerAssigned = true;
            }
        } // if (String.isNotBlank
        
        return ownerAssigned;
    } // assignQueueToLead
    
    public static void handleReferralOwnershipDriftLeads(Map<Id, Lead> driftChatQueueLeads) {
        List<Referral__c> refs = [Select Id, OwnerId, SourceLead__c from Referral__c where SourceLead__c IN :driftChatQueueLeads.keySet()];
        Map<Id,Id> ldOwnerIds = new Map<Id,Id>();
        for(Lead ld: driftChatQueueLeads.values()) {
            ldOwnerIds.put(ld.Id, ld.OwnerId);
        }
        for(Referral__c ref: refs) {
            ref.OwnerId = ldOwnerIds.get(ref.SourceLead__c);
        }
        DmlHelper.performDML2(refs, DmlHelper.DML_UPDATE, 'LeadMethods', 'handleReferralOwnershipDriftLeads', 'Update Drift Referrals from Lead Owner', true); 
    }
    
    public static final Integer NAME_FIELD_LENGTH = LeadCallDisposition__c.Name.getDescribe().getLength();
    
    public static LeadCallDisposition__c findCallDisposition(String callDisposition, String curStatus) {
        System.debug('findCallDisposition callDisposition='+callDisposition+'; curStatus='+curStatus+';');
        
        LeadCallDisposition__c foundLcd = null;
        if (String.isNotBlank(callDisposition)) {
            
            // create a string without any extra characters - should be the name of the custom setting
            // make sure the field isn't longer than the name field
            String searchString = ((callDisposition+(String.isNotBlank(curStatus) ? curStatus : '')).replace(' ','')).left(NAME_FIELD_LENGTH);
            System.debug('findCallDisposition searchString='+searchString);
            
            foundLcd = LeadCallDisposition__c.getInstance(searchString);
            System.debug('findCallDisposition 1st attempt searchString='+searchString+' foundLcd='+(foundLcd != null));
            // if we don't find it using the current status - trying finding it without the current status (to get the default value)
            if (foundLcd == null && String.isNotBlank(curStatus)) {
                searchString = (callDisposition.replace(' ','')).left(NAME_FIELD_LENGTH);
                foundLcd = LeadCallDisposition__c.getInstance(searchString);
                System.debug('findCallDisposition 2nd attempt searchString='+searchString+' foundLcd='+(foundLcd != null));
            }
        } // if (String.isNotBlank
        
        System.debug('findCallDisposition foundLcd='+foundLcd);
        return foundLcd;
    } // findCallDisposition
    
    /** Coming from the after trigger. 
*/
    public static void checkOwnedBy(Set<Id> leadIdSet) {
        System.debug('checkOwnedBy - after trigger');
        Lead[] leads = ReferralQueries.selectLeads(leadIdSet,null);
        Map<Id,Lead_Company__c> companyMap = new Map<Id,Lead_Company__c>();
        // map of the lead company ids
        Set<Id> leadCompanyIdSet = new Set<Id>();
        for (Lead ld : leads) {
            if (ld.Lead_Company__r != null) {
                companyMap.put(ld.Id, ld.Lead_Company__r);
                leadCompanyIdSet.add(ld.Lead_Company__c);
            }
            
            //Prospect_Ownership__c po = ProspectOwnershipMethods.getProspectingOwner(ld.Prospect_Ownership__r,null, null);
            //if (po != null) {
            //  ownerMap.put(ld.Id, po);
            //}
        } // for (Lead ld
        
        Map<Id,Prospect_Ownership__c> ownerMap = checkLeadOwners(leads, leadCompanyIdSet);
        
        checkOwnedBy(leads,true, ownerMap, companyMap);
    } // checkOwnedBy
    
    /** Coming from the before trigger.
*/
    public static void checkOwnedBy(Lead[] leads) {
        System.debug('checkOwnedBy - before trigger');
        Set<Id> leadIdSet = new Set<Id>();
        
        Map<Id, List<Lead>> leadListByCompanyMap = new Map<Id,List<Lead>>();
        for (Lead ld : leads) {
            leadIdSet.add(ld.Id);
            if (ld.Lead_Company__c != null) {
                List<Lead> leadList = leadListByCompanyMap.get(ld.Lead_Company__c);
                if (leadList == null) {
                    leadList = new List<Lead>();
                    leadListByCompanyMap.put(ld.Lead_Company__c,leadList);
                }
                leadList.add(ld);
            } // if (ld.Lead_Company__c != null
        } // for (Lead ld
        
        //Map<Id,Prospect_Ownership__c> ownerMap = ProspectOwnershipMethods.getMapByLeadIds(leadIdSet);
        Map<Id,Prospect_Ownership__c> ownerMap = checkLeadOwners(leads, leadListByCompanyMap.keySet());
        
        //Map<Id,List<Prospect_Ownership__c>> ownersByLeadCompanyMap = ProspectOwnershipMethods.getMapByLeadCompanyIds(leadListByCompanyMap.keySet());
        
        Map<Id,Lead_Company__c> companyMap = new Map<Id,Lead_Company__c>();
        if (!leadListByCompanyMap.isEmpty()) {
            String query = ObjectHelper.getSOQLQuery('Lead_Company__c',null,true, true);
            if (query != null) {
                Set<Id> keySet = leadListByCompanyMap.keySet();
                query += ' Where Id in :keySet';
                List<Lead_Company__c> recs = (List<Lead_Company__c>)Database.query(query);
                // put results into a map - should only have one active record per lead
                for (Lead_Company__c lc : recs) {
                    List<Lead> leadList = leadListByCompanyMap.get(lc.Id);
                    for (Lead ld : leadList) {
                        companyMap.put(ld.Id, lc);
                    }
                } // for (Lead_Company__c lc
            } // if (query != null
        } // if (!leadCompanyIdSet.isEmpty
        checkOwnedBy(leads,false, ownerMap, companyMap);
    } // checkOwnedBy
    
    // pull out the most relevant ownership record, and expire any others that might exist.
    public static Map<Id,Prospect_Ownership__c> checkLeadOwners(Lead[] leads, Set<Id> leadCompanyIdSet) {
        Map<Id,Prospect_Ownership__c> ownerMap = new Map<Id, Prospect_Ownership__c>();
        Map<Id,List<Prospect_Ownership__c>> ownersByLeadCompanyMap = ProspectOwnershipMethods.getMapByLeadCompanyIds(leadCompanyIdSet);
        ProspectOwnershipMethods.initializeSaveObjects();
        
        for (Lead ld : leads) {
            List<Prospect_Ownership__c> ownerList = ownersByLeadCompanyMap.get(ld.Lead_Company__c);
            System.debug('checkLeadOwners ownerList size='+(ownerList != null ? ownerList.size() : -1));
            if (ownerList != null && !ownerList.isEmpty()) {
                ownerMap.put(ld.Id, ownerList[0]);
                // should only be one open owner record on a lead
                if (ownerList.size() > 1) {
                    for (Integer cnt=1; cnt<ownerList.size(); cnt++) {
                        Prospect_Ownership__c thisPo = ownerList[cnt];
                        System.debug('checkLeadOwners ending thisPo='+thisPo);
                        // don't pass in the lead - changes will be made to it elsewhere.
                        ProspectOwnershipMethods.setStageExitInfo(thisPo, null, null, null, null, true, false, true);
                    }
                }
            } // if (ownerList != null
        } // for (Lead ld
        
        // don't save lead changes here
        ProspectOwnershipMethods.saveLeadMap.clear();
        ProspectOwnershipMethods.checkForSaves();
        return ownerMap;
    } // checkLeadOwners
    public class LeadWrapper {
        public Lead ld;
        public Boolean hasVirtualOwnership=false;
        public Boolean hasProspectOwnership=false;
        public PartnerReferral__c mothership;
        public Boolean leadHandled=false;
    }
    
    public class SendToVirtualWrapper {
        public Map<Id,Campaign> campaignAlwaysSendMap = new Map<Id,Campaign>();     
        public Map<Id,Campaign> campaignCheckZipMap = new Map<Id,Campaign>();
    } // class SendToVirtualWrapper
    
    public static SendToVirtualWrapper campaignWrapper = null;
    
    public static String CACHE_KEY='SendToVirtualWrapper';
    
    // get campaigns set to go straight to virtual. Used to determine if lead should go to virtual.  If the amount of campaigns that we're using in this process
    // becomes more than a handful this should be changed to use two queries directly mapped to the maps instead of one query with a for loop to break them out.
    public static void checkCampaignWrapper() {
        if (campaignWrapper == null) {
            campaignWrapper = (SendToVirtualWrapper)CacheManager.getOrg(CACHE_KEY);
        }
        if (campaignWrapper == null) {
            campaignWrapper = new SendToVirtualWrapper();
            Campaign[] campaigns = [SELECT Id,Name,Send_To_Virtual__c FROM Campaign WHERE Send_To_Virtual__c!=null and IsActive=true];
            for (Campaign c : campaigns) {
                if (c.Send_To_Virtual__c == 'Always') {
                    campaignWrapper.campaignAlwaysSendMap.put(c.Id,c);
                } else if (c.Send_To_Virtual__c == 'Check Zips') {
                    campaignWrapper.campaignCheckZipMap.put(c.Id,c);
                } // if (c.Send_To_Virtual__c
            } // for (Campaign c
            
            CacheManager.putOrg(CACHE_KEY,campaignWrapper);
        } // if (campaignWrapper == null
        System.debug('checkCampaignWrapper campaignAlwaysSendMap='+campaignWrapper.campaignAlwaysSendMap.size()+' campaignCheckZipMap='+campaignWrapper.campaignCheckZipMap.size());
        
    } // checkCampaignWrapper
    
    /** Check the value of the owned by field on incoming leads and determine how to set ownership based on that.
*/
    public static void checkOwnedBy(Lead[] leads, Boolean updateLeads, Map<Id,Prospect_Ownership__c> ownerMap, Map<Id,Lead_Company__c> companyMap) {
        System.debug('checkOwnedBy leads='+leads.size()+' updateLeads='+updateLeads);
        //Lead[] leadsToUpdate = new Lead[]{};
        Map<Id,Lead_Company__c> companiesToUpdateMap = new Map<Id,Lead_Company__c>();
        
        List<Lead> virtualLeads = new List<Lead>();
        List<sObject> updateChatter = new List<sObject>();
        
        ProspectOwnershipMethods.initializeSaveObjects();
        
        // if we need to use the assignment rules on the leads
        List<Lead> checkOwnerLeads = new List<Lead>();
        
        checkCampaignWrapper();
        
        
        // allow to group by zip code
        Map<String,LeadWrapper[]> virtualLeadByZipMap = new Map<String,LeadWrapper[]>();     
        
        LeadWrapper[] leadWraps = new LeadWrapper[]{};
            
            PartnerReferral__c[] mothers = new PartnerReferral__c[]{};
                
                Map<Id,List<PartnerReferral__c>> leadPartnerMap = new Map<Id,List<PartnerReferral__c>>();
        Id virtualQueue;
        Boolean sendToVirtualActive =false;
        
        
        BypassNSS__c bNSS = BypassNSS__c.getOrgDefaults();
        System.debug('checkOwnedBy bNSS='+bNSS);
        if (bNSS != null && bNSS.SetupOwnerId != null) {
            sendToVirtualActive = bNSS.IsActive__c;
            virtualQueue = bNSS.Queue_Id__c;
            Integer partRefDuration = (Integer)bNSS.Partner_Referral_Expiration_Duration__c * -1;
            Date partRefExpiration = system.today().addDays(partRefDuration);
            //get all PartnerReferrals related to the record that came in the designated timeframe
            PartnerReferral__c[] partnerQueryList = [SELECT Id,Contact__c,Account__c,Lead__c,Lead__r.OwnerId,Destination__c,Source__c FROM PartnerReferral__c WHERE Lead__c in :leads AND Master_Partner_Referral__c=null AND CreatedDate >= :partRefExpiration order by CreatedDate asc];
            for (PartnerReferral__c partner:partnerQueryList){
                if (leadPartnerMap.containsKey(partner.Account__c)){
                    leadPartnerMap.get(partner.Account__c).add(partner);
                } else {
                    PartnerReferral__c[] pAccountList = new PartnerReferral__c[]{partner};
                        leadPartnerMap.put(partner.Account__c,pAccountList);            
                }
            } // for (PartnerReferral__c
        } // if(bNSS!=null
        
        System.debug('checkOwnedBy leads='+leads.size()+' sendToVirtualActive='+sendToVirtualActive);
        for (lead ld : leads) {
            StringHelper.addToProcessNotes(ld, 'Entered LeadMethods.checkOwnedBy');
            LeadWrapper leadWrap= new LeadWrapper();
            leadWrap.ld = ld;
            leadWraps.add(leadWrap);
            
            // TODO - we shouldn't be creating partner referrals for everything - only for Store Original Data on Lead Loader Config
            PartnerReferral__c mothership = new PartnerReferral__c();
            mothership.Lead__c = ld.Id;
            mothership.Campaign__c = ld.LatestCampaign__c;
            mothership.Source__c= ld.OwnedBy__c;
            mothership.Description__c = ld.Description;
            //get PartnerReferral of the record that came in first in the designated timeframe.  All subsequent records that come in during that timeframe are owned by the same person. 
            PartnerReferral__c[] masterReferrals = leadPartnerMap.get(ld.Id);
            if(masterReferrals!= null && !masterReferrals.isEmpty()){
                PartnerReferral__c masterReferral = masterReferrals.get(0);
                mothership.Master_Partner_Referral__c = masterReferral.Id;
            }
            leadWrap.mothership = mothership;
            mothers.add(mothership);
            
            // check for open ownership record
            Prospect_Ownership__c po = ownerMap.get(ld.Id);
            system.debug('Lead Name: '+ld.Name+' PO: '+po);
            Lead_Company__c company = companyMap.get(ld.Id);
            
            // if no ownership
            LeadLoaderConfig__c config = LeadLoaderConfig__c.getInstance(ld.OwnedBy__c); 
            System.debug('checkOwnedBy processing ld='+ld.Name+' ownedBy='+ld.OwnedBy__c+' hasVirtualOwnership='+leadWrap.hasVirtualOwnership+' config='+config);
            StringHelper.addToProcessNotes(ld,'ownedBy='+ld.OwnedBy__c+' hasVirtualOwnership='+leadWrap.hasVirtualOwnership+' config='+(config != null ? config.Name : 'Not Found')+' po='+(po != null ? po.Name : 'Not Found'));
            
            //System.debug('checkOwnedBy ld='+ld);
            if (config != null && config.IsActive__c) {
                
                Id checkRecordTypeId = null;
                
                StringHelper.addToProcessNotes(ld,'NSSOwnership='+(config.IsNSSOwnership__c));
                if (config.IsNSSOwnership__c) {
                    String[] nssTeams = ProspectOwnershipMethods.getNSSTeams(null, ld.Products__c,ld.RecordType.Name, null, UserHelper.SO_CORE, ld.NumberOfEmployees );
                    // use the first one returned in the array - should always be at least one returned
                    String nssTeam = nssTeams[0];
                    Schema.RecordTypeInfo rt = ProspectOwnershipMethods.getLeadRecordTypeByNssTeam(nssTeam);
                    StringHelper.addToProcessNotes(ld,'nssTeam='+nssTeam+' rt='+(rt != null ? rt.getName() : 'Not Found'));
                    if (rt != null) {
                        checkRecordTypeId = rt.getRecordTypeId();
                    }
                } // if (config.IsNSSOwnership__c
                
                // if no ownership, set to the queue - doesn't matter if inbound or outbound
                if (po == null && String.IsNotBlank(config.QueueName__c)) {
                    // set this as the significant lead on the company
                    if (company != null && company.SignificantLead__c != ld.Id) {
                        company.SignificantLead__c = ld.Id;
                        companiesToUpdateMap.put(company.Id, company);
                    }
                    
                    if (setQueueAsOwner(config, ld)) {
                        leadWrap.leadHandled = true;
                    }
                    
                } else if (po != null && String.isNotBlank(config.NSSSource__c)) {
                    // if outbound queue and po is outbound - do nothing
                    if (config.NSSSource__c == ProspectOwnershipMethods.NSS_OUTBOUND && po.NSS_Source__c == config.NSSSource__c) {
                        // do nothing - already being worked by outbound
                        leadWrap.hasProspectOwnership = true;
                        if(leadWrap.ld.OwnerId != po.NSR_Name__c){
                            leadWrap.ld.OwnerId = po.NSR_Name__c;
                        }
                    } else if (config.NSSSource__c == ProspectOwnershipMethods.NSS_INBOUND && po.NSS_Source__c == config.NSSSource__c) {
                        // don't have to modify the existing ownership
                        // pop to the NSR
                        leadWrap.hasProspectOwnership = true;
                        if(leadWrap.ld.OwnerId != po.NSR_Name__c){
                            leadWrap.ld.OwnerId = po.NSR_Name__c;
                        }
                    } else if (config.NSSSource__c == ProspectOwnershipMethods.NSS_OUTBOUND && po.NSS_Source__c == ProspectOwnershipMethods.NSS_INBOUND) {
                        // do nothing - currently being worked by inbound - leave ownership as is
                        leadWrap.hasProspectOwnership = true;
                        if(leadWrap.ld.OwnerId != po.NSR_Name__c){
                            leadWrap.ld.OwnerId = po.NSR_Name__c;
                        }
                    } else if (config.NSSSource__c == ProspectOwnershipMethods.NSS_INBOUND && po.NSS_Source__c == ProspectOwnershipMethods.NSS_OUTBOUND) {
                        // end outbound ownership, pop to inbound queue
                        ProspectOwnershipMethods.setStageExitInfo(po, null, null, null, ld, true, true, true);
                        po = null;
                        if (setQueueAsOwner(config, ld)) {
                            leadWrap.leadHandled = true;
                        }
                    } // if (config.NSSSource__c
                } else if (po == null && config.UseAssignmentRules__c) {
                    StringHelper.addToProcessNotes(ld,'Setting UseZipAssignmentRules__c');
                    // if there's no open ownership we're going to use the zip assignment rules
                    ld.UseZipAssignmentRules__c = true;
                    checkOwnerLeads.add(ld);
                    leadWrap.leadHandled = true;
                } // if (po == null
                System.debug('checkOwnedBy config.NotifyOwner__c='+config.NotifyOwner__c+' ld.Id='+ld.Id);
                if (config.NotifyOwner__c && ld.Id != null) {
                    StringHelper.addToProcessNotes(ld,'added to notifyOwnerIdSet');
                    System.debug('checkOwnedBy added to notifyOwnerIdSet');
                    ChatterMessageSend.notifyOwnerIdSet.add(ld.Id);
                    //ld.NotifyOwner__c = config.NotifyOwner__c;
                }
                
                // make sure we have the correct record type - only if no open ownership.
                if (po == null && checkRecordTypeId != null) {
                    if (ld.RecordTypeId != checkRecordTypeId) {
                        ld.RecordTypeId = checkRecordTypeId;
                        leadWrap.leadHandled = true;
                    }
                } // if (po == null
                
                if(leadWrap.hasProspectOwnership){
                    leadWrap.mothership.Destination__c = 'NSS Prospect Ownership';
                }
                
            } // if (config != null
            
            
            StringHelper.addToProcessNotes(ld,'zip:'+leadWrap.ld.PostalCode+' campaign: '+leadWrap.ld.LatestCampaign__c +' sendToVirtualActive: '+sendToVirtualActive);
            // check if in the campaigns
            system.debug('zip:'+leadWrap.ld.PostalCode+' campaign: '+leadWrap.ld.LatestCampaign__c +' sendToVirtualActive: '+sendToVirtualActive);
            //check if lead is set to Always go to virtual, no matter who the territory rep is.
            if (sendToVirtualActive && campaignWrapper.campaignAlwaysSendMap.containsKey(leadWrap.ld.LatestCampaign__c)) {
                System.debug('checkOwnedBy ld='+ld.Name+' hasVirtualOwnership=Always Send');
                StringHelper.addToProcessNotes(ld, 'hasVirtualOwnership=Always Send');
                leadWrap.hasVirtualOwnership = true;
                leadWrap.leadHandled = true;
                leadWrap.mothership.Source__c=leadWrap.ld.OwnedBy__c;
                leadWrap.mothership.Destination__c = 'Virtual Sales';
                leadWrap.ld.OwnerId = virtualQueue;
                leadWrap.ld.UseZipAssignmentRules__c = false;
                if (updateLeads) {
                    virtualLeads.add(leadWrap.ld);
                }            
            }//if(campaignAlwaysSendMap
            //check if the lead is set to go to virtual based on zips, then create a map of zipcodes,leads to select.
            else if(leadWrap.ld.PostalCode!=null && sendToVirtualActive && campaignWrapper.campaignCheckZipMap.containsKey(leadWrap.ld.LatestCampaign__c)){
                System.debug('checkOwnedBy ld='+ld.Name+' hasVirtualOwnership=CheckZip');
                StringHelper.addToProcessNotes(ld, 'hasVirtualOwnership=CheckZip');
                String zipCode = (leadWrap.ld.PostalCode.length() > 5) ? leadWrap.ld.PostalCode.substring(0,4) : leadWrap.ld.PostalCode;
                LeadWrapper[] leadList = virtualLeadByZipMap.get(zipCode);
                if (leadList==null) {
                    leadList= new LeadWrapper[]{};
                        leadList.add(leadWrap);
                } else {
                    leadList.add(leadWrap);
                }
                virtualLeadByZipMap.put(zipCode,leadList);
            }//else if(leadWrap
        }//for(lead ld
        
        if (updateLeads) {
            ChatterMessageSend.checkAfterProcess();
        }
        /* 9/28/2023 Dan Carmen - don't believe this is needed because it's handled in TrackRecordEntry
        //get zip assignments for the incoming leads, but only if the territory rep is virtual.
        system.debug('virtualLeadByZipMap: '+virtualLeadByZipMap);
        if (!virtualLeadByZipMap.isEmpty()) {
            List<Zip_Assignment__c> zipList=[SELECT Name,Id,User__c,User__r.Name,User__r.UserRole.Name,User__r.NSS_Team__c 
                                             FROM Zip_Assignment__c 
                                             WHERE Name in :virtualLeadByZipMap.keySet() 
                                             AND Sales_Org__c=:UserHelper.SO_CORE 
                                             AND (Segment_Name__c=:ZipQueries.SEGMENT_DEFAULT OR Segment_Name__c='TIER2')
                                             AND (( User__r.UserRole.Name like '%Virtual%' 
                                                   AND User__r.NSS_Team__c = :Label.NSS_Team_VS_PAY) or (User__r.Name = 'Virtual Sales'))];
            
            //Check for VSR
            for (Zip_Assignment__c za:zipList) {
                system.debug('za: '+za);
                
                Boolean useQueue = (za.User__r.Name == 'Virtual Sales');
                
                LeadWrapper[] leadList = virtualLeadByZipMap.remove(za.Name);
                if (leadList != null) {
                    for (LeadWrapper leadWrap : leadList) {
                        leadWrap.hasVirtualOwnership = true;
                        leadWrap.leadHandled = true;
                        leadWrap.mothership.Source__c=leadWrap.ld.OwnedBy__c;
                        leadWrap.mothership.Destination__c = 'Virtual Sales';
                        if (useQueue) {
                            leadWrap.ld.OwnerId = virtualQueue;
                            leadWrap.ld.UseZipAssignmentRules__c = false;
                        } else {
                            leadWrap.ld.UseZipAssignmentRules__c=true;
                            checkOwnerLeads.add(leadWrap.ld);
                            system.debug('given assignment rules for lead: '+leadWrap.ld);
                            
                        }
                        if (updateLeads) {
                            virtualLeads.add(leadWrap.ld);
                        }
                    } // for (LeadWrapper leadWrap
                } // if (leadList != null
                
            }// for (Zip_Assignment__c
            
            
        } // if (!virtualLeadByZipMap.isEmpty
        */
        
        
        if(!mothers.isEmpty()){
            system.debug('inserting mothers');
            Database.insert(mothers,false);
        }
        
        Map<Id,Lead> rrLeadMap = new Map<Id,Lead>();
        Map<Id,PartnerReferral__c> rrMotherMap = new Map<Id,PartnerReferral__c>();
        for(LeadWrapper leadWrap:leadWraps){
            if(!leadWrap.hasVirtualOwnership && !leadWrap.hasProspectOwnership && !leadWrap.ld.UseZipAssignmentRules__c) {
                rrLeadMap.put(leadWrap.ld.Id,leadWrap.ld);
                rrMotherMap.put(leadWrap.ld.Id,leadWrap.mothership);
            }
        }
        
        if (!rrLeadMap.isEmpty() && !rrMotherMap.isEmpty()) {
            RoundRobin.prepareLeadRoundRobin(rrLeadMap,rrMotherMap);
        }
        
        for (LeadWrapper leadWrap : leadWraps) {
            Lead ld = leadWrap.ld;
            if(leadWrap.hasVirtualOwnership){
                updateChatter.add(leadWrap.ld);
            }
            
            StringHelper.addToProcessNotes(ld, 'leadHandled='+leadWrap.leadHandled);
            system.debug('handled - '+ld.Name+': '+leadWrap.leadHandled);
            // only clear out the ownedBy field if handled. But always save the lead
            if (leadWrap.leadHandled) {
                system.debug('in handled if - '+ld.Name);
                if (String.isNotBlank(ld.OwnedBy__c)) { 
                    ld.OwnedByPrev__c = ld.OwnedBy__c;
                }
                ld.OwnedBy__c = null;
            }
            doNotCheckOwnedIdSet.add(ld.Id);
            Database.DMLOptions dlo = new Database.DMLOptions();
            dlo.EmailHeader.triggerAutoResponseEmail = false;
            dlo.EmailHeader.triggerUserEmail = false;
            dlo.EmailHeader.triggerOtherEmail = false;
            ld.setOptions(dlo);
            ProspectOwnershipMethods.saveLeadMap.put(ld.Id,ld);
            System.debug('checkOwnedBy ProspectOwnershipMethods.saveLeadMap='+ProspectOwnershipMethods.saveLeadMap.size());
            if (updateleads) {
                system.debug('in update if - '+ld.Name);
                leadIdsProcessed.add(ld.Id);
            }
            //leadsToUpdate.add(ld);
            System.debug('checkOwnedBy ld='+ld.Name+' leadHandled='+leadWrap.leadHandled+' id='+ld.Id+' ld.OwnedBy__c='+ld.OwnedBy__c);        
            
        } // for (LeadWrapper leadWrap
        
        if (!checkOwnerLeads.isEmpty()) {
            LeadCheckOwner.processLeads(checkOwnerLeads, false);
        }
        if (!companiesToUpdateMap.isEmpty()) {
            Database.update(companiesToUpdateMap.values(),false);
        }
        if (!updateLeads) {
            System.debug('checkOwnedBy clearing the saveLeadMap');
            ProspectOwnershipMethods.saveLeadMap.clear();
        }
        if(!virtualLeads.isEmpty()){
            update virtualLeads;
        }
        if(!updateChatter.isEmpty()){
            
            sendChatterUpdate(updateChatter);
        }
        // we want to skip the data governance check since we'll be performing another update.
        //CheckDataGovernance.SKIP_DATA_GOVERNANCE = false;
        ProspectOwnershipMethods.checkForSaves();
        
    } // checkOwnedBy
    
    public static Boolean setQueueAsOwner(LeadLoaderConfig__c config, Lead ld) {
        Boolean leadHandled = false;
        Group queue = uh.getQueue(config.QueueName__c);
        system.debug('LEAD_WAS_PROCESSED_ROUND_ROBIN: '+LEAD_WAS_PROCESSED_ROUND_ROBIN);
        if (queue != null && ld.OwnerId != queue.Id && LEAD_WAS_PROCESSED_ROUND_ROBIN == false) {
            ld.OwnerId = queue.Id;
            leadHandled = true;
        }
        else if (LEAD_WAS_PROCESSED_ROUND_ROBIN == true)
        {
            leadHandled = true;
        }
        System.debug('setQueueAsOwner set to queue leadHandled='+leadHandled+' ld.OwnerId='+ld.OwnerId+' queue='+queue);
        return leadHandled;
    } // setQueueAsOwner
    
    //send virtual sales a chatter post when a lead or contact is assigned to them
    public static void sendChatterUpdate(List<sObject> records){
        String baseUrl = Utilities.instanceUrl();
        BypassNSS__c bNSS = BypassNSS__c.getOrgDefaults();
        Id[] mentionList = new Id[]{};
            if(bNSS!=null){
                if(bNSS.Queue_Id__c != null){
                    User[] users = [SELECT Id FROM User WHERE Id IN 
                                    (SELECT UserOrGroupId FROM GroupMember WHERE Group.Id = :bNSS.Queue_Id__c)];
                    for(User u:users){
                        mentionList.add(u.Id);
                        system.debug('mentionList: '+mentionList);
                    }
                    for(sObject s:records){
                        String chatterBody = 'A new '+s.getSObjectType().getDescribe().getName()+' has been assigned to you.\n';
                        //chatterBody+='\nPlease follow this link to view it: https://na5.salesforce.com/'+s.Id;
                        chatterBody+='\nPlease follow this link to view it:' + baseUrl + '/' + s.Id;
                        if(!Test.IsRunningTest()){
                            String[] bodyList = new String[]{chatterBody};
                                ChatterMentionPost.createChatterMentionPost(s.Id, mentionList, bodyList, true,false);
                        }
                    }
                    if(!Test.IsRunningTest()){
                        ChatterMentionPost.postBatchFeedElements();
                    }
                }
            }
    }
    
    // default Lead record type incase Lead Loader has null in this field
    private static Schema.RecordTypeInfo leadNSSrt = null;
    
    public static void checkLeadLoaderValidations(Lead newL, Lead oldL) {
        if (oldL == null) {
            // these are only done on insert
            if (String.isBlank(newL.LastName)) {
                newL.LastName = UserHelper.UNKNOWN;
            }
            if (newL.DoNotCall==null) {
                newL.DoNotCall = false;
            }
            if (String.isBlank(newL.RecordtypeId)) {
                if (leadNSSrt == null) {
                    leadNSSrt = ProspectOwnershipMethods.getLeadRecordTypeByNssTeam(UserHelper.SO_CORE);
                    //RecordTypeHelper.getRecordType('NSS Lead Record Type', 'Lead');
                }
                newL.RecordtypeId = leadNSSrt.getRecordTypeId();               
            }
        } // if (oldL == null
        
        if (oldL != null) {
            // do not allow it to change to 88888 if there's another postal code.
            if (newL.PostalCode == '88888' && String.isNotBlank(oldL.PostalCode)) {
                newL.PostalCode = oldL.PostalCode;
            }
        }
    } // checkLeadLoaderValidations
    
    public static void setStrategicAccountPartner(Map<Lead, Id> leadToRefCtct)
    {
        System.debug('LeadMethods setStrategicAccountPartner leadToRefCtct='+leadToRefCtct);
        
        Id[] refCtctIds = leadToRefctct.values();
        Map<Id, Referral_Contact__c> refCtctMap = new Map<Id, Referral_Contact__c>([SELECT Id, Name, Referral_Account__c FROM Referral_Contact__c WHERE Id IN :refCtctIds]);
      //System.debug('LeadMethods setStrategicAccountPartner refCtctMap='+refCtctMap);
        
        List<Id> refAcctIds = new List<Id>();
        if(!refCtctMap.isEmpty())
        {
            for(Referral_Contact__c refCtct : refCtctMap.values())
         {
               if(refCtct.Referral_Account__c != null)
               {
                  refAcctIds.add(refCtct.Referral_Account__c); 
               }
         }
         Map<Id, Referral_Account__c> refAcctMap = new Map<Id, Referral_Account__c>([SELECT Id, Name, RecordTypeId FROM Referral_Account__c WHERE Id IN :refAcctIds]);
        
         for(Lead ld : leadToRefCtct.keySet())
         {
               Id refCtctId = ld.Referral_Contact__c;
               Referral_Contact__c refCtct = refCtctMap.get(refCtctId);
            
               if(refCtct != null && refCtct.Referral_Account__c != null)
               {
                  Referral_Account__c refAcct = refAcctMap.get(refCtct.Referral_Account__c);
                
                  //System.debug('RefAcct='+refAcct);
                  if(refAcct != null && (refAcct.RecordTypeId == '01270000000UNXuAAO' || refAcct.RecordTypeId == '01270000000ULMAAA4'))
                  {
                     ld.Referral_National_Account__c = refAcct.Id;
                  }
               }
         }
        
        }
        
        /*
        if(refCtct.Referral_Account__c != null)
        {
            Referral_Account__c refAcct = [SELECT Id, Name, RecordTypeId FROM Referral_Account__c WHERE Id=:refCtct.Referral_Account__c LIMIT 1];
            System.debug('RefAcct='+refAcct);
            if(refAcct != null && (refAcct.RecordTypeId == '01270000000UNXuAAO' || refAcct.RecordTypeId == '01270000000ULMAAA4'))
            {
                newLead.Referral_National_Account__c = refAcct.Id;
            }
        }
*/
    }
        
    private static List<Lead> rrLeadList = new List<Lead>();
        
    // check actions from the before trigger
    public static void checkLeadBeforeActions(Lead newL, Lead oldL) {
        
        
        if (oldL != null && newL.Dialed__c || String.isNotBlank(newL.NSSCallDisposition__c)) {
            Boolean dialedTimeOkay = Utilities.checkDialedTimeOkay(newL.DialedLastUsed__c);
            // if it was dialed recently do not let the checkbox be set again
            if (!dialedTimeOkay && newL.Dialed__c) {
                newL.Dialed__c = false;
            }
            
            // clear out call disposition if within the time period and is the same as the previous value
            if (!dialedTimeOkay && String.isNotBlank(newL.NSSCallDisposition__c) && newL.NSSCallDisposition__c == newL.LastNSSCallDisposition__c) {
                newL.NSSCallDisposition__c = null;
            }
        } // if (newL.Dialed__c || String.isNotBlank(newL.NSSCallDisposition__c

        //APR0142376 - reassign Record/Queue Assignment - checkRoundRobin - leadByQueue
       if(newL.OwnerId!=null && (oldL == null || newL.OwnerId!= oldL.OwnerId) && String.valueOf(newL.OwnerId).startsWithIgnoreCase('00G')){
            rrLeadList.add(newL);
       }
       System.debug('checkLeadBeforeActions rrLeadList::'+rrLeadList.size());
    } // checkLeadBeforeActions
    
    public static void processBeforeActions() {
        
        //APR0142376 - reassign Record/Queue Assignment
        if(!rrLeadList.isEmpty()){
            RoundRobin.prepareGenericRoundRobin(rrLeadList,null);
        }
    } // processBeforeActions
    
} // class LeadMethods