/* Match the Territory Hierarchy with the Org Units

  Database.executeBatch(new TerritoryManager(),1);

TerritoryManager.checkSalesOrg('HRS');

  History
  -------
  11/29/2023 Dan Carmen        Created
  01/22/2024 Dan Carmen        Run as batch job
  02/15/2024 Dan Carmen        Set forecast manager when available
  
 */
global without sharing class TerritoryManager implements Database.Batchable<SObject>, Database.Stateful, Schedulable {
    
   public static final String CLASSNAME='TerritoryManager';
    
   global JobHelper jh = new JobHelper(CLASSNAME);
   global Integer numberSalesOrgs = 0;
   global String batchLog = '';
   global String errorMsg = '';

   /** Default constructor. */
   global TerritoryManager() {
   } // TerritoryManager
   
   global Database.QueryLocator start(Database.BatchableContext BC){
      // save the record - show that the job started
      jh.setStarted();
      return Database.getQueryLocator([SELECT Id
                                             ,Name
                                         FROM SalesOrg__c 
                                        WHERE UseInTerritoryManagement__c = true]);
   } // start

   global void execute(SchedulableContext ctx) {
      TerritoryManager ouj = new TerritoryManager();
      Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance(CLASSNAME);
      Integer batchSize = (abc != null && abc.Active__c && abc.BatchSize__c != null ? Integer.valueOf(abc.BatchSize__c) : 1);
      database.executeBatch(ouj, batchSize);
   } // execute

   /** Execute a batch.
    */
   global void execute(Database.BatchableContext BC, List<SObject> scope){
      SalesOrg__c[] salesOrgs = (SalesOrg__c[])scope;
      numberSalesOrgs += salesOrgs.size();
      for (SalesOrg__c salesOrg : salesOrgs) {
         try {
            checkSalesOrg(salesOrg.Name);
            batchLog += '\n\n'+logMsg;
         } catch (Exception ex) {
            errorMsg = ex.getMessage()+'; '+ex.getStackTraceString();
         }
      } // for (SalesOrg__c
   } // execute


   global void finish(Database.BatchableContext bc){
      String message = '\nTotal Sales Orgs Processed: '+numberSalesOrgs+' '; 
      message += batchLog;
      message += '\n\n'+errorMsg;

      jh.completeJob(bc, 'Update Territories', message);
      
   } // finish
    
   public static String logMsg = '';
   public static void checkSalesOrg(String salesOrg) {
      logMsg = 'Processing for '+salesOrg;
      // get all of the org units for the Sales Org
      Org_Unit__c[] orgUnits = [Select Id, Name, Assistant__c, EndDate__c, Manager__c, Org_Type__c, Org_Unit_Name__c
                                      ,Assistant__r.Id, Assistant__r.Name, Assistant__r.Job_Name__c, Assistant__r.IsActive
                                      ,Manager__r.Id, Manager__r.Name, Manager__r.Job_Name__c, Manager__r.IsActive, Manager__r.ForecastEnabled
                                      ,Parent__c, Parent__r.Id, Parent__r.Name, Parent__r.Org_Unit_Name__c
                                      ,RepUserRoleId__c, Sales_Org__c, StartDate__c, UserRoleId__c
                                  From Org_Unit__c
                                 Where Sales_Org__c=:salesOrg];
      Org_Unit__c[] divisions = new Org_Unit__c[]{};
      Org_Unit__c[] areas = new Org_Unit__c[]{};
      Org_Unit__c[] zones = new Org_Unit__c[]{};
      Org_Unit__c[] districts = new Org_Unit__c[]{};
      for (Org_Unit__c orgUnit : orgUnits) {
         if (orgUnit.Org_Type__c == OrgUnitMethods.TYPE_DIVISION) {
            divisions.add(orgUnit);
         } else if (orgUnit.Org_Type__c == OrgUnitMethods.TYPE_AREA) {
            areas.add(orgUnit);
         } else if (orgUnit.Org_Type__c == OrgUnitMethods.TYPE_ZONE) {
            zones.add(orgUnit);
         } else if (orgUnit.Org_Type__c == OrgUnitMethods.TYPE_DISTRICT) {
            districts.add(orgUnit);
         }
      } // for (Org_Unit__c orgUnit : orgUnits
      Map<Id,Org_Unit__c> distMap = new Map<Id,Org_Unit__c>(districts);
      // get the existing territories
      ZipTerritory__c[] zipTerrs = [Select Id, Name, District__c, Sales_Org__c, Territory_Nbr__c
                                          ,TerritoryRep__c, TerritoryRep__r.Id, TerritoryRep__r.Name
                                          ,TerritoryRep__r.IsActive, TerritoryRep__r.Job_Name__c, TerritoryRep__r.ForecastEnabled
                                          ,Zip_Segment__c, Zip_Segment__r.Id, Zip_Segment__r.Name
                                      From ZipTerritory__c
                                     Where District__c in :distMap.keySet()];
      logMsg += '\ndivisions='+divisions.size()+' areas='+areas.size()+' zones='+zones.size()+' districts='+districts.size()+' zipTerrs='+zipTerrs.size();
       
      Map<String,Territory2> terrMap = getTerritories(salesOrg);
      Map<String,Territory2Type> terrTypeMap = getTypeMap();
      Map<Id,Territory2> updateTerritories = new Map<Id,Territory2>();
      UserTerritory2Association[] newUserAssocs = new UserTerritory2Association[]{};
      Map<Id,UserTerritory2Association> delUserAssocs = new Map<Id,UserTerritory2Association>();
      // store the records where we store the manager
      ManagerWrapper[] mgrWraps = new ManagerWrapper[]{};
      logMsg += '\nterrMap='+terrMap.size()+' terrTypeMap='+terrTypeMap.size();
      System.debug('checkSalesOrg '+logMsg);
      //SalesOrg__c salesOrgCs = SalesOrg__c.getInstance(RecordTypeHelper.cleanRtName(salesOrg));
      processOrgLevel(divisions, terrMap, terrTypeMap, updateTerritories, newUserAssocs, delUserAssocs, mgrWraps);
      processOrgLevel(areas, terrMap, terrTypeMap, updateTerritories, newUserAssocs, delUserAssocs, mgrWraps);
      processOrgLevel(zones, terrMap, terrTypeMap, updateTerritories, newUserAssocs, delUserAssocs, mgrWraps);
      processOrgLevel(districts, terrMap, terrTypeMap, updateTerritories, newUserAssocs, delUserAssocs, mgrWraps);
       
      processZipTerritory(zipTerrs, terrMap, terrTypeMap
                         ,updateTerritories, newUserAssocs, delUserAssocs, mgrWraps);
      logMsg += '\nupdateTerritories='+updateTerritories.size()+' newUserAssocs='+newUserAssocs.size()+' delUserAssocs='+delUserAssocs.size();
      System.debug('checkSalesOrg updateTerritories='+updateTerritories.size()+' newUserAssocs='+newUserAssocs.size()+' delUserAssocs='+delUserAssocs.size());
      DmlHelper.performDML2(updateTerritories.values(), DmlHelper.DML_UPDATE, CLASSNAME, 'checkSalesOrg', 'Update Territories', false);
      if (!newUserAssocs.isEmpty()) {
         for (UserTerritory2Association uta : newUserAssocs) {
            if (uta.Territory2Id == null && uta.Territory2 != null && uta.Territory2.Id != null) {
               uta.Territory2Id = uta.Territory2.Id;
               uta.Territory2 = null;
            }
         } // for (UserTerritory2Association uta
         DmlHelper.performDML2(newUserAssocs, DmlHelper.DML_INSERT, CLASSNAME, 'checkSalesOrg', 'Insert User associations', false);
      } // if (!newUserAssocs.isEmpty
      if (!delUserAssocs.isEmpty()) {
         Database.delete(delUserAssocs.values(),false);
      }
      logMsg += '\nmgrWraps='+mgrWraps.size();
      if (!mgrWraps.isEmpty()) {
         Territory2[] updateTerrs = new Territory2[]{};
         for (ManagerWrapper wrap : mgrWraps) {
            wrap.terr.ForecastUserId = wrap.managerId;
            updateTerrs.add(wrap.terr);
         }
         DmlHelper.performDML2(updateTerrs, DmlHelper.DML_UPDATE, CLASSNAME, 'checkSalesOrg', 'Update forecast user', false);

      }
      ErrorLog.checkSave();
   } // checkSalesOrg
    
   public static void processOrgLevel(Org_Unit__c[] orgUnits, Map<String,Territory2> terrMap, Map<String,Territory2Type> terrTypeMap
                                      ,Map<Id,Territory2> updateTerritories
                                      ,UserTerritory2Association[] newUserAssocs, Map<Id,UserTerritory2Association> delUserAssocs
                                      ,ManagerWrapper[] mgrWraps) {
      // new territories are saved in each iteration so they can be referenced for the next level
      System.debug('processOrgLevel orgUnits='+orgUnits.size());
      Territory2[] newTerritories = new Territory2[]{};
      for (Org_Unit__c orgUnit : orgUnits) {
         Map<Id,User> userMap = new Map<Id,User>();
         if (orgUnit.Assistant__c != null) {
            userMap.put(orgUnit.Assistant__c,orgUnit.Assistant__r);
         }
         if (orgUnit.Manager__c != null) {
            userMap.put(orgUnit.Manager__c,orgUnit.Manager__r);
         }
         checkTerritory(orgUnit.Id, null, orgUnit.Org_Unit_Name__c, orgUnit.Name, orgUnit.Sales_Org__c
                                    ,orgUnit.Parent__c, orgUnit.StartDate__c, orgUnit.EndDate__c
                                    ,userMap, null, orgUnit.Manager__r
                                    ,terrMap, terrTypeMap.get(orgUnit.Org_Type__c)
                                    ,newTerritories, updateTerritories
                                    ,newUserAssocs, delUserAssocs, mgrWraps);
      } // for (Org_Unit__c orgUnit : orgUnits
      System.debug('processOrgLevel orgUnits='+orgUnits.size()+' newTerritories='+newTerritories.size());
      logMsg += '\norgUnits='+orgUnits.size()+' newTerritories='+newTerritories.size();
      if (!newTerritories.isEmpty()) {
         DmlHelper.performDML2(newTerritories, DmlHelper.DML_INSERT, CLASSNAME, 'processOrgLevel', 'Insert new Territories', false);
      }
   } // processOrgLevel
    
   public class ManagerWrapper {
      public Territory2 terr=null;
      public Id managerId=null;
   } // ManagerWrapper
    
   public static void processZipTerritory(ZipTerritory__c[] zipTerrs, Map<String,Territory2> terrMap, Map<String,Territory2Type> terrTypeMap
                                      ,Map<Id,Territory2> updateTerritories
                                      ,UserTerritory2Association[] newUserAssocs, Map<Id,UserTerritory2Association> delUserAssocs
                                      ,ManagerWrapper[] mgrWraps) {
      // new territories are saved in each iteration so they can be referenced for the next level
      Territory2[] newTerritories = new Territory2[]{};
      for (ZipTerritory__c zipTerr : zipTerrs) {
         Map<Id,User> userMap = new Map<Id,User>();
         if (zipTerr.TerritoryRep__c != null) {
            userMap.put(zipTerr.TerritoryRep__c,zipTerr.TerritoryRep__r);
         }
         checkTerritory(zipTerr.District__c, zipTerr.Id, zipTerr.Name, zipTerr.Territory_Nbr__c, zipTerr.Sales_Org__c
                                    ,zipTerr.District__c, null, null
                                    ,userMap, (zipTerr.Zip_Segment__c != null ? zipTerr.Zip_Segment__r.Name : null), null
                                    ,terrMap, terrTypeMap.get('Territory')
                                    ,newTerritories, updateTerritories
                                    ,newUserAssocs, delUserAssocs, mgrWraps);
      }
      System.debug('processOrgLevel zipTerrs='+zipTerrs.size()+' newTerritories='+newTerritories.size());
      logMsg += '\nzipTerrs='+zipTerrs.size()+' newTerritories='+newTerritories.size();
      if (!newTerritories.isEmpty()) {
         DmlHelper.performDML2(newTerritories, DmlHelper.DML_INSERT, CLASSNAME, 'processOrgLevel', 'Insert new Territories', false);
      }
   } // processZipTerritory
    
   public static void checkTerritory(String orgUnitId, String zipTerritoryId, String orgUnitName, String orgNbr, String salesOrg
                                    ,String parentId, Date startDate, Date endDate
                                    ,Map<Id,User> userMap, String segmentName, User manager
                                    ,Map<String,Territory2> terrMap, Territory2Type terrType
                                    ,Territory2[] newTerritories, Map<Id,Territory2> updateTerritories
                                    ,UserTerritory2Association[] newUserAssocs, Map<Id,UserTerritory2Association> delUserAssocs
                                    ,ManagerWrapper[] mgrWraps) {
      String terrId = (String.isNotBlank(zipTerritoryId) ? zipTerritoryId : orgUnitId);
      Territory2 terr = terrMap.get(terrId);
      System.debug('processOrgLevel orgUnit='+orgUnitName+' existing terr='+(terr != null));
      if (terr == null) {
         Id modelId = getActiveModelId();
         if (modelId != null && terrType != null) {
            terr = new Territory2(Territory2TypeId=terrType.Id, Territory2ModelId=modelId, SalesOrg__c=salesOrg, OrgUnitId__c=orgUnitId
                                  ,ZipTerritoryId__c=zipTerritoryId);
            terr.StartDate__c = (startDate != null ? startDate : Date.today());
            terr.Description = terrType.MasterLabel+' level Territory';
         }
      }
      System.debug('processOrgLevel orgUnit='+orgUnitName+' terr='+(terr != null)+' newTerr='+(terr != null && terr.Id == null));
      if (terr != null) {
         Boolean changed = (terr.Id != null);
         String orgName = getOrgName(orgUnitName, orgNbr, terrType.MasterLabel, segmentName);
         String devName = getDeveloperName(salesOrg+terrType.MasterLabel+(String.isNotBlank(zipTerritoryId) ? zipTerritoryId : '')+orgUnitId);
         System.debug('processOrgLevel orgName='+orgName+' devName='+devName);
         if (terr.Name != orgName) {
            terr.Name = orgName;
            changed = true;
         }
         if (terr.DeveloperName != devName) {
            terr.DeveloperName = devName;
            changed = true;
         }
         if (terr.EndDate__c != endDate) {
            terr.EndDate__c = endDate;
            changed = true;
         }
         if (manager != null && terr.ForecastUserId != manager.Id && manager.ForecastEnabled) {
            ManagerWrapper wrap = new ManagerWrapper();
            wrap.terr = terr;
            wrap.managerId = manager.Id;
            mgrWraps.add(wrap);
         //   terr.ForecastUserId = managerId;
         //   changed = true;
         }
         if (terr.SegmentName__c != segmentName) {
            terr.SegmentName__c = segmentName;
            changed = true;
         }
         if (parentId != null) {
            Territory2 parentTerr = terrMap.get(parentId);
            if (parentTerr != null && terr.ParentTerritory2Id != parentTerr.Id) {
               terr.ParentTerritory2Id = parentTerr.Id;
               changed = true;
            }
         }
         if (changed && terr.Id == null) {
            newTerritories.add(terr);
            // put in map so can be referenced by a child
            terrMap.put(terrId, terr);
         } else if (changed) {
            updateTerritories.put(terr.Id, terr);
         }
         checkTerrUsers(terr, userMap, newUserAssocs, delUserAssocs);
      } // if (terr != null

   } // checkTerritory
    
   public static void checkTerrUsers(Territory2 terr, Map<Id,User> userMap
                                    ,UserTerritory2Association[] newUserAssocs, Map<Id,UserTerritory2Association> delUserAssocs) {
      System.debug('checkTerrUsers userMap='+userMap.size());
      for (UserTerritory2Association uta : terr.UserTerritory2Associations) {
         User usr = userMap.remove(uta.UserId);
         System.debug('checkTerrUsers usr='+(usr != null));
         // if we don't have a user, that means the user isn't in the territory anymore
         if (usr == null) {
            delUserAssocs.put(uta.Id, uta); 
         }
      } // for (UserTerritory2Association uta
      // if there are any users left, we need to add them
      for (User usr : userMap.values()) {
         UserTerritory2Association uta = new UserTerritory2Association(UserId=usr.Id, RoleInTerritory2=usr.Job_Name__c);
         if (terr.Id == null) {
            uta.Territory2 = terr;
         } else {
            uta.Territory2Id = terr.Id;
         }
         newUserAssocs.add(uta);
      } // for (User usr : userMap.values
   } // checkTerrUsers
   
   public static final Integer NAME_SIZE = Territory2.Name.getDescribe().getLength();
   public static final Integer DEVNAME_SIZE = Territory2.DeveloperName.getDescribe().getLength();

   public static String getOrgName(String orgUnitName, String orgNbr, String orgType, String segmentName) {
      String orgName = orgUnitName;
      if (String.isNotBlank(orgNbr) && !orgName.contains(orgNbr)) {
         orgName += ' ('+orgType+' '+orgNbr+')';
      }
      if (String.isNotBlank(segmentName)) {
         orgName += '-'+segmentName;
      }
      return orgName.left(NAME_SIZE);
   } // getOrgName
    
   public static String getDeveloperName(String valueToCheck) {
      String retValue = (String.isNotBlank(valueToCheck) ? valueToCheck.replaceAll(' ', '') : '');
      retValue = (String.isNotBlank(retValue) ? retValue.replaceAll('__', '_') : '');
      retValue = (String.isNotBlank(retValue) ? retValue.replaceAll('[^A-Za-z0-9\\_]', '') : '');
      return retValue.left(DEVNAME_SIZE);
   } // getDeveloperName
    
   public static Map<String,Territory2Type> getTypeMap() {
      Territory2Type[] terrTypes = [Select Id, DeveloperName, MasterLabel, Priority
                                      From Territory2Type];
      Map<String,Territory2Type> terrTypeMap = new Map<String,Territory2Type>();
      for (Territory2Type terrType : terrTypes) {
         terrTypeMap.put(terrType.DeveloperName, terrType);
      }
      return terrTypeMap;
   } // getTypeMap
    
   // for testing purposes
   public static String TERR_STATE = 'Active';

   // get all territories from the active model
   public static Map<String,Territory2> getTerritories(String salesOrg) {
       Territory2[] terrs = [Select Id, Name, DeveloperName, Territory2ModelId
                                   ,AccountAccessLevel, ContactAccessLevel, OpportunityAccessLevel, CaseAccessLevel
                                   ,EndDate__c, OrgUnitId__c, SalesOrg__c, SegmentName__c, StartDate__c
                                   ,ZipTerritoryId__c
                                   ,ParentTerritory2Id, ForecastUserId
                                   ,Territory2TypeId, Territory2Type.DeveloperName, Territory2Type.MasterLabel
                                   ,(Select Id, UserId, Territory2Id, RoleInTerritory2, IsActive
                                       From UserTerritory2Associations)
                               From Territory2
                              Where SalesOrg__c=:salesOrg
                                and (OrgUnitId__c != null or ZipTerritoryId__c != null)
                                and Territory2Model.State = :TERR_STATE];
      Map<String,Territory2> terrMap = new Map<String,Territory2>();
      // add to the map for easy reference by Id
      for (Territory2 terr : terrs) {
         // if the ZipTerritoryId is populated file under that, otherwise the org unit id
         String recId = (terr.ZipTerritoryId__c != null ? terr.ZipTerritoryId__c : terr.OrgUnitId__c);
         terrMap.put(recId, terr);
      }
      return terrMap;
   } // getTerritories
    
   private static String v_activeModelId=null;
    
   public static Id getActiveModelId() {
      if (v_activeModelId == null) {
         Territory2Model[] models = [Select Id from Territory2Model where State = :TERR_STATE];
         v_activeModelId = (models.size() == 1 ? models.get(0).Id : null);
      }
      return v_activeModelId;
   } // getActiveModelId

} // TerritoryManager