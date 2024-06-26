/*
Custom Setting: HRGAssignment__c
Fields:
Name: Just use any unique value
EmpMin__c (Number 6): Minimum number of employees for tier
EmpMax__c (Number 6): Maximum number of employees for tier
QueueName__c (Text 40): The name of the queue
Tier Name (Text 20): The name of the tier
DistanceInState1__c (Number 6): The first distance to check in state
DistanceInState2__c (Number 6): The second distance to check in state (if any)
DistanceNoState__c (Number 6): The third distance to check without using the state
IsRoundRobin__c (Boolean): Is this tier using round robin? 
States__c (Text 125): the states valid for this option
Custom Label:
oppSourceExclude : to Store the text value of Opportunity Source to exclude {'Lightning Clone','Opportunity Clone'}

History
-------
06/01/2022 Eric Porter       Created
11/10/2022 Eric Porter        Added multi Id Functionality(when an opp is split, to find all child opps and populate an HRG_Assignment on that child Opp)
12/27/2022 Reetesh Pandey     added custom label oppSourceExclude to exclude Opportunity Source
*/

public with sharing class HRGAutoAssignmentQueueable implements Queueable{
    public Map<Id,Opportunity> oppmap;
    public Set<Id> acctIdSet;
    public HRG_Assignment__c[] newAssigns = new HRG_Assignment__c[]{};
    // we'll store these to handle later to bulkify
    public HRG_Assignment__c[] roundRobinAssigns = new HRG_Assignment__c[]{};
    public String childIds = '';
    public String childNames = '';
    public Integer numOfChildren = 0;
    public Decimal totalEmployees = 0;

    public HRGAutoAssignmentQueueable(Map<Id,Opportunity> p_oppMap, Set<Id> p_acctIdSet) {
        oppMap = p_oppMap;
        acctIdSet = p_acctIdSet;
    } // HRGAutoAssignmentQueueable
    
    
    public void execute(QueueableContext context) {
       // TODO - do we need to limit how many are processed at once?
       startAutoAssign();
    } // execute
    
    public void startAutoAssign(){
        System.debug('Running the HRG Queueable');
       Map<Id,Account> acctMap = new Map<Id,Account> ([select Id,Name,ShippingAddress,BillingAddress
                                                             ,Language__c
                                                             ,HR_Generalist__c,IsParent__c,IsChild__c
                                                             ,ShippingState, BillingState, NumberOfEmployees
                                                             ,SalesParent__c, SalesParent__r.Id, SalesParent__r.Name
                                                             ,SalesParent__r.HR_Generalist__c
                                                             ,SalesParent__r.HR_Generalist__r.User_Lookup__r.ManagerId
                                                             ,SalesParent__r.HR_Generalist__r.User_Lookup__r.Manager.Name
                                                         from Account where Id in :acctIdSet]);
       for (Opportunity opp : oppMap.values()) {
          // to only process once, we'll remove from the map
          Account acct = acctMap.remove(opp.AccountId);
          if (acct != null) {
             processAccount(acct,opp);
          }
       } // for (Opportunity
       
       
       // save the records at the end
       // we use upsert in case they've been saved previously
       if (!newAssigns.isEmpty()) {
          upsert newAssigns;
       }
       
       if (!roundRobinAssigns.isEmpty()) {
          handleRoundRobinPart2();
       }

    } // startAutoAssign
    
    public void processAccount(Account acct, Opportunity opp) {
       // if the HRG is already set we don't need to do anything.
       Boolean isParent = false;
       if (acct.HR_Generalist__c != null) {
          return;
       }
       Opportunity multi_Id_check_Opp = [Select Id, OppSource__c, Name,(Select Id, Name, SelectedHRP__c, Manager__c, Status__c, OwnerId, State__c,ProcessNotes__c from HRG_Assignments__r),AccountId,Account.ShippingState,Account.BillingState from Opportunity where Id = :opp.Id limit 1];
       // TODO 11/4/2022
       // query the opp and the list of HRG's associated
       // if any of the HRG's associated with this opportunity are with status 'Waiting For Approval' return
      //  System.debug('opp.HRG_Assignments__r != null && !opp.HRG_Assignments__r.isEmpty()  :'+String.valueOf(multi_Id_check_Opp.HRG_Assignments__r != null && !multi_Id_check_Opp.HRG_Assignments__r.isEmpty()));
      //  System.debug('opp.HRG_Assignments__r != null   :'+String.valueOf(multi_Id_check_Opp.HRG_Assignments__r != null ));
      //  System.debug('!opp.HRG_Assignments__r.isEmpty()  :'+String.valueOf(!multi_Id_check_Opp.HRG_Assignments__r.isEmpty()));
      //  System.debug('opp.HRG_Assignments__r: '+multi_Id_check_Opp.HRG_Assignments__r);
       if(multi_Id_check_Opp.HRG_Assignments__r != null && !multi_Id_check_Opp.HRG_Assignments__r.isEmpty()){
         for(HRG_Assignment__c HRP: multi_Id_check_Opp.HRG_Assignments__r){
            // System.debug('Checking for multiple waitin for approval HRG assignments');
            // System.debug('HRP.Status__c ==\'Waiting For Approval\'');
            if(HRP.Status__c =='Waiting For Approval'){
            //if(HRP.Status__c =='Waiting For Approval'||HRP.Status__c =='Pending'){
               System.debug('WE SKIPPED THIS OPP!'+multi_Id_check_Opp.Name+' Watiing For approval Skip');
               return;
            }
         }
       }
       // TODO - how is the Name field defined? You should make it a text and then set the account name to the HRG_Assignment__c.Name field
       // TODO - Add a lookup to the Opportunity on the assignment object so we know where we started
       // TODO - Is there a status field? That would be consistent with how most processed go. Picklist field, values Pending, Waiting For Approval, Approved, Manager Override, Error
       //        instead of Action Taken field
       // TODO - lookup to the Contact for the SelectedHRP
       // TODO - ProcessNotes__c (large text area, size 2000)
       // TODO - Employees (Number 6)
       // TODO - State__c field (text 10) - in case they want to do metrics on it.
       // TODO - Manager__c (lookup to User) - for the Area Manager
       // TODO - SearchDistance__c (Number 6) - the search distance we used to find a result
       // TODO - FoundDistance__c (Number 6) - the calculated distance of the HRG from the client
       //
       Boolean isSpanishSpeaking = (acct.Language__c == 'Spanish');
       BusinessHours bh = [SELECT Id,Name,SaturdayEndTime,SaturdayStartTime,MondayStartTime FROM BusinessHours WHERE Name='HRG Auto Approval Hours'];
       Datetime targetTime = BusinessHours.add(bh.id,Datetime.now(),12*60*60*1000);
       Datetime nextStart = BusinessHours.nextStartDate(bh.id,targetTime);
       
       HRG_Assignment__c hao = new HRG_Assignment__c(Name=acct.Name, Account__c=acct.Id, Opportunity__c=opp.Id, Request_Date__c=Date.today(),
       Status__c='Pending', OpportunityOwner__c = opp.OwnerId,Spanish_Speaking_Indicator__c=isSpanishSpeaking
       ,AutoApproveDate__c=nextStart
       );

       newAssigns.add(hao);
       //If opp is a parent opp with children Opps
       // find all child opps, use them to make extra HRG's for the child opps 
       Map<Id,Opportunity> childOpps = new Map<Id,Opportunity>([Select Id, Name, OppSource__c, Primary_Opportunity__c,Employees_Paid_Per_Payroll__c,AccountId,Account.Name From Opportunity where Primary_Opportunity__c =: opp.Id]); 
       if(opp.Primary_Opportunity__c == null && childOpps != null && childOpps.values()!= null){
             isParent = true;   
             childIds = '';
             numOfChildren = 0;
             totalEmployees = 0;
             childNames = '';
            List<HRG_Assignment__c> childHRGs = new List<HRG_Assignment__c>();
            List<String>validOppTypes = Label.HRG_Invalid_Oppty_Types.split(',');
            for(Opportunity tempOpp: childOpps.Values()){ 
               System.debug('OppName:' +tempOpp.Name);
               if(tempOpp.Employees_Paid_Per_Payroll__c !=null && !validOppTypes.contains(tempOpp.OppSource__c)){
                  totalEmployees += tempOpp.Employees_Paid_Per_Payroll__c;
                  System.debug('totalEmployees: '+totalEmployees);
               }
               childIds += '' + tempOpp.Id + ',';
               System.debug('childIds: '+childIds);
               childNames += '' +  tempOpp.Name + ', ';
               HRG_Assignment__c tempHao = new HRG_Assignment__c(Name=tempOpp.Account.Name, Account__c=tempOpp.AccountId, Opportunity__c=tempOpp.Id, Request_Date__c=Date.today(),
                                                     Status__c='Pending', OpportunityOwner__c = opp.OwnerId,Spanish_Speaking_Indicator__c=isSpanishSpeaking
                                                     ,AutoApproveDate__c=nextStart,Parent_Opportunity__c=tempOpp.Primary_Opportunity__c
                                                     );
               childHRGs.add(tempHao);
            }
            totalEmployees+=opp.Employees_Paid_Per_Payroll__c;
            insert childHRGs;
            // for(HRG_Assignment__c childHAO: childHRGs){
            //    childHAO.[newEmployeeField] = totalEmployees;
            //    childHAO.Child_Opportunity_Ids__c = childIds;
            // }
            
       }
       
     
      
       

       // if there's a HRG on the parent, we're going to use that
       if (acct.SalesParent__c != null && acct.SalesParent__r.HR_Generalist__c != null) {
          // send this HRG to the area manager for approval.
          hao.SelectedHRP__c = acct.SalesParent__r.HR_Generalist__c;
          // make sure the lookup is populated.
          hao.Manager__c = (acct.SalesParent__r.HR_Generalist__r.User_Lookup__r != null ? acct.SalesParent__r.HR_Generalist__r.User_Lookup__r.ManagerId : null);
          // if the manager is blank is that an error? We can't notify the manager if we can't find them
          hao.Status__c = (hao.Manager__c != null ? 'Waiting For Approval' : 'Error');
          String mgrName = (hao.Manager__c != null ? acct.SalesParent__r.HR_Generalist__r.User_Lookup__r.Manager.Name : 'Manager Not Found');
          StringHelper.addToProcessNotes(hao, 'Using assignment from Sales Parent '+acct.SalesParent__r.Name+' Manager='+mgrName);
          return;
       }
       
       // TODO do we use Account.NumberOfEmployees or Opportunity.Employees_Paid_Per_Payroll__c for the number of employees? 
       System.debug('isParent: '+isParent);
       hao.Employees__c = isParent? totalEmployees: (opp.Employees_Paid_Per_Payroll__c != null ? Integer.valueOf(opp.Employees_Paid_Per_Payroll__c) : Integer.valueOf(acct.NumberOfEmployees));
       // TODO update ^^^ to reflect total employee number(if its a parent pull the kids numbers as well, if its a kid see if it has siblings and total the employees);
       hao.Child_Opportunity_Ids__c = childIds;
       hao.Child_Opportunity_Names__c = childNames;
       // if parent opp include parent opp employee number + all of its kids employee numbers 
       hao.State__c = (String.isNotBlank(acct.ShippingState) ? acct.ShippingState : acct.BillingState);
       //Checks for Proper formatting of States
       if(hao.State__c.contains('.')){
         hao.State__c = hao.State__c.substringBefore('.');
     }
     hao.State__c = hao.State__c.toUpperCase();
       //hao.isMicro__c= (hao.Employees__c<= 9 && hao.Employees__c>=0);
       HRGAssignment__c matchedAssign = null;
       if (String.isNotBlank(hao.State__c)) {
       List<HRGAssignment__c> hao_CS = HRGAssignment__c.getAll().values();
       hao_CS.sort();
          for (HRGAssignment__c assign : hao_CS) {
              System.debug('HRGASSIGNMENT.States__c: '+assign.States__c);
              System.debug('hao.State__c: '+hao.State__c);
              System.debug('assign.States__c.contains(hao.State__c) :'+assign.States__c.contains(hao.State__c));
              System.debug('hao.Employees__c >= assign.EmpMin__c :'+Boolean.valueOf(hao.Employees__c >= assign.EmpMin__c));
              System.debug('hao.Employees__c :'+hao.Employees__c);
              System.debug('assign.EmpMin: '+assign.EmpMin__c);
              System.debug('assign.EmpMax: '+assign.EmpMax__c);

              System.debug('hao.Employees__c <= assign.EmpMax__c :'+Boolean.valueOf(hao.Employees__c <= assign.EmpMax__c));
              System.debug('String.isNotBlank(assign.States__c) :'+String.isNotBlank(assign.States__c));

              
              Boolean ifCriteria = hao.Employees__c >= assign.EmpMin__c && hao.Employees__c <= assign.EmpMax__c && String.isNotBlank(assign.States__c) && assign.States__c.contains(hao.State__c);

              System.debug('If Criteria: '+Boolean.valueOf(ifCriteria));
                         if (hao.Employees__c >= assign.EmpMin__c && hao.Employees__c <= assign.EmpMax__c && String.isNotBlank(assign.States__c) && assign.States__c.contains(hao.State__c)) {

                if(assign.Spanish_Speaking_Indicator__c == hao.Spanish_Speaking_Indicator__c){
                    matchedAssign = assign; 
                    break;              
                }else{
                    matchedAssign = assign;
                    break;
                }
                break;
                System.debug('Found matched Assign: '+matchedAssign.Name+'isRoundRobin:'+matchedAssign.IsRoundRobin__c+' IsSpanishSpeaking: '+matchedAssign.Spanish_Speaking_Indicator__c);
                System.debug('matchedAssign: '+matchedAssign);

             }
          } // for (HRGAssignment__c
       } // if (String.isNotBlank(state
       StringHelper.addToProcessNotes(hao,'matchedAssign='+(matchedAssign != null ? matchedAssign.Name : 'Not Found'));
       if (matchedAssign == null) {
          // TODO - do we need to do any special notification or status here? Is this an error if we don't find anything?
          StringHelper.addToProcessNotes(hao,'No rules were found for assignment');
          hao.Status__c = 'Error';
          return;
       }
       if (matchedAssign.IsRoundRobin__c) {
          handleRoundRobinPart1(matchedAssign,hao);
       } 
    //    else if (matchedAssign.DistanceInState1__c != null 
    //               || matchedAssign.DistanceInState2__c != null 
    //               || matchedAssign.DistanceNoState__c != null) {
    //    // we need to have at least one distance to do the next calculation
    //    findClosestHRG(acct, hao, matchedAssign);
    //    }
       
       
    } // processAccount
    
    public void handleRoundRobinPart1(HRGAssignment__c matchedAssign, HRG_Assignment__c hao) {
       Group queue = new UserHelper().getQueue(matchedAssign.QueueName__c);
       if (queue != null) {
          hao.OwnerId=queue.Id;
          roundRobinAssigns.add(hao);
          // these will be saved later
       } else {
          hao.Status__c = 'Error';
          StringHelper.addToProcessNotes(hao,'Could not find a queue for '+matchedAssign.QueueName__c);
       }
    } // handleRoundRobinPart1
    
    public void handleRoundRobinPart2() {
       // the records were already saved at this point and round robin should have been triggered.
       // reselect to get the new owners
       HRG_Assignment__c[] selectedAssigns = [Select Id, OwnerId, Owner.Name, Status__c, ProcessNotes__c, SelectedHRP__c,isMicro__c,Child_Opportunity_Ids__c 
                                                from HRG_Assignment__c where Id in :roundRobinAssigns];
        System.debug('roundRobin Assigns: '+roundRobinAssigns);
       // need to select the ownerIds to find the contacts 
       Id[] ownerIds = new Id[]{};

       for (HRG_Assignment__c assign : selectedAssigns) {
          ownerIds.add(assign.OwnerId);
       }
       System.debug('ownerIds :'+ownerIds);
       // select the contact records.
       Contact[] ctcts = [Select Id, Name, HR_Person_Id__c, User_Lookup__c
                                ,User_Lookup__r.ManagerId, User_Lookup__r.Manager.Name
                            from Contact where HR_Person_Id__c != null AND User_Lookup__c in :ownerIds];
       Map<Id,Contact> ctctMap = new Map<Id,Contact>();
       for (Contact ctct : ctcts) {
          ctctMap.put(ctct.User_Lookup__c, ctct);
       } // for (Contact ctct
       System.debug('Contacts in Contact map: '+ctctMap.values());
       Id newOwnerId = UserInfo.getUserId();

       for (HRG_Assignment__c assign : selectedAssigns) {
          Contact ctct = ctctMap.get(assign.OwnerId);
          StringHelper.addToProcessNotes(assign,'Searched for Contact, owner='+assign.Owner.Name+' ctct='+(ctct != null ? ctct.Name : 'Not Found!'));
          if (ctct == null) {
              System.debug('null Contact found!');
             // would this be an error if we can't find a contact record?
             assign.Status__c = 'Error';
          } else {
              if(assign.isMicro__c == true){
                // no approval needed
                // 5/24/2022 no more auto approval
                // System.debug('selected Contact:'+ctct);
                // assign.OwnerId = newOwnerId;
                // assign.SelectedHRP__c = ctct.Id;
                // assign.Status__c = 'Approved';
                // assign.Auto_Approved__c = true;
                // assign.Manager__c = (ctct.User_Lookup__c != null ? ctct.User_Lookup__r.ManagerId : null);
                // StringHelper.addToProcessNotes(assign,'Auto Approved assignment due to Round Robin');
              } else{
                assign.OwnerId = newOwnerId;
                assign.SelectedHRP__c = ctct.Id;
                System.debug('ctct: '+ctct+' ctct.User_Lookup__c: '+ctct.User_Lookup__c+'ctct.User_Lookup__r.ManagerId: '+ctct.User_Lookup__r.ManagerId);
                assign.Manager__c = (ctct.User_Lookup__c != null ? ctct.User_Lookup__r.ManagerId : null);
                assign.Status__c = (assign.Manager__c != null ? 'Waiting For Approval' : 'Error');
                if(assign.Child_Opportunity_Ids__c!= null){
                  // this is a parent
                  // pull in all the child assigns and assign 
                  List<String> childIds = assign.Child_Opportunity_Ids__c.split(',');
                  System.debug('ChildIds: '+childIds);
                  String[] oppSource = Label.oppSourceExclude.split(';');
                  List<Opportunity> childOpps = [Select Id, OppSource__c, Name,(Select Id, Name, SelectedHRP__c, Manager__c, Status__c, OwnerId, State__c,ProcessNotes__c from HRG_Assignments__r),AccountId,Account.ShippingState,Account.BillingState from Opportunity where Id in :childIds And OppSource__c not in :oppSource];
                  //! new child Id field
                  List<HRG_Assignment__c> childHRGs = new List<HRG_Assignment__c>();
                  // Multi-Id Scenario
                  System.debug('Size of Child Opps: '+childOpps.size());
                  for(Opportunity childOpp: childOpps){
                     if(!childOpp.HRG_Assignments__r.isEmpty()){
                        List<HRG_Assignment__c> childOppsHRGs = childOpp.HRG_Assignments__r;
                        for(HRG_Assignment__c childHRG :childOppsHRGs){
                           System.debug('childHRG Name:'+childHRG.Name+' ChildHRG Status: '+childHRG.Status__c);
                           if(childHRG.SelectedHRP__c==null && childHRG.Status__c=='Pending'){
                              childHRG.SelectedHRP__c = ctct.Id;
                              childHRG.Manager__c = (ctct.User_Lookup__c != null ? ctct.User_Lookup__r.ManagerId : null);
                              childHRG.Status__c = (assign.Manager__c != null ? 'Waiting For Approval' : 'Error');
                              childHRG.OwnerId = newOwnerId;
                              childHRG.State__c = (String.isNotBlank(childOpp.Account.ShippingState) ? childOpp.Account.ShippingState : childOpp.Account.BillingState);
                              // state field comes from the corresponding account. Opp>Account>HRG.State__c
                              StringHelper.addToProcessNotes(childHRG,'*** Child opportunity*** HRP suggested is same as parent Opp.');

                           
                           }
                        }
                        update childOppsHRGs;
                        System.debug('Chld Opportunities HRGs have been updated');
                        System.debug('Chld Opportunities HRGs: '+childOppsHRGs);
                     }
                  }
                }
                StringHelper.addToProcessNotes(assign,'Suggested HRG Found Via Round Robin');

              }
             
          }
       } // for (HRG_Assignment__c
       
       // trigger on the HRG_Assignment__c to assign to the account and do notifications
       update selectedAssigns;
       System.debug('HRGs have been updated');
       System.debug('HRGs: '+selectedAssigns);
             
    } // handleRoundRobinPart2
    

//    public class HRGWrapper {
//       public Contact ctct = null;
//       public Integer nbrClients = 0;
//    public Integer searchDistance = 0;
//    public Integer hrgDistance = 0;
//    } // class HRGWrapper
   
   
//    public void findClosestHRG(Account acct, HRG_Assignment__c hao, HRGAssignment__c matchedAssign) {
       //!deprecated method
    //   System.debug('findClosestHRG acct='+acct.Name+' matchedAssign='+matchedAssign.Name);
    //   // TODO - 
    //   Boolean spanishSpeaking = (acct.Language__c == 'Spanish');
    //   Address clientAddress = (String.IsNotBlank(acct.ShippingState) ? acct.ShippingAddress : (String.isNotBlank(acct.BillingState) ? acct.BillingAddress : null));
      
    //   StringHelper.addToProcessNotes(hao,'Using queue '+matchedAssign.QueueName__c);
    //   Group queue = new UserHelper().getQueue(matchedAssign.QueueName__c);
    //   if (queue == null) {
    //      hao.Status__c = 'Error';
    //   StringHelper.addToProcessNotes(hao,'Could not find a queue for '+matchedAssign.QueueName__c);
    //   return;
    //   }
      
    //   // TODO - are we going to setup these reps using the Round Robin functionality (Assignment Group) or directly to the Queue?
    //   // For Assignment Group 
    //   Assignment_Group_Queues__c[] agqs = 
    //   //new Assignment_Group_Queues__c[]{};
    //   [Select Id, QueueId__c, Assignment_Group_Name__c 
    //                                          from Assignment_Group_Queues__c
    //                                      where QueueId__c = :queue.Id
    //                                        and Active__c = 'true'];
    //   // should only be one, but what do we do if there is none or more than one?
    //   if (agqs.isEmpty()) {
    //      // log an error, return
    //   StringHelper.addToProcessNotes(hao,'Could not find an assignment Group Queue?');

    //   }
    //   System.debug('Name to match assignment group: '+agqs[0].Id);
    //   Assignment_Groups__c[] groupMembers = [Select Id, User__c,Group_Name__c,Active__c from Assignment_Groups__c Where Active__c='True' and Group_Name__c = :agqs[0].Assignment_Group_Name__c];
    //   Id[] userIds = new Id[]{};
    //   if(groupMembers.isEmpty()||groupMembers.size()==0){
    //  System.debug('groupMembers is empty');
    //   }
    //   for (Assignment_Groups__c groupMember : groupMembers) {
    //      userIds.add(groupMember.User__c);
    //   }

    //   List<Contact> ctcts = [Select Id, Name, OtherAddress,OtherState,OtherLatitude,OtherLongitude, Spanish_Speaking_Indicator__c, Number_of_Business_Clients__c 
    //                                ,User_Lookup__c, User_Lookup__r.ManagerId, User_Lookup__r.Manager.Name
    //                            from Contact 
    //                           where HR_Person_Id__c != null
    //                             and User_Lookup__c in :userIds];

    //   // For linking directly to queues
    // //   List<Contact> ctcts = [Select Id, Name, OtherAddress,OtherState, Spanish_Speaking_Indicator__c, Number_of_Business_Clients__c 
    // //                                ,User_Lookup__c, User_Lookup__r.ManagerId, User_Lookup__r.Manager.Name
    // //                            from Contact 
    // //                           where HR_Person_Id__c != null
    // //                             and User_Lookup__c in (Select UserOrGroupId from GroupMember where GroupId = :queue.Id)];
    // if(ctcts.isEmpty()){
    //  System.debug('No contacts found in group!');
    // }
                                
    // HRGWrapper lowestClientsInState1 = new HRGWrapper();
    // HRGWrapper lowestClientsInState2 = new HRGWrapper();
    // HRGWrapper lowestClientsNoState = new HRGWrapper();
    // HRGWrapper spanishSpeakingInState1 = new HRGWrapper();
    // HRGWrapper spanishSpeakingInState2 = new HRGWrapper();
    // HRGWrapper spanishSpeakingNoState = new HRGWrapper();
    
    // Integer checkNumberOfClients = 0;
    //     for(Contact ctct: ctcts){
    //        Location ctctLoc = Location.newInstance(ctct.OtherLatitude,ctct.OtherLongitude);
    //     System.debug('ctctLoc: '+ctctLoc);
    //     System.debug('clientAddress: '+clientAddress);
    //        Double hrgDistance = clientAddress.getDistance(ctctLoc,'mi');
    //     System.debug('****** HRG DISTANCE:'+ hrgDistance);
    //        Integer hrgClients = (ctct.Number_of_Business_Clients__c != null ? Integer.valueOf(ctct.Number_of_Business_Clients__c) : 0);
    //        if (spanishSpeaking && ctct.Spanish_Speaking_Indicator__c) {
    //            checkCriteria(ctct, spanishSpeakingInState1, hao.State__c, hrgClients, Integer.valueOf(hrgDistance), Integer.valueOf(matchedAssign.DistanceInState1__c));
    //            checkCriteria(ctct, spanishSpeakingInState2, hao.State__c, hrgClients, Integer.valueOf(hrgDistance), Integer.valueOf(matchedAssign.DistanceInState2__c));
    //            checkCriteria(ctct, spanishSpeakingNoState, null, hrgClients, Integer.valueOf(hrgDistance), Integer.valueOf(matchedAssign.DistanceNoState__c));
    //        }
    //     System.debug('ctctOtherState: '+ctct.OtherState);
    //     System.debug('ctct: '+ctct+' lowestClientInState: '+lowestClientsInState1+' HAO.State__c: '+hao.State__c+' hrgClients: '+hrgClients);
    //     System.debug('Distance: '+hrgDistance+' Hao.DistanceInState1: '+hao.DistanceInState1__c+' matchedAssign.DistanceInState1: '+Integer.valueOf(matchedAssign.DistanceInState1__c));
    //     System.debug(' matchedAssign.DistanceInState1: '+Integer.valueOf(matchedAssign.DistanceInState1__c)+' matchedAssign.DistanceInState2: '+Integer.valueOf(matchedAssign.DistanceInState2__c)+' matchedAssign.DistanceNoState: '+Integer.valueOf(matchedAssign.DistanceNoState__c));
    //     checkCriteria(ctct, lowestClientsInState1, hao.State__c, hrgClients, Integer.valueOf(hrgDistance), Integer.valueOf(matchedAssign.DistanceInState1__c));
    //        checkCriteria(ctct, lowestClientsInState2, hao.State__c, hrgClients, Integer.valueOf(hrgDistance), Integer.valueOf(matchedAssign.DistanceInState2__c));
    //        checkCriteria(ctct, lowestClientsNoState, null, hrgClients, Integer.valueOf(hrgDistance), Integer.valueOf(matchedAssign.DistanceNoState__c));
           
    //     } // for(Contact ctct: ctcts
        
    //  System.debug('SSIS1: '+spanishSpeakingInState1+'SSIS2: '+spanishSpeakingInState2+'SSNS: '+spanishSpeakingNoState);
    //     System.debug('LCIS1: '+lowestClientsInState1+'SSIS2: '+lowestClientsInState2+'SSNS: '+lowestClientsNoState);

    //     HRGWrapper bestWrap = (spanishSpeakingInState1.ctct != null ? spanishSpeakingInState1 
    //                            : spanishSpeakingInState2.ctct != null ? spanishSpeakingInState2 
    //                               : spanishSpeakingNoState.ctct != null ? spanishSpeakingNoState
    //                                  : lowestClientsInState1.ctct != null ? lowestClientsInState1
    //                                    : lowestClientsInState2.ctct != null ? lowestClientsInState2 
    //                                      : lowestClientsNoState.ctct != null ? lowestClientsNoState : null);
        
    //     StringHelper.addToProcessNotes(hao,'Search Complete, hrg='+(bestWrap != null && bestWrap.ctct != null ? bestWrap.ctct.Name : 'Not Found'));
    //  if (bestWrap != null && bestWrap.ctct != null) {
    //     hao.SearchDistance__c = bestWrap.searchDistance;
    //     hao.FoundDistance__c = bestWrap.hrgDistance;
    //     hao.SelectedHRP__c = bestWrap.ctct.Id;
    //     hao.Manager__c = (bestWrap.ctct.User_Lookup__c != null ? bestWrap.ctct.User_Lookup__r.ManagerId : null);
    //     // if the manager is blank is that an error? We can't notify the manager if we can't find them
    //     hao.Status__c = (hao.Manager__c != null ? 'Waiting For Approval' : 'Error');
    //        StringHelper.addToProcessNotes(hao,'Search successful');
    //  } else {
    //     hao.Status__c = 'Error';
    //        StringHelper.addToProcessNotes(hao,'Could not find an HRG in the distance(s) specified!');
    //     }
//    } // findClosestHRG

//    public static void checkCriteria(Contact ctct, HRGWrapper checkWrap, String clientState, Integer hrgClients, Integer hrgDistance, Integer checkDistance) {
//     System.debug('CheckWrap: '+checkWrap);  
//  if ((String.isEmpty(clientState) || (String.isNotEmpty(clientState) && ctct.OtherState == clientState))
//            && checkDistance != null && hrgDistance < checkDistance 
//            &&  (checkWrap.ctct == null || checkWrap.nbrClients < hrgClients)) {
//             System.debug('HRG Clients: '+hrgClients);
//      System.debug('this contact: '+ctct.Name+' passed the check criteria');
//      System.debug('this contact: '+ctct.Name+' passed the criteria check. (String.isEmpty(clientState):'
//      +String.isEmpty(clientState)+'(String.isNotEmpty(clientState) && ctct.OtherState == clientState)'
//      +String.valueOf(String.isNotEmpty(clientState) && ctct.OtherState == clientState)
//      +' checkDistance != null'+String.valueOf(checkDistance != null)
//      +' hrgDistance < checkDistance '+ String.valueOf(hrgDistance < checkDistance)
//      + '(checkWrap.ctct == null || checkWrap.nbrClients < hrgClients) '+String.valueOf(checkWrap.ctct == null )+'OR'+ String.valueOf(checkWrap.nbrClients < hrgClients));
  
//      System.debug('contact.OtherState = '+ctct.OtherState+' client State: '+ clientState+ ' ');
//          checkWrap.ctct = ctct;
//          checkWrap.nbrClients = hrgClients;
//       checkWrap.searchDistance = checkDistance;
//       checkWrap.hrgDistance = hrgDistance;
//       // keep track of the lowest number
//       hrgClients = checkWrap.nbrClients;
//       }
      
//    System.debug('this contact: '+ctct.Name+' Failed the criteria check. (String.isEmpty(clientState):'
//    +String.isEmpty(clientState)+'(String.isNotEmpty(clientState) && ctct.OtherState == clientState)'
//    +String.valueOf(String.isNotEmpty(clientState) && ctct.OtherState == clientState)
//    +' checkDistance != null'+String.valueOf(checkDistance != null)
//    +' hrgDistance < checkDistance '+ String.valueOf(hrgDistance < checkDistance)
//    + '(checkWrap.ctct == null || checkWrap.nbrClients < hrgClients) '+String.valueOf(checkWrap.ctct == null || checkWrap.nbrClients < hrgClients));
//    } // checkCriteria


} // class HRGAutoAssignmentQueueable