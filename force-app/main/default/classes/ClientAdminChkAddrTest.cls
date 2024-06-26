/* The methods to test ClientAdminChkAddr class and ClientAdminChkAddrTypes trigger.
   
  History
  -------
  05/01/2009 Dan Carmen   Created
  04/20/2011 Tom Muskatevc Added MMS to test  
  01/15/2013 Dan Carmen   Changed to use Contact Types field
  04/09/2013 Dan Carmen   Changed back to use Address Types until code can be updated
  11/13/2013 Dan Carmen   Change back to use Contact Types field
 */
@isTest
private class ClientAdminChkAddrTest {

    private static Client_Admin__c getCA(Id id) {
       return [select id, name, ADM401__c, Envelopes__c, HRS125__c, HRSADM__c, TAA__c, MMS__c
                     ,Premier_Cobra__c, Premier_Compliance__c, Premier_EAP__c, Premier_Handbooks__c
                     ,Premier_Payroll__c, Premier_Safety__c, Premier_Survey__c
                     ,Premier_Mailing_Labels__c,Premier_Posters__c,Premier_Seminars__c,Premier_Welcome_Letter__c
                     ,Contact_Types__c 
                 from Client_Admin__c where id=:id];
    } // getCA
    
    static testMethod void testAddrTypes() {
       Account a1 = new Account(name='test acct');
       insert a1;
       //****** test for all types on an insert   ****
       Client_Admin__c ca1 = new Client_Admin__c(name='test1',Contact_Types__c='401ADM;ENVELOPES;HRS125;HRSADM;TIB;TLO;MMS;CBR;CI;EAP;HBK;PAYROLL;SAFETY_LOSS;SURVEY;COBRA_LETTER;PST;SEM;WELCOME_LETTER',account__c=a1.id);
       insert ca1;
       ca1 = getCA(ca1.Id);
       System.assertEquals(true, ca1.ADM401__c);
       System.assertEquals(true, ca1.Envelopes__c);
       System.assertEquals(true, ca1.HRS125__c);
       System.assertEquals(true, ca1.HRSADM__c);
       System.assertEquals(true, ca1.TAA__c);
       System.assertEquals(true, ca1.MMS__c);
              
       System.assertEquals(true, ca1.Premier_Cobra__c);
       System.assertEquals(true, ca1.Premier_Compliance__c);
       System.assertEquals(true, ca1.Premier_EAP__c);
       System.assertEquals(true, ca1.Premier_Handbooks__c);
       System.assertEquals(true, ca1.Premier_Payroll__c);
       System.assertEquals(true, ca1.Premier_Safety__c);
       System.assertEquals(true, ca1.Premier_Survey__c);
       
       System.assertEquals(true, ca1.Premier_Mailing_Labels__c);
       System.assertEquals(true, ca1.Premier_Posters__c);
       System.assertEquals(true, ca1.Premier_Seminars__c);
       System.assertEquals(true, ca1.Premier_Welcome_Letter__c);
       
       //****** remove envelopes *****
       ca1.Contact_Types__c = '401ADM;HRS125;HRSADM;TIB;TLO;MMS';
       update ca1;
       ca1 = getCA(ca1.Id);
       System.assertEquals(true, ca1.ADM401__c);
       System.assertEquals(false, ca1.Envelopes__c);
       System.assertEquals(true, ca1.HRS125__c);
       System.assertEquals(true, ca1.HRSADM__c);
       System.assertEquals(true, ca1.TAA__c);
       System.assertEquals(true, ca1.MMS__c);

       
       System.assertEquals(false, ca1.Premier_Cobra__c);
       System.assertEquals(false, ca1.Premier_Compliance__c);
       System.assertEquals(false, ca1.Premier_EAP__c);
       System.assertEquals(false, ca1.Premier_Handbooks__c);
       System.assertEquals(false, ca1.Premier_Payroll__c);
       System.assertEquals(false, ca1.Premier_Safety__c);
       System.assertEquals(false, ca1.Premier_Survey__c);
       
       System.assertEquals(false, ca1.Premier_Mailing_Labels__c);
       System.assertEquals(false, ca1.Premier_Posters__c);
       System.assertEquals(false, ca1.Premier_Seminars__c);
       System.assertEquals(false, ca1.Premier_Welcome_Letter__c);
       
       //****** remove 401ADM, TLO (TAA should still be true because TIB is still there)  ****
       ca1.Contact_Types__c = 'HRS125;HRSADM;TIB;MMS';
       update ca1;
       ca1 = getCA(ca1.Id);
       System.assertEquals(false, ca1.ADM401__c);
       System.assertEquals(false, ca1.Envelopes__c);
       System.assertEquals(true, ca1.HRS125__c);
       System.assertEquals(true, ca1.HRSADM__c);
       System.assertEquals(true, ca1.TAA__c);
       System.assertEquals(true, ca1.MMS__c);
       
       System.assertEquals(false, ca1.Premier_Cobra__c);
       System.assertEquals(false, ca1.Premier_Compliance__c);
       System.assertEquals(false, ca1.Premier_EAP__c);
       System.assertEquals(false, ca1.Premier_Handbooks__c);
       System.assertEquals(false, ca1.Premier_Payroll__c);
       System.assertEquals(false, ca1.Premier_Safety__c);
       System.assertEquals(false, ca1.Premier_Survey__c);

       System.assertEquals(false, ca1.Premier_Mailing_Labels__c);
       System.assertEquals(false, ca1.Premier_Posters__c);
       System.assertEquals(false, ca1.Premier_Seminars__c);
       System.assertEquals(false, ca1.Premier_Welcome_Letter__c);

       //****** only envelopes and hrs125   ****
       ca1.Contact_Types__c = 'ENVELOPES;HRS125';
       update ca1;
       ca1 = getCA(ca1.Id);
       System.assertEquals(false, ca1.ADM401__c);
       System.assertEquals(true, ca1.Envelopes__c);
       System.assertEquals(true, ca1.HRS125__c);
       System.assertEquals(false, ca1.HRSADM__c);
       System.assertEquals(false, ca1.TAA__c);
       System.assertEquals(false, ca1.MMS__c);

       System.assertEquals(false, ca1.Premier_Cobra__c);
       System.assertEquals(false, ca1.Premier_Compliance__c);
       System.assertEquals(false, ca1.Premier_EAP__c);
       System.assertEquals(false, ca1.Premier_Handbooks__c);
       System.assertEquals(false, ca1.Premier_Payroll__c);
       System.assertEquals(false, ca1.Premier_Safety__c);
       System.assertEquals(false, ca1.Premier_Survey__c);
       
       System.assertEquals(false, ca1.Premier_Mailing_Labels__c);
       System.assertEquals(false, ca1.Premier_Posters__c);
       System.assertEquals(false, ca1.Premier_Seminars__c);
       System.assertEquals(false, ca1.Premier_Welcome_Letter__c);

       //****** null out address types  ****
       ca1.Contact_Types__c = null;
       update ca1;
       ca1 = getCA(ca1.Id);
       System.assertEquals(false, ca1.ADM401__c);
       System.assertEquals(false, ca1.Envelopes__c);
       System.assertEquals(false, ca1.HRS125__c);
       System.assertEquals(false, ca1.HRSADM__c);
       System.assertEquals(false, ca1.TAA__c);
       System.assertEquals(false, ca1.MMS__c);

       System.assertEquals(false, ca1.Premier_Cobra__c);
       System.assertEquals(false, ca1.Premier_Compliance__c);
       System.assertEquals(false, ca1.Premier_EAP__c);
       System.assertEquals(false, ca1.Premier_Handbooks__c);
       System.assertEquals(false, ca1.Premier_Payroll__c);
       System.assertEquals(false, ca1.Premier_Safety__c);
       System.assertEquals(false, ca1.Premier_Survey__c);
       
       System.assertEquals(false, ca1.Premier_Mailing_Labels__c);
       System.assertEquals(false, ca1.Premier_Posters__c);
       System.assertEquals(false, ca1.Premier_Seminars__c);
       System.assertEquals(false, ca1.Premier_Welcome_Letter__c);

       //****** only TLO  ****
       ca1.Contact_Types__c = 'TLO';
       update ca1;
       ca1 = getCA(ca1.Id);
       System.assertEquals(false, ca1.ADM401__c);
       System.assertEquals(false, ca1.Envelopes__c);
       System.assertEquals(false, ca1.HRS125__c);
       System.assertEquals(false, ca1.HRSADM__c);
       System.assertEquals(true, ca1.TAA__c);
       System.assertEquals(false, ca1.MMS__c);

       
       System.assertEquals(false, ca1.Premier_Cobra__c);
       System.assertEquals(false, ca1.Premier_Compliance__c);
       System.assertEquals(false, ca1.Premier_EAP__c);
       System.assertEquals(false, ca1.Premier_Handbooks__c);
       System.assertEquals(false, ca1.Premier_Payroll__c);
       System.assertEquals(false, ca1.Premier_Safety__c);
       System.assertEquals(false, ca1.Premier_Survey__c);
       
       System.assertEquals(false, ca1.Premier_Mailing_Labels__c);
       System.assertEquals(false, ca1.Premier_Posters__c);
       System.assertEquals(false, ca1.Premier_Seminars__c);
       System.assertEquals(false, ca1.Premier_Welcome_Letter__c);

       //****** only Handbooks and Safety ****
       ca1.Contact_Types__c = 'HBK;SAFETY_LOSS';
       update ca1;
       ca1 = getCA(ca1.Id);
       System.assertEquals(false, ca1.ADM401__c);
       System.assertEquals(false, ca1.Envelopes__c);
       System.assertEquals(false, ca1.HRS125__c);
       System.assertEquals(false, ca1.HRSADM__c);
       System.assertEquals(false, ca1.TAA__c);
       System.assertEquals(false, ca1.MMS__c);
       
       System.assertEquals(false, ca1.Premier_Cobra__c);
       System.assertEquals(false, ca1.Premier_Compliance__c);
       System.assertEquals(false, ca1.Premier_EAP__c);
       System.assertEquals(true, ca1.Premier_Handbooks__c);
       System.assertEquals(false, ca1.Premier_Payroll__c);
       System.assertEquals(true, ca1.Premier_Safety__c);
       System.assertEquals(false, ca1.Premier_Survey__c);
       
       System.assertEquals(false, ca1.Premier_Mailing_Labels__c);
       System.assertEquals(false, ca1.Premier_Posters__c);
       System.assertEquals(false, ca1.Premier_Seminars__c);
       System.assertEquals(false, ca1.Premier_Welcome_Letter__c);

       //****** only Survey and Payroll  ****
       ca1.Contact_Types__c = 'SURVEY;PAYROLL';
       update ca1;
       ca1 = getCA(ca1.Id);
       System.assertEquals(false, ca1.ADM401__c);
       System.assertEquals(false, ca1.Envelopes__c);
       System.assertEquals(false, ca1.HRS125__c);
       System.assertEquals(false, ca1.HRSADM__c);
       System.assertEquals(false, ca1.TAA__c);
       System.assertEquals(false, ca1.MMS__c);
       
       System.assertEquals(false, ca1.Premier_Cobra__c);
       System.assertEquals(false, ca1.Premier_Compliance__c);
       System.assertEquals(false, ca1.Premier_EAP__c);
       System.assertEquals(false, ca1.Premier_Handbooks__c);
       System.assertEquals(true, ca1.Premier_Payroll__c);
       System.assertEquals(false, ca1.Premier_Safety__c);
       System.assertEquals(true, ca1.Premier_Survey__c);
       
       System.assertEquals(false, ca1.Premier_Mailing_Labels__c);
       System.assertEquals(false, ca1.Premier_Posters__c);
       System.assertEquals(false, ca1.Premier_Seminars__c);
       System.assertEquals(false, ca1.Premier_Welcome_Letter__c);

       //****** only Mailing labels, posters, seminars, welcome letter  ****
       ca1.Contact_Types__c = 'COBRA_LETTER;PST;SEM;WELCOME_LETTER';
       update ca1;
       ca1 = getCA(ca1.Id);
       System.assertEquals(false, ca1.ADM401__c);
       System.assertEquals(false, ca1.Envelopes__c);
       System.assertEquals(false, ca1.HRS125__c);
       System.assertEquals(false, ca1.HRSADM__c);
       System.assertEquals(false, ca1.TAA__c);
       System.assertEquals(false, ca1.MMS__c);
       
       System.assertEquals(false, ca1.Premier_Cobra__c);
       System.assertEquals(false, ca1.Premier_Compliance__c);
       System.assertEquals(false, ca1.Premier_EAP__c);
       System.assertEquals(false, ca1.Premier_Handbooks__c);
       System.assertEquals(false, ca1.Premier_Payroll__c);
       System.assertEquals(false, ca1.Premier_Safety__c);
       System.assertEquals(false, ca1.Premier_Survey__c);
       
       System.assertEquals(true, ca1.Premier_Mailing_Labels__c);
       System.assertEquals(true, ca1.Premier_Posters__c);
       System.assertEquals(true, ca1.Premier_Seminars__c);
       System.assertEquals(true, ca1.Premier_Welcome_Letter__c);

    } // testAddrTypes
    
} // class ClientAdminChkAddrTest