/* 
 * Test methods for the CaseCreateReference class and trigger.
 *
 * History
 * -------
 * 06/30/2010 Dan Carmen   Created
   02/21/2011 Dan Carmen   Added the Credit Risk object
   09/15/2011 Dan Carmen   Added PEO
   11/14/2011 Carrie Marciano added HRO BeneTrac Integration
   03/27/2012 Carrie Marciano changed HRO NCT to HRO LCT
   07/03/2012 Justin Stouffer Added TAA support Case Id to the TAA Support Reference Object
   01/03/2013 Justin Henderson Added the PEO Existing Client Record Type
   01/16/2013 Justin Stouffer Added the Service Onboarding PEM Case Record Type
   02/26/2013 Frank Lurz  Added Service Onboarding 401k Large Market New Case
   3/20/2013 Josh Cartwright added Reference Payroll Fulfillment and Reference Terms/Transfers
   10/13/2015 Jacob Hinds Removing Platinum Object
   02/01/2017 Lynn Michels Removed Service Onboarding S125 New Case Record Type
   10/26/2018 Dan Carmen   Increment API to version 44
   04/24/2019 Jermaine Stukes	Removed testCaseCreation401kMM
   04/09/2020 Dan Carmen   Remove call to AccountHelper for RecordType
   09/01/2021 Carrie Marciano  Removed the Credit Risk object due to uninstalling Equifax package

 */
@isTest
private class CaseCreateReferenceTest {

    static testMethod void testCaseCreation() {
       // collection of RecordTypes
       String[] sObjectNames = new String[]{'Case'};
       Map<String,Schema.RecordTypeInfo> byName = new Map<String,Schema.RecordTypeInfo>();
       RecordTypeHelper.getRecordTypesMap(sObjectNames, null, byName);
       List<Case> cases = new List<Case>();
       // TAA
       cases.add(createCase(byName.get('Service Onboarding TAA Case2').getRecordTypeId()));
       // HRO
       cases.add(createCase(byName.get('Service Onboarding HRO Case Record Type').getRecordTypeId()));
       cases.add(createCase(byName.get('Service Onboarding EAO Case Record Type').getRecordTypeId()));
       cases.add(createCase(byName.get('Service Onboarding W2 Only Case Record Type').getRecordTypeId()));
       cases.add(createCase(byName.get('Service Additional HRO LCT Contact Record Type').getRecordTypeId()));
       cases.add(createCase(byName.get('Service HRO BeneTrac Integration Record Type').getRecordTypeId()));
       cases.add(createCase(byName.get('Service Onboarding PEM Case Record Type').getRecordTypeId()));
       
        // Payroll Fulfillment
       cases.add(createCase(byName.get('Service Onboarding Payroll Fulfillment').getRecordTypeId()));
        
       //Terminations/ Transfers
       cases.add(createCaseRefTermTran(byName.get('401k/S125 Operations Support').getRecordTypeId(),'401K', 'Termination'));
       cases.add(createCaseRefTermTran(byName.get('401k/S125 Operations Support').getRecordTypeId(),'401K', 'Transfer'));   
       cases.add(createCaseRefTermTran(byName.get('401k/S125 Operations Support').getRecordTypeId(),'S125', 'POP Termination'));  
       cases.add(createCaseRefTermTran(byName.get('401k/S125 Operations Support').getRecordTypeId(),'S125', 'FSA/HSA Termination'));
       cases.add(createCaseRefTermTran(byName.get('401k/S125 Operations Support').getRecordTypeId(),'401K', 'NSF'));  
       cases.add(createCaseRefTermTran(byName.get('401k/S125 Operations Support').getRecordTypeId(),'S125', 'NSF'));  
                       
       // insert all cases
       Test.startTest();
       insert cases;
       Test.stopTest();
       
       // verify TAA reference objects were created
       Reference_TAA__c rTAA1 = [Select Id, Client_Graduated__c, RecordType.Name from Reference_TAA__c where Case_Lookup__c = :cases[0].Id];
       System.assertEquals('Service TAA Onboarding Case Page Layout 3', rTAA1.RecordType.Name);
       
       // verify TAA support Case Id is added to the TAA Support Reference Object when Created
       rTAA1.Client_Graduated__c = TRUE;
       update rTAA1;
       Case ChildCase = [Select Id, ParentID from Case where ParentID = :cases[0].Id];
       System.assertequals(ChildCase.Id,[Select Id, Support_Case_Lookup__c from Reference_TAA__c where
                                            Case_Lookup__c= :cases[0].Id].Support_Case_Lookup__c);
            
       // verify HRO reference objects were created
       Reference_HRO__c rHRO1 = [Select Id, RecordType.Name from Reference_HRO__c where Case_Number__c = :cases[1].Id];
       System.assertEquals('Service Onboarding HRO Ref Object', rHRO1.RecordType.Name);
       Reference_HRO__c rHRO2 = [Select Id, RecordType.Name from Reference_HRO__c where Case_Number__c = :cases[2].Id];
       System.assertEquals('Service Onboarding EAO Ref Object', rHRO2.RecordType.Name);
       Reference_HRO__c rHRO3 = [Select Id, RecordType.Name from Reference_HRO__c where Case_Number__c = :cases[3].Id];
       System.assertEquals('Service Onboarding W2 Only Ref Object', rHRO3.RecordType.Name);
       Reference_HRO__c rHRO4 = [Select Id, RecordType.Name from Reference_HRO__c where Case_Number__c = :cases[4].Id];
       System.assertEquals('Service Additional HRO LCT Contact Ref Object', rHRO4.RecordType.Name);
       Reference_HRO__c rHRO5 = [Select Id, RecordType.Name from Reference_HRO__c where Case_Number__c = :cases[5].Id];
       System.assertEquals('Service HRO BeneTrac Integration Ref Obj', rHRO5.RecordType.Name);
       Reference_HRO__c rHRO6 = [Select Id, RecordType.Name from Reference_HRO__c where Case_Number__c = :cases[6].Id];
       System.assertEquals('Service Onboarding PEM Ref Object', rHRO6.RecordType.Name);

         // verify Payroll Fulfillment reference objects were created
        Reference_Payroll_Fulfillment__c rPayF = [Select Id, RecordType.Name from Reference_Payroll_Fulfillment__c where Case_Number__c = :cases[7].Id];
        System.assertEquals('Payroll Fullfillment', rPayF.RecordType.Name);
        
        // verify Termination/Transfer Object was created
        Reference_Terms_Transfers__c rTerm1 = [Select Id, RecordType.Name from Reference_Terms_Transfers__c where Case_Lookup__c = :cases[8].Id];
        System.assertEquals('401k Termination', rTerm1.RecordType.Name); 
        Reference_Terms_Transfers__c rTerm2 = [Select Id, RecordType.Name from Reference_Terms_Transfers__c where Case_Lookup__c = :cases[9].Id];
        System.assertEquals('401k Transfer', rTerm2.RecordType.Name); 
        Reference_Terms_Transfers__c rTerm3 = [Select Id, RecordType.Name from Reference_Terms_Transfers__c where Case_Lookup__c = :cases[10].Id];
        System.assertEquals('S125 POP Termination', rTerm3.RecordType.Name);        
        Reference_Terms_Transfers__c rTerm4 = [Select Id, RecordType.Name from Reference_Terms_Transfers__c where Case_Lookup__c = :cases[11].Id];
        System.assertEquals('S125 FSA Termination', rTerm4.RecordType.Name);        
        Reference_Terms_Transfers__c rTerm5 = [Select Id, RecordType.Name from Reference_Terms_Transfers__c where Case_Lookup__c = :cases[12].Id];
        System.assertEquals('NSF', rTerm5.RecordType.Name);        
        Reference_Terms_Transfers__c rTerm6 = [Select Id, RecordType.Name from Reference_Terms_Transfers__c where Case_Lookup__c = :cases[13].Id];
        System.assertEquals('NSF', rTerm6.RecordType.Name);    
        
    } // testCaseCreation
        
    static testMethod void testCaseCreation2() {
       // collection of RecordTypes
       String[] sObjectNames = new String[]{'Case'};
       Map<String,Schema.RecordTypeInfo> byName = new Map<String,Schema.RecordTypeInfo>();
       RecordTypeHelper.getRecordTypesMap(sObjectNames, null, byName);

       List<Case> cases = new List<Case>();
       // 401k-S125
       cases.add(createCase(byName.get('Service Onboarding 401k Conversion').getRecordTypeId()));
       cases.add(createCase(byName.get('Service Onboarding 401k New Case').getRecordTypeId()));
       cases.add(createCase(byName.get('Service Onboarding S125 Conversion').getRecordTypeId()));
       cases.add(createCase(byName.get('Service Onboarding 401k Large Market New Case').getRecordTypeId()));
       
       // GL
       cases.add(createCase(byName.get('Service Onboarding GL Case').getRecordTypeId()));
       
       // insert all cases
       Test.startTest();
       insert cases;
       Test.stopTest();
       
       // verify 401k-S125 reference objects were created
       Reference_401k_S125__c r4011 = [Select Id, RecordType.Name from Reference_401k_S125__c where Case_Lookup__c = :cases[0].Id];
       System.assertEquals('Service Onboarding 401k Conversions', r4011.RecordType.Name);
       Reference_401k_S125__c r4012 = [Select Id, RecordType.Name from Reference_401k_S125__c where Case_Lookup__c = :cases[1].Id];
       System.assertEquals('Service Onboarding 401k New Case', r4012.RecordType.Name);
       Reference_401k_S125__c r4014 = [Select Id, RecordType.Name from Reference_401k_S125__c where Case_Lookup__c = :cases[2].Id];
       System.assertEquals('Service Onboarding S125 Conversions', r4014.RecordType.Name);
       Reference_401k_S125__c r4015 = [Select Id, RecordType.Name from Reference_401k_S125__c where Case_Lookup__c = :cases[3].Id];
       System.assertEquals('Service Onboarding 401k Large Market New Case', r4015.RecordType.Name);

       // verify GL reference objects were created
       Reference_GL__c rGL1 = [Select Id, RecordType.Name from Reference_GL__c where Case_Lookup__c = :cases[4].Id];
       System.assertEquals('GL Onboarding Record Type', rGL1.RecordType.Name);
    } // testCaseCreation2
        
    static testMethod void testCaseCreationCltRltn() {
       testCreateRef('Service Support Corporate Concerns','Client Relations Support Record Type','Reference_Client_Relations__c','Case_Lookup__c');
    } // testCaseCreationCltRltn
        
    static testMethod void testCaseCreationPEO() {
       testCreateRef('Service Onboarding PEO New Business','PEO New Business Onboarding','Reference_PEO__c','Parent_Case__c');
    } // testCaseCreationPEO

    static testMethod void testCaseCreationPEO2() {
       testCreateRef('Service Onboarding PEO Existing Clients','PEO Existing Client Onboarding','Reference_PEO__c','Parent_Case__c');
    } // testCaseCreationPEO
      
    static testMethod void testCaseCreationCore() {
       testCreateRef('Service Onboarding Core Payroll Case','Reference Onboarding Core Payroll','Reference_Core_Payroll__c','Case_Lookup__c');
    } // testCaseCreationPEO
      
    private static void testCreateRef(String caseRTName, String refRTName, String refObjectName, String refCaseField) {
       System.debug('testCreateRef caseRTName='+caseRTName+' refRTName='+refRTName+' refObjectName='+refObjectName+' refCaseField='+refCaseField);
       // get the record type
       Schema.RecordTypeInfo rt = RecordTypeHelper.getRecordType(caseRTName, 'Case');
       Case c = createCase(rt.getRecordTypeId());
       
       // insert case
       Test.startTest();
       insert c;
       Test.stopTest();
       
       String query = 'Select Id, RecordTypeId from '+refObjectName+' where '+refCaseField+'=\''+c.Id+'\'';
       SObject so = Database.query(query);

       Schema.RecordTypeInfo refRt = RecordTypeHelper.getRecordType(refRTName, refObjectName);
       
       System.assertEquals(refRt.getRecordTypeId(),so.get('RecordTypeId'));
    } // testCreateRef
    
    private static Case createCase(Id recordTypeId) {
       Case c = new Case(RecordTypeId=recordTypeId);
       return c;
    } // createCase
    
    private static Case createCaseRefTermTran(Id recordTypeId, String Product, String TermTransType) {
       Case c = new Case(RecordTypeId=recordTypeId, Product__c=Product, Termination_Transfer_Type__c=TermTransType);
       return c;
    } // createCase
    
} // class CaseCreateReferenceTest