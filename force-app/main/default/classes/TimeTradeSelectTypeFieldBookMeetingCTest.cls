@istest
public class TimeTradeSelectTypeFieldBookMeetingCTest {
 
    public static testmethod void setupData() {
       Opportunity opp1 = new Opportunity(Name='Opp1a',type__c = 'Demo',StageName='Pending',CloseDate=Date.today().addDays(7),OpportunityType__c='TestType1',Customer_Key_Points__c='test',Customer_Success_Criteria__c= 'test');
       insert opp1;
       list<user> userlist = new list<user>([select id,lastname,FirstName,Email,name from user where profile.name = 'System Administrator' limit 10]);
       System.debug('userlist = '+userlist);
        
        Sales_Engineer_TT_Mapping__c SETTMap = new Sales_Engineer_TT_Mapping__c();
        SETTMap.Sales_Engineer_Title__c = 'Developer';
        SETTMap.Sales_Rep_Job_Ttitle__c = 'Default';
        SETTMap.name = 'Default'; 
        insert SETTMap;
       System.debug('userlist[0] = '+userlist[0]);
        
        id userid = UserInfo.getUserId(); 
         Event evnt1 = new Event(Appointment_Type__c='Demo',WhatId=opp1.Id
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
        

        list<OpportunityTeamMember> opptList = new list<OpportunityTeamMember>();
       for(integer i=0;i<10;i++)
       {
			OpportunityTeamMember otm = new OpportunityTeamMember();
            otm.OpportunityId = opp1.id;
           otm.UserId = userlist[i].id;
           otm.TeamMemberRole = 'Pre-Sales Consultant';
           opptList.add(otm);
       }
        insert opptList;
        
        opportunity opp = new opportunity();
        PageReference pageRef = Page.TimeTradeSelectTypeFieldBookMeeting;
        Test.setCurrentPage(pageRef);
		System.currentPageReference().getParameters().put('type__c', 'Demo');
         ApexPages.StandardController sc = new ApexPages.StandardController(opp1);
        TimeTradeSelectTypeFieldBookMeetingCtrl TT = new TimeTradeSelectTypeFieldBookMeetingCtrl(sc);
        TT.IncludeGroup = true;
        tt.attachment.name='Unit Test Attachment';
        tt.attachment.body=Blob.valueOf('Unit Test Attachment Body');

        TT.SaveOpportunity();
        tt.getSEListAction();
        tt.RecentlyMetSalesEngineer = userlist[0];
        tt.getSalesEngineerList();
    }

}