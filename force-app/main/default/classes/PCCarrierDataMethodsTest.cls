/* 
   Test methods for the P_C_Carrier_Data__c object

   
  History
  -------
  12/22/2023 Carrie Marciano        Created

*/
@isTest
public class PCCarrierDataMethodsTest {
	public static String [] dqSalesOrgs = Label.PCQuoteDataSalesOrg.split(',');
    public static ID pcRT = Label.PCQuoteDataRecordTypeId;
    
    static testMethod void testSingleCarrierDataSameOppLOB() {    	                    
        Account acct = new Account(Name='ACCT1', Federal_ID_Number__c='86-7530913'
                                   ,ShippingStreet='23 Some Street', ShippingCity='SomeCity', ShippingState='NY', ShippingPostalCode='14623', ShippingCountry='US');
        insert acct;
        
        Contact ctct = new Contact(FirstName='Louis',LastName='Test1a',Email='louis@test1.com', MobilePhone='(585) 111-2222', AccountId=acct.id);
        insert ctct;
        
        Opportunity opp = new Opportunity(Name='PC OPP', AccountId=acct.Id, RecordTypeId = pcRT, OpportunityType__c = 'AUTO', HNBF_Sales_Type__c = 'New Case', CloseDate=Date.today().addDays(7), StageName = 'Discovery', Probability = 40, Tarmika_Quote__c = 'https://bridge.tarmika.com');
        insert opp;
        
        //initial insert of P&C Quote Data 
        PC_Quote_Data__c pcqD = new PC_Quote_Data__c(Opportunity__c = opp.Id, Prospect_Client__c=acct.Id, Opportunity_Type__c=opp.OpportunityType__c,Prospect_Client_Name__c=acct.Name,
                                                     Prospect_Client_Street__c=acct.ShippingStreet, Prospect_Client_City__c=acct.ShippingCity, Prospect_Client_State__c=acct.ShippingState,
                                                     Prospect_Client_Postal_Code__c=acct.ShippingPostalCode, Contact_First_Name__c=ctct.FirstName, Contact_Last_Name__c=ctct.LastName,
                                                     Contact_Phone_Number__c=ctct.Phone, Contact_Email_Address__c=ctct.Email);
        insert pcqD;
               
        //inserting P&C Carrier Data with inital response from Huckleberry
        P_C_Carrier_Data__c pccD = new P_C_Carrier_Data__c(P_C_Quote_Data__c = pcqD.Id, Line_of_Business__c = 'CA', Carrier_Name__c = 'Farmers', Quote_Carrier_ID__c = '47-87451233', Quote_Request_ID__c = '8754210000', Quote_Premium__c = 1205.36, Quote_Status__c = 'BINDABLE');
        insert pccD;
        
    	P_C_Carrier_Data__c pccD2 = [Select Id, P_C_Quote_Data__c, Opportunity__c, Opportunity__r.StageName, Line_of_Business__c, Carrier_Name__c, Quote_Carrier_ID__c, Quote_Premium__c, Quote_Status__c from P_C_Carrier_Data__c where Id =:pccD.Id];
        System.assertEquals('BINDABLE', pccD2.Quote_Status__c);
        System.assertEquals('Proposal', pccD2.Opportunity__r.StageName);
        
        //updating P&C Carrier Data with Policy Number adn Policy Bind Date response from Huckleberry - update opportunity
        pccD.Policy_Carrier_ID__c = '25478152';
        pccD.Policy_Bind_Date__c = Date.today();
        update pccD;
        
        P_C_Carrier_Data__c pccD3 = [Select Id, P_C_Quote_Data__c, Opportunity__c, Opportunity__r.StageName, Policy_Carrier_ID__c, Policy_Bind_Date__c from P_C_Carrier_Data__c where Id =:pccD.Id];
        System.assertEquals('25478152', pccD3.Policy_Carrier_ID__c);
        System.assertEquals(Date.today(), pccD3.Policy_Bind_Date__c);
        System.assertEquals('Sold-Submitted', pccD3.Opportunity__r.StageName);
        
    } //testSingleCarrierDataSameOppLOB
    
    static testMethod void testSingleCarrierDataSameOppLOBUpdates(){ 	                    
        Account acct = new Account(Name='ACCT1', Federal_ID_Number__c='86-7530913'
                                   ,ShippingStreet='23 Some Street', ShippingCity='SomeCity', ShippingState='NY', ShippingPostalCode='14623', ShippingCountry='US');
        insert acct;
        
        Contact ctct = new Contact(FirstName='Louis',LastName='Test1a',Email='louis@test1.com', MobilePhone='(585) 111-2222', AccountId=acct.id);
        insert ctct;
        
        Opportunity opp = new Opportunity(Name='PC OPP', AccountId=acct.Id, RecordTypeId = pcRT, OpportunityType__c = 'AUTO', HNBF_Sales_Type__c = 'New Case', CloseDate=Date.today().addDays(7), StageName = 'Discovery', Probability = 40, Tarmika_Quote__c = 'https://bridge.tarmika.com');
        insert opp;
        
        Id caseRTId = RecordTypeHelper.getRecordType('Service Onboarding P&C Case', 'Case').getRecordTypeID();
        Case kase  = new Case(AccountId = acct.id, Opportunity__c = opp.id, recordtypeId = caseRTId);
        insert kase;
        
        Id refPCTypeId = RecordTypeHelper.getRecordType('P&C Onboarding', 'Reference_P_C__c').getRecordTypeID();
        Reference_P_C__c refPC = new Reference_P_C__c(Case_Lookup__c = kase.id, Opportunity_Lookup__c = opp.id, recordTypeId = refPCTypeId);
        insert refPC;
        
        //initial insert of P&C Quote Data 
        PC_Quote_Data__c pcqD = new PC_Quote_Data__c(Opportunity__c = opp.Id, Prospect_Client__c=acct.Id, Opportunity_Type__c=opp.OpportunityType__c,Prospect_Client_Name__c=acct.Name,
                                                     Prospect_Client_Street__c=acct.ShippingStreet, Prospect_Client_City__c=acct.ShippingCity, Prospect_Client_State__c=acct.ShippingState,
                                                     Prospect_Client_Postal_Code__c=acct.ShippingPostalCode, Contact_First_Name__c=ctct.FirstName, Contact_Last_Name__c=ctct.LastName,
                                                     Contact_Phone_Number__c=ctct.Phone, Contact_Email_Address__c=ctct.Email);
        insert pcqD;
               
        //inserting P&C Carrier Data with inital response from Huckleberry
        P_C_Carrier_Data__c pccD = new P_C_Carrier_Data__c(P_C_Quote_Data__c = pcqD.Id, Line_of_Business__c = 'CA', Carrier_Name__c = 'Farmers', Quote_Carrier_ID__c = '47-87451233', Quote_Request_ID__c = '8754210000', Quote_Premium__c = 1205.36, Quote_Status__c = 'Quoted');
        insert pccD;
        
    	P_C_Carrier_Data__c pccD2 = [Select Id, P_C_Quote_Data__c, Opportunity__c, Opportunity__r.StageName, Line_of_Business__c, Carrier_Name__c, Quote_Carrier_ID__c, Quote_Premium__c, Quote_Status__c from P_C_Carrier_Data__c where Id =:pccD.Id];
        System.assertEquals('Quoted', pccD2.Quote_Status__c);
        
        //updating P&C Carrier Data with Quote Status response from Huckleberry - update opportunity
        pccD.Quote_Status__c = 'BINDABLE';
        update pccD;
        
        P_C_Carrier_Data__c pccD3 = [Select Id, P_C_Quote_Data__c, Opportunity__c, Opportunity__r.StageName, Line_of_Business__c, Carrier_Name__c, Quote_Carrier_ID__c, Quote_Premium__c, Quote_Status__c from P_C_Carrier_Data__c where Id =:pccD.Id];
        System.assertEquals('BINDABLE', pccD3.Quote_Status__c);
        System.assertEquals('Proposal', pccD3.Opportunity__r.StageName);
        
        //updating P&C Carrier Data with Policy Number adn Policy Bind Date response from Huckleberry - update opportunity
        pccD.Policy_Carrier_ID__c = '25478152';
        pccD.Policy_Bind_Date__c = Date.today();
        pccD.Renewal_Date__c = Date.today()+365;
        update pccD;
        
        P_C_Carrier_Data__c pccD4 = [Select Id, P_C_Quote_Data__c, Opportunity__c, Opportunity__r.StageName, Renewal_Date__c, Policy_Carrier_ID__c, Policy_Bind_Date__c from P_C_Carrier_Data__c where Id =:pccD.Id];
        System.assertEquals('25478152', pccD4.Policy_Carrier_ID__c);
        System.assertEquals(Date.today(), pccD4.Policy_Bind_Date__c);
        System.assertEquals('Sold-Submitted', pccD4.Opportunity__r.StageName);
        
    } //testSingleCarrierDataSameOppLOBUpdates
    
    static testMethod void testSingleCarrierDataNonOppLOB() {
    	 Account acct = new Account(Name='ACCT1', Federal_ID_Number__c='86-7530913'
                                   ,ShippingStreet='23 Some Street', ShippingCity='SomeCity', ShippingState='NY', ShippingPostalCode='14623', ShippingCountry='US');
        insert acct;
        
        Contact ctct = new Contact(FirstName='Louis',LastName='Test1a',Email='louis@test1.com', MobilePhone='(585) 111-2222', AccountId=acct.id);
        insert ctct;
        
        Opportunity opp = new Opportunity(Name='PC OPP', AccountId=acct.Id, RecordTypeId = pcRT, OpportunityType__c = 'BOP (Business Owners Package)', HNBF_Sales_Type__c = 'New Case', CloseDate=Date.today().addDays(7), StageName = 'Discovery', Probability = 40, Tarmika_Quote__c = 'https://bridge.tarmika.com');
        insert opp;
        
        //initial insert of P&C Quote Data 
        PC_Quote_Data__c pcqD = new PC_Quote_Data__c(Opportunity__c = opp.Id, Prospect_Client__c=acct.Id, Opportunity_Type__c=opp.OpportunityType__c,Prospect_Client_Name__c=acct.Name,
                                                     Prospect_Client_Street__c=acct.ShippingStreet, Prospect_Client_City__c=acct.ShippingCity, Prospect_Client_State__c=acct.ShippingState,
                                                     Prospect_Client_Postal_Code__c=acct.ShippingPostalCode, Contact_First_Name__c=ctct.FirstName, Contact_Last_Name__c=ctct.LastName,
                                                     Contact_Phone_Number__c=ctct.Phone, Contact_Email_Address__c=ctct.Email);
        insert pcqD;
               
        //inserting P&C Carrier Data with inital response from Huckleberry
        P_C_Carrier_Data__c pccD = new P_C_Carrier_Data__c(P_C_Quote_Data__c = pcqD.Id, Line_of_Business__c = 'Financial', Carrier_Name__c = 'Citizens', Quote_Carrier_ID__c = '784522-45', Quote_Request_ID__c = '00000452', Quote_Premium__c = 1205.36, Quote_Status__c = 'BINDABLE');
        insert pccD;
        
    	P_C_Carrier_Data__c pccD2 = [Select Id, P_C_Quote_Data__c, Opportunity__c, Opportunity__r.StageName, Opportunity__r.AdditionalProductsOfInterest__c, Line_of_Business__c, Carrier_Name__c, Quote_Carrier_ID__c, Quote_Premium__c, Quote_Status__c from P_C_Carrier_Data__c where Id =:pccD.Id];
        System.assertEquals(null, pccD2.Opportunity__c);
        Opportunity origOpp = [Select Id, Name, OpportunityType__c, AdditionalProductsOfInterest__c from Opportunity where Id = :opp.Id];
        System.assertEquals('Financial', origOpp.AdditionalProductsOfInterest__c);
         
    } //testSingleCarrierDataNonOppLOB 
    
    static testMethod void testMultipleCarrierDataSameOppLOB() {    	                    
	 	Account acct = new Account(Name='ACCT1', Federal_ID_Number__c='86-7530913'
                                   ,ShippingStreet='23 Some Street', ShippingCity='SomeCity', ShippingState='NY', ShippingPostalCode='14623', ShippingCountry='US');
        insert acct;
        
        Contact ctct = new Contact(FirstName='Louis',LastName='Test1a',Email='louis@test1.com', MobilePhone='(585) 111-2222', AccountId=acct.id);
        insert ctct;
        
        Opportunity opp = new Opportunity(Name='PC OPP', AccountId=acct.Id, RecordTypeId = pcRT, OpportunityType__c = 'Umbrella', HNBF_Sales_Type__c = 'New Case', CloseDate=Date.today().addDays(7), StageName = 'Discovery', Probability = 40, Tarmika_Quote__c = 'https://bridge.tarmika.com');
        insert opp;
        
        //initial insert of P&C Quote Data 
        PC_Quote_Data__c pcqD = new PC_Quote_Data__c(Opportunity__c = opp.Id, Prospect_Client__c=acct.Id, Opportunity_Type__c=opp.OpportunityType__c,Prospect_Client_Name__c=acct.Name,
                                                     Prospect_Client_Street__c=acct.ShippingStreet, Prospect_Client_City__c=acct.ShippingCity, Prospect_Client_State__c=acct.ShippingState,
                                                     Prospect_Client_Postal_Code__c=acct.ShippingPostalCode, Contact_First_Name__c=ctct.FirstName, Contact_Last_Name__c=ctct.LastName,
                                                     Contact_Phone_Number__c=ctct.Phone, Contact_Email_Address__c=ctct.Email);
        insert pcqD;
               
        //inserting P&C Carrier Data with inital response from Huckleberry
        P_C_Carrier_Data__c pccD1 = new P_C_Carrier_Data__c(P_C_Quote_Data__c = pcqD.Id, Line_of_Business__c = 'UMB', Carrier_Name__c = 'Farmers', Quote_Carrier_ID__c = '47-87451233', Quote_Request_ID__c = '8754210000', Quote_Premium__c = 1205.36, Quote_Status__c = 'BINDABLE');
        P_C_Carrier_Data__c pccD2 = new P_C_Carrier_Data__c(P_C_Quote_Data__c = pcqD.Id, Line_of_Business__c = 'UMB', Carrier_Name__c = 'Mutual', Quote_Carrier_ID__c = '35-8547521', Quote_Request_ID__c = '8754210001', Quote_Premium__c = 1300.66, Quote_Status__c = 'BINDABLE');
        P_C_Carrier_Data__c pccD3 = new P_C_Carrier_Data__c(P_C_Quote_Data__c = pcqD.Id, Line_of_Business__c = 'UMB', Carrier_Name__c = 'Liberty', Quote_Carrier_ID__c = '60-74125896', Quote_Request_ID__c = '8754210002', Quote_Premium__c = 1175.42, Quote_Status__c = 'BINDABLE');
        P_C_Carrier_Data__c[] pccDs = new P_C_Carrier_Data__c[]{pccD1,pccD2,pccD3};
        insert pccDs;
        
    	P_C_Carrier_Data__c[] pccDs2 = [Select Id, P_C_Quote_Data__c, Opportunity__c, Opportunity__r.StageName, Line_of_Business__c, Carrier_Name__c, Quote_Carrier_ID__c, Quote_Premium__c, Quote_Status__c from P_C_Carrier_Data__c where Id in :pccDs];
        System.assertEquals(opp.Id, pccDs2[0].Opportunity__c);
        System.assertEquals(opp.Id, pccDs2[1].Opportunity__c);
        System.assertEquals(opp.Id, pccDs2[2].Opportunity__c);
       
    } //testMultipleCarrierDataSameOppLOB

    static testMethod void testMultipleCarrierDataMultipleLOB() {
    	Account acct = new Account(Name='ACCT1', Federal_ID_Number__c='86-7530913'
                                   ,ShippingStreet='23 Some Street', ShippingCity='SomeCity', ShippingState='NY', ShippingPostalCode='14623', ShippingCountry='US');
        insert acct;
        
        Contact ctct = new Contact(FirstName='Louis',LastName='Test1a',Email='louis@test1.com', MobilePhone='(585) 111-2222', AccountId=acct.id);
        insert ctct;
        
        Opportunity opp = new Opportunity(Name='PC OPP', AccountId=acct.Id, RecordTypeId = pcRT, OpportunityType__c = 'BOP (Business Owners Package)', HNBF_Sales_Type__c = 'New Case', CloseDate=Date.today().addDays(7), StageName = 'Discovery', Probability = 40, Tarmika_Quote__c = 'https://bridge.tarmika.com');
        insert opp;
        
        OpportunityContactRole ocr = new OpportunityContactRole(OpportunityId=opp.Id,ContactId=ctct.Id,IsPrimary=true,Role='Other');
      	insert ocr;
        
        User[] users = [Select Id, Name from User where IsActive=true and Id != :UserInfo.getUserId() and Sales_Org__c in :UserHelper.DIVISION_LIST limit 3];
        OpportunityTeamMember otm1 = new OpportunityTeamMember(OpportunityId=opp.Id,UserId=users[0].Id,TeamMemberRole='Test Role');
        OpportunityTeamMember otm2 = new OpportunityTeamMember(OpportunityId=opp.Id,UserId=users[1].Id,TeamMemberRole='Test Role');
        OpportunityTeamMember[] otms = new OpportunityTeamMember[]{otm1,otm2};
        insert otms;
        
        //initial insert of P&C Quote Data 
        PC_Quote_Data__c pcqD = new PC_Quote_Data__c(Opportunity__c = opp.Id, Prospect_Client__c=acct.Id, Opportunity_Type__c=opp.OpportunityType__c,Prospect_Client_Name__c=acct.Name,
                                                     Prospect_Client_Street__c=acct.ShippingStreet, Prospect_Client_City__c=acct.ShippingCity, Prospect_Client_State__c=acct.ShippingState,
                                                     Prospect_Client_Postal_Code__c=acct.ShippingPostalCode, Contact_First_Name__c=ctct.FirstName, Contact_Last_Name__c=ctct.LastName,
                                                     Contact_Phone_Number__c=ctct.Phone, Contact_Email_Address__c=ctct.Email);
        insert pcqD;
               
        //inserting P&C Carrier Data with inital response from Huckleberry
        P_C_Carrier_Data__c pccD1 = new P_C_Carrier_Data__c(P_C_Quote_Data__c = pcqD.Id, Line_of_Business__c = 'WC', Carrier_Name__c = 'Farmers', Quote_Carrier_ID__c = '47-87451233', Quote_Request_ID__c = '8754210000', Quote_Premium__c = 1205.36, Quote_Status__c = 'BINDABLE');
        P_C_Carrier_Data__c pccD2 = new P_C_Carrier_Data__c(P_C_Quote_Data__c = pcqD.Id, Line_of_Business__c = 'CYB', Carrier_Name__c = 'Mutual', Quote_Carrier_ID__c = '35-8547521', Quote_Request_ID__c = '8754210001', Quote_Premium__c = 1300.66, Quote_Status__c = 'BINDABLE');
        P_C_Carrier_Data__c pccD3 = new P_C_Carrier_Data__c(P_C_Quote_Data__c = pcqD.Id, Line_of_Business__c = 'GL', Carrier_Name__c = 'Liberty', Quote_Carrier_ID__c = '60-74125896', Quote_Request_ID__c = '8754210002', Quote_Premium__c = 1175.42, Quote_Status__c = 'BINDABLE');
        P_C_Carrier_Data__c[] pccDs = new P_C_Carrier_Data__c[]{pccD1,pccD2,pccD3};
        insert pccDs;
        
    	P_C_Carrier_Data__c[] pccDs2 = [Select Id, P_C_Quote_Data__c, Opportunity__c, Opportunity__r.StageName, Line_of_Business__c, Carrier_Name__c, Quote_Carrier_ID__c, Quote_Premium__c, Quote_Status__c from P_C_Carrier_Data__c where Id in :pccDs];
        System.assertNotEquals(opp.Id, pccDs2[0].Opportunity__c);
        System.assertNotEquals(opp.Id, pccDs2[1].Opportunity__c);
        System.assertNotEquals(opp.Id, pccDs2[2].Opportunity__c);    
    } //testMultipleCarrierDataMultipleLOB 
    
    
}