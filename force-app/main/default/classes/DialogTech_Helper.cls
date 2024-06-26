/* 
 * When DialogTech Call records are inserted:
 *      search for contact - use if found
 *          else search for lead - use if found
 *      create partner referral record
 *      create marketing call tracking record
 *      update call record
 *
 * History
 * -------
   02/14/2019 Cindy Freeman    created
   03/26/2019 Cindy Freeman    changed to set MCT.MM_Call_Date__c = call.IBP__DateAdded__c
   12/03/2019 Cindy Freeman     populating gclid on MCT
   04/09/2020 Dan Carmen        Remove contact record type ids

 */
public without sharing class DialogTech_Helper implements TriggerInterface2 {
    // set of Ids that need market call tracking created
    public static Set<Id> needMCTIdSet = new Set<Id>();
    // set of (cleaned) phone numbers we are searching for
    public static Set<String> phoneSet;
       
    public static Map<String, soslResults> resultMap;  
    public class soslResults {
       public String objType;
       public String objId;
       public String phoneField;
       public SObject sobj;
       public Id dialogRcdId;
    }
    
    public static List<CallWrapper> callWrapperList;
    public class CallWrapper {
        //IBP__Ifbyphone_Call__c kall;
    /*BAU Changes*/
    INVOCA_FOR_SF__Invoca_Call_Log__c kall;
        Marketing_Call_Tracking__c mct;
    }
    
    public void triggerCheckAllFirst(SObject[] recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter) {
        System.debug('DialogTech_Helper.triggerCheckAllFirst recs='+recs.size());    
        needMCTIdSet.clear();
        if (isAfter)
        {   INVOCA_FOR_SF__Invoca_Call_Log__c[] calls = (INVOCA_FOR_SF__Invoca_Call_Log__c[])recs;
            Map<Id,INVOCA_FOR_SF__Invoca_Call_Log__c> oldCallMap = (Map<Id,INVOCA_FOR_SF__Invoca_Call_Log__c>)oldMap;
            for (INVOCA_FOR_SF__Invoca_Call_Log__c call : calls) {
                INVOCA_FOR_SF__Invoca_Call_Log__c oldCall = (oldCallMap != null ? oldCallMap.get(call.Id) : null);           
                if (call.INVOCA_FOR_SF__calling_phone_number__c!='Unknown' && call.MCT__c == null
                    && call.INVOCA_FOR_SF__Account__c== null && call.INVOCA_FOR_SF__Contact__c== null && call.INVOCA_FOR_SF__Lead__c == null
                    && ((oldCall == null) || (oldCall != null && call.createMCT__c && call.createMCT__c != oldCall.createMCT__c)))
                {   needMCTIdSet.add(call.Id);  }
            } // for
        } // if(isAfter)
        
    } // triggerCheckAllFirst
    
    // see if there are any actions that need to take place at the end of the trigger.
    public void triggerCheckActions(Boolean isBefore, Boolean isAfter) {        
        System.debug('DialogTech_Helper.triggerCheckActions, needMCTIdSet='+needMCTIdSet.size());        
        if (isAfter && !needMCTIdSet.isEmpty())
        {   processCallRcds(needMCTIdSet);  }
        
    } // triggerCheckActions
    
    // check each record individually
    public void triggerCheckRec(SObject newRec, SObject oldRec, Boolean isBefore, Boolean isAfter) {}
    
    // for testing purposes, to process the DialogTech call records now instead of the future context
    public static Boolean TEST_PROCESS_NOW=false;
        
    public static void processCallRcds(Set<Id> callIdSet) {
      if (!callIdSet.isEmpty()) {
         if (TEST_PROCESS_NOW || System.isFuture() || System.isBatch()) {
            processCallRcdsNow(callIdSet);
         } else {
            processCallRcdsFuture(callIdSet);
         }
         needMCTIdSet.clear();
      }
    } // checkSalesTeam
    
    @future
    public static void processCallRcdsFuture(Set<Id> callIdSet) {
      processCallRcdsNow(callIdSet);
    }    

    public static void processCallRcdsNow(Set<Id> callIdSet) {
        System.debug('DialogTech_Helper.processCallRcdsNow callIdSet='+callIdSet.size());
        phoneSet = new Set<String>();                   // set of phone numbers we are looking for
        Integer resultNbr = 0;                          // count result from sosl
        String phoneString = '';                        // get phone numbers in string for sosl     
        INVOCA_FOR_SF__Invoca_Call_Log__c[] callList;              // call records
        List<INVOCA_FOR_SF__Invoca_Call_Log__c> updateCallList = new List<INVOCA_FOR_SF__Invoca_Call_Log__c>();  //IBP__Ifbyphone_Call__c// call records to be updated
        Map<Id, Marketing_Call_Tracking__c> insertMCTMap = new Map<Id, Marketing_Call_Tracking__c> ();      // marketing call tracking records to be inserted
        callWrapperList = new List<CallWrapper>();
        
        if (!callIdSet.isEmpty())
        {   /*callList = [Select Id, IBP__CallerID__c, MCT__c, IBP__AccountId__c, IBP__ContactId__c, IBP__Lead__c, createMCT__c, IBP__DateAdded__c, IBP__ST_GCLID__c 
                                                 from IBP__Ifbyphone_Call__c where Id in :callIdSet];*/
      callList = [Select Id, INVOCA_FOR_SF__calling_phone_number__c, MCT__c, INVOCA_FOR_SF__Account__c, INVOCA_FOR_SF__Contact__c, INVOCA_FOR_SF__Lead__c, createMCT__c, INVOCA_FOR_SF__start_time_local__c, INVOCA_FOR_SF__Customer_String_Value_2__c from INVOCA_FOR_SF__Invoca_Call_Log__c where Id in :callIdSet];
            System.debug('DialogTech_Helper.processCallRcdsNow callList='+callList.size());
         
            for (INVOCA_FOR_SF__Invoca_Call_Log__c call: callList)
            {   phoneSet.add(cleanPhone((String)call.INVOCA_FOR_SF__calling_phone_number__c));    
                CallWrapper cw = new CallWrapper();
                //call.createMCT__c = false;
                cw.kall = call;
                callWrapperList.add(cw);
            }
            
            System.debug('DialogTech_Helper.processCallRcdsNow callWrapperList='+callWrapperList.size()+' phoneSet='+phoneSet);
                                
            for (String fone: phoneSet)
            {   phoneString = phoneString +'"'+fone+'" OR ';        }
            phoneString = phoneString.Left(phoneString.length() - 4);
            System.debug('DialogTech_Helper.processCallRcdsNow phoneString='+phoneString);
        
            PaychexSettings__c setting = PaychexSettings__c.getInstance('DuplicatePhoneLimit');
            Integer limitNbr = (setting != null && setting.IsActive__c ? Integer.valueOf(setting.Attribute1__c) : 1000);            
        
            // query and gather results
            resultMap = new Map<String, soslResults>();
            List<List<SObject>> searchList;
            try {   searchList = [FIND :phoneString IN PHONE FIELDS RETURNING
                                    Contact (Id, Name, AccountId, Phone, AssistantPhone, HomePhone, MobilePhone, OtherPhone, NSS_Other_Phone__c,
                                             CreatedDate, LastModifiedDate
                                    Where Phone != null 
                                    Order by LastModifiedDate Desc Limit :limitNbr)];
                    resultNbr += saveResults(searchList[0], 'Contact');
                    searchList = [FIND :phoneString IN PHONE FIELDS RETURNING
                                    Lead (Id, Name, Phone, MobilePhone, Other_Phone__c, 
                                          CreatedDate, LastModifiedDate
                                    Where Phone != null 
                                    Order by LastModifiedDate Desc Limit :limitNbr)];
                    resultNbr += saveResults(searchList[0], 'Lead');
            } // try
            catch (Exception ex) {
                 ErrorLog.logError('DialogTech_Helper', 'processCallRcdsNow', null, null, 'Sosl error '+ex.getMessage()+', phone string='+phoneString);
                 ErrorLog.checkSave();
            } // catch
        
        } // if (!callIdSet.isEmpty())
                
        // go thru wrapper list
        for (callWrapper wrap: callWrapperList )
        {   INVOCA_FOR_SF__Invoca_Call_Log__c call = wrap.kall;
            String cleanFone = cleanPhone(call.INVOCA_FOR_SF__calling_phone_number__c);
            System.debug('DialogTech_Helper.processCallRcdsNow going thru wrapper list,callerId='+call.INVOCA_FOR_SF__calling_phone_number__c+' cleanPhone='+cleanFone);         

            if (resultMap.containsKey(cleanFone))
            {   soslResults rslt = resultMap.get(cleanFone);
             
                if (rslt.objType == 'Contact')
                {   Contact ctct = (Contact)rslt.sobj;
                    call.INVOCA_FOR_SF__Account__c = ctct.AccountId;
                    call.INVOCA_FOR_SF__Contact__c = ctct.Id;                 
                    wrap.mct = new Marketing_Call_Tracking__c(Account__c=ctct.AccountId, Contact__c=ctct.Id, Invoca_Call_Log__c=call.Id,
                                                             MM_Call_Date__c = call.INVOCA_FOR_SF__start_time_local__c, MM_caller_number__c=rslt.phoneField,
                                                             gclid__c = call.INVOCA_FOR_SF__Customer_String_Value_2__c,
                                                             //MM_Call_Date__c=System.today(), MM_caller_number__c=rslt.phoneField,
                                                             Source__c='Invoca', Status__c='Pending' );                                
                    insertMCTMap.put(call.Id,wrap.mct);
                    continue;                                                                
                } // if (objType= Contact)
                else if (rslt.objType == 'Lead')
                {   Lead ld = (Lead)rslt.sobj;
                    call.INVOCA_FOR_SF__Lead__c= ld.Id;
                    Marketing_Call_Tracking__c mktcalltrack = new Marketing_Call_Tracking__c(Lead__c = ld.Id, Invoca_Call_Log__c=call.Id,
                                                                                            MM_Call_Date__c = call.INVOCA_FOR_SF__start_time_local__c, MM_caller_number__c=rslt.phoneField,
                                                                                            gclid__c = call.INVOCA_FOR_SF__Customer_String_Value_2__c,
                                                                                            //MM_Call_Date__c=System.today(),MM_caller_number__c=rslt.phoneField,
                                                                                            Source__c='Invoca', Status__c='Pending' );
                    wrap.mct = mktcalltrack;                
                    insertMCTMap.put(call.Id,mktcalltrack);
                    continue;
                } // if (objType = Lead)
            } // phone found           
        } // for (callWrapper..)
        
        if (!insertMCTMap.isEmpty())
        {   System.debug('**CMF ** insertMCTMap='+insertMCTMap.size());
            DmlHelper.performDML2(insertMCTMap.values(), DmlHelper.DML_INSERT, 'DialogTech_Helper', 'processCallRcdsNow', 'inserting MCT records', true);   
        }
        for (callWrapper wrap:callWrapperList)
        {   Marketing_Call_Tracking__c newMCT = insertMCTMap.get(wrap.kall.Id);
            System.debug('DialogTech_Helper.processCallRcdsNow clear createMCT or update MCT on call, newMCT='+(newMCT==null?'null':newMCT.Id));            
            if (newMCT == null && wrap.kall.createMCT__c == true)
            {   wrap.kall.createMCT__c = false;
                System.debug('DialogTech_Helper.processCallRcdsNow clearing createMCT flag, no newMCT');                
                updateCallList.add(wrap.kall);
            }
            if (newMCT != null && newMCT.Id != null)
            {   wrap.kall.MCT__c = wrap.mct.Id;
                wrap.kall.createMCT__c = false;
                System.debug('DialogTech_Helper.processCallRcdsNow clearing createMCT flag, created MCT');              
                updateCallList.add(wrap.kall);
            }
            // reset createMCT even if didnt find a match
            //else if (wrap.kall.createMCT__c = true)
            //{ wrap.kall.createMCT__c = false;
            //      updateCallList.add(wrap.kall);
            //}
        } // for (callWrapper...)
         
        System.debug('DialogTech_Helper.processCallRcdsNow updateCallList='+updateCallList);        
        if (!updateCallList.isEmpty())
        {   DmlHelper.performDML2(updateCallList, DmlHelper.DML_UPDATE, 'DialogTech_Helper', 'processCallRcdsNow', 'updating Call records', true);  }
        
    } // processCallRcdsNow
    
    /** save sosl results in another list
    **/
    public static Integer saveResults(List<SObject> rsltList, String obj) {
      Integer cnt = 0;
      Boolean matched;
      String phone = null;
      System.debug('DialogTech_Helper.saveResults phoneset='+phoneSet+' rsltList='+rsltList.size());        
      for (SObject rslt: rsltList)
      {     if (obj == 'Contact')
            {   matched = false;
                Contact ctct = (Contact)rslt; 
                if (ctct.Phone != null)
                {   phone = cleanPhone((String)ctct.Phone); 
                    if (phoneSet.contains(phone))
                    {   matched = true; }
                }
                if (!matched && ctct.AssistantPhone != null)    
                {   phone = cleanPhone((String)ctct.AssistantPhone);    
                    if (phoneSet.contains(phone))
                    {   matched = true;}
                }
                if (!matched && ctct.HomePhone != null)    
                {   phone = cleanPhone((String)ctct.HomePhone); 
                    if (phoneSet.contains(phone))
                    {   matched = true;}
                }
                if (!matched && ctct.MobilePhone != null)    
                {   phone = cleanPhone((String)ctct.MobilePhone);   
                    if (phoneSet.contains(phone))
                    {   matched = true;}
                }
                if (!matched && ctct.OtherPhone != null)    
                {   phone = cleanPhone((String)ctct.OtherPhone);    
                    if (phoneSet.contains(phone))
                    {   matched = true;}
                }
                if (!matched && ctct.NSS_Other_Phone__c != null)    
                {   phone = cleanPhone((String)ctct.NSS_Other_Phone__c);    
                    if (phoneSet.contains(phone))
                    {   matched = true;}
                }
                System.debug('DialogTech_Helper.saveResults ctct matched='+ctct.Id);                                   
                if (matched && !resultMap.containsKey(phone)) {
                    soslResults sf = new soslResults();
                    sf.objType = obj;
                    sf.objId = ctct.Id;
                    sf.phoneField = phone;
                    sf.sobj = ctct;
                    resultMap.put(phone,sf);    
                    cnt ++;
                } // if (matched)
            } // if Contact
       
            if (obj == 'Lead')
            {   matched = false;
                Lead ld = (Lead)rslt;
                phone = null;            
                if (ld.Phone != null)
                {   phone = cleanPhone((String)ld.Phone);   
                    if (phoneSet.contains(phone))
                    {   matched = true; }
                }
                if (!matched && ld.MobilePhone != null)    
                {   phone = cleanPhone((String)ld.MobilePhone); 
                    if (phoneSet.contains(phone))
                    {   matched = true;}
                }
                if (!matched && ld.Other_Phone__c != null)    
                {   phone = cleanPhone((String)ld.Other_Phone__c);  
                    if (phoneSet.contains(phone))
                    {   matched = true;}
                }
                System.debug('DialogTech_Helper.saveResults lead matched='+ld.Id);             
                if (matched && !resultMap.containsKey(phone)) {
                    soslResults sf = new soslResults();
                    sf.objType = obj;
                    sf.objId = ld.Id;
                    sf.phoneField = phone;
                    sf.sobj = ld;
                    resultMap.put(phone,sf);    
                    cnt ++;
                } // if (matched)
            } // if (obj == Lead)
         
      }// for      
      System.debug('DialogTech_Helper.saveResults cnt='+cnt+' resultMap='+resultMap.size()+' keyset='+resultMap.keySet());        
      return cnt;
    } // saveResults
    
    /** clean up Phone getting rid of special chars and +1
     **/
   public static String cleanPhone(String fone) {
      String fone2;
      fone2 = (fone.Left(2) == '+1') ? fone.substringAfter('+1') : null;    
      fone = Utilities.removeExtraChars(fone, '0123456789');
      fone2 = Utilities.removeExtraChars(fone2, '0123456789');     
      if (fone.length() > 6)
      { return fone;    }
      if (fone2 != null && fone2.length() > 6)
      { return fone2;   }
      return null; 
   } // cleanPhone
    
    
}