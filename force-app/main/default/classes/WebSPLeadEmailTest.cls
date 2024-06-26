/*
 * Test methods
 *
 * History
 * --------
   04/08/2020   Dan Carmen   Increment API Version
   09/20/2023   Dan Carmen   Remove Dupeblocker code.

 */
 
@IsTest(SeeAllData=FALSE)
public class WebSPLeadEmailTest {
    @testSetup
    public static void setupData() {
        LeadCheckOwnerTest.setupSettings();
    } // setupData

    @IsTest(SeeAllData=FALSE)
    static void testBlankEmail(){
        string except;
        messaging.Inboundemail email = new messaging.Inboundemail();
        email.plainTextBody = 'The information contained';
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        webSPLeadEmailHandler wSPLH = new webSPLeadEmailHandler();
        try{
            wSPLH.handleInboundEmail(email, env);
        }
        catch(webSPLeadEmailHandler.SPEmailException ex){
            except=ex.getMessage();
        }
        system.assertEquals('Empty Email Body',except);
        
    }
    
    @IsTest(SeeAllData=FALSE)
    static void testBadXML(){
        string except;
        messaging.Inboundemail email = new messaging.Inboundemail();
        email.plainTextBody = '<node><node>';
        email.plainTextBody += 'The information contained';
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        webSPLeadEmailHandler wSPLH = new webSPLeadEmailHandler();
        try{
            wSPLH.handleInboundEmail(email, env);
        }
        catch(webSPLeadEmailHandler.SPEmailException ex){
            except=ex.getMessage();
        }
        system.assertEquals('Unable to Parse XML',except);
        
    }
    
    @IsTest(SeeAllData=FALSE)
    static void testBasicLeadCreation(){
        Account paychexInc = CreateTestData.createPaychexEmp();
        Contact paychexEmp = paychexInc.Contacts[0];
        paychexEmp.Title = 'Test SurePayroll Title';
        update paychexEmp;
        system.debug('paychexEmp'+paychexEmp);
        //Contact paychexEmp = [Select Id, Email, Name, Prefered_Name__c, LastName, Title from Contact where Title like '%SurePayroll%' and HR_Person_Id__c != null limit 1];
        messaging.Inboundemail email = new messaging.Inboundemail();
        email.plainTextBody = '<node>';
        email.plainTextBody += addXML('surePayrollLeadID','000000');
        email.plainTextBody += addXML('firstname','WebSPLead');
        email.plainTextBody += addXML('lastname','EmailTest');
        email.plainTextBody += addXML('company','WebSPLeadEmailTestCompany');
        email.plainTextBody += addXML('phone','1234567890');
        email.plainTextBody += addXML('mobile','1234567890');
        email.plainTextBody += addXML('email','test@te.st');
        email.plainTextBody += addXML('NumOfEmployees','12');
        email.plainTextBody += addXML('product','HNBF');
        email.plainTextBody += addXML('contactFullName',paychexEmp.Name);
        email.plainTextBody += addXML('contactPhone','1234567890');
        email.plainTextBody += addXML('contactEmail','test@te.st');
        email.plainTextBody += addXML('street','12 Main St');
        email.plainTextBody += addXML('city','Test');
        email.plainTextBody += addXML('state','NY');
        email.plainTextBody += addXML('zip','14543');
        email.plainTextBody += '</node>\r\nThe information contained';
        
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        webSPLeadEmailHandler wSPLH = new webSPLeadEmailHandler();
        wSPLH.handleInboundEmail(email, env);
        
        list<lead> tLead = [Select id, lastName, firstName, Referring_Employee__c, postalCode,RecordTypeId from lead 
                            where company = 'WebSPLeadEmailTestCompany' 
                            and createdDate = TODAY Limit 1];
        
        system.assertEquals('WebSPLead',tLead[0].firstName);
        system.assertEquals('EmailTest',tLead[0].lastName);
        system.assertEquals('14543',tLead[0].postalCode);   
        system.assertEquals(paychexEmp.Id,tLead[0].Referring_Employee__c);
        system.assertEquals(RecordTypeHelper.getRecordType(Label.RT_HNBF_Lead, 'Lead').getRecordTypeId(),tLead[0].RecordTypeId);
        
        messaging.Inboundemail email2 = new messaging.Inboundemail();
        email2.plainTextBody = '<node>';
        email2.plainTextBody += addXML('surePayrollLeadID','000001');
        email2.plainTextBody += addXML('firstname','WebSPLead2');
        email2.plainTextBody += addXML('lastname','EmailTest2');
        email2.plainTextBody += addXML('company','WebSPPayrollLeadEmailTestCompany');
        email2.plainTextBody += addXML('phone','0987654321');
        email2.plainTextBody += addXML('mobile','0987654321');
        email2.plainTextBody += addXML('email','te@s.t');
        email2.plainTextBody += addXML('NumOfEmployees','18');
        email2.plainTextBody += addXML('product','Payroll');
        email2.plainTextBody += addXML('contactFullName',paychexEmp.Name);
        email2.plainTextBody += addXML('contactPhone','0987654321');
        email2.plainTextBody += addXML('contactEmail','te@s.t');
        email2.plainTextBody += addXML('street','21 Not Main St');
        email2.plainTextBody += addXML('city','Test2');
        email2.plainTextBody += addXML('state','NY');
        email2.plainTextBody += addXML('zip','14450');
        email2.plainTextBody += '</node>\r\nThe information contained';
        
        Messaging.InboundEnvelope env2 = new Messaging.InboundEnvelope();
        webSPLeadEmailHandler wSPLH2 = new webSPLeadEmailHandler();
        wSPLH2.handleInboundEmail(email2, env2);
        
        list<lead> tLead2 = [Select id, lastName, firstName, Referring_Employee__c, postalCode,RecordTypeId from lead 
                            where company = 'WebSPPayrollLeadEmailTestCompany' 
                            and createdDate = TODAY Limit 1];
        
        system.assertEquals('WebSPLead2',tLead2[0].firstName);
        system.assertEquals('EmailTest2',tLead2[0].lastName);
        system.assertEquals('14450',tLead2[0].postalCode);   
        system.assertEquals(paychexEmp.Id,tLead2[0].Referring_Employee__c);
        system.assertEquals(RecordTypeHelper.getRecordType(Label.RT_Core_Lead, 'Lead').getRecordTypeId(),tLead2[0].RecordTypeId);
    }
    
    
    @IsTest(SeeAllData=FALSE)
    static void testNoSPIDLeadCreation(){
        messaging.Inboundemail email = new messaging.Inboundemail();
        email.plainTextBody = '<node>';
        email.plainTextBody += addXML('firstname','WebSPLead');
        email.plainTextBody += addXML('lastname','EmailTest');
        email.plainTextBody += addXML('company','WebSPLeadEmailTestCompany');
        email.plainTextBody += addXML('zip','14543');
        email.plainTextBody += '</node>\r\nThe information contained';
        
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        webSPLeadEmailHandler wSPLH = new webSPLeadEmailHandler();
        wSPLH.handleInboundEmail(email, env);
        
        list<lead> tLead = [Select id, lastName, firstName, postalCode from lead 
                            where company = 'WebSPLeadEmailTestCompany' 
                            and createdDate = TODAY Limit 1];
        
        system.assertEquals(0,tLead.size());
    }

    @IsTest(SeeAllData=FALSE)
    static void testZipAssignOwner(){
        SOAREmailHandlerTest.createZipRules();
        list<Zip_Assignment__c> zas =[Select id, user__c 
                                        from Zip_Assignment__c 
                                        where Name = :SOAREmailHandlerTest.ZIP1 
                                        and Sales_Org__c=:UserHelper.SO_HNB
                                        and createdDate = Today Limit 1];
        
        messaging.Inboundemail email = new messaging.Inboundemail();
        email.plainTextBody = '<node>';
        email.plainTextBody += addXML('surePayrollLeadID','000000');
        email.plainTextBody += addXML('firstname','WebSPLead');
        email.plainTextBody += addXML('lastname','EmailTest');
        email.plainTextBody += addXML('company','WebSPLeadEmailTestCompany');
        email.plainTextBody += addXML('zip',SOAREmailHandlerTest.ZIP1);
        email.plainTextBody += '</node>\r\nThe information contained';
        
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        webSPLeadEmailHandler wSPLH = new webSPLeadEmailHandler();
        wSPLH.handleInboundEmail(email, env);
        
        list<lead> tLead = [Select id, ownerId from lead 
                            where company = 'WebSPLeadEmailTestCompany' 
                            and createdDate = TODAY Limit 1];
        system.assertEquals(zas[0].user__c,tLead[0].ownerId);
    }
   
    @IsTest(SeeAllData=false)
    static void testDuplicateLead(){
       
        Schema.RecordTypeInfo leadHRSRT = RecordTypeHelper.getRecordType('HNBF Lead Record Type', 'Lead'); //Get the HRS Record Type.
        lead testLead1 = new lead(company = 'WebSPLeadEmailTestCompany'
                                  , SurePayroll_ID__c = '000000'
                                  , postalcode = '14514'
                                  , lastName='TestLastName'
                                  , firstName = 'TestFirstName'
                                  , RecordTypeId = leadHRSRT.getRecordTypeId());
        
        insert testLead1;
        
        messaging.Inboundemail email = new messaging.Inboundemail();
        email.plainTextBody = '<node>';
        email.plainTextBody += addXML('surePayrollLeadID',testLead1.SurePayroll_ID__c);
        email.plainTextBody += addXML('firstname',testLead1.FirstName);
        email.plainTextBody += addXML('lastname',testLead1.LastName);
        email.plainTextBody += addXML('company',testLead1.company);
        email.plainTextBody += addXML('zip',testLead1.PostalCode);
        email.plainTextBody += '</node>\r\nThe information contained';
        
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        webSPLeadEmailHandler wSPLH = new webSPLeadEmailHandler();
        wSPLH.handleInboundEmail(email, env);
        
        list<lead> tLead = [Select Id, ownerId, Status, recordType.name, company
                            from lead 
                            where company = :testLead1.company
                            and recordType.name = 'HNBF Lead Record Type'
                            and createdDate = TODAY
                            Order by CreatedDate DESC
                            Limit 1];

        // TODO - have to fix this assertion!!
        //system.assertEquals('Already Contacted/Duplicate',tLead[0].Status);
        
    }    
    
 
 /*   static testMethod void testDuplicateAccount(){
        Schema.RecordTypeInfo acctCorert = RecordTypeHelper.getRecordType('Core Account Record Type', 'Account');  //Get the Core Record Type.
        account testAccount1 = [select name, billingstreet, billingcity, billingstate, billingpostalcode, phone 
                                from account
                                where name = 'Paychex'
                                and billingstreet != NULL
                                and billingCity != NULL
                                and billingPostalCode != NULL
                                and Phone != NULL 
                                and recordtypeId = :acctCorert.getRecordTypeId()
                                order by CreatedDate DESC
                                limit 1][0];
        
        messaging.Inboundemail email = new messaging.Inboundemail();
        email.plainTextBody = '<node>';
        email.plainTextBody += addXML('surePayrollLeadID','000000');
        email.plainTextBody += addXML('firstname','WebSPLead');
        email.plainTextBody += addXML('lastname','EmailTest');
        email.plainTextBody += addXML('company',testAccount1.Name);
        email.plainTextBody += addXML('street',testAccount1.BillingStreet);
        email.plainTextBody += addXML('city',testAccount1.BillingCity);
        email.plainTextBody += addXML('state',testAccount1.BillingState);
        email.plainTextBody += addXML('zip',testAccount1.BillingPostalCode);
        email.plainTextBody += addXML('phone',testAccount1.Phone);
        email.plainTextBody += '</node>\r\nThe information contained';
        
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        webSPLeadEmailHandler wSPLH = new webSPLeadEmailHandler();
        wSPLH.handleInboundEmail(email, env);
        
        list<lead> tLead = [Select id, ownerId, Status, recordtype.name 
                            from lead 
                            where company = :testAccount1.name
                            and postalCode = :testAccount1.BillingPostalCode
                            and street = :testAccount1.BillingStreet
                            and city = :testAccount1.BillingCity
                            and phone = :testAccount1.Phone
                            and firstName = 'WebSPLead'
                            and lastName = 'EmailTest'
                            and recordType.name = 'HRS Lead Record Type'
                            and createdDate = TODAY
                            Order by CreatedDate DESC
                            limit 1];         
        system.assertEquals('Already Contacted/Duplicate',tLead[0].Status);
    }
*/    
    
    static string addXML(string tag, string content){
        return '<' + tag + '>' + content + '</' + tag + '>\r\n';
    }
}