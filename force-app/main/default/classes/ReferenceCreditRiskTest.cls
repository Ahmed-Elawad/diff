/**
 * Test class for ReferenceCreditRiskTest
 * 11/08/2018 Frank Lurz    Created
   09/08/2021 Dan Carmen    Removed all code

 */
@isTest
private with sharing class ReferenceCreditRiskTest {
   static testMethod void testNothing() {
      new ReferenceCreditRisk().handleTrigger(null, null, true, true, true);
   }

}