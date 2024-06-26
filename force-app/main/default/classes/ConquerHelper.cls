/* 
   Methods for working with Conquer

   
  History
  -------
  10/31/2023 Dan Carmen        Removed direct query to RecordType object
  13/11/2023 Lalan Kumar       APR0144852: Conquer Cadence should remove contacts from cadence when an opportunity is created by SMB Virtual New Business

*/
public class ConquerHelper implements TriggerInterfaceC {
    
    /*APR0144852: Added custom label as Label.Core_Opportunity_Record_Type and Label.Core_Virtual_Sales in opptyRTs */ 
    public static final set<string> opptyRTs = new set<String>{Label.MMS_Opportunity_Record_Type,Label.ASO_Opportunity_Record_Type, Label.ASO_Opportunity_FSS_Record_Type, Label.PAY_Opportunity_Record_Type, Label.PAY_Opportunity_DSA_Record_Type, Label.MMS_Opportunity_DSA_Record_Type, Label.Core_Opportunity_Record_Type,Label.Core_Virtual_Sales};
    public static String CLASSNAME='ConquerHelper'; // local class name
    
    public void handleTrigger(SObject[] recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter, Boolean isDelete) {
        System.debug(
            'ConquerHelper.handleTrigger recs=' +
            (recs != null ? recs.size() : -1) +
            ' isBefore=' + isBefore +
            ' isAfter=' + isAfter +
            ' isDelete=' + isDelete + 
            ' Trigger.old='+(Trigger.old != null ? Trigger.old.size() : -1)
        );
        
        // exit execution if the trigger has already run this logic
        if (TriggerMethods.didTriggerRun(CLASSNAME,recs,oldMap,isBefore,isAfter,isDelete)) {
            System.debug('handleTrigger trigger ran');
            return;
        }
        
        // determine obj type that is being processed in this trigger execution
        SObjectType objType = TriggerMethods.objType;
        
        // handle after triggers
        if (isAfter) {
            // process Opps that were just inserted
            if (objType == Opportunity.sObjectType && Trigger.isInsert) {
                set<id> mmsOpportunityIds = new Set<Id>();
                // Get Id for MMS Opportunity record type
                //ID rtId = [SELECT ID FROM RECORDTYPE WHERE NAME = :RT_OPPTY_MMS LIMIT 1].ID;
                Map <Id,Schema.RecordTypeInfo> rtMap = Opportunity.sObjectType.getDescribe().getRecordTypeInfosById();

                // loop thru new opps
                for(opportunity o :(List<opportunity>)recs) {
                    // collect mms opps
                    Schema.RecordTypeInfo rtInfo = (o.RecordTypeId != null ? rtMap.get(o.RecordTypeId) : null);
                    if (rtInfo != null && opptyRTs.contains(rtInfo.getName())) {
                        mmsOpportunityIds.add(o.Id);
                    }
                }
                if (!mmsOpportunityIds.isEmpty()) {
                    DS_Packages.AssociateContactDataToOpp.Configuration config = new DS_Packages.AssociateContactDataToOpp.Configuration();
                    config.processMatchingCadenceData();
                    config.setDaysInactive(90);
                    DS_Packages.AssociateContactDataToOpp service = new DS_Packages.AssociateContactDataToOpp(mmsOpportunityIds,config);
                    if (System.isQueueable()){
                        service.run();
                    } else {
                        System.enqueueJob(new DS_Packages.AssociateContactDataToOpp.RunAsync(service));
                    }
                }
            }
        }
    } // handleTrigger
    
} // ConquerHelper