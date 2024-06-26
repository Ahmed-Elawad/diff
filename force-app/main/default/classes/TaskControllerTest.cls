/* 
  Test methods for TaskController
   
  History
  -------
  07/08/2015 Dan Carmen   Created - removed test method from main class
  04/14/2016 Dan Carmen   Clean up code.
  
 */
@isTest
private class TaskControllerTest {

   //Test method    
   static testMethod void testGetTasks() {
      Referral_Account__c refAcct = new Referral_Account__c(Name='Test RefAcct');
      insert refAcct;
      Referral_Contact__c refCtct = new Referral_Contact__c(Referral_Account__c=refAcct.Id, Name='Test RefCtct');
      insert refCtct;
    
      System.Debug('Debugging...');
      System.Debug('Unit Test:');
      List<Task> taskList = new List<Task>();
      PageReference massCreatePage = new PageReference('/apex/ContactMassCreateTasks?idStr='+refCtct.Id);
      Test.setCurrentPage(massCreatePage);
      TaskController ctrl = new TaskController();
      ctrl.setTaskList(taskList);
      ctrl.getTaskList();
      ctrl.getTaskType();
      ctrl.save();
      System.assertEquals(1,[select count() from Task where WhatId=:refCtct.Id]);
      PageReference nextPage = ctrl.cancel();
      System.assertEquals('/a07', nextpage.getUrl() );
      //Ctrl.save();
   } // testGetTasks

} // class TaskControllerTest