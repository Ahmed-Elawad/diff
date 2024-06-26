/* 
 * Controller for looking up zip code information.
 *
 * History
 * -------
 * 04/04/2012 Dan Carmen        Created.
   06/29/2012 Dan Carmen        Change so DSM/DSA only displayed if User is a sales rep.
   07/11/2012 Dan Carmen        Added more logic to be able to manually load DSMs/DSAs
   07/25/2012 Dan Carmen        Added in check for sales org when selected DSM/DSA.
   11/16/2015 Cindy Freeman     changed getZipAssignmentMap method to remove DEFAULT segment always being returned
   01/18/2016 Cindy Freeman     changed getZipAssignmentMap method to ignore record type check
   01/03/2017 Dan Carmen        Change to return zip assignments if no object is passed in getZipAssignmentMap.
   05/01/2017 Cindy Freeman      Changed to be able to specify which Zip Segment rep you want
   12/12/2017 Jacob Hinds     Change to the override functionality, can now be done at referral partner and zip segment
   07/07/2020 Dan Carmen        Slight change to the getZipAssignment method for SOAR.
   09/01/2022 Dan Carmen       Lines 157 & 158. Added a check for recToCheck
   23/09/2022 Jaipal           Added doNotUseFallback as 5th Parameter to the getZipAssignmentMap method to bypass the Fallback Segment rule if doNotUseFallback = True
   06/19/2023 Dan Carmen         Add meetsSegmentCriteria variable

 */
public with sharing class ZipCodeLookupController {

   /** Used to query for the zip code. */
   public String zipCodeQuery{get;set;}
   /** The information on a Zip Code. */
   public Zip_Code_Information__c zipInfo{get;set;}
   
   /** Do we display the FAQ information? */
   public Boolean displayFAQ{get;set;}
   
   /** Do we have more detailed zip code information? */
   public Boolean hasZipInfo{
      get { return zipInfo != null; }
   } // hasZipInfo
   
   /** Do we show all of the columns on the form? */
   public Boolean showAllColumns{get;set;}
   
   /** Constructor for the controller. 
    */
   public ZipCodeLookupController() {
      displayFAQ = false;
      showAllColumns = false;
      
   } // ZipCodeLookupController
   
   /** Change the showAllColumns flag to the opposite value.
    */
   public PageReference toggleShowAllColumns() {
      showAllColumns = !showAllColumns;
      return null;
   } // toggleShowColumns
   
   /** The text to display for the FAQ link. */
   public String faqLinkTitle{
      get { return (displayFAQ ? 'Hide FAQ' : 'Display FAQ'); }
   }
   
   /** Toggle the FAQ flag. */
   public PageReference toggleFAQ() {
      displayFAQ = !displayFAQ;
      return null;
   } // toggleFAQ
   
   /** All of the available zip segments. */
   //private Zip_Segment__c[] segments;
   
   /** Are there results from the search?
    */
   public Boolean hasResults{
      get {return (zipResults != null && !zipResults.isEmpty()); }
   } // hasResults
   
   //SOAR Fix
   public static boolean doNotUseFallback = false;
   
   /** Verify that a valid value was entered for a zip code and query for the information.
    */
   public PageReference queryZipCodes() {
    zipResults = null;
    zipInfo = null;
    
    // verify valid size entered
    if (zipCodeQuery == null || 
        (zipCodeQuery != null && zipCodeQuery.length() != 5)) {
       ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'A valid 5 character zip code must be entered!'));
       return null;
    }
    String zipCode = String.escapeSingleQuotes(zipCodeQuery);
    // try to retrieve the zip info
      try {
         zipInfo = [Select Id, Name, City__c, State__c, State_Full_Name__c
                          ,AreaCode__c, County__c, TimeZone__c
                      From Zip_Code_Information__c
                     Where Name = :zipCode];
      } catch (Exception e) {
         zipInfo = null;
      }
      
      setZipResults(zipCode);
      
      return null;
   } // queryZipCodes
   
   public static ZipWrapper getZipAssignment(String zipCode, String salesOrg, SObject recToCheck) {
      return getZipAssignment(zipCode,salesOrg,recToCheck,null);
   } // getZipAssignment

       
   // Retrieve the ZipWrapper for the zip code matching the sales org and object passed in.
   public static ZipWrapper getZipAssignment(String zipCode, String salesOrg, SObject recToCheck, String zipSegmentName) {
      return getZipAssignment(zipCode,salesOrg,recToCheck,zipSegmentName,false);
   } // getZipAssignment
   
   //SOAR Fix
   public static ZipWrapper getZipAssignment(String zipCode, String salesOrg, SObject recToCheck, String zipSegmentName, Boolean doNotUseFalbak) {
      System.debug('getZipAssignment zipCode='+zipCode+' salesOrg='+salesOrg+' zipSegmentName='+zipSegmentName+' recToCheck: '+recToCheck);
      String segKey=salesOrg+'-'+zipSegmentName;
      ZipWrapper zipAssignment = null;
      Map<String,ZipWrapper[]> zipAssignmentMap = new Map<String,ZipWrapper[]>();  //CMF
      if(doNotUseFalbak){
		 doNotUseFallback = true; 
		}
		zipAssignmentMap = getZipAssignmentMap(new Set<String>{zipCode}, recToCheck, (recToCheck == null || !String.isBlank(zipSegmentName)),new Set<String>{segKey});  //CMF
      
	  
	  ZipWrapper[] zipAssignments = zipAssignmentMap.get(zipCode);
      if (zipAssignments != null) {
         for (ZipWrapper zw : zipAssignments) {
            System.debug('getZipAssignment zw.zipSeg.Sales_Org__c='+zw.zipSeg.Sales_Org__c+' zw.zipSeg.Name='+zw.zipSeg.Name);
             System.debug('getZipAssignment zw.za.Id='+zw.za.Id+' zw.za.Id='+zw.za.User__c);
            if (zw.zipSeg.Sales_Org__c == salesOrg 
                    && (String.isBlank(zipSegmentName) || zipSegmentName == zw.zipSeg.Name)) {
               
               zipAssignment = zw;
               System.debug('getZipAssignment found match zipAssignment: '+zipAssignment);
               break;
            }
         } // for (ZipWrapper zw
      } // if (zipAssignments != null
      
      return zipAssignment;
   } // getZipAssignment
   
   /** Get all of the zip assignments that meet the criteria for the passed in object. 
    *  default boolean parameter to false so don't have to change all the other places where this method is called.
    */
   public static Map<String,ZipWrapper[]> getZipAssignmentMap(Set<String> zipCodeSet, SObject recToCheck) {
	   return getZipAssignmentMap(zipCodeSet, recToCheck, false,new Set<String>());
   }
       
   /** Get all of the zip assignments that meet the criteria for the passed in object. 
    *  added boolean parameter-if true then include the 'default' Always on Referral Form segment, if false only return segment that fits criteria
    */
   public static Map<String,ZipWrapper[]> getZipAssignmentMap(Set<String> zipCodeSet, SObject recToCheck, Boolean includeAlways,Set<String> overrideSegmentSet) {
     Map<String,ZipWrapper[]> zipAssignmentMap = new Map<String,ZipWrapper[]>();
      //ZipWrapper[] zipAssignments = new ZipWrapper[]{};
      ZipCodeLookupController zclc = new ZipCodeLookupController();
      zclc.setZipResults(zipCodeSet);
      String objectName = (recToCheck != null ? ObjectHelper.getObjectName(recToCheck) : null);
      System.debug('getZipAssignmentMap objectName='+objectName+' recToCheck: '+recToCheck+' includeAlways='+includeAlways+' set:' +overrideSegmentSet);
      if (zclc.hasResults && (String.isNotBlank(objectName) || includeAlways)) {
        for (String zipCode : zclc.zipResultMap.keySet()) {
            ZipWrapper[] zipAssignments = new ZipWrapper[]{};
            for (ZipWrapper zw : zclc.zipResultMap.get(zipCode)) {
               String segmentKey = zw.zipSeg.Segment_Key__c; //zw.zipSeg.Sales_Org__c+'-'+zw.zipSeg.Name; 
               Boolean okayToUse = !zw.zipSeg.NeverOnReferralForm__c || (zw.zipSeg.NeverOnReferralForm__c && overrideSegmentSet.contains(segmentKey));
               zw.meetsSegmentCriteria = (okayToUse && recToCheck != null && ZipCheckOwner.objectMatchesZip(recToCheck, objectName, zw.za, zw.zipSeg, false));
               System.debug('getZipAssignmentMap okayToUse='+okayToUse+ ' neverOnForm: '+zw.zipSeg.NeverOnReferralForm__c+' key: '+segmentKey+' AlwaysOnForm='+zw.zipSeg.AlwaysOnReferralForm__c);
               System.debug('getZipAssignmentMap zw.meetsSegmentCriteria='+zw.meetsSegmentCriteria);
               // always include the "DEFAULT" zip assignments - not any more 11/2015
               //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'getZipAssignmentMap zipCode='+zipCode+' salesOrg='+zw.za.Sales_Org__c+' segmentName='+zw.zipSeg.Name));
               //Boolean checkRecordType = (objectName == ObjectHelper.OBJECT_ACCOUNT);
               if (okayToUse && ((zw.za.SkipJoinCriteria__c)  || (includeAlways && zw.zipSeg.AlwaysOnReferralForm__c) || recToCheck == null ||
                   (recToCheck != null && ZipCheckOwner.objectMatchesZip(recToCheck, objectName, zw.za, zw.zipSeg, false)))) {    //checkRecordType))) {
                  System.debug('getZipAssignmentMap added to return list');
                  //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'getZipAssignmentMap zipCode='+zipCode+' salesOrg='+zw.za.Sales_Org__c+' segmentName='+zw.zipSeg.Name+' added to zipAssignments'));
                  zipAssignments.add(zw);
               }
            } // for (ZipWrapper zw
            zipAssignmentMap.put(zipCode,zipAssignments);
        } // for (String zipCode
        
         //for (ZipWrapper zw : zclc.zipResults) {
            // always include the "DEFAULT" zip assignments
         // if ((zw.zipSeg.Name == ZipQueries.SEGMENT_DEFAULT) ||
         //       (ZipCheckOwner.objectMatchesZip(recToCheck, objectName, zw.za, true))) {
         //      zipAssignments.add(zw);
         //   }
         //} // for (ZipWrapper zw 
      } // if (zclc.hasResults
      //return zipAssignments;
      return zipAssignmentMap;
   } // getZipAssignments
   
   
   
   public void setZipResults(String zipCode) {
      Set<String> zipCodeSet = new Set<String>{zipCode};
      setZipResults(zipCodeSet);
   } // setZipResults

   /** retrieve the zip assignment information.
    */
   public void setZipResults(Set<String> zipCodeSet) {
      // get the zip codes
      //Set<String> queryKeys = new Set<String>{zipCode};

      // the district ids
      List<Id> districtIds = new List<Id>();

      Map<String,List<Zip_Assignment__c>> zipAssgnMap = ZipQueries.getZipAsgnMap(zipCodeSet, false); 
      
      // get the districts
      for (String zipCode : zipAssgnMap.keySet()) {
         List<Zip_Assignment__c> zipList = zipAssgnMap.get(zipCode);
         for (Zip_Assignment__c za : zipList) {
            if (za.District__c != null) {
               System.debug('setZipResults za.District__c: '+za.District__c); 
               districtIds.add(za.District__c);
            }
         } // for (Zip_Assignment__c za
         
      } // for (String zipCode
      
      // the key is the zip code, so will only be one list
      //List<Zip_Assignment__c> zipAssignList = zipAssgnMap.get(zipCode);
      // in case no zip codes are returned - prevent NPEs
      //if (zipAssignList == null) {
      //   zipAssignList = new List<Zip_Assignment__c>();
      //}


      // check for tiers
      //Set<String> officeKeys = new Set<String>();
      
      //for (Zip_Assignment__c za : zipAssignList) {
      //   if (za.District__c != null) {
      //      districtIds.add(za.District__c);
      //   }
      
      //} // for (Zip_Assignment__c za
      
      // get the districts
      Org_Unit__c[] districts = OrgUnitMethods.getOrgUnits(null, null, districtIds, null, null);
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'districtIds='+districtIds+' districts='+districts.size()));
      
      // store in a map for easier lookup
      Map<Id,Org_Unit__c> districtMap = new Map<Id,Org_Unit__c>();
      for (Org_Unit__c district : districts) {
         System.debug('setZipResults district: '+district); 
         districtMap.put(district.Id, district);
      }
      
      zipResultMap.clear();
      
      // clear it out
      zipResults = null;
      
      for (String zipCode : zipAssgnMap.keySet()) {
         zipResults = new ZipWrapper[]{};
         List<Zip_Assignment__c> zipList = zipAssgnMap.get(zipCode);
         for (Zip_Assignment__c za : zipList) {
            System.debug('setZipResults za: '+za); 
            Org_Unit__c district = (za.District__c != null ? districtMap.get(za.District__c) : null);
            System.debug('setZipResults for each za district: '+district); 
            ZipWrapper zw = new ZipWrapper(za,za.Zip_Segment__r,district);
            zipResults.add(zw);
             System.debug(doNotUseFallback);
			if(!doNotUseFallback){
              for (ZipAssignmentFallback__c fallback : za.ZipAssignmentFallbacks__r) {
               System.debug('setZipResults fallback: '+fallback); 
               ZipWrapper zw2 = new ZipWrapper(za,fallback.ZipSegment__r,district);
               zipResults.add(zw2);
              }
			}
         } // for (Zip_Assignment__c za
         zipResults.sort();
         zipResultMap.put(zipCode,zipResults);
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'setZipResults zipCode='+zipCode+' nbr results='+zipResults.size()));
      } // for (String zipCode
      
      if (zipResults == null) {
         zipResults = new ZipWrapper[]{};
      }
      //for (Zip_Assignment__c za : zipAssignList) {
      //   Org_Unit__c district = null;
         // find the district
      //   for (Org_Unit__c checkDistrict : districts) {
      //      if (za.District__c == checkDistrict.Id) {
      //         district = checkDistrict;
      //         break;
      //      }
      //   } // for (Org_Unit__c checkOu
         
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, za.Segment_Name__c+' district='+district));
      //   ZipWrapper zw = new ZipWrapper(za,district);
      //   zipResults.add(zw);
      //} // for (Zip_Assignment__c za
      
      //zipResults.sort();
      System.debug('setZipResults number found='+zipResults.size());
   } // setZipResults
      
   // The results of the search when one zip code is passed in
   public ZipWrapper[] zipResults{get;set;}
   
   // The results of the search when more than one zip code is passed in.
   public Map<String,ZipWrapper[]> zipResultMap = new Map<String,ZipWrapper[]>();
   

} // class ZipCodeLookupController