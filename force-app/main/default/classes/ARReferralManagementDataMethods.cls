/* 
  Methods to handle the AR Referral Management Data records from the trigger.

  AR emails file to email upload service, it creates AR Referral Management Data records which then update the
  associated Payx Referral record and AMP Referral record.
   
  History
  -------
  09/045/2019 Carrie Marciano   Created
    07/06/2020  Jacob Hinds         Added without sharing per PMD
  
 */ 

public without sharing class ARReferralManagementDataMethods {
   public static Boolean SKIP_TRIGGER=false; 
    
   /* set of AR records that need to update Payx and AMP referral records */
   public static Set<Id> arIdSet = new Set<Id>();
   /* AR records we have already processed */
   public static Set<Id> arIdsProcessed = new Set<Id>();
   public static Map<String,Referral__c> updateRefMap = new Map<String,Referral__c>();
   public static Map<String,AR_Referral_Management_Data__c> byRefIdMap = new Map<String,AR_Referral_Management_Data__c>();
   public static Map<String, String> statusTempMap = new Map<String, String>(); 
    
    /* call from ARReferralManagementData trigger */  
    public static void checkTriggerBeforeActions(AR_Referral_Management_Data__c newARupdate) {
      if (!newARupdate.Processed__c) {
         System.debug('***CLM*** checkTriggerBeforeActions newARupdate='+newARupdate);
         if (String.isNotBlank(newARupdate.ReferralID__c)) {
            byRefIdMap.put(newARupdate.ReferralID__c,newARupdate);
         } // if (String.isNotBlank
         // mark all records as processed
         newARupdate.Processed__c=true;
      } // if (!comInfo.Processed__c
   } // checkTriggerBeforeActions
    
   public static void processARUpdates() {
    // to prevent recursion
    SKIP_TRIGGER = true;
    System.debug('***CLM*** processARUpdates byRefIdMap='+byRefIdMap);
    if (!byRefIdMap.isEmpty()) {
         findByRefId();
    }                            
          
   } // processARUpdates
   
 public static void findByRefId() {
      Set<String> querySet = new Set<String>();
      querySet.addAll(byRefIdMap.keySet());
      System.debug('***CLM*** findByRefId querySet='+querySet);

      Referral__c[] refs = [Select Id, Name
                                  ,Amplifinity_Referral__c
                                  ,Amplifinity_Referral__r.amp_dev__Status__c
                                  ,AR_Status__c
                                  ,AMP_Status__c
                                  ,Credit_Date__c
                                  ,Reward_Amount__c
                                  ,Term_End_Date__c
                                  ,Term_Start_Date__c
                                  ,Selling_Opportunity__r.Id
                                  ,ProcessNotes__c
                              From Referral__c
                            Where Id != null
                              and Id in :querySet ];
      //ref.AMP_Status__c = look at custom label to determine based on AR_Status__c value what AMP_Status value should be
      Map<String,String> ampStatusMap = new Map<String,String>();
      Map<String,Boolean> ampAllowUpdatesMap = new Map<String,Boolean>();
      for (Amplifinity_AR_Status_Mapping__mdt statusMapping : [Select MasterLabel, AR_Status__c, AMP_Status__c, Allow_Updates__c from Amplifinity_AR_Status_Mapping__mdt]) {
         ampStatusMap.put(statusMapping.AR_Status__c, statusMapping.AMP_Status__c);
         ampAllowUpdatesMap.put(statusMapping.AR_Status__c, statusMapping.Allow_Updates__c) ;
      }
      system.debug('**CLM*** getAMPStatus ampStatusMap: '+ampStatusMap); 
     
      for (Referral__c ref : refs) {
          AR_Referral_Management_Data__c arData = byRefIdMap.get(ref.Id);
          if (arData == null) {
             String refId2 = ((String)ref.Id).left(15);
             arData = byRefIdMap.get(refId2);
          }
          system.debug('***CLM*** arData: '+arData);
          string shortRefId = Ref.Id;
          shortRefId = shortRefId.left(15);
          //if(ampAllowUpdatesMap.get(ref.Amplifinity_Referral__r.amp_dev__Status__c) == false){
          system.debug('***CLM*** ref.Amplifinity_Referral__c: '+ref.Amplifinity_Referral__c+' ref.AR_Status__c: '+ref.AR_Status__c+' arData.AR_Status__c: '+arData.AR_Status__c);  
          system.debug('***CLM*** ampAllowUpdatesMap.keyset().contains(ref.AR_Status__c): '+ampAllowUpdatesMap.keyset().contains(ref.AR_Status__c)+' ampAllowUpdatesMap.get(ref.AR_Status__c): '+ampAllowUpdatesMap.get(ref.AR_Status__c));  
          if(ref.Amplifinity_Referral__c != null && ref.AR_Status__c != null && 
            ((arData.AR_Status__c != null && ref.AR_Status__c == arData.AR_Status__c) ||
            (ampAllowUpdatesMap.keyset().contains(ref.AR_Status__c) && !ampAllowUpdatesMap.get(ref.AR_Status__c)))){
            system.debug('***CLM*** AR Update did not update Paychex Referral because Status is Unsuccessful or already Processed');
            addToNotes(ref,'AR Update did not update Paychex Referral because Status is already Processed', true);  
                
          } 
          else if(ampStatusMap.containsKey(arData.AR_Status__c)){
                ref.AR_Status__c = arData.AR_Status__c;  
                ref.AMP_Status__c = (ampStatusMap.containsKey(arData.AR_Status__c) ? ampStatusMap.get(arData.AR_Status__c) : '');  
                ref.Credit_Date__c = arData.Credit_Date__c;
                ref.Reward_Amount__c = arData.Reward_Amount__c;
                ref.Term_End_Date__c = arData.Term_End_Date__c;
                ref.Term_Start_Date__c = arData.Term_Start_Date__c;
                addToNotes(ref,'AR Update updated Paychex Referral', true); 
                system.debug('***CLM*** findByRefId after setting values ref: '+ref);
          }
          else{
            addToNotes(ref,'AR Update did not update Paychex Referral because AR Status/AMP Status mapping was not found', true); 
            system.debug('***CLM*** AR Update did not update Paychex Referral because AR Status/AMP Status mapping was not found'+ref);      
          }  
         
      } // for (Referral__c ref : refs
      
      System.debug('***CLM*** findByRefId refs.size: '+refs);
      if (!refs.isEmpty()) {
         //update refs;
         DmlHelper.performDML2(refs, DmlHelper.DML_UPDATE, 'ARReferralManagementDataMethods', 'findByRefId', 'update referrals', true);
         Referral__c[] updatedRefs = [Select Id, Name
                                  ,Amplifinity_Referral__c
                                  ,AR_Status__c   
                                  ,AMP_Status__c
                                  ,Credit_Date__c
                                  ,Reward_Amount__c
                                  ,Term_End_Date__c
                                  ,Term_Start_Date__c
                                  ,Selling_Opportunity__r.Id
                                  ,ProcessNotes__c    
                              From Referral__c
                            Where Id != null
                              and Id in :refs ]; 
          system.debug('**CLM*** findByRefId after DML_UPDATE updatedRefs: '+updatedRefs);   
      }
   } // findByRefId    
   
   public static final Integer PROCESS_NOTES_SIZE = AR_Referral_Management_Data__c.ProcessNotes__c.getDescribe().getLength(); 
    
   public static void addToNotes(Referral__c obj, String notesToAdd, Boolean addTimeStamp) {
      system.debug('***CLM*** inside addToNotes notesToAdd: '+notesToAdd); 
      StringHelper.addNotesToField(obj, 'ProcessNotes__c', PROCESS_NOTES_SIZE, notesToAdd, addTimeStamp);
      system.debug('***CLM*** inside addToNotes after call to StringHelper.addNotesToField');  
   } // addToNotes  
     
}