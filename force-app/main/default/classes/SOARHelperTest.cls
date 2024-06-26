/*
 *
 * History
 * --------
   01/11/2016 Cindy Freeman     rewritten to use custom setting instead of Product Mapping object
   03/17/2022 Dan Carmen        Added extra check for parent owners
   07/25/2022 Carrie Marciano   Added testblankReferringEmp to increase test coverage
   12/29/2022 Dan Carmen        Changed to use SF Duplicated Management
   07/24/2023 Carrie Marciano	added tests to cover changed search for acct/contact to use createAcct and createContact both use duplicateHelper
   09/28/2023 Dan Carmen        Comment out remaining Dupeblocker code.
   03/26/2024 Carrie Marciano	added testNoExistingContact to ensure the Sales Contact checkbox is set when creating a contact to be related to the SOAR Referral

*/ 
@isTest
public class SOARHelperTest {
    
    @testSetup
    public static void setupData() {
        HoldOutExpirationMethodsTest.populateSetting();

    } // setupData
    
    /* SFDC-2703 (US2)  Get Soar Product Mapping Without AddOnClient Using Aggregate Employee Count */
    @isTest
    static void  testSPMWithParentAcctUsingAggregateEmpCount()	{
        List<SoarProductMapping__c> spmList = new List<SoarProductMapping__c>();
        
        SoarProductMapping__c spm = new SoarProductMapping__c(Name='Prod01',AdvClient__c=true, Emp_Count_Min__c=0,Emp_Count_Max__c=49,Product__c='New Client',Sales_Org__c='PAY');
        spmList.add(spm);
        spm = new SoarProductMapping__c(Name='Prod02',AdvClient__c=false, Emp_Count_Min__c=0,Emp_Count_Max__c=49,Product__c='New Client',Sales_Org__c='PAY'); 
        spmList.add(spm);
        spm = new SoarProductMapping__c(Name='Prod03',AdvClient__c=true, Emp_Count_Min__c=50,Emp_Count_Max__c=999999,Product__c='New Client',Sales_Org__c='MMS'); 
        spmList.add(spm);
        spm = new SoarProductMapping__c(Name='Prod04',AdvClient__c=false, Emp_Count_Min__c=50,Emp_Count_Max__c=999999,Product__c='New Client',Sales_Org__c='MMS'); 
        spmList.add(spm);
        spm = new SoarProductMapping__c(Name='Prod05',AdvClient__c=false, Product__c='New Client',Sales_Org__c='MMS',Platform__c='MMS - 50+Ees'); 
        spmList.add(spm);
        spm = new SoarProductMapping__c(Name='Prod06',AdvClient__c=false, Product__c='New Client',Sales_Org__c='PAS',Platform__c='ASO/PEO'); 
        spmList.add(spm);
        spm = new SoarProductMapping__c(Name='Prod07',AdvClient__c=false, Product__c='401(k)',Sales_Org__c='HRS'); 
        spmList.add(spm);
        
        PaychexSettings__c pxs = new PaychexSettings__c (name='SoarForwardErrorEmail',IsActive__c = true , Attribute1__c ='jcartwright@paychex.com'); 
        insert pxs; 
        // Use the following User if no ZipTerritory (ZipAssignment is setup) for ZipSegment or Sales Org
        User coreAdminUser = [Select Id, Name, HR_Person_ID__c from User where Profile.Name like 'Core Zone Admin%' and IsActive = true limit 1];        
        spm = new SoarProductMapping__c(Name='Prod17',Default_Rep__c=coreAdminUser.Name, Default_Rep_HR_Person_ID__c=coreAdminUser.HR_Person_ID__c,Product__c='Unknown Rep',Sales_Org__c='PAY');         
        spmList.add(spm);
        upsert spmList;
                
        User runningUser = [Select Id, FirstName, LastName, Email, HR_Person_Id__c from User where Profile.Name=:Utilities.PROF_SYS_ADMIN and IsActive=true and HR_Person_Id__c != null limit 1];

        Account payxAcct = new Account(Name = UserHelper.PAYCHEX_COMP, NumberOfEmployees=40, Bis_ID__c=464646, RecordTypeId='012500000000nCjAAI');
        insert payxAcct;

        Contact payxEmp = new Contact(FirstName=runningUser.FirstName, LastName=runningUser.LastName, AccountId=payxAcct.Id, 
                              HR_Person_Id__c=runningUser.HR_Person_Id__c, Email=runningUser.Email);      
        insert payxEmp;
                
        String soarMsg = '<SOARINFORMATION>\r  <EEEmail>'+ runningUser.Email +'</EEEmail>\r <PersonID>'+ runningUser.HR_Person_Id__c+'</PersonID>\r';
        soarMsg += '<ID></ID>\r <BIS></BIS>\r <CostCenter>0027</CostCenter>\r';
        soarMsg += '<ClientNumber></ClientNumber>\r <CompanyName>Test Method New Company Client Name</CompanyName>\r <Address>1270 Creekbend Lane</Address>\r';
        soarMsg += '<City>Webster</City>\r <State>NY</State>\r <ZipCode>14625</ZipCode>\r <EmployeeCount>36</EmployeeCount>\r <Product>New Client</Product>\r';
        soarMsg += '<FirstName>Jeff</FirstName>\r <LastName>Elliott</LastName>\r <PhoneNumber>585-222-3434</PhoneNumber>\r';
        soarMsg += '<Platform>None</Platform><AddOnClient>No</AddOnClient><AdvClient>No</AdvClient>';
        soarMsg += '<Notes>Big Notes<email address></Notes><SOARID>10</SOARID><Region>1</Region>\r </SOARINFORMATION>';         
        
        PartnerReferral__c partRef = new PartnerReferral__c(Source__c='SOAR', Comments__c='Pending', Description__c=soarMsg);
        insert partRef;
        
        SOARHelper.SoarRef sr = new SOARHelper.SoarRef();
        sr = SOARHelper.parseXml(soarMsg);
        sr.partRefId = partRef.id;
        
		List<SOARHelper.SoarRef> srList = new List<SOARHelper.SoarRef>();
		srList.add(sr);
        
        System.runAs(runningUser) {                    
            Test.startTest();
            
            SOARHelper.processSoarRef(srList);
            System.assertNotEquals(null, SOARHelper.spm);
            System.assertEquals('Prod02', SOARHelper.spm.Name, 'Incorrect Product Name.');

            Test.stopTest();
        }        
    }

    /* SFDC-2703 (US2) Get Soar Product Mapping With AddOnClient Using Aggregate Employee Count*/
    @isTest
    static void testSPMWithChildAcctUsingAggregateEmpCount()	{
        List<SoarProductMapping__c> spmList = new List<SoarProductMapping__c>();
        
        SoarProductMapping__c spm = new SoarProductMapping__c(Name='Prod01',AdvClient__c=true, Emp_Count_Min__c=0,Emp_Count_Max__c=49,Product__c='New Client',Sales_Org__c='PAY');
        spmList.add(spm);
        spm = new SoarProductMapping__c(Name='Prod02',AdvClient__c=false, Emp_Count_Min__c=0,Emp_Count_Max__c=49,Product__c='New Client',Sales_Org__c='PAY'); 
        spmList.add(spm);
        spm = new SoarProductMapping__c(Name='Prod03',AdvClient__c=true, Emp_Count_Min__c=50,Emp_Count_Max__c=999999,Product__c='New Client',Sales_Org__c='MMS'); 
        spmList.add(spm);
        spm = new SoarProductMapping__c(Name='Prod04',AdvClient__c=false, Emp_Count_Min__c=50,Emp_Count_Max__c=999999,Product__c='New Client',Sales_Org__c='MMS'); 
        spmList.add(spm);
        spm = new SoarProductMapping__c(Name='Prod05',AdvClient__c=false, Product__c='New Client',Sales_Org__c='MMS',Platform__c='MMS - 50+Ees'); 
        spmList.add(spm);
        spm = new SoarProductMapping__c(Name='Prod06',AdvClient__c=false, Product__c='New Client',Sales_Org__c='PAS',Platform__c='ASO/PEO'); 
        spmList.add(spm);
        spm = new SoarProductMapping__c(Name='Prod07',AdvClient__c=false, Product__c='401(k)',Sales_Org__c='HRS'); 
        spmList.add(spm);
        
        // Use the following User if no ZipTerritory (ZipAssignment is setup) for ZipSegment or Sales Org
        User coreAdminUser = [Select Id, Name, HR_Person_ID__c from User where Profile.Name like 'Core Zone Admin%' and IsActive = true limit 1];        
        spm = new SoarProductMapping__c(Name='Prod17',Default_Rep__c=coreAdminUser.Name, Default_Rep_HR_Person_ID__c=coreAdminUser.HR_Person_ID__c,Product__c='Unknown Rep',Sales_Org__c='PAY');         
        spmList.add(spm);
        upsert spmList;
                
        User runningUser = [Select Id, FirstName, LastName, Email, HR_Person_Id__c from User where Profile.Name=:Utilities.PROF_SYS_ADMIN and IsActive=true and HR_Person_Id__c != null limit 1];

        Account payxAcct = new Account(Name = UserHelper.PAYCHEX_COMP, NumberOfEmployees=40, Bis_ID__c=464646, RecordTypeId='012500000000nCjAAI');
        insert payxAcct;

        Contact payxEmp = new Contact(FirstName=runningUser.FirstName, LastName=runningUser.LastName, AccountId=payxAcct.Id, 
                              HR_Person_Id__c=runningUser.HR_Person_Id__c, Email=runningUser.Email);      
        insert payxEmp;
                
        String soarMsg = '<SOARINFORMATION>\r  <EEEmail>'+ runningUser.Email +'</EEEmail>\r <PersonID>'+ runningUser.HR_Person_Id__c+'</PersonID>\r';
        soarMsg += '<ID>' + payxAcct.Id + '</ID>\r <BIS>' + payxAcct.Bis_ID__c + '</BIS>\r <CostCenter>0027</CostCenter>\r';
        soarMsg += '<ClientNumber></ClientNumber>\r <CompanyName>Test Method New Company Client Name</CompanyName>\r <Address>1270 Creekbend Lane</Address>\r';
        soarMsg += '<City>Webster</City>\r <State>NY</State>\r <ZipCode>14625</ZipCode>\r <EmployeeCount>36</EmployeeCount>\r <Product>New Client</Product>\r';
        soarMsg += '<FirstName>Jeff</FirstName>\r <LastName>Elliott</LastName>\r <PhoneNumber>585-222-3434</PhoneNumber>\r';
        soarMsg += '<Platform>None</Platform><AddOnClient>Yes</AddOnClient><AdvClient>No</AdvClient>';
        soarMsg += '<Notes>Big Notes<email address></Notes><SOARID>10</SOARID><Region>1</Region>\r </SOARINFORMATION>';         
        
        PartnerReferral__c partRef = new PartnerReferral__c(Source__c='SOAR', Comments__c='Pending', Description__c=soarMsg);
        insert partRef;
        
        SOARHelper.SoarRef sr = new SOARHelper.SoarRef();
        sr = SOARHelper.parseXml(soarMsg);
        sr.partRefId = partRef.id;
        
		List<SOARHelper.SoarRef> srList = new List<SOARHelper.SoarRef>();
		srList.add(sr);
        
        System.runAs(runningUser) {                    
            Test.startTest();
            
            SOARHelper.processSoarRef(srList);
            System.assertNotEquals(null, SOARHelper.spm);
            System.assertEquals('Prod04', SOARHelper.spm.Name, 'Incorrect Product Name.');

            Test.stopTest();
        }        
    }

    /* SFDC-2703 (US4) Get Soar Product Mapping Based on Employee Count (Account Type is not PEO Client).*/
    @isTest
    static void  testAssignSPMDefaultRepToOpportunityOnEmployeeCount()	{
        List<SoarProductMapping__c> spmList = new List<SoarProductMapping__c>();
        
        SoarProductMapping__c spm;
        spm = new SoarProductMapping__c(Name='Prod354',AdvClient__c=false, Emp_Count_Min__c=0,Emp_Count_Max__c=49,Product__c='Paychex Flex Time Essentials',Account_Type__c='PEO Client',
                                        Sales_Org__c='PAY',Default_Rep__c='Jahmekah Webbe',Default_Rep_HR_Person_ID__c='1253982',ZipSegment__c='TIER1',Opportunity_Type__c='Ancillary');
        spmList.add(spm);
        
        spm = new SoarProductMapping__c(Name='Prod355',AdvClient__c=false, Emp_Count_Min__c=50,Emp_Count_Max__c=999999,Product__c='Paychex Flex Time Essentials',
                                        Sales_Org__c='MMS',Default_Rep__c='Jahmekah Webbe',Default_Rep_HR_Person_ID__c='1253982',ZipSegment__c='TIER1',Opportunity_Type__c='Ancillary');
        spmList.add(spm);

        spm = new SoarProductMapping__c(Name='Prod356',AdvClient__c=false, Emp_Count_Min__c=50,Emp_Count_Max__c=999999,Product__c='Paychex Flex Time',Account_Type__c='PEO Client',
                                        Sales_Org__c='MMS',Default_Rep__c='Jahmekah Webbe',Default_Rep_HR_Person_ID__c='1253982',ZipSegment__c='TIER1',Opportunity_Type__c='Ancillary');
        spmList.add(spm);

        spm = new SoarProductMapping__c(Name='Prod357',AdvClient__c=false, Emp_Count_Min__c=50,Emp_Count_Max__c=999999,Product__c='Paychex TrueShift Time Clock',Account_Type__c='PEO Client',
                                        Sales_Org__c='MMS',Default_Rep__c='Jahmekah Webbe',Default_Rep_HR_Person_ID__c='1253982',ZipSegment__c='TIER1',Opportunity_Type__c='Ancillary');
        spmList.add(spm);
                
        spm = new SoarProductMapping__c(Name='Prod01',AdvClient__c=true, Emp_Count_Min__c=0,Emp_Count_Max__c=49,Product__c='New Client',Sales_Org__c='PAY');
        spmList.add(spm);
        spm = new SoarProductMapping__c(Name='Prod03',AdvClient__c=true, Emp_Count_Min__c=50,Emp_Count_Max__c=999999,Product__c='New Client',Sales_Org__c='MMS'); 
        spmList.add(spm);
        
        // Use the following User if no ZipTerritory (ZipAssignment is setup) for ZipSegment or Sales Org
        User coreAdminUser = [Select Id, Name, HR_Person_ID__c from User where Profile.Name like 'Core Zone Admin%' and IsActive = true limit 1];        
        spm = new SoarProductMapping__c(Name='Prod17',Default_Rep__c=coreAdminUser.Name, Default_Rep_HR_Person_ID__c=coreAdminUser.HR_Person_ID__c,Product__c='Unknown Rep',Sales_Org__c='PAY');         
        spmList.add(spm);

        insert spmList;        
        
        User runningUser = [Select Id, FirstName, LastName, Email, HR_Person_Id__c from User where Profile.Name=:Utilities.PROF_SYS_ADMIN and IsActive=true and HR_Person_Id__c != null limit 1];

        Account payxAcct = new Account(Name = UserHelper.PAYCHEX_COMP, NumberOfEmployees=40, Bis_ID__c=464646, RecordTypeId='012500000000nCjAAI', Type='Not PEO Client');
        insert payxAcct;

        Contact payxEmp = new Contact(FirstName=runningUser.FirstName, LastName=runningUser.LastName, AccountId=payxAcct.Id, 
                              HR_Person_Id__c=runningUser.HR_Person_Id__c, Email=runningUser.Email);      
        insert payxEmp;
                
        String product = 'Paychex Flex Time Essentials';
        String addOnClient = 'Yes';
        
        String soarMsg = '<SOARINFORMATION>\r  <EEEmail>'+ runningUser.Email +'</EEEmail>\r <PersonID>'+ runningUser.HR_Person_Id__c+'</PersonID>\r';
        soarMsg += '<ID>' + payxAcct.Id + '</ID>\r <BIS>' + payxAcct.Bis_ID__c + '</BIS>\r <CostCenter>0027</CostCenter>\r';
        soarMsg += '<ClientNumber></ClientNumber>\r <CompanyName>Test Method New Company Client Name</CompanyName>\r <Address>1270 Creekbend Lane</Address>\r';
        soarMsg += '<City>Webster</City>\r <State>NY</State>\r <ZipCode>14625</ZipCode>\r <EmployeeCount>55</EmployeeCount>\r <Product>' + product + '</Product>\r';
        soarMsg += '<FirstName>Jeff</FirstName>\r <LastName>Elliott</LastName>\r <PhoneNumber>585-222-3434</PhoneNumber>\r';
        soarMsg += '<Platform>None</Platform><AddOnClient>' + addOnClient + '</AddOnClient><AdvClient>No</AdvClient>';
        soarMsg += '<Notes>Big Notes<email address></Notes><SOARID>10</SOARID><Region>1</Region>\r </SOARINFORMATION>';         
        
        PartnerReferral__c partRef = new PartnerReferral__c(Source__c='SOAR', Comments__c='Pending', Description__c=soarMsg);
        insert partRef;
        
        SOARHelper.SoarRef sr = new SOARHelper.SoarRef();
        sr = SOARHelper.parseXml(soarMsg);
        sr.partRefId = partRef.id;
        
		List<SOARHelper.SoarRef> srList = new List<SOARHelper.SoarRef>();
		srList.add(sr);
        
        System.runAs(runningUser) {                    
            Test.startTest();
            
            SOARHelper.processSoarRef(srList);
            System.assertNotEquals(null, SOARHelper.spm, 'SPM is null.');
            System.assertEquals('Prod355', SOARHelper.spm.Name, 'Incorrect Product Name.');

            Test.stopTest();
        }        
    }
 
    /* SFDC-2703 (US4)  
     * Get Soar Product Mapping Based on Account Type (Account Type is not PEO Client).
     * This should ignore the Employee Count when assigning Rep to Opportunity, if Account Type is spcified in SPM.
     * 
     * This is a test where Parent account already exist with Account.Type='PEO Client' with no child account (addOnClient=no).
     */
    @isTest
    static void testAssignSPMDefaultRepToOpportunityOnPEOClientAccountTypeParent()	{
        List<SoarProductMapping__c> spmList = new List<SoarProductMapping__c>();
        
        SoarProductMapping__c spm;
        spm = new SoarProductMapping__c(Name='Prod354',AdvClient__c=false, Emp_Count_Min__c=0,Emp_Count_Max__c=49,Product__c='Paychex Flex Time Essentials',Account_Type__c='PEO Client',
                                        Sales_Org__c='PAY',Default_Rep__c='Jahmekah Webbe',Default_Rep_HR_Person_ID__c='1253982',ZipSegment__c='TIER1',Opportunity_Type__c='Ancillary');
        spmList.add(spm);
        
        spm = new SoarProductMapping__c(Name='Prod355',AdvClient__c=false, Emp_Count_Min__c=50,Emp_Count_Max__c=999999,Product__c='Paychex Flex Time Essentials',
                                        Sales_Org__c='MMS',Default_Rep__c='Jahmekah Webbe',Default_Rep_HR_Person_ID__c='1253982',ZipSegment__c='TIER1',Opportunity_Type__c='Ancillary');
        spmList.add(spm);

        spm = new SoarProductMapping__c(Name='Prod356',AdvClient__c=false, Emp_Count_Min__c=50,Emp_Count_Max__c=999999,Product__c='Paychex Flex Time',Account_Type__c='PEO Client',
                                        Sales_Org__c='MMS',Default_Rep__c='Jahmekah Webbe',Default_Rep_HR_Person_ID__c='1253982',ZipSegment__c='TIER1',Opportunity_Type__c='Ancillary');
        spmList.add(spm);

        spm = new SoarProductMapping__c(Name='Prod357',AdvClient__c=false, Emp_Count_Min__c=50,Emp_Count_Max__c=999999,Product__c='Paychex TrueShift Time Clock',Account_Type__c='PEO Client',
                                        Sales_Org__c='MMS',Default_Rep__c='Jahmekah Webbe',Default_Rep_HR_Person_ID__c='1253982',ZipSegment__c='TIER1',Opportunity_Type__c='Ancillary');
        spmList.add(spm);
                
        spm = new SoarProductMapping__c(Name='Prod01',AdvClient__c=true, Emp_Count_Min__c=0,Emp_Count_Max__c=49,Product__c='New Client',Sales_Org__c='PAY');
        spmList.add(spm);
        spm = new SoarProductMapping__c(Name='Prod03',AdvClient__c=true, Emp_Count_Min__c=50,Emp_Count_Max__c=999999,Product__c='New Client',Sales_Org__c='MMS'); 
        spmList.add(spm);
        
        // Use the following User if no ZipTerritory (ZipAssignment is setup) for ZipSegment or Sales Org
        User coreAdminUser = [Select Id, Name, HR_Person_ID__c from User where Profile.Name like 'Core Zone Admin%' and IsActive = true limit 1];        
        spm = new SoarProductMapping__c(Name='Prod17',Default_Rep__c=coreAdminUser.Name, Default_Rep_HR_Person_ID__c=coreAdminUser.HR_Person_ID__c,Product__c='Unknown Rep',Sales_Org__c='PAY');         
        spmList.add(spm);

        insert spmList;        
        
        User runningUser = [Select Id, FirstName, LastName, Email, HR_Person_Id__c from User where Profile.Name=:Utilities.PROF_SYS_ADMIN and IsActive=true and HR_Person_Id__c != null limit 1];

        RecordType rt  = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'Prospect'];
        Account payxAcct = new Account(Name = UserHelper.PAYCHEX_COMP, NumberOfEmployees=40, Bis_ID__c=464646, RecordTypeId=rt.Id, Type='PEO Client');
        insert payxAcct;

        Contact payxEmp = new Contact(FirstName=runningUser.FirstName, LastName=runningUser.LastName, AccountId=payxAcct.Id, 
                              HR_Person_Id__c=runningUser.HR_Person_Id__c, Email=runningUser.Email);      
        insert payxEmp;
                
        String product = 'Paychex Flex Time Essentials';
        String addOnClient = 'No';
        String platform = 'Prism_PEO';
        
        String soarMsg = '<SOARINFORMATION>\r  <EEEmail>'+ runningUser.Email +'</EEEmail>\r <PersonID>'+ runningUser.HR_Person_Id__c+'</PersonID>\r';
        soarMsg += '<ID>' + payxAcct.Id + '</ID>\r <BIS></BIS>\r <CostCenter>0027</CostCenter>\r';
        soarMsg += '<ClientNumber></ClientNumber>\r <CompanyName>Test Method New Company Client Name</CompanyName>\r <Address>1270 Creekbend Lane</Address>\r';
        soarMsg += '<City>Webster</City>\r <State>NY</State>\r <ZipCode>14625</ZipCode>\r <EmployeeCount>55</EmployeeCount>\r <Product>' + product + '</Product>\r';
        soarMsg += '<FirstName>Jeff</FirstName>\r <LastName>Elliott</LastName>\r <PhoneNumber>585-222-3434</PhoneNumber>\r';
        soarMsg += '<Platform>' + platform + '</Platform><AddOnClient>' + addOnClient + '</AddOnClient><AdvClient>No</AdvClient>';
        soarMsg += '<Notes>Big Notes<email address></Notes><SOARID>10</SOARID><Region>1</Region>\r </SOARINFORMATION>';         
        
        PartnerReferral__c partRef = new PartnerReferral__c(Source__c='SOAR', Comments__c='Pending', Description__c=soarMsg);
        insert partRef;
        
        SOARHelper.SoarRef sr = new SOARHelper.SoarRef();
        sr = SOARHelper.parseXml(soarMsg);
        sr.partRefId = partRef.id;
        
		List<SOARHelper.SoarRef> srList = new List<SOARHelper.SoarRef>();
		srList.add(sr);
        
        System.runAs(runningUser) {                    
            Test.startTest();
            
            SOARHelper.processSoarRef(srList);
            System.assertNotEquals(null, SOARHelper.spm, 'SPM is null.');
            System.assertEquals('Prod354', SOARHelper.spm.Name, 'Incorrect Product Name.');

            Test.stopTest();
        }        
    }
    
    @isTest
    static void testAssignHoldOutOwnerToOpportunity()	{       
        //populateHoldOutList();
        createReferralPartners(); // need to create ReferralPartners in order to create Opportunity
        
        List<SoarProductMapping__c> spmList = new List<SoarProductMapping__c>();
        
        SoarProductMapping__c spm;
        spm = new SoarProductMapping__c(Name='Prod354',AdvClient__c=false, Emp_Count_Min__c=0,Emp_Count_Max__c=49,Product__c='Paychex Flex Time Essentials',Account_Type__c='PEO Client',
                                        Sales_Org__c='PAY',Default_Rep__c='Jahmekah Webbe',Default_Rep_HR_Person_ID__c='1253982',ZipSegment__c='TIER1',Opportunity_Type__c='Ancillary');
        spmList.add(spm);
        
        spm = new SoarProductMapping__c(Name='Prod355',AdvClient__c=false, Emp_Count_Min__c=500,Emp_Count_Max__c=999999,Product__c='Paychex Flex Time Essentials',
                                        Sales_Org__c='MMS',ZipSegment__c='TIER1',Opportunity_Type__c='Ancillary');
        spmList.add(spm);

        spm = new SoarProductMapping__c(Name='Prod356',AdvClient__c=false, Emp_Count_Min__c=50,Emp_Count_Max__c=999999,Product__c='Paychex Flex Time',Account_Type__c='PEO Client',
                                        Sales_Org__c='MMS',Default_Rep__c='Jahmekah Webbe',Default_Rep_HR_Person_ID__c='1253982',ZipSegment__c='TIER1',Opportunity_Type__c='Ancillary');
        spmList.add(spm);

        spm = new SoarProductMapping__c(Name='Prod357',AdvClient__c=false, Emp_Count_Min__c=50,Emp_Count_Max__c=999999,Product__c='Paychex TrueShift Time Clock',Account_Type__c='PEO Client',
                                        Sales_Org__c='MMS',Default_Rep__c='Jahmekah Webbe',Default_Rep_HR_Person_ID__c='1253982',ZipSegment__c='TIER1',Opportunity_Type__c='Ancillary');
        spmList.add(spm);
                
        spm = new SoarProductMapping__c(Name='Prod01',AdvClient__c=true, Emp_Count_Min__c=0,Emp_Count_Max__c=49,Product__c='New Client',Sales_Org__c='PAY');
        spmList.add(spm);
        spm = new SoarProductMapping__c(Name='Prod03',AdvClient__c=true, Emp_Count_Min__c=50,Emp_Count_Max__c=999999,Product__c='New Client',Sales_Org__c='MMS'); 
        spmList.add(spm);
        
        // Use the following User if no ZipTerritory (ZipAssignment is setup) for ZipSegment or Sales Org
        User coreAdminUser = [Select Id, Name, HR_Person_ID__c from User where Profile.Name like 'Core Zone Admin%' and IsActive = true limit 1];        
        spm = new SoarProductMapping__c(Name='Prod17',Default_Rep__c=coreAdminUser.Name, Default_Rep_HR_Person_ID__c=coreAdminUser.HR_Person_ID__c,Product__c='Unknown Rep',Sales_Org__c='PAY');         
        spmList.add(spm);

        insert spmList;        

        User[] users = [Select Id, Name, Sales_Org__c, HR_Person_Id__c from User where HR_Person_Id__c != null and IsActive=true and Sales_Org__c=:UserHelper.SO_CORE and Profile.Name in :Utilities.CORE_PROFS limit 2];
        User uCore = users[0];
        User uCore2 = users[1];
        User uMms = [Select Id, Name, Sales_Org__c, HR_Person_Id__c from User where HR_Person_Id__c != null and IsActive=true and Sales_Org__c=:UserHelper.SO_MMS and Profile.Name =:Utilities.PROF_MMS_SALES_SB limit 1];
        
        User runningUser = [Select Id, FirstName, LastName, Email, HR_Person_Id__c from User where Profile.Name=:Utilities.PROF_SYS_ADMIN and IsActive=true and HR_Person_Id__c != null limit 1];

        //Core Account Record Type
        RecordType rt  = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'CoreAccountRecordType'];
        Account payxAcct = new Account(Name = UserHelper.PAYCHEX_COMP, NumberOfEmployees=40, Bis_ID__c=464646, RecordTypeId=rt.Id, Type='Non PEO Client',
                                      Hold_Out__c=true, OwnerId=uCore.Id);
        insert payxAcct;

        Contact payxEmp = new Contact(FirstName=runningUser.FirstName, LastName=runningUser.LastName, AccountId=payxAcct.Id, 
                              HR_Person_Id__c=runningUser.HR_Person_Id__c, Email=runningUser.Email);      
        insert payxEmp;
                
        String product = 'Paychex Flex Time Essentials';
        String addOnClient = 'Yes';
        String employeeCount = '55';
        
        String soarMsg = '<SOARINFORMATION>\r  <EEEmail>'+ runningUser.Email +'</EEEmail>\r <PersonID>'+ runningUser.HR_Person_Id__c+'</PersonID>\r';
        soarMsg += '<ID>' + payxAcct.Id + '</ID>\r <BIS>' + payxAcct.Bis_ID__c + '</BIS>\r <CostCenter>0027</CostCenter>\r';
        soarMsg += '<ClientNumber></ClientNumber>\r <CompanyName>Test Method New Company Client Name</CompanyName>\r <Address>1270 Creekbend Lane</Address>\r';
        soarMsg += '<City>Webster</City>\r <State>NY</State>\r <ZipCode>14625</ZipCode>\r <EmployeeCount>' + employeeCount + '</EmployeeCount>\r <Product>' + product + '</Product>\r';
        soarMsg += '<FirstName>Jeff</FirstName>\r <LastName>Elliott</LastName>\r <PhoneNumber>585-222-3434</PhoneNumber>\r';
        soarMsg += '<Platform>None</Platform><AddOnClient>' + addOnClient + '</AddOnClient><AdvClient>No</AdvClient>';
        soarMsg += '<Notes>Big Notes<email address></Notes><SOARID>10</SOARID><Region>1</Region>\r </SOARINFORMATION>';         
        
        PartnerReferral__c partRef = new PartnerReferral__c(Source__c='SOAR', Comments__c='Pending', Description__c=soarMsg);
        insert partRef;
        
        SOARHelper.SoarRef sr = new SOARHelper.SoarRef();
        sr = SOARHelper.parseXml(soarMsg);
        sr.partRefId = partRef.id;
        
		List<SOARHelper.SoarRef> srList = new List<SOARHelper.SoarRef>();
		srList.add(sr);
        
        System.runAs(runningUser) {                    
            Test.startTest();
            
            SOARHelper.processSoarRef(srList);
            System.assertNotEquals(null, SOARHelper.spm, 'SPM should not be null.');
            System.assertEquals('Prod355', SOARHelper.spm.Name, 'Incorrect Product Name.');

            Account newAcct = [Select Id, OwnerId, Premier_PBS_Account_Owner__r.Id,
                               (Select Id, Name, RecordTypeId, OwnerId from Opportunities) from Account 
                               where Name = 'Test Method New Company Client Name'];     
            
            System.assertNotEquals(null, newAcct, 'Account should not be null.');
            System.assertEquals(1, newAcct.Opportunities.size(), 'Incorrect Opportunities size.');
			
            User ou = [SELECT Name, HR_Person_Id__c FROM User WHERE Id = :newAcct.Opportunities[0].OwnerId];
            System.assertEquals(uCore.HR_Person_ID__c, SOARHelper.spm.Default_Rep_HR_Person_ID__c, 'Incorrect SOAR HR Person id.');
            System.assertEquals(SOARHelper.spm.Default_Rep_HR_Person_ID__c, ou.HR_Person_Id__c, 'Incorrect Opportunity HR Person id.');
            
            Test.stopTest();
        }        
    }

    /* SFDC-2703 (US3) Set Opportunity Payroll_Unit__c field to 'false' when Opportunity Type is 'Ancillary' */
    @isTest
    static void testOpportunityAncillaryPayrollUnitFalse()	{       
        //populateHoldOutList();

        createReferralPartners(); // need to create ReferralPartners in order to create Opportunity
        
        List<SoarProductMapping__c> spmList = new List<SoarProductMapping__c>();
        
        SoarProductMapping__c spm;
        spm = new SoarProductMapping__c(Name='Prod354',AdvClient__c=false, Emp_Count_Min__c=0,Emp_Count_Max__c=49,Product__c='Paychex Flex Time Essentials',Account_Type__c='PEO Client',
                                        Sales_Org__c='PAY',Default_Rep__c='Jahmekah Webbe',Default_Rep_HR_Person_ID__c='1253982',ZipSegment__c='TIER1',Opportunity_Type__c='Ancillary');
        spmList.add(spm);
        
        spm = new SoarProductMapping__c(Name='Prod355',AdvClient__c=false, Emp_Count_Min__c=500,Emp_Count_Max__c=999999,Product__c='Paychex Flex Time Essentials',
                                        Sales_Org__c='MMS',ZipSegment__c='TIER1',Opportunity_Type__c='Ancillary');
        spmList.add(spm);

        spm = new SoarProductMapping__c(Name='Prod356',AdvClient__c=false, Emp_Count_Min__c=50,Emp_Count_Max__c=999999,Product__c='Paychex Flex Time',Account_Type__c='PEO Client',
                                        Sales_Org__c='MMS',Default_Rep__c='Jahmekah Webbe',Default_Rep_HR_Person_ID__c='1253982',ZipSegment__c='TIER1',Opportunity_Type__c='Ancillary');
        spmList.add(spm);

        spm = new SoarProductMapping__c(Name='Prod357',AdvClient__c=false, Emp_Count_Min__c=50,Emp_Count_Max__c=999999,Product__c='Paychex TrueShift Time Clock',Account_Type__c='PEO Client',
                                        Sales_Org__c='MMS',Default_Rep__c='Jahmekah Webbe',Default_Rep_HR_Person_ID__c='1253982',ZipSegment__c='TIER1',Opportunity_Type__c='Ancillary');
        spmList.add(spm);
                
        spm = new SoarProductMapping__c(Name='Prod01',AdvClient__c=true, Emp_Count_Min__c=0,Emp_Count_Max__c=49,Product__c='New Client',Sales_Org__c='PAY');
        spmList.add(spm);
        spm = new SoarProductMapping__c(Name='Prod03',AdvClient__c=true, Emp_Count_Min__c=50,Emp_Count_Max__c=999999,Product__c='New Client',Sales_Org__c='MMS'); 
        spmList.add(spm);
        
        // Use the following User if no ZipTerritory (ZipAssignment is setup) for ZipSegment or Sales Org
        User coreAdminUser = [Select Id, Name, HR_Person_ID__c from User where Profile.Name like 'Core Zone Admin%' and IsActive = true limit 1];        
        spm = new SoarProductMapping__c(Name='Prod17',Default_Rep__c=coreAdminUser.Name, Default_Rep_HR_Person_ID__c=coreAdminUser.HR_Person_ID__c,Product__c='Unknown Rep',Sales_Org__c='PAY');         
        spmList.add(spm);

        insert spmList;        

        User[] users = [Select Id, Name, Sales_Org__c, HR_Person_Id__c from User where HR_Person_Id__c != null and IsActive=true and Sales_Org__c=:UserHelper.SO_CORE and Profile.Name in :Utilities.CORE_PROFS limit 2];
        User uCore = users[0];
        User uCore2 = users[1];
        User uMms = [Select Id, Name, Sales_Org__c, HR_Person_Id__c from User where HR_Person_Id__c != null and IsActive=true and Sales_Org__c=:UserHelper.SO_MMS and Profile.Name =:Utilities.PROF_MMS_SALES_SB limit 1];
        
        User runningUser = [Select Id, FirstName, LastName, Email, HR_Person_Id__c from User where Profile.Name=:Utilities.PROF_SYS_ADMIN and IsActive=true and HR_Person_Id__c != null limit 1];

        //Core Account Record Type
        RecordType rt  = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'CoreAccountRecordType'];
        Account payxAcct = new Account(Name = UserHelper.PAYCHEX_COMP, NumberOfEmployees=40, Bis_ID__c=464646, RecordTypeId=rt.Id, Type='Non PEO Client',
                                      Hold_Out__c=true, OwnerId=uCore.Id);
        insert payxAcct;

        Contact payxEmp = new Contact(FirstName=runningUser.FirstName, LastName=runningUser.LastName, AccountId=payxAcct.Id, 
                              HR_Person_Id__c=runningUser.HR_Person_Id__c, Email=runningUser.Email);      
        insert payxEmp;
                
        String product = 'Paychex Flex Time Essentials';
        String addOnClient = 'Yes';
        String employeeCount = '55';
        
        String soarMsg = '<SOARINFORMATION>\r  <EEEmail>'+ runningUser.Email +'</EEEmail>\r <PersonID>'+ runningUser.HR_Person_Id__c+'</PersonID>\r';
        soarMsg += '<ID>' + payxAcct.Id + '</ID>\r <BIS>' + payxAcct.Bis_ID__c + '</BIS>\r <CostCenter>0027</CostCenter>\r';
        soarMsg += '<ClientNumber></ClientNumber>\r <CompanyName>Test Method New Company Client Name</CompanyName>\r <Address>1270 Creekbend Lane</Address>\r';
        soarMsg += '<City>Webster</City>\r <State>NY</State>\r <ZipCode>14625</ZipCode>\r <EmployeeCount>' + employeeCount + '</EmployeeCount>\r <Product>' + product + '</Product>\r';
        soarMsg += '<FirstName>Jeff</FirstName>\r <LastName>Elliott</LastName>\r <PhoneNumber>585-222-3434</PhoneNumber>\r';
        soarMsg += '<Platform>None</Platform><AddOnClient>' + addOnClient + '</AddOnClient><AdvClient>No</AdvClient>';
        soarMsg += '<Notes>Big Notes<email address></Notes><SOARID>10</SOARID><Region>1</Region>\r </SOARINFORMATION>';         
        
        PartnerReferral__c partRef = new PartnerReferral__c(Source__c='SOAR', Comments__c='Pending', Description__c=soarMsg);
        insert partRef;
        
        SOARHelper.SoarRef sr = new SOARHelper.SoarRef();
        sr = SOARHelper.parseXml(soarMsg);
        sr.partRefId = partRef.id;
        
		List<SOARHelper.SoarRef> srList = new List<SOARHelper.SoarRef>();
		srList.add(sr);
        
        System.runAs(runningUser) {                    
            Test.startTest();
            
            SOARHelper.processSoarRef(srList);
            System.assertNotEquals(null, SOARHelper.spm, 'SPM should not be null.');
            System.assertEquals('Prod355', SOARHelper.spm.Name, 'Incorrect Product Name.');

            Account newAcct = [Select Id, OwnerId, Premier_PBS_Account_Owner__r.Id, 
                               (Select Id, Name, Payroll_Unit__c, RecordTypeId, OwnerId from Opportunities) from Account 
                               where Name = 'Test Method New Company Client Name'];     
            
            System.assertNotEquals(null, newAcct, 'Account should not be null.');
            System.assertEquals(1, newAcct.Opportunities.size(), 'Incorrect Opportunities size.');
            System.assertEquals(false, newAcct.Opportunities.get(0).Payroll_Unit__c, 'Opportunities Payroll_Unit__c should be true.');
			
            User ou = [SELECT Name, HR_Person_Id__c FROM User WHERE Id = :newAcct.Opportunities[0].OwnerId];
            System.assertEquals(uCore.HR_Person_ID__c, SOARHelper.spm.Default_Rep_HR_Person_ID__c, 'Incorrect SOAR HR Person id.');
            System.assertEquals(SOARHelper.spm.Default_Rep_HR_Person_ID__c, ou.HR_Person_Id__c, 'Incorrect Opportunity HR Person id.');
            
            Test.stopTest();
        }        
    }

    /* SFDC-2703 (US3) Set Opportunity Payroll_Unit__c field to 'true' when Opportunity Type is NOT 'Ancillary' or missing. */
    @isTest
    static void testOpportunityAncillaryPayrollUnitTrue()	{       
        //populateHoldOutList();
        createReferralPartners(); // need to create ReferralPartners in order to create Opportunity
        
        List<SoarProductMapping__c> spmList = new List<SoarProductMapping__c>();
        
        SoarProductMapping__c spm;
        spm = new SoarProductMapping__c(Name='Prod354',AdvClient__c=false, Emp_Count_Min__c=0,Emp_Count_Max__c=49,Product__c='Paychex Flex Time Essentials',Account_Type__c='PEO Client',
                                        Sales_Org__c='PAY',Default_Rep__c='Jahmekah Webbe',Default_Rep_HR_Person_ID__c='1253982',ZipSegment__c='TIER1',Opportunity_Type__c='Ancillary');
        spmList.add(spm);
        
        spm = new SoarProductMapping__c(Name='Prod355',AdvClient__c=false, Emp_Count_Min__c=500,Emp_Count_Max__c=999999,Product__c='Paychex Flex Time Essentials',
                                        Sales_Org__c='MMS',ZipSegment__c='TIER1');
        spmList.add(spm);

        spm = new SoarProductMapping__c(Name='Prod356',AdvClient__c=false, Emp_Count_Min__c=50,Emp_Count_Max__c=999999,Product__c='Paychex Flex Time',Account_Type__c='PEO Client',
                                        Sales_Org__c='MMS',Default_Rep__c='Jahmekah Webbe',Default_Rep_HR_Person_ID__c='1253982',ZipSegment__c='TIER1',Opportunity_Type__c='Ancillary');
        spmList.add(spm);

        spm = new SoarProductMapping__c(Name='Prod357',AdvClient__c=false, Emp_Count_Min__c=50,Emp_Count_Max__c=999999,Product__c='Paychex TrueShift Time Clock',Account_Type__c='PEO Client',
                                        Sales_Org__c='MMS',Default_Rep__c='Jahmekah Webbe',Default_Rep_HR_Person_ID__c='1253982',ZipSegment__c='TIER1',Opportunity_Type__c='Ancillary');
        spmList.add(spm);
                
        spm = new SoarProductMapping__c(Name='Prod01',AdvClient__c=true, Emp_Count_Min__c=0,Emp_Count_Max__c=49,Product__c='New Client',Sales_Org__c='PAY');
        spmList.add(spm);
        spm = new SoarProductMapping__c(Name='Prod03',AdvClient__c=true, Emp_Count_Min__c=50,Emp_Count_Max__c=999999,Product__c='New Client',Sales_Org__c='MMS'); 
        spmList.add(spm);
        
        // Use the following User if no ZipTerritory (ZipAssignment is setup) for ZipSegment or Sales Org
        User coreAdminUser = [Select Id, Name, HR_Person_ID__c from User where Profile.Name like 'Core Zone Admin%' and IsActive = true limit 1];        
        spm = new SoarProductMapping__c(Name='Prod17',Default_Rep__c=coreAdminUser.Name, Default_Rep_HR_Person_ID__c=coreAdminUser.HR_Person_ID__c,Product__c='Unknown Rep',Sales_Org__c='PAY');         
        spmList.add(spm);

        insert spmList;        

        User[] users = [Select Id, Name, Sales_Org__c, HR_Person_Id__c from User where HR_Person_Id__c != null and IsActive=true and Sales_Org__c=:UserHelper.SO_CORE and Profile.Name in :Utilities.CORE_PROFS limit 2];
        User uCore = users[0];
        User uCore2 = users[1];
        User uMms = [Select Id, Name, Sales_Org__c, HR_Person_Id__c from User where HR_Person_Id__c != null and IsActive=true and Sales_Org__c=:UserHelper.SO_MMS and Profile.Name =:Utilities.PROF_MMS_SALES_SB limit 1];
        
        User runningUser = [Select Id, FirstName, LastName, Email, HR_Person_Id__c from User where Profile.Name=:Utilities.PROF_SYS_ADMIN and IsActive=true and HR_Person_Id__c != null limit 1];

        //Core Account Record Type
        RecordType rt  = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'CoreAccountRecordType'];
        Account payxAcct = new Account(Name = UserHelper.PAYCHEX_COMP, NumberOfEmployees=40, Bis_ID__c=464646, RecordTypeId=rt.Id, Type='Non PEO Client',
                                      Hold_Out__c=true, OwnerId=uCore.Id);
        insert payxAcct;

        Contact payxEmp = new Contact(FirstName=runningUser.FirstName, LastName=runningUser.LastName, AccountId=payxAcct.Id, 
                              HR_Person_Id__c=runningUser.HR_Person_Id__c, Email=runningUser.Email);      
        insert payxEmp;
                
        String product = 'Paychex Flex Time Essentials';
        String addOnClient = 'Yes';
        String employeeCount = '55';
        
        String soarMsg = '<SOARINFORMATION>\r  <EEEmail>'+ runningUser.Email +'</EEEmail>\r <PersonID>'+ runningUser.HR_Person_Id__c+'</PersonID>\r';
        soarMsg += '<ID>' + payxAcct.Id + '</ID>\r <BIS>' + payxAcct.Bis_ID__c + '</BIS>\r <CostCenter>0027</CostCenter>\r';
        soarMsg += '<ClientNumber></ClientNumber>\r <CompanyName>Test Method New Company Client Name</CompanyName>\r <Address>1270 Creekbend Lane</Address>\r';
        soarMsg += '<City>Webster</City>\r <State>NY</State>\r <ZipCode>14625</ZipCode>\r <EmployeeCount>' + employeeCount + '</EmployeeCount>\r <Product>' + product + '</Product>\r';
        soarMsg += '<FirstName>Jeff</FirstName>\r <LastName>Elliott</LastName>\r <PhoneNumber>585-222-3434</PhoneNumber>\r';
        soarMsg += '<Platform>None</Platform><AddOnClient>' + addOnClient + '</AddOnClient><AdvClient>No</AdvClient>';
        soarMsg += '<Notes>Big Notes<email address></Notes><SOARID>10</SOARID><Region>1</Region>\r </SOARINFORMATION>';         
        
        PartnerReferral__c partRef = new PartnerReferral__c(Source__c='SOAR', Comments__c='Pending', Description__c=soarMsg);
        insert partRef;
        
        SOARHelper.SoarRef sr = new SOARHelper.SoarRef();
        sr = SOARHelper.parseXml(soarMsg);
        sr.partRefId = partRef.id;
        
		List<SOARHelper.SoarRef> srList = new List<SOARHelper.SoarRef>();
		srList.add(sr);
        
        System.runAs(runningUser) {                    
            Test.startTest();
            
            SOARHelper.processSoarRef(srList);
            System.assertNotEquals(null, SOARHelper.spm, 'SPM should not be null.');
            System.assertEquals('Prod355', SOARHelper.spm.Name, 'Incorrect Product Name.');

            Account newAcct = [Select Id, OwnerId, Premier_PBS_Account_Owner__r.Id, 
                               (Select Id, Name, Payroll_Unit__c, RecordTypeId, OwnerId from Opportunities) from Account 
                               where Name = 'Test Method New Company Client Name'];     
            
            System.assertNotEquals(null, newAcct, 'Account should not be null.');
            System.assertEquals(1, newAcct.Opportunities.size(), 'Incorrect Opportunities size.');
            System.assertEquals(true, newAcct.Opportunities.get(0).Payroll_Unit__c, 'Opportunities Payroll_Unit__c should be true.');
			
            User ou = [SELECT Name, HR_Person_Id__c FROM User WHERE Id = :newAcct.Opportunities[0].OwnerId];
            System.assertEquals(uCore.HR_Person_ID__c, SOARHelper.spm.Default_Rep_HR_Person_ID__c, 'Incorrect SOAR HR Person id.');
            System.assertEquals(SOARHelper.spm.Default_Rep_HR_Person_ID__c, ou.HR_Person_Id__c, 'Incorrect Opportunity HR Person id.');
            
            Test.stopTest();
        }        
    }
    
    @isTest
    static void testOpportunityAncillaryCSSR()	{       
        //populateHoldOutList();
        createReferralPartners(); // need to create ReferralPartners in order to create Opportunity
        
        List<SoarProductMapping__c> spmList = new List<SoarProductMapping__c>();
        
        SoarProductMapping__c spm;
        spm = new SoarProductMapping__c(Name='Prod354',AdvClient__c=false, Emp_Count_Min__c=0,Emp_Count_Max__c=49,Product__c='Paychex Flex Time Essentials',
                                        Sales_Org__c='PAY',ZipSegment__c='TIER1',Opportunity_Type__c='Ancillary');
        spmList.add(spm);
        spm = new SoarProductMapping__c(Name='Prod355',AdvClient__c=false, Emp_Count_Min__c=0,Emp_Count_Max__c=49,Product__c='Paychex Flex Time Essentials',
                                        Sales_Org__c='MMS',Opportunity_Type__c='Ancillary');
        spmList.add(spm);
        
        
        // Use the following User if no ZipTerritory (ZipAssignment is setup) for ZipSegment or Sales Org
        User coreAdminUser = [Select Id, Name, HR_Person_ID__c from User where Profile.Name like 'Core Zone Admin%' and IsActive = true limit 1];        
        spm = new SoarProductMapping__c(Name='Prod17',Default_Rep__c=coreAdminUser.Name, Default_Rep_HR_Person_ID__c=coreAdminUser.HR_Person_ID__c,Product__c='Unknown Rep',Sales_Org__c='PAY');         

        spmList.add(spm);

        insert spmList;        

        User[] users = [Select Id, Name, Sales_Org__c, HR_Person_Id__c from User where HR_Person_Id__c != null and IsActive=true and Sales_Org__c=:UserHelper.SO_CORE and Profile.Name in :Utilities.CORE_PROFS limit 2];
        User uCore = users[0];
        User uCore2 = users[1];
        User uMms = [Select Id, Name, Sales_Org__c, HR_Person_Id__c from User where HR_Person_Id__c != null and IsActive=true and Sales_Org__c=:UserHelper.SO_MMS and Profile.Name =:Utilities.PROF_MMS_SALES_SB limit 1];
        
        User runningUser = [Select Id, FirstName, LastName, Email, HR_Person_Id__c from User where Profile.Name=:Utilities.PROF_SYS_ADMIN and IsActive=true and HR_Person_Id__c != null limit 1];
        Account[] accts = new Account[]{};
        //Core Account Record Type
        RecordType rt  = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'CoreAccountRecordType'];
        Account payxAcct = new Account(Name = UserHelper.PAYCHEX_COMP, NumberOfEmployees=40, Bis_ID__c=464646, RecordTypeId=rt.Id, Type='Non PEO Client',
                                      Hold_Out__c =true, OwnerId=uCore.Id);
        accts.add(payxAcct);
        Account existingAcct = new Account(Name = 'test', AccountNumber='12-222',NumberOfEmployees=40, Bis_ID__c=232323, RecordTypeId=rt.Id,OwnerId=uMms.Id,
                                           BillingStreet='1270 Creekbend Lane',BillingCity='Webster',BillingState='NY',BillingPostalCode='14625',CSSR_Segment__c=true);
        accts.add(existingAcct);
        insert accts;

        Contact payxEmp = new Contact(FirstName=runningUser.FirstName, LastName=runningUser.LastName, AccountId=payxAcct.Id, 
                              HR_Person_Id__c=runningUser.HR_Person_Id__c, Email=runningUser.Email);      
        insert payxEmp;

        String product = 'Paychex Flex Time Essentials';
        String addOnClient = 'No';
        String employeeCount = '55';
        
        String soarMsg = '<SOARINFORMATION>\r  <EEEmail>'+ runningUser.Email +'</EEEmail>\r <PersonID>'+ runningUser.HR_Person_Id__c+'</PersonID>\r';
        soarMsg += '<ID>' + existingAcct.Id + '</ID>\r <BIS>' + existingAcct.Bis_ID__c + '</BIS>\r <CostCenter>0027</CostCenter>\r';
        soarMsg += '<ClientNumber>'+existingAcct.AccountNumber+'</ClientNumber>\r <CompanyName>'+existingAcct.Name+'</CompanyName>\r <Address>'+existingAcct.BillingStreet+'</Address>\r';
        soarMsg += '<City>'+existingAcct.BillingCity+'</City>\r <State>'+existingAcct.BillingState+'</State>\r <ZipCode>'+existingAcct.BillingPostalCode+'</ZipCode>\r <EmployeeCount>' + employeeCount + '</EmployeeCount>\r <Product>' + product + '</Product>\r';
        soarMsg += '<FirstName>Jeff</FirstName>\r <LastName>Elliott</LastName>\r <PhoneNumber>585-222-3434</PhoneNumber>\r';
        soarMsg += '<Platform>None</Platform><AddOnClient>' + addOnClient + '</AddOnClient><AdvClient>No</AdvClient>';
        soarMsg += '<Notes>Big Notes<email address></Notes><SOARID>10</SOARID><Region>1</Region>\r </SOARINFORMATION>';         
        
        PartnerReferral__c partRef = new PartnerReferral__c(Source__c='SOAR', Comments__c='Pending', Description__c=soarMsg);
        insert partRef;
        
        SOARHelper.SoarRef sr = new SOARHelper.SoarRef();
        sr = SOARHelper.parseXml(soarMsg);
        sr.partRefId = partRef.id;
        
		List<SOARHelper.SoarRef> srList = new List<SOARHelper.SoarRef>();
		srList.add(sr);
        
        System.runAs(runningUser) {                    
            Test.startTest();
            
            SOARHelper.processSoarRef(srList);
            System.assertNotEquals(null, SOARHelper.spm, 'SPM should not be null.');
            //System.assertEquals('Prod355', SOARHelper.spm.Name, 'Incorrect Product Name.'); spm doesn't matter

            Account uAcct = [Select Id, OwnerId, Premier_PBS_Account_Owner__r.Id, 
                               (Select Id, Name, Payroll_Unit__c, RecordTypeId, OwnerId from Opportunities) from Account 
                               where Id = :existingAcct.Id];     
            
            System.assertNotEquals(null, uAcct, 'Account should not be null.');
            System.assertEquals(1, uAcct.Opportunities.size(), 'Incorrect Opportunities size.');
			System.assertEquals(uAcct.OwnerId, uAcct.Opportunities.get(0).OwnerId);
			//System.assertEquals(coreAdminUser.Id, uAcct.Opportunities.get(0).OwnerId);          
            Test.stopTest();
        }        
    }

	@isTest
    static void testblankReferringEmp()	{       
        Boolean testPassed = false;
        createReferralPartners(); // need to create ReferralPartners in order to create Opportunity
        
        List<SoarProductMapping__c> spmList = new List<SoarProductMapping__c>();        
        SoarProductMapping__c spm;
        spm = new SoarProductMapping__c(Name='Prod354',AdvClient__c=false, Emp_Count_Min__c=0,Emp_Count_Max__c=49,Product__c='Paychex Flex Time Essentials',
                                        Sales_Org__c='PAY',ZipSegment__c='TIER1',Opportunity_Type__c='Ancillary');
        spmList.add(spm);
        spm = new SoarProductMapping__c(Name='Prod355',AdvClient__c=false, Emp_Count_Min__c=0,Emp_Count_Max__c=49,Product__c='Paychex Flex Time Essentials',
                                        Sales_Org__c='MMS',Opportunity_Type__c='Ancillary');
        spmList.add(spm);
               
        // Use the following User if no ZipTerritory (ZipAssignment is setup) for ZipSegment or Sales Org
        User coreAdminUser = [Select Id, Name, HR_Person_ID__c from User where Profile.Name like 'Core Zone Admin%' and IsActive = true limit 1];        
        spm = new SoarProductMapping__c(Name='Prod17',Default_Rep__c=coreAdminUser.Name, Default_Rep_HR_Person_ID__c=coreAdminUser.HR_Person_ID__c,Product__c='Unknown Rep',Sales_Org__c='PAY');         

        spmList.add(spm);

        insert spmList;        

        User[] users = [Select Id, Name, Sales_Org__c, HR_Person_Id__c from User where HR_Person_Id__c != null and IsActive=true and Sales_Org__c=:UserHelper.SO_CORE and Profile.Name in :Utilities.CORE_PROFS limit 2];
        User uCore = users[0];
        User uCore2 = users[1];
        User uMms = [Select Id, Name, Sales_Org__c, HR_Person_Id__c from User where HR_Person_Id__c != null and IsActive=true and Sales_Org__c=:UserHelper.SO_MMS and Profile.Name =:Utilities.PROF_MMS_SALES_SB limit 1];
        
        User runningUser = [Select Id, FirstName, LastName, Email, HR_Person_Id__c from User where Profile.Name=:Utilities.PROF_SYS_ADMIN and IsActive=true and HR_Person_Id__c != null limit 1];
        Account[] accts = new Account[]{};
        //Core Account Record Type
        RecordType rt  = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'CoreAccountRecordType'];
        Account payxAcct = new Account(Name = UserHelper.PAYCHEX_COMP, NumberOfEmployees=40, Bis_ID__c=464646, RecordTypeId=rt.Id, Type='Non PEO Client',
                                      Hold_Out__c =true, OwnerId=uCore.Id);
        accts.add(payxAcct);
        Account existingAcct = new Account(Name = 'test', AccountNumber='12-222',NumberOfEmployees=40, Bis_ID__c=232323, RecordTypeId=rt.Id,OwnerId=uMms.Id,
                                           BillingStreet='1270 Creekbend Lane',BillingCity='Webster',BillingState='NY',BillingPostalCode='14625',CSSR_Segment__c=true);
        accts.add(existingAcct);
        insert accts;

        Contact payxEmp = new Contact(FirstName=runningUser.FirstName, LastName=runningUser.LastName, AccountId=payxAcct.Id, 
                              HR_Person_Id__c=runningUser.HR_Person_Id__c, Email=runningUser.Email);      
        insert payxEmp;

        String product = 'Paychex Flex Time Essentials';
        String addOnClient = 'No';
        String employeeCount = '55';
        
        String soarMsg = '<SOARINFORMATION>\r  <EEEmail>someone@noemail.com</EEEmail>\r <PersonID>'+8888888+'</PersonID>\r';
        soarMsg += '<ID>' + existingAcct.Id + '</ID>\r <BIS>' + existingAcct.Bis_ID__c + '</BIS>\r <CostCenter>0027</CostCenter>\r';
        soarMsg += '<ClientNumber>'+existingAcct.AccountNumber+'</ClientNumber>\r <CompanyName>'+existingAcct.Name+'</CompanyName>\r <Address>'+existingAcct.BillingStreet+'</Address>\r';
        soarMsg += '<City>'+existingAcct.BillingCity+'</City>\r <State>'+existingAcct.BillingState+'</State>\r <ZipCode>'+existingAcct.BillingPostalCode+'</ZipCode>\r <EmployeeCount>' + employeeCount + '</EmployeeCount>\r <Product>' + product + '</Product>\r';
        soarMsg += '<FirstName>Jeff</FirstName>\r <LastName>Elliott</LastName>\r <PhoneNumber>585-222-3434</PhoneNumber>\r';
        soarMsg += '<Platform>None</Platform><AddOnClient>' + addOnClient + '</AddOnClient><AdvClient>No</AdvClient>';
        soarMsg += '<Notes>Big Notes<email address></Notes><SOARID>10</SOARID><Region>1</Region>\r </SOARINFORMATION>';         
        
        PartnerReferral__c partRef = new PartnerReferral__c(Source__c='SOAR', Comments__c='Pending', Description__c=soarMsg);
        insert partRef;
        
        SOARHelper.SoarRef sr = new SOARHelper.SoarRef();
        sr = SOARHelper.parseXml(soarMsg);
        sr.partRefId = partRef.id;
        
		List<SOARHelper.SoarRef> srList = new List<SOARHelper.SoarRef>();
		srList.add(sr);
        
        System.runAs(runningUser) {                    
            Test.startTest();
            try{
                SOARHelper.processSoarRef(srList);
            }
            catch(SOARHelper.SOARException ex){   
                testPassed = true;  // sends email instead of throwing error coz email body is empty
            }     
        	System.assertEquals(false, testPassed);
            Test.stopTest();
        }        
    }
    
    @isTest
    static void testExistingContact()	{       
        Boolean testPassed = false;
        createReferralPartners(); // need to create ReferralPartners in order to create Opportunity
        
        List<SoarProductMapping__c> spmList = new List<SoarProductMapping__c>();        
        SoarProductMapping__c spm;
        spm = new SoarProductMapping__c(Name='Prod354',AdvClient__c=false, Emp_Count_Min__c=0,Emp_Count_Max__c=49,Product__c='Paychex Flex Time Essentials',
                                        Sales_Org__c='PAY',ZipSegment__c='TIER1',Opportunity_Type__c='Ancillary');
        spmList.add(spm);
        spm = new SoarProductMapping__c(Name='Prod355',AdvClient__c=false, Emp_Count_Min__c=0,Emp_Count_Max__c=49,Product__c='Paychex Flex Time Essentials',
                                        Sales_Org__c='MMS',Opportunity_Type__c='Ancillary');
        spmList.add(spm);
               
        // Use the following User if no ZipTerritory (ZipAssignment is setup) for ZipSegment or Sales Org
        User coreAdminUser = [Select Id, Name, HR_Person_ID__c from User where Profile.Name like 'Core Zone Admin%' and IsActive = true limit 1];        
        spm = new SoarProductMapping__c(Name='Prod17',Default_Rep__c=coreAdminUser.Name, Default_Rep_HR_Person_ID__c=coreAdminUser.HR_Person_ID__c,Product__c='Unknown Rep',Sales_Org__c='PAY');         

        spmList.add(spm);

        insert spmList;        

        User[] users = [Select Id, Name, Sales_Org__c, HR_Person_Id__c from User where HR_Person_Id__c != null and IsActive=true and Sales_Org__c=:UserHelper.SO_CORE and Profile.Name in :Utilities.CORE_PROFS limit 2];
        User uCore = users[0];
        User uCore2 = users[1];
        User uMms = [Select Id, Name, Sales_Org__c, HR_Person_Id__c from User where HR_Person_Id__c != null and IsActive=true and Sales_Org__c=:UserHelper.SO_MMS and Profile.Name =:Utilities.PROF_MMS_SALES_SB limit 1];
        
        User runningUser = [Select Id, FirstName, LastName, Email, HR_Person_Id__c from User where Profile.Name=:Utilities.PROF_SYS_ADMIN and IsActive=true and HR_Person_Id__c != null limit 1];
        Account[] accts = new Account[]{};
        Contact[] ctcts = new Contact[]{};   
        //Core Account Record Type
        RecordType rt  = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'CoreAccountRecordType'];
        Account payxAcct = new Account(Name = UserHelper.PAYCHEX_COMP, NumberOfEmployees=40, Bis_ID__c=464646, RecordTypeId=rt.Id, Type='Non PEO Client',
                                      Hold_Out__c =true, OwnerId=uCore.Id);
        accts.add(payxAcct);
        Account existingAcct = new Account(Name = 'test', AccountNumber='12-222',NumberOfEmployees=40, Bis_ID__c=232323, RecordTypeId=rt.Id,OwnerId=uMms.Id,
                                           BillingStreet='1270 Creekbend Lane',BillingCity='Webster',BillingState='NY',BillingPostalCode='14625',CSSR_Segment__c=true);
        accts.add(existingAcct);
        insert accts;
        
        Contact acctCtct = new Contact(FirstName='Steve', LastName='Scuba', AccountId=existingAcct.Id, Sales_Contact__c = false, 
                              Phone='555-555-5858', Email='sscuba@something.com');   
		ctcts.add(acctCtct);
        Contact payxEmp = new Contact(FirstName=runningUser.FirstName, LastName=runningUser.LastName, AccountId=payxAcct.Id, 
                              HR_Person_Id__c=runningUser.HR_Person_Id__c, Email=runningUser.Email);      
        ctcts.add(payxEmp);
        insert ctcts;

        String product = 'Paychex Flex Time Essentials';
        String addOnClient = 'No';
        String employeeCount = '55';
        
        String soarMsg = '<SOARINFORMATION>\r  <EEEmail>'+ runningUser.Email +'</EEEmail>\r <PersonID>'+ runningUser.HR_Person_Id__c+'</PersonID>\r';
        soarMsg += '<ID>' + existingAcct.Id + '</ID>\r <BIS>' + existingAcct.Bis_ID__c + '</BIS>\r <CostCenter>0027</CostCenter>\r';
        soarMsg += '<ClientNumber>'+existingAcct.AccountNumber+'</ClientNumber>\r <CompanyName>'+existingAcct.Name+'</CompanyName>\r <Address>'+existingAcct.BillingStreet+'</Address>\r';
        soarMsg += '<City>'+existingAcct.BillingCity+'</City>\r <State>'+existingAcct.BillingState+'</State>\r <ZipCode>'+existingAcct.BillingPostalCode+'</ZipCode>\r <EmployeeCount>' + employeeCount + '</EmployeeCount>\r <Product>' + product + '</Product>\r';
        soarMsg += '<FirstName>Steve</FirstName>\r <LastName>Scuba</LastName>\r <PhoneNumber>555-555-5858</PhoneNumber>\r';
        soarMsg += '<Platform>None</Platform><AddOnClient>' + addOnClient + '</AddOnClient><AdvClient>No</AdvClient>';
        soarMsg += '<Notes>Big Notes<email address></Notes><SOARID>10</SOARID><Region>1</Region>\r </SOARINFORMATION>';         
        
        PartnerReferral__c partRef = new PartnerReferral__c(Source__c='SOAR', Comments__c='Pending', Description__c=soarMsg);
        insert partRef;
        
        SOARHelper.SoarRef sr = new SOARHelper.SoarRef();
        sr = SOARHelper.parseXml(soarMsg);
        sr.partRefId = partRef.id;
        
		List<SOARHelper.SoarRef> srList = new List<SOARHelper.SoarRef>();
		srList.add(sr);
        
        System.runAs(runningUser) {                    
            Test.startTest();
            try{
                SOARHelper.processSoarRef(srList);
            }
            catch(SOARHelper.SOARException ex){   
                testPassed = true;  // sends email instead of throwing error coz email body is empty
            }     
        	System.assertEquals(false, testPassed);
            Test.stopTest();
        }        
    }

	@isTest
    static void testNoExistingContact()	{       
        Boolean testPassed = false;
        createReferralPartners(); // need to create ReferralPartners in order to create Opportunity
        
        List<SoarProductMapping__c> spmList = new List<SoarProductMapping__c>();        
        SoarProductMapping__c spm;
        spm = new SoarProductMapping__c(Name='Prod354',AdvClient__c=false, Emp_Count_Min__c=0,Emp_Count_Max__c=49,Product__c='Paychex Flex Time Essentials',
                                        Sales_Org__c='PAY',ZipSegment__c='TIER1',Opportunity_Type__c='Ancillary');
        spmList.add(spm);
        spm = new SoarProductMapping__c(Name='Prod355',AdvClient__c=false, Emp_Count_Min__c=0,Emp_Count_Max__c=49,Product__c='Paychex Flex Time Essentials',
                                        Sales_Org__c='MMS',Opportunity_Type__c='Ancillary');
        spmList.add(spm);
               
        // Use the following User if no ZipTerritory (ZipAssignment is setup) for ZipSegment or Sales Org
        User coreAdminUser = [Select Id, Name, HR_Person_ID__c from User where Profile.Name like 'Core Zone Admin%' and IsActive = true limit 1];        
        spm = new SoarProductMapping__c(Name='Prod17',Default_Rep__c=coreAdminUser.Name, Default_Rep_HR_Person_ID__c=coreAdminUser.HR_Person_ID__c,Product__c='Unknown Rep',Sales_Org__c='PAY');         

        spmList.add(spm);

        insert spmList;        

        User[] users = [Select Id, Name, Sales_Org__c, HR_Person_Id__c from User where HR_Person_Id__c != null and IsActive=true and Sales_Org__c=:UserHelper.SO_CORE and Profile.Name in :Utilities.CORE_PROFS limit 2];
        User uCore = users[0];
        User uCore2 = users[1];
        User uMms = [Select Id, Name, Sales_Org__c, HR_Person_Id__c from User where HR_Person_Id__c != null and IsActive=true and Sales_Org__c=:UserHelper.SO_MMS and Profile.Name =:Utilities.PROF_MMS_SALES_SB limit 1];
        
        User runningUser = [Select Id, FirstName, LastName, Email, HR_Person_Id__c from User where Profile.Name=:Utilities.PROF_SYS_ADMIN and IsActive=true and HR_Person_Id__c != null limit 1];
        Account[] accts = new Account[]{};
        Contact[] ctcts = new Contact[]{};   
        //Core Account Record Type
        RecordType rt  = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'CoreAccountRecordType'];
        Account payxAcct = new Account(Name = UserHelper.PAYCHEX_COMP, NumberOfEmployees=40, Bis_ID__c=464646, RecordTypeId=rt.Id, Type='Non PEO Client',
                                      Hold_Out__c =true, OwnerId=uCore.Id);
        accts.add(payxAcct);
        Account existingAcct = new Account(Name = 'test', AccountNumber='12-222',NumberOfEmployees=40, Bis_ID__c=232323, RecordTypeId=rt.Id,OwnerId=uMms.Id,
                                           BillingStreet='1270 Creekbend Lane',BillingCity='Webster',BillingState='NY',BillingPostalCode='14625',CSSR_Segment__c=true);
        accts.add(existingAcct);
        insert accts;
        
        Contact payxEmp = new Contact(FirstName=runningUser.FirstName, LastName=runningUser.LastName, AccountId=payxAcct.Id, 
                              HR_Person_Id__c=runningUser.HR_Person_Id__c, Email=runningUser.Email);      
        ctcts.add(payxEmp);
        insert ctcts;

        String product = 'Paychex Flex Time Essentials';
        String addOnClient = 'No';
        String employeeCount = '55';
        
        String soarMsg = '<SOARINFORMATION>\r  <EEEmail>'+ runningUser.Email +'</EEEmail>\r <PersonID>'+ runningUser.HR_Person_Id__c+'</PersonID>\r';
        soarMsg += '<ID>' + existingAcct.Id + '</ID>\r <BIS>' + existingAcct.Bis_ID__c + '</BIS>\r <CostCenter>0027</CostCenter>\r';
        soarMsg += '<ClientNumber>'+existingAcct.AccountNumber+'</ClientNumber>\r <CompanyName>'+existingAcct.Name+'</CompanyName>\r <Address>'+existingAcct.BillingStreet+'</Address>\r';
        soarMsg += '<City>'+existingAcct.BillingCity+'</City>\r <State>'+existingAcct.BillingState+'</State>\r <ZipCode>'+existingAcct.BillingPostalCode+'</ZipCode>\r <EmployeeCount>' + employeeCount + '</EmployeeCount>\r <Product>' + product + '</Product>\r';
        soarMsg += '<FirstName>Steve</FirstName>\r <LastName>Scuba</LastName>\r <PhoneNumber>555-555-5858</PhoneNumber>\r';
        soarMsg += '<Platform>None</Platform><AddOnClient>' + addOnClient + '</AddOnClient><AdvClient>No</AdvClient>';
        soarMsg += '<Notes>Big Notes<email address></Notes><SOARID>10</SOARID><Region>1</Region>\r </SOARINFORMATION>';         
        
        PartnerReferral__c partRef = new PartnerReferral__c(Source__c='SOAR', Comments__c='Pending', Description__c=soarMsg);
        insert partRef;
        
        SOARHelper.SoarRef sr = new SOARHelper.SoarRef();
        sr = SOARHelper.parseXml(soarMsg);
        sr.partRefId = partRef.id;
        
		List<SOARHelper.SoarRef> srList = new List<SOARHelper.SoarRef>();
		srList.add(sr);
        
        System.runAs(runningUser) {                    
            Test.startTest();
            try{
                SOARHelper.processSoarRef(srList);
            }
            catch(SOARHelper.SOARException ex){   
                testPassed = true;  // sends email instead of throwing error coz email body is empty
            }     
        	System.assertEquals(false, testPassed);
            Test.stopTest();
        }        
    } //testNoExistingContact
    
    @isTest
    static void testBadAcct()	{       
        Boolean testPassed = false;
        createReferralPartners(); // need to create ReferralPartners in order to create Opportunity
        
        List<SoarProductMapping__c> spmList = new List<SoarProductMapping__c>();        
        SoarProductMapping__c spm;
        spm = new SoarProductMapping__c(Name='Prod354',AdvClient__c=false, Emp_Count_Min__c=0,Emp_Count_Max__c=49,Product__c='Paychex Flex Time Essentials',
                                        Sales_Org__c='PAY',ZipSegment__c='TIER1',Opportunity_Type__c='Ancillary');
        spmList.add(spm);
        spm = new SoarProductMapping__c(Name='Prod355',AdvClient__c=false, Emp_Count_Min__c=0,Emp_Count_Max__c=49,Product__c='Paychex Flex Time Essentials',
                                        Sales_Org__c='MMS',Opportunity_Type__c='Ancillary');
        spmList.add(spm);
               
        // Use the following User if no ZipTerritory (ZipAssignment is setup) for ZipSegment or Sales Org
        User coreAdminUser = [Select Id, Name, HR_Person_ID__c from User where Profile.Name like 'Core Zone Admin%' and IsActive = true limit 1];        
        spm = new SoarProductMapping__c(Name='Prod17',Default_Rep__c=coreAdminUser.Name, Default_Rep_HR_Person_ID__c=coreAdminUser.HR_Person_ID__c,Product__c='Unknown Rep',Sales_Org__c='PAY');         

        spmList.add(spm);

        insert spmList;        

        User[] users = [Select Id, Name, Sales_Org__c, HR_Person_Id__c from User where HR_Person_Id__c != null and IsActive=true and Sales_Org__c=:UserHelper.SO_CORE and Profile.Name in :Utilities.CORE_PROFS limit 2];
        User uCore = users[0];
        User uCore2 = users[1];
        User uMms = [Select Id, Name, Sales_Org__c, HR_Person_Id__c from User where HR_Person_Id__c != null and IsActive=true and Sales_Org__c=:UserHelper.SO_MMS and Profile.Name =:Utilities.PROF_MMS_SALES_SB limit 1];
        
        User runningUser = [Select Id, FirstName, LastName, Email, HR_Person_Id__c from User where Profile.Name=:Utilities.PROF_SYS_ADMIN and IsActive=true and HR_Person_Id__c != null limit 1];
        Account[] accts = new Account[]{};
        Contact[] ctcts = new Contact[]{};   
        //Core Account Record Type
        RecordType rt  = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'CoreAccountRecordType'];
        Account payxAcct = new Account(Name = UserHelper.PAYCHEX_COMP, NumberOfEmployees=40, Bis_ID__c=464646, RecordTypeId=rt.Id, Type='Non PEO Client',
                                      Hold_Out__c =true, OwnerId=uCore.Id);
        accts.add(payxAcct);
        insert accts;
        
        Contact payxEmp = new Contact(FirstName=runningUser.FirstName, LastName=runningUser.LastName, AccountId=payxAcct.Id, 
                              HR_Person_Id__c=runningUser.HR_Person_Id__c, Email=runningUser.Email);      
        ctcts.add(payxEmp);
        insert ctcts;

        String product = 'Paychex Flex Time Essentials';
        String addOnClient = 'No';
        String employeeCount = '12';
        
        String soarMsg = '<SOARINFORMATION>\r  <EEEmail>'+ runningUser.Email +'</EEEmail>\r <PersonID>'+ runningUser.HR_Person_Id__c+'</PersonID>\r';
        soarMsg += '<ID>001000000000000</ID>\r <BIS>63210</BIS>\r <CostCenter>0027</CostCenter>\r';
        soarMsg += '<ClientNumber>741-78451</ClientNumber>\r <CompanyName>Bad Account</CompanyName>\r <Address>123 Main Street</Address>\r';
        soarMsg += '<City>Rochester</City>\r <State>NY</State>\r <ZipCode>14609</ZipCode>\r <EmployeeCount>' + employeeCount + '</EmployeeCount>\r <Product>' + product + '</Product>\r';
        soarMsg += '<FirstName>Steve</FirstName>\r <LastName>Scuba</LastName>\r <PhoneNumber>555-555-5858</PhoneNumber>\r';
        soarMsg += '<Platform>None</Platform><AddOnClient>' + addOnClient + '</AddOnClient><AdvClient>No</AdvClient>';
        soarMsg += '<Notes>Big Notes<email address></Notes><SOARID>10</SOARID><Region>1</Region>\r </SOARINFORMATION>';         
        
        PartnerReferral__c partRef = new PartnerReferral__c(Source__c='SOAR', Comments__c='Pending', Description__c=soarMsg);
        insert partRef;
        
        SOARHelper.SoarRef sr = new SOARHelper.SoarRef();
        sr = SOARHelper.parseXml(soarMsg);
        sr.partRefId = partRef.id;
        
		List<SOARHelper.SoarRef> srList = new List<SOARHelper.SoarRef>();
		srList.add(sr);
        
        System.runAs(runningUser) {                    
            Test.startTest();
            try{
                SOARHelper.processSoarRef(srList);
            }
            catch(SOARHelper.SOARException ex){   
                testPassed = true;  // sends email instead of throwing error coz email body is empty
            }     
        	System.assertEquals(false, testPassed);
            Test.stopTest();
        }        
    }
    
    private static void createReferralPartners() {
        // create referral partner records
        Referral_Partner__c paypart = new Referral_Partner__c(Name = UserHelper.SO_CORE,CreateRefOpp__c=False, Partner_Type__c=SOARHelper.PARTNER_SOAR,
                                                              Selling_Opp_RecordTypeId__c='012500000000n4LAAQ',Sort_Order__c=10);   //,Use_Contact__c=True);
        Referral_Partner__c mmspart = new Referral_Partner__c(Name = UserHelper.SO_MMS,CreateRefOpp__c=False, Partner_Type__c=SOARHelper.PARTNER_SOAR,
                                                              Selling_Opp_RecordTypeId__c='012300000000hQQAAY',Sort_Order__c=20);   //,Use_Contact__c=True);
        Referral_Partner__c hnbfpart = new Referral_Partner__c(Name = UserHelper.SO_HNB,CreateRefOpp__c=False, Partner_Type__c=SOARHelper.PARTNER_SOAR,
                                                               Selling_Opp_RecordTypeId__c='01270000000Q5O2AAK',Sort_Order__c=50);   //,Use_Contact__c=True);
        Referral_Partner__c paspart = new Referral_Partner__c(Name = UserHelper.SO_PEO_ASO,CreateRefOpp__c=False, Partner_Type__c=SOARHelper.PARTNER_SOAR,
                                                              Selling_Opp_RecordTypeId__c='012500000000n4VAAQ',Sort_Order__c=40);   //,Use_Contact__c=True);
        Referral_Partner__c hrspart = new Referral_Partner__c(Name = UserHelper.SO_401,CreateRefOpp__c=False, Partner_Type__c=SOARHelper.PARTNER_SOAR,
                                                              Selling_Opp_RecordTypeId__c='012500000000n4QAAQ',Sort_Order__c=30);   //,Use_Contact__c=True);
        Referral_Partner__c[] refpartList = new Referral_Partner__c[]{paypart,mmspart,hnbfpart,paspart,hrspart};
            insert refpartList;
        
    } 
    
    static testMethod void testMisc() {
       HoldOutExpirationMethodsTest.populateSetting();
       User[] usrs = [Select Id, Name from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP limit 5];
        
       Account acct = new Account(Name='Test 1', MS_Hold_Out__c=true, MS_Hold_Out_Expiration__c=Date.today().addDays(30));
       ZipCheckOwner.SKIP_TRIGGERS=true;
       insert acct;
        
       HoldOut_ExpirationDates__c hoMS = HoldOutExpirationMethodsTest.hoMS;
       AccountTeamMember atm1 = new AccountTeamMember(AccountId=acct.Id,TeamMemberRole=hoMS.AccountTeamRole__c,UserId=usrs[0].Id);       
       insert atm1;
        
       User checkUser = SOARHelper.getAcctUser(acct, hoMS);
       System.assertEquals(usrs[0].Id, checkUser.Id);
        
    } // testMisc
    
    @isTest
    static void testCurrentClientReferral()	{       
        createReferralPartners(); // need to create ReferralPartners in order to create Opportunity
        
        List<SoarProductMapping__c> spmList = new List<SoarProductMapping__c>();
        
        SoarProductMapping__c spm;
        spm = new SoarProductMapping__c(Name='Prod01',AdvClient__c=false, Product__c='New Client',Sales_Org__c='PAY',Leverage_Current_Client_Owner__c=true); 
        spmList.add(spm);
        
        // Use the following User if no ZipTerritory (ZipAssignment is setup) for ZipSegment or Sales Org
        User coreAdminUser = [Select Id, Name, HR_Person_ID__c from User where Profile.Name like 'Core Zone Admin%' and IsActive = true limit 1];        
        spm = new SoarProductMapping__c(Name='Prod17',Default_Rep__c=coreAdminUser.Name, Default_Rep_HR_Person_ID__c=coreAdminUser.HR_Person_ID__c,Product__c='Unknown Rep',Sales_Org__c='PAY');         
        spmList.add(spm);

        insert spmList;        

        User[] users = [Select Id, Name, Sales_Org__c, HR_Person_Id__c from User where HR_Person_Id__c != null and IsActive=true and Sales_Org__c=:UserHelper.SO_CORE and Sales_Division__c in :Label.SMB_Channel_Divisions.split(',') limit 1];
        User uSMB = users[0];
        
        User runningUser = [Select Id, FirstName, LastName, Email, HR_Person_Id__c from User where Profile.Name=:Utilities.PROF_SYS_ADMIN and IsActive=true and HR_Person_Id__c != null limit 1];

        //Core Account Record Type
        RecordType rt  = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'CoreAccountRecordType'];
        Account smbAcct = new Account(Name = UserHelper.PAYCHEX_COMP, NumberOfEmployees=18, Bis_ID__c=464646, AccountNumber='1234-98745632',RecordTypeId=rt.Id, Type='FLEX Client',OwnerId=uSMB.Id);
        insert smbAcct;

        Contact payxEmp = new Contact(FirstName=runningUser.FirstName, LastName=runningUser.LastName, AccountId=smbAcct.Id, 
                              HR_Person_Id__c=runningUser.HR_Person_Id__c, Email=runningUser.Email);      
        insert payxEmp;
                
        String product = 'New Client';
        String addOnClient = 'No';
        String employeeCount = '18';
		String referralClientId = '98745632';
		String referralOfficeId = '1234';
        
        String soarMsg = '<SOARINFORMATION>\r  <EEEmail>'+ runningUser.Email +'</EEEmail>\r <PersonID>'+ runningUser.HR_Person_Id__c+'</PersonID>\r';
		soarMsg += '<ID></ID>\r <BIS></BIS>\r <CostCenter></CostCenter>\r';
        soarMsg += '<ClientNumber></ClientNumber>\r <CompanyName>Test Method New Company Client Name</CompanyName>\r <Address>1270 Creekbend Lane</Address>\r';
        soarMsg += '<City>Webster</City>\r <State>NY</State>\r <ZipCode>14625</ZipCode>\r <EmployeeCount>' + employeeCount + '</EmployeeCount>\r <Product>' + product + '</Product>\r';
        soarMsg += '<FirstName>Jeff</FirstName>\r <LastName>Elliott</LastName>\r <PhoneNumber>585-222-3434</PhoneNumber>\r';
        soarMsg += '<Platform>None</Platform>\r<AddOnClient>' + addOnClient + '</AddOnClient>\r<AdvClient>No</AdvClient>\r';
		soarMsg += '<referralBusId></referralBusId>\r<ReferralClientID>' + referralClientId + '</ReferralClientID>\r<ReferralOfficeID>' + referralOfficeId + '</ReferralOfficeID>\r';
        soarMsg += '<Notes>Big Notes<email address></Notes><SOARID>10</SOARID><Region>1</Region>\r </SOARINFORMATION>';         
        
        PartnerReferral__c partRef = new PartnerReferral__c(Source__c='SOAR', Comments__c='Pending', Description__c=soarMsg);
        insert partRef;
        
        SOARHelper.SoarRef sr = new SOARHelper.SoarRef();
        sr = SOARHelper.parseXml(soarMsg);
        sr.partRefId = partRef.id;
        
		List<SOARHelper.SoarRef> srList = new List<SOARHelper.SoarRef>();
		srList.add(sr);
        
        System.runAs(runningUser) {                    
            Test.startTest();
            
            SOARHelper.processSoarRef(srList);
            System.assertNotEquals(null, SOARHelper.spm, 'SPM should not be null.');

            Account newAcct = [Select Id, OwnerId, Premier_PBS_Account_Owner__r.Id,
                               (Select Id, Name, RecordTypeId, OwnerId from Opportunities) from Account 
                               where Name = 'Test Method New Company Client Name'];     
            
            System.assertNotEquals(null, newAcct, 'Account should not be null.');
            System.assertEquals(1, newAcct.Opportunities.size(), 'Incorrect Opportunities size.');
			
            User ou = [SELECT Id,Name, HR_Person_Id__c FROM User WHERE Id = :newAcct.Opportunities[0].OwnerId];
            System.assertEquals(uSMB.Id, ou.Id, 'Incorrect Opportunity Owner.');
            
            Test.stopTest();
        }        
    }
    
    @isTest
    static void testBadCurrentClientReferral()	{
        Boolean testPassed = false;
        createReferralPartners(); // need to create ReferralPartners in order to create Opportunity
        
        List<SoarProductMapping__c> spmList = new List<SoarProductMapping__c>();
        
        SoarProductMapping__c spm;
        spm = new SoarProductMapping__c(Name='Prod01',AdvClient__c=false, Product__c='New Client',Sales_Org__c='PAY',Leverage_Current_Client_Owner__c=true); 
        spmList.add(spm);
        
        // Use the following User if no ZipTerritory (ZipAssignment is setup) for ZipSegment or Sales Org
        User coreAdminUser = [Select Id, Name, HR_Person_ID__c from User where Profile.Name like 'Core Zone Admin%' and IsActive = true limit 1];        
        spm = new SoarProductMapping__c(Name='Prod17',Default_Rep__c=coreAdminUser.Name, Default_Rep_HR_Person_ID__c=coreAdminUser.HR_Person_ID__c,Product__c='Unknown Rep',Sales_Org__c='PAY');         
        spmList.add(spm);

        insert spmList;        

        User[] users = [Select Id, Name, Sales_Org__c, HR_Person_Id__c from User where HR_Person_Id__c != null and IsActive=true and Sales_Org__c=:UserHelper.SO_CORE and Sales_Division__c in :Label.SMB_Channel_Divisions.split(',') limit 1];
        User uSMB = users[0];
        
        User runningUser = [Select Id, FirstName, LastName, Email, HR_Person_Id__c from User where Profile.Name=:Utilities.PROF_SYS_ADMIN and IsActive=true and HR_Person_Id__c != null limit 1];

        //Core Account Record Type
        RecordType rt  = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'CoreAccountRecordType'];
        Account smbAcct = new Account(Name = UserHelper.PAYCHEX_COMP, NumberOfEmployees=18, Bis_ID__c=464646, AccountNumber='1234-98745632',RecordTypeId=rt.Id, Type='FLEX Client',OwnerId=uSMB.Id);
        insert smbAcct;

        Contact payxEmp = new Contact(FirstName=runningUser.FirstName, LastName=runningUser.LastName, AccountId=smbAcct.Id, 
                              HR_Person_Id__c=runningUser.HR_Person_Id__c, Email=runningUser.Email);      
        insert payxEmp;
                
        String product = 'New Client';
        String addOnClient = 'No';
        String employeeCount = '18';
		String referralClientId = '98745631';
		String referralOfficeId = '1235';
        
        String soarMsg = '<SOARINFORMATION>\r  <EEEmail>'+ runningUser.Email +'</EEEmail>\r <PersonID>'+ runningUser.HR_Person_Id__c+'</PersonID>\r';
		soarMsg += '<ID></ID>\r <BIS></BIS>\r <CostCenter></CostCenter>\r';
        soarMsg += '<ClientNumber></ClientNumber>\r <CompanyName>Test Method New Company Client Name</CompanyName>\r <Address>1270 Creekbend Lane</Address>\r';
        soarMsg += '<City>Webster</City>\r <State>NY</State>\r <ZipCode>14625</ZipCode>\r <EmployeeCount>' + employeeCount + '</EmployeeCount>\r <Product>' + product + '</Product>\r';
        soarMsg += '<FirstName>Jeff</FirstName>\r <LastName>Elliott</LastName>\r <PhoneNumber>585-222-3434</PhoneNumber>\r';
        soarMsg += '<Platform>None</Platform>\r<AddOnClient>' + addOnClient + '</AddOnClient>\r<AdvClient>No</AdvClient>\r';
		soarMsg += '<referralBusId></referralBusId>\r<ReferralClientID>' + referralClientId + '</ReferralClientID>\r<ReferralOfficeID>' + referralOfficeId + '</ReferralOfficeID>\r';
        soarMsg += '<Notes>Big Notes<email address></Notes><SOARID>10</SOARID><Region>1</Region>\r </SOARINFORMATION>';         
        
        PartnerReferral__c partRef = new PartnerReferral__c(Source__c='SOAR', Comments__c='Pending', Description__c=soarMsg);
        insert partRef;
        
        SOARHelper.SoarRef sr = new SOARHelper.SoarRef();
        sr = SOARHelper.parseXml(soarMsg);
        sr.partRefId = partRef.id;
        
		List<SOARHelper.SoarRef> srList = new List<SOARHelper.SoarRef>();
		srList.add(sr);
        
        System.runAs(runningUser) {                    
            Test.startTest();
            try{
            	SOARHelper.processSoarRef(srList);
            }
            catch(SOARHelper.SOARException ex){   
                testPassed = true;
            }    
            System.assertEquals(false, testPassed);
            Test.stopTest();
        }        
    }
    
} // SOARHelperTest