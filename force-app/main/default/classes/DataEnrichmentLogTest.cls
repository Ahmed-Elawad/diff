/* Test Class for DataEnrichmentLogMethods and DataEnrichmentLogQueueabale
 *
 * History
 * -------
   08/28/2019 	Jake Hinds       Created
   01/23/2023   Dan Carmen       Update to TriggerInterfaceC

*/
@isTest
public class DataEnrichmentLogTest {
    
   @testSetup
   public static void setup(){
      TriggerMethodsTest.createTriggerSetting('AccountAfter', false, true, false, false,new String[]{'DataEnrichmentLogMethods'});
      TriggerMethodsTest.createTriggerSetting('ContactAfter', false, true, false, false,new String[]{'DataEnrichmentLogMethods'});
      TriggerMethodsTest.createTriggerSetting('BusinessProfileTrigger', false, true, false, false,new String[]{'DataEnrichmentLogMethods'});
      TriggerMethodsTest.saveSetupClasses();

   } // setup

    static testMethod void testAccount(){
        
        Data_Enrichment_Log_Fields__c delf1 = new Data_Enrichment_Log_Fields__c(Name='AcctName',
                                                                               Object_Name__c='Account',
                                                                               Field_Name_on_Object__c='Name',
                                                                               DEL_Field_Before__c='Account_Name_Before__c',
                                                                               DEL_Field_After__c='Account_Name_After__c');
        Data_Enrichment_Log_Fields__c delf2 = new Data_Enrichment_Log_Fields__c(Name='AcctIndustry',
                                                                               Object_Name__c='Account',
                                                                               Field_Name_on_Object__c='Industry',
                                                                               DEL_Field_Before__c='Industry_Before__c',
                                                                               DEL_Field_After__c='Industry_After__c');
        Data_Enrichment_Log_Fields__c[] delfs = new Data_Enrichment_Log_Fields__c[]{delf1,delf2};
        insert delfs;
        
        List<String> profileNames = Label.Data_Enrichment_Log_Profiles.split(';');
        User u = [SELECT Id FROM User WHERE isActive = true AND Profile.Name in :profileNames LIMIT 1];
        
        Account acct1 = new Account(Name='test Account',OwnerId=u.Id);
        Account acct2 = new Account(Name='test Account2',OwnerId=u.Id,Industry='Fun');
        Account[] accts = new Account[]{acct1,acct2};
        insert accts;
        Id[] acctIds = new Id[]{acct1.Id,acct2.Id};
        
        //simulating an existing one that needs to be updated
        Data_Enrichment_Log__c acct2Del = New Data_Enrichment_Log__c(Account__c=acct2.Id,Object_Type__c = 'Account');
        insert acct2Del;
        TriggerMethods.clearVariables();
        
        Test.startTest();
        System.runAs(u){
            acct1.Name = 'updated Account';
            acct2.Industry='Not Fun';
            update accts;
        }
        Test.stopTest();
        Data_Enrichment_Log__c[] dels = [SELECT Id,Account__c,Account_Name_Before__c,Account_Name_After__c,Industry_Before__c,Industry_After__c FROM Data_Enrichment_Log__c WHERE Account__c in :acctIds];
        system.assertEquals(2,dels.size());
        Data_Enrichment_Log__c del1;
        Data_Enrichment_Log__c del2;
        for(Data_Enrichment_Log__c del:dels){
            if(del.Account__c == acct1.Id){
                del1=del;
            }
            else if(del.Account__c ==acct2.Id){
                del2=del;
            }
        }
        system.assert(del1!=null);
        system.assertEquals('test Account',del1.Account_Name_Before__c);
        system.assertEquals(acct1.name,del1.Account_Name_After__c);
        system.assert(del2!=null);
        system.assertEquals('Fun',del2.Industry_Before__c);
        system.assertEquals(acct2.Industry,del2.Industry_After__c);
    }//testAccount
    static testMethod void testContact(){
        
        Data_Enrichment_Log_Fields__c delf1 = new Data_Enrichment_Log_Fields__c(Name='CtctFirstName',
                                                                               Object_Name__c='Contact',
                                                                               Field_Name_on_Object__c='FirstName',
                                                                               DEL_Field_Before__c='Contact_First_Name_Before__c',
                                                                               DEL_Field_After__c='Contact_First_Name_After__c');
        Data_Enrichment_Log_Fields__c delf2 = new Data_Enrichment_Log_Fields__c(Name='CtctLastName',
                                                                               Object_Name__c='Contact',
                                                                               Field_Name_on_Object__c='LastName',
                                                                               DEL_Field_Before__c='Contact_Last_Name_Before__c',
                                                                               DEL_Field_After__c='Contact_Last_Name_After__c');
        Data_Enrichment_Log_Fields__c delf3 = new Data_Enrichment_Log_Fields__c(Name='Ctct Linkedin',
                                                                               Object_Name__c='Contact',
                                                                               Field_Name_on_Object__c='LinkedIn_Profile__c',
                                                                               DEL_Field_Before__c='LinkedIn_Profile_Before__c',
                                                                               DEL_Field_After__c='LinkedIn_Profile_After__c');
        Data_Enrichment_Log_Fields__c[] delfs = new Data_Enrichment_Log_Fields__c[]{delf1,delf2,delf3};
        insert delfs;
        
        List<String> profileNames = Label.Data_Enrichment_Log_Profiles.split(';');
        User u = [SELECT Id FROM User WHERE isActive = true AND Profile.Name in :profileNames LIMIT 1];
        
        Account acct1 = new Account(Name='test Account',OwnerId=u.Id);
        insert acct1;
        
        Contact ctct1 = new Contact(FirstName='el',LastName='testo',AccountId=acct1.Id);
        insert ctct1;
        Contact ctct2;
        Contact[] ctcts = new Contact[]{ctct1};
        Id[] ctctIds = new Id[]{ctct1.Id};
        
        TriggerMethods.clearVariables();
        Test.startTest();
        System.runAs(u){
            ctct1.FirstName = 'no';
            ctct2 = new Contact(FirstName='second',LastName='test',LinkedIn_Profile__c='www.google.com',AccountId=acct1.Id);
            ctcts.add(ctct2);
            upsert ctcts;
            ctctIds.add(ctct2.Id);
        }
        Test.stopTest();
        Data_Enrichment_Log__c[] dels = [SELECT Id,Object_Type__c,Contact__c,Contact_First_Name_Before__c,Contact_First_Name_After__c,
                                         Contact_Last_Name_Before__c,Contact_Last_Name_After__c,
                                         LinkedIn_Profile_Before__c,LinkedIn_Profile_After__c
                                         FROM Data_Enrichment_Log__c WHERE Contact__c in : ctctIds];
        system.assertEquals(2,dels.size());
        Data_Enrichment_Log__c del1;
        Data_Enrichment_Log__c del2;
        for(Data_Enrichment_Log__c del:dels){
            if(del.Contact__c == ctct1.Id){
                del1=del;
            }
            else if(del.Contact__c ==ctct2.Id){
                del2=del;
            }
        }
        system.assert(del1!=null);
        system.assertEquals('el',del1.Contact_First_Name_Before__c);
        system.assertEquals(ctct1.FirstName,del1.Contact_First_Name_After__c);
        system.assertEquals('Contact - Edit',del1.Object_Type__c);
        system.assert(del2!=null);
        system.assert(string.isBlank(del2.LinkedIn_Profile_Before__c));
        system.assertEquals(ctct2.LinkedIn_Profile__c,del2.LinkedIn_Profile_After__c);
        system.assertEquals('Contact - New',del2.Object_Type__c);
    }//testContact
    static testMethod void testBusinessProfile(){
        
        Data_Enrichment_Log_Fields__c delf1 = new Data_Enrichment_Log_Fields__c(Name='Pain Points',
                                                                               Object_Name__c='Business_Profile__c',
                                                                               Field_Name_on_Object__c='Pain_Points__c',
                                                                               DEL_Field_Before__c='Pain_Points_Before__c',
                                                                               DEL_Field_After__c='Pain_Points_After__c');
        Data_Enrichment_Log_Fields__c delf2 = new Data_Enrichment_Log_Fields__c(Name='Social Info',
                                                                               Object_Name__c='Business_Profile__c',
                                                                               Field_Name_on_Object__c='Social_Info__c',
                                                                               DEL_Field_Before__c='Social_Before__c',
                                                                               DEL_Field_After__c='Social_After__c');
        Data_Enrichment_Log_Fields__c[] delfs = new Data_Enrichment_Log_Fields__c[]{delf1,delf2};
        insert delfs;
        
        List<String> profileNames = Label.Data_Enrichment_Log_Profiles.split(';');
        User u = [SELECT Id FROM User WHERE isActive = true AND Profile.Name in :profileNames LIMIT 1];
        
        Account acct1 = new Account(Name='test Account',OwnerId=u.Id);
        insert acct1;
        
        Business_Profile__c bp = new Business_Profile__c(Prospect_Client__c=acct1.Id,Pain_Points__c='Something');
        insert bp;
        
        TriggerMethods.clearVariables();
        Test.startTest();
        System.runAs(u){
            bp.Pain_Points__c = 'Paychex';
            bp.Social_Info__c = 'Fakebook';
            update bp;
        }
        Test.stopTest();
        Data_Enrichment_Log__c[] dels = [SELECT Id,Object_Type__c,Pain_Points_Before__c,Pain_Points_After__c,Social_Before__c,
                                         Social_After__c FROM Data_Enrichment_Log__c WHERE Business_Profile__c = :bp.Id];
        system.assertEquals(1,dels.size());
        
        system.assertEquals('Something',dels[0].Pain_Points_Before__c);
        system.assertEquals(bp.Pain_Points__c,dels[0].Pain_Points_After__c);
        system.assert(string.isBlank(dels[0].Social_Before__c));
        system.assertEquals(bp.Social_Info__c,dels[0].Social_After__c);
        system.assertEquals('Business Profile',dels[0].Object_Type__c);
    }//testBusinessProfile
    
} // class DataEnrichmentLogTest