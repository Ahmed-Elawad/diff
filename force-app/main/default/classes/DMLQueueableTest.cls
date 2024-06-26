//Test for DMLQueueable 

@isTest
private class DMLQueueableTest {

   public static User rep1;	
   public static Account Acct1 = createTestAcct('acct1');   	
   public static Account Acct2 = createTestAcct('acct2');   	
   public static Account Acct3 = createTestAcct('acct3');   	
   public static Account [] accts = new Account []{acct1, acct2,acct3}; 
   public static List<SObject> dmlUpdateList = new List<SObject>();
   
   
   public static void setUpAccts() {
   	insert accts;  
   	
   	UserHelperTest.selectDsaAndReps(); 
   	
   	rep1 = UserHelperTest.v_reps[0];
   	
   	Acct1.OwnerId = rep1.id; 
   	Acct1.Bypass_Hold_Out__c = true; 

   	Acct2.OwnerId = rep1.id;
   	Acct2.Bypass_Hold_Out__c = true; 

   	Acct3.OwnerId = rep1.id;
   	Acct3.Bypass_Hold_Out__c = true; 
   	
   	dmlUpdateList.addAll((SObject[])accts); 
   	
   }//setUpAccts 
   
   
   static testMethod void testQueueable(){
   	setUpAccts(); 
   	DMLQueueable DML = new DMLQueueable ('string', dmlUpdateList); 
   	
   	test.startTest();
   	
   	system.enqueueJob(DML);
   	test.stopTest(); 
   	
   	system.assertEquals(rep1.id, Acct1.OwnerId); 
   	
   	
   	
   }//testQueueable
   
   
   
   static Account createTestAcct(String acctName){
        return new Account	(name = acctName                                   
                                        ,ShippingStreet = '911 Panorama Trail South'
                                        ,ShippingCity = 'Rochester'
                                        ,ShippingState = 'NY'
                                        ,Hold_Out__c = true
                                        ,Permanent_Hold_Out_Description__c = 'ADMIN'
                                        ,ShippingPostalCode = '14586');
                                        
    } //createTestAcct   

}//DMLQueueableTest