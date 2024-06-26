/*
* Before Trigger for Advocates
* 
* 04/29/2020	Matt Fritschi	Created
* 
*
*  
*/

@isTest(seeAllData=false) 
public class AmpAdvocateBeforeTest {

 /*   static testMethod void testPCAdvocateOwnership()
    {        
        Profile pcProfile = [SELECT Id, Name FROM Profile WHERE Name = 'PC Sales Rep - SB' LIMIT 1];
        User pcRep = [SELECT Id, Name FROM User WHERE ProfileId = :pcProfile.Id AND IsActive = true LIMIT 1];
        
        amp_dev__Amp_Advocate__c ampAdv = new amp_dev__Amp_Advocate__c(Name='TestAdvocate1234', amp_dev__Status__c = 'Invited');
        
        System.runAs(pcRep)
        {
            insert ampAdv;
        }
        
        ampAdv = [SELECT Id, Name, CreatedById, OwnerId, Change_Owner_Date__c, amp_dev__Status__c FROM amp_dev__Amp_Advocate__c WHERE Name='TestAdvocate1234' LIMIT 1];
        System.debug(ampAdv);
        System.assertEquals(ampAdv.CreatedById, pcRep.Id);
        System.assertEquals(ampAdv.OwnerId, pcRep.Id);
        System.assertNotEquals(ampAdv.Change_Owner_Date__c, null);
    } //testPCAdvocateOwnership
    
    static testMethod void testHRSHoldOutSet()
    {        
        //Profile hrsProfile = [SELECT Id, Name FROM Profile WHERE Name = 'HRS 401(k) Sales - SB' LIMIT 1];
        User hrsRep = [Select Id, Name from User where IsActive=true and Sales_Org__c=:UserHelper.SO_401 limit 1];
        
        Schema.RecordTypeInfo rtAcct = RecordTypeHelper.getRecordType(RecordTypeHelper.MMS_ACCOUNT, 'Account');
        Account acctA = new Account(Name = 'testAccountA', RecordTypeId=rtAcct.getRecordTypeId(), AccountNumber = '8-00081234',NumberOfEmployees = 60);
        insert acctA;
        
        amp_dev__Amp_Advocate__c ampAdv = new amp_dev__Amp_Advocate__c(Name='TestAdvocate1234', amp_dev__Status__c = 'Invited', Account__c=acctA.Id);
        
        System.runAs(hrsRep)
        {
            insert ampAdv;
            
            //ampAdv = [SELECT Id, Name, CreatedById, OwnerId, Change_Owner_Date__c, amp_dev__Status__c FROM amp_dev__Amp_Advocate__c WHERE Name='TestAdvocate1234' LIMIT 1];
            
            Test.startTest();
            
            ampAdv.amp_dev__Status__c = 'Active';
            System.debug('ampAdv='+ampAdv);
            update ampAdv;
            
            Test.stopTest();
        }
        
        ampAdv = [SELECT Id, Name, CreatedById, OwnerId, Change_Owner_Date__c, amp_dev__Status__c FROM amp_dev__Amp_Advocate__c WHERE Name='TestAdvocate1234' LIMIT 1];
        acctA = [SELECT Id, Name, HRS_Hold_Out__c, Permanent_Hold_Out_Description__c FROM Account WHERE Id = :acctA.Id LIMIT 1];
        
        System.debug(ampAdv);
        System.assertEquals(ampAdv.CreatedById, hrsRep.Id);
        System.assertEquals(ampAdv.OwnerId, hrsRep.Id);
        System.assertNotEquals(ampAdv.Change_Owner_Date__c, null);
        
        System.assertEquals(ampAdv.amp_dev__Status__c, 'Active');
        System.assertEquals(acctA.HRS_Hold_Out__c, true);
        System.assertEquals(acctA.Permanent_Hold_Out_Description__c, 'Referral Network Advocate');
    } //testHRSHoldOutSet
    
    
    static testMethod void testChangeOwnerToAccountOwner()
    {        
        Profile hrsProfile = [SELECT Id, Name FROM Profile WHERE Name = 'HRS 401(k) Sales - SB' LIMIT 1];
        Profile smbProfile = [SELECT Id, Name FROM Profile WHERE Name = 'Core Sales - SB' LIMIT 1];
        User hrsRep = [SELECT Id, Name FROM User WHERE ProfileId = :hrsProfile.Id AND IsActive = true LIMIT 1];
        User smbRep = [SELECT Id, Name FROM User WHERE ProfileId = :smbProfile.Id AND IsActive = true LIMIT 1];
        
        Schema.RecordTypeInfo rtAcct = RecordTypeHelper.getRecordType(RecordTypeHelper.MMS_ACCOUNT, 'Account');
        Account acctA = new Account(Name = 'testAccountA', RecordTypeId=rtAcct.getRecordTypeId(), AccountNumber = '8-00081234',NumberOfEmployees = 60, OwnerId=smbRep.Id);
        insert acctA;
        
        amp_dev__Amp_Advocate__c ampAdv = new amp_dev__Amp_Advocate__c(Name='TestAdvocate1234', amp_dev__Status__c = 'Active', Account__c=acctA.Id, OwnerId = hrsRep.Id, Change_Owner_Date__c = System.Date.Today());
        insert ampAdv;
          
        ampAdv.Change_Owner_Date__c = null;
        update ampAdv;
        
        ampAdv = [SELECT Id, Name, CreatedById, OwnerId, Change_Owner_Date__c, amp_dev__Status__c, Owner_For_Reporting__c FROM amp_dev__Amp_Advocate__c WHERE Name='TestAdvocate1234' LIMIT 1];
        acctA = [SELECT Id, Name, HRS_Hold_Out__c, Permanent_Hold_Out_Description__c FROM Account WHERE Id = :acctA.Id LIMIT 1];
        
        System.debug(ampAdv);
        //System.assertEquals(ampAdv.CreatedById, hrsRep.Id);
        System.assertEquals(ampAdv.OwnerId, smbRep.Id);
        System.assertEquals(ampAdv.Change_Owner_Date__c, null);
        System.assertEquals(ampAdv.Owner_For_Reporting__c, ampAdv.OwnerId);
        
        System.debug('Updating Owner Now. hrsRepId='+hrsRep.Id+' smbRep='+smbRep.Id);
        ampAdv.OwnerId = hrsRep.Id;
        update ampAdv;
        
        ampAdv = [SELECT Id, Name, CreatedById, OwnerId, Change_Owner_Date__c, amp_dev__Status__c, Owner_For_Reporting__c FROM amp_dev__Amp_Advocate__c WHERE Name='TestAdvocate1234' LIMIT 1];
        System.assertEquals(ampAdv.Owner_For_Reporting__c, ampAdv.OwnerId);
        
    } //testHRSHoldOutSet */
   
}