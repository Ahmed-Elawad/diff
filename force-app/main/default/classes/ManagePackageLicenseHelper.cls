/* 
 * Automation for license requests.
 *
 * History
 * -------
 * 06/28/2017 Saketh Mysa   Created
   11/28/2018 Jake Hinds	Rewriting most of the code to meet requirements
   06/08/2020 Jake Hinds      added in without sharing per pmd 
   08/25/2020 Carrie Marciano Adding Permission Set Groups and Oracle CPQ license functionality 
   04/20/2021 Carrie Marciano added check for salesApprover, if salesApprover include salesUser - both groups are necessary for Oracle CPQ
   01/28/2022 Carrie Marciano added CPQ license reactivation
   03/30/2022 Carrie Marciano added elseIF for CPQ Group management so it didn't fall thru licensing and permset code and changed from Reactivation checkbox to Request Type picklist
   *
 */

public without sharing class ManagePackageLicenseHelper{

    /*********
    intake method: Takes trigger Context variables as parameters and consolidates the list of Records to be processed, 
    It passes these records to various methods for processing
    ***********/
    public void intake(List<Manage_Package_License__c> trigger_new, Map<Id,Manage_Package_License__c> trigger_OldMap){
        Id[] approvedRecIds = new Id[]{};
        Manage_Package_License__c[] triggerNew = trigger_new;
        Map<Id,Manage_Package_License__c> triggerOldMap = trigger_OldMap;
        
        for (Manage_Package_License__c record : triggernew) {
            if (record.Request_Status__c == 'Approved' && record.Request_Status__c != triggerOldMap.get(record.Id).Request_Status__c) {
                approvedRecIds.add(record.Id);
            }
        }
        if (!approvedRecIds.isEmpty()) {
        	system.debug('ManagePackageLicenseHelper intake approvedRecId '+ approvedRecIds );	        
	        processApprovedRecords(approvedRecIds);
        }
        
    }//intake
    
    @future
    public static void processApprovedRecords(Id[] approvedRecIds){
    	system.debug('ManagePackageLicenseHelper processApprovedRecords approvedRecId '+ approvedRecIds );

            List<Manage_Package_License__c> approvedRecs = [SELECT Id, User_Name__c, User_Name__r.TimeZoneSidKey, Package_Name__c, Request_Type__c, Oracle_User__c, Effective_Date__c,CPQ_User_type__c FROM Manage_Package_License__c WHERE Id =:approvedRecIds];
        String[] packageNames = new String[]{};
        
        Map<String,Installed_Package__mdt> packageMDTByPackageName = new Map<String,Installed_Package__mdt>();
        Map<String,PackageLicense> managedPackageLicenceTypeByNamespace = new Map<String,PackageLicense>();
        
        Set<Id> allUserIds = new Set<Id>();
        Map<Id,Id[]> permissionSetListByUserId = new Map<Id,Id[]>();
        Map<Id,Id> permissionSetGroupbyPermSetId = new Map<Id,Id>();
        
        UserPackageLicense[] licensesToAssign = new UserPackageLicense[]{};
        PermissionSetAssignment[] permissionsToAssign = new PermissionSetAssignment[]{};
        cafsl__Oracle_User__c [] oracleUsersToUpsert = new cafsl__Oracle_User__c[]{};    
        PermissionSetGroup[] permissionSetGroupsToAssign = new PermissionSetGroup[]{};    
        User[] usersToUpdate = new User[]{};
        Map<Id,String> userUpdateMap = new Map<Id,String>();
        Id[] mplIds = new Id[]{};

        for (Manage_Package_License__c rec : approvedRecs) {
        	packageNames.add(rec.Package_Name__c);
        	allUserIds.add(rec.User_Name__c);
        } 
	    system.debug('ManagePackageLicenseHelper processApprovedRecords packageNames '+ packageNames );
	    
	    //query all installed metadata package records, put into a map by package name
	    for(Installed_Package__mdt pkg: [Select id, DeveloperName, Name_Prefix__c, User_Permission_Set__c,User_Permission_Set_Group__c,Pilot_User_Value__c,Oracle_CPQ__c,Salesforce_License__c
        											From Installed_Package__mdt where DeveloperName IN : packageNames]){
            packageMDTByPackageName.put(pkg.DeveloperName,pkg);
        }
	    system.debug('ManagePackageLicenseHelper processApprovedRecords packageMDTByPackageName '+ packageMDTByPackageName );
        
        //query all license types(what you see in the installed packages tab), put in map by package name prefix
        for(PackageLicense managedPackageLicenseType : [SELECT Id, NamespacePrefix, AllowedLicenses, UsedLicenses, 
                                    				ExpirationDate,Status FROM PackageLicense]){
        	managedPackageLicenceTypeByNamespace.put(managedPackageLicenseType.NamespacePrefix,managedPackageLicenseType);
        }
        system.debug('ManagePackageLicenseHelper processApprovedRecords managedPackageLicenceTypeByNamespace '+ managedPackageLicenceTypeByNamespace );
        
        //create map of user and all permission sets and permission set groups they have assigned
        for(PermissionSetAssignment psa : [SELECT Id,PermissionSetId,PermissionSetGroupId,AssigneeId FROM PermissionSetAssignment WHERE AssigneeId in : allUserIds]){
        	if(permissionSetListByUserId.containsKey(psa.AssigneeId)){
        		permissionSetListByUserId.get(psa.AssigneeId).add(psa.PermissionSetId);
	       	}
        	else{
        		permissionSetListByUserId.put(psa.AssigneeId,new Id[]{psa.PermissionSetId});               
        	}
            permissionSetGroupbyPermSetId.put(psa.PermissionSetId,psa.PermissionSetGroupId);
        }
        system.debug('ManagePackageLicenseHelper processApprovedRecords permissionSetListByUserId '+ permissionSetListByUserId);
        
        //loop through approved records and assign based on license requirements
        for (Manage_Package_License__c rec : approvedRecs) {
            //if(rec.Reactivation__c)
            if(rec.Request_Type__c == 'Reactivate'){
                cafsl__Oracle_User__c oracleUser = new cafsl__Oracle_User__c();
                oracleUser.Id=rec.Oracle_User__c;
                oracleUser.cafsl__Link_to_CPQ_User__c=True;
                oracleUsersToUpsert.add(oracleUser);
                system.debug('ManagePackageLicenseHelper processApprovedRecords update oracleUser: '+ oracleUser );
            }
            else if(rec.Request_Type__c == 'Manage Groups'){
                cafsl__Oracle_User__c oracleUser = new cafsl__Oracle_User__c();
                oracleUser.Id=rec.Oracle_User__c;
                oracleUser.cafsl__Link_to_CPQ_User__c=True;
                oracleUser.cafsl__Groups__c= rec.CPQ_User_type__c;
                oracleUsersToUpsert.add(oracleUser);
                system.debug('ManagePackageLicenseHelper processApprovedRecords update oracleUser: '+ oracleUser );
            }
            else{
                Installed_Package__mdt mdt = packageMDTByPackageName.get(rec.Package_Name__c);
        		PackageLicense licenseType = managedPackageLicenceTypeByNamespace.get(mdt.Name_Prefix__c);
        		if(mdt!=null && licenseType!= null){
                    //an allowed license value of -1 means unlimited.  if not unlimited, make sure we're not going to go over
                    Boolean enoughLicensesToAssign = (licenseType.AllowedLicenses == -1 || (licenseType.AllowedLicenses > (licenseType.UsedLicenses + approvedRecs.size())));
                    system.debug('ManagePackageLicenseHelper processApprovedRecords enoughLicensesToAssign: '+ enoughLicensesToAssign );
                    //some of these licenses aren't granted through Salesforce, only try to create records for those who are
                    if(mdt.Salesforce_License__c && enoughLicensesToAssign){
                        UserPackageLicense upl = new UserPackageLicense();
                        upl.PackageLicenseId = licenseType.Id;
                        upl.UserId = rec.User_Name__c;
                        licensesToAssign.add(upl);
                        system.debug('ManagePackageLicenseHelper processApprovedRecords licensesToAssign: '+ licensesToAssign );
                    }
                
                    //create permission set and permission set group
                    if(String.isNotBlank(mdt.User_Permission_Set__c)||String.isNotBlank(mdt.User_Permission_Set_Group__c)){
                        Boolean createPermissionSet = true;
                        //check to see if user already has permission set. couldn't avoid nested loop.
                        if(!permissionSetListByUserId.isEmpty() && permissionSetListByUserId.containsKey(rec.User_Name__c)){
                            for(Id psId : permissionSetListByUserId.get(rec.User_Name__c)){
                                system.debug('ManagePackageLicenseHelper psId: '+psId+' mdt.User_Permission_Set__c: '+mdt.User_Permission_Set__c);
                                system.debug('ManagePackageLicenseHelper permissionSetGroupbyPermSetId.get(psId): '+permissionSetGroupbyPermSetId.get(psId)+' mdt.User_Permission_Set_Group__c: '+mdt.User_Permission_Set_Group__c);
                                if(psId==mdt.User_Permission_Set__c || (permissionSetGroupbyPermSetId.get(psId)!=null & permissionSetGroupbyPermSetId.get(psId)==mdt.User_Permission_Set_Group__c)){
                                    createPermissionSet = false;
                                    system.debug('ManagePackageLicenseHelper processApprovedRecords createPermissionSet: '+ createPermissionSet );
                                }
                            }
                        }
                        if(createPermissionSet){
                            PermissionSetAssignment psa = new PermissionSetAssignment();
                            psa.PermissionSetId = mdt.User_Permission_Set__c;
                            psa.AssigneeId = rec.User_Name__c;
                            psa.PermissionSetGroupId = mdt.User_Permission_Set_Group__c;
                            permissionsToAssign.add(psa);
                            system.debug('ManagePackageLicenseHelper processApprovedRecords create psa: '+ psa );
                        }
                    }
                    //set pilot user and/or oracle cpq value on user record
                    if(String.isNotBlank(mdt.Pilot_User_Value__c)||mdt.Oracle_CPQ__c){
                        
                        User userToUpdate = new User();
                        userToUpdate.Id = rec.User_Name__c;
                        userToUpdate.PilotUser__c = mdt.Pilot_User_Value__c;
                        userToUpdate.Oracle_CPQ__c = mdt.Oracle_CPQ__c;
                        usersToUpdate.add(userToUpdate);
                        
                        userUpdateMap.put(rec.User_Name__c,mdt.Pilot_User_Value__c);                     			
                    }
                    //create Oracle CPQ User record
                    if(mdt.Oracle_CPQ__c){
                        cafsl__Embedded_CPQ_Settings__c embeddedCPQSetting = [Select Id from cafsl__Embedded_CPQ_Settings__c where cafsl__Primary__c=True limit 1];
                        system.debug('ManagePackageLicenseHelper embeddedCPQSetting: '+embeddedCPQSetting);
                        cafsl__Oracle_User__c oracleUser = new cafsl__Oracle_User__c();
                        oracleUser.cafsl__allow_quote_creation__c=True;
                        oracleUser.cafsl__Currency_Preference__c='USD';
                        oracleUser.cafsl__Date_Time_Format__c='0';
                        oracleUser.cafsl__Embedded_CPQ_Settings__c=embeddedCPQSetting.Id;
                       if(rec.CPQ_User_type__c =='salesApprover'){
                            oracleUser.cafsl__Groups__c='salesApprover; salesUser';
                        }else{
                            oracleUser.cafsl__Groups__c=rec.CPQ_User_type__c;
                        }
                        oracleUser.cafsl__Language_Preference__c='English';
                        oracleUser.cafsl__Link_to_CPQ_User__c=True;
                        oracleUser.cafsl__Number_Format__c='0';
                        //oracleUser.cafsl__Oracle_User_Profile__c='';
                        oracleUser.cafsl__Time_Zone__c=rec.User_Name__r.TimeZoneSidKey;
                        oracleUser.cafsl__Units__c='1';
                        oracleUser.cafsl__User__c=rec.User_Name__c;
                        oracleUser.cafsl__User_Type__c='SALES_AGENT';
                            
                        oracleUsersToUpsert.add(oracleUser);
                        system.debug('ManagePackageLicenseHelper processApprovedRecords create oracleUser: '+ oracleUser );                  			
                    }
                    //mplIds.add(rec.Id);
        		}
            } 
            mplIds.add(rec.Id);
            
        	system.debug('ManagePackageLicenseHelper processApprovedRecords licensesToAssign '+ licensesToAssign );
        	system.debug('ManagePackageLicenseHelper processApprovedRecords permissionsToAssign '+ permissionsToAssign );
        	system.debug('ManagePackageLicenseHelper processApprovedRecords usersToUpdate '+ usersToUpdate );
            system.debug('ManagePackageLicenseHelper processApprovedRecords oracleUsersToUpsert '+ oracleUsersToUpsert );
        }
        
        String exceptionText;
        try {
            if(!licensesToAssign.isEmpty()){
	        	insert licensesToAssign;
	        }
	        if(!permissionsToAssign.isEmpty()){
	        	insert permissionsToAssign;
	        }
	        if(!usersToUpdate.isEmpty()){
	        	update usersToUpdate;
	        }            
        }catch(DmlException e) {
            for (Integer i = 0; i < e.getNumDml(); i++) {
                // process exception here 
                String status = e.getDmlStatusCode(i);
                exceptionText = status + ' ' + e.getDmlMessage(i);
                System.debug('ManagePackageLicenseHelper processApprovedRecords exceptionText '+exceptionText); 
            }
        }
        Boolean updateSuccess = (exceptionText==null);
        //updateUsersFinishProcess(userUpdateMap,approvedRecId,updateSuccess,exceptionText);
        ManagePackageLicenseHelperQueueable mplhq = new ManagePackageLicenseHelperQueueable(approvedRecIds,updateSuccess,exceptionText,oracleUsersToUpsert);
        ID jobID = System.enqueueJob(mplhq);
    }
}