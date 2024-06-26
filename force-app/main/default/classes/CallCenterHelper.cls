/* 
 * Helper for Call Center fields
 *
 * History
 * -------
   12/05/2018 Dan Carmen       Created
   01/23/2023 Dan Carmen       Change to InterfaceC

 */
public with sharing class CallCenterHelper implements TriggerInterfaceC {
      
   public void handleTrigger(SObject[] p_recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter, Boolean isDelete) {
      SObject[] recs = TriggerMethods.checkRecs('CallCenterHelper', p_recs, oldMap, isBefore, isAfter, null, null);
      System.debug('CallCenterHelper.handleTrigger recs='+(recs != null ? recs.size() : -1));
      if (isBefore && recs != null && !recs.isEmpty()) {
         SObjectType recType = TriggerMethods.objType;
         if (recType == Account.sObjectType
                    || recType == Contact.sObjectType
                    || recType == Lead.sObjectType) {
            checkCallTime(recs, oldMap);
         }
      } // if (isBefore && recs != null
   } // handleTrigger

   public static String RT_INBOUND='Inbound';
   public static String RT_OUTBOUND='Outbound';

   public static Schema.RecordTypeInfo rtInbound = null;
   public static Schema.RecordTypeInfo rtOutbound = null;
   
   public static void checkDSRecordTypes() {
      if (rtInbound == null) {
         Map<String,Schema.RecordTypeInfo> byNameMap = DS_Denali__DialSource_Action__c.SObjectType.getDescribe().getRecordTypeInfosByName();
         rtInbound = byNameMap.get(CallCenterHelper.RT_INBOUND);
         rtOutbound = byNameMap.get(CallCenterHelper.RT_OUTBOUND);
      }
   } // checkDSRecordTypes
   
   // get the call center record type for the outbound type
   public static Schema.RecordTypeInfo getOutboundRt() {
      checkDSRecordTypes();
      return rtOutbound;
   } // getInboundRt
   
   // get the call center record type for the inbound type
   public static Schema.RecordTypeInfo getInboundRt() {
      checkDSRecordTypes();
      return rtInbound;
   } // getInboundRt
   
   public static String[] CHECK_DATE_FLDS = Label.CallTime_Flds.split(',');

   public static String CALL_TIME_FLD='LatestCallTime__c';

   public static void checkCallTime(SObject[] recs, Map<Id,SObject> oldMap) {

      for (SObject rec : recs) {
         Datetime maxCheckDt = null;
         for (String dtFld : CHECK_DATE_FLDS) {
            maxCheckDt = checkLatestDate(rec, dtFld, maxCheckDt);
         }
         maxCheckDt = checkLatestDate(rec, CALL_TIME_FLD, maxCheckDt);
         rec.put(CALL_TIME_FLD,maxCheckDt);
      } // for (SObject rec
      
   } // checkCallTime
   
   // figure out which of the datetimes is the latest
   public static Datetime checkLatestDate(SObject rec, String fldName, Datetime latestTime) {
      Datetime returnTime = null;
      Datetime checkTime = (Datetime)rec.get(fldName);
      if (latestTime == null && checkTime != null) {
         returnTime = checkTime;
      } else if (latestTime != null && checkTime == null) {
         returnTime = latestTime;
      } else if (latestTime != null && checkTime != null) {
         returnTime = (latestTime >= checkTime ? latestTime : checkTime);
      }
      return returnTime;
   } // CHECK_DATE_FLDS
   

} // class CallCenterHelper