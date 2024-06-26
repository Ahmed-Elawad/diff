/* **********************************************************************************************************************************
* History: This is the test class of EmployeeLocationMethodsHandler
* -------
* 01/16/2024 Pratik Das       Created (APR0162760: To add distinct employee location state to acord data )
* 
* 
************************************************************************************************************************************/
@isTest
public class EmployeeLocationMethodsHandlerTest{
    
    @testSetup 
    static void setup(){
        //Create Account
        Account acct = new Account(Name='Test Acct');
        insert acct;
        //Create Acord
        List<Acord__c> lstAcr=new List<Acord__c>();
        Acord__c acc1=new Acord__c();
        acc1.Prospect_Client__c=acct.id;
        acc1.Address__c='69 Laurelton Road Rochester NY  14609 US';
        acc1.Status_of_Submission__c='Issue Policy';
        acc1.Audit__c='At Expiration';
        lstAcr.add(acc1);
        //insert acc1;
        
        
        Acord__c acc2=new Acord__c();
        acc2.Prospect_Client__c=acct.id;
        acc2.Address__c='69 Laurelton Road Rochester NY  14609 US1';
        acc2.Status_of_Submission__c='Issue Policy';
        acc2.Audit__c='At Expiration';
        lstAcr.add(acc2);
        //insert acc2;
        insert lstAcr;
        
        //Create Employee Location
        List<Employee_Location__c> lstempLoc=new List<Employee_Location__c>();
        Employee_Location__c eLoc1=new Employee_Location__c();
        eLoc1.Acord_Name__c=acc1.id;
        eLoc1.Name='1';
        eLoc1.State__c='AK';
        lstempLoc.add(eLoc1);
        Employee_Location__c eLoc2=new Employee_Location__c();
        eLoc2.Acord_Name__c=acc1.id;
        eLoc2.Name='2';
        eLoc2.State__c='AL';
        lstempLoc.add(eLoc2);
        
        Employee_Location__c eLoc3=new Employee_Location__c();
        eLoc3.Acord_Name__c=acc1.id;
        eLoc3.Name='3';
        eLoc3.State__c='AR';
        lstempLoc.add(eLoc3);
        
        Employee_Location__c eLoc4=new Employee_Location__c();
        eLoc4.Acord_Name__c=acc1.id;
        eLoc4.Name='4';
        eLoc4.State__c='AK';
        lstempLoc.add(eLoc4);
        
        Employee_Location__c eLoc5=new Employee_Location__c();
        eLoc5.Acord_Name__c=acc2.id;
        eLoc5.Name='1A';
        eLoc5.State__c='AK';
        lstempLoc.add(eLoc5);
        insert lstempLoc;
        
    }//End of setup
    
    // public static void updateAccordLocation(Set<Id> setAcordIds){
    
    @isTest
    static void testupdateAccordLocation(){
        List<Acord__c> lstAcrd=[Select id from Acord__c];
        set<Id> setAcrId=new Set<Id>();
        for(Acord__c acr:lstAcrd){
            setAcrId.add(acr.id);
        }
        test.starttest();
        EmployeeLocationMethodsHandler.updateAccordLocation(setAcrId);
        List<Employee_Location__c> lstempLoc=[Select id from Employee_Location__c where name='1A'];
        lstempLoc[0].State__c='AL';
        update lstempLoc[0];
        delete lstempLoc;
        test.stoptest();
    }
    
    
}