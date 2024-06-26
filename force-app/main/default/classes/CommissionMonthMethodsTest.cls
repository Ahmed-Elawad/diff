/* Test methods for the CommissionMonthMethods class.
   
  History
  -------
  03/10/2016 Dan Carmen   Created
  
 */
@isTest
private class CommissionMonthMethodsTest {

   @IsTest(SeeAllData=false)
   static void testStatusChange() {
      
      
      CommissionMonth__c commMonth1 = new CommissionMonth__c(Name='March2016',StartDate__c=Date.newInstance(2016,3,1)
                                                     ,EndDate__c=Date.newInstance(2016,3,31), NSSStatus__c='Open');
      insert commMonth1;
      
      commMonth1.NSSStatus__c='Closed';
      update commMonth1;
      
   } // testStatusChange
} // class CommissionMonthMethodsTest