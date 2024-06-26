/*
  * This new process will dynamically create a new  COVID Request Reference_Terms_Transfers__c and link it back to the related case record.  For example, it can create 
  *  
  * 
  * COVID Request Reference_Terms_Transfers__c automatically upon insert of 401k/S125 Operations Support recordtype cases by autopopulating OwnerId,Case Look Up,Contact Name from Case
  *  
  * History
  * --------
  * 04/27/2020 Preetam Thandra    created
  * 
    
   */
@isTest
public with sharing class CreateCovidRequestsTest {
    
   @testSetup
   public static void setupData() {
       
      TriggerSetupClasses__c[] classes = new TriggerSetupClasses__c[]{};
     
      TriggerMethodsTest.createTriggerSetting('CaseAfter', false, true, false, false,new String[]{'CreateCovidRequests'}, classes, TriggerMethods.INTERFACE_C);
      insert classes;
   }
    
    
    @isTest
    public static void createRequestCovid() {
        
        
       Contact con = new Contact(RecordTypeId=Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Admin').getRecordTypeId());    
       con.FirstName = 'Testcon';
       con.LastName = 'TestLastName';
       
       insert con;
        
       
       Case c = new Case(RecordTypeId=Schema.SObjectType.Case.getRecordTypeInfosByName().get('401k/S125 Operations Support').getRecordTypeId());
       c.Product__c ='401k';
       c.ContactId = con.Id;
       c.Termination_Transfer_Type__c = 'COVID Request';
       insert c;
       
       Reference_Terms_Transfers__c ref = [Select Id,Name,Contact_Name__c from Reference_Terms_Transfers__c where Case_Lookup__c =: c.id Limit 1];
       
       System.assertEquals(con.Id,ref.Contact_Name__c);



    }
    
    
    @isTest
    public static void createRequestCovidonCaseUpdate() {
        
        
       Contact con = new Contact(RecordTypeId=Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Admin').getRecordTypeId());    
       con.FirstName = 'Testcon';
       con.LastName = 'TestLastName';
       
       insert con;
        
       
       Case c = new Case(RecordTypeId=Schema.SObjectType.Case.getRecordTypeInfosByName().get('401k Manual Collection').getRecordTypeId());
      
       c.ContactId = con.Id;
      
       insert c;
        
       Case ca = new Case(id=c.Id,RecordTypeId=Schema.SObjectType.Case.getRecordTypeInfosByName().get('401k/S125 Operations Support').getRecordTypeId()); 
       ca.Product__c ='401k';
       ca.Termination_Transfer_Type__c = 'COVID Request';
       update ca;
        
       
       Reference_Terms_Transfers__c ref = [Select Id,Name,Contact_Name__c from Reference_Terms_Transfers__c where Case_Lookup__c =: ca.id Limit 1];
       
       System.assertEquals(con.Id,ref.Contact_Name__c);



    }


}