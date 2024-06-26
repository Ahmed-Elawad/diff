/* Test Methods for ARReferralManagementDataMethods

 * History
 * -------
  10/01/2019 Carrie Marciano      Created
  
*/

@isTest
public class ARReferralManagementDataMethodsTest {

    static testMethod void testARData(){
        
        amp_dev__Amp_Referral__c ampRef1 = new amp_dev__Amp_Referral__c (Name='ampRef1', amp_dev__Status__c='Submitted', AR_Reward_Amount__c='', Term_End_Date__c=Date.today().addDays(364));
        amp_dev__Amp_Referral__c ampRef2 = new amp_dev__Amp_Referral__c (Name='ampRef2', amp_dev__Status__c='SoldPendingPayroll', AR_Reward_Amount__c='$200', Term_End_Date__c=Date.today().addDays(364));
        amp_dev__Amp_Referral__c ampRef3 = new amp_dev__Amp_Referral__c (Name='ampRef3', amp_dev__Status__c='Successful', AR_Reward_Amount__c='$500', Term_End_Date__c=Date.today().addDays(364));
        amp_dev__Amp_Referral__c[] ampRefs = new amp_dev__Amp_Referral__c[]{ampRef1,ampRef2,ampRef3};
        insert ampRefs;
        
        Referral__c payxRef1 = new Referral__c (Name='payxRef1', Amplifinity_Referral__c=ampRef1.Id, AR_Status__c='Suggested', AMP_Status__c='Submitted', Credit_Date__c=null, Reward_Amount__c='', Term_Start_Date__c=Date.today(), Term_End_Date__c=Date.today().addDays(364));
        Referral__c payxRef2 = new Referral__c (Name='payxRef2', Amplifinity_Referral__c=ampRef2.Id, AR_Status__c='Validated', AMP_Status__c='SoldPendingPayroll', Credit_Date__c=null, Reward_Amount__c='$200', Term_Start_Date__c=Date.today(), Term_End_Date__c=Date.today().addDays(364));
        Referral__c payxRef3 = new Referral__c (Name='payxRef3', Amplifinity_Referral__c=ampRef3.Id, AR_Status__c='Processed', AMP_Status__c='Successful', Credit_Date__c=Date.today(), Reward_Amount__c='$500', Term_Start_Date__c=Date.today(), Term_End_Date__c=Date.today().addDays(364));
        Referral__c[] payxRefs = new Referral__c[]{payxRef1,payxRef2,payxRef3};
        insert payxRefs;
        
        AR_Referral_Management_Data__c arDataRec1 = new AR_Referral_Management_Data__c (AR_Status__c='Validated', Credit_Date__c=Date.today(), ReferralID__c=payxRef1.Id, Reward_Amount__c='$500', Term_Start_Date__c=Date.today(), Term_End_Date__c=Date.today().addDays(364)); 
        AR_Referral_Management_Data__c arDataRec2 = new AR_Referral_Management_Data__c (AR_Status__c='Processed', Credit_Date__c=Date.today(), ReferralID__c=payxRef2.Id, Reward_Amount__c='$200', Term_Start_Date__c=Date.today(), Term_End_Date__c=Date.today().addDays(364));
        AR_Referral_Management_Data__c arDataRec3 = new AR_Referral_Management_Data__c (AR_Status__c='Processed', Credit_Date__c=Date.today(), ReferralID__c=payxRef3.Id, Reward_Amount__c='Free Payroll', Term_Start_Date__c=Date.today(), Term_End_Date__c=Date.today().addDays(364));
        AR_Referral_Management_Data__c[] arDataRecs = new AR_Referral_Management_Data__c[]{arDataRec1,arDataRec2,arDataRec3};
        
        Amplifinity_AR_Status_Mapping__mdt[] statusMapping = [select MasterLabel, AR_Status__c, AMP_Status__c, Allow_Updates__c from Amplifinity_AR_Status_Mapping__mdt where label ='Processed']; 
        System.assertEquals(false,statusMapping[0].Allow_Updates__c); 
        
        Test.startTest();
        insert arDataRecs; 
        Test.stopTest();
         
        payxRef1 = [Select Id, Credit_Date__c, AR_Status__c, Reward_Amount__c from Referral__c where Id=:payxRef1.Id];
        System.assertEquals(arDataRec1.Credit_Date__c, payxRef1.Credit_Date__c);
        System.assertEquals('Validated',payxRef1.AR_Status__c);
        System.assertEquals(arDataRec1.Reward_Amount__c, payxRef1.Reward_Amount__c);
        payxRef2 = [Select Id, Credit_Date__c, AR_Status__c from Referral__c where Id=:payxRef2.Id];
        System.assertEquals(arDataRec2.Credit_Date__c, payxRef2.Credit_Date__c);
        System.assertEquals('Processed',payxRef2.AR_Status__c);
        payxRef3 = [Select Id, AR_Status__c, Reward_Amount__c from Referral__c where Id=:payxRef3.Id];
        System.assertEquals('$500',payxRef3.Reward_Amount__c);
        System.assertEquals('Processed',payxRef3.AR_Status__c);
        
   }//testARData
}