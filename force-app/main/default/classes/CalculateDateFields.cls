/* 
 * Looks for updates to specific fields that will calculate a new date/time value for another field on Reference PEO.
 * 
 * History
 * -------
 * 12/21/2017 Lynn Michels   Created
 * 08/26/2018 Frank Lurz     changes for Case 29499656 - adjust hours
 * 05/19/2020 Manmeet Vaseer Added new getBusinessHoursId24 method.
 *
 */

public without sharing class CalculateDateFields implements TriggerInterface{
   
   public static Boolean SKIP_TRIGGER=false;
   public static map<id, Reference_PEO__C> idToPeoMap = new map<id, Reference_PEO__c>();
   Reference_PEO__c updatedRecord = new Reference_PEO__c();

   public void checkAllBeforeTrigger(SObject[] recs, Map<Id,Object> oldMap) {}

   public void checkAllAfterTrigger(SObject[] recs, Map<Id,Object> oldMap) {}

   public void checkBeforeTrigger(SObject newRec, SObject oldRec) {}
   
   public void processBeforeTriggerActions() {}
   
   public static Id BUSINESS_HOURS_ID = null;
   
   // so we don't try to retrieve it for every record.
   public static Id getBusinessHoursId24() {
      if (BUSINESS_HOURS_ID == null) {
         try {
            BusinessHours bh = [SELECT Id FROM BusinessHours WHERE Name = 'PEO 24']; 
            BUSINESS_HOURS_ID = bh.Id;
         } catch (Exception e) {
            System.debug('getBusinessHoursId unable to get business hours for PEO 24!');
         }
      }
      return BUSINESS_HOURS_ID;
   } // getBusinessHoursId
    
   // so we don't try to retrieve it for every record.
   public static Id getBusinessHoursId() {
      if (BUSINESS_HOURS_ID == null) {
         try {
            BusinessHours bh = [SELECT Id FROM BusinessHours WHERE Name = 'PEO']; 
            BUSINESS_HOURS_ID = bh.Id;
         } catch (Exception e) {
            System.debug('getBusinessHoursId unable to get business hours for PEO 24!');
         }
      }
      return BUSINESS_HOURS_ID;
   } // getBusinessHoursId
   
   
    public void checkAfterTrigger(SObject newRec, SObject oldRec){
                
        //convert from SObject to Reference PEO
        Reference_PEO__c refPEO = (Reference_PEO__c)newRec;
        Reference_PEO__c oldRefPEO = (Reference_PEO__c)oldRec;

      checkDateTimeFld(refPEO, oldRefPEO, 'Sent_to_WC_UW_Time__c', 4, new String[]{'WC_UW_Complete_Target_Time__c'});
      checkDateTimeFld(refPEO, oldRefPEO, 'WC_UW_Complete_Time__c', 4, new String[]{'Payroll_Shell_W_Target_Time__c'});
      checkDateTimeFld(refPEO, oldRefPEO, 'WC_UW_Complete_Time__c', 4, new String[]{'ER_Benefits_Setup_W_Target_Time__c'});
      checkDateTimeFld(refPEO, oldRefPEO, 'Pass_to_New_Loads_Date_Time__c', 4, new String[]{'Payroll_Shell_P_Target_Time__c','WC_Loaded_Target_Time__c'});
      checkDateTimeFld(refPEO, oldRefPEO, 'Pass_to_New_Loads_Date_Time__c', 2, new String[]{'EE_Verification_Target_Time__c'});
      checkDateTimeFld(refPEO, oldRefPEO, 'EEs_Loaded_Time__c', 8, new String[]{'ER_Benefits_Setup_P_Target_Time__c'});
      checkDateTimeFld(refPEO, oldRefPEO, 'WC_Loaded_Time__c', 4, new String[]{'Ees_Loaded_Target_Time__c'});
      checkDateTimeFld(refPEO, oldRefPEO, 'Ready_for_SEDI_Time__c', 4, new String[]{'SEDI_Complete_Target_Time__c'});
      checkDateTimeFld(refPEO, oldRefPEO, 'SEDI_Complete_Time__c', 4, new String[]{'Set_to_Pending_Target_Time__c'});
      checkDateTimeFld(refPEO, oldRefPEO, 'Sent_to_Med_UW_Time__c', 4, new String[]{'MED_UW_Target_Time__c'});
      checkDateTimeFld(refPEO, oldRefPEO, 'Onbrdg_HRIS_Approved_Time__c', 6, new String[]{'Final_Enrollment_Target_Time__c'});
      checkDateTimeFld(refPEO, oldRefPEO, 'Med_UW_Time__c', 2, new String[]{'Pass_to_NB_Target_Time__c'});
      checkDateTimeFld(refPEO, oldRefPEO, 'Med_UW_Time__c', 1, new String[]{'Set_to_Approved_Target_Time__c'});
      checkDateTimeFld(refPEO, oldRefPEO, 'EE_Verification_Time__c', 2, new String[]{'Mgmt_Hold_Removed_Target_Time__c'});
      checkDateTimeFld(refPEO, oldRefPEO, 'Set_to_Pending_Time__c', 2, new String[]{'Set_Email_Launch_Target_Time__c'});
      
      System.debug(LoggingLevel.Info, 'LM idToPeoMap.values() ' +idToPeoMap.values()); 
    }// checkAfterTrigger
    
    // check the field on the PEO record. If it's non-null and is new or changed, set the hours on the setFldNames.
    // if it's null and it's not new and changed, clear out the setFldNames
    public static void checkDateTimeFld(Reference_PEO__c refPeo, Reference_PEO__c oldRefPeo, String fieldName, Integer nbrHours, String[] setFldNames) {
       DateTime newValue = (DateTime)refPeo.get(fieldName);
       DateTime oldValue = (oldRefPeo != null ? (DateTime)oldRefPeo.get(fieldName) : (DateTime)null);
       Boolean useSetValue = false;
       DateTime setValue = null;
       System.debug('checkDateTimeFld fieldName='+fieldName+' newValue='+newValue+' oldValue='+oldValue);
       
       if (newValue != null && (oldRefPeo == null || newValue != oldValue)) {
          setValue = CalculateBusinessHours.addHours(newValue, nbrHours, getBusinessHoursId());
          useSetValue = true;
       } else if (newValue == null && oldRefPeo != null && oldValue != null) {
          setValue = null;
          useSetValue = true;
       }

       System.debug('checkDateTimeFld fieldName='+fieldName+' newValue='+newValue+' oldValue='+oldValue+' useSetValue='+useSetValue+' setValue='+setValue);

       if (useSetValue) {
          Reference_PEO__c updateRec = (idToPeoMap.containsKey(refPeo.Id) ? idToPeoMap.get(refPeo.Id) : new Reference_PEO__c(ID = refPeo.Id));
          //loop through the fields to set
          for (String setFldName : setFldNames) {
             System.debug('checkDateTimeFld setFldName='+setFldName+' setValue='+setValue);
             //for this record, set the field value using .put(field, value)
             updateRec.put(setFldName, setValue);
             System.debug('updateRec='+updateRec);
          }
          idToPeoMap.put(refPeo.Id, updateRec); //make sure the record and its new values are in the map
       }
    } // checkDateTimeFld
              
   public void processAfterTriggerActions(){
      System.debug('processAfterTriggerActions idToPeoMap='+idToPeoMap.size());
      if(!idToPeoMap.isEmpty()){
         system.debug('LM update**');
         SKIP_TRIGGER = true;
         update idToPeoMap.values();
         idToPeoMap.clear();
         SKIP_TRIGGER = false;
      }//end isEmpty
   }//end processAfterTriggerActions
      /*
        //if field has changed or is populated
        if(refPEO.Sent_to_WC_UW_Time__c != ((Reference_PEO__c)oldRec).Sent_to_WC_UW_Time__c){
            
            Reference_PEO__c updatedRecord = new Reference_PEO__c();
            
            //does the map contain the active peo id?
            if(!idToPeoMap.containsKey(refPEO.id)){
                //set it's id to the active record
                updatedRecord = new Reference_PEO__c(id = refPEO.id);
                idToPeoMap.put(updatedRecord.id, updatedRecord);    
            }
            //if that peo record is already in the map, set the peo record and update its values
            else{
                updatedRecord = idToPeoMap.get(refPEO.id);
            }
            
            if(((Reference_PEO__c)oldRec).Sent_to_WC_UW_Time__c != null && refPEO.Sent_to_WC_UW_Time__c == null){
                updatedRecord.WC_UW_Complete_Target_Time__c = null;
            }
            else{
                updatedRecord.WC_UW_Complete_Target_Time__c = CalculateBusinessHours.addHours(refPEO.Sent_to_WC_UW_Time__c, 4, businessHourId);
            }
        }//end if Sent_to_WC_UW_Time__c
       */

      
      /*
        if(refPEO.WC_UW_Complete_Time__c != ((Reference_PEO__c)oldRec).WC_UW_Complete_Time__c) {
        
            Reference_PEO__c updatedRecord = new Reference_PEO__c();            
                //does the map contain the active peo id?
                if(!idToPeoMap.containsKey(refPEO.id)){
                    //set it's id to the active record
                    updatedRecord = new Reference_PEO__c(id = refPEO.id);
                    idToPeoMap.put(updatedRecord.id, updatedRecord);    
                }
                //if that peo record is already in the map, set the peo record and update its values
                else{
                    updatedRecord = idToPeoMap.get(refPEO.id);
                }   
            if(((Reference_PEO__c)oldRec).WC_UW_Complete_Time__c != null && refPEO.WC_UW_Complete_Time__c == null){
                updatedRecord.Payroll_Shell_W_Target_Time__c = null;
                updatedRecord.ER_Benefits_Setup_W_Target_Time__c = null;
            }//if field is null
            else{
                updatedRecord.Payroll_Shell_W_Target_Time__c = CalculateBusinessHours.addHours(refPEO.WC_UW_Complete_Time__c, 2, businessHourId);
                updatedRecord.ER_Benefits_Setup_W_Target_Time__c = CalculateBusinessHours.addHours(refPEO.WC_UW_Complete_Time__c, 4, businessHourId);   
            }//if populated
            
        }//end if WC_UW_Complete_Time__c
        */

      /*
        if(refPEO.Pass_to_New_Loads_Date_Time__c != ((Reference_PEO__c)oldRec).Pass_to_New_Loads_Date_Time__c){
            Reference_PEO__c updatedRecord = new Reference_PEO__c();
            
            //does the map contain the active peo id?
            if(!idToPeoMap.containsKey(refPEO.id)){
                //set it's id to the active record
                updatedRecord = new Reference_PEO__c(id = refPEO.id);
                idToPeoMap.put(updatedRecord.id, updatedRecord);    
            }
            //if that peo record is already in the map, set the peo record and update its values
            else{
                updatedRecord = idToPeoMap.get(refPEO.id);
            }
            if(((Reference_PEO__c)oldRec).Pass_to_New_Loads_Date_Time__c != null && refPEO.Pass_to_New_Loads_Date_Time__c == null){
                updatedRecord.Payroll_Shell_P_Target_Time__c = null;
                updatedRecord.WC_Loaded_Target_Time__c = null;
                updatedRecord.EE_Verification_Target_Time__c = null;
            }
            else{
                updatedRecord.Payroll_Shell_P_Target_Time__c = CalculateBusinessHours.addHours(refPEO.Pass_to_New_Loads_Date_Time__c, 4, businessHourId);   
                updatedRecord.WC_Loaded_Target_Time__c = CalculateBusinessHours.addHours(refPEO.Pass_to_New_Loads_Date_Time__c, 4, businessHourId);
                updatedRecord.EE_Verification_Target_Time__c = CalculateBusinessHours.addHours(refPEO.Pass_to_New_Loads_Date_Time__c, 2, businessHourId); 
            }
        }//end if Pass_to_New_Loads_Date_Time__c
        */

   
      /*
        if(refPEO.EEs_Loaded_Time__c != ((Reference_PEO__c)oldRec).EEs_Loaded_Time__c){
            
            Reference_PEO__c updatedRecord = new Reference_PEO__c();
            
            //does the map contain the active peo id?
            if(!idToPeoMap.containsKey(refPEO.id)){
                //set it's id to the active record
                updatedRecord = new Reference_PEO__c(id = refPEO.id);
                idToPeoMap.put(updatedRecord.id, updatedRecord);    
            }
            //if that peo record is already in the map, set the peo record and update its values
            else{
                updatedRecord = idToPeoMap.get(refPEO.id);
            }
            if(((Reference_PEO__c)oldRec).EEs_Loaded_Time__c != null && refPEO.EEs_Loaded_Time__c == null){
                updatedRecord.ER_Benefits_Setup_P_Target_Time__c = null;
            }
            else{
                updatedRecord.ER_Benefits_Setup_P_Target_Time__c = CalculateBusinessHours.addHours(refPEO.EEs_Loaded_Time__c, 8, businessHourId);       
            }
        }//end if EEs_Loaded_Time__c
        */
        
   
      /*
        if(refPEO.Ready_for_SEDI_Time__c != ((Reference_PEO__c)oldRec).Ready_for_SEDI_Time__c){
            
            Reference_PEO__c updatedRecord = new Reference_PEO__c();
            
            //does the map contain the active peo id?
            if(!idToPeoMap.containsKey(refPEO.id)){
                //set it's id to the active record
                updatedRecord = new Reference_PEO__c(id = refPEO.id);
                idToPeoMap.put(updatedRecord.id, updatedRecord);    
            }
            //if that peo record is already in the map, set the peo record and update its values
            else{
                updatedRecord = idToPeoMap.get(refPEO.id);
            }
            if(((Reference_PEO__c)oldRec).Ready_for_SEDI_Time__c != null && refPEO.Ready_for_SEDI_Time__c == null){
                updatedRecord.SEDI_Complete_Target_Time__c = null;
            }
            else{
                updatedRecord.SEDI_Complete_Target_Time__c = CalculateBusinessHours.addHours(refPEO.Ready_for_SEDI_Time__c, 2, businessHourId);     
            }
        }//end if Ready_for_SEDI_Time__c
        */
        
      /*
        if(refPEO.WC_Loaded_Time__c != ((Reference_PEO__c)oldRec).WC_Loaded_Time__c){
             Reference_PEO__c updatedRecord = new Reference_PEO__c();
            
            //does the map contain the active peo id?
            if(!idToPeoMap.containsKey(refPEO.id)){
                //set it's id to the active record
                updatedRecord = new Reference_PEO__c(id = refPEO.id);
                idToPeoMap.put(updatedRecord.id, updatedRecord);    
            }
            //if that peo record is already in the map, set the peo record and update its values
            else{
                updatedRecord = idToPeoMap.get(refPEO.id);
            }
            if(((Reference_PEO__c)oldRec).WC_Loaded_Time__c != null && refPEO.WC_Loaded_Time__c == null){
                updatedRecord.Ees_Loaded_Target_Time__c = null;
            }
            else{
                updatedRecord.Ees_Loaded_Target_Time__c = CalculateBusinessHours.addHours(refPEO.WC_Loaded_Time__c, 4, businessHourId);     
            }
        }//end if WC_Loaded_Time__c
        */
        
  
      /*
        if(refPEO.SEDI_Complete_Time__c != ((Reference_PEO__c)oldRec).SEDI_Complete_Time__c){
            
            Reference_PEO__c updatedRecord = new Reference_PEO__c();
            
            //does the map contain the active peo id?
            if(!idToPeoMap.containsKey(refPEO.id)){
                //set it's id to the active record
                updatedRecord = new Reference_PEO__c(id = refPEO.id);
                idToPeoMap.put(updatedRecord.id, updatedRecord);    
            }
            //if that peo record is already in the map, set the peo record and update its values
            else{
                updatedRecord = idToPeoMap.get(refPEO.id);
            }
            if(((Reference_PEO__c)oldRec).SEDI_Complete_Time__c != null && refPEO.SEDI_Complete_Time__c == null){
                updatedRecord.Set_to_Pending_Target_Time__c = null;
            }
            else{
                updatedRecord.Set_to_Pending_Target_Time__c = CalculateBusinessHours.addHours(refPEO.SEDI_Complete_Time__c, 4, businessHourId);     
            }
        }//end if SEDI_Complete_Time__c
        */
        
      
      /*
        if(refPEO.Sent_to_Med_UW_Time__c != ((Reference_PEO__c)oldRec).Sent_to_Med_UW_Time__c){
            
            Reference_PEO__c updatedRecord = new Reference_PEO__c();
            
            //does the map contain the active peo id?
            if(!idToPeoMap.containsKey(refPEO.id)){
                //set it's id to the active record
                updatedRecord = new Reference_PEO__c(id = refPEO.id);
                idToPeoMap.put(updatedRecord.id, updatedRecord);    
            }
            //if that peo record is already in the map, set the peo record and update its values
            else{
                updatedRecord = idToPeoMap.get(refPEO.id);
            }
            if(((Reference_PEO__c)oldRec).Sent_to_Med_UW_Time__c != null && refPEO.Sent_to_Med_UW_Time__c == null){
                updatedRecord.MED_UW_Target_Time__c = null;
            }
            else{
                updatedRecord.MED_UW_Target_Time__c = CalculateBusinessHours.addHours(refPEO.Sent_to_Med_UW_Time__c, 4, businessHourId);    
            }
        }//end if Sent_to_Med_UW_Time__c
        */
        
      
      /*
        if(refPEO.Onbrdg_HRIS_Approved_Time__c != ((Reference_PEO__c)oldRec).Onbrdg_HRIS_Approved_Time__c){
            Reference_PEO__c updatedRecord = new Reference_PEO__c();
            
            //does the map contain the active peo id?
            if(!idToPeoMap.containsKey(refPEO.id)){
                //set it's id to the active record
                updatedRecord = new Reference_PEO__c(id = refPEO.id);
                idToPeoMap.put(updatedRecord.id, updatedRecord);    
            }
            //if that peo record is already in the map, set the peo record and update its values
            else{
                updatedRecord = idToPeoMap.get(refPEO.id);
            }
            if(((Reference_PEO__c)oldRec).Onbrdg_HRIS_Approved_Time__c != null && refPEO.Onbrdg_HRIS_Approved_Time__c == null){
                updatedRecord.Final_Enrollment_Target_Time__c = null;
            }
            else{
                updatedRecord.Final_Enrollment_Target_Time__c = CalculateBusinessHours.addHours(refPEO.Onbrdg_HRIS_Approved_Time__c, 6, businessHourId);
            }
        }//end if Onbrdg_HRIS_Approved_Time__c
        */
        
      
      /*
        if(refPEO.Med_UW_Time__c != ((Reference_PEO__c)oldRec).Med_UW_Time__c){     
            Reference_PEO__c updatedRecord = new Reference_PEO__c();
            
            //does the map contain the active peo id?
            if(!idToPeoMap.containsKey(refPEO.id)){
                //set it's id to the active record
                updatedRecord = new Reference_PEO__c(id = refPEO.id);
                idToPeoMap.put(updatedRecord.id, updatedRecord);    
            }
            //if that peo record is already in the map, set the peo record and update its values
            else{
                updatedRecord = idToPeoMap.get(refPEO.id);
            }
            if(((Reference_PEO__c)oldRec).Med_UW_Time__c != null && refPEO.Med_UW_Time__c == null){
                updatedRecord.Pass_to_NB_Target_Time__c = null;
            }
            else{
                updatedRecord.Pass_to_NB_Target_Time__c = CalculateBusinessHours.addHours(refPEO.Med_UW_Time__c, 2, businessHourId);    
            }
        }//end if Onbrdg_HRIS_Approved_Time__c
        */
        
      /*
        if(refPEO.EE_Verification_Time__c != ((Reference_PEO__c)oldRec).EE_Verification_Time__c){
            
            Reference_PEO__c updatedRecord = new Reference_PEO__c();
            
            //does the map contain the active peo id?
            if(!idToPeoMap.containsKey(refPEO.id)){
                //set it's id to the active record
                updatedRecord = new Reference_PEO__c(id = refPEO.id);
                idToPeoMap.put(updatedRecord.id, updatedRecord);    
            }
            //if that peo record is already in the map, set the peo record and update its values
            else{
                updatedRecord = idToPeoMap.get(refPEO.id);
            }
            if(((Reference_PEO__c)oldRec).EE_Verification_Time__c != null && refPEO.EE_Verification_Time__c == null){
                updatedRecord.Mgmt_Hold_Removed_Target_Time__c = null;
            }
            else{
                updatedRecord.Mgmt_Hold_Removed_Target_Time__c = CalculateBusinessHours.addHours(refPEO.EE_Verification_Time__c, 2, businessHourId);    
            }
        }//end if EE_Verification_Time__c
        */
               
    //LM THIS IS SUPPOSED TO BE CALLED IN PROCESSAFTERTRIGGERACTIONS = NOT WORKING
    //if(!idToPeoMap.isEmpty()){
//          system.debug('LM update');
    //  update idToPeoMap.values();
        //}//end isEmpty
   // }//end checkAfterTrigger

   
        
}//end CalculateDateField