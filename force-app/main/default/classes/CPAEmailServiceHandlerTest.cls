/**
 * Test method for CPAEmailServiceHandler 
 * History
 * --------
 * 01/16/2023 Josh Cartwright created 
 * 
 */
@isTest
public class CPAEmailServiceHandlerTest {


    static testMethod void myUnitTest() {
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();


        
        ReferralObjectSyncTest.resetFlags(); 
        Referral_Account__c ra = ReferralObjectSyncTest.createTestRefAcct(RecordTypeHelper.getRecordType('Core Referral Source Record Type','Referral_Account__c').getRecordTypeId());      
        insert ra;
        
        ReferralObjectSyncTest.resetFlags(); 
        Referral_Contact__c rc = ReferralObjectSyncTest.createTestRefCntct(RecordTypeHelper.getRecordType('Core Referral Record Type','Referral_Contact__c').getRecordTypeId(), ra.id);
        insert rc; 
        
        Referral_Contact__c refCntct = [select id, Contact__c from Referral_Contact__c where id = :rc.id limit 1 ];

        Contact newContact = [select id, User_Lookup__c,Referral_Contact__c from Contact where Ref_Contact_ID__c = :refCntct.Id limit 1];       

        system.debug('jc refCntct ' +refCntct ); 
        system.debug('jc Referral_Contact__c ' +refCntct.Contact__c);         

        String username = 'testUsernameApx@test.com';
        String nickname = 'testNicknameApx';
        String alias = 'cUserAli';
        String email1 = 'test@email.com'; 
        
        ConvertContactToCPACommunityUser.createCommunityUserNew(username,nickname, newContact.Id, alias, email1);
                
        user usr = [select id,Requested_Invite_Date__c, Community_User_First_Login__c from user where username =:username and isactive = true limit 1] ;
        system.debug('JC usr ' +usr); 
        // setup the data for the email
        // 
        email.subject = 'CPA Portal User Request';
        email.plainTextBody = usr.id;
        email.fromname = 'FirstName LastName';
        envelope.fromAddress = 'someaddress@email.com';
         
        
        // call Helper class directly to check parsing then process list creating new referral account and contact       
        CPAEmailServiceHandler cpaEmailHandler = new CPAEmailServiceHandler(); 
        cpaEmailHandler.handleInboundEmail( email, envelope);
        
        Referral_Contact__c retRc = [select id, CPA_Program_status__c from Referral_Contact__c where id =:rc.id limit 1 ]; 
        system.assert(retRc.CPA_Program_status__c=='Invited') ; 
        
        user u = [select id, name from user where Profile.Name='System Administrator' and isActive = true limit 1];
        system.runAs(u){
            usr.Community_User_First_Login__c = system.now();
            update usr; 
        }
            cpaEmailHandler.handleInboundEmail( email, envelope);
            Referral_Contact__c retRc2 = [select id, CPA_Program_status__c from Referral_Contact__c where id =:rc.id limit 1 ]; 
        
            system.Assert(retRc2.CPA_Program_status__c=='Enrolled'); 
       
        system.runAs(u){
            usr.Requested_Invite_Date__c = null;
            update usr; 
        }
            cpaEmailHandler.handleInboundEmail( email, envelope);
            Referral_Contact__c retRc3 = [select id, CPA_Program_status__c from Referral_Contact__c where id =:rc.id limit 1 ]; 
            system.debug('JC retRc3.CPA_Program_status__c' +retRc3.CPA_Program_status__c); 
            system.Assert(retRc3.CPA_Program_status__c==null);         
 
        
    }
    
}    //CPAEmailServiceHandlerTest