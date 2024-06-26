/*
   
  History
  -------
  02/13/2014 Justin Henderson   Created
  11/04/2015 Dan Carmen         Modifications to the test methods
  11/21/2018 Frank Lurz         This code can be retired/deleted per Case #30679020
  
 */
@isTest(SeeAllData=true)
public class HRS4SChatterPostTest{
    static testMethod void testPost(){
        
       user u1 = [Select Id, Name, DSA_FSS__c, FirstName, LastName from User where HR_Person_Id__c != null and IsActive=true and DSA_FSS__c != null and Sales_Org__c=:UserHelper.SO_CORE limit 1];
        system.debug('**JRH HRS4SChatterPostTest - User'+ u1.Id);
        
       user u2 = [Select Id, Name, DSA_FSS__c, FirstName, LastName from User where HR_Person_Id__c != null and IsActive=true and DSA_FSS__c != null and Sales_Org__c=:UserHelper.SO_CORE limit 1];
        system.debug('**JRH HRS4SChatterPostTest - User' + u2.Id);
        
       Account a = new Account(Name = 'Test Account', 
                               NumberOfEmployees = 18,
                               type = 'MMS Client',
                               Frequency__c = '24',
                               Current_Prior_Method__c = 'ADP',
                               BillingPostalCode = '14424',
                               AccountNumber = '83-1234567',
                               Do_Not_Call__c = true,
                               Email_Opt_Out__c = true,
                               AnnualRevenue = 25);
       insert a;
        system.debug('**JRH HRS4SChatterPostTest - insert Account ' + a.id);
        
       Case c = new Case(AccountId=a.id,
                         OwnerId = u1.id,
                         RecordTypeId = '01270000000Q5Vs',
                         Status = 'New',
                         Origin = 'Email',
                         Product__c = '401k',
                         HRS4SCategory1__c = 'Loans',
                         Disposition_1__c = 'Change of Ownership');
       insert c;
        system.debug('**JRH HRS4SChatterPostTest - insert case ' + c.id);
        
       
       Reference_401k_S125__c r = [Select Id, OwnerId from Reference_401k_S125__c where Case_Lookup__c = :c.Id];
        system.debug('**JRH HRS4SChatterPostTest - Ref401 Select' + r.Id);
        
       HRS_4S_Discrepancy__c disc = new HRS_4S_Discrepancy__c(Reference_401k_S125__c = r.Id,                                                              
                                                              Sales_Rep__c = u1.Id,
                                                              FSS__c = u2.Id,
                                                              Discrepancy_Type__c = 'First Discrepancy');
       insert disc;
       
      system.debug('**JRH HRS4SChatterPostTest - insert Discrepancy' + disc.Id);
       
        
       ///list<feedItem> hrsFIList = [Select Id, Body from feedItem where parentId = :disc.id];
        
       ///system.assert(!hrsFIList.isEmpty());
        
 /******************************************************************Disc1Test
 */
       /***HRS_4S_Discrepancy__c disc1 = new HRS_4S_Discrepancy__c(Reference_401k_S125__c = r.Id,                                                               
                                                               Discrepancy_Type__c = 'First Discrepancy');***/
        
       ///insert disc1;
       ///system.debug('**JRH HRS4SChatterPostTest - insert Discrepancy' + disc1.Id);
       ///list<feedItem> hrsFIList1 = [Select Id, Body from feedItem where parentId = :disc1.id];
       ///system.assert(hrsFIList1.isEmpty());
        
 /******************************************************************Disc2Test
 */
       /***HRS_4S_Discrepancy__c disc2 = new HRS_4S_Discrepancy__c(Reference_401k_S125__c = r.Id,
                                                               Sales_Rep__c = u1.Id,
                                                               Discrepancy_Type__c = 'First Discrepancy');***/
        
       ///insert disc2;
       ///system.debug('**JRH HRS4SChatterPostTest - insert Discrepancy' + disc2.Id);
        
       ///HRS_4S_Discrepancy__c d = [Select Id, FSS__c from HRS_4S_Discrepancy__c where Id = :disc2.Id];
       ///system.debug('**JRH HRS4SChatterPostTest - DiscrepancyTest2'+ d.Id);
        
       ///system.assertEquals(u1.DSA_FSS__c, d.FSS__c);
        
       ///list<feedItem> hrsFIList2 = [Select Id, Body from feedItem where parentId = :disc2.id];
       ///string fssName = [select name from user where id = :u1.DSA_FSS__c Limit 1][0].name;
       ///system.assert(!hrsFIList2.isEmpty());
       ///system.assertEquals('Hello @' + u1.name + ' @' + fssName + '. '+HRS4SChatterPost.MSG_PART1 + a.Name + HRS4SChatterPost.MSG_PART2, hrsFIList2[0].body);
       ///system.debug('**JRH HRS4SChatterPostTest - hrsFIList' + hrsFIList2[0].body);
          
       //system.assertEquals('Hello @' + u1.name + ' @' + u2.name + '. '+HRS4SChatterPost.MSG_PART1 + a.Name + HRS4SChatterPost.MSG_PART2, hrsFIList[0].body);
       ///system.debug('**JRH HRS4SChatterPostTest - hrsFIList' + hrsFIList[0].body);
    }          
} // class HRS4SChatterPostTest