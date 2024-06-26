/* 
 * Wrapper for the Zip Code information. 
   This is a separate class because this has to be defined as global when it implements the Comparable interface.
 *
 * History
 * -------
 * 03/04/2014 Dan Carmen   Created
 * 03/10/2105 Cindy Freeman     Modified to use Territory override for Assistant and Manager 
                                fix (DSA) label 
 * 08/18/2015 Cindy Freeman     added line to populate usr if there was no zip territory or zip assignment record     
   07/07/2016 Dan Carmen        Modified logic to set Manager and Assistant
   05/15/2020 Dan Carmen        Additional ability to display DSA/DSM after rep name
   05/15/2020 Pratik Das        APR0132179: Change lead ownership from DSA to DSM(Method change setupRepName)
   06/19/2023 Dan Carmen        Add meetsSegmentCriteria

*/
global with sharing class ZipWrapper implements Comparable {

   public Zip_Segment__c zipSeg{get;set;}
   public Zip_Assignment__c za{get;set;}
   public Org_Unit__c district{get;set;}
   public String salesOfficeNbr{get; private set;}
   
   public String product{get;set;}
   public User usr{get;set;}
   public Contact ctct{get;set;}
   public String repName{get;set;}
   public String repEmail{get;set;}
   
   public NameWrapper manager{get;set;}
   public NameWrapper assistant{get;set;}
   
   public Boolean usingDSA = false;
   // This is for use with the ReferralController. Sometimes we return more zips than we need to on the form. This is to pass
   // on if the zip actually met the criteria or if it was being forced to return (through an override)
   public Boolean meetsSegmentCriteria=false;

   public ZipWrapper(Zip_Assignment__c p_za, Zip_Segment__c p_seg, Org_Unit__c p_district) {
      za = p_za;
      zipSeg = p_seg;
      district = p_district;
      product = (za != null ? new UserHelper().getProdTranslation(zipSeg.Sales_Org__c) : null);

      // try to get from district if we couldn't get from the rep
      if (String.isBlank(salesOfficeNbr) && district != null && district.Children__r != null && !district.Children__r.isEmpty()) {
         // set to first sales office number
         salesOfficeNbr = district.Children__r[0].Name;
      }
      setMgrAndAsst();
      setupRepName();
   } // ZipWrapper
   
   public ZipWrapper(Zip_Assignment__c p_za, Org_Unit__c p_district) {
      za = p_za;
      zipSeg = (za != null ? za.Zip_Segment__r : null);
      district = p_district;
      product = (za != null ? new UserHelper().getProdTranslation(za.Sales_Org__c) : null);

      // try to get from district if we couldn't get from the rep
      if (String.isBlank(salesOfficeNbr) && district != null && district.Children__r != null && !district.Children__r.isEmpty()) {
         // set to first sales office number
         salesOfficeNbr = district.Children__r[0].Name;
      }
      setMgrAndAsst();
      setupRepName();
   } // ZipWrapper
   
   /**
    If there's a territory contact associated with the territory, we will 
    */
   public void setupRepName() {
      hasTerritoryContact = false;
      String addtlTitle = (za != null ? za.OwnerType__c : '');
      if (za != null && za.ZipTerritory__c != null) {
        // make sure the territory rep isn't an unassigned user
        if (za.ZipTerritory__r.TerritoryRep__r != null 
                && za.ZipTerritory__r.TerritoryRep__r.IsActive 
                && !UserHelper.UNASSIGNED_SET.contains(za.ZipTerritory__r.TerritoryRep__r.HR_Person_Id__c)) {
            usr = za.ZipTerritory__r.TerritoryRep__r;
            usingDSA = za.Owned_By_DSA_DSM__c;
        }
         ctct = za.ZipTerritory__r.TerritoryContact__r;
         // if (usr == null && assistant != null && assistant.usr != null) {
         //    usr = assistant.usr;
         //    usingDSA = true;
         // }

         //APR0132179: Change lead ownership from DSA to DSM
         if (usr == null && manager != null && manager.usr != null) {
            usr = manager.usr;
            usingDSA = true;
         }
         if (usr != null) {
            repName = usr.Name;
            repEmail = usr.Email;
            if (!usr.Non_Paychex_Employee__c) {
               salesOfficeNbr = usr.SalesOfficeNumber__c;
            }
         } else if (ctct != null) {
            hasTerritoryContact = true;
            repName = ctct.Name;
            repEmail = ctct.Email;
         } else {
            repName = za.ZipTerritory__r.Rep_Name__c;
         }
      } else {
         repName = (za != null ? za.Rep_Name__c : null);
         usr = (za != null ? za.User__r:null);
      }
      if (String.isNotBlank(addtlTitle)) {
         repName += '('+addtlTitle+')';
      }
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'setupRepName product='+product+' segment='+za.Segment_Name__c+' repName='+repName));
   } // setupRepName
   
   public Boolean hasTerritoryContact{get;private set;}

   /** Set the manager and assistant fields. */
   public void setMgrAndAsst() {
      manager = new NameWrapper();
      assistant = new NameWrapper();
      // use Assistant and Manager overrides from territory if they are there
      if (za.ZipTerritory__r.OverrideAssistant__c != null) {
         checkName(assistant, za.ZipTerritory__r.OverrideAssistant__r, null, null, false, true);
      }
      if (za.ZipTerritory__r.OverrideManager__c != null) {
         checkName(manager, za.ZipTerritory__r.OverrideManager__r, null, null, false, true);
      }
      // check for the user links off of the district
      if (district != null && district.Org_Unit_User_Links__r != null
             && (!manager.fieldsAreSet() || !assistant.fieldsAreSet())) {
         for (Org_Unit_User_Link__c ouul : district.Org_Unit_User_Links__r) {
            // take the first active
            if (ouul.User__r.Job_Name__c == UserHelper.JOB_DSM) {
               checkName(manager, ouul.User__r, null, null, false, false);
            } else if (ouul.User__r.Job_Name__c == UserHelper.JOB_DSA) {
               checkName(assistant, ouul.User__r, null, null, false, false);
             }
          } // for (Org_Unit_User_Link__c ouul
      } // if (district != null
          
      if (district != null) {
         checkName(manager, district.Manager__r, district.MgrName__c, district.MgrEmail__c, district.OverrideMgr__c, false);
         checkName(assistant, district.Assistant__r, district.AssistantName__c, district.AssistantEmail__c, district.OverrideAssistant__c, false);
      }
      // check at the segment level
      if (zipSeg != null) {
         checkName(manager,zipSeg.Manager__r, zipSeg.MgrName__c, zipSeg.MgrEmail__c, zipSeg.OverrideMgr__c, false);
         checkName(assistant, zipSeg.Assistant__r, zipSeg.AssistantName__c, zipSeg.AssistantEmail__c, zipSeg.OverrideAssistant__c, false);
      } // if (zipSeg != null
      System.debug('**CMF ** setMgrAndAsst assistant='+assistant.fullName);
      System.debug('**CMF ** setMgrAndAsst manager='+manager.fullName);
       
   } // setMgrAndAsst
   
   private void checkName(NameWrapper checkWrapper, User checkUsr, String checkName, String checkEmail, Boolean overrideFlag, Boolean doNotAllowChangeIfSet) {
    // continue if the fields aren't already set or the override flag is set
      if (checkWrapper.allowChange && (!checkWrapper.fieldsAreSet() || overrideFlag)) {
         // make sure there a value
         if (checkUsr != null && checkUsr.IsActive) {
            checkWrapper.usr = checkUsr;
            checkWrapper.fullName = checkUsr.Name;
            checkWrapper.email = checkUsr.Email;
            checkWrapper.allowChange = (doNotAllowChangeIfSet ? false : checkWrapper.allowChange);
         } else if (String.isNotBlank(checkName) && String.isNotBlank(checkEmail)) {
            checkWrapper.fullName = checkName;
            checkWrapper.email = checkEmail;
            checkWrapper.allowChange = (doNotAllowChangeIfSet ? false : checkWrapper.allowChange);
         }
      } // if
   } // checkName
   
   global Integer compareTo(Object objectToCompareTo) {
      if (objectToCompareTo != null) {
         ZipWrapper compareWrapper = (ZipWrapper)objectToCompareTo;
         if (zipSeg != null && zipSeg.Sort_Order__c != null && compareWrapper.zipSeg != null && compareWrapper.zipSeg.Sort_Order__c != null) {
            return (zipSeg.Sort_Order__c - compareWrapper.zipSeg.Sort_Order__c).intValue();
         }
      }
      return -1;
   } // compareTo
   
   public Boolean hasAssistant{
      get {return (assistant != null && assistant.usr != null); }
   }
   
   public Boolean hasManager{
      get {return (manager != null && manager.usr != null); }
   }
   
   public class NameWrapper {
      public String fullName{get;set;}
      public String email{get;set;}
      public User usr{get;set;}
      public Boolean allowChange=true;
      
      public Boolean fieldsAreSet() {
         return (usr != null || (String.isNotBlank(fullName) && String.isNotBlank(email)));
      } // fieldsAreSet
      
   } // class NameWrapper
   
} // class ZipWrapper