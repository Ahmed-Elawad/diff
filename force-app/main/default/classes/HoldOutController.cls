/* 

History
--------

5/15/2015 Josh Cartwright   created
9/10/2015 Josh Cartwright added mass assign holdout functionality 
9/14/2015 Josh Cartwright added Referral Contact to Mass Assign 
3/23/2016 Josh Cartwright changed class to use standardSetController 
3/29/2017 Josh Cartwright - added code to send re-assignments over a limit to queueable job 
04/13/20017 Sunnish Annu added new filter field Refferal account name  to query
02/14/2018  Sunnish Annu added a new column to the Account display table
06/03/2020  Jake Hinds	 adding permanent hold out reason to referral account
*/  

public with sharing class HoldOutController {
    
    public ManageZipAssignController mzac {get;set;} 
    
    public ApexPages.StandardSetController selectedController{get;set;}
    public boolean isQueueable {get;set;}
    
    
    
    public HoldOutController(){  
        mzac = new ManageZipAssignController(); 
        selectReassignUser = false;
        objectSelect = REF_CTCT; 
        districtSelected();
        zipLow = '00000';
        zipHigh = '99999';  
        useFilter = false; 
        isQueueable = false; 
        queryAcct = new Account();
        
    } 
    
    public Boolean recordsFound{get;private set;}
    private ApexPages.StandardSetController stdSetController;
    private String returnPrefix = null;
    public boolean isAssignAcct = false;
    public boolean isAssignRefAcct = false;
    public boolean isReAssignAcct = false;
    public String StrAccPartner{get;set;}
    
    
    
    /** The records that were passed in from the list view. */
    //public list <SObject> selectedRecords{get;set;}
    
    public HoldOutController(ApexPages.StandardSetController stdSetController){
        mzac = new ManageZipAssignController();               
        this.stdSetController = stdSetController;        
        //selectedRecords = new list <SObject>();
        
        displaylist = new list <HoldoutWrapper>(); 
        //       displaylistOld = new list <HoldoutWrapper>();
        recordsFound = !stdSetController.getSelected().isEmpty();
        if (!recordsFound) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'At least one record must be selected to proceed!'));
            return;
        }
        
        Id[] recordIds = new Id[]{};
            
            for(SObject sobj: stdSetController.getSelected()) {
                //selectedRecords.add(sobj);
                recordIds.add(sobj.Id);
                //displaylistOld.add(new HoldoutWrapper(sobj));
                
            }
        
        init(recordIds,stdSetController.getSelected()[0]);
        
    }
    
    public void init(Id[] recordIds, SObject checkRec) {
        Boolean okay = true;
        // if no records were selected, give the user an error
        String objectName = checkRec.getSObjectType().getDescribe().getName();
        mzac.setReassignOrgs();
        if (objectName == 'Referral_Account__c') {
            okay = setupRefAccts(recordIds); 
        }// if referral account
        
        if (objectName == 'Referral_Contact__c') {
            okay = setupRefCtcts(recordIds); 
            
        }// if referral contact
        
        if (objectName == 'Account') {
            okay = setupAccts(recordIds); 
            
        }// account
        
        if (!okay) {
            // yada yada
        }
        
    } // init
    
    public Boolean setupRefAccts(Id[] recordIds) {
        Boolean okay = true;   
        String query = RA_QUERY_1 + ' where Id in :recordIds';
        HoldOutWrapper[] newList = new HoldOutWrapper[]{};
            List<Id> ownerIds = new List<Id>();
        for (Referral_Account__c refAcct : Database.query(query)) {
            HoldOutWrapper how = new HoldOutWrapper(refAcct);
            ownerIds.add(how.ownerId);     
            newList.add (how); 
        }
        objectSelect = REF_ACCT; 
        reAssignDistrictSelected();    
        returnPrefix = ObjectHelper.getObjectPrefix(ObjectHelper.OBJECT_REF_ACCOUNT);
        checkVisibility(newList, ownerIds);
        isAssignRefAcct = true;
        
        return okay;
    } // setupRefAccts
    
    public Boolean setupRefCtcts(Id[] recordIds) {
        Boolean okay = true;   
        String query = RC_QUERY_1 + ' where Id in :recordIds';
        HoldOutWrapper[] newList = new HoldOutWrapper[]{};
            List<Id> ownerIds = new List<Id>();
        for (Referral_Contact__c refCtct : Database.query(query)) {
            HoldOutWrapper how = new HoldOutWrapper(refCtct);
            ownerIds.add(how.ownerId);     
            newList.add (how); 
        }
        objectSelect = REF_CTCT;
        reAssignDistrictSelected();    
        returnPrefix = ObjectHelper.getObjectPrefix(ObjectHelper.OBJECT_REF_CONTACT);
        checkVisibility(newList, ownerIds);
        
        
        return okay;
    } // setupRefAccts
    
    public Boolean setupAccts(Id[] recordIds) {
        Boolean okay = true;   
        String query = A_QUERY_1 + ' where Id in :recordIds';
        HoldOutWrapper[] newList = new HoldOutWrapper[]{};
            List<Id> ownerIds = new List<Id>();
        for (Account acct : Database.query(query)) {
            HoldOutWrapper how = new HoldOutWrapper(acct);
            ownerIds.add(how.ownerId);     
            newList.add (how); 
        }
        objectSelect = ACCT; 
        reAssignDistrictSelected();    
        returnPrefix = ObjectHelper.getObjectPrefix(ObjectHelper.OBJECT_ACCOUNT);
        checkVisibility(newList, ownerIds);
        isAssignAcct = true; 
        
        
        return okay;
    } // setupAccts
    
    
    
    // Determines if the record can be assigned a hold out - checks access and if a hold out exists 
    public void checkVisibility(HoldOutWrapper[] wrappers, Id[] ownerIds) {
        displaylist = new List <HoldOutWrapper>();
        noAccessList = new List <HoldOutWrapper>();
        
        UserHelper.areUsersVisible (UserHelper.getRunningUser(), ownerIds);
        
        
        //remove if statements - use variables defined in hold out wrapper. 
        
        if (isRefAcct){
            for(HoldOutWrapper how: wrappers){
                if(UserHelper.userIdVisibleSet.contains (how.ownerId) & (how.refAcct.Hold_Out__c == false)){
                    displaylist.add(how);
                }//if    
                
                else{
                    if(!UserHelper.userIdVisibleSet.contains (how.ownerId)){
                        
                        how.noAccessReason = 'No Access';
                    } else if (how.refAcct.Hold_Out__c == true){
                        how.noAccessReason = 'Hold Out Exists';
                        
                    }//else if 
                    noAccessList.add(how);
                    
                }//else
                
            }//for
        } // if isrefacct
        
        if (isRefCtct){
            for(HoldOutWrapper how: wrappers){
                if(UserHelper.userIdVisibleSet.contains (how.ownerId) & (how.refCtct.Hold_Out__c == false)){
                    displaylist.add(how);
                }//if    
                
                else{
                    if(!UserHelper.userIdVisibleSet.contains (how.ownerId)){
                        
                        how.noAccessReason = 'No Access';
                    } else if (how.refCtct.Hold_Out__c == true){
                        how.noAccessReason = 'Hold Out Exists';
                        
                    }//else if 
                    noAccessList.add(how);
                    
                }//else
                
            }//for
        } // if isrefctct
        
        if (isAcct){
            for(HoldOutWrapper how: wrappers){
                if(UserHelper.userIdVisibleSet.contains (how.ownerId) & (how.acct.Hold_Out__c == false)){
                    displaylist.add(how);
                }//if    
                
                else{
                    if(!UserHelper.userIdVisibleSet.contains (how.ownerId)){
                        
                        how.noAccessReason = 'No Access';
                    } else if (how.acct.Hold_Out__c == true){
                        how.noAccessReason = 'Hold Out Exists';
                        
                    }//else if 
                    noAccessList.add(how);
                    
                }//else
                
            }//for
        } // if isrefacct
        
        
        //for (holdOutWrappers how: wrappers){
        
        
        //}
        
        
        if(displaylist.isEmpty()){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'No records can be assigned, please use the cancel button to go back and select records you have access to without a hold out'));
            
            
        }//if 
        
        /*       
//added to remove hold out records from display list and add to no access list
for(HoldOutWrapper how: displaylistOld){
if(how.holdOut){
displaylistOld.remove(how);
noAccessList.add(how);
}// if 
}//for
*/
    } // checkVisibility
    
    public String selectedRepId{get;set;} 
    
    public boolean hasSelectedRepID{
        get{return string.isNotBlank(selectedRepID); 
           }//get return string.isNotBlank
        
    }   // hasSelectedRepID 
    
    public String objectSelect {get;set;} 
    
    public Boolean isRefCtct{ get {return (String.isNotBlank(objectSelect) && objectSelect == REF_CTCT);}}
    public Boolean isRefAcct{ get {return (String.isNotBlank(objectSelect) && objectSelect == REF_ACCT);}}
    public Boolean isAcct {get {return (string.isNotBlank(objectSelect) && objectSelect == ACCT);}} 
    public Boolean isCtct {get {return (string.isNotBlank(objectSelect) && objectSelect == CTCT);}} 
    
    // -  removed calculating on page : public integer columnSize {get {return(isRefCtct || isRefAcct ? 1 : 2);}}
    
    public String reAssignSelectedRepId{get;set;}
    
    public List<SelectOption> repOptions{get;set;} 
    
    public List<SelectOption> reAssignRepOptions{get;set;}
    
    public boolean hasRepOptions {
        get{return (repOptions !=null && !repOptions.isEmpty());} 
    }
    
    public boolean hasReassignRepOptions {
        get{return (reassignRepOptions !=null && !reassignRepOptions.isEmpty());} 
    }    
    
    public void zoneSelected(){
        mzac.setZone(); 
        districtSelected(); 
    }//zoneSelected
    
    public void reassignZoneSelected(){
        mzac.setReassignZone(); 
        reAssignDistrictSelected(); 
    }//reassignZoneSelected
    
    public void districtSelected (){  
        
        selectedController = null; 
        selectedRepId = null; 
        mzac.selectedDistrictOrgUnit = null; 
        mzac.checkDistrictId();
        //   displaylistOld = null;
        displaylist = null; 
        //   ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'districtSelected mzac.selectedDistrictOrgUnit='+mzac.selectedDistrictOrgUnit));
        if (mzac.selectedDistrictOrgUnit != null) {
            // select the reps
            repOptions= getDistrictReps (mzac.SelectedDistrictOrgUnit, true); 
        }
    } // districtSelected
    
    public void salesOrgSelected() {
        mzac.changeOrgStructure();
        districtSelected(); 
    } 
    
    public void reassignSalesOrgSelected(){
        mzac.changeOrgStructure();
        mzac.setReassignOrgs();
        reassignZoneSelected();
        reAssignDistrictSelected();
    }//reassignSalesOrgSelected
    
    public void reAssignDistrictSelected (){  
        
        reAssignSelectedRepId = null; 
        reassignRepOptions = null;
        mzac.selectedReassignDistrictOrgUnit = null;
        mzac.checkReassignDistrictId();
        //   ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'districtSelected mzac.selectedDistrictOrgUnit='+mzac.selectedDistrictOrgUnit));
        if (mzac.selectedReassignDistrictOrgUnit != null) {
            // select the reps
            reassignRepOptions= getDistrictReps (mzac.selectedReassignDistrictOrgUnit, false); 
        }
    } // districtSelected 
    
    public List<SelectOption> getDistrictReps(Org_Unit__c district, Boolean transferFromUsers) {
        List<SelectOption> districtReps = new List<SelectOption>();
        if (district != null) {
            map<string,user> userMap = new map <string,user>(); 
            for(Org_Unit_User_Link__c ouul: district.Org_Unit_User_Links__r){
                if(ouul.user__r.isactive){
                    string key = ouul.user__r.lastName + ',' + ouul.user__r.firstName; 
                    //User usr = new User(Id=ouul.user__r.Id, FirstName=ouul.user__r.FirstName, LastName=ouul.user__r.LastName, Comments__c=ouul.user__r.Name);
                    User usr = ouul.user__r;
                    usr.Comments__c = usr.Name;
                    // ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'getDistrictReps key='+key));
                    userMap.put(key, usr);  
                }
            }// for(Org_Unit_User_Link__c ouul 
            
            
            if (transferFromUsers) {
                getHoldOutCounts(district, userMap); 
            }//(!activeOnly) 
            
            if(!userMap.isEmpty()){
                list<string> sortedNames = new list<string>(); 
                sortedNames.addAll(userMap.keyset()); 
                sortedNames.sort(); 
                districtReps.add(new SelectOption('','Select a Rep'));
                for(string key: sortedNames){
                    User districtUser = userMap.get(key); 
                    //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'getDistrictReps addToSelectOption nameOfUser='+nameOfUser));
                    districtReps.add(new SelectOption(districtUser.id, districtUser.Comments__c)); 
                }//for userName 
                
                
            }//if(!userMap.isEmpty()
            
            
            
        } // if (district != null
        return districtReps;
    } // getDistrictReps
    
    
    public void getHoldOutCounts(Org_Unit__c district, map<string,user> userMap){
        
        Set<String> roleIdSet = new Set<String> (); 
        
        if(district != null){ 
            if(String.isNotBlank(district.RepUserRoleId__c)){
                roleIdSet.add(district.RepUserRoleId__c);
            }//if(String.isNotBlank
            
            if(String.isNotBlank(district.UserRoleId__c)){
                roleIdSet.add(district.UserRoleId__c);
            }//if(String.isNotBlank. UserRoleId__c
            
        }//if(district != null
        
        System.debug('getHoldOutCounts roleIdSet='+roleIdSet);
        if(!roleIdSet.isEmpty()){
            
            AggregateResult[] userResults = null;
            User[] holdOutUsers = null;
            If(isRefCtct){  
                userResults = [Select Owner.Id ownerId, Owner.Name ownerName, Owner.FirstName ownerFirstName, Owner.LastName ownerLastName, Owner.IsActive isActive, count(Id) nbr_recs 
                               from Referral_Contact__c 
                               where Hold_Out__c = true 
                               and User_Lookup__r.UserRoleId in :roleIdSet
                               //and Owner.UserRoleId in :roleIdSet
                               //and Owner.IsActive = false
                               group by Owner.Id , Owner.Name, Owner.FirstName, Owner.LastName, Owner.isActive];
            } else If(isRefAcct){  
                
                userResults = [Select Owner.Id ownerId, Owner.Name ownerName, Owner.FirstName ownerFirstName, Owner.LastName ownerLastName, Owner.IsActive isActive, count(Id) nbr_recs 
                               from Referral_Account__c  
                               where Hold_Out__c = true 
                               and User_Lookup__r.UserRoleId in :roleIdSet 
                               //and Owner.UserRoleId in :roleIdSet
                               //and Owner.IsActive = false
                               group by Owner.Id , Owner.Name, Owner.FirstName, Owner.LastName, Owner.isActive]; 
                
            } else If(isAcct){  
                
                holdOutUsers = [Select Id, firstname, lastname, name, comments__c, isactive from User
                                Where Id in (Select OwnerId from Account where Hold_Out__c=true and Owner.UserRoleId in :roleIdSet)];       
            }else If(isCtct){  
                
                holdOutUsers = [Select Id, firstname, lastname, name, comments__c, isactive from User
                                Where Id in (Select OwnerId from Contact where Hold_Out__c=true and Owner.UserRoleId in :roleIdSet)];                                
                
            }// elese if is Ctct   
            
            //        system.debug('holdOutUsers size = '+ holdOutUsers.size());
            
            if(holdOutUsers != null &&(isCtct || isAcct)){
                //   ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'getHoldOutCounts holdOutUsers='+holdOutUsers.size())); 
                for(User usr : holdOutUsers){
                    string key = usr.LastName+','+usr.FirstName;      
                    User mapUser = userMap.get(key);
                    //   ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'getHoldOutCounts key='+key+' mapUser='+(mapUser != null ? 'found' : 'not found')));
                    //   ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'mapUser.isactive='+(mapUser.isactive + ' id = '+mapuser.id)));
                    //   ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'usr.isactive='+(usr.isactive+ ' id = ' +usr.id)));
                    
                    //  ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'mapUser.id='+(mapUser.id)));
                    
                    
                    if(mapUser == null ){
                        usr.comments__c = usr.name; 
                        userMap.put(key,usr);
                        mapUser = usr;
                    }//if 
                    //       System.debug('Is the User Active? ='+ mapUser.isActive);
                    
                    
                    if(!mapUser.isActive){
                        mapUser.Comments__c+= ' (Inactive)';
                    }//if       
                    
                    
                    mapUser.comments__c += ', Has Hold Out(s)';  
                    
                    system.debug ('comment field results= '+ mapUser.comments__c);    
                    
                }//for 
                
            }//if 
            
            else if (userResults != null && (isRefAcct|| isRefCtct)) {
                for (AggregateResult result : userResults) {
                    Id usrId = (Id)result.get('ownerId');
                    User usr = userMap.get(usrId);
                    if (usr == null) {
                        usr = new User(Id=usrId);
                        usr.FirstName = (String)result.get('ownerFirstName');
                        usr.LastName = (String)result.get('ownerLastName');
                        usr.Comments__c = (String)result.get('ownerName');
                        String key = usr.LastName+','+usr.FirstName;
                        userMap.put(key,usr);
                    } // if (usr == null
                    
                    Boolean isActive = (Boolean)result.get('isActive');
                    if (!isActive) {
                        usr.Comments__c += ' (Inactive)';
                    }
                    Integer nbrRecs = (Integer)result.get('nbr_recs');
                    if (nbrRecs != null && nbrRecs > 0) {
                        usr.Comments__c += ', Hold Outs:'+nbrRecs;
                    }
                } // for (AggregateResult result : userResults
                
            }//if (userResults != null
            
            
        }//if(!roleIdSet.isEmpty
    }//getHoldOutCounts 
    
    /*
public void getHoldOutCounts2(Org_Unit__c district, map<string,user> userMap){

Set<String> roleIdSet = new Set<String> (); 

if(district != null){ 
if(String.isNotBlank(district.RepUserRoleId__c)){
roleIdSet.add(district.RepUserRoleId__c);
}//if(String.isNotBlank

if(String.isNotBlank(district.UserRoleId__c)){
roleIdSet.add(district.UserRoleId__c);
}//if(String.isNotBlank. UserRoleId__c

}//if(district != null

System.debug('getHoldOutCounts roleIdSet='+roleIdSet);
if(!roleIdSet.isEmpty()){

AggregateResult[] userResults = null;
If(isRefCtct){  
userResults = [Select Owner.Id ownerId, Owner.Name ownerName, Owner.FirstName ownerFirstName, Owner.LastName ownerLastName, Owner.IsActive isActive, count(Id) nbr_recs 
from Referral_Contact__c 
where Hold_Out__c = true 
and User_Lookup__r.UserRoleId in :roleIdSet
//and Owner.UserRoleId in :roleIdSet
//and Owner.IsActive = false
group by Owner.Id , Owner.Name, Owner.FirstName, Owner.LastName, Owner.isActive];
} else If(isRefAcct){  

userResults = [Select Owner.Id ownerId, Owner.Name ownerName, Owner.FirstName ownerFirstName, Owner.LastName ownerLastName, Owner.IsActive isActive, count(Id) nbr_recs 
from Referral_Account__c  
where Hold_Out__c = true 
and User_Lookup__r.UserRoleId in :roleIdSet 
//and Owner.UserRoleId in :roleIdSet
//and Owner.IsActive = false
group by Owner.Id , Owner.Name, Owner.FirstName, Owner.LastName, Owner.isActive]; 

} else If(isAcct){  

userResults = [Select Owner.Id ownerId, Owner.Name ownerName, Owner.FirstName ownerFirstName, Owner.LastName ownerLastName, Owner.IsActive isActive, count(Id) nbr_recs 
from Account  
where Hold_Out__c = true 
and Owner.UserRoleId in :roleIdSet 
//and Owner.UserRoleId in :roleIdSet
and Owner.IsActive = false
group by Owner.Id , Owner.Name, Owner.FirstName, Owner.LastName, Owner.isActive]; 
}else If(isCtct){  

userResults = [Select Owner.Id ownerId, Owner.Name ownerName, Owner.FirstName ownerFirstName, Owner.LastName ownerLastName, Owner.IsActive isActive, count(Id) nbr_recs 
from Contact
where Hold_Out__c = true 
and Owner.UserRoleId in :roleIdSet 
//and Owner.UserRoleId in :roleIdSet
and Owner.IsActive = false
group by Owner.Id , Owner.Name, Owner.FirstName, Owner.LastName, Owner.isActive]; 



}// elese if is Ctct   

if (userResults != null) {
for (AggregateResult result : userResults) {
Id usrId = (Id)result.get('ownerId');
User usr = userMap.get(usrId);
if (usr == null) {
usr = new User(Id=usrId);
usr.FirstName = (String)result.get('ownerFirstName');
usr.LastName = (String)result.get('ownerLastName');
usr.Comments__c = (String)result.get('ownerName');
String key = usr.LastName+','+usr.FirstName;
userMap.put(key,usr);
} // if (usr == null

Boolean isActive = (Boolean)result.get('isActive');
if (!isActive) {
usr.Comments__c += ' (Inactive)';
}
Integer nbrRecs = (Integer)result.get('nbr_recs');
if (nbrRecs != null && nbrRecs > 0) {
usr.Comments__c += ', Hold Outs:'+nbrRecs;
}
} // for (AggregateResult result : userResults

}//if (userResults != null

} // roleid 

}//getrep2     

*/
    
    //public list<HoldOutWrapper> displaylistOld{get;set;}
    public list<HoldOutWrapper> noAccessList{get;set;}
    
    public Boolean hasDisplayList{
        get { return (displaylist != null && !displaylist.isEmpty()); }
    }
    
    /*
//temporary variable to display message if displaylistOld contains greater than 100 records
public Boolean largeDisplayListOld{
get{ return (displaylistOld != null && displaylistOld.size() ==100);}
}//largeDisplayList
*/
    public Boolean hasNoAccessList{
        get { return (noAccessList != null && !noAccessList.isEmpty()); }
    }// hasnoaccessList - used in VF page to dispaly table if user does not have access to selected records
    
    public Boolean hasSelectedList{
        get { return (selectedList != null && !selectedList.isEmpty()); }
    }// hasSelectedList - used in VF page to determine if there is a valid selected list for accts
    
    public Boolean selectAll {get;set;}
    
    public static final String RC_QUERY_1 = 'select Id, Name, Zip_Code__c, Referral_Account__c, BypassHoldOut__c, OwnerId, Owner.Name, Hold_Out__c, End_Date__c, Referral_ID__c, Street_Address_1__c, Referral_Type__c, City__c, State__c, Use_Account_Ownership__c '+
        ' from Referral_Contact__c ';
    
    public static final String RC_QUERY_2 = RC_QUERY_1+
        ' where Hold_Out__c = True ';
    
    
    public static final String RA_QUERY_1 = 'select Id, Name, BypassHoldOut__c, OwnerId, Owner.Name, Hold_Out__c, Hold_Out_Reason__c,End_Date__c, Street_Address_1__c, City__c, State_Province__c, Zip_Postal_Code__c, Referral_Source_Business_Type__c, Use_Zip_Assignment_Rules__c '+
        ' from Referral_Account__c ';
    
    public static final String RA_QUERY_2 = RA_QUERY_1+
        ' where Hold_Out__c = True '; 
    
    public static final String A_QUERY_1 = 'select Id, Name, SalesParent__c, SalesParent__r.Name, Owner.Id, Owner.Name, Hold_Out__c, Permanent_Hold_Out_Description__c, ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, AccountNumber, type, Hold_Out_Expiration__c, NumberOfEmployees,Organization_Type__c '+
        ' from Account '; 
    
    public static final String A_QUERY_2 = A_QUERY_1+
        ' where Hold_Out__c = True ';    
    
    public static final String C_QUERY_1 = 'select Id, Name, Owner.Id, AccountID, Owner.Name, Hold_Out__c, MailingStreet, MailingCity, MailingState, MailingPostalCode, Contact_Type__c '+
        ' from Contact '; 
    
    public static final String C_QUERY_2 = C_QUERY_1+
        ' where Hold_Out__c = True ';                                                                            
    
    
    public void getRepHoldoutRecords(){ 
        
        //displaylistOld = new List<HoldOutWrapper>();
        // displaylistOld = null;
        numOfPages = null; 
        displaylist = null; 
        
        system.debug('current object is ' + objectSelect) ;
        
        
        String query = (isRefCtct ? RC_QUERY_2 : (isRefAcct ? RA_QUERY_2 : (isAcct ? A_QUERY_2 : (isCtct ? C_QUERY_2: null ))));
        
        if (query == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'No query found for '+objectSelect));
            return;
        }
        
        query += 'and OwnerId  = :selectedRepID ';
        
        
        system.debug(' Query = ' +query);  
        system.debug('Perm Hold Out Desc =' +pHoldOutDescFilter); 
        
        
        if (useFilter) {
            String zipField = (isRefCtct ? 'Zip_Code__c' : (isRefAcct ? 'Zip_Postal_Code__c': (isAcct ? 'Owner_Zip_Code__c' : (isCtct ? 'MailingPostalCode' : '' ))));
            query += ' and ('+zipField+' >= :zipLow and '+zipField+' <= :zipHigh) ';
            
            if(isRefCtct && referralTypeFilter !=null && referralTypeFilter != ALL) {
                query += ' and Referral_Type__c = :referralTypeFilter';
            }// if(referralTypeFilter)
            
            if(isRefAcct && rsbtFilter !=null && rsbtFilter != ALL) {
                query += ' and Referral_Source_Business_Type__c = :rsbtFilter';
            }// if(referralTypeFilter)
            
            system.debug('getRepHoldOutRecords isAcct ='+ isAcct +' acct.=' + pHoldOutDescFilter) ;
            
            
            
            if(isAcct && pHoldOutDescFilter != null && pHoldOutDescFilter != ALL){
                query+= ' and Permanent_Hold_Out_Description__c = :pHoldOutDescFilter';         
                
                //             query += ' and Permanent_Hold_Out_Description__c = \'' + queryAcct.Permanent_Hold_Out_Description__c + '\'';
                
            }//if acct
            if(isAcct && StrAccPartner!=null && StrAccPartner!='')
            {
                
                query+=' and Referral_National_Account__r.Name like \'%'+StrAccPartner+'%\'';
                System.debug('@@@@@'+query);
                
            }
            
            
        }// if (useFilter)
        
        query += ' order by name';   
        
        /*     Referral_Contact__c [] rCHoldOutList = [select Id, Name, Zip_Code__c, Referral_Account__c, BypassHoldOut__c, OwnerId, Hold_Out__c, Use_Account_Ownership__c 
from Referral_Contact__c 
where Hold_Out__c = True and OwnerId  = :selectedRepID];*/
        
        //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO,'getRepHoldoutRecords ' + rCHoldOutList.size()));
        system.debug('getRepHoldoutRecords selectedRepID=' +selectedRepID + ' query = ' + query); 
        //  try {
        /*   for (SObject rec : Database.query(query)) {
displaylistOld.add(new HoldOutWrapper(rec));       
}//for (SObject rec 


*/
        //clear the selected map when re query       
        selectedMap.clear();   
        //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO,'getRepHoldoutRecords query=' + query));  
        selectedController =  new ApexPages.StandardSetController(Database.getQueryLocator(query));
        selectedController.setPageSize(RECS_PER_PAGE); 
        
        
        
        
        
        /*
query += ' limit 100';
for (SObject rec : Database.query(query)) {
if (isRefCtct) {
displaylistOld.add(new HoldOutWrapper((Referral_Contact__c)rec));  
} else if (isRefAcct) {
displaylistOld.add(new HoldOutWrapper((Referral_Account__c)rec));  
} else if (isCtct){
displaylistOld.add(new HoldOutWrapper((Contact)rec));              
} else if (isAcct){
displaylistOld.add(new HoldOutWrapper((Account)rec));              

}//else if refAcct
}//for (SObject rec

system.debug('displaylistOld size=' + displaylistOld.size());
system.debug('has display list ' + hasDisplayList);

*/
        /* 
for (Referral_Contact__c refCtct : Database.query(query)) {
displaylistOld.add(new HoldOutWrapper(refCtct));       
}//for (Referral_Contact__c refCtct

//  } catch (Exception e) {
//   ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,'Error in Query: ' + e));
// 
}
*/
        
    }//getRepHoldoutRecords   
    
    
    //public static final String PREFIX_REF_CTCT = ObjectHelper.getObjectPrefix(ObjectHelper.OBJECT_REF_CONTACT);
    //public static final String PREFIX_REF_ACCT = ObjectHelper.getObjectPrefix(ObjectHelper.OBJECT_REF_ACCOUNT);
    
    public list <HoldOutWrapper> displaylist{
        get{
            if (displaylist == null && selectedController != null) {
                displaylist = new HoldOutWrapper[]{};
                    
                    for (SObject rec : selectedController.getRecords()) {
                        if (isRefCtct) {
                            displaylist.add(new HoldOutWrapper((Referral_Contact__c)rec));  
                        } else if (isRefAcct) {
                            displaylist.add(new HoldOutWrapper((Referral_Account__c)rec));  
                            //          } else if (isCtct){
                            //          displaylist.add(new HoldOutWrapper((Contact)rec));              
                        } else if (isAcct){
                            displaylist.add(new HoldOutWrapper((Account)rec));            
                            
                            
                            
                        }//else if refAcct
                        
                        
                        //if records were selected, the page was changed, then changed back, record will show as selected
                        displayList[displayList.size()-1].selected = selectedMap.containsKey(displayList[displayList.size()-1].thisRecord.Id);
                        
                    }//for (SObject rec
            }//if
            
            
            return displaylist;
            
        }//get
        private set;
        
    }//displaylist
    
    public class HoldOutWrapper{
        
        private SObject thisRecord = null;
        
        public Referral_Contact__c refCtct {get;set;}
        
        public Referral_Account__c refAcct {get;set;}    
        
        public Account Acct {get;set;}    
        
        //    public Contact Ctct {get;set;}    
        
        
        public boolean selected {get;set;} 
        
        public string noAccessReason {get;set;}
        
        public string permHoldOut {get; set;}
        
        public string newPermHoldOut{get; set;}
        
        public Date holdOutExp {get; set;}
        
        public HoldOutWrapper(Referral_Contact__c p_refCtct){
            refCtct = p_refCtct; 
            thisRecord = refCtct;
            selected = false;      
            holdOutFieldName = ObjectHelper.getHoldOutFieldName(ObjectHelper.OBJECT_REF_CONTACT, UserHelper.SO_CORE);   
            //ownerId = refCtct.OwnerId;
        }//HoldOutWrapper
        
        public HoldOutWrapper(Referral_Account__c p_refAcct){
            refAcct = p_refAcct; 
            thisRecord = refAcct;
            selected = false;         
            holdOutFieldName = ObjectHelper.getHoldOutFieldName(ObjectHelper.OBJECT_REF_ACCOUNT, UserHelper.SO_CORE);   
            //ownerId = refAcct.OwnerId;
            
            
        }//HoldOutWrapper
        
        public HoldOutWrapper(Account p_Acct){
            acct = p_Acct; 
            thisRecord = acct;
            selected = false;        
            permHoldOut = Acct.Permanent_Hold_Out_Description__c;         
            //ownerId = Acct.OwnerId;
            holdOutExp = Acct.Hold_Out_Expiration__c; 
            holdOutFieldName = ObjectHelper.getHoldOutFieldName(ObjectHelper.OBJECT_ACCOUNT, UserHelper.SO_CORE);   
            
        }//HoldOutWrapper    
        
        /*   
public HoldOutWrapper(Contact p_Ctct){
Ctct = p_Ctct; 
selected = false;         
ownerId = Ctct.OwnerId;


}//HoldOutWrapper
*/    
        public Id ownerId {
            get {
                return(thisRecord != null ? (Id)thisRecord.get('OwnerId') : null);
            } // get
            set {
                if (thisRecord != null && value != null) {
                    thisRecord.put('OwnerId',value);
                } // if (value != null
            } // set
        } // ownerId
        
        public String holdOutFieldName{get;set;}
        public Boolean holdOutValue{
            get {
                return (String.IsNotBlank(holdOutFieldName) ? (Boolean)thisRecord.get(holdOutFieldName) : null);
            }
            set {
                if (value != null && thisRecord != null && String.isNotBlank(holdOutFieldName)) {
                    thisRecord.put(holdOutFieldName,value);
                }
            } // set
            
        } // holdOutValue
        
        
        // string for use ownership  - boolean - value to set - use acct ownership, use zip assignment rules - etc 
        // string for holdOutDescription - finds the name of the field for perm hold out 
        
        /*    public HoldOutWrapper(Sobject p_Sobject){
//  refCtct = p_refCtct; 
String idStrPrefix = ((String)p_Sobject.Id).left(3);
if(PREFIX_REF_CTCT == idStrPrefix){
refCtct = (Referral_Contact__c)p_Sobject;
} else if(PREFIX_REF_ACCT == idStrPrefix){
refAcct = (Referral_Account__c)p_Sobject;
}// if refCtct
selected = false; 
}
*/
        
    }//HoldOutWrapper
    
    public boolean selectReassignUser {get;private set;} 
    
    public list <HoldOutWrapper> selectedList{get;set;}
    
    public map <ID, holdOutWrapper> selectedMap = new map <id, holdOutWrapper>(); 
    
    public static string REF_CTCT = 'Referral Contact';
    
    public static string REF_ACCT = 'Referral Account';
    
    public Static string ACCT = 'Account';
    
    public static string CTCT = 'Contact';
    
    //new map to store selected values on each page of displaylist 
    
    public string selectedMessage {
        get{string returnval = ''; 
            if(selectedMap != null && selectedMap.size() >0){
                returnval = selectedMap.size() + ' ' + label.Hold_Out_Selected_Message;
            }//if
            
            
            return returnval; 
           }//get
        
    }// string selectedMessage 
    
    public boolean hasSelectedMessage {
        get{return (selectedMap != null && selectedMap.size() >0);}
    }
    
    
    
    public void addToSelectMap(){
        
        for(HoldOutWrapper how : displaylist){
            if(how.selected){      
                selectedMap.put(how.thisrecord.id, how); 
            }//if      
            
            else{selectedMap.remove(how.thisrecord.id);
                 
                }//else
            
            
            
            
        }//for 
        
        
    }//addToSelectMap 
    
    
    public PageReference assignHoldOut(){
        PageReference pr = null;
        selectedList = displaylist;
        
        if(ReassignSelectedRepID == null){
            apexPages.addMessage(new ApexPages.Message(ApexPages.severity.error,'no rep was selected')); 
            
            return null; 
        }//if 
        
        system.debug('value of isAssignAcct '+ isAssignAcct +' value of newPholdOutdesc= ' +newPholdOutDesc);
        
        if((isAssignAcct || isAssignRefAcct) && newPHoldOutDesc =='--Select--'){
            
            apexPages.addMessage(new ApexPages.Message(ApexPages.severity.error,'Hold Out Reason is required when setting a hold out')); 
            
            return null;   
            
        }//isAssignAcct && newPholdoutdesc
        
        
        if (reAssignRecords(false)) {
            pr = new PageReference('/'+(String.isNotBlank(returnPrefix) ? returnPrefix : '')); 
            pr.setRedirect(true);
        }
        
        return pr;
        
    }//assignHoldOut() 
    
    
    public void reAssignHoldOut(){
        if(isAcct){
            isReAssignAcct = true; 
        }//if is acct 
        queryAcct = new Account();  
        queryCtct = new Contact(); 
        
        
        
        if (verifyRecords() ){
            mzac.setReassignOrgs();
            selectReassignUser = true;
            reAssignDistrictSelected(); 
            
            
            User [] selectedUserName =  [select name 
                                         from User
                                         where ID = :selectedRepID];
            
            
            apexPages.addMessage(new ApexPages.Message(ApexPages.severity.Info,'You are about to update ' + selectedList.size() + ' ' + objectSelect + ' record(s) with holdouts owned by ' +  selectedUserName[0].Name)); 
            
            
            
            
        }//if (!selectedList.isEmpty()
        //  else {
        
        //}
    }//reAssignHoldOut
    
    private Boolean verifyRecords(){
        
        selectedList = new list <HoldOutWrapper>(); 
        noAccessList = new list <HoldOutWrapper>(); 
        
        addToSelectMap(); 
        
        if (!isAcct || (isAcct && !isReAssignAcct)) {
            selectedList.addAll(selectedMap.values());
        } else {
            
            for (HoldOutWrapper how : selectedMap.values()) {
                if (isAcct && string.isNotBlank(how.permHoldOut)) {
                    selectedList.add(how);
                } else if (isAcct && string.isBlank(how.permHoldOut)){
                    noAccessList.add(how);
                }
            } // for (HoldOutWrapper how
        } // else
        system.debug('displaylist.size = ' + displaylist.Size());
        //   system.debug('displaylistOld.size = ' + displaylistOld.Size());
        
        
        /*    
if(displaylist != null && !isAcct){
for(HoldOutWrapper how : displaylist){
if(how.selected){
selectedList.add(how); 
}//if
}//for   
}//(displaylist != null && !isAcct)




if(displaylist != null && isAcct){
for(HoldOutWrapper how : displaylist){

if(how.selected && !isReAssignAcct){
selectedList.add(how); 
}//!isreassignacct 

else if(how.selected && string.isNotBlank(how.permHoldOut)){
selectedList.add(how);       

system.debug ('how.permholdout in: is not blank '+ how.permHoldOut);            

}//if(selected)

else if(how.selected && string.isBlank(how.permHoldOut)){
noAccessList.add(how); 

system.debug ('how.permholdout in: is blank '+ how.permHoldOut);            


}//else if 


}//For(HoldOutWrapper)

}//displaylistOld != null

*/
        
        if(selectedList.isEmpty() && !isAcct){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,'You Must Select at Least One Record ')); 
            
        }
        
        if(selectedList.isEmpty() && isAcct){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,'You Must Select at Least One Record with a Permanent Hold Out to Re-Assign. Records without Permanent Hold Outs cannot be Re-assgined')); 
            
        }
        
        
        
        return !selectedList.isEmpty();
        
    }//public list <HoldOutWrapper> verifyRecords()
    
    public void removeHoldOut(){
        
        //remove if statments - use variables defined in hold out wrapper 
        if(isAcct){
            isReAssignAcct = false; 
        }//if is acct 
        
        if (verifyRecords()) {
            List<SObject> recsToUpdate = new List<SObject>();
            for (HoldOutWrapper how : selectedList) {
                how.holdoutValue = false; 
                
                if (isRefCtct) {
                    how.refCtct.Hold_Out__c = false;
                    how.refCtct.Use_Account_Ownership__c = true; 
                    recsToUpdate.add(how.refCtct);
                } else if (isRefAcct) {
                    how.refAcct.Hold_Out__c = false;
                    how.refAcct.Hold_Out_Reason__c = null;
                    how.refAcct.Use_Zip_Assignment_Rules__c = true;
                    recsToUpdate.add(how.refAcct);
                }
                else if (isAcct) {
                    how.Acct.Hold_Out__c = false;
                    how.Acct.Use_Zip_Assignment_Rules__c = true;
                    how.Acct.Permanent_Hold_Out_Description__c = null; 
                    how.Acct.Hold_Out_Expiration__c = null; 
                    recsToUpdate.add(how.Acct);
                }
                
                system.debug('value of how.permholdout ' + how.PermHoldOut); 
            } // for (HoldOutWrapper
            
            if (!recsToUpdate.isEmpty()) {
                
                system.debug('recstoUpdate Size  ' + recsToUpdate.size());         
                
                
                update recsToUpdate;
                selectReassignUser = false;         
                getRepHoldoutRecords();
                districtSelected();                   
            } // if
            
        } // if (verifyRecords()
        
        
    }//removeHoldOut
    
    
    public void cancelReassign(){ 
        
        if(isQueueable){
            districtSelected();  
            isQueueable = false; 
        }//
        
        selectReassignUser = false;
        getRepHoldoutRecords();
        selectAll = false; 
        
        
        
    }//cancelreassign
    
    /*public void assignRecords(){

if (string.isblank(ReassignSelectedRepID)){
ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,'You Must Select a Rep to Re-assign the Record to ')); 

}//if

else {
for(HoldOutWrapper how: selectedList){

}

}//else


}//assignRecords
*/
    
    public void reAssignRecords(){
        
        reassignRecords(True); 
    }
    
    public static Integer QUEUEABLE_LIMIT = Integer.valueOf(label.Hold_out_Queueable_Limit);
    public Boolean reAssignRecords(boolean retrieveHoldOuts){
        Boolean okay = true;
        /*   ---  can use this to create a list of values to determine if we should update permanent hold out 
SELECT
WHATEVER
Set<String> doNotSet = new Set<String>{SELECT,WHATEVER}
if (!doNotSet.contains(newValue)) {
// set the new description
}
*/  
        //list <Referral_Contact__c> rctoUpdateList = new list <Referral_Contact__c> (); 
        //list <Referral_Account__c> ratoUpdateList = new list <Referral_Account__c> (); 
        List<SObject> updateList = new List<SObject>();
        
        
        if (string.isblank(ReassignSelectedRepID)){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,'You Must Select a Rep to Re-assign the Record to ')); 
            
        }
        // remove all if statements - use variables defined in hold out wrapper     
        
        else if (isRefCtct){
            for(HoldOutWrapper how : selectedList){
                how.refctct.OwnerId = ReassignSelectedRepID;
                how.refctct.BypassHoldOut__c = True; 
                how.refctct.Hold_Out__c = True;
                //rctoUpdateList.add(how.refCtct); 
                updateList.add(how.refCtct);
            }//for(Referral_Contact__c rcRecords : selectedList) 
            
        }//else is isRefCtct
        
        else if (isrefAcct) {
            for(HoldOutWrapper how : selectedList){
                how.refAcct.OwnerId = ReassignSelectedRepID;
                how.refAcct.BypassHoldOut__c = True; 
                how.refAcct.Hold_Out__c = True; 
                if(newPHoldOutDesc !='--Do Not Change--'  && newPHoldOutDesc != '--Select--'){
                    how.refAcct.Hold_Out_Reason__c = newPHoldOutDesc;  
                }//if
                //ratoUpdateList.add(how.refAcct); 
                updateList.add(how.refAcct);
            }//for(Referral_Account__c raRecords : selectedList) 
            
        }//else 
        
        else if (isAcct) {
            for(HoldOutWrapper how : selectedList){
                how.Acct.OwnerId = ReassignSelectedRepID;
                how.Acct.Hold_Out__c = True;   
                
                if(newPHoldOutDesc !='--Do Not Change--'  && newPHoldOutDesc != '--Select--'){
                    how.Acct.Permanent_Hold_Out_Description__c = newPHoldOutDesc;  
                    
                }//if 
                
                
                //ratoUpdateList.add(how.Acct); 
                updateList.add(how.Acct);
            }//for(Account aRecords : selectedList) 
            
        }//else 
        /*      
else if (isCtct) {
for(HoldOutWrapper how : selectedList){
how.Ctct.BypassHoldout__c = true;                 
how.Ctct.OwnerId = ReassignSelectedRepID;                
how.Ctct.Hold_Out__c = True;   
how.Ctct.Hold_Out_Expiration__c = queryCtct.Hold_Out_Expiration__c;  
how.Ctct.Hold_Out_Reason__c = queryCtct.Hold_Out_Reason__c;                           
//ratoUpdateList.add(how.Ctct); 
updateList.add(how.Ctct);
}//for(Contact cRecords : selectedList) 

}//else 
*/
        if (!updateList.isEmpty() && updatelist.size()<QUEUEABLE_LIMIT) { //jc added size list size check 
            
            // make limit a label to be able to adjust size 
            
            update updateList;
            if (retrieveHoldOuts) {
                selectReassignUser =false; 
                repOptions= getDistrictReps (mzac.SelectedDistrictOrgUnit, true); 
                getRepHoldoutRecords();
            }
            
            
        } // if (!updateList.isEmpt
        //JC new code creates queueable job for counts over 50 
        if (!updateList.isEmpty() && updatelist.size()>=QUEUEABLE_LIMIT) {
            
            isQueueable = true;  
            
            User [] reassignSelectedUserName =  [select name 
                                                 from User
                                                 where ID = :ReassignSelectedRepID];
            
            DMLQueueable dmlQueue = new DMLQueueable('The request you made to reassign HoldOuts to '+reassignSelectedUserName[0].Name +' has been completed!', updateList);  
            ID jobID = System.enqueueJob(dmlQueue);
            
            updateList.clear(); 
            
            
            if (retrieveHoldOuts) {
                selectReassignUser =false; 
                repOptions= getDistrictReps (mzac.SelectedDistrictOrgUnit, true); 
                selectedRepId = null; 
                getRepHoldoutRecords();
                
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.info, 'The changes you made are processing, you will receive an email once the process completes. Once you receive email confirmation, please refresh the page.'));
                
            }//if(retrieveholdouts)
            
        }//if (!updateList.isEmpty() && updatelist.size()>=50)
        /*
if (!rctoUpdateList.isEmpty()){ 
update rctoUpdateList; 
selectReassignUser =false; 
repOptions= getDistrictReps (mzac.SelectedDistrictOrgUnit, true); 
getRepHoldoutRecords();


}// If (!rctoUpdateList.isEmpty)



if (!ratoUpdateList.isEmpty()){ 
update ratoUpdateList; 
selectReassignUser =false; 
repOptions= getDistrictReps (mzac.SelectedDistrictOrgUnit, true); 
getRepHoldoutRecords();


}// If (!rctoUpdateList.isEmpty)
*/
        return okay;
    }//reAssignRecords()
    
    
    
    
    // are we going to filter the zip code results?
    public Boolean useFilter{get;set;}
    public String zipLow{get;set;}
    public String zipHigh{get;set;}
    public String referralTypeFilter{get;set;} 
    public string rsbtFilter{get;set;}
    public string pHoldOutDescFilter {get;set;}
    public string newPHoldOutDesc {get;set;}
    
    
    
    
    public void toggleUseFilter() {
        useFilter = !useFilter;
        if (!useFilter) {
            // reselect without the filter on
            getRepHoldoutRecords();
        }
    } // toggleUseFilter
    
    private Integer recsPerPage=300;
    
    public PageReference applyFilter() {
        if (String.isBlank(zipLow)) {
            zipLow = '00000';
        }
        if (String.isBlank(zipHigh)) {
            zipHigh = '99999';
        }
        
        // verify 5 characters and all numbers
        String zipLowCheck = Utilities.removeExtraChars(zipLow,Utilities.ALL_NUMBERS);
        String zipHighCheck = Utilities.removeExtraChars(zipHigh,Utilities.ALL_NUMBERS);
        Boolean okay = true;
        if (zipLowCheck.length() != 5) {
            okay = false;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'Invalid valid for Starting Zip: '+zipLow));
        }
        if (zipHighCheck.length() != 5) {
            okay = false;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'Invalid valid for Ending Zip: '+zipHigh));
        }
        
        if (okay) {        
            
            getRepHoldoutRecords();
        }
        return null;
    } // applyFilter 
    
    
    
    
    public list<SelectOption> getOptions(){ 
        
        list <SelectOption> referralTypeFilter = new List<SelectOption>();
        
        Schema.DescribeFieldResult RTfieldResult = Referral_Contact__c.Referral_Type__c.getDescribe();
        List<Schema.PicklistEntry> ple = RTfieldResult.getPicklistValues();
        
        referralTypeFilter.add(new SelectOption(ALL, ALL)); 
        
        for( Schema.PicklistEntry RTPle : ple)
        {
            if(RTPle.isActive()){
                
                referralTypeFilter.add(new SelectOption(RTPle.getLabel(), RTPle.getValue()));
            }      //if(RTPle.isActive() 
        }
        return referralTypeFilter;  
    }// getOptions()      
    
    
    public list<SelectOption> getRSBTOptions(){ 
        
        list <SelectOption> rsbtFilter = new List<SelectOption>();
        
        Schema.DescribeFieldResult RTfieldResult = Referral_Account__c.Referral_Source_Business_Type__c.getDescribe();
        List<Schema.PicklistEntry> ple = RTfieldResult.getPicklistValues();
        
        rsbtFilter.add(new SelectOption(ALL, ALL)); 
        
        for( Schema.PicklistEntry RTPle : ple)
        {
            if(RTPle.isActive()){
                
                rsbtFilter.add(new SelectOption(RTPle.getLabel(), RTPle.getValue()));
            }      //if(RTPle.isActive()   
        } 
        return rsbtFilter;   
    }// getRSBTOptions()      
    
    public Account queryAcct {get;set;}
    public Contact queryCtct {get;set;} 
    public list <SelectOption> getObject(){   
        
        list <SelectOption> objectFilter = new List<SelectOption>(); 
        
        objectFilter.add(new SelectOption(REF_CTCT, REF_CTCT));
        objectFilter.add(new SelectOption(REF_ACCT, REF_ACCT));
        //  objectFilter.add(new SelectOption(CTCT, CTCT));
        objectFilter.add(new SelectOption (ACCT, ACCT)); 
        
        
        return objectFilter;  
    }//getObject
    
    //used to create the picklist used for filtering records  
    public static final string ALL = 'All'; 
    
    //add public static final string for --do not change -- and --select-- 
    
    public list <SelectOption> getPermHoldOut(){
        list <SelectOption> pHoldOutDescFilter = new list <SelectOption>();
        
        Schema.DescribeFieldResult pHOFieldResult = Account.Permanent_Hold_Out_Description__c.getDescribe();
        list<schema.PicklistEntry> ple = pHOFieldResult.getPicklistValues();
        
        pHoldOutDescFilter.add(new SelectOption(ALL, ALL));
        
        for (schema.PicklistEntry PHOPle : ple){
            if(PHOPle.isActive()){
                pHoldOutDescFilter.add(new SelectOption(PHOPle.getLabel(), PHOPle.getValue()));
                
            }//if   
        }//for
        
        return pHoldOutDescFilter; 
        
    } //selectOption getPermHoldOut
    
    //used to create the picklist for setting perm hold outs on accounts
    public list <SelectOption> getNewPermHoldOut(){
        list <SelectOption> newPHoldOutDesc = new list <SelectOption>();

        if(!isAssignAcct && !isAssignRefAcct){
            newPHoldOutDesc.add(new SelectOption('--Do Not Change--', '--Do Not Change--'));
        }//!isAssignAccount
        
        if (isAssignAcct || isAssignRefAcct){
            
            newPHoldOutDesc.add(new SelectOption('--Select--', '--Select--'));
            
        }//isassignAccount
        
        if(isAssignAcct){
            Schema.DescribeFieldResult pHOFieldResultAcct = Account.Permanent_Hold_Out_Description__c.getDescribe();
        	list<schema.PicklistEntry> pleAcct = pHOFieldResultAcct.getPicklistValues();
            for (schema.PicklistEntry PHOPle : pleAcct){
                if(PHOPle.isActive()){
                    newPHoldOutDesc.add(new SelectOption(PHOPle.getLabel(), PHOPle.getValue()));
                    
                }//if   
            }//for
        }
        if(isAssignRefAcct){
            Schema.DescribeFieldResult pHOFieldResultRefAcct = Referral_Account__c.Hold_Out_Reason__c.getDescribe();
        	list<schema.PicklistEntry> pleRefAcct = pHOFieldResultRefAcct.getPicklistValues();
            for (schema.PicklistEntry PHOPle : pleRefAcct){
                if(PHOPle.isActive()){
                    newPHoldOutDesc.add(new SelectOption(PHOPle.getLabel(), PHOPle.getValue()));
                    
                }//if   
            }//for
        }
        
        return newPHoldOutDesc;
        
    } //selectOption getPermHoldOut
    
    public date ExpirationDate {get; set;}  
    
    
    public static Integer RECS_PER_PAGE = Integer.valueOf(Label.Hold_Out_Max_Records);
    
    
    // Goto the next page of records. 
    public void next() {
        addToSelectMap();
        displaylist = null;     
        selectedController.next();
    } // next
    
    // Goto the previous page of records. 
    public void previous() {
        addToSelectMap();  
        displaylist = null;
        selectedController.previous();  
    } // previous    
    
    // Goto the next page of records.
    public void firstPage() {
        addToSelectMap();     
        displaylist = null;
        selectedController.first();
    } // next
    
    // Goto the previous page of records. 
    public void lastPage() {
        addToSelectMap();       
        displaylist = null;
        selectedController.last();  
    } // previous    
    
    // The total number of pages available.
    public Integer numOfPages {
        get {
            if (numOfPages == null) {
                
                numOfPages = 1;
                if (selectedController != null) {
                    decimal result = Decimal.valueOf(selectedController.getResultSize()) / Decimal.valueOf(selectedController.getPageSize());
                    //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'numOfPages resultsize='+ownershipRecs.getResultSize()+' pageSize='+ownershipRecs.getPageSize()+' result='+result));
                    numOfPages = (result.round(System.RoundingMode.CEILING)).intValue();
                }
            } // if (numOfPages
            return numOfPages;
        } // get
        private set;
    } // numOfPages
    
    
    
    
}//HoldoutController