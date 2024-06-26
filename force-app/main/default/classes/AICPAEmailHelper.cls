/*  This class processes AICPA Leads that come in through AICPAEmailHandler.

 * History
 * --------
 * 10/02/2018  Cindy Freeman    created
 * 12/17/2018  Cindy Freeman    modified to handle variable campaign names, stop process if Street or City are blank
 * 4/30/2019   Matthew Fritsch  Added a check to make sure State field is only 2 characters.
 * 5/29/2019   Matthew Fritsch  Changed the check for a matching Campaign to use startsWith() instead of contains().
 * 08/28/2020  Jake Hinds       Change to remove end date if dupeblocker match
   12/28/2022  Dan Carmen       Modify to use SF Duplicate Management

 */
 
 public without sharing class AICPAEmailHelper {
   
   // for testing purposes when no data in sandbox
   // public static Set<Id> DUPE_OVERRIDE_REFACCT_SET = null;
   // public static Set<Id> DUPE_OVERRIDE_REFCTCT_SET = null;
   
   public without sharing class aicpaLead {
     // must match xml tag names
     public String AccountName;
     public String FirstName;
     public String LastName;
     public String Street1;
     public String Street2;
     public String City;
     public String State;
     public String Zip;
     public String Campaign;
     public String Email;
     public String Phone;
     public String squishedPhone;
     public Id campaignId;
     public Id refAcctId;
     public Id refCtctId;
     public String partRefId;                    // id of the Partner Referral record for this email
     public String originalType;          // translated from campaign, custom setting 
   } // aicpaLead
   
   public static Referral_Account__c refAcct {get; set;}               // referral account created or matched
   public static Referral_Contact__c refCtct {get; set;}               // referral contact created or matched
   public static PartnerReferral__c partRef = null;                    // partner Referral created when Soar email came in
   public static PaychexSettings__c payxSetting = null;                 // custom setting Paychex Settings    

  public static AICPALeadSettings__c aicpaSetting;
  public static Map <String, AICPALeadSettings__c> aicpaSettingsMap;
  public static Id refCtctRcdTypeId;                                    // default record type of new referral account
  public static Id refAcctRcdTypeId;                                    // default record type of new referral contact
  
  public static Map<Id, Id> ctctCmpgnMap {get; set;}                    // map of contact id , campaign id to contact can be added to campaign
     
   public static void processAicpaLeads(List<aicpaLead> aicpaList) {
     List<PartnerReferral__c> partRefUpdateList = new List<PartnerReferral__c>();
     ctctCmpgnMap = new Map<Id, Id>();
     
     // default record types
    String recordTypeName = RecordTypeHelper.CORE_REFERRAL_ACCOUNT;
    Schema.RecordTypeInfo refacctRt = RecordTypeHelper.getRecordType(recordTypeName, ObjectHelper.OBJECT_REF_ACCOUNT); 
        refAcctRcdTypeId = refacctRt.getRecordTypeId();    
    recordTypeName = RecordTypeHelper.CORE_REFERRAL_CONTACT;
    Schema.RecordTypeInfo refctctRt = RecordTypeHelper.getRecordType(recordTypeName, ObjectHelper.OBJECT_REF_CONTACT); 
        refCtctRcdTypeId = refctctRt.getRecordTypeId();         
        
        aicpaSettingsMap = AICPALeadSettings__c.getAll();
               
    try {
       for (aicpaLead aLead: aicpaList)
       {  Id cmpgnId = null;
          for (String cmpgn:aicpaSettingsMap.keySet())
          {     
              System.debug('**CMF ** for map key set='+cmpgn+' aLead.Campaign='+aLead.Campaign);
              if (aLead.Campaign.startsWith(cmpgn) && cmpgn != 'Paychex Webinar')
                {   cmpgnId = aicpaSettingsMap.get(cmpgn).CampaignId__c;    
                    System.debug('**CMF ** campaign contains match');  
                    aicpaSetting = aicpaSettingsMap.get(cmpgn);
                }   
          }
                
          if (cmpgnId == null)
          {     forwardEmail('AicpaEmailHelper error','No campaign match in AICPALeadSetting ='+aLead.Campaign, aLead); 
                ErrorLog.logError('AicpaEmailHelper', 'processAicpaLeads','No campaign match in AICPALeadSetting ='+aLead.Campaign+' partRefId='+aLead.partRefId, null, '');
                ErrorLog.checkSave();
                continue;
          } // if (cmpgnId==null)
                
          //DupeBlocker cant match empty fields so to prevent dups dont process if missing street or city
          if (String.isBlank(aLead.Street1) || String.isBlank(aLead.City))
          {   forwardEmail('AicpaEmailHelper error','No Street or City on incoming email', aLead);
              ErrorLog.logError('AicpaEmailHelper', 'processAicpaLeads','Missing Address parts, partRefId='+aLead.partRefId, null, '');
              ErrorLog.checkSave();
              continue;
          } // catch 
                
         partRef = getPartnerReferral(aLead.partRefId);
         
         aLead.originalType = aicpaSetting.Original_Type__c;
         aLead.campaignId = aicpaSetting.CampaignId__c;
         aLead.squishedPhone = Utilities.removeExtraChars(aLead.Phone, '0123456789');
         
         refAcct = findRefAcct(aLead);
         if (refAcct == null)
         {  break;  }
         aLead.refAcctId = refAcct.Id;
         
         refCtct = findRefCtct(aLead);
         if (refCtct == null)
         {  break;  }
         aLead.RefCtctId = refCtct.Id;
   
         ctctCmpgnMap.put(refCtct.Contact__c,aLead.campaignId);
         System.debug('AICPAEmailHelper.processAicpaLeads adding to ctctCmpgnMap='+refCtct.Contact__c+','+aLead.campaignId);
              
         // update Partner Referral      
         try {
           partRefUpdateList.clear();    
           partRef.CampaignId__c = aLead.campaignId;
           partRef.Campaign__c = aLead.campaignId;    
           partRef.PartnerAcct__c = refAcct.Account__c;
           partRef.PartnerContact__c = refCtct.Contact__c;          
           partRef.Comments__c = 'Successful';            
           partRefUpdateList.add(partRef);
           DmlHelper.performDML2(partRefUpdateList, DmlHelper.DML_UPDATE, 'AICPAEmailHelper', 'processAicpaLeads', 'Update Partner Referral', true);                                 
         }
         catch (exception epr)     // catch problem with Partner Referral update
        {   forwardEmail('AicpaEmailHelper partner referral update error',epr.getMessage(), aLead);  
            ErrorLog.logError('AicpaEmailHelper', 'processAicpaLeads', 'AicpaEmailHelper bad update of partner ref', null, epr.getMessage());
            ErrorLog.checkSave();
            throw new AICPAException();
        }                            
       } // for
    } // try around For loop
    catch (exception forEx) {
      return;
    }//  catch
    
    // add contacts to campaign if not already there
    try {    
       if (!ctctCmpgnMap.isEmpty())     
       {  CampaignMethods.checkToCreateCampaignMembers(ctctCmpgnMap);    }
        } // try
        catch (exception ecm)   // catch problem with adding campaign member
        {    forwardEmail('AicpaEmailHelper CampaignMethods.checkToCreateCampaignMembers error',ecm.getMessage());  
             //ErrorLog.logError('AicpaEmailHelper', 'processAicpaLeads','AicpaEmailHelper CampaignMethods.checkToCreateCampaignMembers error', null,ecm.getMessage());
             ErrorLog.logError('AicpaEmailHelper', 'processAicpaLeads','AicpaEmailHelper CampaignMethods.checkToCreateCampaignMembers error', null,'checkToCreateCampaignMembers error');
             ErrorLog.checkSave();
             //throw new AICPAException(ecm.getMessage());
             throw new AICPAException('AICPAEmailHelper exception CampaignMethods.checkToCreateCampaignMembers');
        }     
        
        return;         
   } // processAicpaList
   
   // create new Referral Account, has Dupe Blocker look for a match, return match or insert new Ref Acct and retrun that one
   private static Referral_Account__c findRefAcct (aicpaLead aLead) {
      aLead.State = ZipCodeInformation.checkStateAbbrev(aLead.State, false);
       
      Referral_Account__c refA = new Referral_Account__c(recordtypeId=refAcctRcdTypeId
                        ,Referral_Source_Business_Type__c='Accounting Firm'
                        ,Referral_Type__c=''
                        ,Name=aLead.AccountName
                        ,NameForDuplicateManagement__c=aLead.AccountName
                        ,Street_Address_1__c=aLead.Street1
                        ,Street_Address_2__c=aLead.Street2
                        ,City__c=aLead.City
                        ,State_Province__c=aLead.State
                        ,Zip_Postal_Code__c=aLead.Zip
                        ,Phone__c=aLead.Phone
                        ,Use_Zip_Assignment_Rules__c=true);
                                  
      Id existingRefAcctId = null;
      DuplicateHelper.DupeResult[] results = DuplicateHelper.findDuplicates(new Referral_Account__c[]{refA}); 
      // should only be one result returned
      DuplicateHelper.DupeResult result = results[0];
      System.debug('findRefAcct result='+result);
      if (result.hasResults && !result.refAcctIds.isEmpty()) {
         existingRefAcctId = result.refAcctIds[0];
         refA = getRefAcctInfo(existingRefAcctId);
         if (String.isBlank(refA.Referral_Source_Business_Type__c)
              || (String.isBlank(refA.Street_Address_2__c) && String.isNotBlank(aLead.Street2))
              || String.isBlank(refA.Phone__c)
              || refA.End_Date__c!=null) {
            System.debug('findRefAcct updating refA');
            refA.Referral_Source_Business_Type__c = (String.isBlank(refA.Referral_Source_Business_Type__c) ? 'Accounting Firm' : refA.Referral_Source_Business_Type__c);
            refA.Street_Address_2__c = aLead.Street2;
            refA.Phone__c = (String.isBlank(refA.Phone__c) ? aLead.Phone : refA.Phone__c);
            refA.End_Date__c = null;
            refA.End_Date_Reason__c = null;
            DmlHelper.performDML2(new Referral_Account__c[]{refA}, DmlHelper.DML_UPDATE, 'AICPAEmailHelper', 'findRefAcct', 'Update existing Ref Acct', true);
         }
      } else {
         System.debug('findRefAcct inserting refA');
         DmlHelper.performDML2(new Referral_Account__c[]{refA}, DmlHelper.DML_INSERT, 'AICPAEmailHelper', 'findRefAcct', 'Insert new Ref Acct', true);  
         refA = getRefAcctInfo(refA.Id);
      } // if (result.hasResults
    /*
    CRMfusionDBR101.DB_Api.preventBlocking();    
        List<CRMfusionDBR101.DB_Api.Matches> matchSets = CRMfusionDBR101.DB_Api.findMatches(refA);
    System.debug('AICPAEmailHelper.findRefAcct refAcct matchSets='+matchSets.size());
            
        if (!matchSets.isEmpty() || (Test.isRunningTest() && DUPE_OVERRIDE_REFACCT_SET != null))
        {     Set<Id> matchedRefAcctSet = new Set<Id>();
            if (Test.isRunningTest())
            {    matchedRefAcctSet.addAll(DUPE_OVERRIDE_REFACCT_SET);  }
            else 
              {    for ( CRMfusionDBR101.DB_Api.Matches matchSet : matchSets )
                  {   for (Id matchId : matchSet.matchedIds)
                      {   matchedRefAcctSet.add(matchId);        }
                  } // for
              } //else 
                                      
              //if (matchedRefAcctSet.size() == 1)
              if (!matchedRefAcctSet.isEmpty())
              {   for (Id aid : matchedRefAcctSet)
                  {   String xid = (String)aid;
                      if (xid.left(3) == 'a06')           // make sure match is another Referral Account
                      {   existingRefAcctId = aid;   
                          refA = getRefAcctInfo(existingRefAcctId);
                          Boolean changed = false;
                          if (String.isBlank(refA.Referral_Source_Business_Type__c))
                          {    refA.Referral_Source_Business_Type__c = 'Accounting Firm';  
                              changed = true;
                          }                                                   
                          if (String.isBlank(refA.Street_Address_2__c) && String.isNotBlank(aLead.Street2))
                          {    refA.Street_Address_2__c = aLead.Street2;  
                              changed = true;
                          }                           
                          if (String.isBlank(refA.Phone__c))
                          {    refA.Phone__c = aLead.Phone;  
                              changed = true;
                          }
                           if(refA.End_Date__c!=null){
                              refA.End_Date__c = null;
                              refA.End_Date_Reason__c = null;
                              changed = true;
                        }
              if (changed)
              {    refAList.add(refA);  
                  DmlHelper.performDML2(refAList, DmlHelper.DML_UPDATE, 'AICPAEmailHelper', 'findRefAcct', 'Update existing Ref Acct', true);
              }
                          break;    // break out of for loop so use 1st Ref Acct match it found
                      } // if is Ref Acct
                  } // for
              } // if not empty
              else
              {    System.debug('**CMF ** found more than 1 Ref Acct match **********');       }         
        } // if !matchSets.isEmpty                
        else
        {
         try 
          {  refAList.add(refA);
            DmlHelper.performDML2(refAList, DmlHelper.DML_INSERT, 'AICPAEmailHelper', 'findRefAcct', 'Insert new Ref Acct', true);  
            refA = getRefAcctInfo(refA.Id);
          }
          catch (exception e)   // catch DupeBlocker exception, should never get here
          {   forwardEmail('AicpaEmailHelper bad insert of new referral account',e.getMessage());
              throw new AICPAException(e.getMessage());
          }
            
          System.debug('AICPAEmailHelper.findRefAcct refA id='+refA.Id+' ownerId='+refA.OwnerId);            
        } // else
     */              
     return refA;     
     
   } // findRefAcct
   
   /* query for Referral Account whether just created it or Dupe Blocker found it
   */
   private static Referral_Account__c getRefAcctInfo(Id refAcctId) {
     
     Referral_Account__c currRefAcct =[Select Id, Name, Referral_Source_Business_Type__c, Referral_Type__c,
             Street_Address_1__c, Street_Address_2__c, City__c, State_Province__c, Zip_Postal_Code__c,
             Phone__c, Account__c, OwnerId,End_Date__c,End_Date_Reason__c             
             from Referral_Account__c where id = :refAcctId];
     
     return currRefAcct;
     
   } // getRefAcctInfo
   
   /* create new Referral Contact, has Dupe Blocker look for a match, return match or insert new Ref Ctct and retrun that one
   */
   private static Referral_Contact__c findRefCtct (aicpaLead aLead) {
      List<Referral_Contact__c> refCList = new List<Referral_Contact__c>();            // use for DMLHelper calls
      aLead.State = ZipCodeInformation.checkStateAbbrev(aLead.State, false);
     
      Referral_Contact__c refC = new Referral_Contact__c(recordtypeId=refCtctRcdTypeId
                       ,Referral_Type__c=''
                       ,Referral_Account__c=refAcct.Id
                       ,Name=aLead.FirstName+' '+aLead.LastName
                       ,First_Name__c=aLead.FirstName
                       ,Last_Name__c=aLead.LastName
                       ,Phone__c=aLead.Phone
                       ,Email__c=aLead.Email                               
                       ,Mailing_Street__c=aLead.Street1+(String.isBlank(aLead.Street2)?'':' '+aLead.Street2)
                       ,Mailing_City__c=aLead.City
                       ,Mailing_State__c=aLead.State
                       ,Mailing_Postal_Code__c=aLead.Zip
                       ,LatestCampaign__c=aLead.campaignId     
                       ,LoadCampaignPrev__c=aLead.campaignId              
                       ,AICPA_Latest_Campaign__c=aLead.Campaign                                                        
                       ,AICPA_Original_Type__c=aLead.originalType
                       ,Use_Account_Ownership__c=true
                       ,OwnerId=refAcct.OwnerId);                 
      Id existingRefCtctId = null;
      DuplicateHelper.DupeResult[] results = DuplicateHelper.findDuplicates(new Referral_Contact__c[]{refC}); 
      // should only be one result returned
      DuplicateHelper.DupeResult result = results[0];
      System.debug('findRefCtct result='+result);
      if (result.hasResults && !result.refCtctIds.isEmpty()) {
         existingRefCtctId=result.refCtctIds[0];
         refC=getRefCtctInfo(existingRefCtctId);
         Boolean changed = fieldUpdated(refC,'Email__c', aLead.Email, true, false );
         changed = fieldUpdated(refC,'Phone__c', aLead.Phone, true, changed );
         String tempStr = aLead.Street1+(String.isBlank(aLead.Street2)?'':' '+aLead.Street2);
         changed = fieldUpdated(refC,'Mailing_Street__c', tempStr, true, changed );
         changed = fieldUpdated(refC,'Mailing_City__c', aLead.city, true, changed );
         changed = fieldUpdated(refC,'Mailing_State__c', aLead.state, true, changed );
         changed = fieldUpdated(refC,'Mailing_Postal_Code__c', aLead.zip, true, changed );
         changed = fieldUpdated(refC,'LatestCampaign__c', aLead.campaignId, false, changed );
         changed = fieldUpdated(refC,'AICPA_Latest_Campaign__c', aLead.Campaign, false, changed );
         changed = fieldUpdated(refC,'AICPA_Original_Type__c', aLead.originalType, false, changed );
         if (refC.End_Date__c!=null) {
            refC.End_Date__c = null;
            refC.End_Date_Reason__c = null;
            changed = true;
         }
         System.debug('findRefCtct updateResult changed='+changed);
         if (changed) {
            DmlHelper.performDML2(new Referral_Contact__c[]{refC}, DmlHelper.DML_UPDATE, 'AICPAEmailHelper', 'findRefCtct', 'Update existing Ref Ctct', true);
         }
      } else {
         DmlHelper.performDML2(new Referral_Contact__c[]{refC}, DmlHelper.DML_INSERT, 'AICPAEmailHelper', 'findRefCtct', 'Insert new Ref Ctct', true);  
         refC = getRefCtctInfo(refC.Id);
      } // if (result.hasResults
    /*
    CRMfusionDBR101.DB_Api.preventBlocking();
        List<CRMfusionDBR101.DB_Api.Matches> matchSets = CRMfusionDBR101.DB_Api.findMatches(refC); 
    System.debug('AICPAEmailHelper.findRefCtct refCtct matchSets='+matchSets.size());
    
    Boolean foundMatch = false;
        Boolean changed = false;        
        if (!matchSets.isEmpty() || (Test.isRunningTest() && DUPE_OVERRIDE_REFCTCT_SET != null))
        {     Set<Id> matchedRefCtctSet = new Set<Id>();
            if (Test.isRunningTest())
            {    matchedRefCtctSet.addAll(DUPE_OVERRIDE_REFCTCT_SET);  }
            else 
            {   for ( CRMfusionDBR101.DB_Api.Matches matchSet : matchSets )
                  {   for (Id matchId : matchSet.matchedIds)
                      {   String xid = (String)matchId;
                          if (xid.left(3) == 'a07')      // make sure match is another Referral Contact
                          {     matchedRefCtctSet.add(xid);        
                 System.debug('AICPAEmailHelper.findRefCtct ref ctct match found, scenario='+matchSet.scenarioId+' ctct='+xid);                          
                          }
                      } // for (Id
                  } // for (CRMfusion
            } // else
              
              if (!matchedRefCtctSet.isEmpty())
              {      Referral_Contact__c[] refCtctList = getRefCtctInfo(matchedRefCtctSet);
                
                  for (Referral_Contact__c refCtct : refCtctList)
                  {    String tempPhone = Utilities.removeExtraChars(refCtct.Phone__c, '0123456789');                    
                       if ((refCtct.Email__c != null && refCtct.Email__c == aLead.Email) ||
                            (tempPhone != null && tempPhone == aLead.squishedPhone))
                       {  refC = refCtct;
                          foundMatch = true;                        
                          break;
                       }
                  } // for
                                              
                  //Boolean changed = false;
                  if (foundMatch) {                  
                    if (String.isBlank(refC.Email__c))
                    {    refC.Email__c =aLead.Email;  
                         changed = true;     
                    }
                    if (String.isBlank(refC.Phone__c))
                    {    refC.Phone__c = aLead.Phone;
                        changed = true;                      
                    }
                    String tempStr = aLead.Street1+(String.isBlank(aLead.Street2)?'':' '+aLead.Street2);                          
                    if (String.isBlank(refC.Mailing_Street__c) && String.isNotBlank(tempStr))
                    {    refC.Mailing_Street__c = tempStr;  
                        changed = true;                         
                    }
                    if (String.isBlank(refC.Mailing_City__c) && String.isNotBlank(aLead.city))
                    {    refC.Mailing_City__c = aLead.City;    
                         changed = true;                         
                    }
                    if (String.isBlank(refC.Mailing_State__c) && String.isNotBlank(aLead.state))
                    {    refC.Mailing_State__c = aLead.State;  
                         changed = true;                         
                    }
                    if (String.isBlank(refC.Mailing_Postal_Code__c) && String.isNotBlank(aLead.zip))
                    {    refC.Mailing_Postal_Code__c = aLead.Zip;  
                        changed = true;                         
                    }
                                                          
                    if (String.isBlank(refC.LatestCampaign__c) || refC.LatestCampaign__c != aLead.campaignId)
                    {    refC.LoadCampaignPrev__c = aLead.campaignId;
                         refC.LatestCampaign__c = aLead.campaignId;    
                         changed = true;                         
                    }
                    if (String.isBlank(refC.AICPA_Latest_Campaign__c) || refC.AICPA_Latest_Campaign__c != aLead.Campaign)
                    {    refC.AICPA_Latest_Campaign__c = aLead.Campaign;
                         changed = true;                         
                    }
                    if (String.isBlank(refC.AICPA_Original_Type__c) || refC.AICPA_Original_Type__c != aLead.originalType)
                    {    refC.AICPA_Original_Type__c = aLead.OriginalType;  
                        changed = true;                         
                    }
                    if(refC.End_Date__c!=null){
                          refC.End_Date__c = null;
                          refC.End_Date_Reason__c = null;
                          changed = true;
                    }
                  }
                  if (changed)
            {    try 
                {  refCList.add(refC);
                   DmlHelper.performDML2(refCList, DmlHelper.DML_UPDATE, 'AICPAEmailHelper', 'findRefCtct', 'Update existing Ref Ctct', true);
                }
                catch (exception e) 
                {  forwardEmail('AicpaEmailHelper bad update of referral contact', e.getMessage());
                  throw new AICPAException(e.getMessage());
                }
            } // if changed   
              }  // if (!matchedRefCtctSet.isEmpty())
        } // if !matchSets.isEmpty                

        if (!foundMatch)
        {  try 
          {  
              CRMfusionDBR101.DB_Api.disableDupeBlocker();
              refCList.add(refC);
              DmlHelper.performDML2(refCList, DmlHelper.DML_INSERT, 'AICPAEmailHelper', 'findRefCtct', 'Insert new Ref Ctct', true);  
              refC = getRefCtctInfo(refC.Id);
          }
          catch (exception e)   // catch DupeBlocker exception, should never get here
          {   forwardEmail('AicpaEmailHelper bad insert of new referral contact',e.getMessage());
              throw new AICPAException(e.getMessage());  
          }                                               
        } // if
     */                 
     System.debug('AICPAEmailHelper.findRefCtct refC id='+refC.Id);                      
     return refC;                                 
   
   } // findRefCtct
     
   public static Boolean fieldUpdated(SObject rec, String fieldName, String valueToCheck, Boolean onlySetIfBlank, Boolean isChanged) {
      Boolean changed = rec.get(fieldName) == null && String.isNotBlank(valueToCheck);
      if (!changed && !onlySetIfBlank && String.isNotBlank(valueToCheck) && (String)rec.get(fieldName) != valueToCheck) {
         changed = true;
      }
      if (changed) {
         rec.put(fieldName, valueToCheck);
      }
      return (isChanged || changed);
   } // fieldUpdated
   
   
   /* query for Referral Contact whether just created it or Dupe Blocker found it
   */
   private static Referral_Contact__c getRefCtctInfo(Id refCtctId) {
     Set<Id> tempSet = new Set<Id>{refCtctId};
     List<Referral_Contact__c> refCtctList = getRefCtctInfo(tempSet);
     return refCtctList.get(0);
   }
     
   private static List<Referral_Contact__c> getRefCtctInfo(Set<Id> refCtctIdSet) {      
     Referral_Contact__c[] currRefCtct = [Select Id, Name, First_Name__c, Last_Name__c, Phone__c, Email__c, 
             Mailing_Street__c, Mailing_City__c, Mailing_State__c, Mailing_Postal_Code__c, AICPA_Latest_Campaign__c,
             LatestCampaign__c, LoadCampaignPrev__c, AICPA_Original_Type__c, Contact__c,End_Date__c,End_Date_Reason__c from Referral_Contact__c
             where id in :refCtctIdSet Order by Phone__c NULLS LAST, Email__c];
     
     return currRefCtct;     
   } // getRefCtctInfo
      
      
    /* get partner referral rcd so can fill in fields
    */
    public static PartnerReferral__c getPartnerReferral(String partRefId) {
        PartnerReferral__c pr = null;
        if (!String.isBlank(partRefId))
        {   Id prId = (Id)partRefId;
            pr = [Select Id, Name, Account__c, Contact__c, Referral__c, Campaign__c, CampaignId__c, Comments__c from PartnerReferral__c
                                    where Id = :prId limit 1];
        }       
        return pr;
    } // getPartnerReferral
        
      
    // this exception is used to throw missing data error messages
    public class AICPAException extends Exception {}
   
     
   /* method to send incoming email to person listed in custom setting
    */
    private static void forwardEmail (String p_subj, String p_body) {
        forwardEmail(p_subj, p_body, null);
    }
    private static void forwardEmail (String p_subj, String p_body, aicpaLead p_aLead ) {
        if (payxSetting == null)  
        {   payxSetting = PaychexSettings__c.getInstance('AICPAForwardErrorEmail');
            if (payxSetting != null && !payxSetting.IsActive__c) 
            {  payxSetting = null;  }
        } // if
        
        if (payxSetting != null && payxSetting.Attribute1__c != null)
        {   Messaging.Singleemailmessage mail = new Messaging.Singleemailmessage();
            List<String> addrList = new List<String>();
            addrList = payxSetting.Attribute1__c.split(';');
            mail.setToAddresses(addrList);
            //mail.setToAddresses (new String[]{payxSetting.Attribute1__c});
            mail.setSubject (p_subj);
            mail.setPlainTextBody(p_body+'  '+p_aLead);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        } // if
             
    } // forwardEmail    
     
 } // AICPAEmailHelper