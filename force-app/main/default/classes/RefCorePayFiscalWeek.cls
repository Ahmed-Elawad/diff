/** Called from Before Trigger for Reference Core Payroll object. Updates the 1st Payroll Run Week
 *
 * History
 * -------
 *  08/17/2016 Jacob Hinds      Created
 *
 */
public with sharing class RefCorePayFiscalWeek {
    public class MonthWrapper {
      public Period month;
      public Period[] weeks;
   }
    public static void calculateFiscalWeek(List<Reference_Core_Payroll__c> refs){
        //[SELECT FiscalYearSettings.Name FROM Period WHERE Type = 'Year' AND StartDate <= TODAY AND EndDate >= TODAY].FiscalYearSettings.Name
        List<Reference_Core_Payroll__c> updateRefs = new List<Reference_Core_Payroll__c>();
        String fyName = [SELECT FiscalYearSettings.Name FROM Period WHERE Type = 'Year' AND StartDate <= TODAY AND EndDate >= TODAY].FiscalYearSettings.Name;
        if(fyName != null){
            Period[] months = [SELECT FiscalYearSettings.Name,PeriodLabel,Number,StartDate,EndDate FROM Period WHERE Type = 'Month' AND FiscalYearSettings.Name = :fyName]; 
            if(months != null){
                for(Reference_Core_Payroll__c ref:refs){
                    for(Period month:months){
                        if(ref.Payroll_Run_Date__c >= month.StartDate && ref.Payroll_Run_Date__c <= month.EndDate){
                            Integer difference = month.StartDate.daysBetween(ref.Payroll_Run_Date__c);
                            Double unRounded = difference/7;
                            //ref.X1st_Payroll_Run_Week_Auto__c = (Integer)math.floor(unRounded)+1;
                            ref.X1st_Payroll_Run_Week__c = String.valueOf(Integer.valueOf(math.floor(unRounded)+1));
                        }
                    }
                }
            }
        }
        
    }
}