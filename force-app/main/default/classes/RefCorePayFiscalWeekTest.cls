/** Test for RefCorePayFiscalWeek
 *
 * History
 * -------
 *  08/17/2016 Jacob Hinds      Created
 *
 */
@isTest
private class RefCorePayFiscalWeekTest {

    static testMethod void testFiscalWeek() {
        //Opportunity opp = new Opportunity(Name='Test Oppty',StageName='Demo',CloseDate=system.today());
        //insert opp;
        
        Schema.RecordTypeInfo caseRT= RecordTypeHelper.getRecordType('Service Onboarding Core Payroll Case', 'Case');
        Case ca = new Case(RecordTypeId=caseRT.getRecordTypeId());
        insert ca;
                
        Schema.RecordTypeInfo refRT = RecordTypeHelper.getRecordType('Reference Onboarding Core Payroll', 'Reference_Core_Payroll__c');
        Reference_Core_Payroll__c ref = new Reference_Core_Payroll__c();
        ref.RecordTypeId = refRT.getRecordTypeId();
        ref.Payroll_Run_Date__c = system.today();
        //ref.Opportunity_Lookup__c = opp.Id;
        ref.Case_Lookup__c = ca.Id;
        insert ref;
        
        Period month = [SELECT FiscalYearSettings.Name,PeriodLabel,Number,StartDate,EndDate FROM Period WHERE Type = 'Month' AND StartDate <= TODAY AND EndDate >= TODAY];          
        Integer difference = month.StartDate.daysBetween(system.today());
        Double unRounded = difference/7;
        String week = String.valueOf(Integer.valueOf(math.floor(unRounded)+1));
        
        Reference_Core_Payroll__c newRef = [SELECT Id,X1st_Payroll_Run_Week__c FROM Reference_Core_Payroll__c WHERE Id=:ref.Id]; 
        System.assertEquals(week,newRef.X1st_Payroll_Run_Week__c);
    }
}