/* Controller class for TimeTradeSTFBookMeetingRC vf page
   
  History
  -------
  10/20/2022  Rohit Ranjan    Created
  03/16/2023  Rohit Ranjan  APR0137745 Added new Long Text Area field Exclude_Sales_Engg__c replacing Exclude_Sales_Engineer__c
  
 */

public class TimeTradeSTFBookMeetingRCCtrl {
    
    private Apexpages.StandardController controller;
    public string SalesEngineer{get;set;}
    public user RecentlyMetSalesEngineer{get;set;}   
    public boolean IncludeGroup{get;set;}    
    public list<user> SEPicklistValues = new list<user>();    
    public id Currentuserid;// = UserInfo.getUserId(); 
    public Map<String,Sales_Engineer_TT_Mapping__c> TTMap = new Map<String,Sales_Engineer_TT_Mapping__c>();
    public User CurrentUser = new user();
    public  Referral_Contact__c rc;
    public  Referral_Contact__c rc1;
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
       
       CurrentUser =  (Currentuserid == rc.ownerid) ? [select id,title,sales_org__c,name,lastname,firstname from user where id =: rc.ownerid] : [select id,title,sales_org__c,name,lastname,firstname from user where id =: Currentuserid] ;          
             
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

   	public  void sendDefaultUsedEmail(String rcOwner, String rcOwnerTitle) { 
       Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
       String[] toAddresses = Label.NotifyTTMapDefaultUsed.split(',');
       mail.setToAddresses(toAddresses);
       mail.setSaveAsActivity(false);
       mail.setSubject('TimeTrade Mapping not Found for '+ rcOwnerTitle);
       String body = 'Hi, Timetrade Mapping is not found for '+ rcOwner+' with the title '+ rcOwnerTitle+', default mapping used';
       
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
    
    public TimeTradeSTFBookMeetingRCCtrl(Apexpages.StandardController controller) {
        Currentuserid = UserInfo.getUserId(); 
        this.controller = controller;
         rc1 = (Referral_Contact__c)controller.getRecord();
		String TypeVal = ApexPages.currentPage().getParameters().get('type__c');
        rc1.Type__c = TypeVal;
        list<String> EventTypeToCheckSE = new list<String>();
        for(TimeTrade_for_SE__c tt : TimeTrade_for_SE__c.getall().values())
        {
           EventTypeToCheckSE.add(tt.name); 
        }
         Date CheckSEMetInLast30Days = system.today().addDays(-30);
         rc = [select id,type__c,Customer_Key_Points__c,Customer_Success_Criteria__c,Referral_Account__r.Account__r.Name,ownerid,
                    (select id,ownerid,owner.name from events
                     where StartDateTime >: CheckSEMetInLast30Days 
                     and Appointment_Type__c in: EventTypeToCheckSE 
                     and owner.profile.name = 'Sales Engineer' 
                     order by createddate Desc limit 1)
                from Referral_Contact__c where id =: rc1.id limit 1];
        //owner.title,owner.name,owner.sales_org__c,owner.firstname,owner.lastname,
        
        if(rc.Events.size() > 0)
        {
            Event ev = rc.Events;
            RecentlyMetSalesEngineer = new user();
            RecentlyMetSalesEngineer.id = ev.OwnerId;
            RecentlyMetSalesEngineer.lastname = ev.owner.name;
            SalesEngineer = ev.OwnerId;
        }
    }
        
    public  PageReference SaveRefCon() {
       System.debug('attachment in save method'+attachment);
       rc.Type__c = rc1.Type__c;
       rc.Customer_Key_Points__c = rc1.Customer_Key_Points__c;
       rc.Customer_Success_Criteria__c = rc1.Customer_Success_Criteria__c;
       system.debug('rc : ' + rc); 
       if(rc1.type__c == '' ||rc1.type__c == null)
       {
       ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Please select the meeting type you want to create'));
           return null;
       }
       if((SalesEngineer == '' || SalesEngineer == null) && !IncludeGroup)
       {
       ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Please select the Sales Engineer from the list or select "No Specific SE select most available SE" '));
           return null;
       }
        list<Referral_Contact__c> rcList = new list<Referral_Contact__c>();
        rcList.add(rc);
        String RetUrl = getTTUrl(rc);
        if(RetUrl == null)
        {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Please update Customer Key Points and Customer Success Criteria'));
            return null;            
        }
        else
        {
            if(attachment.body != null)
            {
                attachment.parentid = rc.Id; 
            	 System.debug('attachment'+attachment);
               insert attachment; 
            }
            system.debug('rc : ' + rc);
            DmlHelper.performDML2(rcList, DmlHelper.DML_UPDATE, 'TimeTradeSTFBookMeetingRCCtrl', 'SaveRefCon', 'update TT meeting type to Referral Contact ', true);
            
            PageReference pageRef;
            pageRef = new PageReference(RetUrl);
            pageRef.setRedirect(true);
            return pageRef;       
        } 
        //return null;
    } 
   
    public  String getTTUrl(Referral_Contact__c refCn) {
           System.debug('Referral Contact '+refCn);
  		String RetUrl;
        id userid = UserInfo.getUserId(); 
		map<String,TimeTrade_for_SE__c> TTSe = new map<String,TimeTrade_for_SE__c>(); 
        for(TimeTrade_for_SE__c tt : TimeTrade_for_SE__c.getall().values())
        {
           TTSe.put(tt.Appointment_Type__c,tt); 
        }
        if(TTSe.containskey(refCn.Type__c))
        {
        String LocationType = TTSe.get(refCn.Type__c).Location_type__c;
        String LocationInfo = TTSe.get(refCn.Type__c).Location_Info__c;
        String Duration = TTSe.get(refCn.Type__c).Duration__c;
        String Message = TTSe.get(refCn.Type__c).Message__c;
        String DummyContact = TTSe.get(refCn.Type__c).DummyContact__c;
        String ShowAvailabilityAfterMinutes = TTSe.get(refCn.Type__c).ShowAvailabilityAfterMinutes__c;
        boolean CheckCustomerSuccessCriteria = TTSe.get(refCn.Type__c).Check_Customer_Success_Criteria__c;
        boolean CheckCustomerKeyPoints = TTSe.get(refCn.Type__c).Check_Customer_Key_Points__c;
        String Subject = TTSe.get(refCn.Type__c).Subject__c +' '+ refCn.Referral_Account__r.Account__r.Name ;           
        String RoundRobinQueue ='';
            if(IncludeGroup) {
                RoundRobinQueue = Label.RoundRobinQueueUsedOnTT;
                system.debug('RoundRobinQueue'+RoundRobinQueue);                
                List<String> roundRobinQueueStrList =  RoundRobinQueue.split(',');
                system.debug('1st Group : ' + roundRobinQueueStrList.get(0));     // Sales_Engineering_Team
                system.debug('2st Group : ' + roundRobinQueueStrList.get(1));    // Team_Venture_Sales_Engineer
                System.debug('3rd Group : ' + roundRobinQueueStrList.get(2));     // Flock_Sales_Engineers 
                System.debug('TTMap >> '+ TTMap.size() + '>> '+TTMap.get(CurrentUser.Title) + '>>'+ CurrentUser );
               // RoundRobinQueue = (TTMap!= null && TTMap.get(CurrentUser.Title) != null && TTMap.get(CurrentUser.Title).PEO_Strategic_Role__c == 'Team Venture' && TTMap.get(CurrentUser.Title).Name == CurrentUser.Sales_Org__c)? roundRobinQueueStrList.get(1) :roundRobinQueueStrList.get(0);
                RoundRobinQueue = (TTMap!= null && TTMap.get(CurrentUser.Title) != null && TTMap.get(CurrentUser.Title).PEO_Strategic_Role__c == 'Team Venture' && TTMap.get(CurrentUser.Title).Name == CurrentUser.Sales_Org__c)? roundRobinQueueStrList.get(1) :(TTMap!= null && TTMap.get(CurrentUser.Title) != null && TTMap.get(CurrentUser.Title).PEO_Strategic_Role__c == 'Flock BenAdmin' && TTMap.get(CurrentUser.Title).Name == CurrentUser.Sales_Org__c)? roundRobinQueueStrList.get(2) :roundRobinQueueStrList.get(0);
                
            }
                    
            if(DummyContact == null) {
                    DummyContact = refCn.Id;
            }
         if((CheckCustomerKeyPoints && refCn.Customer_Key_Points__c == null) || (CheckCustomerSuccessCriteria && refCn.Customer_Success_Criteria__c == null)) 
         {
             return null;
         }
        RetUrl = '/apex/TimeTrade_SF1__CreateTimeTradeInvitationNew?relId='+DummyContact+'&whatid='+refCn.Id+'&locationType='+LocationType+'&duration='+Duration+'&locationInfo='+LocationInfo+'&ShowAvailabilityAfterMinutes='+ShowAvailabilityAfterMinutes+'&subject='+Subject+'&userIds='+SalesEngineer+','+RoundRobinQueue+','+Currentuserid;
 
        }
           System.debug('RetUrl'+RetUrl);
            return RetUrl;
        }
          

}