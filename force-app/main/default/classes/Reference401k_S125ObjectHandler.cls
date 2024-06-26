/* History
  -------
  04/20/2023   Lalan Kumar   Created  
*/
public class Reference401k_S125ObjectHandler {
    
    /* Below method is to handle trigger context */
    public static void handleTrigger(Map<Id,Reference_401k_S125__c> newRefMap,Map<Id,Reference_401k_S125__c> oldRefMap){
       /*** Specifies all the actions than should be run for afterInsert ***/ 
        if(trigger.isInsert){
            
       }
        /*** Specifies all the actions that should be run for afterUpdate ***/
        if(trigger.isUpdate){
           new401kCTTcaseCreate(newRefMap,oldRefMap); 
            
       }
    }//handleTrigger -End
    
    /* Below method created as part of APR0147498- 401k - Create New Ref Ops - CTT New Case*/
    public static void new401kCTTcaseCreate(Map <Id,Reference_401k_S125__c> newMap ,Map <Id,Reference_401k_S125__c> oldMap){
      String getSerOnboard401kRecordType = Schema.SObjectType.Reference_401k_S125__c.getRecordTypeInfosByName().get('Service Onboarding 401k New Case').getRecordTypeId();
      String get401kCTTNewCaseRecordType = Schema.SObjectType.Reference_401k_S125__c.getRecordTypeInfosByName().get('401k CTT New Case').getRecordTypeId();
      List<Reference_401k_S125__c> refCTTList = new List<Reference_401k_S125__c>();
        for(Reference_401k_S125__c ref:newMap.values()){
            if(ref.RecordTypeId == getSerOnboard401kRecordType && (oldMap.get(ref.id).CTT_New_Case__c!=ref.CTT_New_Case__c && ref.CTT_New_Case__c)){
             Reference_401k_S125__c refCTT = new Reference_401k_S125__c();
                /*Case Detail Mapping- Start*/
                refCTT.Case_Lookup__c = ref.Case_Lookup__c;
                refCTT.RecordTypeId = get401kCTTNewCaseRecordType;
                refCTT.ECT_Master_ID__c = ref.ECT_Master_ID__c;
                refCTT.Sungard_Number__c = ref.Sungard_Number__c;
                refCTT.ASO__c = ref.ASO__c;
                refCTT.ASO_Type__c = ref.ASO_Type__c;
                refCTT.Plan_Contact__c = ref.Plan_Contact__c;
                refCTT.Contact_Email__c = ref.Contact_Email__c;
                /*Case Detail Mapping- End*/
                /*Internal Partners Mapping - Start*/
                refCTT.Conv_Set_Up_Rep__c = ref.Conv_Set_Up_Rep__c;
                refCTT.FSM__c = ref.FSM__c;
                refCTT.Sales_Rep_Lookup__c = ref.Sales_Rep_Lookup__c;
                refCTT.Financial_Advisor__c = ref.Financial_Advisor__c;
                refCTT.Financial_Advisor_Email_Address__c = ref.Financial_Advisor_Email_Address__c;
                /*Internal Partners Mapping - End*/
                /*Plan Details Mapping - Start*/
                refCTT.Computation_Frequency__c ='Annual';
                refCTT.Plan_Effective_Date__c = ref.Plan_Effective_Date__c;
                refCTT.Original_Run_Date__c = ref.Original_Run_Date__c;
                refCTT.Run_Date__c = ref.Run_Date__c;
                refCTT.First_Check_Date__c = ref.First_Check_Date__c;
                refCTT.Payroll_Frequency__c = ref.Payroll_Frequency__c;
                refCTT.NTP__c = ref.NTP__c;
                refCTT.Owner_Only__c = ref.Owner_Only__c;
                refCTT.Micro_65_90__c = ref.Micro_65_90__c;
                refCTT.Advantage__c = ref.Advantage__c;
                refCTT.Roth__c = ref.Roth__c;
                refCTT.Managed_Account__c = ref.Managed_Account__c;
                refCTT.Auto_Enroll__c = ref.Auto_Enroll__c;
                refCTT.Safe_Harbor__c = ref.Safe_Harbor__c;
                /*Plan Details Mapping - End*/
                /*Enrollment Mapping - Start*/
               
                /*Enrollment Mapping - End*/
                
                refCTTList.add(refCTT);
            }

            
        }
        System.debug('refCTTList-->'+refCTTList);
        if(refCTTList.size()>0){
        DmlHelper.performDML(refCTTList, DmlHelper.DML_INSERT, 'reference401k/S125ObjectHandler', 'new401kCTTcaseCreate', 'insert 401k CTT New Case', false);
        }
    } //new401kCTTcaseCreate Method End

} //Class End