/* Create some default data in new sandboxes - config only boxes
   
  History
  -------
  08/17/2018 Dan Carmen   Created
  01/17/2020 Dan Carmen   Missing Division level from Org Units
  07/06/2020  Jacob Hinds         Added without sharing per PMD
  
 */
global without sharing class SandboxPostCopyNoData implements SandboxPostCopy {
    
   global void runApexClass(SandboxContext context) {
      System.debug('Org ID: ' + context.organizationId());
      System.debug('Sandbox ID: ' + context.sandboxId());
      System.debug('Sandbox Name: ' + context.sandboxName());
      createOrganizationStructures();
      createOrgUnits();
      createReferralPartners();
      createZipSegments();
       
      checkRemovePermSet();
   } // runApexClass
    
   public static String DELETE_PERM_SETS=Label.SandboxPostCopy_DelPermSets;
   global void checkRemovePermSet() {
      System.debug('checkRemovePermSet DELETE_PERM_SETS='+DELETE_PERM_SETS);
      String[] permsToDelete = DELETE_PERM_SETS.split(',');
      PermissionSetAssignment[] assigns = [Select Id, AssigneeId, PermissionSetId from PermissionSetAssignment where PermissionSet.Name in :permsToDelete];

      System.debug('checkRemovePermSet assigns='+assigns.size()+' DELETE_PERM_SETS='+DELETE_PERM_SETS);
      if (!assigns.isEmpty()) {
         try {
           delete assigns;
              
         } catch (Exception e) {
            System.debug('checkRemovePermSet error deleting: '+e.getMessage());
         } // try
      } // if
      
   } // checkRemovePermSet
   
   // create organization structures
   global void createOrganizationStructures() {
      Organization_Structure__c os1 = new Organization_Structure__c(Sales_Office_Number__c='17',Sales_Office_name__c='ROCHESTER ROC',CostCenter__c='0017'
                                        ,Name='21',District_Name__c='ROCHESTER ROC',Zone__c='6',Zone_Name__c='Core Zone 6'
                                        ,Area_Number__c='1',Area__c='EAST',Sales_Org__c=UserHelper.SO_CORE);
      Organization_Structure__c os2 = new Organization_Structure__c(Sales_Office_Number__c='45',Sales_Office_name__c='BUFFALO',CostCenter__c='0045'
                                        ,Name='22',District_Name__c='BUFFALO',Zone__c='6',Zone_Name__c='Core Zone 6'
                                        ,Area_Number__c='1',Area__c='EAST', Sales_Org__c=UserHelper.SO_CORE);
      Organization_Structure__c os3 = new Organization_Structure__c(Sales_Office_Number__c='16',Sales_Office_name__c='SYRACUSE',CostCenter__c='0016'
                                        ,Name='20',District_Name__c='SYRACUSE',Zone__c='6',Zone_Name__c='Core Zone 6'
                                        ,Area_Number__c='1',Area__c='EAST', Sales_Org__c=UserHelper.SO_CORE);
      Organization_Structure__c os4 = new Organization_Structure__c(Sales_Office_Number__c='155',Sales_Office_name__c='CHICAGO NORTH',CostCenter__c='0155'
                                        ,Name='61',District_Name__c='CHICAGO NORTH',Zone__c='18',Zone_Name__c='Core Zone 18'
                                        ,Area_Number__c='3',Area__c='WEST', Sales_Org__c=UserHelper.SO_CORE);
      Organization_Structure__c os5 = new Organization_Structure__c(Sales_Office_Number__c='255',Sales_Office_name__c='CHICAGO SOUTH',CostCenter__c='0255'
                                        ,Name='74',District_Name__c='CHICAGO SOUTH',Zone__c='18',Zone_Name__c='Core Zone 18'
                                        ,Area_Number__c='3',Area__c='WEST', Sales_Org__c=UserHelper.SO_CORE);

      Organization_Structure__c os6 = new Organization_Structure__c(Sales_Office_Number__c='17',Sales_Office_name__c='ROCHESTER',CostCenter__c='0017'
                                        ,Name='70',District_Name__c='HRS - DISTRICT 70',Zone__c='1',Zone_Name__c='HRS - ZONE 1'
                                        ,Area_Number__c='2',Area__c='HR SERVICES', Sales_Org__c=UserHelper.SO_PEO_ASO);
      Organization_Structure__c os7 = new Organization_Structure__c(Sales_Office_Number__c='45',Sales_Office_name__c='BUFFALO',CostCenter__c='0017'
                                        ,Name='70',District_Name__c='HRS - DISTRICT 70',Zone__c='1',Zone_Name__c='HRS - ZONE 1'
                                        ,Area_Number__c='2',Area__c='HR SERVICES', Sales_Org__c=UserHelper.SO_PEO_ASO);
      Organization_Structure__c os8 = new Organization_Structure__c(Sales_Office_Number__c='175',Sales_Office_name__c='PHOENIX',CostCenter__c='0175'
                                        ,Name='19',District_Name__c='HRS - DISTRICT 19',Zone__c='6',Zone_Name__c='HRS - ZONE 6'
                                        ,Area_Number__c='2',Area__c='HR SERVICES', Sales_Org__c=UserHelper.SO_PEO_ASO);
      Organization_Structure__c[] structs = new Organization_Structure__c[]{os1,os2,os3,os4,os5,os6,os7,os8};
      insert structs;
   } // createOrganizationStructures
   
   // create org units
   global void createOrgUnits() {
      Org_Unit__c div1 = new Org_Unit__c(Name='PAY', Org_Unit_Name__c='PAY', Sales_Org__c=UserHelper.SO_CORE, Org_Type__c = OrgUnitMethods.TYPE_DIVISION);
      Org_Unit__c div2 = new Org_Unit__c(Name='PAS', Org_Unit_Name__c='PAS', Sales_Org__c=UserHelper.SO_PEO_ASO, Org_Type__c = OrgUnitMethods.TYPE_DIVISION);


      Org_Unit__c area1 = new Org_Unit__c(Name='1', Org_Unit_Name__c='EAST', Sales_Org__c=UserHelper.SO_CORE, Org_Type__c = OrgUnitMethods.TYPE_AREA);
      Org_Unit__c area2 = new Org_Unit__c(Name='3', Org_Unit_Name__c='WEST', Sales_Org__c=UserHelper.SO_CORE, Org_Type__c = OrgUnitMethods.TYPE_AREA);
      Org_Unit__c area3 = new Org_Unit__c(Name='2', Org_Unit_Name__c='HR SERVICES', Sales_Org__c=UserHelper.SO_PEO_ASO, Org_Type__c = OrgUnitMethods.TYPE_AREA);

      Org_Unit__c zone1 = new Org_Unit__c(Name='6', Org_Unit_Name__c='Core Zone 61', Sales_Org__c=UserHelper.SO_CORE, Org_Type__c = OrgUnitMethods.TYPE_ZONE);
      Org_Unit__c zone2 = new Org_Unit__c(Name='18', Org_Unit_Name__c='Core Zone 18', Sales_Org__c=UserHelper.SO_CORE, Org_Type__c = OrgUnitMethods.TYPE_ZONE);
      Org_Unit__c zone3 = new Org_Unit__c(Name='1', Org_Unit_Name__c='HRS - ZONE 1', Sales_Org__c=UserHelper.SO_PEO_ASO, Org_Type__c = OrgUnitMethods.TYPE_ZONE);
      Org_Unit__c zone4 = new Org_Unit__c(Name='6', Org_Unit_Name__c='HRS - ZONE 6', Sales_Org__c=UserHelper.SO_PEO_ASO, Org_Type__c = OrgUnitMethods.TYPE_ZONE);

      Org_Unit__c dist1 = new Org_Unit__c(Name='21', Org_Unit_Name__c='ROCHESTER ROC', Sales_Org__c=UserHelper.SO_CORE, Org_Type__c = OrgUnitMethods.TYPE_DISTRICT);
      Org_Unit__c dist2 = new Org_Unit__c(Name='22', Org_Unit_Name__c='BUFFALO', Sales_Org__c=UserHelper.SO_CORE, Org_Type__c = OrgUnitMethods.TYPE_DISTRICT);
      Org_Unit__c dist3 = new Org_Unit__c(Name='20', Org_Unit_Name__c='SYRACUSE', Sales_Org__c=UserHelper.SO_CORE, Org_Type__c = OrgUnitMethods.TYPE_DISTRICT);
      Org_Unit__c dist4 = new Org_Unit__c(Name='61', Org_Unit_Name__c='CHICAGO NORTH', Sales_Org__c=UserHelper.SO_CORE, Org_Type__c = OrgUnitMethods.TYPE_DISTRICT);
      Org_Unit__c dist5 = new Org_Unit__c(Name='74', Org_Unit_Name__c='CHICAGO SOUTH', Sales_Org__c=UserHelper.SO_CORE, Org_Type__c = OrgUnitMethods.TYPE_DISTRICT);
      Org_Unit__c dist6 = new Org_Unit__c(Name='70', Org_Unit_Name__c='HRS - DISTRICT 70', Sales_Org__c=UserHelper.SO_PEO_ASO, Org_Type__c = OrgUnitMethods.TYPE_DISTRICT);
      Org_Unit__c dist7 = new Org_Unit__c(Name='19', Org_Unit_Name__c='HRS - DISTRICT 19', Sales_Org__c=UserHelper.SO_PEO_ASO, Org_Type__c = OrgUnitMethods.TYPE_DISTRICT);

      Org_Unit__c office1 = new Org_Unit__c(Name='17', Org_Unit_Name__c='ROCHESTER ROC', Cost_Center__c='0017', Sales_Org__c=UserHelper.SO_CORE, Org_Type__c = OrgUnitMethods.TYPE_SALES_OFFICE);
      Org_Unit__c office2 = new Org_Unit__c(Name='45', Org_Unit_Name__c='BUFFALO', Cost_Center__c='0045', Sales_Org__c=UserHelper.SO_CORE, Org_Type__c = OrgUnitMethods.TYPE_SALES_OFFICE);
      Org_Unit__c office3 = new Org_Unit__c(Name='16', Org_Unit_Name__c='SYRACUSE', Cost_Center__c='0016', Sales_Org__c=UserHelper.SO_CORE, Org_Type__c = OrgUnitMethods.TYPE_SALES_OFFICE);
      Org_Unit__c office4 = new Org_Unit__c(Name='155', Org_Unit_Name__c='CHICAGO NORTH', Cost_Center__c='0155', Sales_Org__c=UserHelper.SO_CORE, Org_Type__c = OrgUnitMethods.TYPE_SALES_OFFICE);
      Org_Unit__c office5 = new Org_Unit__c(Name='255', Org_Unit_Name__c='CHICAGO SOUTH', Cost_Center__c='0255', Sales_Org__c=UserHelper.SO_CORE, Org_Type__c = OrgUnitMethods.TYPE_SALES_OFFICE);
      Org_Unit__c office6 = new Org_Unit__c(Name='17', Org_Unit_Name__c='ROCHESTER', Cost_Center__c='0017', Sales_Org__c=UserHelper.SO_PEO_ASO, Org_Type__c = OrgUnitMethods.TYPE_SALES_OFFICE);
      Org_Unit__c office7 = new Org_Unit__c(Name='45', Org_Unit_Name__c='BUFFALO', Cost_Center__c='0017', Sales_Org__c=UserHelper.SO_PEO_ASO, Org_Type__c = OrgUnitMethods.TYPE_SALES_OFFICE);
      Org_Unit__c office8 = new Org_Unit__c(Name='175', Org_Unit_Name__c='PHOENIX', Cost_Center__c='0175', Sales_Org__c=UserHelper.SO_PEO_ASO, Org_Type__c = OrgUnitMethods.TYPE_SALES_OFFICE);
      
      Org_Unit__c[] orgUnits = new Org_Unit__c[]{div1,div2,area1,area2,area3,zone1,zone2,zone3,zone4,dist1,dist2,dist3,dist4,dist5,dist6,dist7
                                                ,office1,office2,office3,office4,office5,office6,office7,office8};
      insert orgUnits;

      // set the parents on the records for the hierarchy
      area1.Parent__c=div1.Id;
      area2.Parent__c=div1.Id;
      area3.Parent__c=div2.Id;
      
      zone1.Parent__c=area1.Id;
      zone2.Parent__c=area2.Id;
      zone3.Parent__c=area3.Id;
      zone4.Parent__c=area3.Id;
      
      dist1.Parent__c=zone1.Id;
      dist2.Parent__c=zone1.Id;
      dist3.Parent__c=zone1.Id;
      dist4.Parent__c=zone2.Id;
      dist5.Parent__c=zone2.Id;
      dist6.Parent__c=zone3.Id;
      dist7.Parent__c=zone4.Id;
      
      office1.Parent__c=dist1.Id;
      office2.Parent__c=dist2.Id;
      office3.Parent__c=dist3.Id;
      office4.Parent__c=dist4.Id;
      office5.Parent__c=dist5.Id;
      office6.Parent__c=dist6.Id;
      office7.Parent__c=dist6.Id;
      office8.Parent__c=dist7.Id;
      update orgUnits;

   } // createOrgUnits
   
   /*
   public static String zipSegmentHeader='NAME,EMPS_MAX__c,EMPS_MIN__c,PAYCHEX_ID__c,SALES_ORG__c,SORT_ORDER__c,ASSET_MAX__c,ASSET_MIN__c,JOINCRITERIA__c,TEAMROLE__c,ACCTHOLDOUTFLDNAME__c,ACCTOWNERFLDNAME__c,ACCTRECORDTYPENAME__c,BOOLEAN1FIELD__c,BOOLEAN1TRUE__c,BOOLEAN2FIELD__c,BOOLEAN2TRUE__c,CTCTHOLDOUTFLDNAME__c,CTCTOWNERFLDNAME__c,RFRLACCTHOLDOUTFLDNAME__c,RFRLACCTOWNERFLDNAME__c,RFRLCTCTHOLDOUTFLDNAME__c,RFRLCTCTOWNERFLDNAME__c,ALWAYSONREFERRALFORM__c,ALWAYSASSIGNTEAMMEMBER__c,CLONEFROM__c,CLONETO__c,DELETE_ZIPASSIGNMENTS__c,RFRLACCTDEFAULT__c,RFRLRECORDTYPENAME__c,REMOVECRITERIAIFNOZIP__c,NEVERONREFERRALFORM__c,LEADRECORDTYPENAME__c';
   
   public static String zipSegmentData = '<101 Employees,100,0,,MSP,80,,,(Emps),myStaffingPro Sales Representative,,,,,FALSE,,FALSE,,,,,,,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,,FALSE,TRUE,\n'+
                                         '>100 Employees,99999999,101,,MSP,90,,,(Emps),myStaffingPro Sales Representative,,,,,FALSE,,FALSE,,,,,,,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,,FALSE,TRUE,\n'+
                                         'HISP,,,,PAY,12,,,(Boolean1),,Hold_Out__c,OwnerId,Core Account Record Type,Hispanic_Ownership__c,TRUE,,FALSE,Hold_Out__c,OwnerId,,,,,FALSE,FALSE,FALSE,TRUE,TRUE,FALSE,,TRUE,FALSE,Core Lead Record Type\n'+
                                         'Internal Partner,,,,MSP,100,,,,myStaffingPro Internal Partner,,,,,FALSE,,FALSE,,,,,,,FALSE,TRUE,FALSE,FALSE,FALSE,FALSE,,FALSE,TRUE,\n'+
                                         'TIER1,19,0,,PAY,10,999999999999,0,(Emps)(And)(Boolean1),,Hold_Out__c,OwnerId,Core Account Record Type,Hispanic_Ownership__c,FALSE,,FALSE,Hold_Out__c,OwnerId,Hold_Out__c,OwnerId,Hold_Out__c,OwnerId,FALSE,FALSE,FALSE,TRUE,TRUE,TRUE,Core Referral Source Record Type,FALSE,FALSE,Core Lead Record Type\n'+
                                         'TIER1,99999,0,,PC,65,1,1,,P&C Partner,,,,,FALSE,,FALSE,,,,,,,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,,FALSE,FALSE,\n'+
                                         'TIER2,99999999,20,PAY,PAY,11,999999999999,0,(Emps)(And)(Boolean1),,Hold_Out__c,OwnerId,Core Account Record Type,Hispanic_Ownership__c,FALSE,,FALSE,Hold_Out__c,OwnerId,Hold_Out__c,OwnerId,Hold_Out__c,OwnerId,FALSE,FALSE,TRUE,FALSE,FALSE,FALSE,Core Referral Source Record Type,FALSE,FALSE,Core Lead Record Type\n'+
                                         'DEFAULT,99999999,0,MMS,MMS,20,999999999999,0,,,Hold_Out__c,OwnerId,MMS Account Record Type,,FALSE,,FALSE,Hold_Out__c,OwnerId,Hold_Out__c,OwnerId,Hold_Out__c,OwnerId,FALSE,FALSE,FALSE,FALSE,FALSE,TRUE,MMS Referral Account Record Type,FALSE,FALSE,MMS Lead Record Type\n'+
                                         'DEFAULT,49,0,PAS,PAS,40,999999999999,0,(Emps)(And)(Boolean1),PEO-ASO Partner,Premier_PBS_Hold_Out__c,Premier_PBS_Account_Owner__c,,PEOLeasing__c,FALSE,,FALSE,,Premier_PBS_Contact_Owner__c,,Premier_PBS_Account_Owner__c,,Premier_PBS_Contact_Owner__c,FALSE,FALSE,TRUE,FALSE,FALSE,TRUE,,FALSE,FALSE,PEO-ASO Lead Record Type\n'+
                                         'INSIDE_AGENCY,14,0,72136,HNBF,50,1,1,(Emps),HNBF Partner,HNBF_Hold_Out__c,HNBF_Account_Owner__c,,,FALSE,,FALSE,,HNBF_Contact_Owner__c,,HNBF_Account_Owner__c,,HNBF_Contact_Owner__c,FALSE,FALSE,FALSE,FALSE,FALSE,TRUE,,FALSE,FALSE,HNBF Lead Record Type\n'+
                                         'TIER1,50,20,72137,HNBF,60,1,1,(Emps),HNBF Partner,HNBF_Hold_Out__c,HNBF_Account_Owner__c,,,FALSE,,FALSE,,HNBF_Contact_Owner__c,,,,,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,,FALSE,FALSE,HNBF Lead Record Type\n'+
                                         'TIER2,99999990,51,72138,HNBF,70,1,1,(Emps),HNBF Partner,HNBF_Hold_Out__c,HNBF_Account_Owner__c,,,FALSE,,FALSE,,HNBF_Contact_Owner__c,,,,,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,,FALSE,FALSE,HNBF Lead Record Type\n'+
                                         'DEFAULT,99999999,0,ADV-DEFAULT,ADV,110,,,,,,,,,,,,,,,,,,,,,,,,,,,\n'+
                                         'DEFAULT,99999999,0,MS-DEFAULT,MS,120,,,,Merchant Services Representative,,,,,FALSE,,FALSE,,,,,,,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,,FALSE,,\n'+
                                         'DEFAULT,99999999,0,,EW,100,,,,,,,,,FALSE,,FALSE,,,,,,,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,,FALSE,FALSE,\n'+
                                         'UPMARKET,99999999,50,,PAS,41,,,(Emps)(And)(Boolean1),PEO-ASO Partner,Premier_PBS_Hold_Out__c,Premier_PBS_Account_Owner__c,,PEOLeasing__c,FALSE,,FALSE,,Premier_PBS_Contact_Owner__c,,Premier_PBS_Account_Owner__c,,Premier_PBS_Contact_Owner__c,FALSE,FALSE,FALSE,TRUE,TRUE,TRUE,,FALSE,FALSE,PEO-ASO Lead Record Type\n'+
                                         'DEFAULT,99999999,0,ESR-DEFAULT,ESR,130,,,,ESR Sales Representative,,,,,FALSE,,FALSE,,,,,,,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,,FALSE,FALSE,\n'+
                                         'TIER2,200000,100000,,PC,66,1,1,,P&C Partner,,,,,FALSE,,FALSE,,,,,,,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,,FALSE,FALSE,\n'+
                                         'SMALL_MARKET,49,0,73545,HRS,31,449999,0,(Emps)(And)(Assets),Small Market 401(k)/FSA Partner,HRS_Hold_Out__c,HRS_Account_Owner__c,,,FALSE,,FALSE,,HRS_Contact_Owner__c,,HRS_Account_Owner__c,,HRS_Contact_Owner__c,TRUE,FALSE,FALSE,FALSE,FALSE,TRUE,,FALSE,FALSE,HRS Lead Record Type\n'+
                                         'LARGE_MARKET,99999999,50,73546,HRS,32,999999999999,450000,(Emps)(Or)(Assets),Large Market 401(k) Partner,HRS_Hold_Out__c,HRS_Account_Owner__c,,,FALSE,,FALSE,,HRS_Contact_Owner__c,,HRS_Account_Owner__c,,HRS_Contact_Owner__c,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,,FALSE,FALSE,HRS Lead Record Type\n'+
                                         'INTERNAL,99999999,0,HRS WHOLESINTERNAL,HRS WHOLESALER,26,999999999999,0,,Internal Wholesaler,,,,,FALSE,,FALSE,,,,Internal_Wholesaler_Account_Owner__c,,Internal_Wholesaler_Contact_Owner__c,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,,FALSE,FALSE,HRS Lead Record Type\n'+
                                         'EXTERNAL,99999999,0,HRS WHOLESEXTERNAL,HRS WHOLESALER,28,999999999999,0,,External Wholesaler,,,,,FALSE,,FALSE,,,,OwnerId,,OwnerId,FALSE,FALSE,FALSE,FALSE,FALSE,TRUE,HRS Referral Source Record Type,FALSE,FALSE,HRS Lead Record Type\n'+
                                         'PEO,,,,PAS,42,,,,PEO Centric Rep,Hold_Out__c,OwnerId,Prospect,,FALSE,,FALSE,Hold_Out__c,OwnerId,,,,,TRUE,TRUE,FALSE,FALSE,FALSE,FALSE,,FALSE,FALSE,PEO Lead Record Type\n'+
                                         'INSIDE_AGENCY_TIER2,19,15,72139,HNBF,55,1,1,(Emps),HNBF Partner,HNBF_Hold_Out__c,HNBF_Account_Owner__c,,,FALSE,,FALSE,,HNBF_Contact_Owner__c,,,,,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,,FALSE,FALSE,HNBF Lead Record Type\n'+
                                         'DEFAULT,99999999,0,PBA-DEFAULT,PBA,140,,,,PBA Sales Representative,,,,,FALSE,,FALSE,,,,,,,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,,FALSE,FALSE,\n';
   */
   global void createZipSegments() {
      populateFromStaticResource('Sandbox_ZipSegments','Zip_Segment__c');
      
   } // createZipSegments
   
   global void createReferralPartners() {
      populateFromStaticResource('Sandbox_ReferralPartners','Referral_Partner__c');
   } // createReferralPartners
   
   // create zip codes
   
   public static void populateFromStaticResource(String resourceName, String objectName) {
      System.debug('populateFromStaticResource resourceName='+resourceName+' objectName='+objectName);
      // pull in a csv file
      try {
         StaticResource sr = [SELECT Id, Body FROM StaticResource WHERE Name = :resourceName LIMIT 1];
         String body = sr.Body.toString();
         integer endOfHeader = body.indexOf(EmailServiceProcessorBatch.CRLF,0);
         String headerRow = body.substring(0,endOfHeader);//This should be the Column headers from the csv
         String csvData = body.subString(endOfHeader);
         System.debug('populateFromStaticResource endOfHeader='+endOfHeader+' headerRow='+headerRow);
         //System.debug('csvData='+csvData);
         
         EmailServiceProcessorBatch espb = new EmailServiceProcessorBatch();
         espb.fieldMap = new ObjectHelper().getFieldMap(objectName);
         System.debug('populateFromStaticResource espb.fieldMap='+espb.fieldMap.size());
         espb.queryHeaderMap = new Map<String,EmailFileQuery__c>(); 
         espb.parseHeaderFields(headerRow);
         System.debug('populateFromStaticResource headerFieldMap='+espb.headerFieldMap.size());
         
         CSVIterator csvDataInterator = new CSVIterator(csvData, EmailServiceProcessorBatch.CRLF);
         
         SObject[] recsToInsert = new SObject[]{};
         Schema.sObjectType objectDef = Schema.getGlobalDescribe().get(objectName).getDescribe().getSObjectType();
         System.debug('populateFromStaticResource objectDef='+objectDef);
         
         String recreateBody = headerRow;
         while (csvDataInterator.hasNext()) {
            recreateBody += csvDataInterator.next()+'EndOfLine';
         } // while
         createObject(espb, objectDef, recreateBody,recsToInsert);
         
         System.debug('recsToInsert='+recsToInsert.size());
         DmlHelper.performDML2(recsToInsert, DmlHelper.DML_INSERT, 'SandboxPostCopyNoData', 'populateFromStaticResource', 'Creating Records for '+objectName, true);
      } catch (Exception e) {
         ErrorLog.logError('SandboxPostCopyNoData', 'populateFromStaticResource', objectName+'-'+resourceName, null, e, null, true);
      }

   } // populateFromStaticResource
   
   public static void createObject(EmailServiceProcessorBatch espb, Schema.sObjectType objectDef, String lineData, SObject[] recsToInsert) {
      System.debug('createObject lineData='+(lineData != null ? lineData.length() : 0));
      // we're only doing a line at a time here
      Map<integer,Map<string,Object>> recMap = EmailServiceProcessor.parseCSVToMap(lineData,FALSE,espb.headerFieldMap,espb.fieldMap);//Parse the csv and create a map of a map with with string-value pairs for each row/record
      System.debug('createObject recMap='+recMap.size());
      for (map<string,Object> columnDataMap : recMap.values()){
         sObject thisObj = objectDef.newSobject();
         //system.debug('createObject columnDataMap.keySet()=' + columnDataMap.keySet());
         for (string fldName: columnDataMap.keySet()){//For each key (FieldName) add the corresponding value to the new object record
            try {
               // only set the columns that exist in the object. Query columns could be in the mix
               if (espb.fieldMap.containsKey(fldName)) {
                  thisObj.put(fldName,columnDataMap.get(fldName));
               }
            } catch(exception e) {
               //Throw out extra fields that aren't on the object
               System.debug('==== Invalid field specified in header ' + fldName);
            }       
         } // for (string fldName
         recsToInsert.add(thisObj);
      } // for (map<string,Object> columnDataMap
   } // createObject
   
} // class SandboxPostCopyNoData