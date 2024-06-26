/* If the zip code of a record changes, check the ownership against the Zip Assignment object
to see if it should be changed.

• AccountBefore trigger
○ ZipCheckOwner.handleAccountsBefore
§ Set Current_Owner_ID__c and Previous_Owner_Id__c fields
§ checkAcctHoldOuts - see if any holdouts are past their expiration date. If so, clear them and set Use_Zip_Assignment__c to true
• AccountAfter trigger 
○ Evaluate all ownership if:
§ If Use_Zip_Assignment_Rules == true
§ Or if update and owner is SFDC Data and IsChild == false
§ Or ZipCheckOwner.checkForOwnerEval - ownership will be evaluated if any of the following is true.
□ Did the owner zip code change
□ Or one of the hold out fields was changed to false
□ Or the RecordType changed
□ Or the NumberOfEmployees went from null to a non-null value
□ Or the NumberOfEmployees changed greater than the amount of Label.Emp_Change_Thresshold (currently at 9999)
□ Or any of the fields in PaychexSettings__c custom setting 
§ Or Is Insert and user is not a System Administrator profile
§ Calls ZipCheckOwner.checkAccountOwners
○ Evaluate only account team if main ownership isn't evaluated and:
§ Is Insert
§ Or ZipCheckOwner.checkForAcctTeamEval
□ Did one of the fields that directly drive the account team change?
§ Calls ZipCheckOwner.checkAccountTeams
• ZipCheckOwner.checkAccountTeams
○ getAccounts - selects all of the accounts for the passed in ids
○ getUserByPersonIdMap - gets all users where we only have a person id
§ Currently this is only ESR_Person_Id__c
○ verifyAcctTeams
§ Get the current account team members
§ verifyContactAcctTeams - check the ones that are represented by a contact on the account. 
□ HR_Generalist__r & HR_Manager__r
□ Look at the User Lookup field on these for the users
□ See if the team member exists correctly or not.
§ verifyPersonIdAcctTeams
□ This is just the ESR_Person_Id__c field
• ZipCheckOwner.checkAccountOwners
○ If this is one record (or already in future or batch) it runs inline. Otherwise it runs in a future context .
○ processAccounts
§ setupRecordTypeMaps -  rtById and rtByName maps to use elsewhere in the code
§ getAccounts - Select the accounts for the ids provided
§ Make sure the account has a zip code and is of the appropriate record type (core/mms)
§ getUserByPersonIdMap - get all the users where we only have a person id
§ getZipAsgns - get all of the zip assignments for the zip codes found
□ From ZipQueries.getZipAsgnMap
§ For each account, calls checkAccount
□ Get Account Team Members
□ Calls checkAcctHoldOuts to see if any hold outs have expired
□ For each Zip Segment, call checkAccountSegment 
® checkZipCriteria if there's an owner field
◊ setOwnerField to actually set the value on the owner field
◊ checkAccountTeam
checkAccountTeam if there's a team role on the segment


History
-------
05/09/2012 Dan Carmen   Created from AccountCheckOwner
07/13/2012 Dan Carmen   Added more fields to the Zip Assignment query
09/25/2012 Dan Carmen   Added logic for Referral Accounts
12/12/2012 Dan Carmen   Added asset criteria
05/14/2013 Dan Carmen   Removed specific DSR logic
05/22/2013 Dan Carmen   Added check for bad zip codes for referral accounts.
06/24/2013 Dan Carmen   Use the Emp/Asset on the zip segment instead of zip assignment record
07/12/2013 Dan Carmen   Added User's HR Person Id to selection of the Zip Assignments
01/22/2014 Cindy Freeman  changed CheckRefAcctOwner to use only zip5
03/01/2014 Dan Carmen   Changes for NSS
02/24/2015 Dan Carmen   Added check in for number of employees changing from null to not null to evaluate ownership
03/03/2015 Dan Carmen   Fix for using the Use_Zip_Assignment_Rules__c field
05/05/2015 Dan Carmen   Modification for verifyAcctTeams, adding extra logging.
08/05/2015 Cindy Freeman  added AT_LGMKT_401k static variable just in case
11/10/2015 Cindy Freeman  added Hispanic_Ownership to checkForOwnerEval, if changed evaluate ownership
12/23/2015 Dan Carmen   Removed Hispanic_Ownership__c changes - logic is handled by custom settings.
04/07/2016 Dan Carmen   Change to allow account team to be set even if criteria isn't met.
06/09/2016 Dan Carmen   Change to make the join criteria case insensitive.
06/30/2016 Dan Carmen   Ability to assign ownership on referrals based on record type
09/29/2016 Dan Carmen   Move contact ownership to the before trigger.
10/24/2016 Jacob Hinds  Adding in ESR Account Team member.
12/21/2016 Dan Carmen   Additional contact ownership check once sales contact is checked.
12/27/2016 Cindy Freeman  Modified code to Account Junction stuff so child account owners follow parent account owners (unless Hold Out)
12/14/2017 Cindy Freeman  Modified doWeCheckCtctOwner method to update contact owners if relinked to another account
06/01/2018 Cindy Freeman  Modified setupRecordTypeMaps to exclude any record type with Exclude from Zip Batch checked
06/22/2018 Dan Carmen    added check for record types in checkForSegmentationEvaluation
08/16/2018 Cindy Freeman  Modified checkContacts to allow account null owners to be pushed down to contacts
03/05/2018 Jacob Hinds    Adding in multiple record types for zip segment query for AcctRecordTypeName__c and RfrlRecordTypeName__c
06/04/2019 Dan Carmen       Added in a check when deleting the account teams that the Id exists
06/21/2019 Dan Carmen       Added in check for zero joinCriteria
07/16/2019 Dan Carmen       Added record ownerid on change
04/02/2020 Brandon Vidro    Added logic to Freeze Zip Segmentation using custom label - Disable_Zip_Segmentation_Evaluation
05/14/2020 Jake Hinds        Adding TAA hold out fields to acct query
07/22/2020 Dan Carmen        Add AccountAccessLevel to AccountTeamMember
08/10/2020 Jake Hinds    Modified debug statment per PMD
11/08/2021 Jermaine Stukes  Removed references to external wholesaler owner fields 
01/04/2022 Dan Carmen         Move logic from the AccountAfter trigger to ZipCheckOwner
03/04/2022 Dan Carmen         Clean up some ownership logic
08/18/2022 Dan Carmen         Extend holdout when start date set
08/19/2022 Shilpa G      Added Lost Client Ownership logic
01/12/2023 Dan Carmen    Updated logic to allow evaluateSegmentation on new accounts and if account number changes
03/02/2023 Dan/Rohit Ranjan  PEO Ownership rule changes APR0142576
04/07/2023 Jaipal            APR0147082: PEO Client Ownership changes in method: checkZipCriteria && handleAccountsBefore
10/05/2023 Shilpa G       APR0151946: Updated method 'checkAccountSegment' to set Hold Out Reason if available on Zip Segment when owner is changed
11/10/2023 Shilpa G       APR0151946: Updated method 'evaluateSegmentation' to not change record type if CSSR segment is set and has MMS record type currently
12/08/2023 Dan Carmen        Removed an unnecessary query to RecordType__c in setupRecordTypeMaps
01/02/2024 Dan Carmen        Additional linkage for ZipSegmentCriteriaLink__c for more flexibility
01/25/2024 Shilpa G       APR0161315: Updated method 'evaluateSegmentation' to change record type to MMS if Account is a prospect in 10-19 EE space
04/24/2024 Shilpa G       APR0157517:Project Blue Request: Create checkbox field to clear the PC team on accounts
05/10/2024 Pratik Das     APR0163609: PEO hold out for Integrated Selling
05/06/2024 Shilpa G       APR0164310: Updated method checkZipCriteria to add check for Client Type Operand Not Equals
*/
public without sharing class ZipCheckOwner implements TriggerInterfaceC {
    public static final String CLASSNAME='ZipCheckOwner';
    
    public static String TYPE_PROSPECT='Prospect';
    public static String TYPE_CLIENT='Client';
    public static String TYPE_LOSTCLIENT='Lost Client';
    public static String TYPE_PEOCLIENT='PEO Client';
    
    public void handleTrigger(SObject[] p_recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter, Boolean isDelete) {
        SObject[] recs = TriggerMethods.checkRecs(CLASSNAME, p_recs, oldMap, isBefore, isAfter,null, null);
        System.debug('ZipCheckOwner.handleTrigger recs='+recs.size()+' isBefore='+isBefore+' isAfter='+isAfter);
        
        if (isBefore) {
            if (TriggerMethods.objType == Referral_Account__c.sObjectType) {
                handleRefAcctsBefore((Referral_Account__c[])recs, (Map<Id,Referral_Account__c>)oldMap);
            } else if (TriggerMethods.objType == Account.sObjectType) {
                handleAccountsBefore((Account[])recs, (Map<Id,Account>)oldMap);
            } else if (TriggerMethods.objType == Referral_Contact__c.sObjectType) {
                handleRefCtctsBefore((Referral_Contact__c[])recs, (Map<Id,Referral_Contact__c>)oldMap);
            }    
        } else if (isAfter) {
            if (TriggerMethods.objType == Account.sObjectType) {
                handleAccountsAfter((Account[])recs, (Map<Id,Account>)oldMap);
            }
        }
    } // handleTrigger
    
    public static Boolean ENFORCE_HOLDOUT=(Label.ReferralAccount_EnforceHoldOut == 'True');
    
    public static void handleRefCtctsBefore(Referral_Contact__c[] refCtcts, Map<Id,Referral_Contact__c> oldMap) {
        Referral_Contact__c[] setOwnerCtcts = new Referral_Contact__c[]{};
            Id[] refAcctIds = new Id[]{};
                Map<Id,Referral_Contact__c[]> refCtctOwnerMap = new Map<Id,Referral_Contact__c[]>();
        
        for ( Referral_Contact__c refCtct: refCtcts) {
            Referral_Contact__c oldRef = (oldMap != null ? oldMap.get(refCtct.Id) : null);
            // not sure we still need to enforce this - added a flag to easily turn off
            if (ENFORCE_HOLDOUT && !refCtct.BypassHoldOut__c && refCtct.Hold_Out__c && (oldRef != null) && (refCtct.ownerId != oldRef.ownerId)) {
                refCtct.ownerId = oldRef.ownerId;
            } else if (refCtct.BypassHoldOut__c) {
                // reset the flag
                refCtct.BypassHoldOut__c=false;
            }
            
            // if it's a new record, the flag is set, or the hold out is removed, pull the owner from the account
            if (refCtct.Referral_Account__c != null && (oldRef == null || refCtct.Use_Account_Ownership__c || (!refCtct.Hold_Out__c && oldRef.Hold_Out__c))) {
                setOwnerCtcts.add(refCtct);
                refAcctIds.add(refCtct.Referral_Account__c);
            }
            
        } // for
        
        if (!setOwnerCtcts.isEmpty()) {
            ZipCheckOwner.setRefContacts(setOwnerCtcts,refAcctIds);
        } // if (!setOwnerCtcts.isEmpt
        
        
        // always do this check to make sure field is in sync
        for (Referral_Contact__c refCtct: refCtcts) {
            
            // make sure the owner is a user, set the user lookup field
            if (refCtct.OwnerId != null && ((String)refCtct.OwnerId).left(3) == ObjectHelper.PREFIX_USER) {
                if (refCtct.User_Lookup__c == null || (refCtct.User_Lookup__c != refCtct.OwnerId)) {
                    refCtct.User_Lookup__c = refCtct.OwnerId;
                }
            } // if (newR.OwnerId != null
        } // for
    } // handleRefCtctsBefore
    
    public static void handleRefAcctsBefore(Referral_Account__c[] refAccts, Map<Id,Referral_Account__c> oldMap) {
        //Referral_Account__c[] evaluateZipSegments = new Referral_Account__c[]{};
        Referral_Account__c[] checkAcctOwnership = new Referral_Account__c[]{};
            Referral_Account__c[] checkCtctOwnership = new Referral_Account__c[]{};
                Set<String> zipCodeSet = new Set<String>();
        Id[] refAcctIds = new Id[]{};
            
            Id[] checkCtctOwnershipIds = new Id[]{};
                
                for (Referral_Account__c refAcct : refAccts) {
                    Referral_Account__c oldRef = (oldMap != null ? oldMap.get(refAcct.Id) : null);
                    // not sure we still need to enforce this - added a flag to easily turn off
                    if (ENFORCE_HOLDOUT && !refAcct.BypassHoldOut__c && refAcct.Hold_Out__c && (oldRef != null) && (refAcct.ownerId != oldRef.ownerId)) {
                        refAcct.ownerId = oldRef.ownerId;
                    } else if (refAcct.BypassHoldOut__c) {
                        // reset the flag
                        refAcct.BypassHoldOut__c=false;
                    }
                    
                    // segment stuff will not be used anymore
                    /*
if (String.isNotBlank(refAcct.Referral_Source_Business_Type__c) &&
(oldRef == null || refAcct.EvaluateZipSegment__c || refAcct.Referral_Source_Business_Type__c != oldRef.Referral_Source_Business_Type__c
|| refAcct.Referral_Type__c != oldRef.Referral_Type__c)) {
evaluateZipSegments.add(refAcct);
}
*/
                    
                    // if insert, or zip code or record type or business type changes
                    // or hold out changes 
                    if (String.isNotBlank(refAcct.Zip_Postal_Code__c) 
                        && (oldRef == null
                            || refAcct.Use_Zip_Assignment_Rules__c
                            || (refAcct.Hold_Out__c != oldRef.Hold_Out__c)
                            || (refAcct.Zip_Postal_Code__c != oldRef.Zip_Postal_Code__c)
                            || (refAcct.RecordTypeId != oldRef.RecordTypeId)
                            || (refAcct.Referral_Source_Business_Type__c != oldRef.Referral_Source_Business_Type__c)
                           )
                       ) {
                           checkAcctOwnership.add(refAcct);
                           // undo the flag so will not be used again
                           refAcct.Use_Zip_Assignment_Rules__c = false;
                           if (refAcct.Id != null) {
                               refAcctIds.add(refAcct.Id);
                           }
                           String checkZip = Utilities.checkPostalCode(refAcct.Zip_Postal_Code__c, null);
                           if (String.isNotBlank(checkZip)) {
                               zipCodeSet.add(checkZip);
                           }
                           
                       } else if (oldRef != null && ZipCheckOwner.checkForAcctOwnerChange(refAcct,oldRef)) {
                           // if one of the owner changed, we'll check the contacts to make sure they're in sync
                           checkCtctOwnership.add(refAcct);
                           checkCtctOwnershipIds.add(refAcct.Id);
                       }
                } // for (Referral_Account__c refAcct 
        System.debug('handleRefAcctsBefore checkAcctOwnership='+checkAcctOwnership.size()+' zipCodeSet='+zipCodeSet.size()+' checkCtctOwnership='+checkCtctOwnership.size());
        /*
System.debug('handleRefAcctsBefore evaluateZipSegments='+evaluateZipSegments.size());
if (!evaluateZipSegments.isEmpty()) {
handleRefAcctSegments(evaluateZipSegments);
}
*/
        if (!checkAcctOwnership.isEmpty()) {
            ZipCheckOwner.checkReferralAccounts(checkAcctOwnership,refAcctIds,zipCodeSet);
        }
        
        if (!checkCtctOwnership.isEmpty()) {
            ZipCheckOwner.checkRefCtcts(checkCtctOwnership,checkCtctOwnershipIds);
        }
        
        // do this check at the end in case the owner changes
        if (!checkAcctOwnership.isEmpty() || !checkCtctOwnership.isEmpty()) {
            for ( Referral_Account__c refAcct: refAccts) {
                //Referral_Account__c oldRef = (oldMap != null ? oldMap.get(refAcct.Id) : null);
                // make sure the owner is a user, set the user lookup field
                if (refAcct.OwnerId != null && ((String)refAcct.OwnerId).left(3) == ObjectHelper.PREFIX_USER) {
                    if (refAcct.User_Lookup__c == null || (refAcct.User_Lookup__c != refAcct.OwnerId)) {
                        refAcct.User_Lookup__c = refAcct.OwnerId;
                    }
                } // if (newR.OwnerId != null
            } // for
            
        } // if (!checkAcctOwnership.isEmpty()
    } // handleRefAcctsBefore
    /*
public static void handleRefAcctSegments(Referral_Account__c[] refAccts) {
// list the non-null values first so they'll be evaluated first
String defaultSegment = null;
ReferralSourceSegment__mdt[] allSegments = [Select Label, MasterLabel, DefaultSegment__c, RecordTypeName__c,ReferralType__c, ZipSegment__c from ReferralSourceSegment__mdt order by ReferralType__c NULLS LAST];
Map<String, ReferralSourceSegment__mdt[]> segmentMap = new Map<String,ReferralSourceSegment__mdt[]>();
for (ReferralSourceSegment__mdt rss : allSegments) {
if (rss.DefaultSegment__c) {
defaultSegment = rss.ZipSegment__c;
}
ReferralSourceSegment__mdt[] segments = (segmentMap.containsKey(rss.Label) ? segmentMap.get(rss.Label) : new ReferralSourceSegment__mdt[]{});
segments.add(rss);
segmentMap.put(rss.Label, segments);
} // for
// just to confirm there's a value
defaultSegment = (String.isNotBlank(defaultSegment) ? defaultSegment : 'PAY-Other');

for (Referral_Account__c refAcct : refAccts) {
// clear out the value to make sure it's reevaluated
refAcct.EvaluateZipSegment__c=false;
refAcct.ZipSegment2__c=null;
ReferralSourceSegment__mdt[] segments = segmentMap.get(refAcct.Referral_Source_Business_Type__c);
if (segments != null) {
for (ReferralSourceSegment__mdt segment : segments) {
if ((String.isNotBlank(segment.ReferralType__c) && segment.ReferralType__c == refAcct.Referral_Type__c)
|| String.isBlank(segment.ReferralType__c)) {
refAcct.ZipSegment2__c = segment.ZipSegment__c;
break;
}
} // for (ReferralSourceSegment__mdt segment
} // if (segments != null
// put in a default segment
if (refAcct.ZipSegment2__c == null) {
refAcct.ZipSegment2__c = defaultSegment;
}
} // for (Referral_Account__c refAcct : refAccts
} // handleRefAcctSegments
*/
    public static String[] EXCLUDE_PROFILE_NAME_LIST = new String[]{'System Administrator'};
        
        public static String PROCESS_NAME='ZipCheckOwner';
    
    public static Boolean SKIP_TRIGGERS = false;
    
    public static Integer NAME_LENGTH=Profile_List__c.Name.getDescribe().getLength();
    
    // Verify the custom setting is populated. Will only have to be done once, then further queries will be made from memory.
    // this only needs to be done for tests
    public static void verifyExcludeListSetup() {
        List<Profile_List__c> profs = Profile_List__c.getall().values();
        // verify at least one with the process name ZipCheckOwner
        Boolean hasValue = false;
        for (Profile_List__c prof : profs) {
            if (prof.ZipCheckOwnerExclude__c) {
                //if (prof.Name.startsWith(PROCESS_NAME)) {
                // can stop if at least one record is found
                hasValue = true;
                break;
            }
        } // if (Profile_List__c
        
        // if no records are found retrieve the profiles and ids and insert
        if (!hasValue && profs.isEmpty()) {
            Profile[] checkProfs = [Select Id, Name from Profile where Name in :EXCLUDE_PROFILE_NAME_LIST];
            Profile_List__c[] insertRecs = new Profile_List__c[]{};
                for (Profile prof : checkProfs) {
                    String profName = prof.Name.left(NAME_LENGTH);
                    Profile_List__c rec = new Profile_List__c(Name=profName, Profile_Name__c=prof.Name, ProfileId__c=prof.Id, ZipCheckOwnerExclude__c=true);
                    insertRecs.add(rec);
                }
            if (!insertRecs.isEmpty()) {
                try {
                    insert insertRecs;
                    System.debug('verifyExcludeListSetup insertRecs='+insertRecs.size());
                } catch (Exception e) {
                    System.debug('Exception: '+e);
                }
            }
        } // if (!hasValue
        
    } // verifyExcludeListSetup
    
    // Check to see if certain actions happen on insert. Do not fire actions for certain profiles.
    public static Boolean checkOnInsert() {
        // only do the verify when running tests
        if (Test.isRunningTest()) {
            verifyExcludeListSetup();
        }
        Boolean checkRec = true;
        User runningUser = UserHelper.getRunningUser();
        if (runningUser != null) {
            String profName = runningUser.Profile.Name.left(NAME_LENGTH).trim();
            System.debug('checkOnInsert profName='+profName+'.');
            Profile_List__c prof = Profile_List__c.getInstance(profName);
            if (prof != null && prof.ZipCheckOwnerExclude__c) {
                checkRec = false;
            }
        } // if
        
        System.debug('checkOnInsert checkRec='+checkRec);
        return checkRec;
    } // checkUseInsertTrigger
    
    // these are left in for test scenarios - code will use values from the custom settings
    public static final String[] RECORDTYPE_NAMES = new String[]{RecordTypeHelper.CORE_ACCOUNT
        ,RecordTypeHelper.MMS_ACCOUNT
        ,RecordTypeHelper.CORE_CONTACT
        ,RecordTypeHelper.MMS_CONTACT
        ,RecordTypeHelper.CORE_LEAD
        ,RecordTypeHelper.HRS_LEAD
        ,RecordTypeHelper.MMS_LEAD};
            
            public static final String[] OBJECT_NAMES = new String[]{ObjectHelper.OBJECT_ACCOUNT,ObjectHelper.OBJECT_CONTACT,ObjectHelper.OBJECT_LEAD
                ,ObjectHelper.OBJECT_REF_ACCOUNT, ObjectHelper.OBJECT_REF_CONTACT};
                    
                    /* Account team member names */
                    public static final String AT_401K=Label.AT_401k; //'Small Market 401(k) Partner';
    public static final String AT_LGMKT_401K=Label.AT_LGMKT_401k; //'Large Market 401(k) Partner';   
    public static final String AT_PEO_ASO=Label.AT_PEO_ASO; //'HRS PEO-ASO Partner';
    public static final String AT_HNBF=Label.AT_HNBF; //'HRS HNBF Partner';
    public static final String AT_HRG=Label.AT_HRG; //'PHRS HR Generalist';
    public static final String AT_HRM=Label.AT_HRM; //'PHRS HR Manager';
    public static final String AT_INT_WHOLE=Label.AT_INT_WHOLE; //'Internal Wholesaler';
    public static final String AT_EXT_WHOLE=Label.AT_EXT_WHOLE; //'External Wholesaler';
    public static final String AT_ESR=Label.AT_ESR; //'ESR Dedicated Service Rep';
    
    public static Map<String,Schema.RecordTypeInfo> rtById = null;                     
    public static Map<String,Schema.RecordTypeInfo> rtByName = null;
    
    /* initialize rtById and rtByName maps then call RecordTypeHelper.getRecordTypesMap to populate the maps
*/
    public static void setupRecordTypeMaps() {
        if (rtById == null) {
            Set<String> objectNameSet = new Set<String>();
            List<String>  rtNames = new List<String>();
            System.debug('setupRecordTypeMaps RecordType__c.getAll().size()='+RecordType__c.getAll().size());
            if (RecordType__c.getAll().size() == 0) {
                objectNameSet.addAll(OBJECT_NAMES);
                rtNames.addAll(RECORDTYPE_NAMES);
            } else {
                for (RecordType__c rt : RecordType__c.getAll().values()) {
                    if (rt.UsedInOwnership__c) { // && !rt.Exclude_from_ZipBatch__c) {           //CMFCMF PEOC
                        if (String.isNotBlank(rt.ObjectName__c)) {
                            objectNameSet.add(rt.ObjectName__c);
                        }
                        rtNames.add(rt.RecordTypeName__c);
                    }
                } // for
            } // if
            System.debug('setupRecordTypeMaps rtNames='+rtNames.size());
            List<String> objectNames = new List<String>();
            objectNames.addAll(objectNameSet);
            rtById = new Map<String,Schema.RecordTypeInfo>();                     
            rtByName = new Map<String,Schema.RecordTypeInfo>();
            //RecordTypeHelper.getRecordTypesMap(OBJECT_NAMES,RECORDTYPE_NAMES,rtById,rtByName);
            RecordTypeHelper.getRecordTypesMap(objectNames,rtNames,rtById,rtByName);
            System.debug('setupRecordTypeMaps rtById='+rtById.size());
        } // if (rtById == null
    } // setupRecordTypeMaps
    
    /*
// process the list of accounts from the trigger
public static void processAccounts(List<Id> allAcctIds) {
System.debug('processAccounts');
// add them to the set so they're not processed again
accountIdsProcessedSet.addAll(allAcctIds);
setupRecordTypeMaps();

List<Account> allAccts = getAccounts(allAcctIds,rtById.keySet());
System.debug('processAccounts allAcctIds='+allAcctIds.size()+' allAccts='+allAccts.size());
processAccounts(allAccts, true);
} // processAccounts

public static void processAccounts(List<Account> allAccts, Boolean performSave) {
System.debug('ZipCheckOwner processAccounts allAccts='+allAccts.size());
// the zip codes to retrieve Zip_Assignment__c objects for
Set<String> checkZips = new Set<String>();
// the Accounts that have a valid record type
List<Account> checkAccts = new List<Account>();
// list of account ids that had owner changes we want to push to AccountJunctionMethods
List<Id> checkParentChild = new List<Id>();                      // CMF parent


for (Account acct : allAccts) {
// make sure has zip code and record type is one we're checking.
System.debug('processAccounts acct Name='+acct.Name+' zipCode='+acct.Owner_ZipCode__c);
if (acct.isChild__c) {
checkParentChild.add(acct.Id);
}
if (rtById.containsKey(acct.RecordTypeId)) {
checkAccts.add(acct);
if (String.isNotBlank(acct.Owner_Zip_Code__c)) {
checkZips.add(acct.Owner_Zip_Code__c);
}

} // if (acct.Owner_ZipCode__c != null
} // for (Account acct

System.debug('processAccounts checkAccts='+checkAccts.size());      
if (!checkAccts.isEmpty()) {

// retrieve all of the users saved by person id
Map<String,User> userByPersonIdMap = getUserByPersonIdMap(checkAccts);
// retrieve all of the Zip_Assignment__c objects
Map<String,List<Zip_Assignment__c>> zipMap = getZipAsgns(checkZips, ZipQueries.FILTER_ACCOUNTS); //queryKeys);
// retrieve all of the user ids that match the person ids.

// the accounts that will be updated
List<Account> updateAccts = new List<Account>();
// the contacts that will be updated
List<Contact> updateCtcts = new List<Contact>();

// the Account team members that are created or deleted
List<AccountTeamMember> insertAcctTeams = new List<AccountTeamMember>();
List<AccountTeamMember> deleteAcctTeams = new List<AccountTeamMember>();

for (Account acct : checkAccts) {
List<Zip_Assignment__c> zipList = zipMap.get(acct.Owner_ZipCode__c);
if (!acct.isChild__c) {
Boolean acctChanged = checkAccount(acct,zipList,updateCtcts,insertAcctTeams, deleteAcctTeams, userByPersonIdMap);
if (acctChanged) {
updateAccts.add(acct);
} // if (acctChanged
}

// if we're in here, always check the children
if ((acct.isParent__c || acct.isChild__c) && !AccountJunctionMethods.parentIdsProcessed.contains(acct.Id)) {
checkParentChild.add(acct.Id);
}                                                                      
} // for (Account acct

// this is where the owner upates are done
System.debug('processAccounts performSave='+performSave+' updateAccts='+updateAccts.size()+' updateCtcts='+updateCtcts.size());
if (performSave) {
SKIP_TRIGGERS = true;
DmlHelper.performDML2(updateAccts, DmlHelper.DML_UPDATE, 'ZipCheckOwner', 'processAccounts', 'Update Accounts', true);
DmlHelper.performDML2(updateCtcts, DmlHelper.DML_UPDATE, 'ZipCheckOwner', 'processAccounts', 'Update Contacts', true);

saveAcctTeams(insertAcctTeams,deleteAcctTeams);
SKIP_TRIGGERS = false;
} // if (performSave
} // if (!checkAccts.isEmpty

// push parent owners down to children                                                                    // CMF parent
if (performSave && !checkParentChild.isEmpty()) {                                                                         // CMF parent
AccountJunctionMethods.pushParenttoChild(null, checkParentChild);
}

} // processAccounts
*/
    // fields we can't add into the fieldset because the layers go too deep.
    public static String[] extraQueryFields = Label.ZipCheckOwner_ExtraAcctFlds.split(',');
    public static String ATM_QUERY=',(SELECT Id,AccountId,UserId,User.IsActive,TeamMemberRole,AccountAccessLevel,ContactAccessLevel, OpportunityAccessLevel from AccountTeamMembers ) ';
    /*
public static final String SETTING_ACCT_PROCESS_NAME='ZipCheckOwner-Acct';
public static final String SETTING_LEAD_PROCESS_NAME='ZipCheckOwner-Lead';
public static final String SETTING_CONTACT_PROCESS_NAME='ZipCheckOwner-Ctct';

private static String accountSettingQueryFlds = null;

public static String getAccountSettingQueryFlds() {
if (accountSettingQueryFlds == null) {
accountSettingQueryFlds = getSettingQueryFields(SETTING_ACCT_PROCESS_NAME);
}   
return accountSettingQueryFlds;
} // getAccountSettingQueryFlds

private static String leadSettingQueryFlds = null;

public static String getLeadSettingQueryFlds() {
if (leadSettingQueryFlds == null) {
leadSettingQueryFlds = getSettingQueryFields(SETTING_LEAD_PROCESS_NAME);
}
return leadSettingQueryFlds;
} // getLeadSettingQueryFlds

public static String getSettingQueryFields(String processName) {
String retVal = ''; 
for (PaychexSettings__c setting : PaychexSettings__c.getAll().values()) {
if (setting.ProcessName__c == processName && setting.isActive__c ) {
retVal += ','+setting.Attribute1__c;
}
} // for (PaychexSettings__c setting
return retVal;
} // getSettingQueryFields
*/
    public static String QUERY_CACHE_KEY='AcctQueryCacheKey';
    
    public static String getAcctQuery() {
        String query = (String)CacheManager.getOrg(QUERY_CACHE_KEY);
        if (query == null) {
            
            Set<String> queryFldSet = new Set<String>();
            for (Schema.FieldSetMember fsm : Schema.SObjectType.Account.fieldSets.ZipCheckOwnerQuery.getFields()) {
                queryFldSet.add(fsm.getFieldPath());
            }
            queryFldSet.addAll(extraQueryFields);
            // add special fields for ownership checks
            queryFldSet.addAll(ZipQueries.getAccountQueryFields());
            /*
for (PaychexSettings__c setting : PaychexSettings__c.getAll().values()) {
if (setting.ProcessName__c == SETTING_ACCT_PROCESS_NAME && setting.isActive__c ) {
queryFldSet.add(setting.Attribute1__c);
}
} // for (PaychexSettings__c setting
*/
            query = DmlHelper.buildQueryFromSet(queryFldSet, null);
            //String[] queryFlds = new String[]{};
            //queryFlds.addAll(queryFldSet);
            //queryFlds.sort();
            //query = 'Select '+String.join(queryFlds,',');
            String[] ctctFlds = new String[]{};
                for (Schema.FieldSetMember fsm : Schema.SObjectType.Contact.fieldSets.ZipCheckOwnerQuery.getFields()) {
                    ctctFlds.add(fsm.getFieldPath());
                }
            query += ',(Select '+String.join(ctctFlds,',')+' from Contacts Where Sales_Contact__c=true) ';
            query += ATM_QUERY;
            query += ' from Account ';
            System.debug('getAcctQuery query='+query);
            CacheManager.putOrg(QUERY_CACHE_KEY,query);
        }
        return query;
    } // getAcctQuery
    
    // used to just pull up the contact and account team member info
    public static String getAcctQuery2() {
        String query = (String)CacheManager.getOrg(QUERY_CACHE_KEY+'2');
        if (query == null) {
            
            Set<String> queryFldSet = new Set<String>();
            queryFldSet.add('Id');
            queryFldSet.add('Name');
            String[] queryFlds = new String[]{};
                queryFlds.addAll(queryFldSet);
            query = 'Select '+String.join(queryFlds,',');
            String[] ctctFlds = new String[]{};
                for (Schema.FieldSetMember fsm : Schema.SObjectType.Contact.fieldSets.ZipCheckOwnerQuery.getFields()) {
                    ctctFlds.add(fsm.getFieldPath());
                }
            query += ',(Select '+String.join(ctctFlds,',')+' from Contacts Where Sales_Contact__c=true) ';
            query += ATM_QUERY;
            query += ' from Account ';
            System.debug('getAcctQuery query='+query);
            CacheManager.putOrg(QUERY_CACHE_KEY+'2',query);
        }
        return query;
    } // getAcctQuery2
    
    // Get all of the accounts.
    public static List<Account> getAccounts(List<Id> acctIds,Set<String> recordTypeIds) {
        String query = getAcctQuery();
        
        String paychexComp = UserHelper.PAYCHEX_COMP;
        
        query +=  ' where Id in :acctIds and Name != :paychexComp';
        if (recordTypeIds != null) {
            query += '       and RecordTypeId in :recordTypeIds ';
        }
        System.debug('getAccounts query='+query);
        List<Account> allAccts = Database.query(query);
        return allAccts;
    } // getAccounts
    
    private static Set<String> salesOrgFilterSet = null;
    
    /** Retrieve all of the zip assignments for the passed in zip codes.
*/
    public static Map<String,List<Zip_Assignment__c>> getZipAsgns(Set<String> queryKeys) { 
        return getZipAsgns(queryKeys, null);
    }
    public static Map<String,List<Zip_Assignment__c>> getZipAsgns(Set<String> queryKeys, String filterName) { 
        Map<String,List<Zip_Assignment__c>> zipAsgnMap = ZipQueries.getZipAsgnMap(queryKeys,true,salesOrgFilterSet,filterName);
        // reset the filter if it was set.
        salesOrgFilterSet = null;
        return zipAsgnMap;
    } // getZipAsgns
    
    public static Map<String,Set<String>> defaultRtNameByObjectMap = null;
    
    // get the "default" record type names for an object. 
    public static Set<String> getDefaultRecordTypes(String objectName) {
        if (defaultRtNameByObjectMap == null) {
            defaultRtNameByObjectMap = new Map<String,Set<String>>();
            for (RecordType__c rt : RecordType__c.getAll().values()) {
                if (rt.UseforDefault__c && String.isNotBlank(rt.ObjectName__c)) {
                    Set<String> rtSet = (defaultRtNameByObjectMap.containsKey(rt.ObjectName__c) ? defaultRtNameByObjectMap.get(rt.ObjectName__c) : new Set<String>());
                    rtSet.add(rt.RecordTypeName__c);
                    defaultRtNameByObjectMap.put(rt.ObjectName__c, rtSet);
                }
            } // for (RecordType__c rt
        } // if (defaultRtNameByObjectMap == null
        Set<String> defaultRtSet = defaultRtNameByObjectMap.get(objectName);
        if (Test.isRunningTest() && defaultRtSet == null) {
            defaultRtSet = new Set<String>{RecordTypeHelper.CORE_ACCOUNT, RecordTypeHelper.MMS_ACCOUNT};
                }
        return defaultRtSet;
    } // getDefaultRecordTypes
    
    // Check the owner fields to see if they've changed.
    // @return true if a change was made to the account
    private static boolean checkAccount(Account acct, List<Zip_Assignment__c> zaList, List<Contact> updateCtcts
                                        ,AccountTeamMember[] insertAcctTeams, AccountTeamMember[] deleteAcctTeams
                                        ,Map<String,User> userByPersonIdMap) {
                                            // get a map of the team members
                                            Map<String,AccountTeamMember> atmMap = getAtmMap(acct, deleteAcctTeams);
                                            
                                            return checkAccount(acct, zaList, updateCtcts,insertAcctTeams, deleteAcctTeams,userByPersonIdMap, atmMap, acct.Contacts);
                                        } // checkAccount                      
    
    // once we find a match to an owner field, we don't need to check it again - try to save a little bit on processing since there are so many segments.
    public static Set<String> ownerFieldMatched = new Set<String>();
    
    private static boolean checkAccount(Account acct, List<Zip_Assignment__c> zaList, List<Contact> updateCtcts
                                        ,AccountTeamMember[] insertAcctTeams, AccountTeamMember[] deleteAcctTeams
                                        ,Map<String,User> userMap, Map<String,AccountTeamMember> atmMap
                                        ,Contact[] ctcts) {
                                            ownerFieldMatched.clear();
                                            boolean isChanged = false;
                                            
                                            // default to 1 if no employees
                                            Integer empCount = (acct.NumberOfEmployees != null ? acct.NumberOfEmployees : 1);
                                            // default to 0 if no assets
                                            Long assetAmt = (acct.X401K_Assets__c != null ? acct.X401K_Assets__c.longValue() : 0);
                                            
                                            // this was done before we entered this code
                                            //isChanged = checkAcctHoldOuts(acct, null, null);
                                            
                                            System.debug('checkAccount acct='+acct.Name+' empCount='+empCount+' zaList='+(zaList != null ? zaList.size() : -1)+' isChanged='+isChanged);
                                            
                                            // this is to make sure all of the owner fields and team roles are handled. 
                                            // If one isn't handled for a zip code, clear that value after going through all of the zip assignments. 
                                            Set<String> ownerFieldSet = new Set<String>();
                                            Set<String> teamRoleSet = new Set<String>();
                                            
                                            // loop through the zip codes returned
                                            if (zaList != null) {
                                                Boolean matchFound = false;
                                                for (Zip_Assignment__c za : zaList) {
                                                    if (za.Zip_Segment__c != null) {
                                                        isChanged = (checkAccountSegment(acct, za, za.Zip_Segment__r, empCount, assetAmt, atmMap, ownerFieldSet,teamRoleSet ,insertAcctTeams,deleteAcctTeams) || isChanged);
                                                        for (ZipAssignmentFallback__c fallback : za.ZipAssignmentFallbacks__r) {
                                                            isChanged = (checkAccountSegment(acct, za, fallback.ZipSegment__r, empCount, assetAmt, atmMap, ownerFieldSet,teamRoleSet ,insertAcctTeams,deleteAcctTeams) || isChanged);
                                                        }
                                                    } // if (za.Zip_Segment__c != null
                                                } // for (Zip_Assignment__c
                                            } // if (zaList != null
                                            
                                            // only check the contacts if the account is changed
                                            System.debug('checkAccount acct name='+acct.Name+' isChanged='+isChanged);
                                            
                                            verifyContactAcctTeams(acct, insertAcctTeams, deleteAcctTeams, atmMap, userMap);
                                            verifyPersonIdAcctTeams(acct, insertAcctTeams, deleteAcctTeams, atmMap, userMap);
                                            
                                            // always check if the owners match
                                            checkContacts(acct,ctcts,updateCtcts,userMap);
                                            
                                            if (acct.Use_Zip_Assignment_Rules__c) {
                                                isChanged = true;
                                                acct.Use_Zip_Assignment_Rules__c = false;
                                            } // 
                                            
                                            return isChanged;
                                        } // checkAccount
    
    public static Boolean checkAccountSegment(Account acct, Zip_Assignment__c za, Zip_Segment__c seg, Integer empCount, Long assetAmt
                                              ,Map<String,AccountTeamMember> atmMap
                                              ,Set<String> ownerFieldSet, Set<String> teamRoleSet
                                              ,AccountTeamMember[] insertAcctTeams, AccountTeamMember[] deleteAcctTeams) {
                                                  if (seg == null) {
                                                      return false;
                                                  }
                                                  
                                                  System.debug('checkAccountSegment segment='+seg.Name);
                                                  String holdOutFieldName = seg.AcctHoldOutFldName__c;
                                                  Boolean hasHoldOut = (String.isNotBlank(holdOutFieldName) ? (Boolean)acct.get(holdOutFieldName) : false);
                                                  String ownerFieldName = seg.AcctOwnerFldName__c;
                                                  String teamRoleName = seg.TeamRole__c;
                                                  String holdOutReasonFldName = seg.AcctHoldOutReasonFld__c;
                                                  String holdOutReasonFldValue = seg.AcctHoldOutReasonValue__c;
                                                  
                                                  // add the names to the sets so we can keep track of them - make sure we're handling them one way or the other.
                                                  if (String.isNotBlank(ownerFieldName)) {
                                                      ownerFieldSet.add(ownerFieldName);
                                                  }
                                                  if (String.isNotBlank(teamRoleName)) {
                                                      teamRoleSet.add(teamRoleName);
                                                  }
                                                  Boolean ownerHandled = (String.isBlank(ownerFieldName) || ownerFieldMatched.contains(ownerFieldName));
                                                  Boolean teamhandled = (String.isBlank(teamRoleName) || ownerFieldMatched.contains(teamRoleName));
                                                  
                                                  System.debug('checkAccountSegment acct='+acct.Name+' hasHoldOut='+hasHoldOut+' ownerFieldName='+ownerFieldName+' holdOutFieldName='+holdOutFieldName+' ownerHandled='+ownerHandled+' teamhandled='+teamhandled+' za='+za);
                                                  // if the hold out is set and there isn't a local owner field we're not going to do anything further with this record
                                                  if ((hasHoldOut && String.isBlank(ownerFieldName)) || (ownerHandled && teamhandled))  {
                                                      return false;
                                                  }
                                                  Boolean isChanged = false;
                                                  
                                                  // Need to match the record types from the segment.
                                                  Boolean okayToUse = (String.isNotBlank(seg.AccountRecordTypeIds__c) && seg.AccountRecordTypeIds__c.contains(acct.recordTypeId));
                                                  System.debug('checkAccountSegment okayToUse='+okayToUse);
                                                  // 
                                                  if (okayToUse) {        
                                                      // make sure we're on the right segment to use the team member role
                                                      if (checkZipCriteria(za, seg, acct, empCount, assetAmt)) {
                                                          System.debug('checkAccount meets criteria hasHoldOut='+hasHoldOut+' ownerFieldName='+ownerFieldName);
                                                          // if we find a match, we don't want to process for the same one again
                                                          if (String.isNotBlank(ownerFieldName)) {
                                                              ownerFieldMatched.add(ownerFieldName); 
                                                          }
                                                          if (String.isNotBlank(teamRoleName)) {
                                                              ownerFieldMatched.add(teamRoleName); 
                                                          }
                                                          // if it has a hold out and an account owner field, use the current owner and check the account team
                                                          if (hasHoldOut) {
                                                              if (String.isNotBlank(ownerFieldName)) {
                                                                  // use the owner from the account 
                                                                  Id ownerid = (Id)acct.get(ownerFieldName);
                                                                  checkAccountTeam(acct,ownerid,null,teamRoleName, insertAcctTeams, deleteAcctTeams, atmMap); 
                                                              } // if (String.isNotBlank(ownerFieldName
                                                          } else if (String.isNotBlank(ownerFieldName)) {
                                                              // the main owner field is required
                                                              isChanged = setOwnerField(isChanged, za, acct, ownerFieldName, true, (ownerFieldName == ObjectHelper.OWNER_FIELD), atmMap, insertAcctTeams, deleteAcctTeams);
                                                              if(isChanged && String.isNotBlank(holdOutReasonFldName) && String.isNotBlank(holdOutReasonFldValue)){
                                                                  acct.put(holdOutFieldName,true);
                                                                  acct.put(holdOutReasonFldName,holdOutReasonFldValue);
                                                              }
                                                          } else if (String.isBlank(ownerFieldName) && String.isNotBlank(teamRoleName) && atmMap != null) {
                                                              User zaUser = ((za.User__c != null && za.User__r.IsActive) ? za.User__r : null);
                                                              checkAccountTeam(acct,null,zaUser,teamRoleName, insertAcctTeams, deleteAcctTeams, atmMap);
                                                          } // if (!hasHoldOut
                                                      } else if (seg.HasTeamMember__c && seg.AlwaysAssignTeamMember__c && atmMap != null) {
                                                          // if the criteria isn't met, but we're supposed to always set the team member (based on a setting on the zip segment)
                                                          System.debug('checkAccount in the AlwaysAssignTeamMember__c section');
                                                          User zaUser = ((za.User__c != null && za.User__r.IsActive) ? za.User__r : null);
                                                          checkAccountTeam(acct,null,zaUser,teamRoleName, insertAcctTeams, deleteAcctTeams, atmMap);
                                                      } else {
                                                          System.debug('checkAccount no conditions met!');
                                                      } // if (checkZipCriteria
                                                  } // if (okayToUse
                                                  return isChanged;
                                              } // checkAccountSegment
    
    public static String JOIN_NONE='(NONE)';
    public static String JOIN_EMPS='(EMPS)';
    public static String JOIN_ASSETS='(ASSETS)';
    public static String JOIN_OR='(OR)';
    public static String JOIN_AND='(AND)';
    public static String JOIN_BOOLEAN1='(BOOLEAN1)';
    public static String JOIN_BOOLEAN2='(BOOLEAN2)';
    public static String CRITERIA='(C:';
    
    public static Boolean hasEmps = false;
    public static Boolean hasAssets = false;
    public static Boolean hasBoolean1 = false;
    public static Boolean hasBoolean2 = false;
    public static Boolean hasOtherCriteria = false;
    
    public static Boolean isOr = null;
    public static Boolean isAnd = null;
    public static Boolean noJoin = null;
    
    public static Map<String,ZipSegmentCriteria__c> criteriaMap = new Map<String,ZipSegmentCriteria__c>();
    
    public static String getJoinCriteria(Zip_Assignment__c za) {
        return getJoinCriteria(za,za.Zip_Segment__r);
    } // getJoinCriteria
    
    public static String getJoinCriteria(Zip_Assignment__c za, Zip_Segment__c zipSeg) {
        criteriaMap.clear();
        Boolean skipJoin = (za != null ? za.SkipJoinCriteria__c : false);
        String joinCriteria = (!skipJoin && zipSeg != null && String.isNotBlank(zipSeg.JoinCriteria__c) ? zipSeg.JoinCriteria__c.toUpperCase() : JOIN_NONE);
        // if there's some criteria we'd normally use but we don't want to just in some cases, check that here.
        //String criteriaToSkip = (!skipJoin && za != null && String.isNotBlank(za.CriteriaToSkip__c) ? za.CriteriaToSkip__c.toUpperCase() : JOIN_NONE);
        //String joinCriteria = ((za != null && !za.SkipJoinCriteria__c && za.Zip_Segment__r != null && String.IsNotBlank(za.Zip_Segment__r.JoinCriteria__c)) ? za.Zip_Segment__r.JoinCriteria__c.toUpperCase() : JOIN_NONE);
        //hasEmps = joinCriteria.contains(JOIN_EMPS) && !criteriaToSkip.contains(JOIN_EMPS);
        //hasAssets = joinCriteria.contains(JOIN_ASSETS) && !criteriaToSkip.contains(JOIN_ASSETS);
        hasEmps = joinCriteria.contains(JOIN_EMPS);
        hasAssets = joinCriteria.contains(JOIN_ASSETS);
        //hasBoolean1 = (joinCriteria.contains(JOIN_BOOLEAN1) && zipSeg != null && String.isNotBlank(zipSeg.Boolean1Field__c) && !criteriaToSkip.contains(JOIN_BOOLEAN1));
        //hasBoolean2 = (joinCriteria.contains(JOIN_BOOLEAN2) && zipSeg != null && String.isNotBlank(zipSeg.Boolean2Field__c) && !criteriaToSkip.contains(JOIN_BOOLEAN2));
        hasBoolean1 = (joinCriteria.contains(JOIN_BOOLEAN1) && zipSeg != null && String.isNotBlank(zipSeg.Boolean1Field__c));
        hasBoolean2 = (joinCriteria.contains(JOIN_BOOLEAN2) && zipSeg != null && String.isNotBlank(zipSeg.Boolean2Field__c));
        
        // look for the custom criteria - put in a map 
        // TODO - do we assume if a criteria is active is it an AND with the process? 
        if (zipSeg.ZipSegmentCriteriaLinks__r != null && !zipSeg.ZipSegmentCriteriaLinks__r.isEmpty()) {
            for (ZipSegmentCriteriaLink__c link : zipSeg.ZipSegmentCriteriaLinks__r) {
                criteriaMap.put(link.ZipSegmentCriteria__r.Name, link.ZipSegmentCriteria__r);
            }
        }
        hasOtherCriteria = (!criteriaMap.isEmpty());
        Integer nbrCriteria = (hasEmps ? 1 : 0) + (hasAssets ? 1 : 0) + (hasBoolean1 ? 1 : 0) + (hasBoolean2 ? 1 : 0) + criteriaMap.size();
        if (nbrCriteria == 0) {
            joinCriteria = JOIN_NONE;
        }
        
        isOr = (nbrCriteria > 1 && joinCriteria.contains(JOIN_OR));
        isAnd = (nbrCriteria > 1 && joinCriteria.contains(JOIN_AND));
        noJoin = (nbrCriteria <= 1 || (!isOr && !isAnd));
        //System.debug('getJoinCriteria za='+(za != null ? za.Query_Key__c : 'none')+' zipSeg='+(zipSeg != null ? zipSeg.Name : 'none')+' skipJoin='+skipJoin+' hasEmps='+hasEmps+' hasAssets='+hasAssets+' hasBoolean1='+hasBoolean1+' hasBoolean2='+hasBoolean2+' isOr='+isOr+' isAnd='+isAnd+' noJoin='+noJoin+' joinCriteria='+joinCriteria+' criteriaToSkip='+criteriaToSkip);
        System.debug('getJoinCriteria za='+(za != null ? za.Query_Key__c : 'none')+' zipSeg='+(zipSeg != null ? zipSeg.Name : 'none')+' skipJoin='+skipJoin+' hasEmps='+hasEmps+' hasAssets='+hasAssets+' hasBoolean1='+hasBoolean1+' hasBoolean2='+hasBoolean2+' isOr='+isOr+' isAnd='+isAnd+' noJoin='+noJoin+' joinCriteria='+joinCriteria+' hasOtherCriteria='+hasOtherCriteria+' criteriaMap='+criteriaMap.size());
        return joinCriteria;
    } // getJoinCriteria
    
    /*
// return a set of all of the criteria that are set to true
public static Set<String> getJoinCriteriaSet() {
Set<String> criteriaSet = new Set<String>();
if (hasEmps) {
criteriaSet.add(JOIN_EMPS);
}
if (hasAssets) {
criteriaSet.add(JOIN_ASSETS);
}
if (hasBoolean1) {
criteriaSet.add(JOIN_BOOLEAN1);
}
if (hasBoolean2) {
criteriaSet.add(JOIN_BOOLEAN2);
}
return criteriaSet;
} // getJoinCriteriaSet
*/
    public static Boolean checkZipCriteria(Zip_Assignment__c za, Integer numEmployees, Long assetAmt) {      
        return checkZipCriteria(za,za.Zip_Segment__r,null,numEmployees,assetAmt);
    } // checkZipCriteria
    
    
    public static Boolean checkZipCriteria(Zip_Assignment__c za, SObject rec, Integer numEmployees, Long assetAmt) {
        return checkZipCriteria(za,za.Zip_Segment__r,rec,numEmployees,assetAmt);
    } // checkZipCriteria
    
    public static Boolean checkZipCriteria(Zip_Assignment__c za, Zip_Segment__c zipSeg, SObject rec, Integer numEmployees, Long assetAmt) {
      System.debug('checkZipCriteria zipSeg='+(zipSeg != null));
      if (zipSeg == null) {
         return false;
      }
      Boolean criteriaMet = true;
      Boolean isAccount = (rec!=null && rec.getSObjectType() == Account.sObjectType);
      Boolean isLead = (rec!=null && rec.getSObjectType() == Lead.sObjectType);
      Boolean isRefAcct = (rec!=null && rec.getSObjectType() == Referral_Account__c.sObjectType);
      System.debug('checkZipCriteria numEmployees='+numEmployees+' isAccount='+isAccount+' isLead='+isLead+' isRefAcct='+isRefAcct); 
       
       if (isAccount) {
         if (String.isNotBlank(zipSeg.AccountSalesOrg__c)) {
            String[] salesOrgs = zipSeg.AccountSalesOrg__c.split(';');  
            if (salesOrgs != null && !salesOrgs.isEmpty()) {
               Account acct = (Account)rec;
               // account sales org should always be populated. 
               criteriaMet = (String.isBlank(acct.AccountSalesOrg__c) || (String.isNotBlank(acct.AccountSalesOrg__c) && salesOrgs.contains(acct.AccountSalesOrg__c)));
            }
         }
         Boolean acctSegmentationOkay = true;
         Boolean clientTypeOkay = true;
         Boolean evaluateSegmentation = String.isNotBlank(zipSeg.Account_Segmentation_Type_Multi__c) && !zipSeg.Account_Segmentation_Type_Multi__c.contains('All');
            String acctType = (String)rec.get('Type');
            system.debug('criteriaMet'+criteriaMet+'evaluateSegmentation'+evaluateSegmentation+'zipSeg.Account_Segmentation_Type_Multi__c'+zipSeg.Account_Segmentation_Type_Multi__c);
            if (criteriaMet && evaluateSegmentation) {
                Boolean currentClient = (Boolean)rec.get('CurrentClient__c');
                Boolean lostClient = (Boolean)rec.get('LostClient__c'); 
                String[] acctSegments = zipSeg.Account_Segmentation_Type_Multi__c.split(';');
                //criteriaMet = ((lostClient && acctSegments.contains(TYPE_LOSTCLIENT))
                acctSegmentationOkay = ((lostClient && acctSegments.contains(TYPE_LOSTCLIENT))
                                        || (currentClient && acctSegments.contains(TYPE_CLIENT))
                                        || (!currentClient && !lostClient && acctSegments.contains(TYPE_PROSPECT)));
                System.debug('checkZipCriteria checking Account currentClient='+currentClient+' lostClient='+lostClient+' segmentation='+zipSeg.Account_Segmentation_Type_Multi__c+'zipSeg.ClientType__c==='+zipSeg.ClientType__c+'acctSegmentationOkay==='+acctSegmentationOkay+'zipSeg.ClientTypeOperand__c==='+zipSeg.ClientTypeOperand__c);
            }
            if (criteriaMet && String.isNotBlank(zipSeg.ClientType__c) && zipSeg.ClientTypeOperand__c!=null) {
                if (evaluateSegmentation) {
                    String[] clientTypes = zipSeg.ClientType__c.split(',');
                    clientTypeOkay = clientTypes.contains(acctType);
                    system.debug('clientTypeOkay'+clientTypeOkay);
                    // use the ClientTypeOperand__c 
                    // based on the operand, would be contains or not contains
                    if(zipSeg.ClientTypeOperand__c.contains('OR')){ 
                        criteriaMet = criteriaMet && (acctSegmentationOkay || clientTypeOkay);
                        system.debug('criteriaMetOR'+clientTypeOkay);
                    }
                    //APR0164310: Added else if for Client Type Operand Not Equals
                 	else if(zipSeg.ClientTypeOperand__c.contains('NOT EQUALS')){
                      	criteriaMet = criteriaMet && acctSegmentationOkay && !clientTypeOkay; 
                    }
                    else if(zipSeg.ClientTypeOperand__c.contains('AND')){ 
                    	criteriaMet = criteriaMet && acctSegmentationOkay && clientTypeOkay;
                    	system.debug('criteriaMetAND'+clientTypeOkay);
                    }
                }
            } 
            else
                criteriaMet = criteriaMet && acctSegmentationOkay && clientTypeOkay;
        } else if (isLead) {
            if (criteriaMet && String.isNotBlank(zipSeg.Account_Segmentation_Type_Multi__c)) {
                criteriaMet = zipSeg.Account_Segmentation_Type_Multi__c.contains(TYPE_PROSPECT);
                System.debug('checkZipCriteria checking Lead segmentation='+zipSeg.Account_Segmentation_Type_Multi__c);
            }
        } 
        String joinCriteria = getJoinCriteria(za, zipSeg);
        
        //Boolean otherCriteriaOkay = !hasOtherCriteria;
        // if there's other criteria, that will always be included and has to be met before any other criteria
        System.debug('checkZipCriteria criteriaMet='+criteriaMet+' hasOtherCriteria='+hasOtherCriteria);
      if (hasOtherCriteria) {
         criteriaMet = checkOtherCriteria(rec, zipSeg, criteriaMet);
          if (criteriaMet && otherCriteriaIsOr) {
             return true;
          }
      }
        
        if (!criteriaMet) {
            System.debug('checkZipCriteria exiting before joinCriteria with criteriaMet='+criteriaMet);
            return false;
        }
        
        // Make sure there is join criteria - if NONE, then skip the checks
        if (!joinCriteria.contains(ZipCheckOwner.JOIN_NONE)) {
            // change to false - see if we meet the criteria
            criteriaMet = false;
            Boolean empsOkay = !hasEmps;
            Boolean assetsOkay = !hasAssets;
            Boolean boolean1Okay = !hasBoolean1;
            Boolean boolean2Okay = !hasBoolean2;
            
            if (!criteriaMet && hasBoolean1 && rec != null) {
                Boolean fldValue = (Boolean)rec.get(zipSeg.Boolean1Field__c);
                boolean1Okay = (fldValue != null && fldValue == zipSeg.Boolean1True__c);
                criteriaMet = (boolean1Okay && (isOr || noJoin)); 
                //System.debug('checkZipCriteria criteriaMet='+criteriaMet+' boolean1Okay='+boolean1Okay+' fldValue='+fldValue+' za.Zip_Segment__r.Boolean1True__c='+za.Zip_Segment__r.Boolean1True__c);
            } // if (rec != null && hasBoolean1
            
            if (!criteriaMet && hasBoolean2 && rec != null) {
                Boolean fldValue = (Boolean)rec.get(zipSeg.Boolean2Field__c);
                boolean2Okay = (fldValue != null && fldValue == zipSeg.Boolean2True__c);
                criteriaMet = (boolean2Okay && (isOr || noJoin));
                //System.debug('checkZipCriteria criteriaMet='+criteriaMet+' boolean2Okay='+boolean2Okay+' fldValue='+fldValue+' za.Zip_Segment__r.Boolean2True__c='+za.Zip_Segment__r.Boolean2True__c);
            } // if (rec != null && hasBoolean2
            
            if (!criteriaMet && hasEmps) {
                if (numEmployees == null) {
                    numEmployees = 0;
                }
                
                // if employee range does not match, do not proceed
                empsOkay = (numEmployees >= zipSeg.Emps_Min__c && numEmployees <= zipSeg.Emps_Max__c);
                //System.debug('checkZipCriteria emp range empsOkay='+empsOkay+' numEmployees='+numEmployees+' min='+za.Zip_Segment__r.Emps_Min__c+' max='+za.Zip_Segment__r.Emps_Max__c);
                
                // if criteris is EMPS OR ASSETS matching, check to see if emps is true then don't need to continue
                // if emps only, and no AND then also don't need to continue 
                criteriaMet = (empsOkay && (isOr || noJoin));
            } // if (joinCriteria.contains(JOIN_EMPS))
            
            if (!criteriaMet && hasAssets) {
                if (assetAmt == null) {
                    assetAmt = 0;
                }
                // if employee range does not match, do not proceed
                assetsOkay = (assetAmt >= zipSeg.Asset_Min__c && assetAmt <= zipSeg.Asset_Max__c);
                //System.debug('checkZipCriteria asset range assetsOkay='+assetsOkay);
                
                criteriaMet = (assetsOkay && (isOr || noJoin));
            } // if (empCntFieldName != null
            
            if (!criteriaMet && isAnd) {
                // try without the Boolean fields
                criteriaMet = ((!hasBoolean1 && !hasBoolean2 && hasEmps && empsOkay && hasAssets && assetsOkay));
                // try with boolean1 field
                if (!criteriaMet && hasBoolean1 && boolean1Okay && !hasBoolean2) {
                    criteriaMet = ((hasEmps && empsOkay && hasAssets && assetsOkay)
                                   || (hasEmps && empsOkay && !hasAssets)
                                   || (!hasEmps && hasAssets && assetsOkay)
                                  );
                } // if (!criteriaMet && hasBoolean1
                
                // try with boolean2 field
                if (!criteriaMet && !hasBoolean1 && hasBoolean2 && boolean2Okay) {
                    criteriaMet = ((hasEmps && empsOkay && hasAssets && assetsOkay)
                                   || (hasEmps && empsOkay && !hasAssets)
                                   || (!hasEmps && hasAssets && assetsOkay)
                                  );
                } // if (!criteriaMet && hasBoolean1
                
                // try with both boolean fields
                if (!criteriaMet && hasBoolean1 && boolean1Okay && hasBoolean2 && boolean2Okay) {
                    criteriaMet = ((hasEmps && empsOkay && hasAssets && assetsOkay)
                                   || (hasEmps && empsOkay && !hasAssets)
                                   || (!hasEmps && hasAssets && assetsOkay)
                                   || (!hasEmps && !hasAssets)
                                  );
                } // if (!criteriaMet && hasBoolean1
                
            } // if (!criteriaMet && isAnd
            System.debug('checkZipCriteria criteriaMet='+criteriaMet+' boolean1Okay='+boolean1Okay+' boolean2Okay='+boolean2Okay+' empsOkay='+empsOkay+' assetsOkay='+assetsOkay);
        } // if (joinCriteria.contains
        return criteriaMet;
    } // checkZipCriteria
    
    /*
    Criteria1 - Field1=true1, join segment type AND
    Criteria2 - Field2=true, linked to Criteria 1, AND join
     ZipSegment AND (Criteria1 AND Criteria2)

    is it easier to enforce all linked to one parent, versus a chain? You can't link to a criteria that is already linked to another criteria?
    So this wouldn't be valid
    Criteria1 - Field1=true, join segment type AND
    Criteria2 = Field2=false, linked to Criteria 1, OR join
    Criteria3 = Field3=true, linked to Criteria 2, OR join
     ** have to have the same join type within a grouping  **
      ZipSegment AND (Criteria1 OR Criteria2 OR Criteria3)

    Have the criteria linked to a single parent, easier to group them. All will have the same join type. Use the parent?
    Criteria1 - Field1=true, join segment type AND
    Criteria2 = Field2=false, linked to Criteria 1, OR join
    Criteria3 = Field3=true, linked to Criteria 1, OR join
     ** have to have the same join type within a grouping  **
      ZipSegment AND (Criteria1 OR Criteria2 OR Criteria3)

    Does this really make sense?
    Would this instead have no criteria on the zip segment and do everything in the criteria?
    Criteria1 Field1=true, join segment type AND
    Criteria2 Field2=false, join segment type OR
      ZipSegment AND Criteria1 OR Criteria2
    */
    
    public class CriteriaWrap {
       // all of the criteria. The main one as well as all the ones joined
       public ZipSegmentCriteria__c[] allCriteria = new ZipSegmentCriteria__c[]{};
       // how do we connect this with the ZipSegment (assuming it has criteria)
       // if it's false, we assume an OR
       public Boolean segmentJoinIsAnd=true;
       // if there are other criteria linked to this one, they will be controlled by the parent.
       // if it's false, we assume an OR
       public Boolean linkJoinIsAnd=true;
       // is all the criteria met? If this is an AND, parent and children have to be true
       // if this is an OR, only one has to be true
       public Boolean criteriaMet=false;
    } // class CriteriaWrap

    public static Boolean checkOtherCriteria(SObject rec, Zip_Segment__c zipSeg) {
       return checkOtherCriteria(rec,zipSeg,true);
    }
    
    public static Boolean otherCriteriaIsOr = false;
    
    // pass in the current criteriaMet value from the calling method
    public static Boolean checkOtherCriteria(SObject rec, Zip_Segment__c zipSeg, Boolean p_criteriaMet) {
       otherCriteriaIsOr = false;
       Map<Id,CriteriaWrap> results = checkOtherCriteria2(rec,zipSeg);
       Boolean criteriaMet = p_criteriaMet;
       for (CriteriaWrap result : results.values()) {
          // need to check this to make sure any criteria actually came back as a match
          if (!result.allCriteria.isEmpty()) {
             if (result.segmentJoinIsAnd) {
                criteriaMet = (criteriaMet && result.criteriaMet);
             } else {
                otherCriteriaIsOr = true;
                criteriaMet = (criteriaMet || result.criteriaMet);
             }
          }
            
       } // for (CriteriaWrap result
       System.debug('checkOtherCriteria results='+results.size()+' p_criteriaMet='+p_criteriaMet+' criteriaMet='+criteriaMet);
       return criteriaMet;
    } // checkOtherCriteria
    
    public static Map<Id,CriteriaWrap> checkOtherCriteria2(SObject rec, Zip_Segment__c zipSeg) {
       System.debug('checkOtherCriteria links='+(zipSeg.ZipSegmentCriteriaLinks__r != null ? zipSeg.ZipSegmentCriteriaLinks__r.size() : -1) );
       Map<Id,CriteriaWrap> checkCriteriaMap = new Map<Id,CriteriaWrap>();
       if (zipSeg.ZipSegmentCriteriaLinks__r != null && !zipSeg.ZipSegmentCriteriaLinks__r.isEmpty()) {
          Boolean isAccount = (rec!=null && rec.getSObjectType() == Account.sObjectType);
          Boolean isLead = (rec!=null && rec.getSObjectType() == Lead.sObjectType);
          Boolean isRefAcct = (rec!=null && rec.getSObjectType() == Referral_Account__c.sObjectType);
          checkCriteriaMap = checkOtherCriteria(rec, zipSeg, isAccount, isLead, isRefAcct);
       } // if (zipSeg.ZipSegmentCriteriaLinks__r
 
       return checkCriteriaMap;
    } // checkOtherCriteria
    
    public static Map<Id,CriteriaWrap> checkOtherCriteria(SObject rec, Zip_Segment__c zipSeg, Boolean isAccount, Boolean isLead, Boolean isRefAcct) {
       System.debug('checkOtherCriteria links='+(zipSeg.ZipSegmentCriteriaLinks__r != null ? zipSeg.ZipSegmentCriteriaLinks__r.size() : -1) );
       Map<Id,CriteriaWrap> checkCriteriaMap = new Map<Id,CriteriaWrap>();
       if (zipSeg.ZipSegmentCriteriaLinks__r != null && !zipSeg.ZipSegmentCriteriaLinks__r.isEmpty()) {
          ZipSegmentCriteriaLink__c[] childLinks = new ZipSegmentCriteriaLink__c[]{};
          // first check for the "parent" links
          checkLinks(rec, zipSeg.ZipSegmentCriteriaLinks__r, true
                                   ,isAccount, isLead, isRefAcct
                                   ,checkCriteriaMap, childLinks);
          if (!checkCriteriaMap.isEmpty() && !childLinks.isEmpty()) {
             // if the childLinks list has records, process them 
             checkLinks(rec, childLinks, false
                                   ,isAccount, isLead, isRefAcct
                                   ,checkCriteriaMap, childLinks);
          }
       } // if (zipSeg.ZipSegmentCriteriaLinks__r
 
       return checkCriteriaMap;
    } // checkOtherCriteria
    
    public static String JOINTYPE_AND='AND';
    public static String JOINTYPE_OR='OR';
    
    public static void checkLinks(SObject rec, ZipSegmentCriteriaLink__c[] links, Boolean checkParent
                                   ,Boolean isAccount, Boolean isLead, Boolean isRefAcct
                                   ,Map<Id,CriteriaWrap> checkCriteriaMap, ZipSegmentCriteriaLink__c[] childLinks) {
       for (ZipSegmentCriteriaLink__c link : links) {
          ZipSegmentCriteria__c criteria = link.ZipSegmentCriteria__r;
          // is this criteria valid for this record?
          Boolean okayToContinue = (criteria.Account__c && isAccount) || (criteria.Lead__c && isLead) || (criteria.ReferralAccount__c && isRefAcct);
          // do this check all the time (especially for the parent) because we want to have a parent record even if it doesn't have any criteria
          // for the record we're on.
          CriteriaWrap checkCriteria = null;
          if (checkParent && link.ZipLinkJoin__c == null) {
             checkCriteria = new CriteriaWrap();
             checkCriteria.segmentJoinIsAnd = (String.isBlank(link.ZipSegmentJoinType__c) || link.ZipSegmentJoinType__c == JOINTYPE_AND);
             checkCriteria.linkJoinIsAnd = (String.isBlank(link.ZipLinkJoinType__c) || link.ZipLinkJoinType__c == JOINTYPE_AND);
             checkCriteriaMap.put(link.Id, checkCriteria);
          } else if (checkParent && link.ZipLinkJoin__c != null) {
             // save the children for processing later during the parent run
             childLinks.add(link);
          } else if (!checkParent && link.ZipLinkJoin__c != null) {
             checkCriteria = checkCriteriaMap.get(link.ZipLinkJoin__c);
          }

          System.debug('checkLinks link='+link.Name+' okayToContinue='+okayToContinue);
          if (okayToContinue && checkCriteria != null) {
             checkCriteria.allCriteria.add(criteria);
             // what do we do if this is null? Shouldn't be the case unless the parent isn't active
             if (rec != null && checkCriteria != null) {
                if ((checkCriteria.criteriaMet && !checkCriteria.linkJoinIsAnd)
                    || (!checkParent && checkCriteria.linkJoinIsAnd && !checkCriteria.criteriaMet)) {
                   // don't need to do anything if:
                   //   it's an OR and criteriaMet is true.
                   //   if it's a child and an AND and criteriaMet is false
                } else {
                   try {
                      Boolean meetsCriteria = evaluateCriteria(rec, criteria);
                      // if it's the parent, just use the value
                      // if it's a child and it's an AND, then join the values.
                      // if it's a child and it's an OR, then the previous value must have been false so just take the new value.
                      checkCriteria.criteriaMet = (checkParent ? meetsCriteria 
                                                   : (checkCriteria.linkJoinIsAnd ? (checkCriteria.criteriaMet && meetsCriteria)
                                                         : meetsCriteria));
                      
                   } catch (Exception e) {
                      System.debug('checkOtherCriteria Exception evaluating criteria: '+e.getMessage()+'; '+e.getStackTraceString());
                   } // try
 
                }
               
             } // if (checkCriteria != null          

          } // if (okayToContinue

          //    criteriaMap.put(link.ZipSegmentCriteria__r.Name, link.ZipSegmentCriteria__r);
       } // for (ZipSegmentCriteriaLink__c link

    } // checkLinks
    /*
    public static Boolean checkOtherCriteria(SObject rec, Zip_Segment__c zipSeg) {
        System.debug('checkOtherCriteria links='+(zipSeg.ZipSegmentCriteriaLinks__r != null ? zipSeg.ZipSegmentCriteriaLinks__r.size() : -1) );
        Boolean criteriaMet = true;
        if (zipSeg.ZipSegmentCriteriaLinks__r != null && !zipSeg.ZipSegmentCriteriaLinks__r.isEmpty()) {
           Boolean isAccount = (rec!=null && rec.getSObjectType() == Account.sObjectType);
           Boolean isLead = (rec!=null && rec.getSObjectType() == Lead.sObjectType);
           Boolean isRefAcct = (rec!=null && rec.getSObjectType() == Referral_Account__c.sObjectType);
           for (ZipSegmentCriteriaLink__c link : zipSeg.ZipSegmentCriteriaLinks__r) {
              ZipSegmentCriteria__c criteria = link.ZipSegmentCriteria__r;
              if ((criteria.Account__c && isAccount) || (criteria.Lead__c && isLead) || (criteria.ReferralAccount__c && isRefAcct)) {
                 try {
                     if (!evaluateCriteria(rec, criteria)) {
                        criteriaMet = false;
                        break;
                     }
                 } catch (Exception e) {
                        System.debug('checkOtherCriteria Exception evaluating criteria: '+e.getMessage()+'; '+e.getStackTraceString());
                        criteriaMet = false;
                        break;
                 }
              } // if ((criteria.Account__c && isAccount)
              criteriaMap.put(link.ZipSegmentCriteria__r.Name, link.ZipSegmentCriteria__r);
          } // for (ZipSegmentCriteriaLink__c link
       } // if (zipSeg.ZipSegmentCriteriaLinks__r
 
       return criteriaMet;
    } // checkOtherCriteria
    */
    public static String CRI_BOOLEAN='Boolean';
    public static String CRI_TEXT='Text';
    public static String CRI_NBR='Number';
    public static String CRI_NBR_RANGE='Number Range';
    public static String OP_EQUALS='Equals';
    public static String OP_NOT_EQUALS='Not Equals';
    public static String OP_GREATER='Greater Than';
    public static String OP_GREATER_EQUALS='Greater Than Equals';
    public static String OP_LESS='Less Than';
    public static String OP_LESS_EQUALS='Less Than Equals';
    
    public static Boolean evaluateCriteria(SObject rec, ZipSegmentCriteria__c criteria) {
        Boolean criteriaMet = false;
        if (criteria.FieldType__c == CRI_BOOLEAN) {
            // if it's a boolean, we're going to assume the operator is always equals.
            Boolean expectedValue = (criteria.Values__c == 'True');
            System.debug('evaluateCriteria checking '+criteria.FieldAPIName__c+' for '+expectedValue);
            criteriaMet = ((Boolean)rec.get(criteria.FieldAPIName__c) == expectedValue);
        } else if (criteria.FieldType__c == CRI_TEXT) {
            // we'll assume it's equals unless it's not equals
            Boolean checkEquals = (criteria.Operator__c != OP_NOT_EQUALS);
            String recValue = (String)rec.get(criteria.FieldAPIName__c);
            System.debug('evaluateCriteria checking '+recValue);
            // if they're both blank, or the value on the record is one of the values on the criteria.
            // For example, Ethnicity could have values HA1,HA2,HA3,HA4
            // Criteria says Ethnicity__c Equals HA1,HA2,HA3,HA4
            // Account has a blank value in Ethnicity, hasValue=false. Account has HA2 in Ethnicity, hasValue=true. Account has Hobbit, hasValue=false
            Boolean hasValue = ((String.isBlank(recValue) && String.isBlank(criteria.Values__c))
                                || (String.isNotBlank(criteria.Values__c) && String.isNotBlank(recValue) && criteria.Values__c.contains(recValue)));
            // if we're checking for an equal value, hasValue should be true. If we're looking for a Not Equals, HasValue should be false.
            criteriaMet = (checkEquals ? hasValue : !hasValue);
            System.debug('evaluateCriteria checkEquals='+checkEquals+' hasValue='+hasValue);
        } else if (criteria.FieldType__c == CRI_NBR) {
            // we'll assume a blank value is zero
            Double recValue = (rec.get(criteria.FieldAPIName__c) != null ? Double.valueOf(rec.get(criteria.FieldAPIName__c)) : 0);
            Double compareValue = Double.valueOf(criteria.Number1__c);
            System.debug('evaluateCriteria checking '+recValue+' against '+compareValue+' with '+criteria.Operator__c);
            criteriaMet = (criteria.Operator__c == OP_EQUALS ? (recValue == compareValue)
                           : (criteria.Operator__c == OP_NOT_EQUALS ? (recValue != compareValue) 
                              : (criteria.Operator__c == OP_GREATER ? (recValue > compareValue)
                                 : (criteria.Operator__c == OP_GREATER_EQUALS ? (recValue >= compareValue)
                                    : (criteria.Operator__c == OP_LESS ? (recValue < compareValue)
                                       : (criteria.Operator__c == OP_LESS_EQUALS ? (recValue <= compareValue) : false))))));
        } else if (criteria.FieldType__c == CRI_NBR_RANGE) {
            // we'll assume a blank value is zero
            Double recValue = (rec.get(criteria.FieldAPIName__c) != null ? Double.valueOf(rec.get(criteria.FieldAPIName__c)) : 0);
            Double compareLow = Double.valueOf(criteria.Number1__c);
            Double compareHigh = Double.valueOf(criteria.Number2__c);
            System.debug('evaluateCriteria checking '+recValue+' against '+compareLow+' and '+compareHigh);
            criteriaMet = (recValue >= compareLow && recValue <= compareHigh);
        }
        System.debug('evaluateCriteria criteriaMet='+criteriaMet);
        return criteriaMet;
    } // evaluateCriteria
    
    /** TEMPORARY until new code is released!
*/
    public static Boolean objectMatchesZip(SObject rec, String objectName, String empCntFieldName, String assetFieldName, Zip_Assignment__c za) {
        return objectMatchesZip(rec, objectName, za, za.Zip_Segment__r, true);
    }
    
    /** Does the object meet the criteria for the incoming Zip_Assignment__c record? 
*/
    //public static Boolean objectMatchesZip(SObject rec, String objectName, String empCntFieldName, String assetFieldName, Zip_Assignment__c za, Boolean checkRecordType) {
    public static Boolean objectMatchesZip(SObject rec, String objectName, Zip_Assignment__c za, Zip_Segment__c seg, Boolean checkRecordType) {
        Boolean okay = false;
        String zaKey = za.Name+'='+(seg != null ? seg.Sales_Org__c+'-'+seg.Name : 'DEFAULT');
        System.debug('objectMatchesZip objectName='+objectName+' checkRecordType='+checkRecordType+' za='+zaKey+' rec: '+rec);
        if (rec != null && String.isNotBlank(objectName)) {
            String empCntFieldName = ObjectHelper.getEmpCntFieldName(objectName);
            String assetFieldName = ObjectHelper.getAssetFieldName(objectName);
            System.debug('objectMatchesZip empCntFieldName='+empCntFieldName+' assetFieldName='+assetFieldName); 
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'objectMatchesZip zipCode='+zaKey+' empCntFieldName='+empCntFieldName+' assetFieldName='+assetFieldName));
            if (checkRecordType && String.isNotBlank(seg.AccountRecordTypes__c)) {
                setupRecordTypeMaps();
                //String recordTypeName = ObjectHelper.getRecordTypeName(objectName, za.Sales_Org__c);
                String[] recordTypeNames = seg.AccountRecordTypes__c.split(';');
                //System.debug('objectMatchesZip za='+zaKey+' recordTypeName='+recordTypeName);
                if (recordTypeNames != null && !recordTypeNames.isEmpty()) {
                    Id recordTypeId = (Id)rec.get('RecordTypeId');
                    Id[] rtIds = new Id[]{};
                        Boolean rtMatch=false;
                    // if there are multiple record types, make sure at least one matches.
                    for (String recordTypeName : recordTypeNames) {
                        Schema.RecordTypeInfo rt = rtByName.get(recordTypeName);
                        if (rt != null && rt.getRecordTypeId() == recordTypeId) {
                            rtMatch = true;
                            break;
                        }
                    } // for
                    if (!rtMatch) {
                        System.debug('objectMatchesZip failed recordType match');
                        return false;
                    }
                } // if (recordTypeName != null
            } // if (checkRecordType
            
            Long assetValue = null;
            if (assetFieldName != null && rec.get(assetFieldName) != null) {
                assetValue = ((Decimal)rec.get(assetFieldName)).longValue();
            }
            System.debug('objectMatchesZip (Integer)rec.get(empCntFieldName): '+(Integer)rec.get(empCntFieldName)); 
            okay = checkZipCriteria(za, seg, rec, (empCntFieldName != null ? (Integer)rec.get(empCntFieldName) : 0), assetValue);
        } // if (rec != null &&
        
        return okay;
    } // objectMatchesZip
    
    
    /* WHOLESALER
Sales_Org__c = HRS WHOLESALER
Segment_Name__c = Internal or External
*/
    
    public static Boolean LOG_ATM_ERRORS=(Label.ZipCheckOwner_Log_ATM_Errors == 'Y'); 
    
    /** Check the account teams on the passed in Accounts to make sure users match.
*/ 
    public static void checkAccountTeams(List<Id> allAcctIds) {
        setupRecordTypeMaps();
        System.debug('checkAccountTeams allAcctIds='+allAcctIds.size()+' rts='+rtById.keySet());
        
        List<Account> allAccts = getAccounts(allAcctIds,rtById.keySet());             
        
        // the Account team members that are created or deleted
        List<AccountTeamMember> insertAcctTeams = new List<AccountTeamMember>();
        List<AccountTeamMember> deleteAcctTeams = new List<AccountTeamMember>();
        
        Map<String,User> userByPersonIdMap = getUserByPersonIdMap(allAccts);
        for (Account acct : allAccts) {
            verifyAcctTeams(acct,insertAcctTeams, deleteAcctTeams, userByPersonIdMap);
        } // for (Account acct
        
        saveAcctTeams(insertAcctTeams,deleteAcctTeams);
    } // checkAccountTeams
    
    // a user can't be on an account team more than once. the keys will be account id + user id so we can check if they already exist.   
    public static Set<String> accountTeamDuplicateCheck = new Set<String>();
    
    public static void saveAcctTeams(List<AccountTeamMember> insertAcctTeams, List<AccountTeamMember> deleteAcctTeams) {
        System.debug('saveAcctTeams insertAcctTeams='+insertAcctTeams.size()+' deleteAcctTeams='+deleteAcctTeams.size());
        if (!deleteAcctTeams.isEmpty()) {
            // verify that they can all still be deleted
            Map<Id,AccountTeamMember> toDeleteMap = new Map<Id,AccountTeamMember>();
            for (AccountTeamMember atm : deleteAcctTeams) {
                if (atm != null && atm.Id != null) {
                    toDeleteMap.put(atm.Id,atm);
                }
            }
            if (!toDeleteMap.isEmpty()) {
                Database.delete(toDeleteMap.values(),false);
            }
        } // if (!deleteAcctTeams.isEmpty
        
        if (!insertAcctTeams.isEmpty()) {
            Database.SaveResult[] srs = Database.insert(insertAcctTeams,false);
            if (LOG_ATM_ERRORS) {
                String errMsg = '';
                for (Integer cnt=0; cnt<insertAcctTeams.size(); cnt++) {
                    Database.SaveResult sr = srs[cnt];
                    if (sr.isSuccess() ) {
                        //System.debug('saveAcctTeams save is successful');
                    } else {
                        AccountTeamMember atm = insertAcctTeams[cnt];
                        for (Database.Error err : sr.getErrors()) {
                            errMsg += '\nError: accountId='+atm.AccountId+' code='+err.getStatusCode()+' msg='+err.getMessage();
                        }
                        //System.debug('saveAcctTeams Save errored: '+errMsg);
                    }
                }
                if (String.isNotBlank(errMsg)) {
                    ErrorLog.logError(CLASSNAME, 'saveAcctTeams', 'insertAcctTeams', null, errMsg, null, true);
                }
            }
        } // if (!insertAcctTeams.isEmpty
        
    } // saveAcctTeams
    
    public static void verifyAcctTeams(Account acct, List<AccountTeamMember> insertAcctTeams, List<AccountTeamMember> deleteAcctTeams, Map<String, User> userByPersonIdMap) { //, Map<String,Id> userMap) {
        Map<String,AccountTeamMember> atmMap = getAtmMap(acct, deleteAcctTeams);
        System.debug('verifyAcctTeams before acctId='+acct.Id+' insertAcctTeams='+insertAcctTeams.size()+' deleteAcctTeams='+deleteAcctTeams.size()+' atmMap='+atmMap.size());
        
        verifyContactAcctTeams(acct, insertAcctTeams, deleteAcctTeams, atmMap, null);
        verifyPersonIdAcctTeams(acct, insertAcctTeams, deleteAcctTeams, atmMap, userByPersonIdMap);
        
        System.debug('verifyAcctTeams after acctId='+acct.Id+' insertAcctTeams='+insertAcctTeams.size()+' deleteAcctTeams='+deleteAcctTeams.size());
    } // verifyAcctTeams
    
    public static void verifyContactAcctTeams(Account acct, List<AccountTeamMember> insertAcctTeams, List<AccountTeamMember> deleteAcctTeams, Map<String,AccountTeamMember> atmMap
                                              , Map<String,User> userMap) {
                                                  User hrg = (acct.HR_Generalist__c != null && userMap != null ? userMap.get(acct.HR_Generalist__c) : null);
                                                  if (hrg == null) {
                                                      hrg = (acct.HR_Generalist__r != null ? acct.HR_Generalist__r.User_Lookup__r : null);                                        
                                                  }
                                                  checkAccountTeam(acct,null,hrg,AT_HRG, insertAcctTeams, deleteAcctTeams, atmMap);
                                                  
                                                  User hrm = (acct.HR_Manager__c != null && userMap != null ? userMap.get(acct.HR_Manager__c) : null);
                                                  if (hrm == null) {
                                                      hrm = (acct.HR_Manager__r != null ? acct.HR_Manager__r.User_Lookup__r : null);                                        
                                                  }
                                                  checkAccountTeam(acct,null,hrm,AT_HRM, insertAcctTeams, deleteAcctTeams, atmMap);
                                              } // verifyContactAcctTeams
    
    public static void verifyPersonIdAcctTeams(Account acct, List<AccountTeamMember> insertAcctTeams, List<AccountTeamMember> deleteAcctTeams, Map<String,AccountTeamMember> atmMap
                                               , Map<String,User> userMap){
                                                   System.debug('verifyPersonIdAcctTeams userMap='+(userMap != null ? userMap.size() : -1));
                                                   User esrUsr = (String.isNotBlank(acct.ESR_Person_Id__c) ? userMap.get(acct.ESR_Person_Id__c) : null);
                                                   checkAccountTeam(acct,null,esrUsr,AT_ESR, insertAcctTeams, deleteAcctTeams, atmMap);
                                               } // verifyPersonIdAcctTeams
    
    
    public static Map<String,User> getUserByPersonIdMap(Account[] accts) {
        String[] personIds = new String[]{};
            for (Account acct : accts) {
                if(String.isNotBlank(acct.ESR_Person_Id__c)){
                    personIds.add(acct.ESR_Person_Id__c);
                }
            } // for (Account acct
        return getUserByPersonIdMap(personIds);
    } // getUserByPersonIdMap
    
    public static Map<String,User> getUserByPersonIdMap (List<String> personIds){
        Map<String,User> userByPersonIdMap = new Map<String,User>(); 
        if(!personIds.isEmpty()){
            system.debug('getUserByPersonIdMap getting users personIds='+personIds.size());
            for(User u : [SELECT Id,Name,HR_Person_Id__c,IsActive FROM User WHERE HR_Person_Id__c in:personIds AND IsActive = true]){
                userByPersonIdMap.put(u.HR_Person_Id__c,u);
            }
        }
        return userByPersonIdMap;
    } // getUserByPersonIdMap
    
    // get a map of the account team by role name
    public static Map<String,AccountTeamMember> getAtmMap(Account acct, List<AccountTeamMember> deleteAcctTeams) {
        Map<String,AccountTeamMember> atmMap = new Map<String,AccountTeamMember>();
        //APR0157517: Added method call for checkAtmRoleSet
        if(acct.Clear_Sales_Team__c){
            AccountJunctionMethods.checkAtmRoleSet();
        }
        if (acct != null && acct.AccountTeamMembers != null && !acct.AccountTeamMembers.isEmpty()) {
            for (AccountTeamMember atm : acct.AccountTeamMembers) {
                Boolean roleInSet = AccountJunctionMethods.atmRolesSet != null && !AccountJunctionMethods.atmRolesSet.isEmpty() && AccountJunctionMethods.atmRolesSet.contains(atm.TeamMemberRole);
                // don't add inactive users
                if (!atm.User.IsActive || (acct.Clear_Sales_Team__c && roleInSet)) {
                    deleteAcctTeams.add(atm);
                } else {
                    atmMap.put(atm.TeamMemberRole, atm);
                    accountTeamDuplicateCheck.add((String)atm.AccountId+(String)atm.UserId);
                }
            } // for (AccountTeamMember atm
        } // if (acct != null
        return atmMap;
    } // getAtmMap
    
    /** Check to make sure the User isn't already a part of the Account Team. If not, add them.

* @param acct - The Account
* @param originalOwner - the Original Owner of the account (the user that will be added as the Account Team Member)
* @param salesOrg - the sales organization of the original owner.
* @param acctType - the type of Account (Core, MMS)
* @param addAcctTeams - the list of Account Team Members that will be inserted.
*/
    public static void checkAccountTeam(Account acct,Id p_userId, User usr,String roleName, List<AccountTeamMember> insertAcctTeams, List<AccountTeamMember> deleteAcctTeams, Map<String,AccountTeamMember> atmMap) {
        if (String.isBlank(roleName) || atmMap == null) {
            return;
        }
        // only active users
        Id userId = ((usr != null && usr.IsActive) ? usr.Id : p_userId);
        
        AccountTeamMember atm = atmMap.get(roleName);
        System.debug('checkAccountTeam acct='+acct.Id+' roleName='+roleName+' userId='+userId+' atm='+(atm != null));
        
        if (atm == null && userId == null) {
            // if no owner id and no role exists do nothing
            return;
        } // if (atm == null && ownerId == null
        
        if (atm != null && userId == null) {
            // there is no longer a user for this role - delete the record
            atmMap.remove(roleName);
            deleteAcctTeams.add(atm);
            accountTeamDuplicateCheck.remove((String)atm.AccountId+(String)atm.UserId);
            
        }
        // you are not allowed to update the AccountTeamMember. So if it changes, delete current and create a new one.
        if (atm != null && userId != null && atm.UserId != userId) {
            atmMap.remove(roleName);
            deleteAcctTeams.add(atm);
            accountTeamDuplicateCheck.remove((String)atm.AccountId+(String)atm.UserId);
            atm = null;
        }
        
        if (userId != null && atm == null) {
            // create a new record
            String key = (String)acct.Id+(String)userId;
            // make sure we don't already have a record for the account/user combination
            if (!accountTeamDuplicateCheck.contains(key)) {
                System.debug('checkAccountTeam acct='+acct.Id+' creating new team member');
                atm = new AccountTeamMember(AccountId=acct.Id, UserId = userId, TeamMemberRole = roleName, AccountAccessLevel='Edit', ContactAccessLevel='Edit', OpportunityAccessLevel='Read');
                // if this is an insert, store for later to save in the after trigger
                if (acct.Id == null) {
                    System.debug('checkAccountTeam adding atm to atmsToInsert');
                    atmsToInsert.add(new AcctTeamInsert(acct,atm));
                } else {
                    accountTeamDuplicateCheck.add((String)atm.AccountId+(String)atm.UserId);
                    if(acct.Clear_Sales_Team__c == null || (acct.Clear_Sales_Team__c != null && acct.Clear_Sales_Team__c == false)){   //APR0157517: added if
                        insertAcctTeams.add(atm);
                    }
                }
                atmMap.put(roleName, atm);
            } else {
                System.debug('checkAccountTeam an account team member already exists for '+acct.Id+' user '+userId);
            }
        } // if (userId != null && atm == null
    } // checkAccountTeam
    
    public static Map<Id, Contact[]> ctctByAcctIdMap = new Map<Id, Contact[]>();
    
    // do we need to set the owner on the contact?
    public static void doWeCheckCtctOwner(Contact ctct, Contact oldCtct) {
        if (ctct.AccountId != null 
            && ((ctct.Sales_Contact__c && oldCtct == null) // set owner on insert
                || (ctct.Sales_Contact__c && oldCtct != null && ctct.Sales_Contact__c != oldCtct.Sales_Contact__c)
                || ctct.Use_Zip_Assignment_Rules__c
                || (oldCtct != null && !ctct.Hold_Out__c && oldCtct.Hold_Out__c)  // if the hold out flag is removed, check the owner
                || (oldCtct != null && ctct.AccountId != oldCtct.AccountId)       // contact was linked to another account
               )
           ) {
               ctct.Use_Zip_Assignment_Rules__c = false;
               Contact[] ctcts = ctctByAcctIdMap.get(ctct.AccountId);
               if (ctcts == null) {
                   ctcts = new Contact[]{};
                       ctctByAcctIdMap.put(ctct.AccountId, ctcts);
               }
               ctcts.add(ctct);
           } // if (ctct.AccountId != null
    } // doWeCheckCtctOwner
    
    // if we're doing a lead convert, the contact owners will be set from the account, so we don't need this to run in that context.
    public static Boolean ALLOW_CONTACT_OWNER_CHECK=true;
    
    public static void checkProcessCtctOwnersBefore() {
        if (ALLOW_CONTACT_OWNER_CHECK && !ctctByAcctIdMap.isEmpty()) {
            processContactOwners();
        }
    } // checkProcessCtctOwners
    
    // the account ids that were already processed - do not process them again.
    public static Set<Id> accountIdsProcessedSet = new Set<Id>();
    
    
    // Check the Contacts, make sure the owners are in line with the zip code.
    private static void processContactOwners() {
        System.debug('processContactOwners nbr accts='+ctctByAcctIdMap.size());
        setupRecordTypeMaps();
        
        accountIdsProcessedSet.addAll(ctctByAcctIdMap.keySet());
        
        Id[] acctIds = new Id[]{};
            acctIds.addAll(ctctByAcctIdMap.keySet());
        List<Account> allAccts = getAccounts(acctIds,null);             
        
        // the contacts that will be updated
        List<Contact> updateCtcts = new List<Contact>();
        
        // loop through all of the accounts
        for (Account acct : allAccts) {
            System.debug('acct='+acct.id);
            checkContacts(acct,ctctByAcctIdMap.get(acct.Id),updateCtcts, null);
        } // if (!checkZips
        
    } // processContactOwners
    
    /** Get the correct record type to use when setting the contact record, based on the accout.
*  If the account is a Core Record Type, the contacts should also be a Core record type. 
*/
    private static Schema.RecordTypeInfo getCtctRecordType(Account acct) {
        
        Schema.RecordTypeInfo ctctRT = null;
        
        Schema.RecordTypeInfo acctRT = rtById.get(acct.RecordTypeId);
        System.debug('getCtctRecordType acct='+acct.Name+' acctRT='+acctRT);
        if (acctRT != null) {
            if (acctRT.getName() == RecordTypeHelper.MMS_ACCOUNT) {
                System.debug('getCtctRecordType MMS Record Type');
                ctctRT = rtByName.get(RecordTypeHelper.MMS_CONTACT);
            } else if (acctRT.getName() == RecordTypeHelper.CORE_ACCOUNT) {
                System.debug('getCtctRecordType Core Record Type');
                ctctRT = rtByName.get(RecordTypeHelper.CORE_CONTACT);
            }
        } // if (acctRT != null)
        // to make sure only valid record types get this far.
        System.debug('getCtctRecordType ctctRT='+ctctRT);
        return ctctRT;
    } // getCtctRecordType
    
    public static String MAP_CACHE_KEY='ZipCheckOwneracctToCtctMap';
    
    // get a map of the custom account owner fields to the custom contact owner fields
    public static Map<String,String> getAcctOwnerMap() {
        Map<String,String> acctToCtctMap = (Map<String,String>)CacheManager.getOrg(MAP_CACHE_KEY);
        if (acctToCtctMap == null) {
            acctToCtctMap = new Map<String,String>();
            Zip_Segment__c[] segments = ZipQueries.getAllSegments();
            for (Zip_Segment__c segment : segments) {
                if (String.isNotBlank(segment.AcctOwnerFldName__c) && !acctToCtctMap.containsKey(segment.AcctOwnerFldName__c) && String.isNotBlank(segment.CtctOwnerFldName__c)) {
                    acctToCtctMap.put(segment.AcctOwnerFldName__c,segment.CtctOwnerFldName__c);
                }
            }
            CacheManager.putOrg(MAP_CACHE_KEY,acctToCtctMap);
        }
        return acctToCtctMap;
    } // getAcctOwnerMap
    
    /** Check to see if the record type and ownership of the contacts matches the account.
*/
    public static void checkContacts(Account acct, Contact[] ctcts, Contact[] updateCtcts) {
        checkContacts(acct, ctcts, updateCtcts, null);
    } // checkContacts
    public static void checkContacts(Account acct, Contact[] ctcts, Contact[] updateCtcts, Map<String,User> userMap) {
        System.debug('checkContacts');
        if (ctcts == null) {
            System.debug('checkContacts ctcts='+ctcts);
            return;
        } 
        Schema.RecordTypeInfo newCtctRT = getCtctRecordType(acct);
        System.debug('checkContacts nbrContacts='+ctcts.size()+' newCtctRT='+newCtctRT);
        for (Contact ctct : ctcts) {
            boolean isChanged = false;
            
            Schema.RecordTypeInfo ctctRT = rtById.get(ctct.RecordTypeId);
            System.debug('checkContacts ctctRT='+ctctRT);
            if (ctctRT != null) {
                RecordType__c rtSetting = RecordTypeHelper.getRtSetting(ctctRT.getName());
                // check the record type - make sure it's a record type we're checking. All valid records types should exist here.
                if (newCtctRT != null && (rtSetting == null || (rtSetting != null && !rtSetting.DoNotAllowChange__c)) 
                    && (ctctRT.getRecordTypeId() != newCtctRT.getRecordTypeId())) {
                        System.debug('checkContacts - record type changed old='+ctctRT.getRecordTypeId()+' new='+newCtctRT.getRecordTypeId());
                        isChanged = true;
                        ctct.RecordTypeId = newCtctRT.getRecordTypeId();
                    }
            } // if (ctctRT != null
            
            // check the owner fields
            // standard field we won't change. Every other field will be based on zip segment definition
            User acctMainOwner = (userMap != null && userMap.containsKey(acct.OwnerId) ? userMap.get(acct.OwnerId) : acct.Owner);
            System.debug('checkContacts holdout='+ctct.Hold_Out__c+' acct.OwnerId='+acct.OwnerId+' ctctOwner='+ctct.OwnerId+' acctMainOwner'+acctMainOwner);
            if (!ctct.Hold_Out__c && (ctct.OwnerId != acct.OwnerId) && acctMainOwner != null && acctMainOwner.IsActive) {
                System.debug('checkContacts - main owner changed old='+ctct.OwnerId+' new='+acct.OwnerId);
                isChanged = true;
                ctct.OwnerId = acct.OwnerId;
            }
            
            Map<String,String> acctCtctOwnerMap = getAcctOwnerMap();
            for (String acctFld : acctCtctOwnerMap.keySet()) {
                System.debug('checkContacts acctFld='+acctFld);
                if (acctFld != 'OwnerId') {
                    String relationshipFld = acctFld.replace('__c','__r');
                    String ctctFld = acctCtctOwnerMap.get(acctFld);
                    Id acctOwnerId = (Id)acct.get(acctFld);
                    User acctOwner = (acctOwnerId != null && userMap != null && userMap.containsKey(acctOwnerId) ? userMap.get(acctOwnerId)
                                      : (acctOwnerId != null ? (User)acct.getSobject(relationshipFld) : null));
                    Id ctctOwnerId = (Id)ctct.get(ctctFld);
                    Boolean ctctChanged = ((acctOwnerId == null || (acctOwner != null && acctOwner.isActive)) && acctOwnerId != ctctOwnerId);
                    System.debug('checkContacts '+acctFld+' ctctChanged='+ctctChanged+' acctOwnerId='+acctOwnerId+' ctctOwnerId='+ctctOwnerId);
                    
                    if (ctctChanged) {
                        System.debug('checkContacts '+acctFld+' changed old='+ctctOwnerId+' new='+acctOwnerId);
                        isChanged = true;
                        ctct.put(ctctFld,acctOwnerId);
                    }
                } // if (acctFld != 'OwnerId') {
            } // for (String acctFld
            System.debug('ZipCheckOwner Contact '+ctct.Name+' Id: '+ctct.Id+' isChanged='+isChanged);
            if (isChanged) {
                updateCtcts.add(ctct);
            }
        } // for (Contact ctct
    } // checkContacts
    
    // Check and set the ownership of the referral accounts.
    public static void checkReferralAccounts(Referral_Account__c[] refAccts,Id[] refAcctIds,Set<String> zipCodeSet) {
        System.debug('checkReferralAccounts refAccts='+refAccts.size()+' refAcctIds='+refAcctIds.size()+' zipCodeSet='+zipCodeSet.size());
        ZipBatch.checkSalesOrgs();
        setupRecordTypeMaps();
        
        // make sure there are zip codes
        if (!zipCodeSet.isEmpty()) {
            Map<String,List<Zip_Assignment__c>> zipMap = getZipAsgns(zipCodeSet, ZipQueries.FILTER_REFERRAL_SOURCES);
            Referral_Contact__c[] updateCtcts = new Referral_Contact__c[]{};
                
                if (!zipMap.isEmpty()) {
                    setRefAcctOwners(refAccts,zipMap,refAcctIds, updateCtcts);
                } // if (!zipMap.isEmpty
            
            DmlHelper.performDML(updateCtcts, DmlHelper.DML_UPDATE, 'ZipCheckOwner', 'checkReferralAccounts', 'updating Referral Accounts', true);
        } // if (!zipCodeSet
    } // checkReferralAccounts
    
    public static Boolean setRefAcctOwners(Referral_Account__c[] refAccts, Map<String,List<Zip_Assignment__c>> zipMap, Id[] refAcctIds, Referral_Contact__c[] updateCtcts) {
        Boolean allOkay = true;
        if (refAccts != null && !refAccts.isEmpty()) {
            Map<Id,List<Referral_Contact__c>> refCtctMap = getRefContacts(refAcctIds);
            
            for (Referral_Account__c ra : refAccts) {
                String checkZip = Utilities.checkPostalCode(ra.Zip_Postal_Code__c, null);
                checkRefAccount(ra, zipMap.get(checkZip), refCtctMap.get(ra.Id), updateCtcts);
            } // for (Referral_Account__c
        } // if (refAccts != null
        return allOkay;
    } // setRefAcctOwners
    
    // get all of the referral contacts for the list of referral accounts
    public static Map<Id,List<Referral_Contact__c>> getRefContacts(List<Id> refAcctIds) {
        Integer rowLimit = (Integer)((Limits.getLimitDmlRows()-Limits.getDmlRows()) / 4);
        
        System.debug('getRefContacts number ids='+refAcctIds.size()+' rowLimit='+rowLimit);
        
        Map<Id,List<Referral_Contact__c>> refCtctMap = new Map<Id,List<Referral_Contact__c>>();
        if (refAcctIds != null && !refAcctIds.isEmpty()) {
            for (Referral_Contact__c[] rcs : [Select Id, Name
                                              ,OwnerId
                                              ,Owner.Id
                                              ,Owner.IsActive
                                              ,RecordTypeId
                                              ,RecordType.Id
                                              ,RecordType.Name
                                              ,HNBF_Contact_Owner__c
                                              ,HNBF_Contact_Owner__r.Id
                                              ,HNBF_Contact_Owner__r.IsActive
                                              ,Hold_Out__c
                                              ,HRS_Contact_Owner__c
                                              ,HRS_Contact_Owner__r.Id
                                              ,HRS_Contact_Owner__r.IsActive
                                              ,Internal_Wholesaler_Contact_Owner__c
                                              ,Internal_Wholesaler_Contact_Owner__r.Id
                                              ,Internal_Wholesaler_Contact_Owner__r.IsActive
                                              ,MMS_Contact_Owner__c
                                              ,MMS_Contact_Owner__r.Id
                                              ,MMS_Contact_Owner__r.IsActive
                                              ,Premier_PBS_Contact_Owner__c
                                              ,Premier_PBS_Contact_Owner__r.Id
                                              ,Premier_PBS_Contact_Owner__r.IsActive
                                              ,Referral_Account__c
                                              ,Referral_Type__c
                                              From Referral_Contact__c 
                                              where Referral_Account__c in :refAcctIds
                                              limit :rowLimit]) {
                                                  for (Referral_Contact__c rc : rcs) {
                                                      List<Referral_Contact__c> rcList = refCtctMap.get(rc.Referral_Account__c);
                                                      if (rcList == null) {
                                                          rcList = new List<Referral_Contact__c>();
                                                          refCtctMap.put(rc.Referral_Account__c,rcList);
                                                      }
                                                      rcList.add(rc);
                                                  } // for (Referral_Contact__c rc
                                              } // for (Referral_Contact__c[] rcs
        } // if (refAcctIds != null
        return refCtctMap;
    } // getRefContacts
    
    // Get the referral accounts for the passed in Ids.
    public static Map<Id,Referral_Account__c> getRefAccounts(List<Id> refAcctIds) {
        Map<Id,Referral_Account__c> refAcctMap = null;
        if (refAcctIds != null && !refAcctIds.isEmpty()) {
            refAcctMap = new Map<Id,Referral_Account__c>([Select Id, Name
                                                          ,CreatedById
                                                          ,RecordTypeId
                                                          ,RecordType.Id
                                                          ,RecordType.Name
                                                          ,OwnerId
                                                          ,Owner.Id
                                                          ,Owner.IsActive
                                                          ,HNBF_Account_Owner__c
                                                          ,HNBF_Account_Owner__r.Id
                                                          ,HNBF_Account_Owner__r.IsActive
                                                          ,Hold_Out__c
                                                          ,HRS_Account_Owner__c
                                                          ,HRS_Account_Owner__r.Id
                                                          ,HRS_Account_Owner__r.IsActive
                                                          ,Internal_Wholesaler_Account_Owner__c
                                                          ,Internal_Wholesaler_Account_Owner__r.Id
                                                          ,Internal_Wholesaler_Account_Owner__r.IsActive
                                                          ,MMS_Account_Owner__c
                                                          ,MMS_Account_Owner__r.Id
                                                          ,MMS_Account_Owner__r.IsActive
                                                          ,Premier_PBS_Account_Owner__c
                                                          ,Premier_PBS_Account_Owner__r.Id
                                                          ,Premier_PBS_Account_Owner__r.IsActive
                                                          ,Referral_Source_Business_Type__c
                                                          ,ReferralSourceSubType__c
                                                          ,Referral_Type__c
                                                          ,Zip_Postal_Code__c
                                                          ,ZipSegment__c
                                                          ,ZipSegment2__c
                                                          From Referral_Account__c where Id in :refAcctIds
                                                          and Zip_Postal_Code__c != null]);
        } // if (refAcctIds
        return refAcctMap;
    } // getRefAccounts
    
    /* Check the owner fields to see if they've changed.
* @return true if a change was made to the referral account
*/
    private static boolean checkRefAccount(Referral_Account__c acct, List<Zip_Assignment__c> zaList, List<Referral_Contact__c> refCtcts, Referral_Contact__c[] updateCtcts) {
        boolean isChanged = false;
        // if any of this criteria are met, do not need to continue
        if ((acct == null) || (zaList == null) || (zaList != null && zaList.isEmpty())) {
            return isChanged;
        }
        
        // loop through the zip codes returned
        for (Zip_Assignment__c za : zaList) {
            isChanged = checkRefAccountSegment(acct, za, za.Zip_Segment__r) || isChanged;
            for (ZipAssignmentFallback__c fallback : za.ZipAssignmentFallbacks__r) {
                isChanged = (checkRefAccountSegment(acct, za, fallback.ZipSegment__r) || isChanged);
            }
        } // for (Zip_Assignment__c
        
        // only check the contacts if the account is changed
        System.debug('checkRefAccount acct name='+acct.Name+' isChanged='+isChanged);
        if (refCtcts != null && !refCtcts.isEmpty()) {
            for (Referral_Contact__c rc : refCtcts) {
                if (setRefCtctOwners(rc, acct)) {
                    updateCtcts.add(rc);
                }
            } // for (Referral_Contact__c
        } // if (isChanged
        return isChanged;
    } // checkRefAccount
    
    public static Boolean checkRefAccountSegment(Referral_Account__c acct, Zip_Assignment__c za, Zip_Segment__c segment) {
        Boolean isChanged = false;
        // make sure the sales org is setup for ownership and that the segment
        // do we still need the default field?
        Boolean meetsCriteria = (segment != null && ZipBatch.rfrlSalesOrgs.contains(za.Sales_Org__c) && String.isNotBlank(segment.RfrlAcctOwnerFldName__c) && String.isNotBlank(segment.RfrlRecordTypes__c));
        System.debug('checkRefAccountSegment seg='+(segment != null ? segment.Segment_Key__c : 'No Segment')+' meetsCriteria='+meetsCriteria);
        meetsCriteria = meetsCriteria && String.isNotBlank(segment.RfrlRecordTypeIds__c) && segment.RfrlRecordTypeIds__c.contains(acct.RecordTypeId);
        System.debug('checkRefAccountSegment check2 meetsCriteria='+meetsCriteria);
        Boolean recordTypeCheckOkay=true;
        if (meetsCriteria) {
            String[] busTypes = (String.isNotBlank(segment.ReferralSourceType__c) ? segment.ReferralSourceType__c.split(';') : new String[]{});
            System.debug('checkRefAccountSegment busTypes='+busTypes.size());
            meetsCriteria = (busTypes.isEmpty() || busTypes.contains(acct.Referral_Source_Business_Type__c));
        } // if (meetsCriteria
        if (meetsCriteria) {
            String[] subTypes = (String.isNotBlank(segment.RfrlSourceSubTypes__c) ? segment.RfrlSourceSubTypes__c.split(';') : new String[]{});
            System.debug('checkRefAccountSegment subTypes='+subTypes.size());
            meetsCriteria = (subTypes.isEmpty() || subTypes.contains(acct.ReferralSourceSubType__c));
            // if the subtype is a criteria for another segment, it should be excluded from this one.
            if (meetsCriteria && String.isNotBlank(segment.RfrlSubTypesExcluded__c)) {
                meetsCriteria = !segment.RfrlSubTypesExcluded__c.contains(acct.ReferralSourceSubType__c);
            }
        } // if (meetsCriteria
        System.debug('checkRefAccountSegment check3 meetsCriteria='+meetsCriteria);
        if (meetsCriteria) {
            meetsCriteria = checkOtherCriteria(acct, segment, meetsCriteria);
        }
        System.debug('checkRefAccountSegment check4 meetsCriteria='+meetsCriteria);
        
        if (meetsCriteria) {
            String acctOwnerFieldName = segment.RfrlAcctOwnerFldName__c;
            String holdOutFieldName = segment.RfrlAcctHoldOutFldName__c;
            Boolean hasHoldOut=(String.isNotBlank(holdOutFieldName) ? (Boolean)acct.get(holdOutFieldName) : false);
            if (String.isNotBlank(acctOwnerFieldName)) {
                ownerFieldMatched.add(acctOwnerFieldName); 
            }
            System.debug('checkRefAccountSegment seg='+za.Zip_Segment__r.Name+' acctOwnerFieldName='+acctOwnerFieldName+' hasHoldOut='+hasHoldOut);
            if (!hasHoldOut) {
                // the main owner field is required
                isChanged = setOwnerField(isChanged, za, acct, acctOwnerFieldName, true, (acctOwnerFieldName == ObjectHelper.OWNER_FIELD), (Map<String,AccountTeamMember>)null, (AccountTeamMember[])null, (AccountTeamMember[])null);
            } // if (checkZip && checkZipCriteria
        } // if (za.Zip_Segment__c != null)
        return isChanged;
    } // checkRefAccountSegment
    
    public static Boolean setOwnerField(Boolean currentIsChanged, Zip_Assignment__c za, SObject rec, String ownerIdFieldName, Boolean useOwnerRefField, Boolean ownerIsRequired
                                        ,Map<String,AccountTeamMember> atmMap, List<AccountTeamMember> insertAcctTeams, List<AccountTeamMember> deleteAcctTeams) {
                                            // we pass in the value of the isChanged field so we can just override it and pass it back without having to do any further
                                            // checking on return. If true is passed in, will always stay true. If false is passed can, can pass back true or false depending. 
                                            if (String.isNotBlank(ownerIdFieldName)) {
                                                ownerFieldMatched.add(ownerIdFieldName); 
                                            }
                                            
                                            Boolean isChanged = currentIsChanged;
                                            String refFieldName = (!useOwnerRefField ? null : (ownerIdFieldName == ObjectHelper.OWNER_FIELD ? 'Owner' : (ownerIdFieldName.endsWith('Id') ? ownerIdFieldName.substring(0,ownerIdFieldName.length()-2) : (ownerIdFieldName.endsWith('__c') ? ownerIdFieldName.replace('__c', '__r') : null))));
                                            // get the current record id
                                            Id curOwnerId = (Id)rec.get(ownerIdFieldName);
                                            User zaUser = ((za.User__c != null && za.User__r.IsActive) ? za.User__r : null);
                                            System.debug('setOwnerField isChanged='+isChanged+' ownerIdFieldName='+ownerIdFieldName+' refFieldName='+refFieldName+' curOwnerId='+curOwnerId+' zaUser='+zaUser);
                                            
                                            if ((!ownerIsRequired && zaUser == null) || ((zaUser != null) && (curOwnerId != zaUser.Id))) {
                                                Id zaUserId = (zaUser != null ? zaUser.Id : null);
                                                System.debug('setOwnerField changing '+za.Sales_Org__c+' '+ownerIdFieldName+' from '+curOwnerId+' to '+zaUserId);
                                                rec.put(ownerIdFieldName,zaUserId);
                                                // this has to be set because the active flag is checked for the contacts.
                                                if (refFieldName != null && zaUser != null) {
                                                    rec.putSObject(refFieldName,zaUser);
                                                }
                                                isChanged = true;
                                            }
                                            String teamRole = za.Zip_Segment__r.TeamRole__c;
                                            String objectTypeName = rec.getSObjectType().getDescribe().getName();
                                            
                                            if (atmMap != null && String.isNotBlank(teamRole) && objectTypeName == ObjectHelper.OBJECT_ACCOUNT) {
                                                checkAccountTeam((Account)rec,null,zaUser,teamRole, insertAcctTeams, deleteAcctTeams, atmMap);
                                            } // if (String.isNotBlank(teamRole
                                            
                                            return isChanged;
                                        } // setOwnerField
    
    /** Set the ownership on the Referral Contacts. 
* @param refCtcts set all of the ownership fields
* @param checkWholesalers - only set the Internal/External wholesaler fields.
*/
    public static void setRefContacts(Referral_Contact__c[] refCtcts, Id[] refAcctIds) {
        // select the referral accounts
        Map<Id,Referral_Account__c> refAcctMap = getRefAccounts(refAcctIds);
        
        for (Referral_Contact__c refCtct : refCtcts) {
            setRefCtctOwners(refCtct,refAcctMap.get(refCtct.Referral_Account__c));
        }
    } // setRefContacts
    
    // update the referral contacts to match the account
    public static void checkRefCtcts(Referral_Account__c[] refAccts, List<Id> refAcctIds) {
        // select the contacts and accounts
        Map<Id,List<Referral_Contact__c>> refCtctByAcctIdMap = getRefContacts(refAcctIds);
        // the list of contacts to update
        Referral_Contact__c[] updateCtcts = new Referral_Contact__c[]{};
            for (Referral_Account__c refAcct : refAccts) {
                List<Referral_Contact__c> refCtcts = refCtctByAcctIdMap.get(refAcct.Id);
                if (refCtcts != null) {
                    for (Referral_Contact__c refCtct : refCtcts) {
                        if (setRefCtctOwners(refCtct, refAcct)) {
                            updateCtcts.add(refCtct);
                        }
                    }
                } // if (refCtcts != null
            } // for (Referral_Account__c refAcct
        System.debug('checkRefCtcts updateCtcts='+updateCtcts.size());
        DmlHelper.performDML(updateCtcts, DmlHelper.DML_UPDATE, 'ZipCheckOwner', 'checkRefCtcts', 'updating Referral Contacts', true);
    } // checkRefCtcts
    
    public static Boolean checkContactRecordType(Referral_Account__c ra, Referral_Contact__c rc) {
        Boolean changed = false;
        setupRecordTypeMaps();
        // check if the contact's current record type can be changed.
        Schema.RecordTypeInfo currectCtctRt = rtById.get(rc.RecordTypeId);
        RecordType__c ctctRecordType = (currectCtctRt != null ? RecordType__c.getInstance(currectCtctRt.getName()) : null);
        Boolean changeable = (ctctRecordType != null && ctctRecordType.UsedInOwnership__c && String.isNotBlank(ctctRecordType.ParentObjectName__c));
        
        System.debug('checkContactRecordType changeable='+changeable+' ra.RecordType.Name='+ra.RecordType.Name);
        if (changeable) {
            // get the account's record type info
            Schema.RecordTypeInfo currectAcctRt = rtById.get(ra.RecordTypeId);
            RecordType__c acctRecordType = (currectAcctRt != null ? RecordType__c.getInstance(currectAcctRt.getName()) : null);
            // check to see if the contacts record type matches the record type of the account
            if (acctRecordType != null && acctRecordType.UsedInOwnership__c
                && String.isNotBlank(acctRecordType.ContactRecordTypeName__c)
                && acctRecordType.ContactRecordTypeName__c != ctctRecordType.Name) {
                    Schema.RecordTypeInfo ctctRt = RecordTypeHelper.getRecordType(acctRecordType.ContactRecordTypeName__c, ctctRecordType.ObjectName__c);
                    if (ctctRt != null && ctctRt.getRecordTypeId() != rc.RecordTypeId) {
                        rc.RecordTypeId = ctctRt.getRecordTypeId();
                        changed = true;
                    }
                } // if (acctRecordType == null &&
        } // if (changeable
        System.debug('checkContactRecordType changed='+changed);
        return changed;
    } // getCtctRecordTypeId
    
    // Set the owner fields on the Referral Contact.
    public static Boolean setRefCtctOwners(Referral_Contact__c rc, Referral_Account__c ra) {
        Boolean changed = false;
        if (rc != null && ra != null) {
            changed = checkContactRecordType(ra,rc);
            System.debug('ra.Owner='+ra.Owner+' ra.OwnerId='+ra.OwnerId);
            if (!rc.Hold_Out__c && ra.OwnerId != null && rc.OwnerId != ra.OwnerId) {
                System.debug('setting referral contact owner to '+ra.OwnerId+', original id='+rc.OwnerId);
                rc.OwnerId = ra.OwnerId;
                changed = true;
            }
            // TODO - do I need to make this more dynamic?
            changed = checkRefCtctOwnerFld(changed, rc, 'MMS_Contact_Owner__c', ra.MMS_Account_Owner__r, ra.MMS_Account_Owner__c);
            changed = checkRefCtctOwnerFld(changed, rc, 'HRS_Contact_Owner__c', ra.HRS_Account_Owner__r, ra.HRS_Account_Owner__c);
            changed = checkRefCtctOwnerFld(changed, rc, 'Premier_PBS_Contact_Owner__c', ra.Premier_PBS_Account_Owner__r, ra.Premier_PBS_Account_Owner__c);
            changed = checkRefCtctOwnerFld(changed, rc, 'HNBF_Contact_Owner__c', ra.HNBF_Account_Owner__r, ra.HNBF_Account_Owner__c);
            changed = checkRefCtctOwnerFld(changed, rc, 'Internal_Wholesaler_Contact_Owner__c', ra.Internal_Wholesaler_Account_Owner__r, ra.Internal_Wholesaler_Account_Owner__c);
        } // if (rc != null
        return changed;
    } // setRefCtctOwners
    
    public static Boolean checkRefCtctOwnerFld(Boolean originalChanged, Referral_Contact__c rc, String ctctFieldName, User checkUser, Id checkUserId) {
        Boolean changed = originalChanged;
        Id originalId = (Id)rc.get(ctctFieldName);
        Id newOwnerId = checkUser(originalId, checkUser, checkUserId);
        if (originalId != newOwnerId) {
            rc.put(ctctFieldName, newOwnerId);
            changed = true;
        }
        return changed;
    } // checkRefCtctOwnerFld
    
    public static Id checkUser(Id originalId, User checkUser, Id checkUserId) {
        Id retVal = originalId;
        if (checkUser == null && checkUserId != null) {
            retVal = checkUserId;
        } else if (checkUser == null) {
            retVal = null;
        } else if (checkUser != null && checkUser.IsActive) {
            retVal = checkUser.Id;
        }
        System.debug('checkUser originalId='+originalId+' newId='+retVal+' checkUser='+checkUser);
        return retVal;
    } // checkUser
    
    // if we need to check the account team and this is an update.
    public static Id[] checkAcctTeamIds = new Id[]{};
        
        public static String[] MMS_RECORD_TYPES = Label.MMS_Opportunity_RecordTypes.split(',');
    
    public static void handleAccountsBefore(Account[] accts, Map<Id,Account> oldMap) {
        System.debug('handleAccountsBefore accts='+accts.size());
        atmsToInsert.clear();
        // if we need to check the owner
        Account[] checkOwners = new Account[]{};
            
            // the account ids that we will check for crossover requests - link to the hold out expiration record so we know which field to check
            Map<Id,HoldOut_ExpirationDates__c> acctIdOwnerFldMap = new Map<Id,HoldOut_ExpirationDates__c>();
        
        Set<Id> checkOppIds = new Set<Id>();
        Set<Id> checkOppAcctIds = new Set<Id>();
        Set<Id> checkIntRefIdSet= new Set<ID>();
        Set<Id> cscmContractStatus=new Set<Id>();
        Date lowestStartDate = Date.today();
        
        // check to see if an account went lost. 
        Id mmsRTID = RecordTypeHelper.getRecordType(Label.RT_MMS_Account,'Account').getRecordTypeId();
        Id smbRTId = RecordTypeHelper.getRecordType(Label.RT_Core_Account,'Account').getRecordTypeId();
        for (Account acct : accts) {
            Account oldAcct = (oldMap != null ? oldMap.get(acct.Id) : null);
            if (acct.Lost_Date__c != null && oldAcct != null && oldAcct.Lost_Date__c == null && acct.LatestPayrollOpp__c != null) {
                System.debug('handleAccountsBefore acct='+acct.Name+' lost date is set');
                if (!acct.Hold_Out__c || (acct.Hold_Out__c && acct.Hold_Out_Expiration__c!=null)) {
                    checkOppIds.add(acct.LatestPayrollOpp__c);
                    checkOppAcctIds.add(acct.Id);
                    acct.Permanent_Hold_Out_Description__c = null;
                    acct.Hold_Out__c = false;
                    acct.Hold_Out_Expiration__c = null;
                }
            } // if (oldAcct != null
            
            //APR0165075: US2 Due to the sales policy the check for the CSSR Segment is evaluated here ONLY for MMS Record Types 
            System.debug('checking Lost data Old Acc'+oldAcct);
            System.debug('checking Lost data New Acc'+acct);
            if(oldAcct !=null && acct.Lost_Date__c != null && oldAcct.Lost_Date__c == null && ((acct.RecordTypeId == mmsRTID && (acct.Type == 'FLEX Client' || acct.Type == 'Oasis Client' || acct.Type == 'PEO Client')) || (acct.RecordTypeId == smbRTId && (acct.Type == 'Oasis Client' || acct.Type == 'PEO Client'))) ){
                System.debug('First if 2096');
                acct.Client_Start_Date__c = null;
                if(acct.CSSR_Segment__c){
                    System.debug('Second if 2096');
                    acct.CSSR_Segment__c=false;
                    acct.Use_Zip_Assignment_Rules__c=true;
                }
            }
            
            if (acct.First_Run_Date__c != null && oldAcct != null && acct.First_Run_Date__c != oldAcct.First_Run_Date__c) {
                checkIntRefIdSet.add(acct.Id);
                lowestStartDate = (acct.First_Run_Date__c < lowestStartDate ? acct.First_Run_Date__c : lowestStartDate);
            }
            if(oldAcct!=null && acct.CSCMContractStatus__c!= null && acct.CSCMContractStatus__c == 'Terminated' && oldAcct.CSCMContractStatus__c!= 'Terminated'){  
                cscmContractStatus.add(acct.Id);  
            }
            if(!cscmContractStatus.isEmpty()){  
                if(acct.OasisPEOHoldOutReason__c == 'PEO Client'){  
                    system.debug('cscmContractStatus'+cscmContractStatus+'OasisPEOHoldOut__c'+acct.OasisPEOHoldOut__c+'OasisPEOHoldOutExpiration__c'+acct.OasisPEOHoldOutExpiration__c+'OasisPEOHoldOutReason__c'+acct.OasisPEOHoldOutReason__c);  
                    acct.OasisPEOHoldOut__c = false;  
                    acct.OasisPEOHoldOutExpiration__c = null;  
                    acct.OasisPEOHoldOutReason__c = null;  
                    acct.Use_Zip_Assignment_Rules__c = true;  
                }  
            }
        } // for (Account acct : accts
        
        // if an account went lost, retrieve their latest payroll opp in order to check the owner of it.
        Map<Id,Opportunity> oppMap = (checkOppIds.isEmpty() ? new Map<Id,Opportunity>()
                                      : new Map<Id,Opportunity>([Select Id, OwnerId, Owner.Sales_Division__c, Owner.IsActive, Owner.Sales_Org__c
                                                                 From Opportunity
                                                                 Where Id in :checkOppIds]));
        
        Map<Id,Referral__c> intRefMap = new Map<Id,Referral__c>();
        if (!checkIntRefIdSet.isEmpty()) {
            // TODO - this should someday be changed to be more dynamic, but right now we'll set this only for referrals from PEO to MMS
            // referring opportunity owner has to be active APR0142576
            Date lookBackPeriod = lowestStartDate.addDays(-Integer.valueOf(System.Label.PEO_Referral_look_back_period));
            /*Referral__c[] intRefList= [Select id,Account__c,Referral_Approved_Date__c
,Selling_Opportunity__c,Referring_Opportunity__c,Selling_Opportunity__r.RecordType.Name
,Referring_Opportunity__r.OwnerId, Referring_Opportunity__r.RecordType.Name 
,Selling_Opportunity__r.OwnerId, Selling_Opportunity__r.Owner.IsActive
FROM Referral__c 
where Account__c in :checkIntRefIdSet AND Referral_Partner__c!= null AND PartnerType__c ='Internal Referral' 
AND Selling_Opportunity__c != null 
//AND Selling_Opportunity__r.CloseDate <= :lowestStartDate     //   changed from >=  to  <=   
//AND Selling_Opportunity__r.CloseDate >= :lookBackPeriod
AND Selling_Opportunity__r.RecordType.Name in :MMS_RECORD_TYPES
AND Selling_Opportunity__r.IsClosed=true
AND Selling_Opportunity__r.IsWon=true
AND Referral_Approved_Date__c >= :lookBackPeriod
AND Referring_Opportunity__c != null 
AND Referring_Opportunity__r.Owner.IsActive=true
AND Referring_Opportunity__r.Owner.Sales_Org__c='PEO'];*/
            //APR0163609: PEO hold out Change--Query Changed-- OR Inbound_Integrated_Selling__c =True,AND Selling_Opportunity__r.RecordType.Name in :lstRecordTypesMMSPEO,OR Referring_Opportunity__r.Owner.Sales_Org__c='MMS'
            Referral__c[] intRefList= [Select id,Account__c,Referral_Approved_Date__c
                                       ,Selling_Opportunity__c,Referring_Opportunity__c,Selling_Opportunity__r.RecordType.Name
                                       ,Referring_Opportunity__r.OwnerId, Referring_Opportunity__r.RecordType.Name 
                                       ,Selling_Opportunity__r.OwnerId, Selling_Opportunity__r.Owner.IsActive
                                       ,PartnerType__c 
                                       ,Referring_Opportunity__r.Owner.Sales_Org__c 
                                       ,Inbound_Integrated_Selling__c
                                       ,Contact__r.User_Lookup__c
                                       FROM Referral__c 
                                       where Account__c in :checkIntRefIdSet AND Referral_Partner__c!= null AND Referral_Approved_Date__c >= :lookBackPeriod
                                       AND ((PartnerType__c ='Internal Referral' 
                                             AND Selling_Opportunity__c != null 
                                             //AND Selling_Opportunity__r.CloseDate <= :lowestStartDate // changed from >= to <= 
                                             //AND Selling_Opportunity__r.CloseDate >= :lookBackPeriod
                                             AND Selling_Opportunity__r.RecordType.Name in :MMS_RECORD_TYPES
                                             AND Selling_Opportunity__r.IsClosed=true
                                             AND Selling_Opportunity__r.IsWon=true 
                                             AND Referring_Opportunity__c != null 
                                             AND Referring_Opportunity__r.Owner.IsActive=true
                                             AND Referring_Opportunity__r.Owner.Sales_Org__c='PEO') OR (Inbound_Integrated_Selling__c =True AND Referral_Partner__r.Name = 'PEO' AND Contact__r.User_Lookup__r.IsActive=true and PartnerReferral__c!=null and PartnerReferral__r.Referral__c!=null and PartnerReferral__r.Referral__r.Referral_Partner__r.Name='MMS' AND PartnerReferral__r.Referral__r.Selling_Opportunity__c!=null AND PartnerReferral__r.Referral__r.Selling_Opportunity__r.IsClosed=true AND PartnerReferral__r.Referral__r.Selling_Opportunity__r.IsWon=true))];
            System.debug('handleAccountsBefore lookBackPeriod='+lookBackPeriod+' intRefList='+intRefList.size()+' lowestStartDate='+lowestStartDate);
            //APR0163609: PEO hold out Change--Commented out the old logic and implimented new logic
            //for (Referral__c ref : intRefList) {
            //    intRefMap.put(ref.Account__c, ref);
            //}
            for (Referral__c ref : intRefList) {
                if(ref.Referring_Opportunity__r.Owner.Sales_Org__c=='PEO' && ref.PartnerType__c =='Internal Referral'){
                    //system.debug('MA Internal Referral'+ref+' '+ref.Referring_Opportunity__r.Owner.Sales_Org__c+' '+ref.PartnerType__c);
                    intRefMap.put(ref.Account__c, ref);
                }
                else if(ref.Inbound_Integrated_Selling__c==true){
                    //system.debug('MA Integrated Selling'+ref+' '+ref.Referring_Opportunity__r.Owner.Sales_Org__c+' '+ref.Inbound_Integrated_Selling__c);
                    intRefMap.put(ref.Account__c, ref);
                }
            }
            //APR0163609: PEO hold out Change--Commented out the old logic and implimented new logic
        } // if (!checkIntRefIdSet
        System.debug('handleAccountsBefore checkOppIds='+checkOppIds.size()+' checkOppAcctIds='+checkOppAcctIds.size()+' oppMap='+oppMap.size());
        for (Account acct : accts) {
            System.debug('handleAccountsBefore acct.Hold_Out__c='+acct.Hold_Out__c);
            Account oldAcct = (oldMap != null ? oldMap.get(acct.Id) : null);
            // make sure the zip code is set
            AccountMethods.checkZipFields(acct, oldAcct);
            
            // log the ids of the owners in different fields.
            if (acct.OwnerId != null && (oldAcct == null || acct.OwnerId != oldAcct.OwnerId)) {
                acct.Current_Owner_ID__c = acct.OwnerId;
                acct.Previous_Owner_ID__c = (oldAcct != null ? oldAcct.OwnerId : null);
            }
            checkAcctHoldOuts(acct, oldAcct,acctIdOwnerFldMap, intRefMap);
            checkForSegmentationEvaluation(acct,oldAcct);
            
            // if the owner of the latest payroll opp was a channel or virtual and are still active, they will retain ownership for 12 months.
            if (acct.Id != null && checkOppAcctIds.contains(acct.Id)) {
                Opportunity opp = (acct.LatestPayrollOpp__c != null ? oppMap.get(acct.LatestPayrollOpp__c) : null);
                System.debug('handleAccountsBefore checking Opp attributes opp='+(opp != null));
                
                if (opp != null && opp.Owner.IsActive && String.isNotBlank(opp.Owner.Sales_Division__c)
                    && (opp.Owner.Sales_Division__c.contains(Label.CoreZipDefault) 
                        || opp.Owner.Sales_Division__c == Label.SMB_NewBus_SalesDiv
                        || (opp.Owner.Sales_Org__c == UserHelper.SO_PAY && opp.Owner.Sales_Division__c == Label.VirtualSMBInbound_SalesDiv))) {
                            acct.OwnerId = opp.OwnerId;
                            acct.Permanent_Hold_Out_Description__c = 'Payroll Lost Client';
                            acct.Hold_Out__c = true;
                            acct.Hold_Out_Expiration__c = Date.today().addDays(365);
                        } else {
                            // let it use the territory rules
                            acct.Use_Zip_Assignment_Rules__c = true;
                        }
            } // if (acct.Id != null
            
            if (acct.Use_Zip_Assignment_Rules__c 
                || oldAcct == null
                || (oldAcct != null && checkForOwnerEval(acct,oldAcct, acct.isChild__c))) {
                    checkOwners.add(acct);
                } else if (oldAcct != null && checkForAcctTeamEval(acct, oldAcct)) {
                    checkAcctTeamIds.add(acct.Id);
                }
        } // for (Account acct : accts
        
        System.debug('handleAccountsBefore checkOwners='+checkOwners.size()+' checkAcctTeamIds='+checkAcctTeamIds.size());
        if (!checkOwners.isEmpty()) {
            processAccountsBefore(checkOwners);
        }
    } // handleAccountsBefore
    
    // this is called from the before method to see if the hold outs change
    public static Boolean checkAcctHoldOuts(Account acct, Account oldAcct,Map<Id,HoldOut_ExpirationDates__c> acctIdOwnerFldMap, Map<Id,Referral__c> intRefMap) {
        //Boolean changed = false;
        // this is just if a holdout is removed
        Boolean holdOutChanged = false;
        Boolean checkOwnership = false;
        Boolean startDateSet = (acct.First_Run_Date__c != null && (oldAcct == null || acct.First_Run_Date__c != oldAcct.First_Run_Date__c));
        //System.debug('checkAcctHoldOuts startDateSet='+startDateSet+' intRefMap='+intRefMap.size());
        // if startDateSet==true then query for internal referals from PEO->MMS
        //    Map<String,String> refFromToMap
        //    is there a time limit on how far back we're selecting internal referrals?
        //    collection of referral from and referral to values
        // create 2 new fields on the HoldOut_ExpirationDates__c custom setting
        //   StartDateSetsExpiration__c -> number 4  365
        //   StartDateHoldOutName -> text 40    hold out name
        //   StartDateRefTo -> Text 10   MMS
        
        for (HoldOut_ExpirationDates__c holdOutSetting : HoldOut_ExpirationDates__c.getAll().values()) {
            System.debug('checkAcctHoldOuts holdOutSetting='+holdOutSetting.Name);
            Boolean curHoldOut = (String.isNotBlank(holdOutSetting.Account_Hold_Out__c) && acct.get(holdOutSetting.Account_Hold_Out__c) != null ? (Boolean)acct.get(holdOutSetting.Account_Hold_Out__c) : false);
            Boolean prevHoldOut = (oldAcct != null && String.isNotBlank(holdOutSetting.Account_Hold_Out__c) ? (Boolean)oldAcct.get(holdOutSetting.Account_Hold_Out__c) : false);
            String holdOutReason = (String.isNotBlank(holdOutSetting.HoldOutReasonFld__c) ? (String)acct.get(holdOutSetting.HoldOutReasonFld__c) : null);
            
            Id curOwnerId = (String.isNotBlank(holdOutSetting.Account_Owner__c) ? (Id)acct.get(holdOutSetting.Account_Owner__c) : null);
            Id prevOwnerId = (oldAcct != null && String.isNotBlank(holdOutSetting.Account_Owner__c) ? (Id)oldAcct.get(holdOutSetting.Account_Owner__c) : null);
            Boolean ownerChanged = (curOwnerId != prevOwnerId);
            if (ownerChanged) {
                checkOwnership = true;
            }
            Boolean handled=false;
            // if the start date is set and there's a hold out and hold out reason
            if (startDateSet && curHoldOut && String.isNotBlank(holdOutReason)) {
                HoldOut_Dictionary__c hod = HoldOut_Dictionary__c.getInstance(RecordTypeHelper.cleanRtName(holdOutReason));
                if (hod != null && hod.StartDateSetsExpiration__c != null) {
                    System.debug('checkAcctHoldOuts extending holdout date');
                    Date newDate = acct.First_Run_Date__c.addDays(Integer.valueOf(hod.StartDateSetsExpiration__c));
                    acct.put(holdOutSetting.Account_Hold_Out_Date__c,newDate);
                    handled = true;
                }
                // else if startDateSet && holdOutSetting.StartDateSetsExpiration__c != null 
                //       && (!curHoldOut || acct.get(holdOutSetting.Account_Hold_Out_Date__c) != null)) {
                //    if (String.isBlank(holdOutSetting.StartDateRefTo) 
                //              || (refFromToMap.containsKey(holdOutSetting.Sales_Org__c) && refFromToMap.get(holdOutSetting.Sales_Org__c) == holdOutSetting.StartDateRefTo) {
                //  Date newDate = acct.First_Run_Date__c.addDays(Integer.valueOf(holdOutSetting.StartDateSetsExpiration__c));
                //  acct.put(holdOutSetting.Account_Hold_Out_Date__c,newDate);
                //  acct.put(holdOutSetting.Account_Hold_Out__c,true);
                //  acct.put(holdOutSetting.HoldOutReasonFld__c,holdOutSetting.StartDateHoldOutName);
                //  }
            }
            System.debug('checkAcctHoldOuts handled='+handled+' holdOutSetting.StartDateSetsExpiration__c='+(holdOutSetting.StartDateSetsExpiration__c != null));
            if(!handled && startDateSet && holdOutSetting.StartDateSetsExpiration__c != null && acct.Id != null && intRefMap != null && intRefMap.containsKey(acct.Id)) {
                Referral__c ref = intRefMap.get(acct.Id);
                //APR0163609: PEO hold out Change-Start
                Id newOwnerId=ref.PartnerType__c=='Internal Referral'?ref.Referring_Opportunity__r.OwnerId:ref.Contact__r.User_Lookup__c;
                String newHoldoutreason=ref.PartnerType__c=='Internal Referral'?holdOutSetting.StartDateHoldOutName__c:Label.Market_Segmentation_Policy;
                //APR0163609: PEO hold out Change-End
                System.debug('checkAcctHoldOuts intRef found='+(ref != null)+' curHoldOut='+curHoldOut);
                // 2/13/2023 only selecting referrals that are from PEO to MMS, so if a referral is returned it meets the criteria
                if (ref != null) {
                    // We're doing the same thing whether or not the owners match
                    // if hold out without a date, do nothing 
                    // if no hold out or hold out with date, set the date to number of days in StartDateSetsExpiration__c
                    if (!curHoldOut || (curHoldOut && acct.get(holdOutSetting.Account_Hold_Out_Date__c) != null)) {
                        System.debug('checkAcctHoldOuts setting holdout');
                        Date newDate = acct.First_Run_Date__c.addDays(Integer.valueOf(holdOutSetting.StartDateSetsExpiration__c));
                        //APR0163609: PEO hold out Change--Commented out the old logic and implimented new logic-Start
                        //if (curOwnerId != ref.Referring_Opportunity__r.OwnerId) {
                        //    acct.put(holdOutSetting.Account_Owner__c, ref.Referring_Opportunity__r.OwnerId);
                        //}
                        if (curOwnerId != newOwnerId) {
                            acct.put(holdOutSetting.Account_Owner__c, newOwnerId);
                        }
                        //APR0163609: PEO hold out Change-Commented out the old logic and implimented new logic--End
                        acct.put(holdOutSetting.Account_Hold_Out_Date__c,newDate);
                        acct.put(holdOutSetting.Account_Hold_Out__c,true);
                        //acct.put(holdOutSetting.HoldOutReasonFld__c,holdOutSetting.StartDateHoldOutName__c);//Commented out by Pratik--APR0163609
                        acct.put(holdOutSetting.HoldOutReasonFld__c,newHoldoutreason);
                    }
                }
                
            }
            
            // see if a holdout was removed
            System.debug('checkAcctHoldOuts curHoldOut='+curHoldOut+' prevHoldOut='+prevHoldOut+' curOwnerId='+curOwnerId+' prevOwnerId='+prevOwnerId+' ownerChanged='+ownerChanged);
            holdOutChanged = (holdOutChanged || (curHoldOut==false && prevHoldOut==true));
            
            if (holdOutSetting.UseForOwnershipChange__c && String.isNotBlank(holdOutSetting.Account_Hold_Out__c) && String.isNotBlank(holdOutSetting.Account_Hold_Out_Date__c) && String.isNotBlank(holdOutSetting.HoldOutReasonFld__c)) {
                // see if an account hold out is past the expiration date
                Date holdOutDate = (Date)acct.get(holdOutSetting.Account_Hold_Out_Date__c);
                if (curHoldOut != null && curHoldOut && holdOutDate != null && holdOutDate < Date.today()) {
                    acct.put(holdOutSetting.Account_Hold_Out__c,false);
                    acct.put(holdOutSetting.Account_Hold_Out_Date__c,null);
                    if (String.isNotBlank(holdOutSetting.HoldOutReasonFld__c) && acct.get(holdOutSetting.HoldOutReasonFld__c) != null) {
                        acct.put(holdOutSetting.HoldOutReasonFld__c,null);
                    }
                    checkOwnership = true;
                    System.debug('checkAcctHoldOuts fld='+holdOutSetting.Account_Hold_Out__c+' curHoldOut='+curHoldOut+' holdOutDate='+holdOutDate);
                }
                if (oldAcct != null && acctIdOwnerFldMap != null) {
                    // see if a hold was removed. If it did change, does the previous reason match the crossover one (NOTE: this should be in a label)
                    Boolean newHoldOut = (Boolean)acct.get(holdOutSetting.Account_Hold_Out__c);
                    if (curHoldOut && !newHoldOut && holdOutReason == Label.Crossover_Hold_Out_Reason) {
                        // store the account id and the owner field
                        // right now we're going to assume that we'll only be doing this for one hold out field on an account in a transaction!
                        acctIdOwnerFldMap.put(acct.Id, holdOutSetting);
                    }
                } // if (oldAcct != null
            } // if (holdOutSetting.UseForOwnershipChange__c &&
        } // for (HoldOut_ExpirationDates__c holdOutSetting
        
        
        // pass in a null for the old account because we just want to see if there is a referral source, not if it changed
        if (holdOutChanged && ReferralAccountChkAcctOwner.checkAccountReferralSources(acct,null)) {
            // set the flag so the batch job will pick it up
            acct.EvaluateRefAcctOwner__c = true;
            // so we don't need to evaluate this elsewhere
            checkOwnership = true;
            // we don't want this evaluated right now. So we'll skip that part of the trigger. ReferralAccountChkAcctBatch will pick it up later
            TriggerMethods.skipObjectTriggerSet.add(ReferralAccountChkAcctOwner.CLASSNAME);
        }
        if (checkOwnership) {
            acct.Use_Zip_Assignment_Rules__c = true;
        }
        return (checkOwnership);
    } // checkAcctHoldOuts
    
    public static void handleAccountsAfter(Account[] recs, Map<Id,Account> oldMap) {
        
        checkSaveATMs();
        if (!checkAcctTeamIds.isEmpty()) {
            checkAccountTeams(checkAcctTeamIds);
        }
        if (!parentIdsToPush.isEmpty()) {
            AccountJunctionMethods.pushParenttoChild(null, parentIdsToPush);
        }
        
    } // handleAccountsAfter
    
    public static void checkSaveATMs() {
        System.debug('checkSaveATMs atmsToInsert='+atmsToInsert.size());
        if (atmsToInsert.isEmpty()) {
            return;
        }
        AccountTeamMember[] insertAtms = new AccountTeamMember[]{};
            for (AcctTeamInsert wrap : atmsToInsert) {
                System.debug('checkSaveATMs wrap.acct.Id='+wrap.acct.Id);
                if (wrap.acct.Id != null) {
                    wrap.atm.AccountId = wrap.acct.Id;
                    insertAtms.add(wrap.atm);
                }
            } // for (atmsToInsert wrap
        DmlHelper.performDML2(insertAtms, DmlHelper.DML_INSERT, 'ZipCheckOwner', 'checkSaveATMs', 'Insert atms', true);
        
    } // checkSaveATMs
    
    // Check if we need to reevaluate ownership on non-Child account
    public static Boolean checkForOwnerEval(Account newA, Account oldA) {
        Boolean ans = checkForOwnerEval(newA, oldA, false);
        return ans;
    } // checkForOwnerEval
    
    // Check if we need to reevaluate ownership, re-eval Child accounts only if a Hold Out changes      //CMF
    public static Boolean checkForOwnerEval(Account newA, Account oldA, Boolean isChild) {          
        
        // don't trigger a change if the field previously didn't have a value
        Boolean changed = (newA.Owner_Zip_Code__c != oldA.Owner_Zip_Code__c && String.isNotBlank(oldA.Owner_Zip_Code__c) && !isChild);
        System.debug('checkForOwnerEval 1 changed='+changed);
        if (!changed) {
            // TODO - use custom setting for holdout fields. 
            /*APR0157517:When Clear Sales Team is unchecked add all sales reps from the prospect client team related link */
            changed = ((newA.Hold_Out__c == false && oldA.Hold_Out__c == true) 
                       || (newA.HNBF_Hold_Out__c == false && oldA.HNBF_Hold_Out__c == true) 
                       || (newA.HRS_Hold_Out__c == false && oldA.HRS_Hold_Out__c == true) 
                       || (newA.OasisPEOHoldOut__c == false && oldA.OasisPEOHoldOut__c == true) 
                       || (newA.Premier_PBS_Hold_Out__c == false && oldA.Premier_PBS_Hold_Out__c == true) 
                       || (newA.SalesParent__c != oldA.SalesParent__c)
                       || (newA.RecordTypeId != oldA.RecordTypeId && !isChild) 
                       || (newA.NumberOfEmployees != null && oldA.NumberOfEmployees == null && !isChild)
                       || (newA.Lost_Date__c != oldA.Lost_Date__c)
                       || (newA.Clear_Sales_Team__c == false && oldA.Clear_Sales_Team__c == true)    //APR0157517
                      );
        }
        System.debug('checkForOwnerEval 2 changed='+changed);
        if (!changed && oldA != null && newA.NumberOfEmployees != null && oldA.NumberOfEmployees != null && newA.NumberOfEmployees != oldA.NumberOfEmployees && !isChild) {
            Integer empTreshhold = Integer.valueOf(Label.Emp_Change_Thresshold);
            Integer empChange = Integer.valueOf(Math.abs(oldA.NumberOfEmployees - newA.NumberOfEmployees));
            changed = empChange >= empTreshhold;
        }
        
        System.debug('checkForOwnerEval 3 changed='+changed);
        // for any special fields added in the Zip Segment for evaluation
        if (!changed && oldA != null && !isChild) {
            Set<String> acctFldSet = ZipQueries.getAccountQueryFields();
            for (String fldName : acctFldSet) {
                if (newA.get(fldName) != oldA.get(fldName)) {
                    changed = true;
                    break;
                }
            } // for (String fldName : acctFldSet
            /*
for (PaychexSettings__c setting : PaychexSettings__c.getAll().values()) {
if (setting.ProcessName__c == SETTING_ACCT_PROCESS_NAME && setting.isActive__c ) {
if (newA.get(setting.Attribute1__c) != oldA.get(setting.Attribute1__c)) {
changed = true;
break;
}
} // if (setting.ProcessName__c
} // for (PaychexSettings__c setting
*/
        } // if (!changed
        System.debug('checkForOwnerEval 4 changed='+changed);
        return changed;
    } // checkForOwnerEval
    
    public static Boolean checkForAcctTeamEval(Account newA, Account oldA) {
        Boolean changed = ((oldA == null && (newA.HRS_Account_Owner__c != null
                                             || newA.HNBF_Account_Owner__c != null
                                             || newA.OasisPEOAccountOwner__c != null
                                             || newA.Premier_PBS_Account_Owner__c != null
                                             || newA.HR_Generalist__c != null
                                             || newA.HR_Manager__c != null
                                             || newA.ESR_Person_ID__c != null))
                           || (oldA != null && (newA.OwnerId != oldA.OwnerId
                                                || newA.HRS_Account_Owner__c != oldA.HRS_Account_Owner__c
                                                || newA.HNBF_Account_Owner__c != oldA.HNBF_Account_Owner__c
                                                || newA.OasisPEOAccountOwner__c != oldA.OasisPEOAccountOwner__c
                                                || newA.Premier_PBS_Account_Owner__c != oldA.Premier_PBS_Account_Owner__c
                                                || newA.HR_Generalist__c != oldA.HR_Generalist__c
                                                || newA.HR_Manager__c != oldA.HR_Manager__c
                                                || newA.ESR_Person_ID__c != oldA.ESR_Person_ID__c
                                                || newA.Clear_Sales_Team__c != oldA.Clear_Sales_Team__c)));    //APR0157517: Added criteria for Clear_Sales_Team__c
        System.debug('checkForAcctTeamEval acct='+newA.Name+' changed='+changed);
        return changed;
    } // checkForAcctTeamEval
    
    // see if one of the owner fields changed on the referral account
    public static Boolean checkForAcctOwnerChange(Referral_Account__c newA, Referral_Account__c oldA) {
        Boolean changed = (newA.OwnerId != oldA.OwnerId
                           || newA.HRS_Account_Owner__c != oldA.HRS_Account_Owner__c
                           || newA.HNBF_Account_Owner__c != oldA.HNBF_Account_Owner__c
                           || newA.Premier_PBS_Account_Owner__c != oldA.Premier_PBS_Account_Owner__c
                           || newA.MMS_Account_Owner__c != oldA.MMS_Account_Owner__c
                           || newA.Internal_Wholesaler_Account_Owner__c != oldA.Internal_Wholesaler_Account_Owner__c);
        System.debug('checkForAcctOwnerChange changed='+changed);
        return changed;
    } // checkForAcctOwnerChange
    
    public static Boolean CHECK_REFERRAL_ZIP = (Label.Referral_Check_Zip_Change == 'Yes');
    
    // all accounts where the record type changed due to the trigger action.
    public static Id[] recordTypeChangedIds = new Id[]{};
        
        public static Boolean evaluateBranchNumber(Account newA, Account oldA) {
            Integer oldBranchNbr = AccountHelper.getBranchNumber(oldA);
            Integer newBranchNbr = AccountHelper.getBranchNumber(newA);
            
            Boolean branchDivisionChanged = false;
            // both should have a value we're starting with
            if (oldBranchNbr != null && newBranchNbr != null) {
                Boolean newIsMMS = (newBranchNbr >= 400 && newBranchNbr <= 499);
                Boolean oldIsMMS = (oldBranchNbr >= 400 && oldBranchNbr <= 499);
                branchDivisionChanged = (newIsMMS != oldIsMMS);
            } // if (oldBranchNbr != null
            
            return branchDivisionChanged;
        } // evaluateBranchNumber
    
    //Freeze Zip Segmentation if necessary
    public static Boolean DISABLE_ZIP_SEGMENTATION = Label.Disable_Zip_Segmentation_Evaluation == 'Y';
    
    // only evaluate the segmentation for the core/mms record types
    public static Boolean checkForSegmentationEvaluation(Account newA, Account oldA) {
        Boolean changed = false;
        Map<String,Schema.RecordTypeInfo> rtMap = Account.sObjectType.getDescribe().getRecordTypeInfosByName();
        Set<Id> recordTypeIdSet = new Set<Id>();
        recordTypeIdSet.add(rtMap.get(RecordTypeHelper.CORE_ACCOUNT).getRecordTypeId());
        recordTypeIdSet.add(rtMap.get(RecordTypeHelper.MMS_ACCOUNT).getRecordTypeId());
        
        
        if (!newA.ByPassSegmentationEval__c) {
            System.debug('checkForSegmentationEvaluation account segmentation bypassed');
            // only evaluate if Zip Segmentation is disabled
            if(!DISABLE_ZIP_SEGMENTATION) {
                // only evaluate on an update
                if (oldA != null && recordTypeIdSet.contains(newA.RecordTypeId) 
                    && (newA.EvaluatePayrollSegmentation__c 
                        || (newA.OwnerId != oldA.OwnerId)  // owner changes
                        || (newA.Lost_Date__c != null && oldA.Lost_Date__c == null) // lost date is added
                        || (evaluateBranchNumber(newA,oldA))
                       ) 
                   ) {
                       changed = evaluateSegmentation(newA,oldA);
                       //} else if (oldA == null && newA.AccountNumber != null) {
                   } else if (oldA == null || (oldA != null && newA.AccountNumber != null && newA.AccountNumber != oldA.AccountNumber)) {
                       // if a new account or the account number changes.
                       changed = evaluateSegmentation(newA,oldA);
                   } // if (newA.EvaluatePayrollSegmentation__c
            }// if (!DISABLE_ZIP_SEGMENTATION) 
        } else {
            newA.ByPassSegmentationEval__c = false;
        }
        return changed;
    } // checkForSegmentationEvaluation
    
    public static Boolean evaluateSegmentation(Account newA, Account oldA) {
        Boolean changed = false;
        newA.EvaluatePayrollSegmentation__c = false;
        // did we find a match based on number of employees?
        RecordType__c rtEmpMatch = null;
        //APR0161315: Change record type to MMS if Account is a prospect in 10-19 EE space
        if(!newA.CurrentClient__c && !newA.LostClient__c && newA.NumberOfEmployees >= Integer.valueOf(Label.MMS_Prospect_Emp_Min) && newA.NumberOfEmployees <= Integer.valueOf(Label.MMS_Prospect_Emp_Max)){
            rtEmpMatch = RecordType__c.getInstance(RecordTypeHelper.MMS_ACCOUNT);
            System.debug('evaluateSegmentation match on prospect in 10-19 space');
        }
        // if current preview client (based on branch number), leave the record type the same
        if (rtEmpMatch == null && AccountHelper.isCurrentClient(newA)) {
            Integer branchNbr = AccountHelper.getBranchNumber(newA);
            if ((branchNbr != null && branchNbr >= 400 && branchNbr <= 499) || (newA.CSSR_Segment__c != null && newA.CSSR_Segment__c == true && newA.RecordTypeId == RecordTypeHelper.getRecordType(RecordTypeHelper.MMS_ACCOUNT, ObjectHelper.OBJECT_ACCOUNT).getRecordTypeId())) {
                rtEmpMatch = RecordType__c.getInstance(RecordTypeHelper.MMS_ACCOUNT);
                System.debug('evaluateSegmentation match on current client and payroll branch number');
            }
        } // if (AccountHelper.isCurrentClient(newA
        if (rtEmpMatch == null) {
            rtEmpMatch = AccountHelper.getAcctRecordTypeMatch(newA.NumberOfEmployees);
            
        }
        
        // if a match is found based on employee count
        if (rtEmpMatch != null) {
            // get the record type id
            Schema.RecordTypeInfo recordTypeInfo = RecordTypeHelper.getRecordType(rtEmpMatch.Name, ObjectHelper.OBJECT_ACCOUNT);
            System.debug('evaluateSegmentation newA.RecordTypeId='+newA.RecordTypeId+' recordTypeInfo='+recordTypeInfo);
            if (recordTypeInfo != null && recordTypeInfo.getRecordTypeId() != newA.RecordTypeId) {
                newA.RecordTypeId = recordTypeInfo.getRecordTypeId();
                recordTypeChangedIds.add(newA.Id);
                System.debug('evaluateSegmentation recordType for '+newA.Name+' changed to '+newA.RecordTypeId);
                changed = true;
            }
        } // if (rtEmpMatch != null
        
        return changed;
    } // evaluateSegmentation
    
    // moving logic to the before trigger. If it's an insert, the save of the account team members will happen in the after trigger.
    public class AcctTeamInsert {
        public AcctTeamInsert(Account p_acct, AccountTeamMember p_atm) {
            acct = p_acct;
            atm = p_atm;
        }
        public Account acct;
        public AccountTeamMember atm;
    } // class AcctTeamInsert
    
    // on the insert of a record, since we're doing this in the before trigger, save these records to process in the after trigger.
    public static AcctTeamInsert[] atmsToInsert = new AcctTeamInsert[]{};
        
        public static Map<String,User> getAcctUsers(Account[] accts) {
            Set<Id> userIdSet = new Set<Id>();
            Set<Id> ctctIdSet = new Set<Id>();
            Set<String> personIdSet = new Set<String>();
            
            for (Account acct : accts) {
                userIdSet.add(acct.OwnerId);
                if (acct.HRS_Account_Owner__c != null) {
                    userIdSet.add(acct.HRS_Account_Owner__c);
                }
                if (acct.HNBF_Account_Owner__c != null) {
                    userIdSet.add(acct.HNBF_Account_Owner__c);
                }
                if (acct.OasisPEOAccountOwner__c != null) {
                    userIdSet.add(acct.OasisPEOAccountOwner__c);
                }
                if (acct.Premier_PBS_Account_Owner__c != null) {
                    userIdSet.add(acct.Premier_PBS_Account_Owner__c);
                }
                if (acct.HR_Generalist__c != null) {
                    ctctIdSet.add(acct.HR_Generalist__c);
                }
                if (acct.HR_Manager__c != null) {
                    ctctIdSet.add(acct.HR_Manager__c);
                }
                if (acct.ESR_Person_ID__c != null) {
                    personIdSet.add(acct.ESR_Person_ID__c);
                }
            } // for (Account acct : accts
            System.debug('getAcctUsers userIdSet='+userIdSet.size()+' ctctIdSet='+ctctIdSet.size()+' personIdSet='+personIdSet.size());
            Map<String,User> userMap = new Map<String,User>();
            User[] users1 = (userIdSet.isEmpty() ? new User[]{} : [Select Id,Name,HR_Person_Id__c,IsActive FROM User where IsActive=true and Id in :userIdSet ]);
            User[] users2 = (personIdSet.isEmpty() ? new User[]{} : [Select Id,Name,HR_Person_Id__c,IsActive FROM User where IsActive=true and HR_Person_Id__c in :personIdSet ]);
            Contact[] ctcts = (ctctIdSet.isEmpty() ? new Contact[]{} : [Select Id, Name, User_Lookup__c, User_Lookup__r.Id, User_Lookup__r.Name, User_Lookup__r.HR_Person_Id__c, User_Lookup__r.IsActive
                                                                        From Contact where Id in :ctctIdSet and  User_Lookup__r.IsActive=true]);
            for (User usr : users1) {
                userMap.put(usr.Id, usr);
            }
            for (User usr : users2) {
                userMap.put(usr.HR_Person_Id__c, usr);
            }
            for (Contact ctct : ctcts) {
                userMap.put(ctct.Id, ctct.User_Lookup__r);
            }
            System.debug('getAcctUsers userMap='+userMap.size());
            return userMap;
        } // getAcctUsers
    
    public static Set<Id> getAcctRecordTypeIdSet() {
        // get the record types we want to process
        Map<String,Schema.RecordTypeInfo> acctRtMap = Account.SObjectType.getDescribe().getRecordTypeInfosByName();
        
        Set<Id> acctRTIdSet = new Set<Id>();
        for (RecordType__c rt : RecordType__c.getAll().values()) {
            if (rt.ObjectName__c == ObjectHelper.OBJECT_ACCOUNT && rt.UsedInOwnership__c && String.isNotBlank(rt.RecordTypeName__c)) {
                Schema.RecordTypeInfo rtInfo = acctRtMap.get(rt.RecordTypeName__c);
                if (rtInfo != null) {
                    acctRTIdSet.add(rtInfo.getRecordTypeId());
                }
            }
        } // for (RecordType__c rt
        System.debug('getAcctRecordTypeIdSet acctRTIdSet='+acctRTIdSet.size());
        return acctRTIdSet;
    } // getAcctRecordTypeIdSet
    
    // these will run in the after trigger - push from the parents to the children
    public static Id[] parentIdsToPush = new Id[]{};
        
        public static void processAccountsBefore(Account[] accts) {
            Set<Id> acctRTIdSet = getAcctRecordTypeIdSet();
            // if it's a child, pull from the parent
            Account[] childAccts = new Account[]{};
                Id[] parentAcctIds = new Id[]{};
                    
                    Set<String> zipCodes = new Set<String>();
            
            Account[] checkOwnerAccts = new Account[]{};
                // the ids of the accounts we're processing
                Id[] acctIds = new Id[]{};
                    
                    for (Account acct : accts) {
                        if (acct.SalesParent__c != null) {
                            childAccts.add(acct);
                            parentAcctIds.add(acct.SalesParent__c);
                            if (acct.id != null) {
                                acctIds.add(acct.Id);
                            }
                        } else if (acct.RecordTypeId != null && acctRTIdSet.contains(acct.RecordTypeId)) {
                            checkOwnerAccts.add(acct);
                            if (acct.id != null) {
                                acctIds.add(acct.Id);
                            }
                            if (String.isNotBlank(acct.Owner_Zip_Code__c)) {
                                zipCodes.add(acct.Owner_Zip_Code__c);
                            }
                        }   
                    } // for (Account acct : accts
            
            System.debug('processAccountsBefore checkOwnerAccts='+checkOwnerAccts.size()+' childAccts='+childAccts.size());
            if (checkOwnerAccts.isEmpty() && childAccts.isEmpty()) {
                return;
            }
            // the contacts that will be updated
            Contact[] updateCtcts = new Contact[]{};
                // the Account team members that are created or deleted
                AccountTeamMember[] insertAcctTeams = new AccountTeamMember[]{};
                    AccountTeamMember[] deleteAcctTeams = new AccountTeamMember[]{};
                        
                        Map<Id,Map<String,AccountTeamMember>> atmByAcctIdMap = new Map<Id,Map<String,AccountTeamMember>>();
            Map<Id,Contact[]> ctctsByAcctIdMap = new Map<Id,Contact[]>();
            getOtherAcctInfo(acctIds, deleteAcctTeams, atmByAcctIdMap, ctctsByAcctIdMap);
            
            if (!checkOwnerAccts.isEmpty()) {
                setupRecordTypeMaps();
                
                
                Map<String,User> userMap = getAcctUsers(checkOwnerAccts);
                Map<String,List<Zip_Assignment__c>> zipMap = getZipAsgns(zipCodes, ZipQueries.FILTER_ACCOUNTS);
                
                
                System.debug('processAccountsBefore zipMap='+zipMap.size()+' atmByAcctIdMap='+atmByAcctIdMap.size()+' ctctsByAcctIdMap='+ctctsByAcctIdMap.size());
                for (Account acct : checkOwnerAccts) {
                    Zip_Assignment__c[] zipList = (String.isNotBlank(acct.Owner_ZipCode__c) ? zipMap.get(acct.Owner_ZipCode__c) : new Zip_Assignment__c[]{});
                    Map<String,AccountTeamMember> atmMap = (acct.Id != null && atmByAcctIdMap.containsKey(acct.Id) ? atmByAcctIdMap.get(acct.Id) : new Map<String,AccountTeamMember>());
                    Contact[] ctcts = (acct.Id != null && ctctsByAcctIdMap.containsKey(acct.Id) ? ctctsByAcctIdMap.get(acct.Id) : new Contact[]{});
                    Boolean acctChanged = checkAccount(acct,zipList,updateCtcts,insertAcctTeams, deleteAcctTeams, userMap, atmMap, ctcts);
                    
                    // if we're in here, always check the children
                    if (acct.Id != null && acct.isParent__c && !AccountJunctionMethods.parentIdsProcessed.contains(acct.Id)) {
                        parentIdsToPush.add(acct.Id);
                    }                                                                      
                } // for (Account acct
                
            } // if (!checkOwnerAccts.isEmpty
            
            if (!childAccts.isEmpty()) {
                ZipCheckOwner.setupRecordTypeMaps();
                Account[] parentAccts = getAccounts(parentAcctIds,rtById.keySet());
                Map<Id,Account> parentMap = new Map<Id,Account>(parentAccts);
                for (Account child : childAccts) {
                    Account parentAcct = parentMap.get(child.SalesParent__c);
                    if (parentAcct != null) {
                        AccountTeamMember[] childAtms = (child.Id != null && atmByAcctIdMap.containsKey(child.Id) ? atmByAcctIdMap.get(child.Id).values() : new AccountTeamMember[]{});
                        AccountJunctionMethods.pushToChild(parentAcct, child, parentAcct.AccountTeamMembers, childAtms, insertAcctTeams, deleteAcctTeams, updateCtcts);
                    }
                }
                
            } // if (!childAccts.isEmpty
            
            SKIP_TRIGGERS = true;
            DmlHelper.performDML2(updateCtcts, DmlHelper.DML_UPDATE, 'ZipCheckOwner', 'processAccounts', 'Update Contacts', true);
            
            saveAcctTeams(insertAcctTeams,deleteAcctTeams);
            SKIP_TRIGGERS = false;
            
        } // processAccountsBefore
    
    // get a map of the account team by role name
    public static void getOtherAcctInfo(Id[] acctIds, AccountTeamMember[] deleteAcctTeams
                                        , Map<Id,Map<String,AccountTeamMember>> atmByAcctIdMap, Map<Id,Contact[]> ctctsByAcctIdMap) {
                                            if (!acctIds.isEmpty()) {
                                                // select into an account so that the atms and contacts are bundled together
                                                String query = getAcctQuery2();
                                                query += ' where id in :acctIds';
                                                Account[] tempAccts = Database.query(query);
                                                for (Account acct : tempAccts) {
                                                    if (!acct.Contacts.isEmpty()) {
                                                        ctctsByAcctIdMap.put(acct.Id, acct.Contacts);
                                                    } 
                                                    Map<String,AccountTeamMember> atmMap = (atmByAcctIdMap.containsKey(acct.Id) ? atmByAcctIdMap.get(acct.Id) : new Map<String,AccountTeamMember>());
                                                    atmByAcctIdMap.put(acct.Id, atmMap);
                                                    for (AccountTeamMember atm : acct.AccountTeamMembers) {
                                                        // don't add inactive users
                                                        if (!atm.User.IsActive) {
                                                            deleteAcctTeams.add(atm);
                                                        } else {
                                                            atmMap.put(atm.TeamMemberRole, atm);
                                                        }
                                                    } // for (AccountTeamMember atm : acct.AccountTeamMember
                                                } // for (Account acct
                                            } // if (!acctIds.isEmpty
                                        } // getOtherAcctInfo
    
} // class ZipCheckOwner