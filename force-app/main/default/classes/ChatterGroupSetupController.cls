/* Controller to maintain the Chatter_Group_Setup__c object. 
   This is only intended for use on editing an existing record, not in creating a new one.
   Test methods are in ChatterMethodsTest.
   
  History
  -------
  04/10/2012 Dan Carmen   Created
  06/11/2012 Dan Carmen   Modified for owner fix.
  07/31/2012 Dan Carmen   Logic to select based only on profiles - ability to use all profiles for selection.
  
 */
public with sharing class ChatterGroupSetupController {

   /** The setup object retrieved. */
   public Chatter_Group_Setup__c cgs{get;set;}
   
   /** Constructor
    */
   public ChatterGroupSetupController(ApexPages.StandardController stdController) {
      cgs = (Chatter_Group_Setup__c)stdController.getRecord();
      Id cgsId = System.currentPageReference().getParameters().get('Id');
      // if this is an existing record, will select it here
      if (cgsId != null) {
         cgs = [Select Id, Name
                      ,ChatterGroupId__c
                      ,Child_Groups__c
                      ,Do_Not_Include_Child_Profiles__c
                      ,ExecuteSetup__c
                      ,IsActive__c
                      ,Manager_Profiles__c
                      ,Org_Units__c
                      ,Owner__c
                      ,Owner_Profile__c
                      ,Owner_Role__c
                      ,Selected_Profiles__c
                      ,Select_From_All_Profiles__c
                      ,Type__c
                      ,Use_Owner__c
                  From Chatter_Group_Setup__c
                 Where Id = :cgsId];
         // set the options from the existing record
         setProfileOptions(cgs);
      } // if (cgsId

   } //ChatterGroupSetupController
   
   /** The profiles selected to be part of this group. */
   public List<String> selectedProfiles{get;set;}
   /** The options selected for the manager role. */
   public List<String> managerProfiles{get;set;}
   
   /** The options for the owner role. */
   public List<SelectOption> ownerProfileOptions{get;set;}

   /** All of the available profile options. */
   public List<SelectOption> profileOptions{get;set;}
   
   /** Set up all of the profiles that are available.
    */
   public void setProfileOptions(Chatter_Group_Setup__c cgs) {
   	ChatterMethods cm = new ChatterMethods();
      Map<Id,Chatter_Group_Setup__c> allSetupsMap = cm.getGroupAndChildren(cgs);
      
      // check for cost centers of all groups
      Org_Unit__c[] costCenters = cm.getCostCenters(allSetupsMap.keySet());
   	Set<String> profileNamesSet = new Set<String>();
   	for (Org_Unit__c costCenter : costCenters) {
   	   if (costCenter.Available_Profiles__c != null) {
   	      String[] profs = costCenter.Available_Profiles__c.split(';');
   	      profileNamesSet.addAll(profs);
   	   }
   	} // for (Org_Unit__c
   	// if the flag is set, select all profiles
   	if (cgs.Select_From_All_Profiles__c) {
   	   profileNamesSet = getAllProfiles(profileNamesSet);
   	}
   	List<String> profileNamesList = new List<String>();
   	profileNamesList.addAll(profileNamesSet);
   	profileNamesList.sort();
   	
   	profileOptions = new List<SelectOption>();
   	ownerProfileOptions = new List<SelectOption>();
   	ownerProfileOptions.add(new SelectOption('','<None>'));
   	profileOptions.add(new SelectOption('','<None>'));
   	for (String profName : profileNamesList) {
   	   profileOptions.add(new SelectOption(profName,profName));
   	   ownerProfileOptions.add(new SelectOption(profName,profName));
   	}
   	selectedProfiles = (cgs.Selected_Profiles__c != null ? cgs.Selected_Profiles__c.split(';') : new List<String>());
      managerProfiles = (cgs.Manager_Profiles__c != null ? cgs.Manager_Profiles__c.split(';') : new List<String>());
   } // setProfileOptions

   /** Concatenated the profiles into one string. */
   public String concatenateProfs(List<String> profs, Integer maxLength) {
      String retVal = '';
      for (String prof : profs) {
      	if (prof != '<None>') {
      		if (retVal.length()+prof.length()+1 < maxLength) {
               if (retVal.length() > 0) {
                  retVal += ';';
               }
               retVal += prof;
      		} else {
      		   System.debug('The maximum field length was reached!');
      		} // if
      	} // if (prof != '<None>'
      } // for
      return retVal;
   } // concatenateProfs
   
   /** Retrieve all of the profiles that are not already retrieved.
    */
   public Set<String> getAllProfiles(Set<String> p_profileNamesSet) {
   	Set<String> profileNamesSet = new Set<String>();
   	profileNamesSet.addAll(p_profileNamesSet);
   	// there shouldn't be a volume issue, but just in case...
   	for (Profile[] profs : [Select Id, Name from Profile where Name not in :p_profileNamesSet]) {
   		for (Profile prof : profs) {
   		   profileNamesSet.add(prof.Name);
   		}
   	} // for (Profile[]
   	return profileNamesSet;
   } // getAllProfiles
   
   /**  Save the record. */
   public PageReference save() {
   	cgs.Selected_Profiles__c = concatenateProfs(selectedProfiles, 2000);
   	cgs.Manager_Profiles__c = concatenateProfs(managerProfiles, 500);
   	
   	try {
   	   upsert cgs;
   	} catch (Exception e) {
   	   throw e;
   	}
      PageReference pr = new PageReference('/'+cgs.id);   
      return pr;
   } // save
   
} // class ChatterGroupSetupController