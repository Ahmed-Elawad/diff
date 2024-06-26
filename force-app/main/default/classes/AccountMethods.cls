/** Methods on the Account object
*
* History
* -------
* 11/26/2013 Dan Carmen        Created.
* 07/07/2014 Cindy Freeman      Added methods to test DataFlux field changes
10/28/2014 Dan Carmen         Captured the exception when trying to save the account from setting the significant contact.
02/16/2015 Dan Carmen         Changes for Call Disposition
03/11/2015 Dan Carmen         Provide updates to the significant contact
01/19/2016 Dan Carmen         User Owned Shipping Address checkbox doesn't reset when record type changes.
02/15/2016 Dan Carmen         Add in functionality for EndOnlyRunningUser__c field.
03/10/2016 Jacob Hinds        Adding in setAccountType Method
04/12/2016 Dan Carmen         Change to clear NSS Call Disposition field on the account
05/02/2016 Jacob Hinds        Adding in HR Solutions Preview Client per INC0874095
05/02/2016 Dan Carmen         Ability to not trigger on the dialed checkbox
05/31/2016 Dan Carmen         Fix for setting the disposition on an account
09/14/2016 Cindy Freeman      Added a method for account junction stuff
01/27/2017 Cindy Freeman      added try/catch in updateAssetEmps method
02/08/2017 Cindy Freeman      modifed to only update assets or NumberOfEmployees if values really change
03/22/2017 Cindy Freeman      commented out processUpdateAssetEmps, not used any more
07/12/2017 Dan Carmen         Add additional Logging
12/12/2017 Dan Carmen         Additional adjustments to asset code
01/10/2018 Jacob Hinds        Commented out checkcalldisposition
05/11/2018 Jacob Hinds        Adding in RRS Partnership
07/13/2018 Jacob Hinds          Removing code preventing sfdcdata updating account owner with holdout. Fix for INC1676606
07/16/2018 Dan Carmen         Code for Client_Start_Date__c and CSSR_Segment__c
07/27/2018 Jacob Hinds        Small tweak to client start date
09/11/2018 Dan Carmen         Added in extra logging
10/30/2018 Jacob Hinds        Small change to asset query for HROi
11/06/2018 Jacob Hinds        Adding HROi automation method
12/06/2018 Dan Carmen       Replace qbdialer__LastCallTime__c with LatestCallTime__c
02/19/2019 Dan Carmen       Adjustment for PO Ownership
02/22/2019 Jacob Hinds        Removing hrg requirement from hroi type
05/15/2019 Jacob Hinds        Re-adding code for the above line
05/22/2019 Jacob Hinds     Adding client type Oasis
06/11/2019 Jacob Hinds     Certain client types will only be set for non peo RT accounts
07/02/2019 Brandon Vidro       Added check for CSSR Segment and Client Start Date to send Chatter Notification to new owner
07/17/2019 Dan Carmen          Change for HR Solutions account health
80/21/2019 Carrie Marciano    Added Hold Out when the account is linked to an Amplifinity Advocate
11/13/2019 Josh Cartwright   updated amp code to set status to suspended instead of inactive. 
11/20/2019 Josh Cartwright   changed wording on the chatter post for amp.    
03/03/2020 Jermaine Stukes   Removed holdout for amplifinity advocate on invite
03/06/2020 Dan Carmen        Add ability to filter products
03/17/2020 Jacob Hinds       changes for owner partnership
04/20/2020 Dan Carmen        Change significant contact criteria - exclue no longer with company, and decision maker first.
05/04/2020 Dan Carmen        Update checkForSignificanceRecalc to check owners when AccountId changes on contact.
05/14/2020 Manmeet Vaseer    SFDC-3313 Removed code related to HROi clients.
05/18/2020 Josh Cartwright   added to before method to set PRN Invitation Id.
07/16/2020 Brandon Vidro     Added updates for miEdge related Account fields
07/16/2020 Matt Fritschi     Disabled Amplifinity Advocate Chatter messages.
09/01/2020 Brandon Vidro     Updates to miEdge method
12/04/2020 Jake Hinds        Adding error log for prn invitation ID to try and figure out what is getting added
01/05/2021 Michael Karcz     Added check to set the Protected_Date__c field
04/16/2021 Dan Carmen        Clean up debug statement
05/25/2021 Jermaine Stukes   Update for APR0118366 - FY22 HR Services Segmentation
06/17/2021 Dan Carmen        Set Type for Oasis based on CS Contract Status
11/04/2021 Dan Carmen        Don't default clientStatus to I if blank
18/05/2022 Jaipal            Added SendLostNotificationCSSR Method to notify users through chatter post regarding lost client
09/02/2022 Rohit Ranjan      Broker Commission Records are set to 'Terminated' upon the Account | CS CM Contract Status field being set to Terminated
01/03/2023 Dan Carmen        Move Time Zone logic to TimeZoneHelper
03/10/2023 Rohit Ranjan      Added upsertAccountProductSensitvities
05/19/2023 Dan Carmen        Update AccountTeamMember logic
06/22/2023 Lalan Kumar       Updated Prospect-Client Type Logic for PEO Client APR0154399
07/25/2023 Lalan Kumar       APR0148096: Update the process that sets the Type field for PEO clients
12/11/2023 Dan Carmen        Remove logic for HR_Services_Partner__c

*/
public without sharing class AccountMethods {
    
    public static Boolean ACCOUNT_BEFORE_TRIGGER_EXECUTING=false;
    public static Boolean ACCOUNT_AFTER_TRIGGER_EXECUTING=false;
    
    public static Boolean CHATTER_SENT = false;
    
    // the account ids that already have their call disposition handled
    public static Set<ID> callDispositionHandledSet = new Set<Id>();
    
    public static Map<Id,User> userMap = new Map<Id,User>();

    /*BAU Changes*/
    public static Map<Id,Account> checkAcctAtmMap = new Map<Id,Account>();
    //public static Map<Id,Account> newMap=new Map<Id,Account>();
    //public static Map<Id,Account> oldMap=new Map<Id,Account>();
    /*BAU Changes*/
    
    public static void setUserMap(Set<Id> userIdSet) {
        if ((userMap == null || userMap.isEmpty()) && userIdSet != null) {
            userMap = ProspectOwnershipMethods.getNsrUserMap(userIdSet);
        } else if (userMap == null) {
            userMap = new Map<Id,User>();
        }
    } // setUserMap
    
    /** If the NSS Call Disposition changes on the Account, check if something needs to change.
*/
    public static void checkCallDisposition(Account[] callDispositionAccts, Account[] lastCallDateAccts, Set<Id> significantContactIdSet
                                            ,Set<Id> acctIdSet, Set<Id> userIdSet) {
                                                
                                                // select the contacts associated with the accounts
                                                //Map<Id,List<Contact>> contactListMap = ReferralQueries.getContactListMap(acctIdSet);
                                                List<Id> ctctIds = new List<Id>();
                                                ctctIds.addAll(significantContactIdSet);
                                                Map<Id,Contact> significantCtctMap = ReferralQueries.selectCtctMap(ctctIds);
                                                
                                                Map<Id,List<AccountTeamMember>> atmListMap = ReferralQueries.getAtmListMap(acctIdSet);
                                                
                                                // get the ownership records
                                                Map<Id,List<Prospect_Ownership__c>> acctOwnerMap = ProspectOwnershipMethods.getAcctOwnerMap(acctIdSet,true,null, null);
                                                
                                                User runningUser = UserHelper.getRunningUser();
                                                
                                                setUserMap(userIdSet);
                                                //Map<Id,User> userMap = ProspectOwnershipMethods.getNsrUserMap(userIdSet);
                                                
                                                // we need to be able to translate the record type names
                                                Map<String,Schema.RecordTypeInfo> byId = new Map<String,Schema.RecordTypeInfo>();
                                                RecordTypeHelper.getRecordTypesMap(ObjectHelper.OBJECT_ACCOUNT, byId, null);
                                                
                                                ProspectOwnershipMethods.initializeSaveObjects();
                                                
                                                for (Account acct : callDispositionAccts) {
                                                    LeadCallDisposition__c lcd = LeadMethods.findCallDisposition(acct.NSSCallDisposition__c, acct.NSSStatus__c);
                                                    Schema.RecordTypeInfo rt = byId.get(acct.RecordTypeId);
                                                    
                                                    User dialedUser = runningUser;
                                                    
                                                    if (String.isNotBlank(acct.DialedUserId__c)) {
                                                        User checkUser = userMap.get((Id)acct.DialedUserId__c);
                                                        if (checkUser != null) {
                                                            dialedUser = checkUser;
                                                        }
                                                    } // if (String
                                                    
                                                    // make sure the id isn't already in the set - otherwise we can get a recursive call
                                                    Contact significantContact = (acct.SignificantContact__c != null ? significantCtctMap.get(acct.SignificantContact__c) : null);
                                                    handleCallDispositionChange(lcd,acct,significantContact,null,atmListMap.get(acct.Id),(rt != null ? rt.getName() : null),acctOwnerMap.get(acct.Id),dialedUser);
                                                    //handleCallDispositionChange(lcd,acct,null,contactListMap.get(acct.Id),atmListMap.get(acct.Id),(rt != null ? rt.getName() : null),acctOwnerMap.get(acct.Id),dialedUser);
                                                    
                                                    if (significantContact != null && (significantContact.LastNSSCallDisposition__c != acct.LastNSSCallDisposition__c 
                                                                                       || significantContact.NSSStatus__c != acct.NSSStatus__c)) {
                                                                                           significantContact.LastNSSCallDisposition__c = acct.LastNSSCallDisposition__c;
                                                                                           significantContact.NSSStatus__c = acct.NSSStatus__c;
                                                                                           callDispositionHandledSet.add(significantContact.Id);
                                                                                           ProspectOwnershipMethods.saveCtctMap.put(significantContact.Id, significantContact);
                                                                                       } // if (significantContact
                                                    
                                                } // for (Account acct : callDispositionAccts
                                                
                                                
                                                for (Account acct : lastCallDateAccts) {
                                                    Contact significantContact = (acct.SignificantContact__c != null ? significantCtctMap.get(acct.SignificantContact__c) : null);
                                                    if (significantContact != null && acct.LatestCallTime__c != significantContact.LatestCallTime__c) {
                                                        significantContact.LatestCallTime__c = acct.LatestCallTime__c;
                                                        callDispositionHandledSet.add(significantContact.Id);
                                                        ProspectOwnershipMethods.saveCtctMap.put(significantContact.Id, significantContact);
                                                    }
                                                } // for (Account acct : lastCallDateAccts
                                                
                                                // don't save accounts since we're in the before trigger
                                                ProspectOwnershipMethods.saveAcctMap.clear();
                                                
                                                // check for contacts in the save map = remove if they're in the trigger
                                                Set<Id> keySet = ProspectOwnershipMethods.saveCtctMap.keySet();
                                                for (Id key : keySet) {
                                                    if (callDispositionHandledSet.contains(key)) {
                                                        ProspectOwnershipMethods.saveCtctMap.remove(key);
                                                    }
                                                } // for
                                                
                                                ProspectOwnershipMethods.checkForSaves();
                                                
                                            } // checkCallDisposition*/
    
    public static void handleCallDispositionChange(LeadCallDisposition__c lcd, Account acct, Contact ctct, List<Contact> ctcts, List<AccountTeamMember> atms, String recordTypeName, List<Prospect_Ownership__c> ownerList, User runningUser) {
        System.debug('handleCallDispositionChange lcd='+lcd+' acct='+(acct != null ? acct.Name : 'null'));
        String acctLog = 'handleCallDispositionChange lcd='+(lcd != null ? lcd.Name : 'null')+' ownerList='+(ownerList != null ? ownerList.size() : -1);
        // mark the account as already handled
        callDispositionHandledSet.add(acct.Id);
        
        if (acct != null && lcd != null) {
            
            // set the status on the account
            if (String.isNotBlank(lcd.NewLeadStatus__c) && acct.NSSStatus__c != lcd.NewLeadStatus__c) {
                acct.NSSStatus__c = lcd.NewLeadStatus__c;
                acctLog += '; Set NSSStatus to '+lcd.NewLeadStatus__c;
                ProspectOwnershipMethods.saveAcctMap.put(acct.Id, acct);
            }
            
            if (lcd.EndOwnership__c || String.isNotBlank(lcd.NewOwnershipStatus__c)) {
                System.debug('checkNSSLeadStatus Updating ownership record');
                acctLog += '; Updating ownership record';
                
                String nssSource = ProspectOwnershipMethods.getNSS_Source(runningUser);
                
                String[] nssTeams = ProspectOwnershipMethods.getNSSTeams(runningUser, acct.Products__c, recordTypeName, null,null, acct.NumberOfEmployees);
                String nssTeam = nssTeams[0];
                
                // check for Ownership Record
                Prospect_Ownership__c po = ProspectOwnershipMethods.checkAccountOwnership(null, false, acct, ctct, null, atms, runningUser, null, nssTeam, nssSource, ownerList);
                acctLog += '; after checkAccountOwnership has po='+(po != null);
                
                // do not do anything with ownership if it's a lockout
                if (po != null && po.Ownership_Status__c == ProspectOwnershipMethods.STAGE_LOCKOUT) {
                    po = null;
                }
                
                // if the running user doesn't own the ownership, don't end it.
                if (po != null && lcd.EndOwnership__c && lcd.EndOnlyRunningUser__c) {
                    if (runningUser != null && runningUser.Id != po.NSR_Name__c) {
                        po = null;
                    }
                } // if (lcd.EndOwnership__c &&
                
                if (po != null) {
                    if (ctct == null && ctcts != null && po.Decision_Maker__c != null) {
                        ctct = findContact(acct, ctcts, po.Decision_Maker__c, po.NSS_Team__c);
                    }
                    
                    if (lcd.EndOwnership__c) {
                        acctLog += '; ending ownership for '+po.Id;
                        ProspectOwnershipMethods.setStageExitInfo(po, acct, ctct, atms, null, lcd.EndOwnership__c, true, false);
                    } else if (String.isNotBlank(lcd.NewOwnershipStatus__c) && po.Ownership_Status__c != lcd.NewOwnershipStatus__c) {
                        acctLog += '; changing ownership from '+po.Ownership_Status__c+' to '+lcd.NewOwnershipStatus__c;
                        ProspectOwnershipMethods.addToProcessTracker(po,'handleCallDispositionChange change status from '+po.Ownership_Status__c+' to '+lcd.NewOwnershipStatus__c);
                        po.Ownership_Status__c = lcd.NewOwnershipStatus__c;
                        ProspectOwnershipMethods.setStageEntryInfo(po, acct, ctct, atms, null, true, false);
                    }
                }
                //checkOwnershipRecords(ld.OwnerId, ld.Prospect_Ownership__r, updateOwnerships, lcd);
            } // if (lcd.EndOwnership__c
            
            if (!lcd.QueueOnlyForReferral__c && String.isNotBlank(lcd.AssignToQueue__c)) {
                acct.OwnedBy__c = lcd.AssignToQueue__c;
                ProspectOwnershipMethods.saveAcctMap.put(acct.Id, acct);
            }
            
            if (lcd.SetDoNotCall__c && !acct.Do_Not_Call__c) {
                acct.Do_Not_Call__c = true;
                ProspectOwnershipMethods.saveAcctMap.put(acct.Id, acct);
            } // if (SetDoNotCall__c
        } // if (acct != null &&
        
        if (acct != null) {      
            if (String.isNotBlank(acct.NSSCallDisposition__c)) {
                // save the old value and clear the new value so the field can be triggered again.
                acct.LastNSSCallDisposition__c = acct.NSSCallDisposition__c;
                acct.NSSCallDisposition__c = null;
                ProspectOwnershipMethods.saveAcctMap.put(acct.Id, acct);
            } // if (String.isNotBlank(
        } // if (acct != null)
        StringHelper.addToProcessNotes(acct,acctLog);
    } // handleCallDispositionChange
    
    public static void checkDialed(Account[] accts) {
        // get all of the account ids
        Set<Id> acctIdSet = new Set<Id>();
        List<Id> acctIdList = new List<Id>();
        Set<Id> userIdSet = new Set<Id>();
        
        for (Account acct : accts) {
            acctIdSet.add(acct.Id);
            acctIdList.add(acct.Id);
            if (String.IsNotBlank(acct.DialedUserId__c)) {
                userIdSet.add((Id)acct.DialedUserId__c);
            }
        } // for (Account acct
        
        // right now this is only going to be executed from a trigger - use the running user
        User runningUser = UserHelper.getRunningUser();
        
        // the team of the running user
        String runningUserSource = ProspectOwnershipMethods.getNSS_Source(runningUser);
        
        Map<Id,User> userMap = ProspectOwnershipMethods.getNsrUserMap(userIdSet);
        
        // select the prospect ownership records associated with the account ids
        Map<Id,List<Prospect_Ownership__c>> acctOwnerMap = ProspectOwnershipMethods.getAcctOwnerMap(acctIdSet, true, null, null);
        
        // retrieve the contact records
        Map<Id,List<Contact>> contactListMap = ReferralQueries.getContactListMap(acctIdSet);
        Map<Id,List<AccountTeamMember>> atmListMap = ReferralQueries.getAtmListMap(acctIdSet);
        
        // we need to be able to translate the record type names
        Map<String,Schema.RecordTypeInfo> byId = new Map<String,Schema.RecordTypeInfo>();
        RecordTypeHelper.getRecordTypesMap(ObjectHelper.OBJECT_ACCOUNT, byId, null);
        
        ProspectOwnershipMethods.initializeSaveObjects();
        
        for (Account acct : accts) {
            // get any open ownership records
            List<Prospect_Ownership__c> openPOs = acctOwnerMap.get(acct.Id);
            String acctMsg = 'checkDialed openPOs='+(openPOs != null ? openPOs.size() : -1);
            
            User dialedUser = runningUser;
            String dialedSource = runningUserSource;
            String ownershipSource = null;
            
            if (String.isNotBlank(acct.DialedUserId__c)) {
                User checkUser = userMap.get((Id)acct.DialedUserId__c);
                if (checkUser != null) {
                    ownershipSource = 'DialedUserId';
                    dialedUser = checkUser;
                    dialedSource = ProspectOwnershipMethods.getNSS_Source(dialedUser);
                }
            } // if (String
            
            Schema.RecordTypeInfo rt = byId.get(acct.RecordTypeId);
            String[] nssTeams = ProspectOwnershipMethods.getNSSTeams(dialedUser, acct.Products__c, (rt != null ? rt.getName() : null), null,null, acct.NumberOfEmployees);
            String nssTeam = nssTeams[0];
            acctMsg += '; nssTeam='+nssTeam;
            
            // if there's an open ownership record use the contact attached. Otherwise if no ownership, or no contact attached, pick one.
            Id ctctId = null;
            if (openPOs != null && !openPOs.isEmpty()) {
                // take the first one where the nss team matches
                for (Prospect_Ownership__c po : openPOs) {
                    if (po.NSS_Team__c == nssTeam && po.Decision_Maker__c != null) {
                        ctctId = po.Decision_Maker__c;
                        break;
                    }
                } // for (Prospect_Ownership__c po
                
            } // if (openPOs != null
            
            Contact ctct = findContact(acct,contactListMap.get(acct.Id), ctctId, nssTeam);
            
            Prospect_Ownership__c po = ProspectOwnershipMethods.checkAccountOwnership(ProspectOwnershipMethods.STAGE_PROSPECTING, false, acct, ctct, null, atmListMap.get(acct.Id), dialedUser, null, nssTeam, dialedSource, openPOs);
            acctMsg += '; from checkAccountOwnership po='+(po != null);
            if (po != null && po.Id == null) {
                po.Source__c = ownershipSource;
            }
            
        } // for (Account acct
        
        // clear out the account map - this is executing from a before trigger so changes will be automatically saved
        ProspectOwnershipMethods.saveAcctMap.clear();
        ProspectOwnershipMethods.checkForSaves();
        
    } // checkDialed
    
    public static Contact findContact(Account acct, List<Contact> ctcts, Id ctctId, String nssTeam) {
        Contact foundCtct = null;
        if (ctcts != null && !ctcts.isEmpty()) {
            for (Contact ctct : ctcts) {
                if (ctctId != null && ctctId == ctct.Id) {
                    foundCtct = ctct;
                    break;
                } else if (ctctId == null) {
                    /*
if (acct != null && (String.isNotBlank(acct.NSSContactName__c) || String.isNotBlank(acct.NSSContactPhone__c))) {
if ((String.isNotBlank(acct.NSSContactName__c) && acct.NSSContactName__c == ctct.Name) &&
(String.isBlank(acct.NSSContactPhone__c) || (String.isNotBlank(acct.NSSContactPhone__c) && acct.NSSContactPhone__c == ctct.Phone))) {
foundCtct = ctct;
break;
}
} else {
*/
                    // what other criteria do we want to use here?
                    foundCtct = ctct;
                    break;
                    /*
}
*/
                }
            } // for (Contact
            // if none was found here, just use the first in the array
            if (foundCtct == null) {
                foundCtct = ctcts[0];
            }
        } // if (ctcts != null
        return foundCtct;
    } // findContact
    
    @future
    public static void handleAcctDateChangesFuture(Set<Id> acctHasLostDateIdSet, Set<Id> acctHasStartDateIdSet) {
        handleAcctDateChanges(acctHasLostDateIdSet, acctHasStartDateIdSet);
    }
    
    public static void handleAcctDateChanges(Set<Id> acctHasLostDateIdSet, Set<Id> acctHasStartDateIdSet) {
        checkEndOwner(acctHasStartDateIdSet, null, new Set<String>{UserHelper.SO_CORE, UserHelper.SO_MMS}, 'Payroll ownership ended due to client starting',false );
        checkEndOwner(acctHasLostDateIdSet, null, new Set<String>{UserHelper.SO_401}, 'HRS ownership ended due to client going lost',false );
    }
    
    /** Check if there are open ownership records. If open ownership is one of the types in nssTeamSet, end the ownership.
*/
    public static void checkEndOwner(Set<Id> acctIdSet, Map<Id,Id> acctIdOwnerMap, Set<String> nssTeamSet, String processNotes, Boolean onlyProspecting) {
        if (acctIdSet.isEmpty()) {
            return;
        }
        System.debug('checkEndOwner number of ids='+acctIdSet.size()+' nssTeamSet='+nssTeamSet);
        // retrieve the open ownership records.
        Map<Id,List<Prospect_Ownership__c>> acctOwnerMap = ProspectOwnershipMethods.getAcctOwnerMap(acctIdSet, true, null, null);
        
        // get the account ids to select further - the ones with ownership we are ending
        List<Id> acctIdList = new List<Id>();
        // the open ownership records
        List<Prospect_Ownership__c> ownerRecsToEnd = new List<Prospect_Ownership__c>();
        
        for (Id key : acctOwnerMap.keySet()) {
            List<Prospect_Ownership__c> acctOwners = acctOwnerMap.get(key);
            if (acctOwners != null) {
                for (Prospect_Ownership__c po : acctOwners) {
                    if (nssTeamSet.contains(po.NSS_Team__c)) {
                        // If a set of ids is passed in, only end the records with those ids
                        Id ownerIdToCheck = (acctIdOwnerMap != null ? acctIdOwnerMap.get(po.Prospect_Client__c) : null);
                        if ((ownerIdToCheck == null || (ownerIdToCheck != null && ownerIdToCheck == po.NSR_Name__c))
                            && (!onlyProspecting || (onlyProspecting && po.Ownership_Status__c == ProspectOwnershipMethods.STAGE_PROSPECTING))
                           ) {
                               ownerRecsToEnd.add(po);
                               acctIdList.add(po.Prospect_Client__c);
                           }
                    } // if (nssTeamSet.contains
                } // for (Prospect_Ownership__c
            }
        } // for (Id key
        
        System.debug('checkEndOwner ownerRecsToEnd='+ownerRecsToEnd);
        
        // if there are no accounts found here end.
        if (ownerRecsToEnd.isEmpty()) {
            return;
        }
        
        Map<Id,Account> acctMap = ReferralQueries.selectAcctMap(acctIdList);
        
        ProspectOwnershipMethods.initializeSaveObjects();
        
        // force the expiration of the HRS ownership
        for (Prospect_Ownership__c po : ownerRecsToEnd) {
            ProspectOwnershipMethods.setStageExitInfo(po, acctMap.get(po.Prospect_Client__c), null, null, null, true, true, true);
            po.ProcessNotes__c = processNotes;
            po.Ownership_Status__c = ProspectOwnershipMethods.STAGE_EXPIRED;
            System.debug('checkEndOwner po='+po);
        } // for (Prospect_Ownership__c
        
        DmlHelper.performDML2(ownerRecsToEnd, DmlHelper.DML_UPDATE, 'AccountMethods', 'checkEndOwner', 'Update Prospect Ownership', true);
        
        ProspectOwnershipMethods.checkForSaves();
        
    } // checkEndOwner
    
    /** Check if a change in the contact is grounds to re-evaluate the significant contact.
*/
    public static Boolean checkForSignificanceRecalc(Contact newC, Contact oldC) {
        Boolean recalc=false;
        if (newC != null && newC.AccountId != null && !accountIdsChecked.contains(newC.AccountId) && !accountIdsToCheckSignificantSet.contains(newC.AccountId)) {
            // always recalc on an insert or if the accountId changes
            Id oldAcctId = (oldC != null ? oldC.AccountId : null);
            recalc = (newC.AccountId != oldAcctId);
            System.debug('checkForSignificanceRecalc inside the if statement name='+newC.FirstName+' '+newC.LastName+' recalc='+recalc);
            
            if (!recalc) {
                recalc = ((LeadCompanyMethods.statusTriggersRecalc(newC.NSSStatus__c,oldC.NSSStatus__c)
                           || LeadCompanyMethods.holdOutTriggersRecalc(newC.Hold_Out_Reason__c,oldC.Hold_Out_Reason__c)
                           || (newC.DoNotCall != oldC.DoNotCall)
                           || (newC.Sales_Contact__c != oldC.Sales_Contact__c)
                           || (newC.No_Longer_With_Company__c != oldC.No_Longer_With_Company__c) ));
            }
            
            if (recalc) {
                accountIdsToCheckSignificantSet.add(newC.AccountId);
                if (oldAcctId != null) {
                    accountIdsToCheckSignificantSet.add(oldAcctId);
                }
            }
        } // if (oldC != null &&
        System.debug('checkForSignificanceRecalc name='+newC.FirstName+' '+newC.LastName+' recalc='+recalc);
        return recalc;
    } // checkForSignificanceRecalc
    
    public static Boolean CALCULATE_SIGNIFICANCE=true;
    
    // so we only check an id once.
    public static Set<Id> accountIdsChecked = new Set<Id>();
    
    public static Set<Id> accountIdsToCheckSignificantSet = new Set<Id>();
    
    public static map<id,id> opptyPrimaryContact = new map<id,id>();                    
    
    public static void checkSignificantContact() {
        System.debug('accountIdsToCheckSignificantSet = '+accountIdsToCheckSignificantSet);
        if (CALCULATE_SIGNIFICANCE && !accountIdsToCheckSignificantSet.isEmpty()) {
            if (System.isFuture() || System.isBatch() || Test.isRunningTest()) {
                setSignificantContact(accountIdsToCheckSignificantSet);
            } else {
                setSignificantContactFuture(accountIdsToCheckSignificantSet);
            }
            accountIdsToCheckSignificantSet.clear();
        } // if (CALCULATE_SIGNIFICANCE
    } // checkLeadCompany
    
    @future
    public static void setSignificantContactFuture(Set<Id> accountIdSet) {
        setSignificantContact(accountIdSet);
    }
    
    public static void setSignificantContact(Set<Id> accountIdSet) {
        LeadCompanyMethods.setQueryParameters();
        
        Account[] accounts = [Select Id, Name
                              ,EvaluateSignificant__c
                              ,SignificantContact__c
                              ,Do_Not_Call__c
                              ,(Select Id, Name, accountid
                                ,Decision_Maker__c,Business_Owner__c ,Title
                                From Contacts
                                Where Sales_Contact__c=true
                                and DoNotCall=false
                                and Hold_Out_Reason__c not in :LeadCompanyMethods.holdOutReasonSet
                                and NSSStatus__c not in :LeadCompanyMethods.statusSet
                                and No_Longer_With_Company__c=false
                                order by Decision_Maker__c desc,Business_Owner__c desc,Title desc NULLS LAST, LastModifiedDate desc limit 10)
                              ,(Select Id, Decision_Maker__c
                                From Prospect_Ownership__r
                                Where EndDate__c = null
                                order by StartDate__c
                               ),
                              (Select id from opportunities where probability > 90 order by createddate desc limit 1)
                              From Account
                              Where Id in :accountIdSet];
        
        System.debug('setSignificantContact number of accounts='+accounts.size()+' accountIdSet='+accountIdSet);
        Account[] acctsToUpdate = new Account[]{};
            set<id> Opptyids = new set<id>();
        for (Account acct : accounts) {
            if(acct.opportunities.size() > 0)
                Opptyids.add(acct.opportunities[0].id);
        }
        if(Opptyids != null)
        {
            for(OpportunityContactRole ocr : [select id,opportunity.accountid,ContactId from OpportunityContactRole where opportunityid in : Opptyids and isPrimary = true])
            {
                System.debug('ocr ='+ocr);
                opptyPrimaryContact.put(ocr.opportunity.accountid,ocr.ContactId);
            }
        }
        for (Account acct : accounts) {
            accountIdsChecked.add(acct.Id);
            
            if (significantChanged(acct)) {
                acctsToUpdate.add(acct);
            }
        } // for (Account acct
        
        System.debug('setSignificantContact number of acctsToUpdate='+acctsToUpdate.size());
        //ZipCheckOwner.SKIP_TRIGGERS=true;
        DmlHelper.performDML2(acctsToUpdate, DmlHelper.DML_UPDATE, 'AccountMethods', 'setSignificantContact', 'Updating Significant Contact', true);
        
    } // setSignificantContact
    
    public static Boolean significantChanged(Account acct) {
        Boolean changed = acct.EvaluateSignificant__c;
        // collect all of the contact ids that have prospect ownership
        Set<Id> ctctIdSet = new Set<Id>();
        if (acct.Prospect_Ownership__r != null) {
            for (Prospect_Ownership__c po : acct.Prospect_Ownership__r) {
                if (po.Decision_Maker__c != null) {
                    ctctIdSet.add(po.Decision_Maker__c);
                }
            } // for (Prospect_Ownership__c po
        } // if (acct.Prospect_Ownership__r
        
        Integer nbrCtcts = (acct.Contacts != null ? acct.Contacts.size() : 0);
        System.debug('significantChanged acct='+acct.Name+' nbrCtcts='+nbrCtcts+' ctctIdSet='+ctctIdSet);
        
        Id significantContactId = null;
        if (nbrCtcts > 0) {
            // if only 1 contact default to the first
            set<contact> OwnerContactid = new set<contact>();
            Contact significant = ((nbrCtcts == 1) ? acct.Contacts[0] : null);
            System.debug('significantChanged acct='+acct.Name+' significant='+significant);
            if (acct.Contacts.size() > 1) {
                Boolean openOwnershipFound = false;
                
                for (Contact ctct : acct.Contacts) {
                    System.debug('ctct ='+ctct+' significant='+significant);
                    if(ctct.Id == opptyPrimaryContact.get(acct.Id))
                    {
                        significant = ctct;
                        break;
                    }
                    else {
                        Boolean match = (significant == null);
                        System.debug('significantChanged acct='+ctct.Name+' first step in for loop match='+match);
                        if (!match && !openOwnershipFound) {
                            if (ctctIdSet.contains(ctct.Id)) {
                                match = true;
                            }
                        }
                        if (match) {
                            significant = ctct;
                            openOwnershipFound = (ctctIdSet.contains(ctct.Id));
                            System.debug('significantChanged acct='+ctct.Name+' in match check openOwnershipFound='+openOwnershipFound);
                            if (openOwnershipFound) {
                                // we don't need to continue if we find open ownership
                                break;
                            }
                        } // if (match
                        if(!ctct.Business_Owner__c && !ctct.Decision_Maker__c && ctct.Title != null && ctct.Title.contains('owner'))
                            OwnerContactid.add(ctct); 
                    }
                } // for (Contact ctct
                
            } // if (acct.Contacts.size() > 1
            if(significant != null && !significant.Decision_Maker__c && !significant.Business_Owner__c && OwnerContactid.size()>0 && opptyPrimaryContact.get(significant.AccountId) != significant.Id)
            {
                significant = new List<contact> (OwnerContactid).get(0);   //OwnerContactid[0];
            }
            significantContactId = (significant != null ? significant.Id : null);
            System.debug('significantChanged inside if acct='+acct.Name+' significantContactId='+significantContactId+' significant='+significant);
        } // if (acct.Contacts
        
        System.debug('significantChanged acct='+acct.Name+' significantContactId='+significantContactId+' acct.SignificantContact__c='+acct.SignificantContact__c);
        if (acct.SignificantContact__c != significantContactId) {
            acct.SignificantContact__c = significantContactId;
            changed = true;
        }
        
        if (changed) {
            acct.EvaluateSignificant__c = false;
        }
        
        System.debug('significantChanged acct='+acct.Name+' changed='+changed);
        return changed;
    } // significantChanged
    
    
                public static Account[] hroiClientsToCheck = new Account[]{};
                    
                    public static void accountBeforeChecks(Account newA, Account oldA) {
                        UserHelper.setRunningUserAttributes();
                        // Add a check here to verify the existence of a PEO onboarding checklist
                        if (newA != null) {
                            checkZipFields(newA, oldA); // ln 874
                            if (newA.AccountNumber !=null && newA.AccountNumber != newA.PRN_Invitation_Id__c) {
                                if(newA.AccountNumber.length() > 18){
                                    ErrorLog.logError('AccountMethods', 'accountBeforeCheck', 'PRN Invitation Id too long', (newA.Id!=null?newA.Id:newA.Name), 'PRN Invitation Id: '+newA.AccountNumber, newA, true);
                                    newA.PRN_Invitation_Id__c = newA.AccountNumber.left(18); 
                                }
                                else{
                                    newA.PRN_Invitation_Id__c = newA.AccountNumber; 
                                }
                                
                                
                            }//if
                            
                            if(newA.AccountNumber == null){
                                newA.PRN_Invitation_Id__c = newA.Id;  
                            }//if
                            
                            if (oldA != null && newA.DialedLastUsed__c != null && (newA.Dialed__c || String.isNotBlank(newA.NSSCallDisposition__c))) {
                                Boolean dialedTimeOkay = Utilities.checkDialedTimeOkay(newA.DialedLastUsed__c);
                                // if it was dialed recently do not let the checkbox be set again
                                if (!dialedTimeOkay && newA.Dialed__c) {
                                    newA.Dialed__c = false;
                                }
                                
                                // clear out call disposition if within the time period and is the same as the previous value
                                if (!dialedTimeOkay && String.isNotBlank(newA.NSSCallDisposition__c) && newA.NSSCallDisposition__c == newA.LastNSSCallDisposition__c) {
                                    newA.NSSCallDisposition__c = null;
                                }
                                
                                
                            } // if (oldA != null && newA.DialedLastUsed__c != null
                            
                            // is this an update
                            if (oldA != null) {
                                // ensure that AccountNumber is upper case if there's not a bis id
                                // this fixes people entering lower case letters and the values not matching.
                                if (newA.Bis_ID__c == null && String.isNotBlank(newA.AccountNumber)) {
                                    newA.AccountNumber = newA.AccountNumber.toUpperCase();
                                }
                                if (UserHelper.runningUserIsSfdcData || UserHelper.runningUserIsLeadLoader) {
                                    checkUserOwnedShipping(newA, oldA);
                                }
                            } // if (oldA != null
                            
                            // only perform the check on insert
                            if (oldA == null && UserHelper.runningUserIsSfdcData) {
                                // check to make sure the current/prior method is correct.
                                newA.Current_Prior_Method__c = OpptyCheckFields.checkPrimaryComp(newA.Current_Prior_Method__c, newA.Local_Competitors__c);
                                
                            } // if (oldA == null
                            Id mmsRTID = RecordTypeHelper.getRecordType(Label.RT_MMS_Account,'Account').getRecordTypeId();
                            Id smbRTId = RecordTypeHelper.getRecordType(Label.RT_Core_Account,'Account').getRecordTypeId();
                            String[] holdoutReasons = new String[]{Label.Account_Partnership_Holdout_Reason, Label.Account_HR_Partnership_Holdout_Reason};
                            // if the client start date is null and the first run date is not null, populate it.
                            if(newA.Bis_Id__c != null && newA.Client_Start_Date__c == null && newA.First_Run_Date__c != null && newA.Lost_Date__c==null && (oldA == null || oldA.First_Run_Date__c != newA.First_Run_Date__c)) {
                                //System.debug('accountBeforeChecks acct='+newA.Name+' Client_Start_Date__c='+newA.First_Run_Date__c);
                                newA.Client_Start_Date__c = newA.First_Run_Date__c;
                            }
                            else if(oldA!=null && newA.Lost_Date__c != null && oldA.Lost_Date__c == null){
                                newA.Client_Start_Date__c = null;
                                if(newA.CSSR_Segment__c){
                                    newA.CSSR_Segment__c=false;
                                    newA.Use_Zip_Assignment_Rules__c=true;
                                }
                            }
                            
                            if((oldA==null||(oldA!=null && oldA.Type != newA.Type)) && (newA.Type == Label.AccountTypeHROi || newA.Type == Label.AccountTypeHROiLost)){
                                hroiClientsToCheck.add(newA);
                            }
                            
                            //Check that the Data Review field is changed to anything with 'Completed' or the Profiled checkbox gets checked
                            //Set the Protected Date field to date + 12 months
                            if((oldA != null && ((newA.Data_Review__c != null && newA.Data_Review__c.startsWith('Complete') && (oldA.Data_Review__c == null || (oldA.Data_Review__c != null && !oldA.Data_Review__c.startsWith('Complete')))) || (newA.Profiled__c && !oldA.Profiled__c)))
                               || (oldA == null && ((newA.Data_Review__c != null && newA.Data_Review__c.startsWith('Complete')) || newA.Profiled__c))) {
                                   newA.Protected_Date__c = Date.today().addMonths(12); //This may get changed to use a custom setting instead of a hard 12
                               }
                            
                            //newA.Data_Review__c.contains('Completed') || Profiled__c) && (oldA == null || (oldA != null && !oldA.Data_Review__c.)))
                            
                            //Permanent Holdout set for Referral Network program - Amplifinity
                            //amp_dev__Amp_Partner__c is not the correct field.  this will need to be updated with the actual 
                            //lookup field from AMP once they have their most recent code sent to us connecting advocate to account
                            system.debug('***CLM*** AccountMethods checking if Advocate is populated on newA.Amplifinity_Advocate__c: '+newA.Amplifinity_Advocate__c+' newA.Hold_Out__c: '+newA.Hold_Out__c);
                            if(newA.Amplifinity_Advocate__c != null && oldA.Amplifinity_Advocate__c == null) {
                                system.debug('***CLM*** newA.ownerId: '+newA.ownerId+' newA.Hold_Out__c: '+newA.Hold_Out__c);
                                Id[] userIds = new Id[]{newA.ownerId};
                                    //newA.Hold_Out__c = true;
                                    //newA.Permanent_Hold_Out_Description__c = 'Referral Network Advocate';
                                    //system.debug('***CLM*** newA.Hold_Out__c: '+newA.Hold_Out__c+' newA.Permanent_Hold_Out_Description__c: '+newA.Permanent_Hold_Out_Description__c);
                                    //newA.SignificantContact__r.Do_Not_Sync__c = False;
                                    String postText = ' This account has been invited to join the Paychex Referral Network program. The next step is to make sure the client completes the registration if they have not already! ';
                                system.debug('***CLM*** newA.id: '+newA.id+' userIds: '+userIds+' postText: '+postText);
                                //ChatterMentionPost.createChatterMentionPost(newA.id, userIds, new String[]{postText}, true, true);
                            }
                        } // if (newA != null
                        
                    } // accountBeforeChecks
    
    public static void processBeforeActions() {
    } // processBeforeActions
    
    public static Set<Id> acctHasLostDateIdSet = new Set<Id>();
    
    public static Set<Id> acctHasStartDateIdSet = new Set<Id>();
    
    public static List<Id> acctSigContactSet = new List<Id>();
    public static Map<Id, Account> acctCssrSegment = new Map<Id, Account>();
    public static Map<Id, Account> acctmiEdgeUpdates = new Map<Id, Account>();
    public static Set<Id> activeAdvocates = new Set<Id>();   
    public static Set<Id> inactiveAdvocates = new Set<Id>();   
    public static list <amp_dev__Amp_Advocate__c> advocatesToUpdate = new list<amp_dev__Amp_Advocate__c>(); 
    public static Set<Id> updatebrokerCommission = new Set<Id>();
    public static Set<Id> crbAccIds = new Set<Id>();
    
    public static void accountAfterChecks(Account newA, Account oldA) {
        UserHelper.setRunningUserAttributes();
        /*BAU Changes*/
        //if (newA.Relationship_Manager_PEO_Client_Advocate__c!=null && oldA != null && newA.Relationship_Manager_PEO_Client_Advocate__c!=oldA.Relationship_Manager_PEO_Client_Advocate__c){
        if ((oldA == null && newA.Relationship_Manager_PEO_Client_Advocate__c != null)
            || (oldA != null && newA.Relationship_Manager_PEO_Client_Advocate__c!=oldA.Relationship_Manager_PEO_Client_Advocate__c)) {
            checkAcctAtmMap.put(newA.Id, newA);
            //newMap.put(newA.id,newA);
            //oldMap.put(oldA.id,oldA);
        }
        /*BAU Changes*/
        if (UserHelper.runningUserIsSfdcData && newA != null && oldA != null) {
            if ((newA.AssignedToInboundNSR__c || newA.AssignedToOutboundNSR__c) && newA.Bis_ID__c != null) {
                if (olda.Lost_Date__c == null && newA.Lost_Date__c != null ) {
                    acctHasLostDateIdSet.add(newA.Id);
                } else if (newA.First_Run_Date__c != null && newA.First_Run_Date__c != olda.First_Run_Date__c) {
                    acctHasStartDateIdSet.add(newA.Id);
                }
            } 
            if (newA.Current_Owner_Id__c != oldA.Current_Owner_Id__c && newA.CSSR_Segment__c == true && newA.Client_Start_Date__c < (Date.today() - 365)){
                acctCssrSegment.put(newA.Id, newA);    
            } 
            
        } // if (newA != null
        //system.debug('***CLM*** accountAfterChecks newA.Amplifinity_Advocate__c:'+newA.Amplifinity_Advocate__c+' oldA.Amplifinity_Advocate__c: '+oldA.Amplifinity_Advocate__c);
        // system.debug('***CLM*** accountAfterChecks newA.SignificantContact__c:'+newA.SignificantContact__c+' oldA.SignificantContact__c: '+oldA.SignificantContact__c);
        /*jc combined with below
if((newA.Amplifinity_Advocate__c != null && (oldA == null || (newA.Amplifinity_Advocate__c != oldA.Amplifinity_Advocate__c))) 
|| (newA.SignificantContact__c != null && (oldA == null || (newA.SignificantContact__c != oldA.SignificantContact__c)))) {
acctSigContactSet.add(newA.SignificantContact__c);
}//if        */
        
        if (oldA != null && oldA.miEdge_crm__Sync_Date__c != newA.miedge_crm__Sync_Date__c && newA.miedge_crm__Master_MSID__c != null) {
            acctmiEdgeUpdates.put(newA.Id, newA);
        }
        
        //JC adding check for acct type changing. combining Amplifnity advocate check 
        if(newA.Amplifinity_Advocate__c != null){
            if(oldA == null || (newA.Amplifinity_Advocate__c != oldA.Amplifinity_Advocate__c)
               || (newA.SignificantContact__c != null && (oldA == null || (newA.SignificantContact__c != oldA.SignificantContact__c)))) {
                   acctSigContactSet.add(newA.SignificantContact__c);
               } //if  
            if(newA.Type =='Lost Client' && (oldA ==null ||newA.Type != oldA.Type )){
                inactiveAdvocates.add(newA.Amplifinity_Advocate__c);   
            }//If 
            
            if(newA.Type !='Lost Client' && (oldA ==null || (newA.type!=oldA.type && oldA.Type =='Lost Client'))) {
                activeAdvocates.add(newA.Amplifinity_Advocate__c);  
            } //if
            
        }// if((newA.Amplifinity_Advocate__c != null  
        
        // Rohit Ranjan code starts
        If ( oldA != null && newA.CSCMContractStatus__c=='Terminated' && oldA.CSCMContractStatus__c !='Terminated'){	
			updatebrokerCommission.add(newA.id);
        }
        
        //Rohit
       if((oldA==null && String.isNotBlank(newA.Restricted_Industry__c) && newA.Restricted_Industry__c == 'CRB' )||(oldA!=null && String.isNotBlank(newA.Restricted_Industry__c) && newA.Restricted_Industry__c != oldA.Restricted_Industry__c && newA.Restricted_Industry__c == 'CRB')){
                crbAccIds.add(newA.Id);
            
       }
    } // accountAfterChecks
    
    public static void checkForAccountAfterMethods() {
        System.debug('checkForAccountAfterMethods checkAcctAtmMap='+checkAcctAtmMap.size());
        /*BAU Changes*/
        if(!checkAcctAtmMap.isEmpty()){
            createAccountTeamMember(checkAcctAtmMap);
        }
        /*BAU Changes*/
        if (!acctHasLostDateIdSet.isEmpty() || !acctHasStartDateIdSet.isEmpty()) {
            if (System.isFuture() || System.isBatch() || Test.isRunningTest()) {
                handleAcctDateChanges(acctHasLostDateIdSet, acctHasStartDateIdSet);
            } else {
                handleAcctDateChangesFuture(acctHasLostDateIdSet, acctHasStartDateIdSet);
            }
        } // if (!acctHasLostDateIdSet
        if(!acctSigContactSet.isEmpty()){
            updateSignificantContact(acctSigContactSet);
        } 
        checkSignificantContact();
        if (!acctCssrSegment.isEmpty()) {
            AccountMethods.sendCssrSegmentChatterNotifications(acctCssrSegment);
            acctCssrSegment.clear();
        }
        if(!acctmiEdgeUpdates.isEmpty()){
            AccountMethods.updateAccountFieldsMiEdge(acctmiEdgeUpdates);
            //acctmiEdgeUpdates.clear();
        }
        if (!inactiveAdvocates.isEmpty() || !activeAdvocates.isEmpty()) {
            checkAdvocateStatus(activeAdvocates, inactiveAdvocates);
        }
        
        // Rohit Ranjan code starts
        
        List<Broker_Commission__c> bcList = new List<Broker_Commission__c>();	
		if(!updatebrokerCommission.isEmpty()){	
		List<Referral_Account__c> refAccList = [SELECT Id , (SELECT Id, status__c FROM Broker_Commissions__r ) 
                                                FROM Referral_Account__c WHERE Account__c IN :updatebrokerCommission];	
		for(Referral_Account__c ra : refAccList){	
		for(Broker_Commission__c bc :ra.Broker_Commissions__r){	
		bc.Status__c= 'Terminated';	
		bcList.add(bc);	
	}	
	}	
		if(bcList.size() >0){	
		DmlHelper.performDML2(bcList, DmlHelper.DML_UPDATE, 'AccountMethods', 'checkForAccountAfterMethods', 'Update Broker Commission', true);	
	}	
	}
     
     // Rohit 
     if(!crbAccIds.isEmpty()){
         upsertAccountProductSensitvities(crbAccIds);
     }
        
        
    } // checkForAccountAfterMethods
    
    /** Evaluate the owner zip code field.
*/
    public static void updateSignificantContact(List<Id> contactIdList){
        List<Contact> contactList = [Select Id, Do_Not_Sync__c from Contact where Id in:contactIdList and Do_Not_Sync__c = true];
        for(Contact ct : contactList){
            ct.Do_Not_Sync__c = false;
        }
        DmlHelper.performDML2(contactList, DmlHelper.DML_UPDATE, 'AccountMethods', 'updateSignificantContact', 'Update Do Not Sync on Amplifinity Significant Contacts', true);
    }
    
    public static void checkAdvocateStatus(Set<Id> activeIdSet, Set<Id> inactiveIdSet) {
        Id[] advocateIds = new Id[]{};
            advocateIds.addAll(activeIdSet);
        advocateIds.addAll(inactiveIdSet);
        if (!advocateIds.isEmpty()) {
            amp_dev__Amp_Advocate__c[] updateAdvocates = new amp_dev__Amp_Advocate__c[]{};
                amp_dev__Amp_Advocate__c[] advocates = [Select Id, amp_dev__Status__c from amp_dev__Amp_Advocate__c where Id in :advocateIds];
            for (amp_dev__Amp_Advocate__c advocate : advocates) {
                if (activeIdSet.contains(advocate.Id)) {
                    if (advocate.amp_dev__Status__c != 'Active') {
                        advocate.amp_dev__Status__c = 'Active';
                        updateAdvocates.add(advocate);
                    }
                } else if (inactiveIdSet.contains(advocate.Id)) {
                    if (advocate.amp_dev__Status__c != 'Suspended') {
                        advocate.amp_dev__Status__c = 'Suspended';
                        updateAdvocates.add(advocate);
                    }
                }
            } // for (amp_dev__Amp_Advocate__c advocate
            
            DmlHelper.performDML2(updateAdvocates, DmlHelper.DML_UPDATE, 'AccountMethods', 'checkAdvocateStatus', 'Update status on advocates', true);
        } // if (!advocateIds.isEmpty
    } // checkAdvocateStatus
    
    public static Boolean checkZipFields(Account newA, Account oldA) {
        UserHelper.setRunningUserAttributes();
        // check for the '88888' scenario - do not allow 88888 to overwrite existing zip code
        if (UserHelper.runningUserIsLeadLoader && oldA != null) {
            if (newA.ShippingPostalCode == '88888' && String.isNotBlank(oldA.ShippingPostalCode)) {
                newA.ShippingPostalCode = oldA.ShippingPostalCode;
            }
            if (newA.BillingPostalCode == '88888' && String.isNotBlank(oldA.BillingPostalCode)) {
                newA.BillingPostalCode = oldA.BillingPostalCode;
            }
        } // if (oldA != null
        
        String newOwnerZip = 'nozip';
        // populate the owner zip code
        if (String.isNotBlank(newA.ShippingPostalCode) && newA.ShippingPostalCode.length() >= 5) {
            newOwnerZip = newA.ShippingPostalCode.left(5);
        } else if (String.isNotBlank(newA.BillingPostalCode) && newA.BillingPostalCode.length() >= 5) {
            newOwnerZip = newA.BillingPostalCode.left(5);
        }
        if (newOwnerZip != 'nozip' && newA.Owner_Zip_Code__c != newOwnerZip) {
            newA.Owner_Zip_Code__c = newOwnerZip;
        } else if (newOwnerZip == 'nozip') {
            newA.Owner_Zip_Code__c = null;
        }
        return true;
    } // checkZipFields
    
    public static Boolean checkUserOwnedShipping(Account newA, Account oldA) {
        if (newA.User_Owned_Shipping_Address__c == true) {       
            // if the address is changed, change it back.
            if (newA.ShippingStreet != oldA.ShippingStreet) {
                newA.ShippingStreet = oldA.ShippingStreet;
            }
            if (newA.ShippingCity != oldA.ShippingCity) {
                newA.ShippingCity = oldA.ShippingCity;
            }
            if (newA.ShippingState != oldA.ShippingState) {
                newA.ShippingState = oldA.ShippingState;
            }
            if (newA.ShippingPostalCode != oldA.ShippingPostalCode) {
                newA.ShippingPostalCode = oldA.ShippingPostalCode;
            }
            if (newA.ShippingCountry != oldA.ShippingCountry) {
                newA.ShippingCountry = oldA.ShippingCountry;
            }
        } // if (newa.Hold_Out__c
        return true;
    } // checkUserOwnedShipping
    
    public static Set<String> CLIENT_TYPE_PLAN_CODE_SET = ReferenceHRGController.PREMIER_PLAN_CODE_SET;
    /*
public static Set<Id> acctIdForClientTypeSet = new Set<Id>();

public static void checkAssetForClientType(Asset asst, Asset oldAsst) {
if (String.isNotBlank(asst.Paychex_Asset_Id__c) && asst.AccountId != null
&& (oldAsst == null || (oldAsst != null && String.isNotBlank(asst.Product_Plan_Code__c)
&& (asst.Plan_Cancel_Date__c != oldAsst.Plan_Cancel_Date__c 
|| asst.Product_Plan_Code__c != oldAsst.Product_Plan_Code__c))
)) {
acctIdForClientTypeSet.add(asst.AccountId);
} // if (String.isNotBlank
} // checkAssetForClientType


public static void processFromAssetTrigger(Map<Id,Account> updateAccountMap) {
if (!acctIdForClientTypeSet.isEmpty()) {
Account[] accts = [SELECT Id,Name,Client_Status__c,HR_Generalist__c,HR_Manager__c,Payroll_Branch_Nbr__c,Type,Lost_Date__c 
FROM Account 
WHERE Id in :acctIdForClientTypeSet];
setAccountType(accts, updateAccountMap);
}
} // processFromAssetTrigger
*/
    
    //gets called from Account Before and Asset After Triggers.  callUpdate flag is so we can call an update, true if from After Trigger, false if from Before Trigger.
    public static void setAccountType(List<Account> accts, Boolean callUpdate){
        setAccountType(accts,(Map<Id,Account>)null);
    }
    
    public static Boolean FILTER_PRODS = (Label.AccountMethods_FilterProds == 'Y');
    
    public static void setAccountType(List<Account> accts, Map<Id,Account> updateAccountMap){
        
        //only search for the products we'll use to determine the type
        Map<Id,Set<String>> planCodeSetByAcctId = new Map<Id,Set<String>>();
        Map<Id,Set<String>> hrsProdsByAcctId = new Map<Id,Set<String>>();
        
        // to only loop through the assets once
        for (Asset asst : [SELECT Id,Plan_Cancel_Date__c,Product_Plan_Code__c,AccountId,Product_End_Date__c, Paychex_Asset_Id__c
                           ,Account.Bis_ID__c, Account.Client_Status__c
                           FROM Asset 
                           WHERE AccountId in :accts AND (Paychex_Asset_Id__c != null OR Product_Plan_Code__c LIKE 'HROI%' OR Product_Plan_Code__c LIKE 'Oasis%') 
                           AND Plan_Cancel_Date__c = null]) {
                               system.debug('AccountMethods setAccountType asst: '+asst);
                               if (String.isNotBlank(asst.Product_Plan_Code__c)) {
                                   Set<String> activeProductCodeSet = (planCodeSetByAcctId.containsKey(asst.AccountId) ? planCodeSetByAcctId.get(asst.AccountId) : new Set<String>());
                                   
                                   
                                   planCodeSetByAcctId.put(asst.AccountId, activeProductCodeSet);
                                   
                                   //don't need specifics, if any hroi products are active they're an hroi client.
                                   if (asst.Product_Plan_Code__c.startsWith('HROI')) {
                                       activeProductCodeSet.add('HROI');
                                   } else if (asst.Product_Plan_Code__c.startsWith('Oasis')) {
                                       activeProductCodeSet.add('Oasis');
                                   } else {
                                       String bisIdStr = (asst.Account.Bis_ID__c != null ? String.valueOf(asst.Account.Bis_ID__c)+'-' : 'None');
                                       String clientStatus = (String.isNotBlank(asst.Account.Client_Status__c) ? asst.Account.Client_Status__c : '');
                                       // make sure if this is from the feed that the product is part of this account
                                       // (other products might be in an account list due to a merge)
                                       if (String.isBlank(asst.Paychex_Asset_Id__c)) {
                                           activeProductCodeSet.add(asst.Product_Plan_Code__c);
                                       } else if (asst.Paychex_Asset_Id__c.startsWith(bisIdStr)) {
                                           Boolean isPayrollActive = (asst.Account.Bis_ID__c != null && clientStatus == 'A');
                                           String caKey = asst.Account.Bis_ID__c+'-CA-';
                                           Boolean isCaProd = (asst.Paychex_Asset_Id__c.startsWith(caKey));
                                           String mmsKey = asst.Account.Bis_ID__c+'-MMS-';
                                           Boolean isMmsProd = (asst.Paychex_Asset_Id__c.startsWith(mmsKey));
                                           // if payroll is an active product, we want to include all product codes. 
                                           // if payroll is not active, we only want to include the product codes from HRIS (not CA - titan tables and non MMS)
                                           if (!FILTER_PRODS || isPayrollActive || (!isCaProd && !isMmsProd)) {
                                               activeProductCodeSet.add(asst.Product_Plan_Code__c);
                                           } // if (isPayrollActive
                                       }
                                   } // if (asst.Product_Plan_Code__c.startsWith('HROI')
                               } // if (String.isNotBlank(asst.Product_Plan_Code__c
                               
                           } // for (Asset asst
        setAccountType(accts,planCodeSetByAcctId,updateAccountMap);
    } // setAccountType
    
    public static void setAccountType(List<Account> accts, Map<Id,Set<String>> planCodeSetByAcctId, Map<Id,Account> updateAccountMap){
        for (Account acct:accts) {
            checkAcctType(acct, planCodeSetByAcctId.get(acct.Id), updateAccountMap);
        } //for (Account acct
        
    }//setAccountType
    
    // the branch numbers that could be used by clients in client space but aren't actually oasis
    public static String[] NonOasisBranchNumbers = new String[]{'741'};
    
    public static void checkAcctType(Account acct, Set<String> activeProductCodeSet, Map<Id,Account> updateAccountMap) {
        if (activeProductCodeSet == null) {
            activeProductCodeSet = new Set<String>();
        }
        Date todayDate = system.today();
        String originalType = acct.Type;
        // default type
        System.debug('setAccountType acct.Client_Status__c='+acct.Client_Status__c+' activeProductCodeSet='+activeProductCodeSet);
        //Prospect
        
        String clientStatus = (String.isNotBlank(acct.Client_Status__c) ? acct.Client_Status__c : '');
        Integer prBranchNbr = (acct.Payroll_Branch_Nbr__c != null ? Integer.valueOf(acct.Payroll_Branch_Nbr__c) : 0);
        String branchNbrStr = String.valueOf(prBranchNbr);
        Boolean oasisClient = (acct.CSCMContractStatus__c == 'Client' && !NonOasisBranchNumbers.contains(branchNbrStr));
        System.debug('checkAcctType in the Oasis Client Section');
        System.debug('acct.CSCMContractStatus__c' + acct.CSCMContractStatus__c);
        // default values
        String newType = (clientStatus == 'A' ? 'FLEX Client' : 'Prospect');
        
        if(clientStatus == 'P'){
            newType = 'Prospect';
        }
        //Sample
        else if(clientStatus == 'S'){
            newType = 'Sample';
        }
        //Paychex
        else if(clientStatus == 'D'){
            newType = 'Paychex';
        }          
        //HROi Client
        else if(activeProductCodeSet.contains('HROI')){
            newType = 'HROi Client';
        }
         //PEO Client : APR0148096: Update the process that sets the Type field for PEO clients
         else if(acct.CSCMContractStatus__c == 'Client' && acct.Other_PEO_Client_Number__c!= null && acct.Other_PEO_Client_Number__c.startsWith('0741')){
            newType = 'PEO Client';
        }
        //HROi Client
        else if(oasisClient || activeProductCodeSet.contains('Oasis')){
            newType = 'Oasis Client';
        }
        //Lost Client
        else if ((clientStatus == 'A' && acct.Lost_Date__c != null && activeProductCodeSet.isEmpty())
                 ||(clientStatus == 'I' && activeProductCodeSet.isEmpty()))
        {
            newType=Label.AccountTypeLost;
        }
        //HR Solutions Preview Client
        else if((activeProductCodeSet.contains('793')||activeProductCodeSet.contains('884')) && prBranchNbr >= 400 && prBranchNbr <= 499){
            newType = 'HR Solutions Preview Client';
        }           
        //PEO Client
        else if(prBranchNbr==741 || (activeProductCodeSet.contains('1029') && (acct.HR_Generalist__c != null || acct.HR_Manager__c!=null))){
            newType = 'PEO Client';
        }
        //HR Solutions Advantage Client
        else if(activeProductCodeSet.contains('1005')){
            newType = 'HR Solutions Advantage Client';
        }
        //HR Solutions NPR Client
        else if(activeProductCodeSet.contains('1010')){
            newType = 'HR Solutions NPR Client';
        }
        //HR Solutions FLEX Client
        else if(activeProductCodeSet.contains('793')||activeProductCodeSet.contains('884')){
            newType = 'HR Solutions FLEX Client';
        }
        //HRS Client Only
        else if((clientStatus == 'A' && acct.Lost_Date__c != null && !activeProductCodeSet.isEmpty())
                ||(clientStatus == 'I' && !activeProductCodeSet.isEmpty()))
        {
            newType = Label.AccountTypeHRSOnly;
        }
        //Advantage Client
        else if (prBranchNbr>=600 && prBranchNbr <=699){
            newType = 'Advantage Client';
        }
        //Preview Client
        else if(prBranchNbr >= 400 && prBranchNbr <= 499){
            newType = 'Preview Client';
        }
        system.debug('setAccountType Finished Evaluating Prospect-Client Type for Account: '+acct.Name+' New Type: '+newType);
        
        if (originalType != newType) {
            // if changes to a client, remove the Oasis hold out information (the zip segment will not set this owner field)
            //Commented by Srujan - APR0162803 - SFDC-26235
            /*if (String.isNotBlank(originalType) && originalType.contains('Prospect') && newType.contains('Client')) {
                acct.OasisPEOHoldOut__c = false;
                acct.OasisPEOHoldOutExpiration__c = null;
                acct.OasisPEOHoldOutReason__c = null;
                if (newType != 'Oasis Client' && acct.OasisPEOAccountOwner__c != null) {
                    // if changes to a client, but not an Oasis Client, clear out the OasisPEOAccountOwner__c owner field
                    acct.OasisPEOAccountOwner__c = null;
                }
            }*/
            System.debug('setAccountType setting new type');
            if (updateAccountMap != null) {
                Account updateAcct = updateAccountMap.get(acct.Id);
                if (updateAcct == null) {
                    updateAcct = new Account(Id=acct.Id, Type=newType);
                    updateAccountMap.put(updateAcct.Id, updateAcct);
                }
                acct = updateAcct;
            } // if (updateAccountMap != null
            acct.Type = newType;
            // if it changes to HR Solutions   
            if ((newType.contains('HR Solutions') || newType == 'PEO Client')  
                && (String.isBlank(originalType) || (!originalType.contains('HR Solutions') && originalType != 'PEO Client'))) {   
                    acct.Premier_Account_Health__c = 'Stable';
                } 
        } // if(originalType != newType
    } // checkAcctType
    
    public static void sendCssrSegmentChatterNotifications(Map<Id, Account> acctCssrSegment) {  
        List<Account> accts = [Select Id, Name, Current_Owner_Id__c FROM Account WHERE Id IN :acctCssrSegment.keySet()];  
        List<Id> usersToMention = new List<Id>(); 
        String postText = ' has either just reached 12 months with Paychex or has increased their employee count, and transitioned into your ownership.'; //' has just reached 12 months with Paychex and transitioned into your ownership.'; 
        for(Account a : accts) {  
            usersToMention.add(a.Current_Owner_Id__c); 
            ChatterMentionPost.createChatterMentionPost(a.Id, usersToMention, new String[]{a.Name, postText}, true);   
            usersToMention.clear();    
            CHATTER_SENT = true;   
        } 
    }
    //APR0132594: Create a new CSSR Mid-Market role in 20-49 segment (Method to notify users through chatter post regarding lost client)
    public static void SendLostNotificationCSSR(Account OldA,Account newA) {
        if((OldA.CSSR_Segment__c== True && newA.CSSR_Segment__c==False) && (newA.OwnerId!= oldA.OwnerId))
           {
            String postText = 'A current client account has been transferred to your ownership. This is likely a result of a lost client notification. Please review account.';
            List<Id> usersToMention = new List<Id>();
            usersToMention.add(newA.OwnerId);
            ChatterMentionPost.createChatterMentionPost(newA.Id, usersToMention, new String[]{postText}, true);
        }
    }
    public static void updateAccountFieldsMiEdge(Map<Id, Account> acctmiEdgeUpdates) {  
        
        List<Account> accts = [select id, miedge_crm__master_msid__r.Name, miedge_crm__master_msid__r.miedge_crm__WC_Carrier__c, miedge_crm__master_msid__r.miedge_crm__WC_Renewal_Date__c, 
                               miedge_crm__Master_MSID__r.miedge_crm__Ben_Broker__c, miedge_crm__Master_MSID__r.miedge_crm__Exmod__c, 
                               miedge_crm__Master_MSID__r.miedge_crm__Ret_Plan_Assets__c, 
                               miedge_crm__master_msid__r.miedge_crm__Ben_Renewal_Date__c, miedge_crm__master_msid__r.miedge_crm__Ben_Lead_Carrier__c, Work_Comp_Renewal_Date__c, H_B_Renewal_Date__c 
                               from Account where id in :acctmiEdgeUpdates.keySet()];
        
        Map<Id, Id> msidMap = new Map<Id, Id>();
        Map<Id, Account> msidAcctMap = new Map<Id, Account>();
        
        List<miedge_crm__Master_MSID__c> msids = new List<miedge_crm__Master_MSID__c>();
        List<miEdge_crm__EB_Detail__c> allEBs = new List<miEdge_crm__EB_Detail__c>();
        Map<Id, List<miEdge_crm__EB_Detail__c>> ebAcctsMap = new Map<Id, List<miEdge_crm__EB_Detail__c>>();
        
        Map<Account, List<Decimal>> denAcctEbMap = new Map<Account, List<Decimal>>();
        Map<Decimal, String> denCarrierNameMap = new Map<Decimal, String>();
        
        Map<Account, List<Decimal>> visionAcctMap = new Map<Account, List<Decimal>>();
        Map<Decimal, String> visionCarrierNameMap = new Map<Decimal, String>();
        
        Map<Account, List<Decimal>> healthAcctMap = new Map<Account, List<Decimal>>();
        Map<Decimal, Date> healthCarrierNameMap = new Map<Decimal, Date>();
        
        Account acctToUpdate;
        List<Account> dentalAcctsToUpdate = new List<Account>();
        
        Integer wcRenewal = 0;
        Integer hbRenewal = 0;
        String wcMonth = '';
        String hbMonth = '';
        
        String ebDental = '';
        String ebVision = '';
        
        Map<Integer, String> dateMap = new Map<Integer,String>();
        Map<Integer, String> dateMapHb = new Map<Integer, String>();
        List<String> months = new String[]{'JAN','FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'};
            List<String> monthsHb = new String[]{'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'};
                
                for(Integer i=1; i<13; i++) {
                    dateMap.put(i,months.get(i-1));
                    dateMapHb.put(i, monthsHb.get(i-1));
                } //for(Integer i=1)
        
        if(!accts.isEmpty()) {
            for(Account a: accts) {
                msidMap.put(a.miedge_crm__Master_MSID__c, a.Id);
                msidAcctMap.put(a.miedge_crm__Master_MSID__r.Id, a);
                if(a.miedge_crm__Master_MSID__r != null) {
                    a.Workers_Comp_Carrier__c = a.miedge_crm__Master_MSID__r.miedge_crm__WC_Carrier__c;
                    a.H_B_Brokerage_Firm__c = a.miedge_crm__Master_MSID__r.miedge_crm__Ben_Broker__c;
                    a.H_B_Carrier__c = a.miedge_crm__Master_msid__r.miedge_crm__Ben_Lead_Carrier__c;
                    a.Larkspur_401K_Assets__c = a.miedge_crm__Master_MSID__r.miedge_crm__Ret_Plan_Assets__c;
                    a.Workers_Comp_Ex_Mod__c = a.miedge_crm__Master_MSID__r.miedge_crm__Exmod__c;
                    if(a.miedge_crm__Master_MSID__r.miedge_crm__WC_Renewal_Date__c != null) {
                        wcRenewal = (a.miedge_crm__Master_MSID__r.miedge_crm__WC_Renewal_Date__c).month();
                        wcMonth = dateMap.get(wcRenewal);
                        a.Work_Comp_Renewal_Date__c = wcMonth;
                    }
                } //if(a.miedge_crm__Master_MSID__r != null)
                
            } //for(Account a: accts)
            
            if(!msidMap.isEmpty()) {
                
                msids = [Select Id, Name, Prospect_Client__c, (Select Id, Name, miedge_crm__Renewal_Date__c, miedge_crm__Carrier__c, miedge_crm__Master_MSID__r.Id, miedge_crm__Enrolled_Employees__c from miEdge_crm__EB_Details__r), 
                         (Select Id, Name, Dental_Carrier__c, Vision_Carrier__c, H_B_Renewal_Date__c from miEdge_crm__Accounts__r) 
                         from miedge_crm__Master_MSID__c where id in :msidMap.keySet()];
                
                if(!msids.isEmpty()) {
                    for(miedge_crm__Master_MSID__c m: msids) {
                        m.Prospect_Client__c = msidMap.get(m.Id);
                        if(!m.miEdge_crm__EB_Details__r.isEmpty()){
                            allEBs.addAll(m.miEdge_crm__EB_Details__r);
                        }
                    }
                }
                
                if(!allEBs.isEmpty()) {
                    for(miEdge_crm__EB_Detail__c eb:allEBs){
                        eb.Prospect_Client__c = msidMap.get(eb.miedge_crm__Master_MSID__r.Id);
                        acctToUpdate = msidAcctMap.get(eb.miedge_crm__Master_MSID__r.Id);
                        if(eb.Name.contains('Dental')) {
                            if(denAcctEbMap.containsKey(acctToUpdate)) {
                                List<Decimal> currList = denAcctEbMap.get(acctToUpdate);
                                currList.add(eb.miedge_crm__Enrolled_Employees__c);
                                denAcctEbMap.put(acctToUpdate, currList);
                            } else {
                                denAcctEbMap.put(acctToUpdate, new List<Decimal>{eb.miedge_crm__Enrolled_Employees__c});
                            }
                            denCarrierNameMap.put(eb.miedge_crm__Enrolled_Employees__c, eb.miedge_crm__Carrier__c);
                        }
                        if(eb.Name.contains('Vision')) {
                            if(visionAcctMap.containsKey(acctToUpdate)) {
                                List<Decimal> currList = visionAcctMap.get(acctToUpdate);
                                currList.add(eb.miedge_crm__Enrolled_Employees__c);
                                visionAcctMap.put(acctToUpdate, currList);
                            } else {
                                visionAcctMap.put(acctToUpdate, new List<Decimal>{eb.miedge_crm__Enrolled_Employees__c});
                            }
                            visionCarrierNameMap.put(eb.miedge_crm__Enrolled_Employees__c, eb.miedge_crm__Carrier__c);
                        }
                        if(eb.Name.contains('Health')) {
                            if(healthAcctMap.containsKey(acctToUpdate)) {
                                List<Decimal> currList = healthAcctMap.get(acctToUpdate);
                                currList.add(eb.miedge_crm__Enrolled_Employees__c);
                                healthAcctMap.put(acctToUpdate, currList);
                            } else {
                                healthAcctMap.put(acctToUpdate, new List<Decimal>{eb.miedge_crm__Enrolled_Employees__c});
                            }
                            healthCarrierNameMap.put(eb.miedge_crm__Enrolled_Employees__c, eb.miedge_crm__Renewal_Date__c);
                        }
                    }
                }
                
                if(!denAcctEbMap.isEmpty()) {
                    for(Account acct: denAcctEbMap.keySet()) {
                        List<Decimal> empNumList = denAcctEbMap.get(acct);
                        empNumList.sort();
                        Decimal maxEmpNum = empNumList.get(empNumList.size()-1);
                        if(!denCarrierNameMap.isEmpty()) {
                            ebDental = denCarrierNameMap.get(maxEmpNum);
                            if(ebDental != null){
                                acct.Dental_Carrier__c = ebDental;
                            }
                        }
                    }
                }
                
                if(!visionAcctMap.isEmpty()) {
                    for(Account acct: visionAcctMap.keySet()) {
                        List<Decimal> empNumList = visionAcctMap.get(acct);
                        empNumList.sort();
                        Decimal maxEmpNum = empNumList.get(empNumList.size()-1);
                        if(!visionCarrierNameMap.isEmpty()){
                            ebVision = visionCarrierNameMap.get(maxEmpNum);
                            if(ebVision != null){
                                acct.Vision_Carrier__c = ebVision;
                            }
                        }
                    }
                }
                
                if(!healthAcctMap.isEmpty()) {
                    for(Account acct: healthAcctMap.keySet()) {
                        List<Decimal> empNumList = healthAcctMap.get(acct);
                        empNumList.sort();
                        Decimal maxEmpNum = empNumList.get(empNumList.size()-1);
                        if(!healthCarrierNameMap.isEmpty()){
                            hbRenewal = (healthCarrierNameMap.get(maxEmpNum)).month();
                            hbMonth = dateMapHb.get(hbRenewal);
                            if(hbMonth != null && acct.H_B_Renewal_Date__c == null){
                                acct.H_B_Renewal_Date__c = hbMonth;
                            }
                        }
                    }
                }                  
                
            }
            
        }
        
        DmlHelper.performDML2(accts, DmlHelper.DML_UPDATE, 'AccountMethods', 'updateAccountFieldsMiEdge', 'Update miEdge Account fields', true);
        DmlHelper.performDML2(msids, DmlHelper.DML_UPDATE, 'AccountMethods', 'updateAccountFieldsMiEdge', 'Update miEdge fields', true);
        if(!allEBs.isEmpty()) {
            DmlHelper.performDML2(allEBs, DmlHelper.DML_UPDATE, 'AccountMethods', 'updateAccountFieldsMiEdge', 'Update miEdge EB Detail fields', true);
        }
        
        
    } //if(!accts.isEmpty())
    
    public static String ATM_REL_MGR = Label.AT_REL_MGR;

        /*BAU Changes*/
        public static void createAccountTeamMember(Map<Id,Account> checkAcctAtmMap){
            System.debug('createAccountTeamMember checkAcctAtmMap='+checkAcctAtmMap.size());
            List<AccountTeamMember> atmsToBeInserted=new List<AccountTeamMember>();
            AccountTeamMember[] atmsToDelete = new AccountTeamMember[]{};
            AccountTeamMember[] atms=(!checkAcctAtmMap.isEmpty() ? [Select id,UserId,AccountId,TeamMemberRole 
                                                             from AccountTeamMember 
                                                            where TeamMemberRole=:ATM_REL_MGR and AccountId In:checkAcctAtmMap.keyset()]
                                      : new AccountTeamMember[]{});
            System.debug('createAccountTeamMember atms='+atms.size());
            // could be multiple, use accountid and userid - so we can check if they already exist
            Map<String,AccountTeamMember> atmByAcctIdMap = new Map<String,AccountTeamMember>();
            for (AccountTeamMember atm : atms ) {
               String key = ''+atm.AccountId+atm.UserId;
               atmByAcctIdMap.put(key, atm);
            }
            
            //if(atms!=null && !atms.isEmpty()){
            //    delete atms;
            //}
            for (Account acct : checkAcctAtmMap.values()) {
               if (acct.Relationship_Manager_PEO_Client_Advocate__c != null) {
                  // see if one already exists.
                  String key = ''+acct.Id+acct.Relationship_Manager_PEO_Client_Advocate__c;
                  // remove from the map if it exists. 
                  AccountTeamMember atm = atmByAcctIdMap.remove(key);
                  // if one doesn't already exist, create a new one
                  if (atm == null) {
                     atm=new AccountTeamMember(AccountId=acct.Id, TeamMemberRole = ATM_REL_MGR
                                   ,UserId =acct.Relationship_Manager_PEO_Client_Advocate__c
                                   ,AccountAccessLevel='Edit', ContactAccessLevel='Edit', OpportunityAccessLevel='Read');
                     atm.Opportunity_Team_Start_Date__c=Datetime.now();
                     atmsToBeInserted.add(atm);
                  }
               }
            } // for (Account acct : checkAcctAtmMap
            System.debug('createAccountTeamMember atmByAcctIdMap='+atmByAcctIdMap.size()+' atmsToBeInserted='+atmsToBeInserted.size());
            if (!atmByAcctIdMap.isEmpty()) {
               // anything remaining in this map can be deleted.
               delete atmByAcctIdMap.values();
            }
            if(!atmsToBeInserted.isEmpty()){
                 DmlHelper.performDML2(atmsToBeInserted, DmlHelper.DML_INSERT, 'AccountMethods', 'createAccountTeamMember', 'We are inserting ATM', true);
            }
        } // createAccountTeamMember
        /*BAU Changes*/
    
    // Rohit
    // Update Oasis_401k_Sensitivity__c and X401k_Sensitivity_Reason__c field
    // Insert Account Product Sensitvities Record
    public static void upsertAccountProductSensitvities(Set<Id> accIds){
        
        List<Account_Product_Sensitivities__c> updateAPSList = new List<Account_Product_Sensitivities__c>();
        List<Account_Product_Sensitivities__c> insertAPSList = new List<Account_Product_Sensitivities__c>();
       
        if(!accIds.isEmpty()){
           
            List<Account_Product_Sensitivities__c> accProductList = [Select Id, Oasis_401k_Sensitivity__c ,X401k_Sensitivity_Reason__c from Account_Product_Sensitivities__c where Prospect_Client__c IN : accIds];
            if(accProductList!=null && !accProductList.isEmpty()){
                for(Account_Product_Sensitivities__c aps : accProductList){
                    if(!aps.Oasis_401k_Sensitivity__c){
                        aps.Oasis_401k_Sensitivity__c = True;                    
                        aps.X401k_Sensitivity_Reason__c = '672249';
                        updateAPSList.add(aps);
                    }
                }
                if(updateAPSList!=null && !updateAPSList.isEmpty()){
                    
                     DmlHelper.performDML2(updateAPSList, DmlHelper.DML_UPDATE, 'AccountMethods', 'upsertAccountProductSensitvities', 'Updating Account Product Sensitivities', true);
                    
                }
            }else{
                for(Id accId : accIds){
                    Account_Product_Sensitivities__c newAPS = new Account_Product_Sensitivities__c(); 
                    newAPS.Prospect_Client__c = accId;
                    newAPS.Oasis_401k_Sensitivity__c = True;
                    newAPS.X401k_Sensitivity_Reason__c = '672249';
                    insertAPSList.add(newAPS);
                }
                if(insertAPSList!=null && !insertAPSList.isEmpty()){
                   
                     DmlHelper.performDML2(insertAPSList, DmlHelper.DML_INSERT, 'AccountMethods', 'upsertAccountProductSensitvities', 'Inserting Account Product Sensitivities', true);
                    
                }
            }
        }
        
    }
    
} // class AccountMethods