/**
 * Test methods for ClientEDWInfoHelper
 *
 *  History
 *  --------
  05/02/2017 Josh Cartwright        created
  07/31/2017 Dan Carmen             Add process tracker
 *
 */
   
@isTest  
private class ClientEDWInfoHelperTest {
   public static Account acct1 = createTestAcct('acct1'); 
       
   public static ClientEDWInfo__c edw401k = createTestEDW ('401k', system.today());
   public static ClientEDWInfo__c edwFSA  = createTestEDW ('FSA', system.today());
   public static ClientEDWInfo__c edwPOP  = createTestEDW ('POP', system.today());
   public static ClientEDWInfo__c edwXYZ  = createTestEDW ('xyz', system.today());
   
   
   public static ClientEDWInfo__c [] edwS = new ClientEDWInfo__c []{edw401k,edwFSA,edwPOP, edwXYZ};
      
   static testMethod void checkAny(){
      ClientEDWInfoHelper.SKIP_TRIGGER = false;
      ClientEDWInfoHelper.SKIP_FUTURE = true;
      ZipCheckOwner.SKIP_TRIGGERS=true;
      insert acct1;
      insert edws; 
      System.assertEquals(edwS.size(), [select count() from ClientEDWInfo__c]);
   
      list<Account> acctList = [select name, Any_401k__c, Any_FSA__c, Any_POP__c, id from Account where Bis_ID__c = : 123456 limit 1]; 
      system.assert(acctlist[0].Any_401k__c); 
      system.assert(acctlist[0].Any_FSA__c); 
      system.assert(acctlist[0].Any_POP__c); 
   
      list<ClientEDWInfo__c> EDWList = [select name, Unrecognized_Name__c,BisId__c, id from ClientEDWInfo__c where Name = : 'xyz']; 
   
      //system.assertEquals(true, EDWList[0].Unrecognized_Name__c); 
   
      edw401k.BisId__c = null; 
      ClientEDWInfoHelper.TRIGGER_ALREADY_RAN = false;
      update edw401k; 
   
      EDWList= [select name, Unrecognized_Name__c,BisId__c, id, Bad_BIS_ID__c from ClientEDWInfo__c where Name = : '401k']; 
      system.assert(EDWList[0].Bad_BIS_ID__c); 
   
      edwFSA.StartDate__c = system.today()-1;
      ClientEDWInfoHelper.TRIGGER_ALREADY_RAN = false;
      update edwFSA; 
   
      edw401k.BisId__c = '12223';
      ClientEDWInfoHelper.TRIGGER_ALREADY_RAN = false;
      update edw401k; 
      EDWList= [select name, Unrecognized_Name__c,BisId__c, id, Bad_BIS_ID__c from ClientEDWInfo__c where Name = : '401k']; 
   
      system.assert(EDWList[0].Bad_BIS_ID__c); 
   
      edw401k.BisId__c = 'Josh';
      ClientEDWInfoHelper.TRIGGER_ALREADY_RAN = false;
      update edw401k; 
      EDWList= [select name, Unrecognized_Name__c,BisId__c, id, Bad_BIS_ID__c from ClientEDWInfo__c where Name = : '401k']; 
   
      system.assert(EDWList[0].Bad_BIS_ID__c); 
      
  }//checkany 
  
  
  static Account createTestAcct(String acctName){
       return new Account  (name = acctName                                   
                            ,Bis_ID__c = 123456
                            ,ShippingStreet = '911 Panorama Trail South'
                            ,ShippingCity = 'Rochester'
                            ,ShippingState = 'NY'
                            ,Permanent_Hold_Out_Description__c = 'ADMIN'
                            ,ShippingPostalCode = '14586');
  }//createTestAcct
  
  static ClientEDWInfo__c createTestEDW (String edwName, date startDate){
       return new ClientEDWInfo__c (name = edwName 
                            , BisId__c = '123456'
                            , StartDate__c = startDate); 
       
  }//createTestEDW
  

}//ClientEDWInfoHelperTest