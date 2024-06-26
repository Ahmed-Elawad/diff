/* 
 * Test Methods for the MassEditTasksController class.
 *
 * History
 * -------
 * 10/14/2015 Justin Stouffer   Created
 *
 */
@isTest
private class MassEditTasksControllerTest {

   static testMethod void testBasic() {
        list<task> tskList = MassEditTasksControllerTest.createTestTasks();
        list<event> evtList = MassEditTasksControllerTest.createTestEvent(); 
        insert tskList;
        insert evtList;
        string tskIDs = '';
        string evtIDs = '';

        for(task t: tskList){
            tskIDs += t.id + ',';
        }
        for(Event e: evtList){
            evtIDs += e.id + ',';
        }
       //tskIDs = tskIDs.removeEnd(',');
        evtIDs = evtIDs.removeEnd(','); 
        PageReference pageRef = new PageReference('/apex/MassEditTasksPage?Id=' + tskIDs +evtIDS); 
        test.setCurrentPage(pageRef);
        MassEditTasksController controller = new MassEditTasksController();
        
        system.assert(controller.numberOfSelected == 5);
        system.assertEquals(2,controller.numberOfEventsSelected); 
        system.assertEquals('Call',controller.listOfTasks[0].type);
        PageReference nextPage = controller.cancel();
        
   } // testBasic
   
   
   static testMethod void testUpdate() {
        list<task> tskList = MassEditTasksControllerTest.createTestTasks();
        insert tskList;
        string tskIDs = '';
        for(task t: tskList){
            tskIDs += t.id + ',';
        }
 
        tskIDs = tskIDs.removeEnd(',');
        PageReference pageRef = new PageReference('/apex/MassEditTasksPage?Id=' + tskIDs);
        test.setCurrentPage(pageRef);
        MassEditTasksController controller = new MassEditTasksController();
        controller.emptyTask.type = 'Email';
        controller.setTaskValues();
        system.assertEquals('Email',controller.listOfTasks[0].type);
        task t1 =[select id, type from Task where id = :controller.listOfTasks[0].id];
        system.assertEquals('Call',t1.type);
        controller.commitChanges();
        task t2 =[select id, type from Task where id = :controller.listOfTasks[0].id];
        system.assertEquals('Email',t2.type);
        
   } // testUpdate
   
  static testMethod void testFinal() {
        list<task> tskList = MassEditTasksControllerTest.createTestTasks();
        insert tskList;
        string tskIDs = '';
        for(task t: tskList){
            tskIDs += t.id + ',';
        }
        tskIDs = tskIDs.removeEnd(',');
        PageReference pageRef = new PageReference('/apex/MassEditTasksPage?Id=' + tskIDs);
        test.setCurrentPage(pageRef);
        MassEditTasksController controller = new MassEditTasksController();
        controller.emptyTask.description = 'This is my new description.';
        controller.appendComment = FALSE;
        controller.setTaskValues();
        system.assertEquals('This is my new description.',controller.listOfTasks[0].description);
        controller.emptyTask.description = 'I am appending this.';
        controller.appendComment = TRUE;
        controller.setTaskValues();
        system.assertEquals('This is my new description.\nI am appending this.',controller.listOfTasks[0].description);        
        task t1 =[select id, description from Task where id = :controller.listOfTasks[0].id];
        system.assertEquals('This is my initial description',t1.description);
        pageReference nextPage = controller.commitChangesAndReturn();
        task t2 =[select id, description from Task where id = :controller.listOfTasks[0].id];
        system.assertEquals('This is my new description.\nI am appending this.',t2.description);
        
   } // testFinal
   
   static list<task> createTestTasks(){
       list<task> tskList = new list<task>();
       For(integer i=0;i<5;i++){
           tskList.add(new task(type = 'Call',description = 'This is my initial description'));
       }
       return tskList;
   }
    
       static list<Event> createTestEvent(){
       list<Event> evtList = new list<Event>();
       For(integer i=0;i<2;i++){
           evtList.add(new Event(type = 'Meeting',subject = 'This is my initial description', DurationInMinutes = 30, ActivityDateTime = Datetime.now()));
       }
       return evtList;
   }
    
}