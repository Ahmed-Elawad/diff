/* Class for Reference PEO Medical UW Object
*
*   HISTORY
*  ---------
*   02/21/2018  Jacob Hinds     Created
*   11/05/2018  Jermaine Stukes Added method to calculate agency response in hours Case#30688906
*   12/11/2018  Carrie Marciano Removed +' Hours' from Agency_Response_Time__c field per Case#31080482
*   06/05/2019  Carrie Marciano Added Reference PEO UW field PEO Group Type and checked to see if record is locked before updating Reference PEO 
*   04/20/2020  Manmeet Vaseer SFDC-3072, Increased Response Target Timeframe from 9 to 24 hours. Added more values to UW SLA picklist based on 24 hours business day.
*
*/
public with sharing class ReferencePEOMedicalUWMethods {
    /* This works but is not bulkified, called within a loop from the trigger
    public static void checkForExistingPEOUW(Reference_PEO_Medical_UW__c peoUW){
        Opportunity[] opptyList = [SELECT ID,(SELECT ID,Opportunity__c FROM Reference_PEO_Medical_UWs__r) FROM Opportunity WHERE ID=:peoUW.Opportunity__c];
        for(Opportunity oppty:opptyList){
            if(!oppty.Reference_PEO_Medical_UWs__r.isEmpty()){
                peoUW.addError('A Reference PEO UW Record Already Exists.  If you believe you have received this message in error, please contact AskIT');
            }
        }
    }*/
    //can only create one peo uw record per opportunity
    public static void checkForExistingPEOUW(Reference_PEO_Medical_UW__c[] peoUWs){
        Id[] opptyIds = new Id[]{};
        for(Reference_PEO_Medical_UW__c peoUW: peoUWs){
            if(peoUW.Opportunity__c!=null){
                opptyIds.add(peoUW.Opportunity__c);
            }
        }
        Map<Id,Opportunity> opptyMap = new Map<Id,Opportunity>([SELECT ID,(SELECT ID,Opportunity__c FROM Reference_PEO_Medical_UWs__r) FROM Opportunity WHERE ID in:opptyIds]);
        for(Reference_PEO_Medical_UW__c peoUW:peoUWs){
            Opportunity oppty = opptyMap.get(peoUW.Opportunity__c);
            if(oppty!=null && !oppty.Reference_PEO_Medical_UWs__r.isEmpty()){
                peoUW.addError('A Reference PEO UW record already exists on the related opportunity.  If you believe you have received this message in error, please contact AskIT');
            }
        }
    }
    //calculate sla field
    public static Id busHours;
    public static void processResponseTargetSLA(Reference_PEO_Medical_UW__c [] responseTargetSLA){
        if(busHours==null){
            busHours = CalculateDateFields.getBusinessHoursId24();
        }
        for(Reference_PEO_Medical_UW__c peoUW:responseTargetSLA){
            System.debug('processResponseTargetSLA, busHours: ' + busHours + ', Date_Submitted__c: ' + peoUW.Date_Submitted__c);
            /* the response time should be 24 hours from the Date Submitted 
             * The business hours are used to determine Rep/company working hours. 
             * If the business hours is set to 8 hours and the respose time is 24 hours then it will take 24/8=3 business days to respond.
             * Similarly, if the business hours is set to 24 hours and the respose time is 24 hours then it will take 24/24=1 business day to respond.
			*/
            peoUW.Response_Target_Timeframe__c = CalculateBusinessHours.addHours(peoUW.Date_Submitted__c,24,busHours);
        }
        
    }
    //calculate sla field
    public static void processApprovalTimeframeSLA(Reference_PEO_Medical_UW__c [] approvalTimeframeSLA){
        Pattern isNumbers = Pattern.Compile('(^[0-9][0-9][0-9]?).*');
        
        if(busHours==null){
            busHours = CalculateDateFields.getBusinessHoursId24();
        }
        for(Reference_PEO_Medical_UW__c peoUW:approvalTimeframeSLA){
            Matcher businessHoursMatcher = isNumbers.matcher(peoUW.UW_SLA__c);            
            if(businessHoursMatcher.Matches()){
                System.debug('processApprovalTimeframeSLA, businessHoursMatcher: ' + businessHoursMatcher.group(1));
                Integer sla = Integer.valueOf(businessHoursMatcher.group(1));                
                
                DateTime dueDate = BusinessHours.add(busHours, peoUW.Deal_100_Complete__c, (((sla * 60) * 60) * 1000));
                Long diff = BusinessHours.diff(busHours, peoUW.Deal_100_Complete__c, peoUW.Approval_Date__c); 
                diff = (((diff/1000)/60)/60);
                peoUW.Approval_Due__c = dueDate;
                system.debug('processApprovalTimeframeSLA sla: '+sla+' dueDate: '+string.valueOf(dueDate)+' diff: '+diff);
                peoUW.Approval_Timeframe__c = (dueDate > peoUW.Approval_Date__c ? 'Inside SLA':'Outside SLA');
            }
        }
    }
    
    public static void agencyResponseHours(Reference_PEO_Medical_UW__c [] approvalTimeframeSLA){
        if(busHours==null){
            busHours = CalculateDateFields.getBusinessHoursId24();
        }
        for(Reference_PEO_Medical_UW__c peoUW:approvalTimeframeSLA){
            Long diff = BusinessHours.diff(busHours, peoUW.Date_Submitted_to_Agency__c, peoUW.Date_Response_from_Agency__c); 
            diff = (((diff/1000)/60)/60);
            peoUW.Agency_Response_Time__c = String.valueOf(diff);
        }
    }
    public static Map<Id,Id> peoUWIdByOppIdMap;
    //when ref peo is created, link up with reference peo UW and grab fields already filled on that record to update ref peo.  Called from ReferencePEOUpdate.trigger
    public static void handleRefPEOs(Reference_PEO__c[] refPEOs){
        system.debug('referencePEOMedicalUWMethods in handle peo');
        Id[] oppIds = new Id[]{};
        //Reference_PEO_Medical_UW__c[] peoUWtoUpdate = new Reference_PEO_Medical_UW__c[]{};
        
        for(Reference_PEO__c peo: refPEOs){
            oppIds.add(peo.Opportunity__c);
        }
        system.debug('referencePEOMedicalUWMethods oppIds'+oppIds);
        Map<Id,Reference_PEO_Medical_UW__c> peoUWByOppId = new Map<Id,Reference_PEO_Medical_UW__c>();
        if(!oppIds.isEmpty()){
            Reference_PEO_Medical_UW__c[] peoUWs = [SELECT Id,Opportunity__c,PEO_Carrier_Location__c,Approval_Date__c,Approval_Reason__c,Underwriter__c,Record_is_locked__c,
                        Kaiser_Band_if_dual_quote__c,Approved_Rate_Band_UW__c,FE_Completed_Date__c,Banding_Status__c,Special_Medical_Exceptions__c,PEO_Group_Type__c,EPO_HMO_ACO_Approved_Rate_Band__c
                        FROM Reference_PEO_Medical_UW__c WHERE Opportunity__c in:oppIds];
            if(peoUWs!=null && !peoUWs.isEmpty()){
                for(Reference_PEO_Medical_UW__c peoUW : peoUWs){
                    peoUWByOppId.put(peoUW.Opportunity__c,peoUW);
                }
            }
        }
        system.debug('referencePEOMedicalUWMethods peoUWOppId'+peoUWByOppId);
        peoUWIdByOppIdMap = new Map<Id,Id>();
        //map fields from uw->peo
        for(Reference_PEO__c peo: refPEOs){
            Reference_PEO_Medical_UW__c peoUW = peoUWByOppId.get(peo.Opportunity__c);
            if(peoUW!=null && peoUW.Record_is_locked__c != true){
                peoUWIdByOppIdMap.put(peoUW.Opportunity__c,peoUW.Id);
                //this stuff gets populated when uw is basically done with their work
                if(peoUW.FE_Completed_Date__c != null && peoUW.Banding_Status__c != 'Final Enrollment-Decline'){
                    peo.Final_Rate_Band__c = Decimal.valueOf(peoUW.Approved_Rate_Band_UW__c);
                    peo.Final_Approval_Date__c = peoUW.FE_Completed_Date__c;
                    peo.Final_Medical_Approval_2__c = 'Approved';
                }
                if(peoUW.Approved_Rate_Band_UW__c!=null){
                    peo.Initial_Rate_Band__c = Decimal.valueOf(peoUW.Approved_Rate_Band_UW__c);
                }
                if(peoUW.Approved_Rate_Band_UW__c!=null){
                    peo.Initial_Approval_Date__c = Date.valueOf(peoUW.Approval_Date__c);
                }
                if(peoUW.Special_Medical_Exceptions__c!=null){
                    peo.Medical_Notes__c = peoUW.Special_Medical_Exceptions__c.left(250);
                }
                if(peoUW.Kaiser_Band_if_dual_quote__c!=null){
                    peo.Kaiser_Rate_Band_if_applic__c = peoUW.Kaiser_Band_if_dual_quote__c;
                }
                if(peoUW.PEO_Carrier_Location__c!=null){
                    peo.Medical_Carrier__c = peoUW.PEO_Carrier_Location__c;
                }
                if(peoUW.Underwriter__c!=null){
                    peo.Initial_Medical_UW__c = peoUW.Underwriter__c;
                }
                if(peoUW.PEO_Group_Type__c!=null && peoUW.PEO_Group_Type__c.contains('Virgin')){
                    peo.Virgin_Group__c = True;
                }
                if(peoUW.Approval_Reason__c!=null && peoUW.Approval_Reason__c.contains('Approved')){
                    peo.Initial_Medical_UW_Approval__c = 'Approved';
                }
                else if(peoUW.Approval_Reason__c!=null && peoUW.Approval_Reason__c.contains('Declined')){
                    peo.Initial_Medical_UW_Approval__c = 'Approved to Self-Retain';
                }                
                if(peoUW.EPO_HMO_ACO_Approved_Rate_Band__c != null){
                    peo.EPO_HMO_ACO_Rate_Band__c = peoUW.EPO_HMO_ACO_Approved_Rate_Band__c;
                }                
            }//if peoUW!=null
            system.debug('referencePEOMedicalUWMethods peo:'+peo+' map: '+peoUWIdByOppIdMap);
        }
        //call method to populate the peo lookup field on uw record
        /*if(!peoUWIdByOppIdMap.isEmpty()){
            if (Test.isRunningTest() || System.isBatch() || System.isFuture()) {
                processPEOUWLinkNow(peoUWIdByOppIdMap);
            } else {
                processPEOUWLinkFuture(peoUWIdByOppIdMap);
            }
        }*/
   }
   public static void processPEOUWLink(){
        if(!peoUWIdByOppIdMap.isEmpty()){
            if (Test.isRunningTest() || System.isBatch() || System.isFuture()) {
                processPEOUWLinkNow(peoUWIdByOppIdMap);
            } else {
                processPEOUWLinkFuture(peoUWIdByOppIdMap);
            }
        }
   }
   
   //call future method to update lookup field on UW record with created peo record
   @future
   public static void processPEOUWLinkFuture(Map<Id,Id> peoUWIdByOppIdMap) {
        processPEOUWLinkNow(peoUWIdByOppIdMap);
   }
   //populate the peo lookup field on uw record
   public static void processPEOUWLinkNow(Map<Id,Id> peoUWIdByOppIdMap) {
        Reference_PEO_Medical_UW__c[] peoUWtoUpdate = new Reference_PEO_Medical_UW__c[]{};
        Map<Id,Id> peoIdByOpptyIdMap = new Map<Id,Id>();
        Reference_PEO__c[] peos = [SELECT Id,CreatedDate,Opportunity__c FROM Reference_PEO__c WHERE Opportunity__c in:peoUWIdByOppIdMap.keySet() ORDER BY CreatedDate DESC];
        for(Reference_PEO__c peo:peos){
            if(!peoIdByOpptyIdMap.containsKey(peo.Opportunity__c)){
                peoIdByOpptyIdMap.put(peo.Opportunity__c,peo.Id);
            }   
        }
        Reference_PEO_Medical_UW__c[] peoUWs = [SELECT Id,Ref_PEO__c,Opportunity__c FROM Reference_PEO_Medical_UW__c WHERE Id in :peoUWIdByOppIdMap.values()];
        for(Reference_PEO_Medical_UW__c peoUW : peoUWs){
            if(peoIdByOpptyIdMap.containsKey(peoUW.Opportunity__c)){
                peoUw.Ref_PEO__c = peoIdByOpptyIdMap.get(peoUW.Opportunity__c);
                peoUWtoUpdate.add(peoUW);
            }
        }
        system.debug('referencePEOMedicalUWMethods processPEOUWLinkNow:'+peoUWtoUpdate);
        if(!peoUWtoUpdate.isEmpty()){
            DMLHelper.performDML2(peoUWtoUpdate,'Update','ReferencePEOMedicalUWMethods','processPEOUWLinkNow','updating PEO lookup on UWs',true);
            peoUWIdByOppIdMap.clear();
        }
   } // processAfterTrigger
}