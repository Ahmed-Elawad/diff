/* 
 *  A class to contain all methods need for Lead Company logic
 * History
 * -------
 * 05/02/2014 Cindy Freeman     created
 * 06/05/2014 Cindy Freeman     added logic to set Significant Lead when Company is created to Lead is deleted
 * 06/18/2014 Cindy Freeman     fixed createNoLeadGroupCompanies to skip leads that already have a Lead Company set
   11/06/2014 Dan Carmen        Change to convert extra leads outside this form
   12/09/2014 Dan Carmen        Do not convert extra leads of certain lead sources
   07/30/2015 Dan Carmen        Fix for postal code.
   02/27/2016 Dan Carmen        Fix for possible NPE in createMatchKey
   09/11/2018 Dan Carmen        Change code to run more in the future.
   11/08/2018 Dan Carmen        Clean up the handling for converted leads.
   03/15/2019 Dan Carmen        Don't use a future method on insert of a lead

 */
public without sharing class LeadCompanyMethods implements TriggerInterface2 {
   public static Boolean SKIP_LEAD_TRIGGER=false;

   public void triggerCheckAllFirst(SObject[] recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter) {
      if (SKIP_LEAD_TRIGGER) {
         System.debug('LeadCompanyMethods.triggerCheckAllFirst SKIP_LEAD_TRIGGER='+SKIP_LEAD_TRIGGER);
         return;
      }
      System.debug('LeadCompanyMethods.triggerCheckAllFirst recs='+(recs != null ? recs.size() : -1)+' isBefore='+isBefore+' isAfter='+isAfter);
      Lead[] leads = (Lead[])recs;
      Map<Id,Lead> oldLeadMap = (Map<Id,Lead>)oldMap;
      Id[] leadIds = new Id[]{};
      Id[] convertedLeadIds = new Id[]{};
      // only allow a future call on an update, not an insert
      Boolean allowFuture = (oldMap != null && !oldMap.isEmpty());
      // if it's an insert or a value changes
      for (Lead ld : leads) {
         Lead oldLd = (oldLeadMap != null ? oldLeadMap.get(ld.Id) : null);
         if (ld.IsConverted && oldLd != null && !oldLd.IsConverted) {
            convertedLeadIds.add(ld.Id);
         } else if (ld.Lead_Company__c == null
                || (oldLd == null)
                || (oldLd != null 
                   && (ld.Company != oldLd.Company
                      || ld.Street != oldLd.Street
                      || ld.City != oldLd.City
                      || ld.Email != oldLd.Email
                      || ld.Phone != oldLd.Phone
                      || ld.PostalCode != oldLd.PostalCode
                      || ld.State != oldLd.State)) 
            ) {
            leadIds.add(ld.Id);
         } // If (ld.Lead_Company__c
      }
      System.debug('LeadCompanyMethods.triggerCheckAllFirst leadIds='+leadIds.size());
      launchCompanyMethods(leadIds, convertedLeadIds, allowFuture);
      SKIP_LEAD_TRIGGER = true;
   } // checkAllAfterTrigger
   
   public void triggerCheckRec(SObject newRec, SObject oldRec, Boolean isBefore, Boolean isAfter) {}
   
   // see if there are any actions that need to take place at the end of the trigger.
   public void triggerCheckActions(Boolean isBefore, Boolean isAfter) {}

   // this is for testing purposes
   public static Boolean SKIP_FUTURE=false;
   
   public static void launchCompanyMethods(Id[] leadIds, Id[] convertedLeadIds, Boolean allowFuture) {
      if (!leadIds.isEmpty() || !convertedLeadIds.isEmpty()) {
         if (!allowFuture || SKIP_FUTURE || System.isFuture() || System.isBatch()) {
            handleLeadsNow(leadIds, convertedLeadIds);
         } else {
            handleLeadsFuture(leadIds, convertedLeadIds);
         }
         
      } // if (SKIP_FUTURE
   } // launchCompanyMethods
   
   @future
   public static void handleLeadsFuture(Id[] leadIds, Id[] convertedLeadIds) {
      handleLeadsNow(leadIds, convertedLeadIds);
   } // handleLeadsFuture

   public static void handleLeadsNow(Id[] leadIds, Id[] convertedLeadIds) {
      Id[] queryLeadIds = new Id[]{};
      queryLeadIds.addAll(leadIds);
      
      if (convertedLeadIds != null && !convertedLeadIds.isEmpty()) {
         //companyIdsToEvaluateSet.addAll(convertedLeadIds);
         // we need to query the leads to get the lead company id
         queryLeadIds.addAll(convertedLeadIds);
         //checkLeadCompanies();
      }
      //if (leadIds.isEmpty()) {
      //   return;
      //}
      Lead[] leads = getLeads(queryLeadIds);
      System.debug('handleLeadsNow queryLeadIds='+queryLeadIds.size()+' leads='+leads.size());
      
      Map<Id,Lead_Company__c> lcUpdateMap = new Map<Id,Lead_Company__c>();
      Map<Id,Lead_Company__c> lcDeleteMap = new Map<Id,Lead_Company__c>();
      Map<Id,Lead> leadUpdateMap = new Map<Id,Lead>();
      Map<String,LeadWrapper> leadWrapperMap = new Map<String,LeadWrapper>();
      Set<String> leadGroupIdSet = new Set<String>();
      
      for (lead ld : leads) {
         // if there are existing companies update/evaluate those. There should be only 1.
         if (ld.IsConverted) {
            if (ld.Lead_Company__c != null) {
               companyIdsToEvaluateSet.add(ld.Lead_Company__c);
            }
         } else if (!ld.Lead_Companies__r.isEmpty()) {
            checkExistingCompanies(ld, lcUpdateMap, lcDeleteMap, leadUpdateMap);
         } else {
            // if there aren't any, we need to find/create one
            String key = (String.IsNotBlank(ld.LeadGroupId__c) ? ld.LeadGroupId__c : createMatchKey(ld));
            LeadWrapper groupWrapper = getWrapper(key, ld, leadWrapperMap);
            if (String.isNotBlank(ld.LeadGroupId__c)) {
               leadGroupIdSet.add(ld.LeadGroupId__c);
            }
         }
      } // for (lead ld
      
      if (!companyIdsToEvaluateSet.isEmpty()) {
         checkLeadCompanies();
      }

      Lead[] leadsToUpdate = new Lead[]{};
      if (!leadUpdateMap.isEmpty() ) {
         leadsToUpdate.addAll(leadUpdateMap.values());
      }
      
      if (!leadGroupIdSet.isEmpty()) {
         LeadWrapper[] leadWraps = findExistingCompanies(leadGroupIdSet, leadWrapperMap);
         for (LeadWrapper wrapper : leadWraps) {
            leadsToUpdate.addAll(wrapper.setCompanyIdOnLeads());
         } // for
      } // if (!leadGroupIdSet.isEmpty

      System.debug('handleLeadsNow leadWrapperMap='+leadWrapperMap.size());
      if (!leadWrapperMap.isEmpty()) {
         checkForNewCompanies(leadWrapperMap);
         for (LeadWrapper wrapper : leadWrapperMap.values()) {
            leadsToUpdate.addAll(wrapper.setCompanyIdOnLeads());
         }
      } // if (!leadWrapperMap.isEmpty
      
      LeadCompanyMethods.SKIP_TRIGGER = true;
      DmlHelper.performDML2(lcDeleteMap.values(), DmlHelper.DML_DELETE, 'LeadCompanyMethods', 'handleLeadsNow', 'Delete extra Lead Companies',false);
      
      if (!lcUpdateMap.isEmpty()) {
         DmlHelper.performDML2(lcUpdateMap.values(), DmlHelper.DML_UPDATE, 'LeadCompanyMethods', 'handleLeadsNow', 'Updating Lead Companies',false);
      }
      
      System.debug('handleLeadsNow leadsToUpdate='+leadsToUpdate.size());
      if (!leadsToUpdate.isEmpty()) {
         DmlHelper.performDML2(leadsToUpdate, DmlHelper.DML_UPDATE, 'LeadCompanyMethods', 'handleLeadsNow', 'Updating Leads',false);
      }
      ErrorLog.checkSave();

   } // handleLeadsNow
   
   public static void checkExistingCompanies(Lead ld, Map<Id,Lead_Company__c> lcUpdateMap, Map<Id,Lead_Company__c> lcDeleteMap, Map<Id,Lead> leadUpdateMap) {
      // if there's more than one, the extra should be deleted
      Lead_Company__c mainCompany = ld.Lead_Company__r;
      
      for (Lead_Company__c lc : ld.Lead_Companies__r) {
         if (lc.CompanyJoinOkay__c || mainCompany == null) {
            mainCompany = lc;
         } else {
            lcDeleteMap.put(lc.Id, lc);
         }
      } // for (Lead_Company__c lc : ld.Lead_Companies__r
      
      System.debug('checkExistingCompanies ld='+ld.Name+' mainCompany found='+(mainCompany != null)+' lcDeleteMap='+lcDeleteMap.size());
            
      // if there's any difference, update the
      if (mainCompany != null && (ld.Company != mainCompany.Name
                  || ld.Street != mainCompany.Address__c
                  || ld.City != mainCompany.City__c
                  || ld.Email != mainCompany.Email__c
                  || ld.Phone != mainCompany.Phone__c
                  || ld.PostalCode != mainCompany.Postal_Code__c
                  || ld.State != mainCompany.State__c
                  || mainCompany.SignificantLead__c != ld.Id)
                  ) {
         System.debug('checkExistingCompanies updating lead company');
         mainCompany.Name = ld.Company.Left(80);
         mainCompany.Address__c = ld.Street;
         mainCompany.City__c = ld.City;
         mainCompany.Email__c = ld.Email;
         mainCompany.Phone__c = ld.Phone;
         String postalCode = (String.isNotBlank(ld.PostalCode) ? ld.PostalCode.left(POSTAL_LENGTH) : ld.PostalCode);
         mainCompany.Postal_Code__c = postalCode;
         mainCompany.State__c = ld.State;
         mainCompany.SignificantLead__c = ld.Id;
         lcUpdateMap.put(mainCompany.Id, mainCompany);
      } // if (ld.Name != mainCompany.Name

      Id lcId = (mainCompany != null ? mainCompany.Id : null);
      if (ld.Lead_Company__c != lcId) {
         ld.Lead_Company__c = lcId;
         leadUpdateMap.put(ld.Id, ld);
      }
       
   } // checkExistingCompanies
   
   // get leads and their existing companies
   public static Lead[] getLeads(Id[] leadIds) {
      Lead[] leads = [Select Id, Name, Company, Street, City, State, PostalCode
                            ,Email, Phone
                            ,IsConverted
                            ,LeadGroupId__c, Lead_Company__c
                            ,Lead_Company__r.Id
                            ,Lead_Company__r.Name
                            ,Lead_Company__r.Address__c
                            ,Lead_Company__r.City__c
                            ,Lead_Company__r.CompanyJoinOkay__c
                            ,Lead_Company__r.Email__c
                            ,Lead_Company__r.LeadGroupId__c
                            ,Lead_Company__r.Phone__c
                            ,Lead_Company__r.Postal_Code__c
                            ,Lead_Company__r.SignificantLead__c
                            ,Lead_Company__r.State__c
                            ,(Select Id, Name, AccountId__c, Address__c, City__c, CompanyJoinOkay__c
                                    ,Email__c, LeadGroupId__c, Phone__c, Postal_Code__c
                                    ,SignificantLead__c, State__c
                                From Lead_Companies__r
                               order by CompanyJoinOkay__c desc)
                        from Lead where id in :leadIds];
      return leads;
   } // getLeads
   
   // if a lead is deleted or converted, check the lead companies to see if there are any remaining records attached to it
   public static void checkLeadCompanies() {
      System.debug('checkLeadCompanies companyIdsToEvaluateSet='+companyIdsToEvaluateSet.size());
      if (companyIdsToEvaluateSet.isEmpty()) {
         return;
      }
      // select any leads associated with the lead companies
      Lead[] lds = [Select Id, Lead_Company__c from Lead where Lead_Company__c in :companyIdsToEvaluateSet and IsConverted=false];
      System.debug('checkLeadCompanies lds='+lds.size());
      Lead_Company__c[] updateCompanies = new Lead_Company__c[]{};
      Lead_Company__c[] deleteCompanies = new Lead_Company__c[]{};
      //Lead[] updateLeads = new Lead[]{};
      
      // remove all of the company ids if there's a surviving lead. Update the significant lead on the company
      for (Lead ld : lds) {
         if (companyIdsToEvaluateSet.contains(ld.Lead_Company__c)) {
            companyIdsToEvaluateSet.remove(ld.Lead_Company__c);
            Id leadCompId = ld.Lead_Company__c;
            // change the significant lead
            Lead_Company__c tempLc = new Lead_Company__c(Id=LeadCompId, SignificantLead__c=ld.Id);
            updateCompanies.add(tempLc);
         }
      } // for (Lead ld : lds
      
      // for any remaining lead companies, delete them because there are no surviving leads
      for (Id LeadCompId : companyIdsToEvaluateSet) {
         Lead_Company__c tempLc = new Lead_Company__c(Id=LeadCompId);
         deleteCompanies.add(tempLc);
      }
      DmlHelper.performDML2(updateCompanies, DmlHelper.DML_UPDATE, 'LeadCompanyMethods', 'checkLeadCompanies', 'Updating Lead Companies',false);
      DmlHelper.performDML2(deleteCompanies, DmlHelper.DML_DELETE, 'LeadCompanyMethods', 'checkLeadCompanies', 'Deleting Lead Companies',false);
      ErrorLog.checkSave();
      companyIdsToEvaluateSet.clear();
   } // checkLeadCompanies

/*
   // Evaluate leads coming in from an after trigger.
   public static void evaluateLeads(List<Id> idList) {
      List<Lead> leadList = [Select Id, Name, Company, Street, City, State, PostalCode
                                   ,Email, Phone
                                   ,LeadGroupId__c, Lead_Company__c
                        from Lead where id in :idList];
      evaluateLeads(leadList);
      update leadList;
   } // evaluateLeads


   // Evaluate all of the leads coming in through the trigger.
   //    Make sure they're attached to a lead company
   public static void evaluateLeads(Lead[] leadList) {
      Map<String,LeadWrapper> leadWrapperMap = new Map<String,LeadWrapper>();
      // do we have at least one group id - so we don't query if we don't need to
      Boolean hasGroupIds = false;
      
      for (Lead ld : leadList) {
        String key = (String.IsNotBlank(ld.LeadGroupId__c) ? ld.LeadGroupId__c : createMatchKey(ld));
        hasGroupIds = (hasGroupIds || String.IsNotBlank(ld.LeadGroupId__c));
        LeadWrapper groupWrapper = getWrapper(key, ld, leadWrapperMap);
      } // for (Lead ld
      
      if (hasGroupIds) {
         findExistingCompanies(leadWrapperMap);
      }
      
      checkForNewCompanies(leadWrapperMap);
      
      for (LeadWrapper wrapper : leadWrapperMap.values()) {
         wrapper.setCompanyIdOnLeads();
      }
   } // evaluateLeads
   */
   
   // Find any existing lead companies based on the LeadGroupId.
   public static LeadWrapper[] findExistingCompanies(Set<String> leadGroupIdSet, Map<String,LeadWrapper> leadWrapperMap) {
      LeadWrapper[] foundComps = new LeadWrapper[]{};
      System.debug('findExistingCompanies leadGroupIdSet='+leadGroupIdSet.size()+' leadWrapperMap='+leadWrapperMap.size());
      if (!leadGroupIdSet.isEmpty()) {
         List<Lead_Company__c> companyList = [Select Id, Name, Address__c, City__c, State__c, Postal_code__c, LeadGroupId__c, SignificantLead__c 
                                      from Lead_Company__c
                                     where LeadGroupId__c in :leadGroupIdSet and isDeleted = false];
         System.debug('findExistingCompanies companyList='+companyList.size());
         for (Lead_Company__c company : companyList) {
            companyIdsToEvaluateSet.add(company.Id);
            // take ones we find out of the set so they won't be processed further
            LeadWrapper wrapper = leadWrapperMap.remove(company.LeadGroupId__c);
            System.debug('findExistingCompanies wrapper='+(wrapper != null));
            if (wrapper != null) {
               wrapper.leadCompany = company;
               foundComps.add(wrapper);
            }
         } // for (Lead_Company__c company
      } // if (!matchKeyMap.isEmpty
      return foundComps;
   } // findExistingCompanies

   public static final Integer POSTAL_LENGTH = Lead_Company__c.Postal_code__c.getDescribe().getLength();

   // Check if we need to create new lead companies.

   public static void checkForNewCompanies(Map<String,LeadWrapper> leadWrapperMap) {
      System.debug('checkForNewCompanies leadWrapperMap='+leadWrapperMap.size());
      Lead_Company__c[] newCompanies = new Lead_Company__c[]{};
      // this list is just for the new records - to match up to error if needed.
      LeadWrapper[] wrapperList = new LeadWrapper[]{};
      
      for (LeadWrapper wrapper : leadWrapperMap.values()) {
         if (wrapper.leadCompany == null) {
            Lead ld = null;
            try {
               ld = wrapper.leadList[0];
               wrapper.leadCompany = new Lead_Company__c();
               wrapper.leadCompany.Name = ld.Company.Left(80);
               wrapper.leadCompany.Address__c = ld.Street;
               wrapper.leadCompany.City__c = ld.City;
               wrapper.leadCompany.State__c = ld.State;
               String postalCode = (String.isNotBlank(ld.PostalCode) ? ld.PostalCode.left(POSTAL_LENGTH) : ld.PostalCode);
               wrapper.leadCompany.Postal_code__c = postalCode;
               wrapper.leadCompany.Email__c = ld.Email;
               wrapper.leadCompany.Phone__c = ld.Phone;
               wrapper.leadCompany.LeadGroupId__c = (String.isBlank(ld.LeadGroupId__c) ? String.valueOf(ld.Id) : ld.LeadGroupId__c);
               // default the significant lead here
               wrapper.leadCompany.SignificantLead__c = ld.Id;
               newCompanies.add(wrapper.leadCompany);
               wrapperList.add(wrapper);
            } catch (Exception ex) {
               ErrorLog.logError('LeadCompanyMethods', 'checkForNewCompanies', 'Setting values on a lead company', (ld != null ? ld.Id : null), ex, null, false);

               System.debug('checkForNewCompanies exception: '+ex.getStackTraceString());
            }
         }
      } // for (LeadWrapper wrapper
      ErrorLog.checkSave();
   
      System.debug('checkForNewCompanies newCompanies='+newCompanies.size());
      if (!newCompanies.isEmpty()) {
         Database.SaveResult[] results = Database.insert(newCompanies, false);
         for (Integer cnt=0; cnt<results.size(); cnt++) {
            if (results[cnt].isSuccess()) {
                //companyIdsToEvaluateSet.add(results[cnt].getId());
            } else {
               String errmsg = '';
               for (Database.Error err : results[cnt].getErrors()) {
                  errmsg += err.getMessage();
               }
               System.debug('checkForNewCompanies errMsg='+errMsg);
               // catch the dupeblocker error 
               if (errmsg.indexOf('COE-Potential duplicate') > -1) {
                  String compId = errmsg.substringBetween('href="/', '"');    // get Id of first existing company, should be closest match
                  Lead_Company__c companyMatch = [Select Id, Name, Address__c, City__c, State__c, Postal_code__c, email__c, Phone__c, LeadGroupId__c
                                                  from Lead_Company__c where Id = :compId];
                  //companyIdsToEvaluateSet.add(companyMatch.Id);
                  wrapperList[cnt].leadCompany = companyMatch;
               // commenting out for now - not sure we need to worry about exceptions
               //} else if (newCompanies.size() == 1) {
                // only throw the exception if one record? 
               //   Throw new CompanyException('insert exception on new Company-'+wrapperList[cnt].leadCompany.Name+' err='+errMsg);
               }
            } // if (!results[cnt].isSuccess
         } // for (Integer cnt=0; cnt<results.size()
      } // if (!newCompanies.isEmpty
   } // checkForNewCompanies
   
   public static LeadWrapper getWrapper(String key, Lead ld, Map<String,LeadWrapper> wrapperMap) {
      LeadWrapper wrapper = wrapperMap.get(key);
      if (wrapper == null) {
         wrapper = new LeadWrapper(key);
         wrapperMap.put(key,wrapper);
      }
      wrapper.leadList.add(ld);
      return wrapper;
   } // getWrapper
   
   public class LeadWrapper {
    public LeadWrapper(String p_wrapperKey) {
       wrapperKey = p_wrapperKey;
    }
    public String wrapperKey = null;
      public Lead_Company__c leadCompany = null;
      public Lead[] leadList = new lead[]{};
      public Boolean hasCompany() {
         return (leadCompany != null && leadCompany.Id != null);
      }
      
      public Lead[] setCompanyIdOnLeads() {
        Lead[] updatedLeads = new Lead[]{};
        Boolean hasLeadCompany = (leadCompany != null && leadCompany.Id != null);
        System.debug('setCompanyIdOnLeads hasLeadCompany='+hasLeadCompany+' leadList='+leadList.size());
         if (hasLeadCompany && !leadList.isEmpty()) {
            // this will be null if the company was just created and we didn't already have an id
            // the workflow populates the id - so if the workflow changes this also has to change
            // the workflow uses the 15 character id so we'll truncate it to match
            if (String.IsBlank(leadCompany.LeadGroupId__c)) {
               leadCompany.LeadGroupId__c = ((String)leadCompany.Id);
            }
            
            for (Lead ld : leadList) {
               if (ld.Lead_Company__c != leadCompany.Id
                    || ld.LeadGroupId__c != leadCompany.LeadGroupId__c) {
                  ld.Lead_Company__c = leadCompany.Id;
                  ld.LeadGroupId__c = leadCompany.LeadGroupId__c;
                  updatedLeads.add(ld);
               }
            } // for (Lead ld
         } // if (leadCompany != null &&
         System.debug('setCompanyIdOnLeads updatedLeads='+updatedLeads.size());
         return updatedLeads;
      } // setCompanyIdOnLeads
      
   } // LeadWrapper
   
    // exeption used to throw on Dupe Blocker error message
    public class CompanyException extends Exception{}
    
   /** Create a simple match key for a lead.
    */
   public static String createMatchKey(Lead l) {
      String shortSt = (l.Street==null?'':l.Street.substringBefore(' '));
      String keyName = (String.isNotBlank(l.Company) ? l.Company.left(80).trim() : String.isNotBlank(l.LastName) ? l.LastName.left(80).trim() : 'NoKeyFound');
      String matchkey = 'Key-'+keyName + shortSt + (String.isBlank(l.PostalCode) ?'':l.PostalCode.left(5));
      return matchKey;
   } // createMatchKey

/*
   public static Boolean checkForSignificanceRecalc(Lead_Company__c newL, Lead_Company__c oldL) {
    Boolean changed = false;
      if (newL.EvaluateSignificant__c) {
         companyIdsToEvaluateSet.add(newL.Id);
         changed = true;
      }
      return changed;
   } // checkForSignificanceRecalc

    // Check if any of the fields have changed that could cause the significance to change. 
    public static Boolean checkForSignificanceRecalc(Lead newL, Lead oldL) {
        Boolean changed = false;
       if (newL != null && oldL != null && newL.Lead_Company__c != null) {

          if (statusTriggersRecalc(newL.Status,oldL.Status)
              || holdOutTriggersRecalc(newL.Hold_Out_Reason__c,oldL.Hold_Out_Reason__c)
              || (newL.DoNotCall != oldL.DoNotCall)
              || (newL.IsConverted != oldL.IsConverted)
             ) {
             companyIdsToEvaluateSet.add(newL.Lead_Company__c);
             changed = true;
          }
       } // if (newL != null && oldL != null
       return changed;
    } // checkForSignificanceRecalc
    */
    // Check if at least one of the hold out values is one we care about.
    public static Boolean holdOutTriggersRecalc(String holdOutReason1, String holdOutReason2) {
        if (holdOutReason1 != holdOutReason2) {
            System.debug('holdOutTriggersRecalc holdOutReason1='+holdOutReason1+' holdOutReason2='+holdOutReason2);
            setQueryParameters();
          if ((String.isNotBlank(holdOutReason1) && holdOutReasonSet.contains(holdOutReason1))
               || (String.isNotBlank(holdOutReason2) && holdOutReasonSet.contains(holdOutReason2))
              ) {
            System.debug('holdOutTriggersRecalc returning true');
             return true;
          } // if (notBlank and in reasonSet)
        } // if (reason1 != reason2)
      System.debug('holdOutTriggersRecalc returning false');
       return false;
    } // holdOutTriggersRecalc
    
    // Check if at least one of the status value is one we care about for a recalc.
    public static Boolean statusTriggersRecalc(String status1, String status2) {
      if (status1 != status2) {
         setQueryParameters();
         if ((String.isNotBlank(status1) && statusSet.contains(status1))
              || (String.isNotBlank(status2) && statusSet.contains(status2))
             ) {
            return true;
          }
      }
      return false;
    } // statusTriggersRecalc
    
    public static Set<Id> companyIdsToEvaluateSet = new Set<Id>();
    
    public static Set<String> holdOutReasonSet = null;
    public static Set<String> statusSet = null;
    
    public static final String HOLD_OUT_DEFAULT='Bank Referral';
    public static final String STATUS_DEFAULT='Disqualified';

    public static void setQueryParameters() {
       if (holdOutReasonSet == null) {
          holdOutReasonSet = new Set<String>();
          statusSet = new Set<String>();
          
          for (PaychexSettings__c setting : PaychexSettings__c.getAll().values()) {
             if (setting.IsActive__c && setting.ProcessName__c == 'SignificantHoldOut') {
                holdOutReasonSet.add(setting.Attribute1__c);
             } else if (setting.IsActive__c && setting.ProcessName__c == 'SignificantStatus') {
               statusSet.add(setting.Attribute1__c);
             }
          } // for (PaychexSettings__c setting
          
          // set default values - just in case
          if (holdOutReasonSet.isEmpty()) {
             holdOutReasonSet.add(HOLD_OUT_DEFAULT);
          }
          if (statusSet.isEmpty()) {
             statusSet.add(STATUS_DEFAULT);
          }
          
          System.debug('setQueryParameters holdOutReasonSet='+holdOutReasonSet+' statusSet='+statusSet);
       }  // if (holdOutReasonSet == null
    } // setQueryParameters

   public static Boolean CALCULATE_SIGNIFICANCE=true;

    public static void checkLeadCompany(Boolean allowDelete) {
   /*
System.debug('**CMF ** here at checkLeadCompany, calc_signif='+CALCULATE_SIGNIFICANCE);         
        if (CALCULATE_SIGNIFICANCE && !companyIdsToEvaluateSet.isEmpty()) {
         if (System.isFuture() || System.isBatch() || Test.isRunningTest()) {
               setSignificantLead(companyIdsToEvaluateSet,allowDelete);
           } else {
            setSignificantLeadFuture(companyIdsToEvaluateSet,allowDelete);
           }
           
        } // if (CALCULATE_SIGNIFICANCE
        */
    } // checkLeadCompany
    /*
   @future
   public static void setSignificantLeadFuture(Set<Id> companyIdSet, Boolean allowDelete) {
      setSignificantLead(companyIdSet,allowDelete);
    }
    // Evaluate the lead company and set the significant lead.
    public static void setSignificantLead(Set<Id> companyIdSet, Boolean allowDelete) {

      //companyIdsEvaluatedSet.addAll(companyIdSet);
      
      // the lead companies that will be updated
      Lead_Company__c[] companiesToUpdate = new Lead_Company__c[]{};
      // the lead companies that will be deleted
      Lead_Company__c[] companiesToDelete = new Lead_Company__c[]{};
      
      setQueryParameters();
        // only select ones that are valid
        // the first one for each company id are the ones we'll want to use.
        Lead[] leadList = [Select Id, Name, Company, Lead_Company__c
                                 ,Status, CreatedDate, DoNotCall
                                 ,Hold_Out__c, Hold_Out_Reason__c
                                 ,(Select Id, StartDate__c from Prospect_Ownership__r
                                    Where EndDate__c = null
                                   order by StartDate__c limit 1)
                             From Lead
                            Where Lead_Company__c in :companyIdSet
                              and IsConverted = false
                              and Hold_Out_Reason__c not in :holdOutReasonSet
                              and DoNotCall = false
                              and Status not in :statusSet
                            order by Lead_Company__c asc, CreatedDate desc
                           ];

      // verify at least one lead is attached to the company when selecting
      Lead_Company__c[] leadCompanyList = [
                         select Id, Name, EvaluateSignificant__c, SignificantLead__c 
                               ,(Select Id, Name from Leads__r where IsConverted=false limit 1)
                           from Lead_Company__c 
                          where Id in :companyIdSet
                         ];

      // put all lead companies into a map
      Map<Id,CompanyWrapper> companyMap = new Map<Id,CompanyWrapper>();                        
      for (Lead_Company__c leadCompany : leadCompanyList) {
         CompanyWrapper companyWrapper = new CompanyWrapper(leadCompany);
         companyMap.put(leadCompany.Id,companyWrapper);
      } 

      
      for (Lead ld: leadList) {
        CompanyWrapper companyWrapper = companyMap.get(ld.Lead_Company__c);
        if (companyWrapper != null) {
           companyWrapper.leads.add(ld);
        }
      } // for (Lead ld
      
      // evaluate the company wrappers
      for (CompanyWrapper wrapper : companyMap.values()) {
        if (allowDelete && !wrapper.hasLeads()) {
            companiesToDelete.add(wrapper.leadCompany);
        } else if (wrapper.leadCompanyChanged()) {
            wrapper.leadCompany.EvaluateSignificant__c = false;
            companiesToUpdate.add(wrapper.leadCompany);
         }
      } // for (CompanyWrapper wrapper
      
        if (!companiesToUpdate.isEmpty()) {
           Database.update(companiesToUpdate,false);
        }
      
      if (!companiesToDelete.isEmpty()) {
         Database.delete(companiesToDelete,false);
      }
    } // setSignificantLead
        
   public class CompanyWrapper {
    public CompanyWrapper(Lead_Company__c p_leadCompany) {
       leadCompany = p_leadCompany;
    }
      public Lead_Company__c leadCompany = null;
      public Lead[] leads = new Lead[]{};
      
      // does the lead company have any leads attached to it?
      public Boolean hasLeads() {
         return (leadCompany.Leads__r != null && !leadCompany.Leads__r.isEmpty());
      }
      public Boolean leadCompanyChanged() {
        // if only 1 - default
         Lead significant = (leads.size() == 1 ? leads[0] : null);
         if (leads.size() > 1) {
            Boolean openOwnershipFound = false;
            for (Lead ld : leads) {
                Boolean match = (significant == null);
                if (!match && !openOwnershipFound) {
                   if (ld.Prospect_Ownership__r != null && !ld.Prospect_Ownership__r.isEmpty()) {
                      match = true;
                   }
                }
               if (match) {
                  significant = ld;
                  openOwnershipFound = (ld.Prospect_Ownership__r != null && !ld.Prospect_Ownership__r.isEmpty());
                  if (openOwnershipFound) {
                    // we don't need to continue if we find open ownership
                     break;
                  }
               } // if (match
            } // for (Lead ld
         } // if (leads.size() > 1
         
         Boolean saveCompany = leadCompany.EvaluateSignificant__c;
         Id significantId = (significant != null ? significant.Id : null);
         if (leadCompany.SignificantLead__c != significantId) {
            leadCompany.SignificantLead__c = significantId;
            saveCompany = true;
         }
         return saveCompany;
      } // leadCompanyChanged
      
   } // CompanyWrapper
   */
   // the lead companies we want to evaluate on their account id
   public static List<Id> leadCompaniesToEvaluateAccountId = new List<Id>();
   
   public static void checkHandleAccountId() {
      System.debug('checkHandleAccountId calling leadCompaniesToEvaluateAccountId='+leadCompaniesToEvaluateAccountId.size());
      if (!leadCompaniesToEvaluateAccountId.isEmpty()) {
         if (System.isFuture() || System.isBatch() || Test.isRunningTest()) {
            handleConvertAllLeads(userInfo.getSessionId(),leadCompaniesToEvaluateAccountId);
         } else {
            handleConvertAllLeadsFuture(userInfo.getSessionId(),leadCompaniesToEvaluateAccountId);
         }
      }
   } // checkHandleAccountId
   
   // convert all leads attached to a lead company, using the account id set on the lead company
   @future(callout=true)
   public static void handleConvertAllLeadsFuture(String sessionId, Id[] leadCompanyIds) {
      handleConvertAllLeads(sessionId, leadCompanyIds);
   } // handleConvertAllLeadsFuture

      // send in batch size defined in Label.Lead_Convert_Nbr_Leads
   public static Integer BATCH_SIZE=Integer.valueOf(Label.Lead_Convert_Nbr_Leads);
   
   public static Boolean SKIP_TRIGGER = false;
   
   // convert all leads attached to a lead company, using the account id set on the lead company
   public static void handleConvertAllLeads(String sessionId, Id[] leadCompanyIds) {
      SKIP_TRIGGER = true;
      AccountMethods.CALCULATE_SIGNIFICANCE = false;
      
      // do not select leads with certain lead sources
      Set<String> leadSourceSet = new Set<String>(); 
      for (DoNotConvertLeadSources__c dncls : DoNotConvertLeadSources__c.getAll().values()) {
         leadSourceSet.add(dncls.Name);
      }
      System.debug('handleConvertAllLeads leadCompanyIds='+leadCompanyIds);
      Map<Id,List<Id>> leadIdsByAcctIdMap = new Map<Id,List<Id>>();
      for (Lead ld : [Select Id, Lead_Company__r.AccountId__c 
                        from Lead 
                       where IsConverted=false 
                         and Lead_Company__c in :leadCompanyIds
                         and Lead_Company__r.AccountId__c != null
                         and LeadSource not in :leadSourceSet]) {
         List<Id> leadIds = leadIdsByAcctIdMap.get(ld.Lead_Company__r.AccountId__c);
         if (leadIds == null) {
            leadIds = new List<Id>();
            leadIdsByAcctIdMap.put(ld.Lead_Company__r.AccountId__c,leadIds);
         }
         leadIds.add(ld.Id);
      } // for
      
      System.debug('handleConvertAllLeads leadIdsByAcctIdMap='+leadIdsByAcctIdMap.size());
      
      for (Id acctId : leadIdsByAcctIdMap.keySet()) {
         List<Id> leadIds = leadIdsByAcctIdMap.get(acctId);
         System.debug('handleConvertAllLeads BATCH_SIZE='+BATCH_SIZE+' acctId='+acctId+' nbr leadIds='+leadIds.size());
         List<Id> idsToSend = new List<Id>();
         while (!leadIds.isEmpty()) {
            idsToSend.add(leadIds.remove(0));
            if (idsToSend.size() == BATCH_SIZE) {
                System.debug('handleConvertAllLeads idsToSend.size()='+idsToSend.size()+' processing callout1');
               processCallout(sessionId, acctId, idsToSend);
               idsToSend.clear();
            }
         } // while (!leadIds.
         
         if (!idsToSend.isEmpty()) {
            System.debug('handleConvertAllLeads idsToSend.size()='+idsToSend.size()+' processing callout2');
            processCallout(sessionId, acctId, idsToSend);
         }
      } // for (Id keyId

      AccountMethods.CALCULATE_SIGNIFICANCE = true;
      //companyIdsToEvaluateSet.addAll(leadCompanyIds);
      //LeadCompanyMethods.checkLeadCompany(true);
      AccountMethods.checkSignificantContact();
   } // handleConvertAllLeads
   
   public static void processCallout(String sessionId, Id acctId, Id[] leadIds) {
      HttpRequest req = new HttpRequest();
      req.setEndpoint('https://'+URL.getSalesforceBaseUrl().getHost()+'/services/apexrest/leadConvertOther/');
      req.setMethod('POST');
      String body = '{"acctId":"'+acctId+'",';
      body += '"leadIds":'+JSON.serialize(leadIds)+'}';
      req.setBody(body);
      req.setHeader('Authorization', 'Bearer '+ sessionId);
      req.setHeader('Content-Type', 'application/json');
      req.setTimeout(50000);
      Http http = new Http();
      if (!test.isRunningTest()){
         System.debug('processCallout performing rest callout');
         try {
            HTTPResponse res = http.send(req);
        } catch (Exception ex) {
           ErrorLog.logError('LeadCompanyMethods', 'processCallout', 'Sending message', acctId, ex);
        }
      } else {
        System.debug('processCallout converting leads directly');
         LeadConvertOtherREST.doPost(acctId, leadIds);
      }
      ErrorLog.checkSave();
   } // processCallout
   
} // class LeadCompanyMethods