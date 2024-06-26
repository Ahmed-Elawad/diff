/** Reference Incoming Fund Trigger Handler class

* History
* -------
03/23/2023 Reetesh Pandey       Created

*/
public without sharing class RIFUpdateCaseHandler {
    public static void updateHandler(Boolean isUpdate,Map<Id,Reference_Incoming_Funds__c> newMap,Map<Id,Reference_Incoming_Funds__c> oldMap,Boolean isAfterTrg,Boolean isBeforeTrg){
        
        If(isUpdate){
            Map<Id,String> caseStepMap = new Map<Id,String>();            
            Map<Id,Id> caseOwnerMap = new Map<Id,Id>();            
            Map<ID,Schema.RecordTypeInfo> rtMap = Reference_Incoming_Funds__c.sObjectType.getDescribe().getRecordTypeInfosById();
            List<Group> HRSQueues = [SELECT Id, Name, DeveloperName, Type FROM Group WHERE Type = 'Queue' AND Name LIKE 'HRS 4S%'];
            List<HRS_4S_Clt_Support_Discrepancy__c> disc = [Select Id,Reference_Incoming_Funds__c, Resolution_Date__c FROM HRS_4S_Clt_Support_Discrepancy__c WHERE Resolution_Date__c = null];
            Id checkRT = RecordTypeHelper.getRecordType('401k Incoming Checks and ACHs','Reference_Incoming_Funds__c').getRecordTypeId();
            Id wireRT = RecordTypeHelper.getRecordType('401k Incoming Wires','Reference_Incoming_Funds__c').getRecordTypeId();
            Id grpId;
            for ( Reference_Incoming_Funds__c newRT: newMap.Values()) {
                if (isUpdate && (newRt.RecordTypeId == checkRT || newRt.RecordTypeId == wireRT)) {
                    Reference_Incoming_Funds__c oldRT = oldMap.get(newRT.id);
                    System.debug('Reference_Incoming_Funds after='+isAfterTrg+' before='+isBeforeTrg+' checking record newRT.Current_Step__c='+newRT.Current_Step__c);
                    //if there is an open discrepancy related record, set current step.
                    if(isBeforeTrg){
                        List<HRS_4S_Clt_Support_Discrepancy__c> discList = new List<HRS_4S_Clt_Support_Discrepancy__c>();
                        for(HRS_4S_Clt_Support_Discrepancy__c d:disc){
                            if(d.Reference_Incoming_Funds__c==newRT.Id){
                                discList.add(d);
                            }
                        }
                        if(discList.size()>0){
                            newRT.Current_Step__c = 'Open Discrepancy';
                        }
                        else if (newRT.Current_Step__c!='Complete'){
                            newRT.Current_Step__c = 'In Process';
                        }
                    }
                    
                    // should be a lookup present and a value in the current step field.
                    if (isAfterTrg && (newRT.Case_Lookup__c != null) && (newRT.Current_Step__c != '')) {                        
                        // if update, only set if there is a value and step field changes 
                        if ((newRt.Current_Step__c != oldRT.Current_Step__c)) {
                            caseStepMap.put(newRT.Case_Lookup__c,newRT.Current_Step__c);
                        }
                    }//current step
                    
                    if (isAfterTrg && newRT.Case_Lookup__c != null && !ReferenceUpdateCase.OWNER_CHANGE_WAS_PROCESSED){
                        //check current record type
                        Boolean checkACH = rtMap.get(newRT.recordTypeID).getName().containsIgnoreCase('401k Incoming Checks and ACHs');
                        Boolean wires = rtMap.get(newRT.recordTypeID).getName().containsIgnoreCase('401k Incoming Wires');
                        
                        //assigns the case and ref object to the user in the CAM Specialist field
                        if (checkACH && newRT.Transmission_Method__c=='ACH 401k' && newRT.ACH_Approved_Date__c != null  && newRT.CAM_Specialist__c != null && 
                            ((newRT.ACH_Approved_Date__c != oldRT.ACH_Approved_Date__c) || (newRT.CAM_Specialist__c != oldRT.CAM_Specialist__c))){
                                caseOwnerMap.put(newRT.Case_Lookup__c,newRT.CAM_Specialist__c);
                                system.debug('assigning to '+newRT.CAM_Specialist__c);
                            }
                        //manual queue HRS 4S LDPS Checks
                        else if (checkACH && newRT.Check_Type__c == 'Misc Check' && newRT.Entered_into_HRIS__c == null  && newRT.RC1_Posted__c != null && 
                                 ((newRT.Check_Type__c != oldRT.Check_Type__c) || (newRT.Entered_into_HRIS__c != oldRT.Entered_into_HRIS__c) || (newRT.RC1_Posted__c != oldRT.RC1_Posted__c))){
                                     for(Group g: HRSQueues){
                                         if(g.Name == 'HRS 4S LDPS Checks'){
                                             caseOwnerMap.put(newRT.Case_Lookup__c,g.Id);
                                             system.debug('assigning to '+g.Name);
                                         }
                                         else{
                                             system.debug('no match');
                                         }
                                     }
                                 }
                        //round robin to HRS 4S CAT ACH
                        else if (checkACH && newRT.ACH_Entered_by_CAM__c != null && newRT.ACH_Type__c=='Need CAT Approval' && ((newRT.ACH_Entered_by_CAM__c != oldRT.ACH_Entered_by_CAM__c) 
                                                                                                                               || (newRT.ACH_Type__c != oldRT.ACH_Type__c))){
                                                                                                                                   for(Group g: HRSQueues){
                                                                                                                                       if(g.Name == 'HRS 4S CAT ACH'){
                                                                                                                                           caseOwnerMap.put(newRT.Case_Lookup__c,g.Id);
                                                                                                                                           system.debug('assigning to '+g.Name);
                                                                                                                                       }
                                                                                                                                       else{
                                                                                                                                           system.debug('no match');
                                                                                                                                       }
                                                                                                                                   }	
                                                                                                                               }
                        //round robin to HRS 4S CAM Rollover Checks (APR0145274)
                        else if(newRT.Contribution_Type__c == 'Rollover' || newRT.Contribution_Type__c == 'Roth Rollover'){
                            for(Group g: HRSQueues){
                                if(g.Name == 'HRS 4S CAM Rollover Checks'){
                                    if ( newRt.Tentative_Trade_Date__c == null && newRT.Ready_for_Trade__c != null  && (newRT.Contribution_Type__c!=oldRT.Contribution_Type__c  || newRT.Ready_for_Trade__c !=oldRT.Ready_for_Trade__c) ) {
                                        caseOwnerMap.put(newRT.Case_Lookup__c,g.Id);
                                        grpId =g.Id;
                                    }                                    
                                    system.debug('assigning to '+g.Name);
                                }
                                else{
                                    system.debug('no match');
                                }
                            }
                            
                        }
                        
                        //round robin to HRS 4S CAM Checks and ACH
                        else if ((newRT.Contribution_Type__c != 'Rollover' || newRT.Contribution_Type__c != 'Roth Rollover') && checkACH && (newRT.Transmission_Method__c=='Chase 401k'||newRT.Transmission_Method__c=='ACH 401k'||newRT.Transmission_Method__c=='Misc 401k')
                                 && newRT.Ready_for_Trade__c!=null && newRT.Contribution_Type__c!=null && newRT.Contribution_Type__c!='Conversion' && newRT.Entry_Type__c==null &&
                                 ((newRT.Transmission_Method__c != oldRT.Transmission_Method__c) || (newRT.Ready_for_Trade__c != oldRT.Ready_for_Trade__c) || (newRT.Contribution_Type__c != oldRT.Contribution_Type__c)
                                  || (newRT.Entry_Type__c != oldRT.Entry_Type__c))){
                                      for(Group g: HRSQueues){
                                          if(g.Name == 'HRS 4S CAM Checks and ACH'){
                                              caseOwnerMap.put(newRT.Case_Lookup__c,g.Id);
                                              system.debug('assigning to '+g.Name);
                                          }
                                          else{
                                              system.debug('no match');
                                          }
                                      }
                                  }
                        
                        //manual queue HRS 4S CAM Trade Import
                        else if ((checkACH && (newRT.Transmission_Method__c=='Chase 401k'||newRT.Transmission_Method__c=='ACH 401k'||newRT.Transmission_Method__c=='Misc 401k')
                                  && newRT.Ready_for_Trade__c!=null && newRT.Contribution_Type__c=='Conversion' && newRT.Entry_Type__c==null &&
                                  ((newRT.Transmission_Method__c != oldRT.Transmission_Method__c) || (newRT.Ready_for_Trade__c != oldRT.Ready_for_Trade__c) || (newRT.Contribution_Type__c != oldRT.Contribution_Type__c)
                                   || (newRT.Entry_Type__c != oldRT.Entry_Type__c))) || wires){
                                       for(Group g: HRSQueues){
                                           if(g.Name == 'HRS 4S CAM Trade Import'){
                                               caseOwnerMap.put(newRT.Case_Lookup__c,g.Id);
                                               system.debug('assigning to '+g.Name);
                                           }
                                           else{
                                               system.debug('no match');
                                           }
                                       }			
                                   }
                        //manual queue HRS 4S LDPS ROE V&R
                        else if (checkACH && (newRT.Check_Type__c=='ROE' || newRT.Check_Type__c=='V&R' || newRT.Check_Type__c=='Other') && newRT.Check_Process_Started__c==null && newRT.RC1_Posted__c != null &&
                                 ((newRT.Check_Type__c != oldRT.Check_Type__c) || (newRT.Check_Process_Started__c != oldRT.Check_Process_Started__c) || (newRT.RC1_Posted__c != oldRT.RC1_Posted__c))){
                                     for(Group g: HRSQueues){
                                         if(g.Name == 'HRS 4S LDPS ROE V&R'){
                                             caseOwnerMap.put(newRT.Case_Lookup__c,g.Id);
                                             system.debug('assigning to '+g.Name);
                                         }
                                         else{
                                             system.debug('no match');
                                         }
                                     }	
                                 }
                        
                        
                    }//Trigger.isBefore
                } // if (Trigger.isUpdat
                
            } // for (Reference_GL__c
            if (!caseStepMap.isEmpty()) {
                ReferenceUpdateCase.updateCaseStep(caseStepMap);
            }
            if (!caseOwnerMap.isEmpty()) {
                system.debug('vvv 5 no match' +caseOwnerMap );               
                ReferenceUpdateCase.updateCaseOwner(caseOwnerMap);                
                reCheckCaseOwner(newMap,caseOwnerMap,grpId);
            }
        }
    }
    //Method to re-Check the owner
    public static void reCheckCaseOwner(Map<Id,Reference_Incoming_Funds__c> newRefMap,Map<Id,Id> caseIdGrpIdMap, Id grpId){
        System.debug('Inside reCheckCaseOwner method');
        Map<Id,Reference_Incoming_Funds__c> csIdRIF = new Map<Id,Reference_Incoming_Funds__c>();
        Map<Id,Id> caseOwnerIdMap = new Map<Id,Id>();        
        Map<Id,Id> csIdgrpIdMap = new Map<Id,Id>();
        for(Id cid: caseIdGrpIdMap.keySet()){
            if(caseIdGrpIdMap.get(cid) == grpId){
                csIdgrpIdMap.put(cid,grpId);
            }            
        }        
        if(csIdgrpIdMap.size()>0 ){
            for(Reference_Incoming_Funds__c rif:newRefMap.Values()){
                csIdRIF.put(rif.Case_Lookup__c,rif);
            }
            for(Case cs:[select id,ownerId,owner.Name from case where id in :csIdgrpIdMap.keySet()]){
                System.debug('ownerId >>> '+cs.OwnerId +'---'+csIdRIF.get(cs.Id).ownerId+'---'+csIdRIF.get(cs.Id).Client_Support_Specialist__c +'---'+csIdRIF.get(cs.Id).Contribution_Type__c +'---'+csIdRIF.get(cs.Id).Ready_for_Trade__c);
                if(cs.ownerId!= null && cs.ownerId == csIdRIF.get(cs.Id).Client_Support_Specialist__c && (csIdRIF.get(cs.Id).Contribution_Type__c == 'Rollover' || csIdRIF.get(cs.Id).Contribution_Type__c == 'Roth Rollover') && csIdRIF.get(cs.Id).Ready_for_Trade__c!= null){
                    caseOwnerIdMap.put(cs.Id, grpId); 
                }               
            }
            if(!caseOwnerIdMap.isEmpty()){
                ReferenceUpdateCase.OWNER_CHANGE_WAS_PROCESSED =false;                
                ReferenceUpdateCase.updateCaseOwner(caseOwnerIdMap);                
            }
        }
        
    }
}