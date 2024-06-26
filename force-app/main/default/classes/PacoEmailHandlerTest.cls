/*

05/17/2023  Dan Carmen       Added CEID/CAID

*/
@IsTest
public with sharing class PacoEmailHandlerTest {
    
    static testMethod void testBlankEmail(){
        string except;
        messaging.Inboundemail email = new messaging.Inboundemail();
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        PacoEmailHandler pEH = new PacoEmailHandler();
        try{
            pEH.handleInboundEmail(email, env);
        }
        catch(PacoEmailHandler.PACOEmailHandlerException ex){
            except=ex.getMessage();
        }
        //system.assertEquals('Empty Email Body',except);
        
    }
    
    static testMethod void testBadXML(){
        string except;
        messaging.Inboundemail email = new messaging.Inboundemail();
        email.htmlBody = '<node><junk></node>';
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        PacoEmailHandler pEH = new PacoEmailHandler();
        try{
            pEH.handleInboundEmail(email, env);
        }
        catch(PacoEmailHandler.PACOEmailHandlerException ex){
            except=ex.getMessage();
        }
        //system.assertEquals(true,except.startsWith('Unable to Parse XML'));
        
    }
    
    static testMethod void testAssignedStatus(){
        Id opptyId = RefCorePayUpdateOpptyTest.createSoldOppty();
        messaging.Inboundemail email = new messaging.Inboundemail();
        email.htmlBody = '<node>';
        email.htmlBody += addXML('opportunityId',opptyId);
        email.htmlBody += addXML('clientNumber','901-1111');
        email.htmlBody += addXML('ownerEmail','jstouffer@paychex.com');
        email.htmlBody += addXML('status','Assigned');
        email.htmlBody += addXML('dateToUpdate','11/12/2015');
        email.htmlBody += '</node>\r\nThe information contained';

        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        PacoEmailHandler pEH = new PacoEmailHandler();
        pEH.handleInboundEmail(email, env);
        
        Reference_Core_Payroll__c rcp1 = [Select Current_Step__c, Client_Load_Received__c  from Reference_Core_Payroll__c 
                            where Opportunity_Lookup__c = :opptyId Limit 1];
        
        //system.assert(rcp1.Client_Load_Received__c);
        //system.assertEquals('Client Received',rcp1.Current_Step__c);  
    }
    
    static testMethod void testCompletedStatus(){
        Id opptyId = RefCorePayUpdateOpptyTest.createSoldOppty();
        messaging.Inboundemail email = new messaging.Inboundemail();
        email.htmlBody = '<node>';
        email.htmlBody += addXML('opportunityId',opptyId);
        email.htmlBody += addXML('clientNumber','901-1111');
        email.htmlBody += addXML('ownerEmail','jstouffer@paychex.com');
        email.htmlBody += addXML('status','Complete');
        email.htmlBody += addXML('dateToUpdate','11/12/2015');
        email.htmlBody += '</node>\r\nThe information contained';

        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        PacoEmailHandler pEH = new PacoEmailHandler();
        pEH.handleInboundEmail(email, env);
        
        Reference_Core_Payroll__c rcp1 = [Select Current_Step__c, Client_Load_Complete__c from Reference_Core_Payroll__c 
                            where Opportunity_Lookup__c = :opptyId Limit 1];
        //system.assert(rcp1.Client_Load_Complete__c);
        //system.assertEquals('(2 of 4) Client Load Complete',rcp1.Current_Step__c);  
    }
    
    static testMethod void testRanStatus(){
        Id opptyId = RefCorePayUpdateOpptyTest.createSoldOppty();
        messaging.Inboundemail email = new messaging.Inboundemail();
        email.htmlBody = '<node>';
        email.htmlBody += addXML('opportunityId',opptyId);
        email.htmlBody += addXML('clientNumber','901-1111');
        email.htmlBody += addXML('ownerEmail','jstouffer@paychex.com');
        email.htmlBody += addXML('status','Ran');
        email.htmlBody += addXML('dateToUpdate','11/12/2015');
        email.htmlBody += '</node>\r\nThe information contained';

        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        PacoEmailHandler pEH = new PacoEmailHandler();
        pEH.handleInboundEmail(email, env);
        
        Reference_Core_Payroll__c rcp1 = [Select Current_Step__c  from Reference_Core_Payroll__c 
                            where Opportunity_Lookup__c = :opptyId Limit 1];

        //system.assertEquals('(3 of 4) First Payroll Ran',rcp1.Current_Step__c);  
    }
    
    static testMethod void testRanStatus2(){
        Id opptyId = RefCorePayUpdateOpptyTest.createSoldOppty();
        messaging.Inboundemail email = new messaging.Inboundemail();
        email.htmlBody = '<node>';
        email.htmlBody += addXML('opportunityId',opptyId);
        email.htmlBody += addXML('clientNumber','901-1111');
        email.htmlBody += addXML('ceid','00H2A1IULFS7P13O006M');
        email.htmlBody += addXML('caid','00HWYNTDLFS7P1RU4W56');
        email.htmlBody += addXML('ownerEmail','jstouffer@paychex.com');
        email.htmlBody += addXML('status','Ran');
        email.htmlBody += addXML('dateToUpdate','11/12/2015');
        email.htmlBody += '</node>\r\nThe information contained';

        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        PacoEmailHandler pEH = new PacoEmailHandler();
        pEH.handleInboundEmail(email, env);
        
        Reference_Core_Payroll__c rcp1 = [Select Current_Step__c, New_Prospect_Client_Number__c, CEID__c, CAID__c  from Reference_Core_Payroll__c 
                            where Opportunity_Lookup__c = :opptyId Limit 1];

        //Assert.areEqual('(3 of 4) First Payroll Ran',rcp1.Current_Step__c);  
        //Assert.areEqual('901-1111',rcp1.New_Prospect_Client_Number__c);  
        //Assert.areEqual('00H2A1IULFS7P13O006M',rcp1.CEID__c);  
        //Assert.areEqual('00HWYNTDLFS7P1RU4W56',rcp1.CAID__c);  
    } // testRanStatus2
    
    
    static string addXML(string tag, string content){
        return '<' + tag + '>' + content + '</' + tag + '>\r\n';
    }
    
} // class PacoEmailHandlerTest