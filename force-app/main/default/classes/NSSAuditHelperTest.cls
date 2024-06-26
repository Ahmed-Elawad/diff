/* Test methods for the NSSAuditHelper class.
   
  History
  -------
  02/25/2014 Dan Carmen     Created
  09/18/2014 Dan Carmen     Added logic to set the NSR (contact) field
  03/09/2016 Dan Carmen     Add ability to link to the Commission Month object
  
 */
@isTest
private class NSSAuditHelperTest {

   public static final String PROD_401='401K';
   public static final String PROD_MMS='MMS';
   public static final String PROD_CORE='Core';

   static testMethod void testGetNssAuditListMap() {
      Account acct1 = new Account(Name='Account1');
      Account acct2 = new Account(Name='Account2');
      Account acct3 = new Account(Name='Account3');
      Account[] accts = new Account[]{acct1,acct2,acct3};
      insert accts;
      
      Opportunity opp1 = new Opportunity(AccountId=acct1.Id, Name='Opp1', StageName='Pending', CloseDate=Date.today());
      Opportunity opp2 = new Opportunity(AccountId=acct2.Id, Name='Opp2', StageName='Pending', CloseDate=Date.today());
      Opportunity opp3 = new Opportunity(AccountId=acct3.Id, Name='Opp3', StageName='Pending', CloseDate=Date.today());
      Opportunity[] opps = new Opportunity[]{opp1,opp2,opp3};
      insert opps;
      
      Prospect_Ownership__c po1 = new Prospect_Ownership__c(Prospect_Client__c=acct1.Id, Opportunity__c=opp1.Id, Ownership_Status__c='Lockout',StartDate__c=Date.today());
      Prospect_Ownership__c po2 = new Prospect_Ownership__c(Prospect_Client__c=acct2.Id, Opportunity__c=opp2.Id, Ownership_Status__c='Lockout',StartDate__c=Date.today());
      Prospect_Ownership__c po3 = new Prospect_Ownership__c(Prospect_Client__c=acct3.Id, Opportunity__c=opp3.Id, Ownership_Status__c='Lockout',StartDate__c=Date.today());
      Prospect_Ownership__c[] pos = new Prospect_Ownership__c[]{po1,po2,po3};
      insert pos;
      
      NSSAudit__c audit1 = new NSSAudit__c(Account__c=acct1.Id, Opportunity__c=opp1.Id, Prospect_Ownership__c=po1.Id);
      NSSAudit__c audit2 = new NSSAudit__c(Account__c=acct2.Id, Opportunity__c=opp2.Id, Prospect_Ownership__c=po2.Id);
      NSSAudit__c audit3 = new NSSAudit__c(Account__c=acct3.Id, Opportunity__c=opp3.Id, Prospect_Ownership__c=po3.Id);
      NSSAudit__c[] audits = new NSSAudit__c[]{audit1,audit2,audit3};
      insert audits;
      
      Map<Id,List<NSSAudit__c>> auditListMap = NSSAuditHelper.getNssAuditListMap(null, null, new Set<Id>{UserInfo.getUserId()}, true);
      System.assertEquals(1,auditListMap.size());
      System.assertEquals(3,auditListMap.get(UserInfo.getUserId()).size());
      
      Set<Id> acctIdSet = new Set<Id>{acct1.Id, acct2.Id, acct3.Id};
      auditListMap = NSSAuditHelper.getNssAuditListMap(acctIdSet, null, null, true);
      System.assertEquals(3,auditListMap.size());
      
      List<Id> oppIdList = new List<Id>{opp1.Id, opp2.Id, opp3.Id};
      auditListMap = NSSAuditHelper.getNssAuditListMap(null, oppIdList, null, true);
      System.assertEquals(3,auditListMap.size());

      auditListMap = NSSAuditHelper.getNssAuditListMap(null, null, null, true);
      System.assertEquals(0,auditListMap.size());

   } // testGetNssAuditListMap
   
   public static ProductGroupMapping__c[] setupProductGroupMapping() {
      ProductGroupMapping__c[] mapping = new ProductGroupMapping__c[]{};
      String prefixName = NSSAuditHelper.AUDIT_MAPPING_TYPE+'-'+ProspectOwnershipMethods.NSS_OUTBOUND;
      mapping.add(new ProductGroupMapping__c(Name=prefixName+UserHelper.SO_401+PROD_401
                                            ,NSS_Source__c=ProspectOwnershipMethods.NSS_OUTBOUND
                                            ,NSS_Team__c=UserHelper.SO_401
                                            ,MappingType__c=NSSAuditHelper.AUDIT_MAPPING_TYPE
                                            ,Product_of_Interest__c=PROD_401
                                            ,Revenue__c=100, Units__c=1
                                            ,RecordTypeName__c=OpportunityCreateCase.RT_OPPTY_401K
                                            ,RecordTypeName2__c=OpportunityCreateCase.RT_OPPTY_401K_FSS));
      mapping.add(new ProductGroupMapping__c(Name=prefixName+UserHelper.SO_401+PROD_MMS
                                            ,NSS_Source__c=ProspectOwnershipMethods.NSS_OUTBOUND
                                            ,NSS_Team__c=UserHelper.SO_401
                                            ,MappingType__c=NSSAuditHelper.AUDIT_MAPPING_TYPE
                                            ,Product_of_Interest__c=PROD_MMS
                                            ,Revenue__c=200, Units__c=2
                                            ,RecordTypeName__c=OpportunityCreateCase.RT_OPPTY_MMS
                                            ,RecordTypeName2__c=OpportunityCreateCase.RT_OPPTY_MMS_DSA));
      mapping.add(new ProductGroupMapping__c(Name=prefixName+PROD_CORE
                                            ,NSS_Source__c=ProspectOwnershipMethods.NSS_OUTBOUND
                                            ,NSS_Team__c=null
                                            ,MappingType__c=NSSAuditHelper.AUDIT_MAPPING_TYPE
                                            ,Product_of_Interest__c=PROD_CORE
                                            ,Revenue__c=300, Units__c=3
                                            ,RecordTypeName__c=OpportunityCreateCase.RT_OPPTY_CORE
                                            ,RecordTypeName2__c=OpportunityCreateCase.RT_OPPTY_CORE_DSA));
      insert mapping;
      // verify the mapping
      for (ProductGroupMapping__c pgm : ProductGroupMapping__c.getAll().values()) {
         System.debug('setupProductGroupMapping name='+pgm.Name);
      }
      return mapping;
   } // setupProductGroupMapping
   
   static testMethod void testGetDefaultAuditProd() {
      setupProductGroupMapping();
      System.assertEquals(PROD_401,NSSAuditHelper.getDefaultAuditProduct(OpportunityCreateCase.RT_OPPTY_401K_FSS));
      System.assertEquals(PROD_MMS,NSSAuditHelper.getDefaultAuditProduct(OpportunityCreateCase.RT_OPPTY_MMS));
      System.assertEquals(PROD_CORE,NSSAuditHelper.getDefaultAuditProduct(OpportunityCreateCase.RT_OPPTY_CORE_DSA));
      System.assertEquals(null,NSSAuditHelper.getDefaultAuditProduct('Bad Record Type Name'));
   } // testGetDefaultAuditProd
   
   static testMethod void testHandleProduct() {
   	setupProductGroupMapping();
      NSSAudit__c audit1 = new NSSAudit__c(NSS_Source__c=ProspectOwnershipMethods.NSS_OUTBOUND
                                          ,NSS_Team__c=UserHelper.SO_401
                                          ,Product__c=PROD_401);
      NSSAudit__c audit2 = new NSSAudit__c(NSS_Source__c=ProspectOwnershipMethods.NSS_OUTBOUND
                                          ,NSS_Team__c=UserHelper.SO_401
                                          ,Product__c=PROD_MMS);
      NSSAudit__c audit3 = new NSSAudit__c(NSS_Source__c=ProspectOwnershipMethods.NSS_OUTBOUND
                                          ,NSS_Team__c=UserHelper.SO_401
                                          ,Product__c=PROD_CORE);
      NSSAudit__c audit4 = new NSSAudit__c(NSS_Source__c=ProspectOwnershipMethods.NSS_OUTBOUND
                                          ,NSS_Team__c=UserHelper.SO_401
                                          ,Product__c='UnknownProd');
      NSSAudit__c[] audits = new NSSAudit__c[]{audit1,audit2,audit3,audit4};
      insert audits;
      
      audit1 = [Select Id, Revenue__c, Units__c from NSSAudit__c where Id=:audit1.Id];
      //System.assertEquals(100,audit1.Revenue__c);
      //System.assertEquals(1,audit1.Units__c);
      
      audit2 = [Select Id, Revenue__c, Units__c from NSSAudit__c where Id=:audit2.Id];
      System.assertEquals(200,audit2.Revenue__c);
      System.assertEquals(2,audit2.Units__c);
      
      audit3 = [Select Id, Revenue__c, Units__c from NSSAudit__c where Id=:audit3.Id];
      System.assertEquals(300,audit3.Revenue__c);
      System.assertEquals(3,audit3.Units__c);
      
      audit4 = [Select Id, Revenue__c, Units__c from NSSAudit__c where Id=:audit4.Id];
      System.assertEquals(null,audit4.Revenue__c);
      System.assertEquals(null,audit4.Units__c);
      
      
   } // testHandleProduct
   
   static testMethod void testHandleNSRContacts() {
   	// find a random user
   	User usr = [Select Id, FirstName, LastName, HR_Person_Id__c from User where IsActive=true and HR_Person_Id__c != null and Profile.Name like 'NSS%' limit 1];
   	
      // set up a contact record for a user
      Account acct = new Account(Name=UserHelper.PAYCHEX_COMP);
      insert acct;
      Contact ctct = new Contact(AccountId=acct.Id, FirstName=usr.FirstName, LastName=usr.LastName, HR_Person_Id__c=usr.HR_Person_Id__c);
      insert ctct;
      
      // create an nss audit record
      NSSAudit__c audit = new NSSAudit__c();
      insert audit;
      
      audit = [Select Id, NSR_Name__c, NSR__c from NSSAudit__c where Id=:audit.Id];
      System.assertEquals(null,audit.NSR__c);
      audit.NSR_Name__c=usr.Id;
      update audit;
      
      audit = [Select Id, NSR_Name__c, NSR__c from NSSAudit__c where Id=:audit.Id];
      System.assertEquals(ctct.Id,audit.NSR__c);
      
   } // testHandleNSRContacts

   static testMethod void testCommissionMonth() {
      CommissionMonth__c commMonth1 = new CommissionMonth__c(Name='January2016',StartDate__c=Date.newInstance(2016,1,1)
                                                     ,EndDate__c=Date.newInstance(2016,1,31), NSSStatus__c='Closed');
      CommissionMonth__c commMonth2 = new CommissionMonth__c(Name='February2016',StartDate__c=Date.newInstance(2016,2,1)
                                                     ,EndDate__c=Date.newInstance(2016,2,29), NSSStatus__c='Open');
      CommissionMonth__c commMonth3 = new CommissionMonth__c(Name='March2016',StartDate__c=Date.newInstance(2016,3,1)
                                                     ,EndDate__c=Date.newInstance(2016,3,31), NSSStatus__c='Open');
      CommissionMonth__c[] commMonths = new CommissionMonth__c[]{commMonth1,commMonth2,commMonth3};
      insert commMonths;
      
      NssAuditHelper.LOG_COMM_MONTH_ERROR=true;
      NssAuditHelper.OPEN_STATUS='Open';
      
      NSSAudit__c audit1 = new NSSAudit__c(CreditDate__c=Date.newInstance(2015,12,15));
      NSSAudit__c audit2 = new NSSAudit__c(CreditDate__c=Date.newInstance(2016,1,15));
      NSSAudit__c audit3 = new NSSAudit__c(CreditDate__c=Date.newInstance(2016,2,15));
      NSSAudit__c audit3a = new NSSAudit__c(CreditDate__c=Date.newInstance(2016,2,20));
      NSSAudit__c audit3b = new NSSAudit__c(CreditDate__c=Date.newInstance(2016,2,25));
      NSSAudit__c audit4 = new NSSAudit__c(CreditDate__c=Date.newInstance(2016,3,15));
      NSSAudit__c audit5 = new NSSAudit__c(CreditDate__c=Date.newInstance(2016,4,15));
      NSSAudit__c[] audits = new NSSAudit__c[]{audit1,audit2,audit3,audit3a,audit3b,audit4,audit5};
      Database.SaveResult[] results = Database.insert(audits,false);
      
      Map<Id,NSSAudit__c> auditMap = new Map<Id,NSSAudit__c>([Select Id, CreditDate__c, CommissionMonth__c from NSSAudit__c]);
      NSSAudit__c checkAudit1 = auditMap.get(audit1.Id);
      System.assertEquals(null,checkAudit1.CommissionMonth__c);
      
      // audit2 should fail the insert because the month is closed
      System.assertEquals(null,audit2.Id);
      Database.SaveResult result2 = results[1];
      System.debug('testCommissionMonth result2 errors='+result2.getErrors());
      
      NSSAudit__c checkAudit3 = auditMap.get(audit3.Id);
      System.assertEquals(commMonth2.Id,checkAudit3.CommissionMonth__c);

      NSSAudit__c checkAudit3a = auditMap.get(audit3a.Id);
      System.assertEquals(commMonth2.Id,checkAudit3a.CommissionMonth__c);

      NSSAudit__c checkAudit3b = auditMap.get(audit3b.Id);
      System.assertEquals(commMonth2.Id,checkAudit3b.CommissionMonth__c);

      NSSAudit__c checkAudit4 = auditMap.get(audit4.Id);
      System.assertEquals(commMonth3.Id,checkAudit4.CommissionMonth__c);

      NSSAudit__c checkAudit5 = auditMap.get(audit5.Id);
      System.assertEquals(null,checkAudit5.CommissionMonth__c);
      
      
   } // testCommissionMonth
   
} // class NSSAuditHelperTest