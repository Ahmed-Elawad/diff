/**
 * This class contains unit tests for validating the ObjectRelationshipsFieldsBefore trigger.
 * 
 *
 * History
 * --------
 * 03/20/2013   Cindy Freeman   created
 * 10/06/2013 	Cindy Freeman	modified to test (ID) in field constant and to use longer FilterCriteria field
 *
 */

@isTest
private class ObjectRelationshipsFieldsBeforeTest {

    static testMethod void objRelFldTest1() {
        
        // insert Object relationship
        Object_Relationships__c orc1 = new Object_Relationships__c(Primary_Object_API_name__c = 'Case'
                                                                    , Primary_Object_Rcd_Type__c = 'Service Onboarding 401k New Case'
                                                                    , Related_Object_API_name__c = 'Reference_401k_S125__c'
                                                                    , Related_Object_Rcd_Type__c = 'Service Onboarding 401k New Case');
        insert orc1;
        
        // insert good Field relationship
        Object_Relationships_Fields__c orf1 = new Object_Relationships_Fields__c(Object_Relationships__c = orc1.Id
                                                        , Primary_Field_API_name__c = 'Id'
                                                        , Related_Field_API_name__c = 'Case_Lookup__c');
        insert orf1;
        Object_Relationships_Fields__c neworf1 = [Select Id, Name, Primary_Field_API_name__c, Primary_Field_type__c, Primary_Object_API_name__c, Primary_Relationship_API_name__c, 
                                                    Related_Field_API_name__c, Related_Field_type__c, Related_Object_API_name__c, 
                                                    Field_Constant__c, Queue__c, Queue_Id__c
                                                    From Object_Relationships_Fields__c where Object_Relationships__c = :orc1.Id];
        System.assertEquals('ID', neworf1.Primary_Field_type__c);
        System.assertEquals('Case', neworf1.Primary_Object_API_name__c);
        System.assertEquals('ID', neworf1.Related_Field_type__c);
        System.assertEquals('Reference_401k_S125__c', neworf1.Related_Object_API_name__c);                                                  
        
        // insert good Field relationships
        List<Object_Relationships_Fields__c> listorfs = new List<Object_Relationships_Fields__c>();
        Object_Relationships_Fields__c orf2 = new Object_Relationships_Fields__c(Object_Relationships__c = orc1.Id
                                                        , Field_Constant__c = 'True'
                                                        , Related_Field_API_name__c = 'Blackout_Lifted__c');
        listorfs.add(orf2);
        Object_Relationships_Fields__c orf3 = new Object_Relationships_Fields__c(Object_Relationships__c = orc1.Id
                                                        , Field_Constant__c = '1234.5'
                                                        , Related_Field_API_name__c = 'Basis_Points__c');
        listorfs.add(orf3);
        Object_Relationships_Fields__c orf4 = new Object_Relationships_Fields__c(Object_Relationships__c = orc1.Id
                                                        , Field_Constant__c = 'ABC123'
                                                        , Related_Field_API_name__c = 'Welcome_Package_Contents_Notes__c');
        listorfs.add(orf4);
        Object_Relationships_Fields__c orf5 = new Object_Relationships_Fields__c(Object_Relationships__c = orc1.Id
                                                        , Queue__c = 'HRS Field Support'
                                                        , Related_Field_API_name__c = 'OwnerId');
        listorfs.add(orf5);
        Object_Relationships_Fields__c orf6 = new Object_Relationships_Fields__c(Object_Relationships__c = orc1.Id
                                                        , Primary_field_API_name__c = 'Owner.ManagerId'
                                                        , Primary_Object_API_name__c = 'Opportunity'
                                                        , Primary_Relationship_API_name__c = 'Opportunity__c'
                                                        , Related_Field_API_name__c = 'OwnerId');
        listorfs.add(orf6);
        Object_Relationships_Fields__c orf7 = new Object_Relationships_Fields__c(Object_Relationships__c = orc1.Id
                                                        , IsFilter__c = true
                                                        , Primary_Field_API_name__c = 'Status'                                                      
                                                        , FilterCriteria__c = 'New');
        listorfs.add(orf7);
        Object_Relationships_Fields__c orf8 = new Object_Relationships_Fields__c(Object_Relationships__c = orc1.Id
                                                        , IsFilter__c = true
                                                        , Primary_Field_API_name__c = 'Origin'                                                      
                                                        , FilterCriteria__c = 'Not Null');
        listorfs.add(orf8);
        
        
        insert listorfs;                                                        
        Object_Relationships_Fields__c neworf2 = [Select Id, Primary_Field_type__c from Object_Relationships_Fields__c 
                                                    where Related_Field_API_name__c = 'Blackout_Lifted__c'];
        System.assertEquals('BOOLEAN', neworf2.Primary_Field_type__c);                                                  
        Object_Relationships_Fields__c neworf3 = [Select Id, Primary_Field_type__c from Object_Relationships_Fields__c 
                                                    where Related_Field_API_name__c = 'Basis_Points__c'];
        System.assertEquals('DOUBLE', neworf3.Primary_Field_type__c);                                                   
        Object_Relationships_Fields__c neworf4 = [Select Id, Primary_Field_type__c from Object_Relationships_Fields__c 
                                                    where Related_Field_API_name__c = 'Welcome_Package_Contents_Notes__c'];
        System.assertEquals('STRING', neworf4.Primary_Field_type__c);                                                   
        Object_Relationships_Fields__c neworf5 = [Select Id, Primary_Field_type__c from Object_Relationships_Fields__c 
                                                    where Queue__c = 'HRS Field Support'];
        System.assertEquals('ID', neworf5.Primary_Field_type__c);                                                   
        Object_Relationships_Fields__c neworf6 = [Select Id, Primary_Field_type__c from Object_Relationships_Fields__c 
                                                    where Primary_Field_API_name__c = 'Owner.ManagerId'];
        System.assertEquals('ID', neworf6.Primary_Field_type__c);                                                   
        Object_Relationships_Fields__c neworf8 = [Select Id, FilterCriteria__c from Object_Relationships_Fields__c 
                                                    where Primary_Field_API_name__c = 'Origin'];
        System.assertEquals('not null', neworf8.FilterCriteria__c);

        
        // insert bad Field realtionships       
        Object_Relationships_Fields__c orfb1 = new Object_Relationships_Fields__c(Object_Relationships__c = orc1.Id
                                                        , Primary_field_API_name__c = 'Bad_Primary_Fld'
                                                        , Related_Field_API_name__c = 'Blackout_Lifted__c');
        try {
            insert orfb1;
        }
        catch (Exception e2)
        {   System.assertEquals('Failed', 'Failed');}  
                
        Object_Relationships_Fields__c orfb2 = new Object_Relationships_Fields__c(Object_Relationships__c = orc1.Id
                                                        , Primary_field_API_name__c = 'Close_Date'
                                                        , Primary_Object_API_name__c = 'Opportunity'
                                                        , Primary_Relationship_API_name__c = 'Opportunity__c'
                                                        , Related_Field_API_name__c = 'Proposed_Run_Date__c');
        try {
            insert orfb2;
        }
        catch (Exception e2)
        {   System.assertEquals('Failed', 'Failed');}  
                
        Object_Relationships_Fields__c orfb3 = new Object_Relationships_Fields__c(Object_Relationships__c = orc1.Id
                                                        , Related_Field_API_name__c = 'Bad_Related_Fld');
        try {
            insert orfb3;
        }
        catch (Exception e2)
        {   System.assertEquals('Failed', 'Failed');}    
                
        Object_Relationships_Fields__c orfb4 = new Object_Relationships_Fields__c(Object_Relationships__c = orc1.Id
                                                        , Queue__c = 'Bad Queue Name'
                                                        , Related_Field_API_name__c = 'OwnerId');
        try {
            insert orfb4;
        }
        catch (Exception e2)
        {   System.assertEquals('Failed', 'Failed');}           
        
        Object_Relationships_Fields__c orfb5 = new Object_Relationships_Fields__c(Object_Relationships__c = orc1.Id
                                                        , Primary_field_API_name__c = 'Close_Date'
                                                        , Primary_Object_API_name__c = 'Opportunity'
                                                        , Primary_Relationship_API_name__c = 'Bad_Opportunity__r'
                                                        , Related_Field_API_name__c = 'Proposed_Run_Date__c');
        try {
            insert orfb5;
        }
        catch (Exception e2)
        {   System.assertEquals('Failed', 'Failed');}  
  
        Object_Relationships_Fields__c orfb6 = new Object_Relationships_Fields__c(Object_Relationships__c = orc1.Id
                                                        , Primary_field_API_name__c = 'Id'
                                                        , Related_Field_API_name__c = 'Blackout_Lifted__c');
        try {
            insert orfb6;
        }
        catch (Exception e2)
        {   System.assertEquals('Failed', 'Failed');}  
  
        Object_Relationships_Fields__c orfb7 = new Object_Relationships_Fields__c(Object_Relationships__c = orc1.Id
                                                        , IsFilter__c = true
                                                        , FilterCriteria__c = 'not null'
                                                        , Related_Field_API_name__c = 'Blackout_Lifted__c');
        try {
            insert orfb7;
        }
        catch (Exception e2)
        {   System.assertEquals('Failed', 'Failed');}  

        Object_Relationships_Fields__c orfb8 = new Object_Relationships_Fields__c(Object_Relationships__c = orc1.Id
                                                        , IsFilter__c = true);
        try {
            insert orfb8;
        }
        catch (Exception e2)
        {   System.assertEquals('Failed', 'Failed');}  

        Object_Relationships_Fields__c orfb9 = new Object_Relationships_Fields__c(Object_Relationships__c = orc1.Id
                                                        , Primary_field_API_name__c = 'Owner.SomeText.Id'
                                                        , Related_Field_API_name__c = 'OwnerId');
        try {
            insert orfb9;
        }
        catch (Exception e2)
        {   System.assertEquals('Failed', 'Failed');}  

        Object_Relationships_Fields__c orfb10 = new Object_Relationships_Fields__c(Object_Relationships__c = orc1.Id
                                                        , Primary_field_API_name__c = 'Owner.BossId'
                                                        , Related_Field_API_name__c = 'OwnerId');
        try {
            insert orfb10;
        }
        catch (Exception e2)
        {   System.assertEquals('Failed', 'Failed');}  

		Object_Relationships_Fields__c orfb11 = new Object_Relationships_Fields__c(Object_Relationships__c = orc1.Id
                                                        , Field_Constant__c = '(ID)badid123'
                                                        , Related_Field_API_name__c = 'Comments__c');
        try {
            insert orfb11;
        }
        catch (Exception e2)
        {   System.assertEquals('Failed', 'Failed');}  

    }
    
    
}