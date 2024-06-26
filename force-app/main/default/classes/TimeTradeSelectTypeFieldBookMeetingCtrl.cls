/* Controller class for TimeTradeSelectTypeFieldBookMeeting

History
-------
01/14/2021 Pradeep Garlapaati       Created


10/17/2022  Rohit Ranjan  Added functionality for Team Venture Sales Engineer group and auto populate subject field in getTTUrl method
03/16/2023  Rohit Ranjan  APR0137745 Added new Long Text Area field Exclude_Sales_Engg__c replacing Exclude_Sales_Engineer__c
10/22/2023  Pratik Das    APR0157374: Update Book Meeting process 
3/21/2024   Susmitha Somavarapu APR0167864:INC3637662 Salesforce | Meeting scheduling error(removing special character #)

*/

public class TimeTradeSelectTypeFieldBookMeetingCtrl {
    
    private Apexpages.StandardController controller;
    public string SalesEngineer{get;set;}
    public user RecentlyMetSalesEngineer{get;set;}
    public boolean IncludeGroup{get;set;}
    public  opportunity opp;
    public list<user> SEPicklistValues = new list<user>();
    public  opportunity opp1{get;set;}
    public id Currentuserid;// = UserInfo.getUserId(); 
    public User CurrentUser = new user();
    public Map<String,Sales_Engineer_TT_Mapping__c> TTMap = new Map<String,Sales_Engineer_TT_Mapping__c>();
    //APR0157374: Update Book Meeting process --Start
    public Id oppOwnerId;
    //APR0157374: Update Book Meeting process --End
    
    Public List<Selectoption> getSalesEngineerList(){
        List<Selectoption> SEList = new List<selectoption>();
        set<id> SEListids = new set<id>();
        SEList.add(new selectOption('', '- None -'));
        for(User u : SEPicklistValues){
            SEListids.add(u.id);
            SEList.add(new selectoption(u.id,u.name));
        }
        if(RecentlyMetSalesEngineer != null && !SEListids.contains(RecentlyMetSalesEngineer.Id))
        {
            SEList.add(new selectOption(RecentlyMetSalesEngineer.Id, RecentlyMetSalesEngineer.lastname));
        }
        return SEList; 
    }
    
    public  String TT_CACHEKEY='TTMappingCacheKey';
    
    public  void getSEListAction(){
        getSEList();
    }
    
    public  user[] getSEList() {
        String[] SETitlesforRep;
        String[] PEORolesforRep;
        String[] IncludeSEs;
        String[] ExcludeSEs;
        user[] SEList;
        TTMap = getTTMap();
        
        if(Currentuserid != opp.ownerid)
        {
            CurrentUser = [select id,title,sales_org__c,name,lastname,firstname from user where id =: Currentuserid];
        }
        else
        {
            CurrentUser.Title =  opp.owner.title; 
            CurrentUser.Sales_Org__c = opp.owner.sales_org__c;           
            CurrentUser.lastname = opp.owner.lastname;  
            Currentuser.FirstName = opp.owner.firstname;
        }
        for(String SalesRepTitle : TTMap.keyset())
        {
            if(SalesRepTitle == CurrentUser.Title && TTMap.get(SalesRepTitle).name == CurrentUser.Sales_Org__c)
            {
                SETitlesforRep = TTMap.get(SalesRepTitle).Sales_Engineer_Title__c != null ? TTMap.get(SalesRepTitle).Sales_Engineer_Title__c.split(',') : null;
                PEORolesforRep = TTMap.get(SalesRepTitle).PEO_Strategic_Role__c != null ? TTMap.get(SalesRepTitle).PEO_Strategic_Role__c.split(',') : null;
                IncludeSEs = TTMap.get(SalesRepTitle).Include_Sales_Engineer__c != null ? TTMap.get(SalesRepTitle).Include_Sales_Engineer__c.split(',') : null;
                ExcludeSEs = TTMap.get(SalesRepTitle).Exclude_Sales_Engg__c != null ? TTMap.get(SalesRepTitle).Exclude_Sales_Engg__c.split(',') : null;
            }
        }
        
        SEList = getSEList(SETitlesforRep,PEORolesforRep,IncludeSEs,ExcludeSEs);
        
        if(SEList.size() == 0){
            SETitlesforRep = TTMap.get('Default').Sales_Engineer_Title__c != null ? TTMap.get('Default').Sales_Engineer_Title__c.split(',') : null;
            PEORolesforRep = TTMap.get('Default').PEO_Strategic_Role__c != null ? TTMap.get('Default').PEO_Strategic_Role__c.split(',') : null;
            IncludeSEs	  = TTMap.get('Default').Include_Sales_Engineer__c != null ? TTMap.get('Default').Include_Sales_Engineer__c.split(',') : null;
            ExcludeSEs 	  = TTMap.get('Default').Exclude_Sales_Engg__c != null ? TTMap.get('Default').Exclude_Sales_Engg__c.split(',') : null;
            SEList = getSEList(SETitlesforRep,PEORolesforRep,IncludeSEs,ExcludeSEs);
            sendDefaultUsedEmail(CurrentUser.FirstName+' '+CurrentUser.LastName,CurrentUser.Title);
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'No Sales Engineers found for this user title, displaying default list'));
        }
        
        SEPicklistValues.addAll(SEList);
        return SEList;        
        
    }
    
    public  user[] getSEList(String[] SETitlesforRep,String[] PEORolesforRep, String[] IncludeSEs, String[] ExcludeSEs) {
        list<user> SEListwithoutExcluding = new list<user>();
        list<user> SEList = new list<user>();
        
        String Query;
        
        if(SETitlesforRep != null && PEORolesforRep != null)
        {
            Query = 'select id,name,email from user where isActive = true AND (title IN : SETitlesforRep OR UserRole.name IN : PEORolesforRep';
        }
        else if(SETitlesforRep != null && PEORolesforRep == null)
        {
            Query = 'select id,name,email from user where isActive = true AND (title IN : SETitlesforRep';
        }
        else if(SETitlesforRep == null && PEORolesforRep != null)
        {
            Query = 'select id,name,email from user where isActive = true AND (UserRole.name IN : PEORolesforRep';
        }
        
        if(query != null && IncludeSEs != null)
        {
            Query = Query+' or Email IN : IncludeSEs)';
        }
        if(query != null && IncludeSEs == null)
        {
            Query = Query+')';
        }
        
        if(query == null && IncludeSEs != null)
        {
            Query ='select id,name,email from user where Email IN : IncludeSEs and isActive = true';
        }
        
        System.debug('query = '+query);
        if(query != null)
        {
            SEListwithoutExcluding = database.query(query);
        }
        if(ExcludeSEs != null)
        {
            for(user u : SEListwithoutExcluding)
            {
                if(!ExcludeSEs.contains(u.email)) 
                {
                    SEList.add(u); 
                }
            }
        }
        else
        {
            SEList = SEListwithoutExcluding;
        }
        return SEList;
        
    }
    
    public  void sendDefaultUsedEmail(String OpptyOwner, String OpptyOwnerTitle) { 
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = Label.NotifyTTMapDefaultUsed.split(',');
        mail.setToAddresses(toAddresses);
        mail.setSaveAsActivity(false);
        mail.setSubject('TimeTrade Mapping not Found for '+OpptyOwnerTitle);
        String body = 'Hi, Timetrade Mapping is not found for '+OpptyOwner+' with the title '+OpptyOwnerTitle+', default mapping used';
        
        mail.setPlainTextBody (body);
        if(!test.isRunningTest()){
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
    } //sendDefaultUsedEmail   
    
    public  Map<String,Sales_Engineer_TT_Mapping__c> getTTMap() {
        
        Map<String,Sales_Engineer_TT_Mapping__c> TTMp = (Map<String,Sales_Engineer_TT_Mapping__c>)CacheManager.getOrg(TT_CACHEKEY);
        
        if (TTMp == null) {
            TTMp = new Map<String,Sales_Engineer_TT_Mapping__c>();
            for(Sales_Engineer_TT_Mapping__c SRJT : [Select id,name,PEO_Strategic_Role__c,Sales_Engineer_Title__c,Sales_Rep_Job_Ttitle__c,Include_Sales_Engineer__c,Exclude_Sales_Engg__c from Sales_Engineer_TT_Mapping__c])
            {
                TTMp.put(SRJT.Sales_Rep_Job_Ttitle__c,SRJT); 
            }
            CacheManager.putOrg(TT_CACHEKEY,TTMp);
        }
        System.debug('TTMp = '+TTMp);
        return TTMp;
    }//getTTMap
    
    public  Attachment attachment {
        get { if (attachment == null) attachment = new Attachment(); return attachment; } set; 
    }
    
    public TimeTradeSelectTypeFieldBookMeetingCtrl(Apexpages.StandardController controller) {
        Currentuserid = UserInfo.getUserId(); 
        this.controller = controller;
        opp1 = (opportunity)controller.getRecord();
        String TypeVal = ApexPages.currentPage().getParameters().get('type__c');
        opp1.Type__c = TypeVal;
        list<String> EventTypeToCheckSE = new list<String>();
        for(TimeTrade_for_SE__c tt : TimeTrade_for_SE__c.getall().values())
        {
            EventTypeToCheckSE.add(tt.name); 
        }
        Date CheckSEMetInLast30Days = system.today().addDays(-30);
        //APR0157374: Update Book Meeting process--ownerid for Opportunity added in the query
        opp = [select id,type__c,Customer_Key_Points__c,Customer_Success_Criteria__c,owner.title,owner.name,
               owner.sales_org__c,owner.firstname,owner.lastname,Account.Name,ownerid,
               (select id,ownerid,owner.name from events
                where StartDateTime >: CheckSEMetInLast30Days 
                and Appointment_Type__c in: EventTypeToCheckSE 
                and owner.profile.name = 'Sales Engineer' 
                order by createddate Desc limit 1)
               from opportunity where id =: opp1.id limit 1];
        //APR0157374: Update Book Meeting process --Start
        oppOwnerId=opp.ownerid;
        //APR0157374: Update Book Meeting process --End
        
        if(opp.Events.size() > 0)
        {
            Event ev = opp.Events;
            RecentlyMetSalesEngineer = new user();
            RecentlyMetSalesEngineer.id = ev.OwnerId;
            RecentlyMetSalesEngineer.lastname = ev.owner.name;
            SalesEngineer = ev.OwnerId;
        }
    }
    
    public  PageReference SaveOpportunity() {
        System.debug('attachment in save method'+attachment);
        opp.Type__c = opp1.Type__c;
        opp.Customer_Key_Points__c = opp1.Customer_Key_Points__c;
        opp.Customer_Success_Criteria__c = opp1.Customer_Success_Criteria__c;
        
        if(opp1.type__c == '' ||opp1.type__c == null)
        {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Please select the meeting type you want to create'));
            return null;
        }
        if((SalesEngineer == '' || SalesEngineer == null  ) && !IncludeGroup)
        {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Please select the Sales Engineer from the list or select "No Specific SE select most available SE" '));
            return null;
        }
        list<opportunity> opptyList = new list<opportunity>();
        opptyList.add(opp);
        String RetUrl = getTTUrl(opp);
        if(RetUrl == null)
        {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Please update Customer Key Points and Customer Success Criteria'));
            return null;            
        }
        else
        {
            if(attachment.body != null)
            {
                attachment.parentid = opp.Id; 
                System.debug('attachment'+attachment);
                insert attachment; 
            }
            
            DmlHelper.performDML2(opptyList, DmlHelper.DML_UPDATE, 'TimeTradeSelectTypeFieldBookMeetingCtrl', 'SaveOpportunity', 'update TT meeting type to opp ', true);
            
            PageReference pageRef;
            pageRef = new PageReference(RetUrl);
            pageRef.setRedirect(true);
            return pageRef;       
        } 
        //return null;
    } 
    
    public  String getTTUrl(opportunity oppty) {
        System.debug('oppty'+oppty);
        String RetUrl;
        id userid = UserInfo.getUserId(); 
        map<String,TimeTrade_for_SE__c> TTSe = new map<String,TimeTrade_for_SE__c>(); 
        for(TimeTrade_for_SE__c tt : TimeTrade_for_SE__c.getall().values())
        {
            TTSe.put(tt.Appointment_Type__c,tt); 
        }
        if(TTSe.containskey(oppty.Type__c))
        {
            String LocationType = TTSe.get(oppty.Type__c).Location_type__c;
            String LocationInfo = TTSe.get(oppty.Type__c).Location_Info__c;
            String Duration = TTSe.get(oppty.Type__c).Duration__c;
            String Message = TTSe.get(oppty.Type__c).Message__c;
            String DummyContact = TTSe.get(oppty.Type__c).DummyContact__c;
            String ShowAvailabilityAfterMinutes = TTSe.get(oppty.Type__c).ShowAvailabilityAfterMinutes__c;
            boolean CheckCustomerSuccessCriteria = TTSe.get(oppty.Type__c).Check_Customer_Success_Criteria__c;
            boolean CheckCustomerKeyPoints = TTSe.get(oppty.Type__c).Check_Customer_Key_Points__c;
            String Subject = TTSe.get(oppty.Type__c).Subject__c +' '+ oppty.Account.Name ; 
              String getTimeTradOPSpecilCharters = Label.Timetrade_oppty_special_characters;    
               for (String charvar : getTimeTradOPSpecilCharters.split( ';')) {
                Subject = Subject.replace(charvar, '');   
            }     
            String RoundRobinQueue;
            if(IncludeGroup) {
                RoundRobinQueue = Label.RoundRobinQueueUsedOnTT;
                system.debug('RoundRobinQueue'+RoundRobinQueue);                
                List<String> roundRobinQueueStrList =  RoundRobinQueue.split(',');
                system.debug('1st Group : ' + roundRobinQueueStrList.get(0));     // Sales_Engineering_Team
                system.debug('2st Group : ' + roundRobinQueueStrList.get(1));    // Team_Venture_Sales_Engineer
                System.debug('TTMap >> '+ TTMap.size() + '>> '+TTMap.get(CurrentUser.Title) + '>>'+ CurrentUser );
                RoundRobinQueue = (TTMap!= null && TTMap.get(CurrentUser.Title) != null && TTMap.get(CurrentUser.Title).PEO_Strategic_Role__c == 'Team Venture' && TTMap.get(CurrentUser.Title).Name == CurrentUser.Sales_Org__c)? roundRobinQueueStrList.get(1) :roundRobinQueueStrList.get(0);
                
            }
            
            if(DummyContact == null) {
                DummyContact = oppty.Id;
            }
            if((CheckCustomerKeyPoints && oppty.Customer_Key_Points__c == null) || (CheckCustomerSuccessCriteria && oppty.Customer_Success_Criteria__c == null)) 
            {
                return null;
            }
            // RetUrl = '/apex/TimeTrade_SF1__CreateTimeTradeInvitationNew?relId='+oppty.Id+'&locationType='+LocationType+'&duration='+Duration+'&locationInfo='+LocationInfo+'&message='+Message+'&userIds='+SalesEngineer+','+RoundRobinQueue+','+Currentuserid;
            // RetUrl = '/apex/TimeTrade_SF1__CreateTimeTradeInvitationNew?relId='+DummyContact+'&whatid='+oppty.Id+'&locationType='+LocationType+'&duration='+Duration+'&locationInfo='+LocationInfo+'&ShowAvailabilityAfterMinutes='+ShowAvailabilityAfterMinutes+'&userIds='+SalesEngineer+','+RoundRobinQueue+','+Currentuserid;
            //RetUrl = '/apex/TimeTrade_SF1__CreateTimeTradeInvitationNew?relId='+DummyContact+'&whatid='+oppty.Id+'&locationType='+LocationType+'&duration='+Duration+'&locationInfo='+LocationInfo+'&ShowAvailabilityAfterMinutes='+ShowAvailabilityAfterMinutes+'&subject='+Subject+'&userIds='+SalesEngineer+','+RoundRobinQueue+','+Currentuserid;
            //APR0157374: Update Book Meeting process
            RetUrl = '/apex/TimeTrade_SF1__CreateTimeTradeInvitationNew?relId='+DummyContact+'&whatid='+oppty.Id+'&locationType='+LocationType+'&duration='+Duration+'&locationInfo='+LocationInfo+'&ShowAvailabilityAfterMinutes='+ShowAvailabilityAfterMinutes+'&subject='+Subject+'&userIds='+SalesEngineer+','+RoundRobinQueue+','+oppOwnerId;  
            
        }
        System.debug('RetUrl'+RetUrl);
        return RetUrl;
    }
    
}