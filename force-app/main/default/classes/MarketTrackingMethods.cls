/** Methods on the Lead object
 *
 * History
 * -------
 * 12/12/2016 Cindy Freeman        Created.
 * 02/05/2017 Cindy Freeman         Modified for additional phrases from webform, now uses custom setting to map phase and field
 * 02/16/2017 Cindy Freeman         Modified to prevent duplicate MCTs, check Ct before Lead so checking Create_Market_Tracking links to right rcd
 * 03/01/2017 Cindy Freeman         Modified to handle task's with no Whoid to a Lead or Contact, only a WhatId to an account 
 * 03/03/2017 Cindy Freeman         Added Task Call Result to MCT record, useful if task had not WhoId or WhatId populated
 * 03/14/2017 Cindy Freeman         for webleads, use OwnedBy or OwnedByPrev to fill in Source
 * 04/06/2017 Cindy Freeman         changed mnatchMCTtoTask to use qbdialer__Call_Date_Time__c instead of CreatedDate on Task 
 * 05/02/2017 Cindy Freeman         changed to use description from Partner Referral instead of Lead or Contact   
 * 05/04/2017 Cindy Freeman         changed processOptyMCT method to only look for NSS Inbound optys  
 * 05/09/2017 Cindy Freeman         changed linkOpty so only looks at Inbound Optys and wont overwrite existing keywords
   09/11/2017 Dan Carmen            Added in check for null pointer.
   09/25/2017 Dan Carmen            Added handling for number fields
   12/27/2017 Dan Carmen            Refactor some of the methods to use elsewhere.
   01/15/2018 Cindy Freeman         Modified to use toUppercase for MarketingCallTracking_Mapping lookup
   03/09/2018 Dan Carmen            Changes to account for Marketo vs Lead Loader descriptions
   03/20/2018 Cindy Freeman         Added try/catch around SOSL Find on phoneString in tasks
   03/26/2018 Dan Carmen            Modification to the Marketo logic
   03/28/2018 Cindy Freeman         instantiated searchList to avoid null object error
   04/12/2018 Dan Carmen            Marketo is changing the boolean from 1/0 to yes/no. Changed logic to handle both.
   06/20/2018 Rick Segura           update Lead/Contact Product of Interest from MCT product checkboxes
   12/10/2018 Dan Carmen            Replace qbdialer__Call_Date_Time__c with CallDateTime__c
   10/09/2019 Dan Carmen            Change partner referral query
   11/04/2019 Dan Carmen            Remove reference to all ISDC fields
   12/29/2019 Cindy Freeman         add matchMCTtoPartRef method to populate Partner Referral lookup on MCT
   01/29/2024 Pujitha Madamanchi    Remove blob code/create MCT
   01/29/2024 Pujitha Madamanchi    Populate PR on MCT and update PR with XeroId populated by Marketo webhook
   06/10/2024 Pujitha Madamanchi    Set Status to Match Found when PR is found
 */

 public without sharing class MarketTrackingMethods {
  
   //OwnedBy values that need a tracking record
   public static List<String> llcSourceList = new List<String>();
 
   /* pass in Ownedby field from lead or contact to determine if it needs a tracking record
    */
   public static boolean checkOwnedBy(String ownedby)
   { if (llcSourceList.isEmpty())
       {   List<LeadLoaderConfig__c> llcList = LeadLoaderConfig__c.getAll().values();
           for (LeadLoaderConfig__c llc : llcList)
           {  if (llc.CreateTracking__c)
              {  llcSourceList.add(llc.Name);  }
           } // for       
       } // if (llcSourceList.isEmpty)    
     for (String src : llcSourceList)
       {   if (src.equalsIgnoreCase(ownedby))
        {  return true;   }    
       } // for
     return false;            
   } // checkOwnedBy
   
   public static Integer testRuns = 0;
   // map built from custom setting of webform label and field api name
   public static Map<String, String> mctFieldMap = new Map<String, String>();
   public static Map<String, MarketingCallTracking_Mapping__c> mctMap = new Map<String, MarketingCallTracking_Mapping__c>();
   
  /* called from PartnerReferral after trigger, finds Leads and/or Contacts that sent in new webform 
      create and insert MCT records       
    */
/* public static void createTrackingfromHub(Set<Id> partRefIds) {
     testRuns +=1;
           
     List<MarketingCallTracking_Mapping__c> mctMappingList = MarketingCallTracking_Mapping__c.getall().values();  
     for (MarketingCallTracking_Mapping__c mct : mctMappingList) {
        mctFieldMap.put(mct.Name, mct.api_field_name__c);
        mctMap.put(mct.Name, mct);
     }
     System.debug('**MarketTrackingMethods ** mctMappingList='+mctMappingList.size()+' mctMap='+mctMap.size());

     // select the partner referrals     
     List<PartnerReferral__c> partRefList = [select Id, Account__c, Contact__c,                                      
                                   Lead__c, Master_Partner_Referral__c, Source__c, Description__c, ProcessNotes__c
                                   , (Select Id, Partner_Referral__c from Marketing_Call_Tracking__r)
                                   from PartnerReferral__c where id in :partRefIds];
                                   
     // build set of partner referral ids that have an existing MarketTracking rcds so don't create dups
     //Set<Id> partrefExistingMCTSet = new Set<Id> ();
     //List<Marketing_Call_Tracking__c> mctExistingList = [Select Id, Partner_Referral__c from Marketing_Call_Tracking__c
     //                                 where Partner_Referral__c in :partRefIds];
     //for (Marketing_Call_Tracking__c mct: mctExistingList) {
     //   partrefExistingMCTSet.add(mct.Partner_Referral__c);
     //}
                                                                                
     List<Lead> leadUpdateList = new List<Lead>();
     List<Contact> ctctUpdateList = new List<Contact>();
     List<Marketing_Call_Tracking__c> mctList = new List<Marketing_Call_Tracking__c>();
     
     for (PartnerReferral__c pr: partRefList) {
        if (pr.Marketing_Call_Tracking__r.isEmpty()) {
           Marketing_Call_Tracking__c mct = createMCT(pr);
           if (mct != null) {
              mctList.add(mct);
           }           
        } // if (!partrefExistingMCTSet.contains(pr.Id))
     }
     System.debug('**MarketTrackingMethods ** mctList='+mctList.size());     
     if (!mctList.isEmpty() && (!Test.isRunningTest() || (Test.isRunningTest() && testRuns == 1))) {
        if (DmlHelper.performDML2(mctList, DmlHelper.DML_INSERT, 'MarketTrackingMethods', 'createTrackingfromHub', 'Insert Marketing Call Tracking', true) == false) {
           // if there's only 1 record, log on the partner referral record
           if (mctList.size() == 1 && partRefList.size() == 1 && DmlHelper.performDmlResult != null) {
              PartnerReferral__c partRef = partRefList[0];
              StringHelper.addToProcessNotes(partRef, 'Exception creating MCT record: '+DmlHelper.performDmlResult.firstError);
              Database.update(partRef,false);
           }
        }
     }
     
 } // createTrackingfromHub */
  
  public static String TYPE_BOOLEAN='Boolean';
  public static String TYPE_NUMBER='Number';
  
/*  public static String getRecentDescription(String descToCheck) {
     String recentdesc = '';
     if (String.isNotBlank(descToCheck)) {
        if (descToCheck.startsWith(TrackRecordEntry.WEBLEAD_START) && descToCheck.contains(TrackRecordEntry.WEBLEAD_END)) {
           recentdesc = descToCheck.subString(0,descToCheck.indexOf(TrackRecordEntry.WEBLEAD_END));
        } else {
           System.debug('**MarketTrackingMethods ** getRecentDescription descToCheck='+descToCheck);  
           String[] descArray = descToCheck.split('TO: <sales@paychex.com>');
           System.debug('**MarketTrackingMethods ** getRecentDescription descArray size='+descArray.size());          
           recentdesc = (descArray.size() > 1 ? descArray.get(1) : descArray.get(0));
        }  
     }
     System.debug('**MarketTrackingMethods ** getRecentDescription recentdesc = '+recentdesc);
     return recentdesc;
 } // getRecentDescription */
  
  // the separator used between the key and value pairs when coming directly from Marketo.
  public static String MARKETO_SEPARATOR=Label.Marketo_KeyValueSeparator;
  
  /* look at lead or contact to parse description and create MCT record
  */
/* private static Marketing_Call_Tracking__c createMCT(PartnerReferral__c pr) {
     if (String.isBlank(pr.description__c)) {
        System.debug('createMCT description is null');
        return null;
     }
     Marketing_Call_Tracking__c mct = null;
     Map<String, Schema.SObjectField> fieldMap = Marketing_Call_Tracking__c.getSObjectType().getDescribe().fields.getMap();
     
     String recentdesc = getRecentDescription(pr.description__c);
     // Did this weblead originate directly from Marketo which means we parse the record initially?
     Boolean marketoWeblead = (String.isNotBlank(recentDesc) && recentDesc.startsWith(TrackRecordEntry.WEBLEAD_START_MARKETO));
     // depending on how the data comes in (Lead Loader or direct through Marketo) a different separator between the key and value 
     // is used. Lead Loader uses '|^|' and direct from Marketo uses MARKETO_SEPARATOR
     String valueSeparator = '|';
     if (marketoWeblead) {
        valueSeparator = MARKETO_SEPARATOR;
     }
     //String valueSeparator = (marketoWeblead ? MARKETO_SEPARATOR : '|');
     System.debug('MarketTrackingMethods.createMCT valueSeparator='+valueSeparator+' MARKETO_SEPARATOR='+MARKETO_SEPARATOR);
     //System.debug('**CMF ** descrip at beginning of createMCT = '+pr.description__c);  
     //String[] descArray = pr.description__c.split('TO: <sales@paychex.com>');
     //System.debug('**CMF ** descArray size='+descArray.size());          
     //String recentdesc = (descArray.size() > 1 ? descArray.get(1) : descArray.get(0));  
     //System.debug('**CMF ** recentdesc = '+recentdesc);
   
     String[] descList = recentdesc.split('\r');
     System.debug('MarketTrackingMethods.createMCT split1 valueSeparator='+valueSeparator+' descList size='+descList.size());
     if (descList.size() < 2) {
        descList = recentdesc.split('\n');
     }    
     System.debug('MarketTrackingMethods.createMCT split2 descList size='+descList.size()+' mctMap='+mctMap.size());    
                 
     for (String dsc : descList) {
        String prefix = (marketoWeblead ? dsc.substringBefore(MARKETO_SEPARATOR) : dsc.substringBefore('|')).trim();         
        System.debug('MarketTrackingMethods.createMCT before if prefix='+prefix);
        if (String.isNotBlank(prefix) && mctMap.containsKey(prefix.toUpperCase())) {
           MarketingCallTracking_Mapping__c mapping = mctMap.get(prefix.toUpperCase());
           String fldValue = (marketoWeblead ? dsc.substringAfterLast(MARKETO_SEPARATOR) : dsc.substringAfterLast('|')).trim();
           System.debug('MarketTrackingMethods.createMCT prefix='+prefix+' fldValue='+fldValue);
           if (String.isNotBlank(fldValue)) {
              fldValue = fldValue.replaceAll('\r','');
              fldValue = fldValue.replaceAll('\n', '').trim();
              if (mct == null) {
                 mct = new Marketing_Call_Tracking__c();
              }
              Object objectValue = fldValue;
              if (mapping.FieldType__c == TYPE_BOOLEAN) {
                 Boolean booleanValue = ((fldValue == '1' || fldValue == 'yes') ? true : ((fldValue == '0' || fldValue == 'no') ? false : null));
                 objectValue = booleanValue;
              } else if (mapping.FieldType__c == 'Number') {
                 Schema.SObjectField fld = fieldMap.get(mapping.api_field_name__c);
                 if (fld != null) {
                    objectValue = ObjectHelper.formatStringAsObject(fld, fldValue);
                 }
              }
              mct.put(mapping.api_field_name__c, objectValue);
              System.debug('**MarketTrackingMethods ** createMCT fld='+mapping.api_field_name__c+' objectValue='+objectValue);                  
           }
         
        } //if (!String.isBlank(prefix))
     } // for descList
     System.debug('**MarketTrackingMethods ** mct != null '+(mct != null ? 'true':'false'));
     if (mct != null)     // && !String.isBlank(mct.keywords__c))      
     {  mct.source__c = pr.source__c;       
        mct.status__c = 'Match Found';
        mct.Partner_Referral__c = pr.Id;
        mct.Account__c = pr.Account__c;
        mct.Contact__c = pr.Contact__c;
        mct.Lead__c = pr.Lead__c;        
        return mct; 
     } // if (mct!=null)
     return null;
           
 } // createMCT */
  
  /* take passed in selling opty id and contact id and update opty with keywords from latest MCT record within x days (from label)
  */
  public static void linkOpty (Map<Id, Id> optyCtctMap) {
     
     List<Opportunity> optyUpdates = new List<Opportunity>();
     // make set of contact Ids for MCT query     
     Set<Id> ctctSet = new Set<Id>();
     ctctSet.addAll(optyCtctMap.values());
     
     // query uses a label and is expecting a value such as TODAY or LAST_N_DAYS:3 
     String query = 'Select Id, Account__c, Contact__c, keywords__c,gclid__c from Marketing_Call_Tracking__c';
     query += ' where Contact__c in :ctctSet';
     if (Label.MarketingCallTrackingTimeFrame!='No Timeframe')      // use value such as LAST_n_Days:5 to only look at MCT records created in last 5 days
       {   query += ' and CreatedDate = '+Label.MarketingCallTrackingTimeFrame; }
     query += ' order by Contact__c, Name desc';
     List<Marketing_Call_Tracking__c> mctList =Database.query(query);
     // make map<ctct Id, latest keyword>
     Map<Id, String> keywordMap = new Map<Id, String>();
     // make map<ctct Id, latest gclid> 
     Map<Id, String> gclidMap = new Map<Id, String>();
     // make map<ctct Id, latest trackingId>
     Map<Id, Id> trackingMap = new Map<Id, Id>();
     Id ctctId = null;
     for (Marketing_Call_Tracking__c mct : mctList)
     {  if (ctctId == null || ctctId != mct.Contact__c)
        {  ctctId = mct.Contact__c;
           keywordMap.put(mct.Contact__c,mct.keywords__c);
           trackingMap.put(mct.Contact__c, mct.Id);
           if(string.isNotBlank(mct.gclid__c)){
              gclidMap.put(mct.Contact__c,mct.gclid__c);   
           }
        }
     }  
     
     Map<Id, Opportunity> optyMap = new Map<Id, Opportunity>([Select Id, Keywords__c, Latest_Marketing_Call_Tracking__c,GCLID__c 
                                from Opportunity where id in :optyCtctMap.Keyset() and (NSS_Source__C = 'Inbound' OR NSS_Source__C='Inbound-Oasis')]); 
                                                            
     // read thru optyCtctMap if existing opty has no Keywords and MCT, update opty
     for (Id optyId : optyCtctMap.Keyset())
     {  Opportunity opty = optyMap.get(optyId);
        if (opty != null && String.isBlank(opty.Keywords__c) && opty.Latest_Marketing_Call_Tracking__c == null)
       
        {  opty.Keywords__c = keywordMap.get(optyCtctMap.get(optyId));
           opty.Latest_Marketing_Call_Tracking__c = trackingMap.get(optyCtctMap.get(optyId));
           if(string.isBlank(opty.GCLID__c)){
              opty.GCLID__c = gclidMap.get(optyCtctMap.get(optyId));
           }
           optyUpdates.add(opty);
        } // if keywords is blank
     }                 
        
     /* read thru optyCtctMap to create opty, get keyword based on contact, update opty
     for (Id optyId : optyCtctMap.Keyset())
     {  Opportunity opty = new Opportunity();
        opty.Id = optyId;
        opty.Keywords__c = keywordMap.get(optyCtctMap.get(optyId));
        opty.Latest_Marketing_Call_Tracking__c = trackingMap.get(optyCtctMap.get(optyId));
        optyUpdates.add(opty);
     }
     */                
System.debug('**MarketTrackingMethods ** linkOpty updating optys-'+optyUpdates.size());
     if (!optyUpdates.isEmpty())
     {  update optyUpdates;  }
           
  } // linkOpty
     
  /* look at database.converted Lead results to update tracking rcd with acct, ct info
     parameter Map<LeadId, List of Ids(accountId, ContactId)>
  */
  public static void addAcctCt(Map<Id, List<Id>> ldConvertMap) {
     
     List<Marketing_Call_Tracking__c> mctList = [select Id, Lead__c, Account__c, Contact__c, keywords__c from Marketing_Call_Tracking__c
                                      where Lead__c in :ldConvertMap.keySet() order by Lead__c];
     for (Marketing_Call_Tracking__c mct : mctList)                                      
     {  List<Id> idList = ldConvertMap.get(mct.Lead__c);
        mct.Account__c = idList.get(0);
        mct.Contact__c = idList.get(1);
     }
     
     update mctList;
     
  } // addAcctCt
   
//////////////////////////////////////////////////////////////////////////////

/*  // MarketingCallTracking Ids that need to be matched up to an NSS task 
  public static Set<Marketing_Call_Tracking__c> v_processBeforeMCTSet = new Set<Marketing_Call_Tracking__c>();
  
  // MarketingCallTracking Ids that have been processed //
  public static Set<Id> idsProcessedMCTSet = new Set<Id>();
  
  // MarketingCallTracking that need Custom1 field parsed //
  public static Set<Marketing_Call_Tracking__c> v_parseBeforeMCTSet = new Set<Marketing_Call_Tracking__c>();
  // MarketingCallTracking that have been parsed //
  public static Set<Id> idsParsedMCTSet = new Set<Id>();
*/  
 /** contact Ids that were linked task to MCT, use to find any opty that were created **/
 public static Set<Id> v_ctctIdsProcessAfterMCTSet = new Set<Id>();
 /** contact Ids already processed **/
 public static Set<Id> ctctIdsProcessedMCTSet = new Set<Id>();
 
 /** MarketingCallTracking Ids that need to be matched up to Partner Referral by activity ID **/
 public static Set<Id> v_mctIdsNeedPartRef = new Set<Id>();
 /** MCT Ids already processed **/
 public static Set<Id> mctIdsProcessedPartRef = new Set<Id>();
 
 
///////////////
 
/*  public static void checkBeforeMCT(Marketing_Call_Tracking__c newMCT, Marketing_Call_Tracking__c oldMCT) {
     if ((oldMCT == null || (newMCT.match_to_task__c && !oldMCT.match_to_task__c)) 
           && newMCT.Source__c == 'Dialog Tech' && newMCT.Status__c == 'Pending' 
           && (newMct.Match_Attempts__c == null || newMct.Match_Attempts__c < 3))
     {  v_processBeforeMCTSet.add(newMCT);
        newMCT.match_to_task__c = false;
        newMct.Match_Attempts__c = (newMct.Match_Attempts__c == null ? 1 : newMct.Match_Attempts__c + 1);        
     }
     if (newMCT.match_to_task__c && newMCT.Status__c == 'Not Found')
     {  newMCT.match_to_task__c = false; }
     if (newMCT.parse_custom1__c || oldMct == null)
     {  v_parseBeforeMCTSet.add(newMCT); 
        newMCT.parse_custom1__c = false;
     }
           
 } // checkBeforeMCT 
 */
 
 public static void processBeforeMCT(Marketing_Call_Tracking__c[] recs, Map<Id,Marketing_Call_Tracking__c> oldMap) {
    /** MarketingCallTracking Ids that need to be matched up to an NSS task **/
    Set<Marketing_Call_Tracking__c> v_processBeforeMCTSet = new Set<Marketing_Call_Tracking__c>();
    /** MarketingCallTracking that need Custom1 field parsed **/
    //Set<Marketing_Call_Tracking__c> v_parseBeforeMCTSet = new Set<Marketing_Call_Tracking__c>();
    //Process records created by Marketo
    Marketing_Call_Tracking__c[] processMctRecs = new Marketing_Call_Tracking__c[]{};
    Map<Id, Marketing_Call_Tracking__c> mctObjMap = new Map<Id, Marketing_Call_Tracking__c>();

    for (Marketing_Call_Tracking__c mct: recs) {
       Marketing_Call_Tracking__c oldRec = (oldMap!=null ? oldMap.get(mct.id) : null);
       if ((oldRec == null || (mct.match_to_task__c && !oldRec.match_to_task__c)) 
          && mct.Source__c == 'Dialog Tech' && mct.Status__c == 'Pending' 
          && (mct.Match_Attempts__c == null || mct.Match_Attempts__c < 3)){  
             v_processBeforeMCTSet.add(mct);
             mct.match_to_task__c = false;
             mct.Match_Attempts__c = (mct.Match_Attempts__c == null ? 1 : mct.Match_Attempts__c + 1);        
       }
       if (mct.match_to_task__c && mct.Status__c == 'Not Found'){
          mct.match_to_task__c = false; 
       }
       /*if (newMCT.parse_custom1__c || oldMct == null){
          v_parseBeforeMCTSet.add(newMCT); 
          newMCT.parse_custom1__c = false;
       }*/
       if(mct.Source__c == 'WEBLEAD'){
          processMctRecs.add(mct);
           if(mct.Lead__c!=null){
               mctObjMap.put(mct.Lead__c, mct);
           }
           if(mct.Contact__c!=null){
               mctObjMap.put(mct.Contact__c, mct);
           }
       }
    }
       
       
    if (!v_processBeforeMCTSet.isEmpty())
    {  matchMCTtoTask(v_processBeforeMCTSet);    
       v_processBeforeMCTSet.clear();
    }
    /* if (!v_parseBeforeMCTSet.isEmpty())
    {  parseMCT(v_parseBeforeMCTSet);      } */

    if(!processMctRecs.isEmpty()){
        marketoMctsBefore(processMctRecs, mctObjMap);
    }
          
 } // processBeforeMCT
 
////////////////
 
/*  public static void checkAfterMCT(Marketing_Call_Tracking__c newMCT, Marketing_Call_Tracking__c oldMCT) {
   
     if (newMCT.Partner_Referral__c == null && newMCT.Inbound_Task_ID__c != null && !mctIdsProcessedPartRef.contains(newMCT.Id))
    {   v_mctIdsNeedPartRef.add(newMCT.Id);  }
    
 } // checkAfterMCT 
*/
 
  public static void processAfterMCT(Marketing_Call_Tracking__c[] recs, Map<Id,Marketing_Call_Tracking__c> oldMap ) { 
     Map<Id, Marketing_Call_Tracking__c> mctPrMap = new Map<Id, Marketing_Call_Tracking__c>();
     for (Marketing_Call_Tracking__c mct: recs) {      
        Marketing_Call_Tracking__c oldMCT = (oldMap != null ? oldMap.get(mct.Id) : null);
        if (mct.Partner_Referral__c == null && mct.Inbound_Task_ID__c != null && !mctIdsProcessedPartRef.contains(mct.Id)){
           v_mctIdsNeedPartRef.add(mct.Id);
        }
        if(mct.Source__c == 'WEBLEAD'){
           mctPrMap.put(mct.Partner_Referral__c, mct);
        }
     }

     if (!v_ctctIdsProcessAfterMCTSet.isEmpty()){ 
        ctctIdsProcessedMCTSet.addAll(v_ctctIdsProcessAfterMCTSet);          
        linkOptyMCT(v_ctctIdsProcessAfterMCTSet);       
        v_ctctIdsProcessAfterMCTSet.clear();
     } 

     if (!v_mctIdsNeedPartRef.isEmpty()) {   
        mctIdsProcessedPartRef.addAll(v_mctIdsNeedPartRef);
        processMCTtoPartRef(v_mctIdsNeedPartRef);  
        v_mctIdsNeedPartRef.clear();
     } 

     if(!mctPrMap.isEmpty()){
        updatePartRefAfter(mctPrMap);
     }

    
  } // processAfterMCT
  

//////////////////////////////////////////////////////////////////////////////

  public static void matchMCTtoTask(Set<Marketing_Call_Tracking__c> mctSet) {
      
       // build map of phone number to MCT record
       Map<String, Marketing_Call_Tracking__c> phoneMCTMap = new Map<String, Marketing_Call_Tracking__c>();
       // build string of phone number to search for
       String phoneString = '';
     
     // build set of dates so can process old MCTs against old Task records
     Set<Date> mctCallDateSet = new Set<Date>();     

     for (Marketing_Call_Tracking__c mct: mctSet)
     {  if (mct.MM_caller_number__c!=null && phoneMCTMap.containsKey(mct.MM_caller_number__c))
        {  ErrorLog.logError('MarketTrackingMethods', 'matchMCTtoTask', 'building phoneMCTMap, dup phone', mct.Id, 'building phoneMCTMap, dup phone');
              ErrorLog.checkSave();
        } // if phoneMCTMap.containsKey
        //phoneMCTMap.put(mct.MM_caller_number__c, mct);
        String fone = mct.MM_caller_number__c;
        fone = Utilities.removeExtraChars(fone, '0123456789');
        phoneMCTMap.put(fone, mct);
        phoneString = phoneString +'"'+fone+'" OR ';        
      if(mct.MM_Call_Date__c!=null && mct.MM_Call_Date__c.date()!=null){
          mctCallDateSet.add(mct.MM_Call_Date__c.date());
      }
        System.debug('matchMCTtoTask mct.MM_Call_Date__c.date='+mct.MM_Call_Date__c);      
     } // for
     
     phoneString = phoneString.Left(phoneString.length() - 4);
     
     Date beforeDt = System.today();
     Date afterDt = System.today().addDays(-90);     // set this way early so will be reset to max date in mctCallDateSet    
     for (Date dt:mctCallDateSet)
     {  beforeDt = (dt < beforeDt ? dt : beforeDt);
        afterDt = (dt > afterDt ? dt : afterDt);
     }
     beforeDt = beforeDt.addDays(-2);
     afterDt = afterDt.addDays(2);
     System.debug('matchMCTtoTask beforeDt='+beforeDt+' afterDt='+afterDt);     
     List<List<SObject>> searchList = new List<List<SObject>>();
     
     //Schema.RecordTypeInfo taskNSSrt = RecordTypeHelper.getRecordType(RecordTypeHelper.NSS_TASK, ObjectHelper.OBJECT_TASK);
     String taskNSSrtId = '01270000000UNPj'; 

         try {
         searchList = [FIND :phoneString IN PHONE FIELDS RETURNING
                   DS_Denali__DialSource_Action__c (Id, DS_Denali__Account__c, DS_Denali__Phone__c
                                       ,DS_Denali__Contact__c, DS_Denali__Lead__c, DS_Denali__Call_Ended__c
                                       ,InboundCallerId__c
                         where DS_Denali__Call_Ended__c > :beforeDt
                           and DS_Denali__Call_Ended__c < :afterDt
                          order by CreatedDate DESC) 
                      ];
        }
       catch (Exception ex)
       {     ErrorLog.logError('MarketTrackingMethods', 'matchMCTtoTask', 'SOSL Find phoneString='+phoneString, null, ex);
             ErrorLog.checkSave();
       } // catch

     if (searchList.isEmpty())
     {  return;  }                    
     Task[] rsltList = new Task[]{};
     DS_Denali__DialSource_Action__c[] actionList = (DS_Denali__DialSource_Action__c[])searchList[0];
     // select the tasks so we can link them up.
     if (actionList != null && !actionList.isEmpty()) {
        Task[] dsTasks = getDialSourceTasks(actionList);
        rsltList.addAll(dsTasks);
     }
     
     System.debug('matchMCTtoTask rsltList='+rsltList.size()+' actionList='+actionList.size());     
     for (Task tsk: rsltList) {
        //Task tsk = (Task)sobj;            
        System.debug('matchMCTtoTask tsk.CallDateTime__c='+tsk.CallDateTime__c);    
        String taskPhone = (tsk.DS_Denali__DialSource_Action__c != null ? tsk.DS_Denali__DialSource_Action__r.InboundCallerId__c : null);
        taskPhone = Utilities.removeExtraChars(taskPhone, '0123456789');        
        Marketing_Call_Tracking__c mct = (String.isNotBlank(taskPhone) ? phoneMCTMap.get(taskPhone) : null);
     
        if (mct !=  null) {
           //if (sobj.get('Who.Type') == 'Lead')
           String whoseId = (String)tsk.WhoId;
           String whatsId = (String)tsk.WhatId;
           if (String.isBlank(whoseId) && !String.isBlank(whatsId)) {
              mct.Account__c = tsk.WhatId;  
              mct.Inbound_Task_ID__c = (String)tsk.Id;
              mct.Task_Call_Result__c = (String)tsk.CallDisposition;
              mct.Status__c = 'Match Found';
           } else { 
              if (!String.isBlank(whoseId) && whoseId.Left(3) == ObjectHelper.PREFIX_LEAD) {
                 mct.Lead__c = tsk.WhoId;
              } else {
                 mct.Contact__c = tsk.WhoId;
                 mct.Account__c = tsk.WhatId;
                 if (!ctctIdsProcessedMCTSet.contains(tsk.WhoId)) {
                    v_ctctIdsProcessAfterMCTSet.add(tsk.WhoId);
                 }
              }
           } // else
           mct.Inbound_Task_ID__c = (String)tsk.Id;
           mct.Task_Call_Result__c = tsk.CallDisposition;
           mct.Status__c = 'Match Found';
        } // if (mct != null)
     } // for
     
     // go thru set to see if mct never got a task match after 3 tries, change status to Not Found
     for (Marketing_Call_Tracking__c mct :mctSet)
     {  if (mct.Match_Attempts__c == 3 && String.isBlank(mct.Inbound_Task_ID__c))
        {  mct.Status__c = 'Not Found';  }
     }
     
     
           
  } // matchMCTtoTask
  
  public static Task[] getDialSourceTasks(DS_Denali__DialSource_Action__c[] actionList) {
     Id[] dialSourceIds = new Id[]{};
     for (DS_Denali__DialSource_Action__c action : actionList) {
        dialSourceIds.add(action.Id);
     }
     Task[] tsks = [Select Id, WhoId, WhatId, Type, CallDateTime__c, RecordTypeId
                         ,LastModifiedDate, CallDisposition, DS_Denali__DialSource_Action__c
                         ,DS_Denali__DialSource_Action__r.Id
                         ,DS_Denali__DialSource_Action__r.DS_Denali__Account__c
                         ,DS_Denali__DialSource_Action__r.DS_Denali__Phone__c
                         ,DS_Denali__DialSource_Action__r.DS_Denali__Contact__c
                         ,DS_Denali__DialSource_Action__r.DS_Denali__Lead__c
                         ,DS_Denali__DialSource_Action__r.DS_Denali__Call_Ended__c
                         ,DS_Denali__DialSource_Action__r.InboundCallerId__c                          
                      From Task
                     Where DS_Denali__DialSource_Action__c in :dialSourceIds];
     return tsks;
  } // getDialSourceTasks

//////////////////////////////////////////////////////////////////////////////

/*  public static void parseMCT(Set<Marketing_Call_Tracking__c> mctSet) {
     System.debug('**MarketTrackingMethods ** parseMCT, mctsToParse size='+mctSet.size());
     
     if (mctFieldMap.isEmpty())
     {  List<MarketingCallTracking_Mapping__c> mctMappingList = MarketingCallTracking_Mapping__c.getall().values();  
        for (MarketingCallTracking_Mapping__c mct : mctMappingList)
        {  mctFieldMap.put(mct.Name, mct.api_field_name__c);  }
        System.debug('**MarketTrackingMethods ** mctMappingList='+mctMappingList.size()+' mctFieldMap='+mctFieldMap.size());
     }
     
     for (Marketing_Call_Tracking__c mct: mctSet)
     {  String custom1 = mct.MM_Custom1__c;
        if (String.isBlank(custom1))
        {  break;   }
        if (custom1.Left(12)== '?mm_campaign')
        {  custom1 = custom1.substring(1);  }
        System.debug('**MarketTrackingMethods ** custom1='+custom1);            
        String[] custom1List = custom1.split('&');   
        System.debug('**MarketTrackingMethods ** createMCT split custom1List size='+custom1List.size());      
        for (String cst : custom1List)
        {  String prefix = cst.substringBefore('=').trim();      
           if (!String.isBlank(prefix))
           {  if (mctFieldMap.containsKey(prefix))
              {  String fldValue = cst.substringAfterLast('=');        
                 if (!String.isBlank(fldValue))
                 {  fldValue = fldValue.replaceAll('\r', '');
                    fldValue = fldValue.replaceAll('\n', '');
                    mct.put(mctFieldMap.get(prefix), fldValue);
        System.debug('**MarketTrackingMethods ** mct custom prefix='+prefix+' fldValue='+fldValue);                 
                 } // if (fldValue not blank)     
              } // if (.. contains prefix)
           } //if (!String.isBlank(prefix))
        } // for custom1List
     } // for (mctSet)
     
  } // parseMCT

  */

///////////////////////////////////////////////////////////

  public static void linkOptyMCT(Set<Id> p_ctctIdsProcessAfterMCTSet) {
     if (p_ctctIdsProcessAfterMCTSet.size() > 1) {
        if (System.isFuture() || System.isBatch() || Test.isRunningTest()) {
           processOptyMCT(p_ctctIdsProcessAfterMCTSet);
        } else {
           processOptyMCTFuture(p_ctctIdsProcessAfterMCTSet);
        } 
     } // if (acctIdList.size() > 1
     else if (p_ctctIdsProcessAfterMCTSet.size() == 1) 
     {    processOptyMCT(p_ctctIdsProcessAfterMCTSet);  }
   } // linkOptyMCT

   @future
   public static void processOptyMCTFuture(Set<Id> p_ctctIdsProcessAfterMCTSet) {
      processOptyMCT(p_ctctIdsProcessAfterMCTSet);
   } // processCreateJunctionFuture

  
  public static void processOptyMCT(Set<Id> p_ctctIdsProcessAfterMCTSet) {      
     
     //using contacts from tasks, look for opty, add to optyCtctMap, send to linkOpty to update optys with Latest
     Map<Id, Id> optyCtctMap = new Map<Id, Id>(); 
     if (!p_ctctIdsProcessAfterMCTSet.isEmpty())
     {  // query uses a label to set timeframe and is expecting a value such as TODAY or LAST_N_DAYS:2 
        String query = 'SELECT Id, isPrimary, contactId, opportunityId, Role from OpportunityContactRole where ';
        query += ' opportunity.NSS_Source__c = \'Inbound\' ';
        if (Label.MongooseTimeFrame!='No Timeframe')    // use value such as LAST_n_Days:5 to only look at MCT records created in last 5 days
        {  query += ' and CreatedDate = '+Label.MarketingCallTrackingTimeFrame+' ';   }
        query += ' and contactId in :p_ctctIdsProcessAfterMCTSet and isPrimary = true';
        List<OpportunityContactRole> optyCtctRoleList = Database.query(query);                                               
        for (OpportunityContactRole ocr: optyCtctRoleList)
        {  optyCtctMap.put(ocr.opportunityId, ocr.contactId); }
     }
     
     if (!optyCtctMap.isEmpty())
     {  linkOpty(optyCtctMap);  }
                                                                          
     
  } // processOptyMCT

   /***************************************************************************
    Purpose: Returns map of Product of Interest Field Mappings
    Parameters: NONE
    Returns: map<String, Product_of_Interest_Field_Mapping__c>
    Throws [Exceptions]: NONE
    Created: 2018-06-09
    Author: Rick Segura, DemandGen Inc.
   ****************************************************************************/
  public static map<String, String> getProductOfInterestFieldMapping(){
      
     map<String, String> retMap = new map<String, String>();
        
     try{
        //  assume test is not running (for increased code coverage)
        list<MarketingCallTracking_Mapping__c> poiMapList = 
           new list<MarketingCallTracking_Mapping__c>([SELECT api_field_name__c, Field_Value__c FROM MarketingCallTracking_Mapping__c WHERE Source__c = 'MCT' AND Field_Value__c != null ORDER BY Name]);

        for(MarketingCallTracking_Mapping__c v: poiMapList){
           retMap.put(v.api_field_name__c, v.Field_Value__c);
        }
           
     }catch(exception e){
        system.debug('### An exception occurred: ' + e.getMessage() + ' on MarketTrackingMethods.getProductOfInterestFieldMapping()');
     }
     
     return retMap;
  } // getProductOfInterestFieldMapping
  
  /***************************************************************************
    Purpose: Updates Lead/Contact Product of Interest field
    Parameters: list of Marketing_Call_Tracking__c records
    Returns: void
    Throws [Exceptions]: NONE
    Created: 2018-06-09
    Author: Rick Segura, DemandGen Inc.
   ****************************************************************************/
  public static void update_LC_ProductOfInterest(list<Marketing_Call_Tracking__c> mcts){
           
     set<Id> tmpLeadIds = new set<Id>();
     set<Id> tmpContactIds = new set<Id>();
     
     map<Id, sobject> mapLCRecs = new map<Id, sobject>();
     
     list<Contact> lstContacts = new list<Contact>();
     list<Lead> lstLeads = new list<Lead>();
     list<sobject> lstRecsToUpdate = new list<sobject>();
     
     string lcId = '';
     string tmpPOI = '';
     
     system.debug('!!! update_LC_ProductOfInterest.mcts.size(): ' + mcts.size());
     for(Marketing_Call_Tracking__c x : mcts){
        system.debug('!!! mcts id/lead/contact: ' + x.Id + '/' + x.Lead__c + '/' + x.Contact__c);
     }
     
     try{
        // build list of Leads and Contacts for SOQL filters
        for(Marketing_Call_Tracking__c mct: mcts){
           if(mct.Contact__c != NULL){
              tmpContactIds.add(mct.Contact__c );
           }else if (mct.Lead__c != NULL){
              tmpLeadIds.add(mct.Lead__c );
           } // for
        }
        
        // Populate Lead/Contact maps with Product of Interest Values
        if(tmpLeadIds.size() > 0){
           system.debug('!!! tmpLeadsIds.size(): ' + tmpLeadIds.size());
           mapLCRecs.putAll([SELECT Id, Products__c FROM Lead WHERE IsConverted= false AND IsDeleted = false AND Id IN :tmpLeadIds]);
        }
        if(tmpContactIds.size() > 0){
           system.debug('!!! tmpContactIds.size(): ' + tmpContactIds.size());
           mapLCRecs.putAll([SELECT Id, Products__c FROM Contact WHERE IsDeleted = false AND Id IN :tmpContactIds]);
        }
        system.debug('!!! mapLCRecs: ' + mapLCRecs);
        
        map<string, string> fldMap = getProductOfInterestFieldMapping();
        
        // Evaluate Lead/Contact POI value with MCT product checkboxes
        for(Marketing_Call_Tracking__c mct: mcts){
           
           list<string> lstPOIs = new list<string>();
           set<string> setPOIs = new set<String>();
           lcId = '';
           
           if(mct.Contact__c != NULL){
              lcId = mct.Contact__c;
           }else if (mct.Lead__c != NULL){
              lcId = mct.Lead__c;
           }
           
           if(!String.IsBlank(lcId)){
              sobject LCRec = mapLCRecs.get(lcId);
              
              if(LCRec != null){
                 tmpPOI = (String)LCRec.get('Products__c');
                 
                 if(!String.isBlank(tmpPOI)) lstPOIs = tmpPOI.split(';');
                 setPOIs = new set<string>(lstPOIs);
                 system.debug('!!! setPOIs(before): ' + setPOIs);
                 
                 //  Loop through MCT prod checkboxes and adjust POI value as needed
                 for(string fld : fldMap.keySet()){
                    //system.debug('!!! fld/fldMap.get(): ' + fld + '/' + fldMap.get(fld));
                    system.debug('!!! fld/mct.get(fld): ' + fld + '/' + mct.get(fld));
                    if(mct.get(fld) == true){
                       setPOIs.add(fldMap.get(fld));
                    }else{
                       setPOIs.remove(fldMap.get(fld));
                    }
                 }
                 String newPOI = String.join(new list<string>(setPOIs), ';');
                 system.debug('!!! newPOI: ' + newPOI);
                 LCRec.put('Products__c', newPOI);
                 lstRecsToUpdate.add(LCRec);
              }  // if(LCRec != null){
              
           }  // if(!String.IsBlank(lcId)){
           
        } // for
        
        // Update leads and contacts, if any
        system.debug('!!! lstRecsToUpdate.size():' + lstRecsToUpdate.size());
        if(lstRecsToUpdate.size()>0) DmlHelper.performDML2(lstRecsToUpdate, DmlHelper.DML_UPDATE, 'MarketTrackingMethods', 'update_LC_ProductOfInterest', 'Update Lead/Contact Product of Interest (multi)', true);
        
        
     }catch(exception e){
        system.debug('### An exception occurred: ' + e.getMessage() + ' on MarketTrackingMethods.update_LC_ProductOfInterest()');
     }  // try/catch
     
  } // update_LC_ProductOfInterest
  
  //////////////////////////////////////   
  /*  need to populate Partner Referral lookup on Market Call Tracking record
      match using activity ID 
  */
  public static void processMCTtoPartRef(Set<Id> p_mctIdsNeedPartRef) {    

       if (System.isFuture() || System.isBatch() || Test.isRunningTest()) 
       {   matchMCTtoPartRef(p_mctIdsNeedPartRef);    }
       else 
       {  matchMCTtoPartRefFuture(p_mctIdsNeedPartRef);   }
       
  } // processMCTtoPartRef
  
    
  @future
  public static void matchMCTtoPartRefFuture(Set<Id> p_mctIdsNeedPartRef) {
       matchMCTtoPartRef(p_mctIdsNeedPartRef);
  }     
     
  public static void matchMCTtoPartRef (Set<Id> p_mctIdsNeedPartRef) {
      Marketing_Call_Tracking__c[] mctList = [Select Id, MM_Call_Date__c, Inbound_Task_ID__c, Partner_Referral__c from Marketing_Call_Tracking__c 
                          where id in :p_mctIdsNeedPartRef and Partner_Referral__c = null];
      Map<String, Marketing_Call_Tracking__c> actMCTMap = new Map<String, Marketing_Call_Tracking__c>();       
      if (mctList.isEmpty())
      {  return;  }
      
      // build set of dates so can process old MCTs against old Partner Referral records
       Set<Date> mctCallDateSet = new Set<Date>();
      Map<Id, Id> mctLeadIdMap = new Map<Id, Id>();
       for (Marketing_Call_Tracking__c mct:mctList)
       {   
          if(mct.Inbound_Task_ID__c!=null){
             actMCTMap.put(mct.Inbound_Task_ID__c, mct);   
             mctCallDateSet.add(mct.MM_Call_Date__c.date());
          }
       }
       // find earliest date and latest date to limit partner referral query
      Date beforeDt = System.today();
      Date afterDt = System.today().addDays(-90);     // set this way early so will be reset to max date in mctCallDateSet    
      if(mctCallDateSet!=null){
          for (Date dt:mctCallDateSet)
             {   beforeDt = (dt < beforeDt ? dt : beforeDt);
                   afterDt = (dt > afterDt ? dt : afterDt);
             }
          beforeDt = beforeDt.addDays(-2);
          afterDt = afterDt.addDays(2);
       }
      System.debug('matchMCTtoPartRef beforeDt='+beforeDt+' afterDt='+afterDt);

       PartnerReferral__c[] partRefList = [Select Id, Name, ActivityId__c, CreatedDate from PartnerReferral__c 
                           where ActivityId__c in :actMCTMap.keySet()
                           and CreatedDate > :beforeDt
                                     and CreatedDate < :afterDt                                      
                                      order by CreatedDate DESC];                                       
   if (partRefList.isEmpty())
   {  return;  }
   
   List<Marketing_Call_Tracking__c> updateMCTList = new List<Marketing_Call_Tracking__c>();
   
   for (PartnerReferral__c pr:partRefList)
   {  Marketing_Call_Tracking__c mct = actMCTMap.get(pr.ActivityId__c);           
     mct.Partner_Referral__c = pr.Id;
     updateMCTList.add(mct);
   }
   
   if (!updateMCTList.isEmpty())
   {  DmlHelper.performDML(updateMCTList, DmlHelper.DML_UPDATE, 'MarketTrackingMethods', 'matchMCTtoPartRef', 'Updating MCT with Part Ref id', false);  }                  
        
  } // matchMCTtoPartRef
   
  
 public static void marketoMctsBefore(Marketing_Call_Tracking__c[] recs, Map<Id, Marketing_Call_Tracking__c> mctObjMap){
    //update mct with pr
    PartnerReferral__c[] prList = [Select Id, CreatedDate, Lead__c, Contact__c from PartnerReferral__c 
                                      WHERE Lead__c in: mctObjMap.keyset() OR Contact__c in: mctObjMap.keyset()
                                      order by CreatedDate DESC ];
     System.debug('processMarketoMcts prList'+prList.size());
     if(prList!=null){ 
         for(PartnerReferral__c pr : prList){
             //remove from map and then check for mct is not null
            Marketing_Call_Tracking__c mct = pr.Lead__c!=null ? mctObjMap.get(pr.Lead__c): mctObjMap.get(pr.Contact__c);
            if(mct!=null){
                mct.Partner_Referral__c = pr.Id;
                mct.Status__c = 'Match Found';
                break;
            }
         }
     }
 }

 public static void updatePartRefAfter(Map<Id, Marketing_Call_Tracking__c> mctPartRefMap){
  PartnerReferral__c[] updatePartRefs = new PartnerReferral__c[]{};
  PartnerReferral__c[] prList = [Select Id, CreatedDate, Lead__c, Xero_Id__c from PartnerReferral__c 
                                      WHERE Id in: mctPartRefMap.keyset()];
  for(PartnerReferral__c pr: prList){
     Marketing_Call_Tracking__c mct = mctPartRefMap.get(pr.Id);
     pr.Xero_Id__c = pr.Xero_Id__c!=null ? pr.Xero_Id__c : mct.Xero_Id__c;
     StringHelper.addToProcessNotes(pr, 'Populate Xero Id:'+mct.Xero_Id__c);
     updatePartRefs.add(pr);
  }
  if (!updatePartRefs.isEmpty()){  
      //add skip triggers
     DmlHelper.performDML(updatePartRefs, DmlHelper.DML_UPDATE, 'MarketTrackingMethods', 'updatePartRefAfter', 'Updating PartnerReferrals', false);  
  }  

 }
 
 
 
} // MarketTrackingMethods