/**
 * Test method for PartnerReferral trigger and PartnerReferralHelper class
 * 
 * History
 * --------
  02/17/2017 Cindy Freeman   created
  01/15/2018 Cindy Freeman    modified for uppercase MarketingCallTracking_Mapping
  01/31/2019 Dan Carmen     Ability to pop a weblead to a user.
  10/15/2020 Dan Carmen     Clean up code
  11/30/2023 Dan Carmen            Remove unused Round Robin fields
  01/19/2024 Pujitha Madamanchi : Remove test related to blob 

 */ 
@isTest
private class PartnerReferralTest {

    @testSetup public static void setupRoundRobin(){
        
      User runUser = [Select Id, Name from User where IsActive=true and Profile.Name='System Administrator' limit 1];
      System.runAs(runUser) {
             // create assignment group 
          Group grp1 = new Group(Name='RoundRobinTest Case Queue',Type='Queue');
          // this queue will not be associated with an assignment group
          Group grp2 = new Group(Name='RoundRobinTest Case Queue 2',Type='Queue');
          // this queue will be for leads
          Group grp3 = new Group(Name='RoundRobinTest Lead Queue',Type='Queue');
          
          Group grp4 = new Group(Name='RoundRobinTest Contact Queue',Type='Queue');
          Group grp5 = new Group(Name='RoundRobinTest Contact Off Queue',Type='Queue');
          Group grp6 = new Group(Name='RoundRobinTest Night/Weekend Queue',Type='Queue');
          
          Group grp7 = new Group(Name='RoundRobinTest Event Queue',Type='Queue');
          
          Group grp8 = new Group(Name='Virtual Sales Queue',Type='Queue');
          
          Group grp9 = new Group(Name='RoundRobinTest Oppty Queue',Type='Queue');
          Group[] grps = new Group[]{grp1,grp2,grp3,grp4,grp5,grp6,grp7,grp8,grp9};
          insert grps;
          
          // associate the queues with the objects
          QueueSobject[] qSobjects = new QueueSobject[]{};
          qSobjects.add(new QueueSobject(QueueId=grp1.Id,SobjectType='Case'));
          qSobjects.add(new QueueSobject(QueueId=grp2.Id,SobjectType='Case'));
          qSobjects.add(new QueueSobject(QueueId=grp3.Id,SobjectType='Lead'));
          qSobjects.add(new QueueSobject(QueueId=grp4.Id,SobjectType='Lead')); //SobjectType doesn't matter because nothing actually gets stored in the queue.
          qSobjects.add(new QueueSobject(QueueId=grp5.Id,SobjectType='Lead')); //SobjectType doesn't matter because nothing actually gets stored in the queue.
          qSobjects.add(new QueueSobject(QueueId=grp6.Id,SobjectType='Lead')); //SobjectType doesn't matter because nothing actually gets stored in the queue.
          qSobjects.add(new QueueSobject(QueueId=grp7.Id,SobjectType='Lead')); //SobjectType doesn't matter because nothing actually gets stored in the queue.
          qSobjects.add(new QueueSobject(QueueId=grp8.Id,SobjectType='Lead'));
          qSobjects.add(new QueueSobject(QueueId=grp9.Id,SobjectType='Lead')); //SobjectType doesn't matter because nothing actually gets stored in the queue.
          insert qSobjects;
          
          insert new BypassNSS__c(SetupOwnerId=UserInfo.getOrganizationId(), IsActive__c=true,Queue_Id__c=grp8.Id,Queue_Name__c=grp8.Name,Partner_Referral_Expiration_Duration__c=1,Holdout_Expiration__c=1);
          

         Assignment_Group_Name__c cagn = new Assignment_Group_Name__c(Name='RoundRobinTest Case Queue');
         Assignment_Group_Name__c lagn = new Assignment_Group_Name__c(Name='RoundRobinTest Lead Queue');
         Assignment_Group_Name__c coagn = new Assignment_Group_Name__c(Name='RoundRobinTest Contact Queue'); 
         Assignment_Group_Name__c cooagn = new Assignment_Group_Name__c(Name='RoundRobinTest Contact Off Queue');
         Assignment_Group_Name__c nwagn = new Assignment_Group_Name__c(Name='RoundRobinTest Night/Weekend Queue');
         Assignment_Group_Name__c eagn = new Assignment_Group_Name__c(Name='RoundRobinTest Event Queue');
         Assignment_Group_Name__c oagn = new Assignment_Group_Name__c(Name='RoundRobinTest Oppty Queue');
         Assignment_Group_Name__c[] agns = new Assignment_Group_Name__c[]{cagn,lagn,coagn,cooagn,nwagn,eagn,oagn};
         insert agns; 

         // insert a Queue record
         Assignment_Group_Queues__c cagq = new Assignment_Group_Queues__c(Assignment_Group_Name__c=cagn.Id, Name='RoundRobinTest Case Queue');
         Assignment_Group_Queues__c lagq = new Assignment_Group_Queues__c(Assignment_Group_Name__c=lagn.Id, Name='RoundRobinTest Lead Queue');
         Assignment_Group_Queues__c coagq = new Assignment_Group_Queues__c(Assignment_Group_Name__c=coagn.Id, Name='RoundRobinTest Contact Queue');
         Assignment_Group_Queues__c cooagq = new Assignment_Group_Queues__c(Assignment_Group_Name__c=cooagn.Id, Name='RoundRobinTest Contact Off Queue');
         Assignment_Group_Queues__c nwagq = new Assignment_Group_Queues__c(Assignment_Group_Name__c=nwagn.Id, Name='RoundRobinTest Night/Weekend Queue');
         Assignment_Group_Queues__c eagq = new Assignment_Group_Queues__c(Assignment_Group_Name__c=eagn.Id, Name='RoundRobinTest Event Queue');
         Assignment_Group_Queues__c oagq = new Assignment_Group_Queues__c(Assignment_Group_Name__c=oagn.Id, Name='RoundRobinTest Oppty Queue');
         Assignment_Group_Queues__c[] agqs = new Assignment_Group_Queues__c[]{cagq,lagq,coagq,cooagq,nwagq,eagq,oagq}; 
         insert agqs;
         
         // select users
         User[] users = [Select Id, Name from User where Profile.Name='System Administrator' 
                                                  and IsActive=true
                                                  and Assignment_Group_Active__c=true
                                                  and Id != :runUser.Id  
                                                  limit 3];
         system.debug('testUsers: '+users);
         DateTime rightNow = DateTime.now();
         
        // add as group members 
         Assignment_Groups__c[] ags = new Assignment_Groups__c[]{};
         Integer millisecond = 1;
         Integer skillSet = 1;
         for (User u : users) {
            Assignment_Groups__c cag = new Assignment_Groups__c(Active__c='True',Group_Name__c=cagn.Id,User__c=u.Id, Millisecond__c=millisecond++);
            ags.add(cag);
            Assignment_Groups__c lag = new Assignment_Groups__c(Active__c='True',Group_Name__c=lagn.Id,User__c=u.Id, Millisecond__c=millisecond++);
            ags.add(lag);
            Assignment_Groups__c coag = new Assignment_Groups__c(Active__c='True',Group_Name__c=coagn.Id,User__c=u.Id, Millisecond__c=millisecond++);
            ags.add(coag);
            Assignment_Groups__c cooag = new Assignment_Groups__c(Active__c='True',Group_Name__c=cooagn.Id,User__c=u.Id, Millisecond__c=millisecond++);
            ags.add(cooag);
            Assignment_Groups__c nwag = new Assignment_Groups__c(Active__c='True',Group_Name__c=nwagn.Id,User__c=u.Id, Millisecond__c=millisecond++);
            ags.add(nwag);
            Assignment_Groups__c eag = new Assignment_Groups__c(Active__c='True',Group_Name__c=eagn.Id,User__c=u.Id, Millisecond__c=millisecond++,Skill_Set__c = 'Level '+skillSet);
            if(skillSet == 3){
                skillSet = 0;
            }
            skillSet++;
            ags.add(eag);
            Assignment_Groups__c oag = new Assignment_Groups__c(Active__c='True',Group_Name__c=oagn.Id,User__c=u.Id, Millisecond__c=millisecond++);
            ags.add(oag);
         }
         insert ags;
         
         List<MarketingCallTracking_Mapping__c> mctMapList = new List<MarketingCallTracking_Mapping__c>();
         MarketingCallTracking_Mapping__c mct = new MarketingCallTracking_Mapping__c(Name='GCLID',api_field_name__c='gclid__c');                                        
         mctMapList.add(mct);
         mct = new MarketingCallTracking_Mapping__c(Name='ADPOSITION',api_field_name__c='webform_adposition__c');                                        
         mctMapList.add(mct);
         mct = new MarketingCallTracking_Mapping__c(Name='KEYWORD',api_field_name__c='keywords__c');                                        
         mctMapList.add(mct);
         mct = new MarketingCallTracking_Mapping__c(Name='MM_CAMPAIGN',api_field_name__c='webform_mm_campaign__c');                                        
         mctMapList.add(mct);
         upsert mctMapList;
        
      } // runAs
    } // testSetup  

   /* static testMethod void myUnitTest() {
        User leadLdrUser = [Select Id, FirstName, LastName, Email, HR_Person_Id__c from User where Name='Lead Loader' and IsActive=true and HR_Person_Id__c != null limit 1];       
        Schema.RecordTypeInfo leadCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_LEAD, ObjectHelper.OBJECT_LEAD);
        
        // populate custom settings
        LeadLoaderConfig__c llc = new LeadLoaderConfig__c(Name='WEBLEAD',IsActive__c=true,CreateTracking__c=true);   //IsNSSOwnership__c=true,LogWebleadFields__c=true,
                                                            //NSSSource__c='Inbound',QueueName__c='NSS Inbound Queue',WebServiceName__c='Lead Loader-WebLeads');
        insert llc;                                                                                                  
        ProcessNameMap__c pnm = new ProcessNameMap__c(Name='LL-Lead Loader',IsActive__c=true);
        insert pnm;
        
        
        Boolean ans = MarketTrackingMethods.checkOwnedBy('WEBLEAD');
        System.assertEquals(true, ans);
                  
        System.runAs(leadLdrUser) {
            //Boolean isLeadLoader = UserHelper.isLeadLoader(UserInfo.getName());
            //System.assertEquals(true, isLeadLoader);
            Lead ld1 = new Lead(Firstname = 'First'
                                ,Lastname = 'Last Lead1'
                                ,Company = 'Test Lead Company1'
                                ,recordtypeId = leadCorert.getRecordTypeId()
                                ,DataFlux_Id__c = null
                                ,LeadGroupId__c = null
                                ,OwnedBy__c = 'WEBLEAD');
            ld1.description = 'utm_source |^| Google\r';
            ld1.description += 'utm_medium |^| CPC\r'; 
            ld1.description += 'keyword |^| This is a TEST\r'; 
            ld1.description += 'mm_campaign |^| 4EFE303C35B53BB23DAED7ED512D0BF0\r'; 
            ld1.description += 'gclid |^| CJ2uuL277NACFcS4wAodm7ECnQ\r'; 
            ld1.description += 'original_referer |^| http://pages.paychex.com/hcm.html?mm_campaign=4EFE303C35B53BB23DAED7ED512D0BF0&%20keyword=hris%20pay\r'; 
            ld1.description += 'REDIRECT |^|\r'; 
            ld1.description += 'HTTP_REFERER |^|\r'; 
            insert ld1;                         
            
            List<Marketing_Call_Tracking__c> mctList = [select Id, Lead__c, Account__c, Contact__c, keywords__c from Marketing_Call_Tracking__c
                                                        where Lead__c = :ld1.Id];                                                                               
            mctList = [select Id, Lead__c, Account__c, Contact__c, keywords__c from Marketing_Call_Tracking__c
                                                        where Lead__c = :ld1.Id];
            System.assertEquals(1, mctList.size());
            System.assertEquals('This is a TEST', mctList.get(0).keywords__c);
            
            PartnerReferral__c partRef = [select Id from PartnerReferral__c where Lead__c = :ld1.Id limit 1];
            System.assertNotEquals(null, partRef);
                        
            partRef.Create_Market_Tracking__c = true;
            PartnerReferralHelper.TRIGGER_ALREADY_RAN=false;
            update partRef;
            // make sure didnt create dup
            mctList = [select Id, Lead__c, Account__c, Contact__c, keywords__c from Marketing_Call_Tracking__c
                                                        where Lead__c = :ld1.Id];
            System.assertEquals(1, mctList.size());
            
        } // runAs
    
    } // myUnitTest */

   static testMethod void testWeblead() {
      Lead ld = new Lead(Firstname='First', LastName='Last', Company='Test Company', Phone='(585) 555-1234' );
      insert ld;
      
      
      PartnerReferral__c partRef = new PartnerReferral__c(FirstName__c=ld.FirstName, LastName__c=ld.LastName, Company__c =ld.Company, Phone__c=ld.Phone);
      partRef.Lead__c = ld.Id;
      partRef.Source__c = TrackRecordEntry.WEBLEAD;
      insert partRef;
      
      User usr = [Select Id, Name from User where IsActive=true and HR_Person_Id__c != null and UserRoleId != null and Sales_Org__c=:UserHelper.SO_CORE limit 1];
      
      Referral__c ref = new Referral__c(PartnerReferral__c=partRef.Id, SourceLead__c=ld.Id, User__c=usr.Id);
      insert ref;
      
      Test.startTest();
      partRef.Original_Owner__c = usr.Name; 
      PartnerReferralHelper.TRIGGER_ALREADY_RAN=false;
      //PartnerReferralHelper.popWebLeadSet.clear();
      update partRef;
      Test.stopTest();
      
      PartnerReferral__c checkPartRef = [Select Id, ForceRTPQ__c, RTPQDateTime__c from PartnerReferral__c where Id=:partRef.Id];
      System.assertNotEquals(null, checkPartRef.RTPQDateTime__c);
      
      PartnerReferralHelper.SKIP_FUTURE=true;
      PartnerReferralHelper.WEB_LEAD_RAN=false;
      PartnerReferralHelper.TRIGGER_ALREADY_RAN=false;
      //PartnerReferralHelper.popWebLeadSet.clear();
      checkPartRef.ForceRTPQ__c = true;
      checkPartRef.RTPQDateTime__c = null;
      update checkPartRef;
      
      checkPartRef = [Select Id, ForceRTPQ__c, RTPQDateTime__c from PartnerReferral__c where Id=:partRef.Id];
      System.assertNotEquals(null, checkPartRef.RTPQDateTime__c);
      System.assertEquals(false, checkPartRef.ForceRTPQ__c);
      
      
   } // testWeblead
   
   static testMethod void testSendEmail() {
      PartnerReferral__c partRef1 = new PartnerReferral__c(FirstName__c='First1', LastName__c='Last1', Company__c='Company1', Phone__c='(585) 111-1111',SubmitAsEmail__c=true,ProcessReferral__c=true);
      PartnerReferral__c partRef2 = new PartnerReferral__c(FirstName__c='First2', LastName__c='Last2', Company__c='Company2', Phone__c='(585) 222-2222',SubmitAsEmail__c=true,ProcessReferral__c=true);
      PartnerReferral__c[] partRefs = new PartnerReferral__c[]{partRef1,partRef2};
      insert partRefs;
      System.assertEquals(true,PartnerReferralHelper.emailSent);
      
      Set<Id> idSet = new Set<Id>{partRef1.Id,partRef2.Id};
      PartnerReferral__c[] queryPartRefs = PartnerReferralHelper.getReferralsToProcess(idSet);
      System.assertEquals(2,queryPartRefs.size());
      
      PartnerReferralHelper.processReferrals(idSet);
   } // testSendEmail
   
} // class PartnerReferralTest