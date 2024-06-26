/* 
   
  History
  -------
  10/20/2022 Rohit Ranjan     Created
  


 */



@isTest
public class TimeTradeSTFBookMeetingRCCtrlTest {
    
    public static testmethod void setupData() {
        ReferralObjectsSync.SKIP_SYNC = true;
        
        Schema.RecordTypeInfo hrsRefAcctRt = RecordTypeHelper.getRecordType('HRS Referral Source Record Type', 'Referral_Account__c');
        Schema.RecordTypeInfo hrsRefCtctRt = RecordTypeHelper.getRecordType('HRS Referral Record Type', 'Referral_Contact__c');
        
        Referral_Account__c refacct = new Referral_Account__c (name = 'Referral Account1'
                                ,RecordTypeId=hrsRefAcctRt.getRecordTypeId()
                                ,Referral_Type__c = 'Broker'
                                ,Zip_Postal_Code__c = '10000'
                                ,To_Be_Deleted__c = false);
        insert refacct;
                
        Referral_Contact__c refcon1 = new Referral_Contact__c(Name = 'First Ref Ctct1'
                                ,RecordTypeId=hrsRefCtctRt.getRecordTypeId()
                                ,Phone__c = '585-555-1212'
                                ,Email__c = 'fLast1@abc.com'
                                ,Referral_Type__c = '100 Broker'
                                ,Referral_Account__c = refacct.Id
                                                             ,type__c = 'Demo',Customer_Key_Points__c='test',Customer_Success_Criteria__c= 'test');
        insert refcon1;
      
       list<user> userlist = new list<user>([select id,lastname,FirstName,Email,name from user where profile.name = 'System Administrator' limit 10]);
       System.debug('userlist = '+userlist);
        
        Sales_Engineer_TT_Mapping__c SETTMap = new Sales_Engineer_TT_Mapping__c();
        SETTMap.Sales_Engineer_Title__c = 'Developer';
        SETTMap.Sales_Rep_Job_Ttitle__c = 'Default';
        SETTMap.name = 'Default'; 
        insert SETTMap;
        System.debug('userlist[0] = '+userlist[0]);
        
        id userid = UserInfo.getUserId(); 
         Event evnt1 = new Event(Appointment_Type__c='Demo',WhatId=refcon1.Id
                          ,Subject='Other'
                          ,ownerid = userlist[0].id
                          //,owner.name = 'test'
                          ,ActivityDate=Date.today()
                          ,ActivityDateTime=DateTime.now()
                          ,DurationInMinutes=60);
        insert evnt1;

        
        TimeTrade_for_SE__c ttse = new TimeTrade_for_SE__c();
        ttse.name = 'Demo';
        ttse.Appointment_Type__c = 'Demo';
        ttse.Check_Customer_Key_Points__c = true;
        ttse.Check_Customer_Success_Criteria__c = true;
        ttse.Duration__c = '15%20Minutes';
        ttse.Location_Info__c = 'See WebEx Information Enclosed';
        ttse.Location_type__c = 'Physical';
        ttse.Message__c = 'WebEx Details:';
        ttse.Subject__c = 'Demo';
        insert ttse;
        
        Referral_Contact__c refContact = new Referral_Contact__c();
        PageReference pageRef = Page.TimeTradeSTFBookMeetingRC;
        Test.setCurrentPage(pageRef);
		System.currentPageReference().getParameters().put('type__c', 'Demo');
         ApexPages.StandardController sc = new ApexPages.StandardController(refcon1);
        TimeTradeSTFBookMeetingRCCtrl TT = new TimeTradeSTFBookMeetingRCCtrl(sc);
        TT.IncludeGroup = true;
        tt.attachment.name='Unit Test Attachment';
        tt.attachment.body=Blob.valueOf('Unit Test Attachment Body');

        TT.SaveRefCon();
        tt.getSEListAction();
        tt.RecentlyMetSalesEngineer = userlist[0];
        tt.getSalesEngineerList();
    }


}