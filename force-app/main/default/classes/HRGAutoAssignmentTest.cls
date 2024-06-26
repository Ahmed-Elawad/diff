/*
History
-------
06/01/2022 Eric Porter       Created
 */
@isTest
public class HRGAutoAssignmentTest {

    @testSetup
    public static void setupData() {
        
       TriggerMethodsTest.createTriggerSetting('OpptyAfter', false, true, false, false, new String[]{'HRGAutoAssignment'});
       TriggerMethodsTest.saveSetupClasses();

        System.debug('SETUP TEST DATA');
            //create assignment group 
            // Group eastQueue = new Group(Name='HRGAutoEast',Type='Queue');
            // Group westQueue = new Group(Name='HRGAutoWest',Type='Queue');
            // List<Group> queues = new List<Group>();
            // queues.add(eastQueue);
            // queues.add(westQueue);
            // insert queues;
            // QueueSobject[] qSobjects = new QueueSobject[]{};
            // qSobjects.add(new QueueSobject(QueueId=eastQueue.Id,SobjectType='Case'));
            // qSobjects.add(new QueueSobject(QueueId=westQueue.Id,SobjectType='Case'));
            // insert qSobjects;
            
            // //create assignment group
            // Assignment_Group_Name__c eastQueueName = new Assignment_Group_Name__c(Name='HRGAutoEast');
            // Assignment_Group_Name__c westQueueName = new Assignment_Group_Name__c(Name='HRGAutoWest');
            // Assignment_Group_Name__c[] agns = new Assignment_Group_Name__c[]{eastQueueName,westQueueName};
            // insert agns;
            // //create assignment group queue

            // Assignment_Group_Queues__c eastAGQ = new Assignment_Group_Queues__c(Assignment_Group_Name__c=eastQueueName.Id, Name='HRGAutoEast');
            // Assignment_Group_Queues__c westAGQ = new Assignment_Group_Queues__c(Assignment_Group_Name__c=eastQueueName.Id, Name='HRGAutoWest');
            // Assignment_Group_Queues__c[] agqs = new Assignment_Group_Queues__c[]{eastAGQ,westAGQ}; 
            // insert agqs;
            // User[] users = [Select Id, Name from User where Profile.Name='System Administrator' 
            //                                         and IsActive=true
            //                                         and Assignment_Group_Active__c=true
            //                                         and Id != :runUser.Id 
            //                                         limit 4];
            // Assignment_Groups__c[] ags = new Assignment_Groups__c[]{};
            // Integer millisecond = 1;
            // //create group members

            // for (User u : users) {

            //     Assignment_Groups__c cag = new Assignment_Groups__c(Active__c='True',Group_Name__c=eastQueueName.Id,User__c=u.Id, Millisecond__c=millisecond++);
            //     ags.add(cag);
            // }
            // insert ags;
            List<HRGAssignment__c> hrg_cs = new List<HRGAssignment__c>();
// New Queues 
    HRGAssignment__c HRGAutoMicroQueue1 = new HRGAssignment__c(EmpMax__c = 9, EmpMin__c=0,  IsRoundRobin__c=true, Name='HRGAutoMicroQueue1',QueueName__c='HRGAutoMicroQueue1', Spanish_Speaking_Indicator__c = false,States__c ='ME,NH,VT,NJ,PA,DE');
    hrg_cs.add(HRGAutoMicroQueue1);
    HRGAssignment__c HRGAutoMicroQueue1SS = new HRGAssignment__c(EmpMax__c = 9, EmpMin__c = 0, IsRoundRobin__c=true,    Name = 'HRGAutoMicroQueue1SS', QueueName__c='HRGAutoMicroQueue1SS', Spanish_Speaking_Indicator__c=true, States__c='ME,NH,VT,NJ,PA,DE');
    hrg_cs.add(HRGAutoMicroQueue1SS);
    HRGAssignment__c HRGAutoMicroQueue2 = new HRGAssignment__c(EmpMax__c = 9, EmpMin__c = 0, IsRoundRobin__c=true,  Name = 'HRGAutoMicroQueue2', QueueName__c='HRGAutoMicroQueue2', Spanish_Speaking_Indicator__c=false, States__c='NY');
    hrg_cs.add(HRGAutoMicroQueue2);
    HRGAssignment__c HRGAutoMicroQueue2SS = new HRGAssignment__c(EmpMax__c = 9, EmpMin__c = 0, IsRoundRobin__c=true,    Name = 'HRGAutoMicroQueue2SS', QueueName__c='HRGAutoMicroQueue2SS', Spanish_Speaking_Indicator__c=true, States__c='NY');
    hrg_cs.add(HRGAutoMicroQueue2SS);
    //HRGAssignment__c HRGAutoMicroQueue3 = new HRGAssignment__c(EmpMax__c = 9, EmpMin__c = 0, IsRoundRobin__c=true,    Name = 'HRGAutoMicroQueue3', QueueName__c='HRGAutoMicroQueue3', Spanish_Speaking_Indicator__c=false, States__c='MA,RI,OH,IN,VA,NC,DC'); 
    //hrg_cs.add(HRGAutoMicroQueue3);
    //HRGAssignment__c HRGAutoMicroQueue3SS = new HRGAssignment__c(EmpMax__c = 9, EmpMin__c = 0, IsRoundRobin__c=true,  Name = 'HRGAutoMicroQueue3SS', QueueName__c='HRGAutoMicroQueue3SS', Spanish_Speaking_Indicator__c=true, States__c='MA,RI,OH,IN,VA,NC,DC');
    //hrg_cs.add(HRGAutoMicroQueue3SS);
    //HRGAssignment__c HRGAutoMicroQueue4 = new HRGAssignment__c(EmpMax__c = 9, EmpMin__c = 0, IsRoundRobin__c=true,    Name = 'HRGAutoMicroQueue4', QueueName__c='HRGAutoMicroQueue4', Spanish_Speaking_Indicator__c=false, States__c='CT,MD,WV,MI,KY,SC,GA,FL');
    //hrg_cs.add(HRGAutoMicroQueue4);
    //HRGAssignment__c HRGAutoMicroQueue4SS = new HRGAssignment__c(EmpMax__c = 9, EmpMin__c = 0, IsRoundRobin__c=true,  Name = 'HRGAutoMicroQueue4SS', QueueName__c='HRGAutoMicroQueue4SS', Spanish_Speaking_Indicator__c=true, States__c='CT,MD,WV,MI,KY,SC,GA,FL');   
    //hrg_cs.add(HRGAutoMicroQueue4SS);
    //HRGAssignment__c HRGAutoMicroQueue5 = new HRGAssignment__c(EmpMax__c = 9, EmpMin__c = 0, IsRoundRobin__c=true,    Name = 'HRGAutoMicroQueue5', QueueName__c='HRGAutoMicroQueue5', Spanish_Speaking_Indicator__c=false, States__c='CA,NV,MT,ID,WY,UT,CO,AZ,NM,HI');
    //hrg_cs.add(HRGAutoMicroQueue5);
    //HRGAssignment__c HRGAutoMicroQueue5SS = new HRGAssignment__c(EmpMax__c = 9, EmpMin__c = 0, IsRoundRobin__c=true,  Name = 'HRGAutoMicroQueue5SS', QueueName__c='HRGAutoMicroQueue5SS', Spanish_Speaking_Indicator__c=true, States__c='CA,NV,MT,ID,WY,UT,CO,AZ,NM,HI');
    //hrg_cs.add(HRGAutoMicroQueue5SS);
    //HRGAssignment__c HRGAutoMicroQueue6 = new HRGAssignment__c(EmpMax__c = 9, EmpMin__c = 0, IsRoundRobin__c=true,    Name = 'HRGAutoMicroQueue6', QueueName__c='HRGAutoMicroQueue6', Spanish_Speaking_Indicator__c=false, States__c='ND,SD,NE,KS,OK,TX,MN,IA,MO,AR,LA,WI,IL,TN,MI,AL');
    //hrg_cs.add(HRGAutoMicroQueue6);
    //HRGAssignment__c HRGAutoMicroQueue6SS = new HRGAssignment__c(EmpMax__c = 9, EmpMin__c = 0, IsRoundRobin__c=true,  Name = 'HRGAutoMicroQueue6SS', QueueName__c='HRGAutoMicroQueue6SS', Spanish_Speaking_Indicator__c=true, States__c='ND,SD,NE,KS,OK,TX,MN,IA,MO,AR,LA,WI,IL,TN,MI,AL');   
    //hrg_cs.add(HRGAutoMicroQueue6SS);
    //HRGAssignment__c HRGAutoMicroQueue7 = new HRGAssignment__c(EmpMax__c = 9, EmpMin__c = 0, IsRoundRobin__c=true,    Name = 'HRGAutoMicroQueue7', QueueName__c='HRGAutoMicroQueue7', Spanish_Speaking_Indicator__c=false, States__c='WA,OR,AK');
    //hrg_cs.add(HRGAutoMicroQueue7);
    //HRGAssignment__c HRGAutoMicroQueue7SS = new HRGAssignment__c(EmpMax__c = 9, EmpMin__c = 0, IsRoundRobin__c=true,  Name = 'HRGAutoMicroQueue7SS', QueueName__c='HRGAutoMicroQueue7SS', Spanish_Speaking_Indicator__c=true, States__c='WA,OR,AK');
    //hrg_cs.add(HRGAutoMicroQueue7SS);
    HRGAssignment__c HRGAutoSMBQueue1 = new HRGAssignment__c(EmpMax__c = 49, EmpMin__c = 10, IsRoundRobin__c=true,  Name = 'HRGAutoSMBQueue1', QueueName__c='HRGAutoSMBQueue1', Spanish_Speaking_Indicator__c=false, States__c='NY,NJ,PA'); 
    hrg_cs.add(HRGAutoSMBQueue1);
    HRGAssignment__c HRGAutoSMBQueue1SS = new HRGAssignment__c(EmpMax__c = 49, EmpMin__c = 10, IsRoundRobin__c=true,    Name = 'HRGAutoSMBQueue1SS', QueueName__c='HRGAutoSMBQueue1SS', Spanish_Speaking_Indicator__c=true, States__c='NY,NJ,PA');  
    hrg_cs.add(HRGAutoSMBQueue1SS);
    HRGAssignment__c HRGAutoSMBQueue2 = new HRGAssignment__c(EmpMax__c = 49, EmpMin__c = 10, IsRoundRobin__c=true,  Name = 'HRGAutoSMBQueue2', QueueName__c='HRGAutoSMBQueue2', Spanish_Speaking_Indicator__c=false, States__c='CT,ME,MA,NH,RI,VT');    
    hrg_cs.add(HRGAutoSMBQueue2);
    HRGAssignment__c HRGAutoSMBQueue2SS = new HRGAssignment__c(EmpMax__c = 49, EmpMin__c = 10, IsRoundRobin__c=true,    Name = 'HRGAutoSMBQueue2SS', QueueName__c='HRGAutoSMBQueue2SS', Spanish_Speaking_Indicator__c=true, States__c='CT,ME,MA,NH,RI,VT'); 
    hrg_cs.add(HRGAutoSMBQueue2SS);
    //HRGAssignment__c HRGAutoSMBQueue3 = new HRGAssignment__c(EmpMax__c = 49, EmpMin__c = 10, IsRoundRobin__c=true,    Name = 'HRGAutoSMBQueue3', QueueName__c='HRGAutoSMBQueue3', Spanish_Speaking_Indicator__c=false, States__c='AL,DE,FL,GA,IN,KY,MD,NC,OH,SC,TN,VA,DC,WV');
    //hrg_cs.add(HRGAutoSMBQueue3);
    //HRGAssignment__c HRGAutoSMBQueue3SS = new HRGAssignment__c(EmpMax__c = 49, EmpMin__c = 10, IsRoundRobin__c=true,  Name = 'HRGAutoSMBQueue3SS', QueueName__c='HRGAutoSMBQueue3SS', Spanish_Speaking_Indicator__c=true, States__c='AL,DE,FL,GA,IN,KY,MD,NC,OH,SC,TN,VA,DC,WV'); 
    //hrg_cs.add(HRGAutoSMBQueue3SS);
    //HRGAssignment__c HRGAutoSMBQueue4 = new HRGAssignment__c(EmpMax__c = 49, EmpMin__c = 10, IsRoundRobin__c=true,    Name = 'HRGAutoSMBQueue4', QueueName__c='HRGAutoSMBQueue4', Spanish_Speaking_Indicator__c=false, States__c='AK,CA,HI');
    //hrg_cs.add(HRGAutoSMBQueue4);
    //HRGAssignment__c HRGAutoSMBQueue4SS = new HRGAssignment__c(EmpMax__c = 49, EmpMin__c = 10, IsRoundRobin__c=true,  Name = 'HRGAutoSMBQueue4SS', QueueName__c='HRGAutoSMBQueue4SS', Spanish_Speaking_Indicator__c=true, States__c='AK,CA,HI');
    //hrg_cs.add(HRGAutoSMBQueue4SS);
    //HRGAssignment__c HRGAutoSMBQueue5 = new HRGAssignment__c(EmpMax__c = 49, EmpMin__c = 10, IsRoundRobin__c=true,    Name = 'HRGAutoSMBQueue5', QueueName__c='HRGAutoSMBQueue5', Spanish_Speaking_Indicator__c=false, States__c='AZ,CO,ID,MT,NV,NM,OR,UT,WA,WY');
    //hrg_cs.add(HRGAutoSMBQueue5);
    //HRGAssignment__c HRGAutoSMBQueue5SS = new HRGAssignment__c(EmpMax__c = 49, EmpMin__c = 10, IsRoundRobin__c=true,  Name = 'HRGAutoSMBQueue5SS', QueueName__c='HRGAutoSMBQueue5SS', Spanish_Speaking_Indicator__c=true, States__c='AZ,CO,ID,MT,NV,NM,OR,UT,WA,WY'); 
    //hrg_cs.add(HRGAutoSMBQueue5SS);
    //HRGAssignment__c HRGAutoSMBQueue6 = new HRGAssignment__c(EmpMax__c = 49, EmpMin__c = 10, IsRoundRobin__c=true,    Name = 'HRGAutoSMBQueue6', QueueName__c='HRGAutoSMBQueue6', Spanish_Speaking_Indicator__c=false, States__c='AR,IL,IA,KS,LA,MI,MN,MS,MO,NE,ND,OK,SD,TX,WI');
    //hrg_cs.add(HRGAutoSMBQueue6);
    //HRGAssignment__c HRGAutoSMBQueue6SS = new HRGAssignment__c(EmpMax__c = 49, EmpMin__c = 10, IsRoundRobin__c=true,  Name = 'HRGAutoSMBQueue6SS', QueueName__c='HRGAutoSMBQueue6SS', Spanish_Speaking_Indicator__c=true, States__c='AR,IL,IA,KS,LA,MI,MN,MS,MO,NE,ND,OK,SD,TX,WI');
    //hrg_cs.add(HRGAutoSMBQueue6SS);
    HRGAssignment__c HRGAutoMMQueue1 = new HRGAssignment__c(EmpMax__c = 199, EmpMin__c = 50, IsRoundRobin__c=true,  Name = 'HRGAutoMMQueue1', QueueName__c='HRGAutoMMQueue1', Spanish_Speaking_Indicator__c=false, States__c='NY,NJ,PA,CT,RI,MA,NH,VT,ME,DC,MD,DE');
    hrg_cs.add(HRGAutoMMQueue1);
    HRGAssignment__c HRGAutoMMQueue1SS = new HRGAssignment__c(EmpMax__c = 199, EmpMin__c = 50, IsRoundRobin__c=true,    Name = 'HRGAutoMMQueue1SS', QueueName__c='HRGAutoMMQueue1SS', Spanish_Speaking_Indicator__c=true, States__c='NY,NJ,PA,CT,RI,MA,NH,VT,ME,DC,MD,DE');
    hrg_cs.add(HRGAutoMMQueue1SS);
    HRGAssignment__c HRGAutoMMQueue2 = new HRGAssignment__c(EmpMax__c = 199, EmpMin__c = 50, IsRoundRobin__c=true,  Name = 'HRGAutoMMQueue2', QueueName__c='HRGAutoMMQueue2', Spanish_Speaking_Indicator__c=false, States__c='MN,WI,MI,IN,OH,KY,TN');
    hrg_cs.add(HRGAutoMMQueue2);
    HRGAssignment__c HRGAutoMMQueue2SS = new HRGAssignment__c(EmpMax__c = 199, EmpMin__c = 50, IsRoundRobin__c=true,    Name = 'HRGAutoMMQueue2SS', QueueName__c='HRGAutoMMQueue2SS', Spanish_Speaking_Indicator__c=true, States__c='MN,WI,MI,IN,OH,KY,TN');
    hrg_cs.add(HRGAutoMMQueue2SS);
    //HRGAssignment__c HRGAutoMMQueue3 = new HRGAssignment__c(EmpMax__c = 199, EmpMin__c = 50, IsRoundRobin__c=true,    Name = 'HRGAutoMMQueue3', QueueName__c='HRGAutoMMQueue3', Spanish_Speaking_Indicator__c=false, States__c='WV,VA,FL,GA,AL,MS,NC,SC');
    //hrg_cs.add(HRGAutoMMQueue3);
    //HRGAssignment__c HRGAutoMMQueue3SS = new HRGAssignment__c(EmpMax__c = 199, EmpMin__c = 50, IsRoundRobin__c=true,  Name = 'HRGAutoMMQueue3SS', QueueName__c='HRGAutoMMQueue3SS', Spanish_Speaking_Indicator__c=true, States__c='WV,VA,FL,GA,AL,MS,NC,SC');
    //hrg_cs.add(HRGAutoMMQueue3SS);
    //HRGAssignment__c HRGAutoMMQueue4 = new HRGAssignment__c(EmpMax__c = 199, EmpMin__c = 50, IsRoundRobin__c=true,    Name = 'HRGAutoMMQueue4', QueueName__c='HRGAutoMMQueue4', Spanish_Speaking_Indicator__c=false, States__c='IA,MO,AR,LA,ND,SD,NE,OK,TX,IL,KS');
    //hrg_cs.add(HRGAutoMMQueue4);
    //HRGAssignment__c HRGAutoMMQueue4SS = new HRGAssignment__c(EmpMax__c = 199, EmpMin__c = 50, IsRoundRobin__c=true,  Name = 'HRGAutoMMQueue4SS', QueueName__c='HRGAutoMMQueue4SS', Spanish_Speaking_Indicator__c=true, States__c='IA,MO,AR,LA,ND,SD,NE,OK,TX,IL,KS');
    //hrg_cs.add(HRGAutoMMQueue4SS);
    //HRGAssignment__c HRGAutoMMQueue5 = new HRGAssignment__c(EmpMax__c = 199, EmpMin__c = 50, IsRoundRobin__c=true,    Name = 'HRGAutoMMQueue5', QueueName__c='HRGAutoMMQueue5', Spanish_Speaking_Indicator__c=false, States__c='AZ,CO,ID,MT,NV,NM,OR,UT,WA,WY');
    //hrg_cs.add(HRGAutoMMQueue5);
    //HRGAssignment__c HRGAutoMMQueue5SS = new HRGAssignment__c(EmpMax__c = 199, EmpMin__c = 50, IsRoundRobin__c=true,  Name = 'HRGAutoMMQueue5SS', QueueName__c='HRGAutoMMQueue5SS', Spanish_Speaking_Indicator__c=true, States__c='AZ,CO,ID,MT,NV,NM,OR,UT,WA,WY');
    //hrg_cs.add(HRGAutoMMQueue5SS);
    //HRGAssignment__c HRGAutoMMQueue6 = new HRGAssignment__c(EmpMax__c = 199, EmpMin__c = 50, IsRoundRobin__c=true,    Name = 'HRGAutoMMQueue6', QueueName__c='HRGAutoMMQueue6', Spanish_Speaking_Indicator__c=false, States__c='CA,HI');
    //hrg_cs.add(HRGAutoMMQueue6);
    //HRGAssignment__c HRGAutoMMQueue6SS = new HRGAssignment__c(EmpMax__c = 199, EmpMin__c = 50, IsRoundRobin__c=true,  Name = 'HRGAutoMMQueue6SS', QueueName__c='HRGAutoMMQueue6SS', Spanish_Speaking_Indicator__c=true, States__c='CA,HI');
    //hrg_cs.add(HRGAutoMMQueue6SS);
    insert hrg_cs;

    //TODO set up queues 
    List<HRGAssignment__c> hrg_Cust = HRGAssignment__c.getAll().values();
    List<Group> queues= new List<Group>();
    List<Assignment_Group_Name__c> queueNames = new List<Assignment_Group_Name__c>();
    List<Assignment_Group_Queues__c> AGQs = new List<Assignment_Group_Queues__c>();
    for(HRGAssignment__c hcs: hrg_Cust){
        //Group tempQueue = new Group(Name=hcs.Name,Type='Queue');
        queues.add(new Group(Name=hcs.Name,Type='Queue'));
        //Assignment_Group_Name__c tempQueueName = new Assignment_Group_Name__c(Name=hcs.Name);
        queueNames.add(new Assignment_Group_Name__c(Name=hcs.Name));
        //Assignment_Group_Queues__c tempAGQ = new Assignment_Group_Queues__c(Assignment_Group_Name__c=tempQueueName.Id, Name=hcs.Name);
        //AGQs.add(tempAGQ);
    }
     System.runAs(new User(Id=UserInfo.getUserId())){
    insert queues;
    List<QueueSObject> supportedObjects = new List<QueueSObject>();
    for(Group queue: queues){
        QueueSObject q = new QueueSObject(SobjectType='HRG_Assignment__c', QueueId=queue.Id);
        QueueSObject q2 = new QueueSObject(SobjectType='Assignment_Group_Name__c', QueueId=queue.Id);

        supportedObjects.add(q);
        supportedObjects.add(q2);
    }
    insert supportedObjects;
    insert queueNames;
   }
    for (Integer cnt=0; cnt<queues.size(); cnt++) {
       AGQs.add(new Assignment_Group_Queues__c(Assignment_Group_Name__c=queueNames[cnt].Id, Name=queues[cnt].Name));
    }
    insert AGQs; 

    User[] users = [Select Id, Name,ManagerId,HR_Person_Id__c from User where Profile.Name='System Administrator' 
                                                    and IsActive=true
                                                    and Assignment_Group_Active__c=true
                                                    and Id != :UserInfo.getUserId() 
                                                    limit 4];
        
            System.debug('The users found: '+users);
            Assignment_Group_Name__c[] assignGrpNames = [Select Id, Name from Assignment_Group_Name__c];
            Map<String,Assignment_Group_Name__c> agnMap = new Map<String,Assignment_Group_Name__c>();
            for (Assignment_Group_Name__c assignGrpName : assignGrpNames) {
               agnMap.put(assignGrpName.Name, assignGrpName);
            }
            Assignment_Groups__c[] ags = new Assignment_Groups__c[]{};
            Integer millisecond = 1;
            //create group members
            //Assignment_Group_Name__c MidMarketqueuename = [Select Id, Name from Assignment_Group_Name__c where Name ='HRGAutoMMQueue1' limit 1];
            //Assignment_Group_Name__c MidMarketqueuenameSS = [Select Id, Name from Assignment_Group_Name__c where Name ='HRGAutoMMQueue1SS' limit 1];
            //Assignment_Group_Name__c SMBqueuename = [Select Id, Name from Assignment_Group_Name__c where Name ='HRGAutoSMBQueue1' limit 1];
            //Assignment_Group_Name__c SMBqueuenameSS = [Select Id, Name from Assignment_Group_Name__c where Name ='HRGAutoSMBQueue1SS' limit 1];
            //Assignment_Group_Name__c Microqueuename = [Select Id, Name from Assignment_Group_Name__c where Name ='HRGAutoMicroQueue2' limit 1];
            //Assignment_Group_Name__c MicroqueuenameSS = [Select Id, Name from Assignment_Group_Name__c where Name ='HRGAutoMicroQueue2SS' limit 1];
            Assignment_Group_Name__c MidMarketqueuename = agnMap.get('HRGAutoMMQueue1');
            Assignment_Group_Name__c MidMarketqueuenameSS = agnMap.get('HRGAutoMMQueue1SS');
            Assignment_Group_Name__c SMBqueuename = agnMap.get('HRGAutoSMBQueue1');
            Assignment_Group_Name__c SMBqueuenameSS = agnMap.get('HRGAutoSMBQueue1SS');
            Assignment_Group_Name__c Microqueuename = agnMap.get('HRGAutoMicroQueue2');
            Assignment_Group_Name__c MicroqueuenameSS = agnMap.get('HRGAutoMicroQueue2SS');
            Schema.RecordTypeInfo rtAcct = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT, 'Account');
            Schema.RecordTypeInfo rtCtct = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_CONTACT, 'Contact');
            Account fillerAcct = new Account(Name='Test Account 1',RecordTypeId=rtAcct.getRecordTypeId());
            List<Contact> repsAndManagers = new List<Contact>();
            for (User u : users) {
                System.debug('UserId: '+u.Id);
                Contact rep = new Contact(FirstName=u.Name,LastName='Test', User_Lookup__c = u.Id,AccountId=fillerAcct.Id,RecordTypeId=rtCtct.getRecordTypeId(),HR_Person_Id__c = u.HR_Person_Id__c);
                if(!repsAndManagers.contains(rep)){
                    repsAndManagers.add(rep);
                }
                User Manager = [Select Id,Name,HR_Person_Id__c from User where Id =:u.ManagerId];
                Contact ManagerContact = new Contact(FirstName = Manager.Name,LastName='Test', User_Lookup__c = Manager.Id,AccountId=fillerAcct.Id,RecordTypeId=rtCtct.getRecordTypeId(),HR_Person_Id__c = Manager.HR_Person_Id__c);
                if(!repsAndManagers.contains(managerContact)){
                    repsAndManagers.add(managerContact);
                }


                Assignment_Groups__c cag = new Assignment_Groups__c(Active__c='True',Group_Name__c=MidMarketqueuename.Id,User__c=u.Id, Millisecond__c=millisecond++);
                Assignment_Groups__c cag2 = new Assignment_Groups__c(Active__c='True',Group_Name__c=MidMarketqueuenameSS.Id,User__c=u.Id, Millisecond__c=millisecond++);
                Assignment_Groups__c cag3 = new Assignment_Groups__c(Active__c='True',Group_Name__c=SMBqueuename.Id,User__c=u.Id, Millisecond__c=millisecond++);
                Assignment_Groups__c cag4 = new Assignment_Groups__c(Active__c='True',Group_Name__c=SMBqueuenameSS.Id,User__c=u.Id, Millisecond__c=millisecond++);
                Assignment_Groups__c cag5 = new Assignment_Groups__c(Active__c='True',Group_Name__c=Microqueuename.Id,User__c=u.Id, Millisecond__c=millisecond++);
                Assignment_Groups__c cag6 = new Assignment_Groups__c(Active__c='True',Group_Name__c=MicroqueuenameSS.Id,User__c=u.Id, Millisecond__c=millisecond++);
                
                ags.add(cag);
                ags.add(cag2);
                ags.add(cag3);
                ags.add(cag4);
                ags.add(cag5);
                ags.add(cag6);
            }
            System.debug(repsAndManagers);
            insert repsAndManagers;
            insert ags;
       // set up queues and Assignment groups with some members in em
                Account testAcct = new Account(Name='Test Acct'
                ,ShippingStreet='21 Cayuga'
                ,ShippingState='NY'
                ,ShippingPostalCode='14850'
                ,BillingStreet='21 Cayuga'
                ,BillingState='NY'
                ,BillingPostalCode='14850');// be sure to add in shipping and billing address 
                ZipCheckOwner.SKIP_TRIGGERS=true;
                insert testAcct;

       setupProducts();
    } // setupData
    
    public static void setupProducts() {
                Product2 validProd = new Product2( Name ='HR Solutions - ASO (Non Payroll Client)'
                ,Default_Units_to_Employees__c=true,Unit_Type__c='Employees'
                ,Is_Non_Payroll_Unit__c=true
                ,Sales_Org__c='PAS'
                ,Pricing_Type__c='Monthly'
                ,IsActive=true
                ,ProductCode='ASO'
                );
                Product2 validProd2 = new Product2(Name ='HR Solutions (ASO)' 
                ,Default_Units_to_Employees__c=true
                ,IsActive=true
                ,Pricing_Type__c='Per Pay Period'
                ,Family='HR - HR Solutions'
                ,ProductCode='PNG ADMIN'
                );
                Product2[] prods = new Product2[]{validProd,validProd2};
                insert prods;
                System.debug('newly inserted prods: '+ prods);
                validProd = [Select Id,Name from Product2 where Name LIKE '%HR Solutions - ASO (Non Payroll Client)' limit 1];
                validProd2 = [Select Id,Name from Product2 where Name LIKE '%HR Solutions (ASO)%' limit 1];
                //Pricebook2 spricebook =  [select Id from Pricebook2 where isStandard=true];
                Id spricebookId =  Test.getStandardPricebookId();
                System.debug(spricebookId);
                List<PricebookEntry> standardPricebookProducts = [Select Id,Pricebook2Id,Product2Id,UnitPrice from PricebookEntry where Pricebook2Id =:spricebookId];
                System.debug('all the products in our standard pricebook in our test: '+standardPricebookProducts);
                Product2 productInPricebook = [Select Id,Name from Product2 where Id =:standardPricebookProducts[0].Product2Id];
                System.debug('name of product in pricebook: '+productInPricebook.Name);


                //PricebookEntry spbe1 = new PricebookEntry(Pricebook2Id = spricebookId, Product2Id = validProd.Id, UnitPrice=5.00, isActive=true,UseStandardPrice=false);
                PricebookEntry spbe2 = new PricebookEntry(Pricebook2Id = spricebookId, Product2Id = validProd2.Id, UnitPrice=7.00, isActive=true,UseStandardPrice=false);
                PricebookEntry[] spbes = new PricebookEntry[]{spbe2};
                insert spbes;
                
                Pricebook2 flexPB = new Pricebook2(Name='FLEX', IsActive=true);
                insert flexPB;
                
                //flexPB= [Select Id, Name, IsActive from Pricebook2 where Name='FLEX'];

                PricebookEntry pbe1 = new PricebookEntry(Pricebook2Id = flexPB.Id, Product2Id = validProd.Id, UnitPrice=5.00, isActive=true,UseStandardPrice=false);
                PricebookEntry pbe2 = new PricebookEntry(Pricebook2Id = flexPB.Id, Product2Id = validProd2.Id, UnitPrice=7.00, isActive=true,UseStandardPrice=false);  
                insert new PricebookEntry[]{pbe1,pbe2};
    } // setupProducts
    
    public static Pricebook2 getFlexPb() {
       Pricebook2 pb = [Select Id, IsActive, Name from Pricebook2 where Name='FLEX'];
       return pb;
    } // getFlexPb
    
    public static Product2 getValidProd1() {
       Product2 validProd = [Select Id,Name from Product2 where Name LIKE '%HR Solutions - ASO (Non Payroll Client)' limit 1];
       return validProd;
    } // getValidProd1
    
    public static Product2 getValidProd2() {
       Product2 validProd2 = [Select Id,Name from Product2 where Name LIKE '%HR Solutions (ASO)%' limit 1];
       return validProd2;
    }
    
    public static Account getTestAcct() {
       Account acct = [Select Id, Name, HR_Generalist__c, ShippingStreet, ShippingState, ShippingPostalCode, BillingStreet, BillingState,BillingPostalCode
                         From Account where Name='Test Acct'];
       return acct;
    } // getTestAcct
    
    static testMethod void test0To9Emps() {
        

                Account testAcct = getTestAcct();

                System.assertEquals(testAcct.HR_Generalist__c,null,'Account should not have an HRG on Account');

                Opportunity testOpp = new Opportunity(Name='Test Opp 1',Probability = 10
                ,StageName = 'Qualified',Employees_Paid_Per_Payroll__c=8
                ,AccountId = testAcct.Id,CloseDate=Date.today());
                insert testOpp;
                /*
                // add products to Opp
                Product2 validProd = new Product2( Name ='HR Solutions - ASO (Non Payroll Client)'
                ,Default_Units_to_Employees__c=true,Unit_Type__c='Employees'
                ,Is_Non_Payroll_Unit__c=true
                ,Sales_Org__c='PAS'
                ,Pricing_Type__c='Monthly'
                ,IsActive=true
                ,ProductCode='ASO'
                );
                Product2 validProd2 = new Product2(Name ='HR Solutions (ASO)' 
                ,Default_Units_to_Employees__c=true
                ,IsActive=true
                ,Pricing_Type__c='Per Pay Period'
                ,Family='HR - HR Solutions'
                ,ProductCode='PNG ADMIN'
                );
                List<Product2> prodsInRest = [Select id,Name from Product2 where Name Like '%HR Solutions%' limit 1000];
                System.debug('PRODS IN REST'+prodsInRest);
                Product2[] prods = new Product2[]{validProd,validProd2};
                insert prods;
                System.debug('newly inserted prods: '+ prods);
                validProd = [Select Id,Name from Product2 where Name LIKE '%HR Solutions - ASO (Non Payroll Client)' limit 1];
                validProd2 = [Select Id,Name from Product2 where Name LIKE '%HR Solutions (ASO)%' limit 1];
                //Pricebook2 spricebook =  [select Id from Pricebook2 where isStandard=true];
                Id spricebookId =  Test.getStandardPricebookId();
                System.debug(spricebookId);
                List<PricebookEntry> standardPricebookProducts = [Select Id,Pricebook2Id,Product2Id,UnitPrice from PricebookEntry where Pricebook2Id =:spricebookId];
                System.debug('all the products in our standard pricebook in our test: '+standardPricebookProducts);
                Product2 productInPricebook = [Select Id,Name from Product2 where Id =:standardPricebookProducts[0].Product2Id];
                System.debug('name of product in pricebook: '+productInPricebook.Name);


                //PricebookEntry spbe1 = new PricebookEntry(Pricebook2Id = spricebookId, Product2Id = validProd.Id, UnitPrice=5.00, isActive=true,UseStandardPrice=false);
                PricebookEntry spbe2 = new PricebookEntry(Pricebook2Id = spricebookId, Product2Id = validProd2.Id, UnitPrice=7.00, isActive=true,UseStandardPrice=false);
                PricebookEntry[] spbes = new PricebookEntry[]{spbe2};
                insert spbes;
                
                Pricebook2 flexPB = new Pricebook2(Name='FLEX', IsActive=true);
                insert flexPB;
                
                flexPB= [Select Id, Name, IsActive from Pricebook2 where Name='FLEX'];

                PricebookEntry pbe1 = new PricebookEntry(Pricebook2Id = flexPB.Id, Product2Id = validProd.Id, UnitPrice=5.00, isActive=true,UseStandardPrice=false);
                PricebookEntry pbe2 = new PricebookEntry(Pricebook2Id = flexPB.Id, Product2Id = validProd2.Id, UnitPrice=7.00, isActive=true,UseStandardPrice=false);  
                PricebookEntry[] pbes = new PricebookEntry[]{pbe1,pbe2};
                insert pbes;
                */
                Pricebook2 flexPB = getFlexPb();
                Product2 validProd = getValidProd1();
                Product2 validProd2 = getValidProd2();
        
                testOpp.Pricebook2Id = flexPB.Id;
                update testOpp;
                OpportunityLineItem oli1 = new OpportunityLineItem(Product2Id= validProd.Id , OpportunityId = testOpp.Id,Quantity=1,TotalPrice=5);
                OpportunityLineItem oli2 = new OpportunityLineItem(Product2Id= validProd2.Id , OpportunityId = testOpp.Id,Quantity=1,TotalPrice=7);
                OpportunityLineItem[] olis = new OpportunityLineItem[]{oli1,oli2};
                insert olis;
                System.assertEquals(oli1.OpportunityId,testOpp.Id,'Not the same opportunity on the opp line item ');
                System.assertEquals(oli2.OpportunityId,testOpp.Id,'Not the same opportunity on the opp line item ');


                testOpp.Probability = 90;
                testOpp.StageName = 'Sold';
                testOpp.Assign_HRG__c = true;
                update testOpp;
                System.assert(testOpp.Probability>=90,'Probability is not greater than or equal to 90');
                List<Opportunity> oppList = new List<Opportunity>{testOpp};
                Map<Id,Opportunity> oppMap = new Map<Id, Opportunity>(oppList);
                Set<Id> acctIds = new Set<Id>{testOpp.AccountId};
                Test.startTest();
                HRGAutoAssignmentQueueable tempQueueable = new HRGAutoAssignmentQueueable(oppMap,acctIds);
                System.enqueueJob(tempQueueable);
                Test.stopTest();
                HRG_Assignment__c createdHAO = [Select Id,Opportunity__c,SelectedHRP__c from HRG_Assignment__c where Opportunity__c = :testOpp.Id limit 1];
                System.assertNotEquals(createdHAO,null,'did not create HRG Assignment Object');
                System.debug('Created HAO'+createdHAO);
                //System.assertEquals(createdHAO.SelectedHRP__c,null,'Selected HRG was not assigned');
                Account updatedAcct = [Select Id,Name,HR_Generalist__c from Account where Id = :testAcct.Id];
                System.assertEquals(updatedAcct.HR_Generalist__c,null,'Selected HRG populated Account');

            //TODO double check the opp we're testing is micro
            //todo double check there are contacts available in that queue
    

            //create Accounts for test
            
            //create Opportunities for test 

            }
            static testMethod void test0To9Emps2() {
        

                Account testAcct = getTestAcct();

                System.assertEquals(testAcct.HR_Generalist__c,null,'Account should not have an HRG on Account');

                Opportunity testOpp = new Opportunity(Name='Test Opp 1',Probability = 10
                ,StageName = 'Qualified',Employees_Paid_Per_Payroll__c=8
                ,AccountId = testAcct.Id,CloseDate=Date.today());
                insert testOpp;
                /*
                // add products to Opp
                Product2 validProd = new Product2( Name ='HR Solutions - ASO (Non Payroll Client)'
                ,Default_Units_to_Employees__c=true,Unit_Type__c='Employees'
                ,Is_Non_Payroll_Unit__c=true
                ,Sales_Org__c='PAS'
                ,Pricing_Type__c='Monthly'
                ,IsActive=true
                ,ProductCode='ASO'
                );
                Product2 validProd2 = new Product2(Name ='HR Solutions (ASO)' 
                ,Default_Units_to_Employees__c=true
                ,IsActive=true
                ,Pricing_Type__c='Per Pay Period'
                ,Family='HR - HR Solutions'
                ,ProductCode='PNG ADMIN'
                );
                List<Product2> prodsInRest = [Select id,Name from Product2 where Name Like '%HR Solutions%' limit 1000];
                System.debug('PRODS IN REST'+prodsInRest);
                Product2[] prods = new Product2[]{validProd,validProd2};
                insert prods;
                System.debug('newly inserted prods: '+ prods);
                validProd = [Select Id,Name from Product2 where Name LIKE '%HR Solutions - ASO (Non Payroll Client)' limit 1];
                validProd2 = [Select Id,Name from Product2 where Name LIKE '%HR Solutions (ASO)%' limit 1];
                //Pricebook2 spricebook =  [select Id from Pricebook2 where isStandard=true];
                Id spricebookId =  Test.getStandardPricebookId();
                System.debug(spricebookId);
                List<PricebookEntry> standardPricebookProducts = [Select Id,Pricebook2Id,Product2Id,UnitPrice from PricebookEntry where Pricebook2Id =:spricebookId];
                System.debug('all the products in our standard pricebook in our test: '+standardPricebookProducts);
                Product2 productInPricebook = [Select Id,Name from Product2 where Id =:standardPricebookProducts[0].Product2Id];
                System.debug('name of product in pricebook: '+productInPricebook.Name);


                //PricebookEntry spbe1 = new PricebookEntry(Pricebook2Id = spricebookId, Product2Id = validProd.Id, UnitPrice=5.00, isActive=true,UseStandardPrice=false);
                PricebookEntry spbe2 = new PricebookEntry(Pricebook2Id = spricebookId, Product2Id = validProd2.Id, UnitPrice=7.00, isActive=true,UseStandardPrice=false);
                PricebookEntry[] spbes = new PricebookEntry[]{spbe2};
                insert spbes;
                
                Pricebook2 flexPB = new Pricebook2(Name='FLEX', IsActive=true);
                insert flexPB;
                
                flexPB= [Select Id, Name, IsActive from Pricebook2 where Name='FLEX'];

                PricebookEntry pbe1 = new PricebookEntry(Pricebook2Id = flexPB.Id, Product2Id = validProd.Id, UnitPrice=5.00, isActive=true,UseStandardPrice=false);
                PricebookEntry pbe2 = new PricebookEntry(Pricebook2Id = flexPB.Id, Product2Id = validProd2.Id, UnitPrice=7.00, isActive=true,UseStandardPrice=false);  
                PricebookEntry[] pbes = new PricebookEntry[]{pbe1,pbe2};
                insert pbes;
                */
                Pricebook2 flexPB = getFlexPb();
                Product2 validProd = getValidProd1();
                Product2 validProd2 = getValidProd2();
        
                testOpp.Pricebook2Id = flexPB.Id;
                update testOpp;
                OpportunityLineItem oli1 = new OpportunityLineItem(Product2Id= validProd.Id , OpportunityId = testOpp.Id,Quantity=1,TotalPrice=5);
                OpportunityLineItem oli2 = new OpportunityLineItem(Product2Id= validProd2.Id , OpportunityId = testOpp.Id,Quantity=1,TotalPrice=7);
                OpportunityLineItem[] olis = new OpportunityLineItem[]{oli1,oli2};
                insert olis;
                System.assertEquals(oli1.OpportunityId,testOpp.Id,'Not the same opportunity on the opp line item ');
                System.assertEquals(oli2.OpportunityId,testOpp.Id,'Not the same opportunity on the opp line item ');


                testOpp.Probability = 100;
                testOpp.StageName = 'Sold';
                testOpp.Assign_HRG__c = true;
                update testOpp;
                System.assert(testOpp.Probability>=90,'Probability is not greater than or equal to 90');
                List<Opportunity> oppList = new List<Opportunity>{testOpp};
                Map<Id,Opportunity> oppMap = new Map<Id, Opportunity>(oppList);
                Set<Id> acctIds = new Set<Id>{testOpp.AccountId};
                Test.startTest();
                HRGAutoAssignmentQueueable tempQueueable = new HRGAutoAssignmentQueueable(oppMap,acctIds);
                System.enqueueJob(tempQueueable);
                Test.stopTest();
                HRG_Assignment__c createdHAO = [Select Id,Opportunity__c,SelectedHRP__c from HRG_Assignment__c where Opportunity__c = :testOpp.Id limit 1];
                System.assertNotEquals(createdHAO,null,'did not create HRG Assignment Object');
                System.debug('Created HAO'+createdHAO);
                //System.assertEquals(createdHAO.SelectedHRP__c,null,'Selected HRG was not assigned');
                Account updatedAcct = [Select Id,Name,HR_Generalist__c from Account where Id = :testAcct.Id];
                System.assertEquals(updatedAcct.HR_Generalist__c,null,'Selected HRG populated Account');

            //TODO double check the opp we're testing is micro
            //todo double check there are contacts available in that queue
    

            //create Accounts for test
            
            //create Opportunities for test 

            }
            
            
            
            
            
            
            static testMethod void test10To49Emps() {
                Account testAcct = getTestAcct();
                System.assertEquals(testAcct.HR_Generalist__c,null,'Account should not have an HRG on Account');

                Opportunity testOpp = new Opportunity(Name='Test Opp 1',Probability = 10
                ,StageName = 'Qualified',Employees_Paid_Per_Payroll__c=15
                ,AccountId = testAcct.Id,CloseDate=Date.today());
                insert testOpp;
                /*
                // add products to Opp
                Product2 validProd = new Product2( Name ='HR Solutions - ASO (Non Payroll Client)'
                ,Default_Units_to_Employees__c=true,Unit_Type__c='Employees'
                ,Is_Non_Payroll_Unit__c=true
                ,Sales_Org__c='PAS'
                ,Pricing_Type__c='Monthly'
                ,IsActive=true
                ,ProductCode='ASO'
                );
                Product2 validProd2 = new Product2(Name ='HR Solutions (ASO)' 
                ,Default_Units_to_Employees__c=true
                ,IsActive=true
                ,Pricing_Type__c='Per Pay Period'
                ,Family='HR - HR Solutions'
                ,ProductCode='PNG ADMIN'
                );
                List<Product2> prodsInRest = [Select id,Name from Product2 where Name Like '%HR Solutions%' limit 1000];
                System.debug('PRODS IN REST'+prodsInRest);
                Product2[] prods = new Product2[]{validProd,validProd2};
                insert prods;
                System.debug('newly inserted prods: '+ prods);
                validProd = [Select Id,Name from Product2 where Name LIKE '%HR Solutions - ASO (Non Payroll Client)' limit 1];
                validProd2 = [Select Id,Name from Product2 where Name LIKE '%HR Solutions (ASO)%' limit 1];
                //Pricebook2 spricebook =  [select Id from Pricebook2 where isStandard=true];
                Id spricebookId =  Test.getStandardPricebookId();
                System.debug(spricebookId);
                List<PricebookEntry> standardPricebookProducts = [Select Id,Pricebook2Id,Product2Id,UnitPrice from PricebookEntry where Pricebook2Id =:spricebookId];
                System.debug('all the products in our standard pricebook in our test: '+standardPricebookProducts);
                Product2 productInPricebook = [Select Id,Name from Product2 where Id =:standardPricebookProducts[0].Product2Id];
                System.debug('name of product in pricebook: '+productInPricebook.Name);


                //PricebookEntry spbe1 = new PricebookEntry(Pricebook2Id = spricebookId, Product2Id = validProd.Id, UnitPrice=5.00, isActive=true,UseStandardPrice=false);
                PricebookEntry spbe2 = new PricebookEntry(Pricebook2Id = spricebookId, Product2Id = validProd2.Id, UnitPrice=7.00, isActive=true,UseStandardPrice=false);
                PricebookEntry[] spbes = new PricebookEntry[]{spbe2};
                insert spbes;
                
                Pricebook2 flexPB = new Pricebook2(Name='FLEX', IsActive=true);
                insert flexPB;
                
                flexPB= [Select Id, Name, IsActive from Pricebook2 where Name='FLEX'];

                PricebookEntry pbe1 = new PricebookEntry(Pricebook2Id = flexPB.Id, Product2Id = validProd.Id, UnitPrice=5.00, isActive=true,UseStandardPrice=false);
                PricebookEntry pbe2 = new PricebookEntry(Pricebook2Id = flexPB.Id, Product2Id = validProd2.Id, UnitPrice=7.00, isActive=true,UseStandardPrice=false);  
                PricebookEntry[] pbes = new PricebookEntry[]{pbe1,pbe2};
                insert pbes;
                */
                Pricebook2 flexPB = getFlexPb();
                Product2 validProd = getValidProd1();
                Product2 validProd2 = getValidProd2();

                testOpp.Pricebook2Id = flexPB.Id;
                update testOpp;
                OpportunityLineItem oli1 = new OpportunityLineItem(Product2Id= validProd.Id , OpportunityId = testOpp.Id,Quantity=1,TotalPrice=5);
                OpportunityLineItem oli2 = new OpportunityLineItem(Product2Id= validProd2.Id , OpportunityId = testOpp.Id,Quantity=1,TotalPrice=7);
                OpportunityLineItem[] olis = new OpportunityLineItem[]{oli1,oli2};
                insert olis;
                System.assertEquals(oli1.OpportunityId,testOpp.Id,'Not the same opportunity on the opp line item ');
                System.assertEquals(oli2.OpportunityId,testOpp.Id,'Not the same opportunity on the opp line item ');


                testOpp.Probability = 90;
                testOpp.StageName = 'Sold';
                testOpp.Assign_HRG__c = true;
                update testOpp;
                System.assert(testOpp.Probability>=90,'Probability is not greater than or equal to 90');
                List<Opportunity> oppList = new List<Opportunity>{testOpp};
                Map<Id,Opportunity> oppMap = new Map<Id, Opportunity>(oppList);
                Set<Id> acctIds = new Set<Id>{testOpp.AccountId};
                Test.startTest();
                HRGAutoAssignmentQueueable tempQueueable = new HRGAutoAssignmentQueueable(oppMap,acctIds);
                System.enqueueJob(tempQueueable);
                Test.stopTest();
                HRG_Assignment__c createdHAO = [Select Id,Opportunity__c,SelectedHRP__c,Status__c from HRG_Assignment__c where Opportunity__c = :testOpp.Id limit 1];
                System.assertNotEquals(createdHAO,null,'did not create HRG Assignment Object');
                System.debug('Created HAO'+createdHAO);
                //System.assertEquals(createdHAO.SelectedHRP__c,null,'Selected HRG was assigned and should not have been');
                //System.assertEquals(createdHAO.Status__c,'Waiting For Approval','Status was not Waiting For Approval');
                Account updatedAcct = [Select Id,Name,HR_Generalist__c from Account where Id = :testAcct.Id];
                System.assertEquals(updatedAcct.HR_Generalist__c,null,'Selected HRG populated Account');

            }
            static testMethod void test10To49Emps2() {
                Account testAcct = getTestAcct();
                System.assertEquals(testAcct.HR_Generalist__c,null,'Account should not have an HRG on Account');

                Opportunity testOpp = new Opportunity(Name='Test Opp 1',Probability = 10
                ,StageName = 'Qualified',Employees_Paid_Per_Payroll__c=15
                ,AccountId = testAcct.Id,CloseDate=Date.today());
                insert testOpp;
                /*
                // add products to Opp
                Product2 validProd = new Product2( Name ='HR Solutions - ASO (Non Payroll Client)'
                ,Default_Units_to_Employees__c=true,Unit_Type__c='Employees'
                ,Is_Non_Payroll_Unit__c=true
                ,Sales_Org__c='PAS'
                ,Pricing_Type__c='Monthly'
                ,IsActive=true
                ,ProductCode='ASO'
                );
                Product2 validProd2 = new Product2(Name ='HR Solutions (ASO)' 
                ,Default_Units_to_Employees__c=true
                ,IsActive=true
                ,Pricing_Type__c='Per Pay Period'
                ,Family='HR - HR Solutions'
                ,ProductCode='PNG ADMIN'
                );
                List<Product2> prodsInRest = [Select id,Name from Product2 where Name Like '%HR Solutions%' limit 1000];
                System.debug('PRODS IN REST'+prodsInRest);
                Product2[] prods = new Product2[]{validProd,validProd2};
                insert prods;
                System.debug('newly inserted prods: '+ prods);
                validProd = [Select Id,Name from Product2 where Name LIKE '%HR Solutions - ASO (Non Payroll Client)' limit 1];
                validProd2 = [Select Id,Name from Product2 where Name LIKE '%HR Solutions (ASO)%' limit 1];
                //Pricebook2 spricebook =  [select Id from Pricebook2 where isStandard=true];
                Id spricebookId =  Test.getStandardPricebookId();
                System.debug(spricebookId);
                List<PricebookEntry> standardPricebookProducts = [Select Id,Pricebook2Id,Product2Id,UnitPrice from PricebookEntry where Pricebook2Id =:spricebookId];
                System.debug('all the products in our standard pricebook in our test: '+standardPricebookProducts);
                Product2 productInPricebook = [Select Id,Name from Product2 where Id =:standardPricebookProducts[0].Product2Id];
                System.debug('name of product in pricebook: '+productInPricebook.Name);


                //PricebookEntry spbe1 = new PricebookEntry(Pricebook2Id = spricebookId, Product2Id = validProd.Id, UnitPrice=5.00, isActive=true,UseStandardPrice=false);
                PricebookEntry spbe2 = new PricebookEntry(Pricebook2Id = spricebookId, Product2Id = validProd2.Id, UnitPrice=7.00, isActive=true,UseStandardPrice=false);
                PricebookEntry[] spbes = new PricebookEntry[]{spbe2};
                insert spbes;
                
                Pricebook2 flexPB = new Pricebook2(Name='FLEX', IsActive=true);
                insert flexPB;
                
                flexPB= [Select Id, Name, IsActive from Pricebook2 where Name='FLEX'];

                PricebookEntry pbe1 = new PricebookEntry(Pricebook2Id = flexPB.Id, Product2Id = validProd.Id, UnitPrice=5.00, isActive=true,UseStandardPrice=false);
                PricebookEntry pbe2 = new PricebookEntry(Pricebook2Id = flexPB.Id, Product2Id = validProd2.Id, UnitPrice=7.00, isActive=true,UseStandardPrice=false);  
                PricebookEntry[] pbes = new PricebookEntry[]{pbe1,pbe2};
                insert pbes;
                */
                Pricebook2 flexPB = getFlexPb();
                Product2 validProd = getValidProd1();
                Product2 validProd2 = getValidProd2();

                testOpp.Pricebook2Id = flexPB.Id;
                update testOpp;
                OpportunityLineItem oli1 = new OpportunityLineItem(Product2Id= validProd.Id , OpportunityId = testOpp.Id,Quantity=1,TotalPrice=5);
                OpportunityLineItem oli2 = new OpportunityLineItem(Product2Id= validProd2.Id , OpportunityId = testOpp.Id,Quantity=1,TotalPrice=7);
                OpportunityLineItem[] olis = new OpportunityLineItem[]{oli1,oli2};
                insert olis;
                System.assertEquals(oli1.OpportunityId,testOpp.Id,'Not the same opportunity on the opp line item ');
                System.assertEquals(oli2.OpportunityId,testOpp.Id,'Not the same opportunity on the opp line item ');


                testOpp.Probability = 100;
                testOpp.StageName = 'Sold';
                testOpp.Assign_HRG__c = true;
                update testOpp;
                System.assert(testOpp.Probability>=90,'Probability is not greater than or equal to 90');
                List<Opportunity> oppList = new List<Opportunity>{testOpp};
                Map<Id,Opportunity> oppMap = new Map<Id, Opportunity>(oppList);
                Set<Id> acctIds = new Set<Id>{testOpp.AccountId};
                Test.startTest();
                HRGAutoAssignmentQueueable tempQueueable = new HRGAutoAssignmentQueueable(oppMap,acctIds);
                System.enqueueJob(tempQueueable);
                Test.stopTest();
                HRG_Assignment__c createdHAO = [Select Id,Opportunity__c,SelectedHRP__c,Status__c from HRG_Assignment__c where Opportunity__c = :testOpp.Id limit 1];
                System.assertNotEquals(createdHAO,null,'did not create HRG Assignment Object');
                System.debug('Created HAO'+createdHAO);
                //System.assertEquals(createdHAO.SelectedHRP__c,null,'Selected HRG was assigned and should not have been');
                //System.assertEquals(createdHAO.Status__c,'Waiting For Approval','Status was not Waiting For Approval');
                Account updatedAcct = [Select Id,Name,HR_Generalist__c from Account where Id = :testAcct.Id];
                System.assertEquals(updatedAcct.HR_Generalist__c,null,'Selected HRG populated Account');

            }
            static testMethod void test50To199Emps() {
                Account testAcct = getTestAcct();
                System.assertEquals(testAcct.HR_Generalist__c,null,'Account should not have an HRG on Account');

                Opportunity testOpp = new Opportunity(Name='Test Opp 1',Probability = 10
                ,StageName = 'Qualified',Employees_Paid_Per_Payroll__c=75
                ,AccountId = testAcct.Id,CloseDate=Date.today());
                insert testOpp;
                /*
                // add products to Opp
                Product2 validProd = new Product2( Name ='HR Solutions - ASO (Non Payroll Client)'
                ,Default_Units_to_Employees__c=true,Unit_Type__c='Employees'
                ,Is_Non_Payroll_Unit__c=true
                ,Sales_Org__c='PAS'
                ,Pricing_Type__c='Monthly'
                ,IsActive=true
                ,ProductCode='ASO'
                );
                Product2 validProd2 = new Product2(Name ='HR Solutions (ASO)' 
                ,Default_Units_to_Employees__c=true
                ,IsActive=true
                ,Pricing_Type__c='Per Pay Period'
                ,Family='HR - HR Solutions'
                ,ProductCode='PNG ADMIN'
                );
                List<Product2> prodsInRest = [Select id,Name from Product2 where Name Like '%HR Solutions%' limit 1000];
                System.debug('PRODS IN REST'+prodsInRest);
                Product2[] prods = new Product2[]{validProd,validProd2};
                insert prods;
                System.debug('newly inserted prods: '+ prods);
                validProd = [Select Id,Name from Product2 where Name LIKE '%HR Solutions - ASO (Non Payroll Client)' limit 1];
                validProd2 = [Select Id,Name from Product2 where Name LIKE '%HR Solutions (ASO)%' limit 1];
                //Pricebook2 spricebook =  [select Id from Pricebook2 where isStandard=true];
                Id spricebookId =  Test.getStandardPricebookId();
                System.debug(spricebookId);
                List<PricebookEntry> standardPricebookProducts = [Select Id,Pricebook2Id,Product2Id,UnitPrice from PricebookEntry where Pricebook2Id =:spricebookId];
                System.debug('all the products in our standard pricebook in our test: '+standardPricebookProducts);
                Product2 productInPricebook = [Select Id,Name from Product2 where Id =:standardPricebookProducts[0].Product2Id];
                System.debug('name of product in pricebook: '+productInPricebook.Name);


                //PricebookEntry spbe1 = new PricebookEntry(Pricebook2Id = spricebookId, Product2Id = validProd.Id, UnitPrice=5.00, isActive=true,UseStandardPrice=false);
                PricebookEntry spbe2 = new PricebookEntry(Pricebook2Id = spricebookId, Product2Id = validProd2.Id, UnitPrice=7.00, isActive=true,UseStandardPrice=false);
                PricebookEntry[] spbes = new PricebookEntry[]{spbe2};
                insert spbes;
                
                Pricebook2 flexPB = new Pricebook2(Name='FLEX', IsActive=true);
                insert flexPB;
                
                flexPB= [Select Id, Name, IsActive from Pricebook2 where Name='FLEX'];

                PricebookEntry pbe1 = new PricebookEntry(Pricebook2Id = flexPB.Id, Product2Id = validProd.Id, UnitPrice=5.00, isActive=true,UseStandardPrice=false);
                PricebookEntry pbe2 = new PricebookEntry(Pricebook2Id = flexPB.Id, Product2Id = validProd2.Id, UnitPrice=7.00, isActive=true,UseStandardPrice=false);  
                PricebookEntry[] pbes = new PricebookEntry[]{pbe1,pbe2};
                insert pbes;
                */
                Pricebook2 flexPB = getFlexPb();
                Product2 validProd = getValidProd1();
                Product2 validProd2 = getValidProd2();

                testOpp.Pricebook2Id = flexPB.Id;
                update testOpp;
                OpportunityLineItem oli1 = new OpportunityLineItem(Product2Id= validProd.Id , OpportunityId = testOpp.Id,Quantity=1,TotalPrice=5);
                OpportunityLineItem oli2 = new OpportunityLineItem(Product2Id= validProd2.Id , OpportunityId = testOpp.Id,Quantity=1,TotalPrice=7);
                OpportunityLineItem[] olis = new OpportunityLineItem[]{oli1,oli2};
                insert olis;
                System.assertEquals(oli1.OpportunityId,testOpp.Id,'Not the same opportunity on the opp line item ');
                System.assertEquals(oli2.OpportunityId,testOpp.Id,'Not the same opportunity on the opp line item ');


                testOpp.Probability = 90;
                testOpp.StageName = 'Sold';
                testOpp.Assign_HRG__c = true;
                System.assert(testOpp.Probability>=90,'Probability is not greater than or equal to 90');
                List<Opportunity> oppList = new List<Opportunity>{testOpp};
                Map<Id,Opportunity> oppMap = new Map<Id, Opportunity>(oppList);
                Set<Id> acctIds = new Set<Id>{testOpp.AccountId};
                Test.startTest();
                update testOpp;
                HRGAutoAssignmentQueueable tempQueueable = new HRGAutoAssignmentQueueable(oppMap,acctIds);
                System.enqueueJob(tempQueueable);
                Test.stopTest();
                HRG_Assignment__c createdHAO = [Select Id,Opportunity__c,SelectedHRP__c,Status__c from HRG_Assignment__c where Opportunity__c = :testOpp.Id limit 1];
                System.assertNotEquals(createdHAO,null,'did not create HRG Assignment Object');
                System.debug('Created HAO'+createdHAO);
                //System.assertEquals(createdHAO.SelectedHRP__c,null,'Selected HRG was assigned and should not have been');
                //System.assertEquals(createdHAO.Status__c,'Waiting For Approval','Status was not Waiting For Approval');
                Account updatedAcct = [Select Id,Name,HR_Generalist__c from Account where Id = :testAcct.Id];
                System.assertEquals(updatedAcct.HR_Generalist__c,null,'Selected HRG populated Account');
            }
            static testMethod void test50To199Emps2() {
                Account testAcct = getTestAcct();
                System.assertEquals(testAcct.HR_Generalist__c,null,'Account should not have an HRG on Account');

                Opportunity testOpp = new Opportunity(Name='Test Opp 1',Probability = 10
                ,StageName = 'Qualified',Employees_Paid_Per_Payroll__c=75
                ,AccountId = testAcct.Id,CloseDate=Date.today());
                insert testOpp;
                /*
                // add products to Opp
                Product2 validProd = new Product2( Name ='HR Solutions - ASO (Non Payroll Client)'
                ,Default_Units_to_Employees__c=true,Unit_Type__c='Employees'
                ,Is_Non_Payroll_Unit__c=true
                ,Sales_Org__c='PAS'
                ,Pricing_Type__c='Monthly'
                ,IsActive=true
                ,ProductCode='ASO'
                );
                Product2 validProd2 = new Product2(Name ='HR Solutions (ASO)' 
                ,Default_Units_to_Employees__c=true
                ,IsActive=true
                ,Pricing_Type__c='Per Pay Period'
                ,Family='HR - HR Solutions'
                ,ProductCode='PNG ADMIN'
                );
                List<Product2> prodsInRest = [Select id,Name from Product2 where Name Like '%HR Solutions%' limit 1000];
                System.debug('PRODS IN REST'+prodsInRest);
                Product2[] prods = new Product2[]{validProd,validProd2};
                insert prods;
                System.debug('newly inserted prods: '+ prods);
                validProd = [Select Id,Name from Product2 where Name LIKE '%HR Solutions - ASO (Non Payroll Client)' limit 1];
                validProd2 = [Select Id,Name from Product2 where Name LIKE '%HR Solutions (ASO)%' limit 1];
                //Pricebook2 spricebook =  [select Id from Pricebook2 where isStandard=true];
                Id spricebookId =  Test.getStandardPricebookId();
                System.debug(spricebookId);
                List<PricebookEntry> standardPricebookProducts = [Select Id,Pricebook2Id,Product2Id,UnitPrice from PricebookEntry where Pricebook2Id =:spricebookId];
                System.debug('all the products in our standard pricebook in our test: '+standardPricebookProducts);
                Product2 productInPricebook = [Select Id,Name from Product2 where Id =:standardPricebookProducts[0].Product2Id];
                System.debug('name of product in pricebook: '+productInPricebook.Name);


                //PricebookEntry spbe1 = new PricebookEntry(Pricebook2Id = spricebookId, Product2Id = validProd.Id, UnitPrice=5.00, isActive=true,UseStandardPrice=false);
                PricebookEntry spbe2 = new PricebookEntry(Pricebook2Id = spricebookId, Product2Id = validProd2.Id, UnitPrice=7.00, isActive=true,UseStandardPrice=false);
                PricebookEntry[] spbes = new PricebookEntry[]{spbe2};
                insert spbes;
                
                Pricebook2 flexPB = new Pricebook2(Name='FLEX', IsActive=true);
                insert flexPB;
                
                flexPB= [Select Id, Name, IsActive from Pricebook2 where Name='FLEX'];

                PricebookEntry pbe1 = new PricebookEntry(Pricebook2Id = flexPB.Id, Product2Id = validProd.Id, UnitPrice=5.00, isActive=true,UseStandardPrice=false);
                PricebookEntry pbe2 = new PricebookEntry(Pricebook2Id = flexPB.Id, Product2Id = validProd2.Id, UnitPrice=7.00, isActive=true,UseStandardPrice=false);  
                PricebookEntry[] pbes = new PricebookEntry[]{pbe1,pbe2};
                insert pbes;
                */
                Pricebook2 flexPB = getFlexPb();
                Product2 validProd = getValidProd1();
                Product2 validProd2 = getValidProd2();

                testOpp.Pricebook2Id = flexPB.Id;
                update testOpp;
                OpportunityLineItem oli1 = new OpportunityLineItem(Product2Id= validProd.Id , OpportunityId = testOpp.Id,Quantity=1,TotalPrice=5);
                OpportunityLineItem oli2 = new OpportunityLineItem(Product2Id= validProd2.Id , OpportunityId = testOpp.Id,Quantity=1,TotalPrice=7);
                OpportunityLineItem[] olis = new OpportunityLineItem[]{oli1,oli2};
                insert olis;
                System.assertEquals(oli1.OpportunityId,testOpp.Id,'Not the same opportunity on the opp line item ');
                System.assertEquals(oli2.OpportunityId,testOpp.Id,'Not the same opportunity on the opp line item ');


                testOpp.Probability = 100;
                testOpp.StageName = 'Sold';
                testOpp.Assign_HRG__c = true;
                System.assert(testOpp.Probability>=90,'Probability is not greater than or equal to 90');
                List<Opportunity> oppList = new List<Opportunity>{testOpp};
                Map<Id,Opportunity> oppMap = new Map<Id, Opportunity>(oppList);
                Set<Id> acctIds = new Set<Id>{testOpp.AccountId};
                Test.startTest();
                update testOpp;
                HRGAutoAssignmentQueueable tempQueueable = new HRGAutoAssignmentQueueable(oppMap,acctIds);
                System.enqueueJob(tempQueueable);
                Test.stopTest();
                HRG_Assignment__c createdHAO = [Select Id,Opportunity__c,SelectedHRP__c,Status__c from HRG_Assignment__c where Opportunity__c = :testOpp.Id limit 1];
                System.assertNotEquals(createdHAO,null,'did not create HRG Assignment Object');
                System.debug('Created HAO'+createdHAO);
                //System.assertEquals(createdHAO.SelectedHRP__c,null,'Selected HRG was assigned and should not have been');
                //System.assertEquals(createdHAO.Status__c,'Waiting For Approval','Status was not Waiting For Approval');
                Account updatedAcct = [Select Id,Name,HR_Generalist__c from Account where Id = :testAcct.Id];
                System.assertEquals(updatedAcct.HR_Generalist__c,null,'Selected HRG populated Account');
            }
            static testMethod void testOverride(){
                User runUser = UserHelper.getRunningUser();
                //Contact ManagerContact = new Contact(FirstName = Manager.Name,LastName='Test', User_Lookup__c = Manager.Id,AccountId=fillerAcct.Id,RecordTypeId=rtCtct.getRecordTypeId(),HR_Person_Id__c = Manager.HR_Person_Id__c);


                Account testAcct = getTestAcct();
                System.assertEquals(testAcct.HR_Generalist__c,null,'Account should not have an HRG on Account');
                Contact me = new Contact(FirstName = runUser.Name, LastName = 'test',User_Lookup__c = runUser.Id,AccountId = testAcct.Id,HR_Person_Id__c = runUser.HR_Person_Id__c);
                insert me;
                Contact myManager = new Contact(FirstName ='My',LastName='Manager',User_Lookup__c = runUser.ManagerId,AccountId=testAcct.Id);
                insert myManager;
                Opportunity testOpp = new Opportunity(Name='Test Opp 1',Probability = 10
                ,StageName = 'Qualified',Employees_Paid_Per_Payroll__c=75
                ,AccountId = testAcct.Id,CloseDate=Date.today());
                insert testOpp;
                /*
                // add products to Opp
                Product2 validProd = new Product2( Name ='HR Solutions - ASO (Non Payroll Client)'
                ,Default_Units_to_Employees__c=true,Unit_Type__c='Employees'
                ,Is_Non_Payroll_Unit__c=true
                ,Sales_Org__c='PAS'
                ,Pricing_Type__c='Monthly'
                ,IsActive=true
                ,ProductCode='ASO'
                );
                Product2 validProd2 = new Product2(Name ='HR Solutions (ASO)' 
                ,Default_Units_to_Employees__c=true
                ,IsActive=true
                ,Pricing_Type__c='Per Pay Period'
                ,Family='HR - HR Solutions'
                ,ProductCode='PNG ADMIN'
                );
                List<Product2> prodsInRest = [Select id,Name from Product2 where Name Like '%HR Solutions%' limit 1000];
                System.debug('PRODS IN REST'+prodsInRest);
                Product2[] prods = new Product2[]{validProd,validProd2};
                insert prods;
                System.debug('newly inserted prods: '+ prods);
                validProd = [Select Id,Name from Product2 where Name LIKE '%HR Solutions - ASO (Non Payroll Client)' limit 1];
                validProd2 = [Select Id,Name from Product2 where Name LIKE '%HR Solutions (ASO)%' limit 1];
                //Pricebook2 spricebook =  [select Id from Pricebook2 where isStandard=true];
                Id spricebookId =  Test.getStandardPricebookId();
                System.debug(spricebookId);
                List<PricebookEntry> standardPricebookProducts = [Select Id,Pricebook2Id,Product2Id,UnitPrice from PricebookEntry where Pricebook2Id =:spricebookId];
                System.debug('all the products in our standard pricebook in our test: '+standardPricebookProducts);
                Product2 productInPricebook = [Select Id,Name from Product2 where Id =:standardPricebookProducts[0].Product2Id];
                System.debug('name of product in pricebook: '+productInPricebook.Name);


                //PricebookEntry spbe1 = new PricebookEntry(Pricebook2Id = spricebookId, Product2Id = validProd.Id, UnitPrice=5.00, isActive=true,UseStandardPrice=false);
                PricebookEntry spbe2 = new PricebookEntry(Pricebook2Id = spricebookId, Product2Id = validProd2.Id, UnitPrice=7.00, isActive=true,UseStandardPrice=false);
                PricebookEntry[] spbes = new PricebookEntry[]{spbe2};
                insert spbes;
                
                Pricebook2 flexPB = new Pricebook2(Name='FLEX', IsActive=true);
                insert flexPB;
                
                flexPB= [Select Id, Name, IsActive from Pricebook2 where Name='FLEX'];

                PricebookEntry pbe1 = new PricebookEntry(Pricebook2Id = flexPB.Id, Product2Id = validProd.Id, UnitPrice=5.00, isActive=true,UseStandardPrice=false);
                PricebookEntry pbe2 = new PricebookEntry(Pricebook2Id = flexPB.Id, Product2Id = validProd2.Id, UnitPrice=7.00, isActive=true,UseStandardPrice=false);  
                PricebookEntry[] pbes = new PricebookEntry[]{pbe1,pbe2};
                insert pbes;
                */
                Pricebook2 flexPB = getFlexPb();
                Product2 validProd = getValidProd1();
                Product2 validProd2 = getValidProd2();

                testOpp.Pricebook2Id = flexPB.Id;
                update testOpp;
                OpportunityLineItem oli1 = new OpportunityLineItem(Product2Id= validProd.Id , OpportunityId = testOpp.Id,Quantity=1,TotalPrice=5);
                OpportunityLineItem oli2 = new OpportunityLineItem(Product2Id= validProd2.Id , OpportunityId = testOpp.Id,Quantity=1,TotalPrice=7);
                OpportunityLineItem[] olis = new OpportunityLineItem[]{oli1,oli2};
                insert olis;
                System.assertEquals(oli1.OpportunityId,testOpp.Id,'Not the same opportunity on the opp line item ');
                System.assertEquals(oli2.OpportunityId,testOpp.Id,'Not the same opportunity on the opp line item ');


                testOpp.Probability = 90;
                testOpp.StageName = 'Sold';
                testOpp.Assign_HRG__c = true;
                System.assert(testOpp.Probability>=90,'Probability is not greater than or equal to 90');
                List<Opportunity> oppList = new List<Opportunity>{testOpp};
                Map<Id,Opportunity> oppMap = new Map<Id, Opportunity>(oppList);
                Set<Id> acctIds = new Set<Id>{testOpp.AccountId};
                Test.startTest();
                update testOpp;
                HRGAutoAssignmentQueueable tempQueueable = new HRGAutoAssignmentQueueable(oppMap,acctIds);
                System.enqueueJob(tempQueueable);
                Test.stopTest();
                HRG_Assignment__c createdHAO = [Select Id,Opportunity__c,SelectedHRP__c,Status__c from HRG_Assignment__c where Opportunity__c = :testOpp.Id limit 1];
                System.assertNotEquals(createdHAO,null,'did not create HRG Assignment Object');
                System.debug('Created HAO'+createdHAO);
                //System.assertEquals(createdHAO.SelectedHRP__c,null,'Selected HRG was assigned and should not have been');
                System.assertEquals(createdHAO.Status__c,'Waiting For Approval','Status was not Waiting For Approval');
                Account updatedAcct = [Select Id,Name,HR_Generalist__c from Account where Id = :testAcct.Id];
                System.assertEquals(updatedAcct.HR_Generalist__c,null,'Selected HRG populated Account');
                Contact runCtct = [Select Id,Name, User_Lookup__c from Contact where User_Lookup__c = :runUser.Id limit 1];
                Contact runManCtct = [select Id,Name, User_Lookup__c from Contact where User_Lookup__c = :runUser.ManagerId limit 1];
                HRG_Assignment__c updatedHAO = new HRG_Assignment__c(Id = createdHAO.Id, Status__c = 'Manager Override',Override_HRG_User__c=runCtct.Id,Override_Reason__c='Productivity concerns');
                update updatedHAO;
        

            }
            static testMethod void testOverride2(){
                User runUser = UserHelper.getRunningUser();
                //Contact ManagerContact = new Contact(FirstName = Manager.Name,LastName='Test', User_Lookup__c = Manager.Id,AccountId=fillerAcct.Id,RecordTypeId=rtCtct.getRecordTypeId(),HR_Person_Id__c = Manager.HR_Person_Id__c);


                Account testAcct = getTestAcct();
                System.assertEquals(testAcct.HR_Generalist__c,null,'Account should not have an HRG on Account');
                Contact me = new Contact(FirstName = runUser.Name, LastName = 'test',User_Lookup__c = runUser.Id,AccountId = testAcct.Id,HR_Person_Id__c = runUser.HR_Person_Id__c);
                insert me;
                Contact myManager = new Contact(FirstName ='My',LastName='Manager',User_Lookup__c = runUser.ManagerId,AccountId=testAcct.Id);
                insert myManager;
                Opportunity testOpp = new Opportunity(Name='Test Opp 1',Probability = 10
                ,StageName = 'Qualified',Employees_Paid_Per_Payroll__c=75
                ,AccountId = testAcct.Id,CloseDate=Date.today());
                insert testOpp;
                /*
                // add products to Opp
                Product2 validProd = new Product2( Name ='HR Solutions - ASO (Non Payroll Client)'
                ,Default_Units_to_Employees__c=true,Unit_Type__c='Employees'
                ,Is_Non_Payroll_Unit__c=true
                ,Sales_Org__c='PAS'
                ,Pricing_Type__c='Monthly'
                ,IsActive=true
                ,ProductCode='ASO'
                );
                Product2 validProd2 = new Product2(Name ='HR Solutions (ASO)' 
                ,Default_Units_to_Employees__c=true
                ,IsActive=true
                ,Pricing_Type__c='Per Pay Period'
                ,Family='HR - HR Solutions'
                ,ProductCode='PNG ADMIN'
                );
                List<Product2> prodsInRest = [Select id,Name from Product2 where Name Like '%HR Solutions%' limit 1000];
                System.debug('PRODS IN REST'+prodsInRest);
                Product2[] prods = new Product2[]{validProd,validProd2};
                insert prods;
                System.debug('newly inserted prods: '+ prods);
                validProd = [Select Id,Name from Product2 where Name LIKE '%HR Solutions - ASO (Non Payroll Client)' limit 1];
                validProd2 = [Select Id,Name from Product2 where Name LIKE '%HR Solutions (ASO)%' limit 1];
                //Pricebook2 spricebook =  [select Id from Pricebook2 where isStandard=true];
                Id spricebookId =  Test.getStandardPricebookId();
                System.debug(spricebookId);
                List<PricebookEntry> standardPricebookProducts = [Select Id,Pricebook2Id,Product2Id,UnitPrice from PricebookEntry where Pricebook2Id =:spricebookId];
                System.debug('all the products in our standard pricebook in our test: '+standardPricebookProducts);
                Product2 productInPricebook = [Select Id,Name from Product2 where Id =:standardPricebookProducts[0].Product2Id];
                System.debug('name of product in pricebook: '+productInPricebook.Name);


                //PricebookEntry spbe1 = new PricebookEntry(Pricebook2Id = spricebookId, Product2Id = validProd.Id, UnitPrice=5.00, isActive=true,UseStandardPrice=false);
                PricebookEntry spbe2 = new PricebookEntry(Pricebook2Id = spricebookId, Product2Id = validProd2.Id, UnitPrice=7.00, isActive=true,UseStandardPrice=false);
                PricebookEntry[] spbes = new PricebookEntry[]{spbe2};
                insert spbes;
                
                Pricebook2 flexPB = new Pricebook2(Name='FLEX', IsActive=true);
                insert flexPB;
                
                flexPB= [Select Id, Name, IsActive from Pricebook2 where Name='FLEX'];

                PricebookEntry pbe1 = new PricebookEntry(Pricebook2Id = flexPB.Id, Product2Id = validProd.Id, UnitPrice=5.00, isActive=true,UseStandardPrice=false);
                PricebookEntry pbe2 = new PricebookEntry(Pricebook2Id = flexPB.Id, Product2Id = validProd2.Id, UnitPrice=7.00, isActive=true,UseStandardPrice=false);  
                PricebookEntry[] pbes = new PricebookEntry[]{pbe1,pbe2};
                insert pbes;
                */
                Pricebook2 flexPB = getFlexPb();
                Product2 validProd = getValidProd1();
                Product2 validProd2 = getValidProd2();

                testOpp.Pricebook2Id = flexPB.Id;
                update testOpp;
                OpportunityLineItem oli1 = new OpportunityLineItem(Product2Id= validProd.Id , OpportunityId = testOpp.Id,Quantity=1,TotalPrice=5);
                OpportunityLineItem oli2 = new OpportunityLineItem(Product2Id= validProd2.Id , OpportunityId = testOpp.Id,Quantity=1,TotalPrice=7);
                OpportunityLineItem[] olis = new OpportunityLineItem[]{oli1,oli2};
                insert olis;
                System.assertEquals(oli1.OpportunityId,testOpp.Id,'Not the same opportunity on the opp line item ');
                System.assertEquals(oli2.OpportunityId,testOpp.Id,'Not the same opportunity on the opp line item ');


                testOpp.Probability = 100;
                testOpp.StageName = 'Sold';
                testOpp.Assign_HRG__c = true;
                System.assert(testOpp.Probability>=90,'Probability is not greater than or equal to 90');
                List<Opportunity> oppList = new List<Opportunity>{testOpp};
                Map<Id,Opportunity> oppMap = new Map<Id, Opportunity>(oppList);
                Set<Id> acctIds = new Set<Id>{testOpp.AccountId};
                Test.startTest();
                update testOpp;
                HRGAutoAssignmentQueueable tempQueueable = new HRGAutoAssignmentQueueable(oppMap,acctIds);
                System.enqueueJob(tempQueueable);
                Test.stopTest();
                HRG_Assignment__c createdHAO = [Select Id,Opportunity__c,SelectedHRP__c,Status__c from HRG_Assignment__c where Opportunity__c = :testOpp.Id limit 1];
                System.assertNotEquals(createdHAO,null,'did not create HRG Assignment Object');
                System.debug('Created HAO'+createdHAO);
                //System.assertEquals(createdHAO.SelectedHRP__c,null,'Selected HRG was assigned and should not have been');
                System.assertEquals(createdHAO.Status__c,'Waiting For Approval','Status was not Waiting For Approval');
                Account updatedAcct = [Select Id,Name,HR_Generalist__c from Account where Id = :testAcct.Id];
                System.assertEquals(updatedAcct.HR_Generalist__c,null,'Selected HRG populated Account');
                Contact runCtct = [Select Id,Name, User_Lookup__c from Contact where User_Lookup__c = :runUser.Id limit 1];
                Contact runManCtct = [select Id,Name, User_Lookup__c from Contact where User_Lookup__c = :runUser.ManagerId limit 1];
                HRG_Assignment__c updatedHAO = new HRG_Assignment__c(Id = createdHAO.Id, Status__c = 'Manager Override',Override_HRG_User__c=runCtct.Id,Override_Reason__c='Productivity concerns');
                update updatedHAO;
        

            }

            static testMethod void testOpportunityUpdates() {
                Account testAcct = getTestAcct();
                System.assertEquals(testAcct.HR_Generalist__c,null,'Account should not have an HRG on Account');

                Opportunity testOpp = new Opportunity(Name='Test Opp 1',Probability = 90
                ,StageName = 'Qualified',Employees_Paid_Per_Payroll__c=75
                ,AccountId = testAcct.Id,CloseDate=Date.today());
                upsert testOpp;
                /*
                // add products to Opp
                Product2 validProd = new Product2( Name ='HR Solutions - ASO (Non Payroll Client)'
                ,Default_Units_to_Employees__c=true,Unit_Type__c='Employees'
                ,Is_Non_Payroll_Unit__c=true
                ,Sales_Org__c='PAS'
                ,Pricing_Type__c='Monthly'
                ,IsActive=true
                ,ProductCode='ASO'
                );
                Product2 validProd2 = new Product2(Name ='HR Solutions (ASO)' 
                ,Default_Units_to_Employees__c=true
                ,IsActive=true
                ,Pricing_Type__c='Per Pay Period'
                ,Family='HR - HR Solutions'
                ,ProductCode='PNG ADMIN'
                );
                List<Product2> prodsInRest = [Select id,Name from Product2 where Name Like '%HR Solutions%' limit 1000];
                System.debug('PRODS IN REST'+prodsInRest);
                Product2[] prods = new Product2[]{validProd,validProd2};
                insert prods;
                System.debug('newly inserted prods: '+ prods);
                validProd = [Select Id,Name from Product2 where Name LIKE '%HR Solutions - ASO (Non Payroll Client)' limit 1];
                validProd2 = [Select Id,Name from Product2 where Name LIKE '%HR Solutions (ASO)%' limit 1];
                //Pricebook2 spricebook =  [select Id from Pricebook2 where isStandard=true];
                Id spricebookId =  Test.getStandardPricebookId();
                System.debug(spricebookId);
                List<PricebookEntry> standardPricebookProducts = [Select Id,Pricebook2Id,Product2Id,UnitPrice from PricebookEntry where Pricebook2Id =:spricebookId];
                System.debug('all the products in our standard pricebook in our test: '+standardPricebookProducts);
                Product2 productInPricebook = [Select Id,Name from Product2 where Id =:standardPricebookProducts[0].Product2Id];
                System.debug('name of product in pricebook: '+productInPricebook.Name);


                //PricebookEntry spbe1 = new PricebookEntry(Pricebook2Id = spricebookId, Product2Id = validProd.Id, UnitPrice=5.00, isActive=true,UseStandardPrice=false);
                PricebookEntry spbe2 = new PricebookEntry(Pricebook2Id = spricebookId, Product2Id = validProd2.Id, UnitPrice=7.00, isActive=true,UseStandardPrice=false);
                PricebookEntry[] spbes = new PricebookEntry[]{spbe2};
                insert spbes;
                
                Pricebook2 flexPB = new Pricebook2(Name='FLEX', IsActive=true);
                insert flexPB;
                
                flexPB= [Select Id, Name, IsActive from Pricebook2 where Name='FLEX'];

                PricebookEntry pbe1 = new PricebookEntry(Pricebook2Id = flexPB.Id, Product2Id = validProd.Id, UnitPrice=5.00, isActive=true,UseStandardPrice=false);
                PricebookEntry pbe2 = new PricebookEntry(Pricebook2Id = flexPB.Id, Product2Id = validProd2.Id, UnitPrice=7.00, isActive=true,UseStandardPrice=false);  
                PricebookEntry[] pbes = new PricebookEntry[]{pbe1,pbe2};
                insert pbes;
                */
                Pricebook2 flexPB = getFlexPb();
                Product2 validProd = getValidProd1();
                Product2 validProd2 = getValidProd2();

                testOpp.Pricebook2Id = flexPB.Id;
                update testOpp;
                OpportunityLineItem oli1 = new OpportunityLineItem(Product2Id= validProd.Id , OpportunityId = testOpp.Id,Quantity=1,TotalPrice=5);
                OpportunityLineItem oli2 = new OpportunityLineItem(Product2Id= validProd2.Id , OpportunityId = testOpp.Id,Quantity=1,TotalPrice=7);
                OpportunityLineItem[] olis = new OpportunityLineItem[]{oli1,oli2};
                insert olis;
                System.assertEquals(oli1.OpportunityId,testOpp.Id,'Not the same opportunity on the opp line item ');
                System.assertEquals(oli2.OpportunityId,testOpp.Id,'Not the same opportunity on the opp line item ');
               
                List<Opportunity> oppList = new List<Opportunity>{testOpp};
                Map<Id,Opportunity> oppMap = new Map<Id, Opportunity>(oppList);
                Set<Id> acctIds = new Set<Id>{testOpp.AccountId};
                Test.startTest();
                testOpp.Probability = 90;
                testOpp.StageName = 'Sold';
                testOpp.Assign_HRG__c = true;
                System.assert(testOpp.Probability>=90,'Probability is not greater than or equal to 90');
                update testOpp;
                Test.stopTest();

            } // testOpportunityUpdates
            static testMethod void testOpportunityUpdates2() {
                Account testAcct = getTestAcct();
                System.assertEquals(testAcct.HR_Generalist__c,null,'Account should not have an HRG on Account');

                Opportunity testOpp = new Opportunity(Name='Test Opp 1',Probability = 100
                ,StageName = 'Qualified',Employees_Paid_Per_Payroll__c=75
                ,AccountId = testAcct.Id,CloseDate=Date.today());
                upsert testOpp;
                /*
                // add products to Opp
                Product2 validProd = new Product2( Name ='HR Solutions - ASO (Non Payroll Client)'
                ,Default_Units_to_Employees__c=true,Unit_Type__c='Employees'
                ,Is_Non_Payroll_Unit__c=true
                ,Sales_Org__c='PAS'
                ,Pricing_Type__c='Monthly'
                ,IsActive=true
                ,ProductCode='ASO'
                );
                Product2 validProd2 = new Product2(Name ='HR Solutions (ASO)' 
                ,Default_Units_to_Employees__c=true
                ,IsActive=true
                ,Pricing_Type__c='Per Pay Period'
                ,Family='HR - HR Solutions'
                ,ProductCode='PNG ADMIN'
                );
                List<Product2> prodsInRest = [Select id,Name from Product2 where Name Like '%HR Solutions%' limit 1000];
                System.debug('PRODS IN REST'+prodsInRest);
                Product2[] prods = new Product2[]{validProd,validProd2};
                insert prods;
                System.debug('newly inserted prods: '+ prods);
                validProd = [Select Id,Name from Product2 where Name LIKE '%HR Solutions - ASO (Non Payroll Client)' limit 1];
                validProd2 = [Select Id,Name from Product2 where Name LIKE '%HR Solutions (ASO)%' limit 1];
                //Pricebook2 spricebook =  [select Id from Pricebook2 where isStandard=true];
                Id spricebookId =  Test.getStandardPricebookId();
                System.debug(spricebookId);
                List<PricebookEntry> standardPricebookProducts = [Select Id,Pricebook2Id,Product2Id,UnitPrice from PricebookEntry where Pricebook2Id =:spricebookId];
                System.debug('all the products in our standard pricebook in our test: '+standardPricebookProducts);
                Product2 productInPricebook = [Select Id,Name from Product2 where Id =:standardPricebookProducts[0].Product2Id];
                System.debug('name of product in pricebook: '+productInPricebook.Name);


                //PricebookEntry spbe1 = new PricebookEntry(Pricebook2Id = spricebookId, Product2Id = validProd.Id, UnitPrice=5.00, isActive=true,UseStandardPrice=false);
                PricebookEntry spbe2 = new PricebookEntry(Pricebook2Id = spricebookId, Product2Id = validProd2.Id, UnitPrice=7.00, isActive=true,UseStandardPrice=false);
                PricebookEntry[] spbes = new PricebookEntry[]{spbe2};
                insert spbes;
                
                Pricebook2 flexPB = new Pricebook2(Name='FLEX', IsActive=true);
                insert flexPB;
                
                flexPB= [Select Id, Name, IsActive from Pricebook2 where Name='FLEX'];

                PricebookEntry pbe1 = new PricebookEntry(Pricebook2Id = flexPB.Id, Product2Id = validProd.Id, UnitPrice=5.00, isActive=true,UseStandardPrice=false);
                PricebookEntry pbe2 = new PricebookEntry(Pricebook2Id = flexPB.Id, Product2Id = validProd2.Id, UnitPrice=7.00, isActive=true,UseStandardPrice=false);  
                PricebookEntry[] pbes = new PricebookEntry[]{pbe1,pbe2};
                insert pbes;
                */
                Pricebook2 flexPB = getFlexPb();
                Product2 validProd = getValidProd1();
                Product2 validProd2 = getValidProd2();

                testOpp.Pricebook2Id = flexPB.Id;
                update testOpp;
                OpportunityLineItem oli1 = new OpportunityLineItem(Product2Id= validProd.Id , OpportunityId = testOpp.Id,Quantity=1,TotalPrice=5);
                OpportunityLineItem oli2 = new OpportunityLineItem(Product2Id= validProd2.Id , OpportunityId = testOpp.Id,Quantity=1,TotalPrice=7);
                OpportunityLineItem[] olis = new OpportunityLineItem[]{oli1,oli2};
                insert olis;
                System.assertEquals(oli1.OpportunityId,testOpp.Id,'Not the same opportunity on the opp line item ');
                System.assertEquals(oli2.OpportunityId,testOpp.Id,'Not the same opportunity on the opp line item ');
               
                List<Opportunity> oppList = new List<Opportunity>{testOpp};
                Map<Id,Opportunity> oppMap = new Map<Id, Opportunity>(oppList);
                Set<Id> acctIds = new Set<Id>{testOpp.AccountId};
                Test.startTest();
                testOpp.Probability = 100;
                testOpp.StageName = 'Sold';
                testOpp.Assign_HRG__c = true;
                System.assert(testOpp.Probability>=90,'Probability is not greater than or equal to 90');
                update testOpp;
                Test.stopTest();

            } // testOpportunityUpdates2
            //Multi-Id Testing
            static testMethod void testOpportunityUpdates3() {
                Account testAcct = getTestAcct();
                System.assertEquals(testAcct.HR_Generalist__c,null,'Account should not have an HRG on Account');

                Opportunity testOpp = new Opportunity(Name='Test Opp 1',Probability = 100
                ,StageName = 'Qualified',Employees_Paid_Per_Payroll__c=75
                ,AccountId = testAcct.Id,CloseDate=Date.today());
                upsert testOpp;
                Opportunity testOpp2 = new Opportunity(Name='Test Opp 2',Probability = 100
                ,StageName = 'Qualified',Employees_Paid_Per_Payroll__c=75
                ,AccountId = testAcct.Id,CloseDate=Date.today(), Primary_Opportunity__c = testOpp.Id);
                upsert testOpp2;
                /*
                // add products to Opp
                Product2 validProd = new Product2( Name ='HR Solutions - ASO (Non Payroll Client)'
                ,Default_Units_to_Employees__c=true,Unit_Type__c='Employees'
                ,Is_Non_Payroll_Unit__c=true
                ,Sales_Org__c='PAS'
                ,Pricing_Type__c='Monthly'
                ,IsActive=true
                ,ProductCode='ASO'
                );
                Product2 validProd2 = new Product2(Name ='HR Solutions (ASO)' 
                ,Default_Units_to_Employees__c=true
                ,IsActive=true
                ,Pricing_Type__c='Per Pay Period'
                ,Family='HR - HR Solutions'
                ,ProductCode='PNG ADMIN'
                );
                List<Product2> prodsInRest = [Select id,Name from Product2 where Name Like '%HR Solutions%' limit 1000];
                System.debug('PRODS IN REST'+prodsInRest);
                Product2[] prods = new Product2[]{validProd,validProd2};
                insert prods;
                System.debug('newly inserted prods: '+ prods);
                validProd = [Select Id,Name from Product2 where Name LIKE '%HR Solutions - ASO (Non Payroll Client)' limit 1];
                validProd2 = [Select Id,Name from Product2 where Name LIKE '%HR Solutions (ASO)%' limit 1];
                //Pricebook2 spricebook =  [select Id from Pricebook2 where isStandard=true];
                Id spricebookId =  Test.getStandardPricebookId();
                System.debug(spricebookId);
                List<PricebookEntry> standardPricebookProducts = [Select Id,Pricebook2Id,Product2Id,UnitPrice from PricebookEntry where Pricebook2Id =:spricebookId];
                System.debug('all the products in our standard pricebook in our test: '+standardPricebookProducts);
                Product2 productInPricebook = [Select Id,Name from Product2 where Id =:standardPricebookProducts[0].Product2Id];
                System.debug('name of product in pricebook: '+productInPricebook.Name);


                //PricebookEntry spbe1 = new PricebookEntry(Pricebook2Id = spricebookId, Product2Id = validProd.Id, UnitPrice=5.00, isActive=true,UseStandardPrice=false);
                PricebookEntry spbe2 = new PricebookEntry(Pricebook2Id = spricebookId, Product2Id = validProd2.Id, UnitPrice=7.00, isActive=true,UseStandardPrice=false);
                PricebookEntry[] spbes = new PricebookEntry[]{spbe2};
                insert spbes;
                
                Pricebook2 flexPB = new Pricebook2(Name='FLEX', IsActive=true);
                insert flexPB;
                
                flexPB= [Select Id, Name, IsActive from Pricebook2 where Name='FLEX'];

                PricebookEntry pbe1 = new PricebookEntry(Pricebook2Id = flexPB.Id, Product2Id = validProd.Id, UnitPrice=5.00, isActive=true,UseStandardPrice=false);
                PricebookEntry pbe2 = new PricebookEntry(Pricebook2Id = flexPB.Id, Product2Id = validProd2.Id, UnitPrice=7.00, isActive=true,UseStandardPrice=false);  
                PricebookEntry[] pbes = new PricebookEntry[]{pbe1,pbe2};
                insert pbes;
                */
                Pricebook2 flexPB = getFlexPb();
                Product2 validProd = getValidProd1();
                Product2 validProd2 = getValidProd2();

                testOpp.Pricebook2Id = flexPB.Id;
                testOpp2.Pricebook2Id = flexPb.Id;
                update testOpp2;
                update testOpp;
                OpportunityLineItem oli1 = new OpportunityLineItem(Product2Id= validProd.Id , OpportunityId = testOpp.Id,Quantity=1,TotalPrice=5);
                OpportunityLineItem oli2 = new OpportunityLineItem(Product2Id= validProd2.Id , OpportunityId = testOpp.Id,Quantity=1,TotalPrice=7);
                OpportunityLineItem oli3 = new OpportunityLineItem(Product2Id= validProd.Id , OpportunityId = testOpp2.Id,Quantity=1,TotalPrice=5);
                OpportunityLineItem oli4 = new OpportunityLineItem(Product2Id= validProd2.Id , OpportunityId = testOpp2.Id,Quantity=1,TotalPrice=7);
                
                OpportunityLineItem[] olis = new OpportunityLineItem[]{oli1,oli2,oli3,oli4};
                insert olis;
                System.assertEquals(oli1.OpportunityId,testOpp.Id,'Not the same opportunity on the opp line item ');
                System.assertEquals(oli2.OpportunityId,testOpp.Id,'Not the same opportunity on the opp line item ');
                System.assertEquals(oli3.OpportunityId,testOpp2.Id,'Not the same opportunity on the opp line item ');
                System.assertEquals(oli4.OpportunityId,testOpp2.Id,'Not the same opportunity on the opp line item ');
               
                List<Opportunity> oppList = new List<Opportunity>{testOpp};
                Map<Id,Opportunity> oppMap = new Map<Id, Opportunity>(oppList);
                Set<Id> acctIds = new Set<Id>{testOpp.AccountId};
                Test.startTest();
                testOpp.Probability = 100;
                testOpp.StageName = 'Sold';
                testOpp.Assign_HRG__c = true;
                testOpp2.Probability = 90;
                testOpp2.StageName = 'Sold - Submitted';
                testOpp2.OppSource__c ='Opportunity Split';
                System.assert(testOpp2.Probability>=90,'Probability is not greater than or equal to 90');
                update testOpp2;
                System.assert(testOpp.Probability>=90,'Probability is not greater than or equal to 90');
                update testOpp;
                Test.stopTest();

            } // testOpportunityUpdates3
    
           static testMethod void oppStuffAgain(){
            Opportunity testOpp = new Opportunity(Name='Test Opp 1',Probability = 90
                ,StageName = 'Qualified',Employees_Paid_Per_Payroll__c=75
                ,CloseDate=Date.today());
                List<Opportunity> oppList = new List<Opportunity>{testOpp};
                Test.startTest();
                insert oppList;
                Test.stopTest();
           }
    }