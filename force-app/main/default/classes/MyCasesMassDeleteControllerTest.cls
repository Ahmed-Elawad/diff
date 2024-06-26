/* 
 * Allow the users to manage their quotas
 *
 * History
 * -------
 * 10/29/2018 Dan Carmen     Created class to move test method out of main class.
   09/25/2020 Jake Hinds	 API Version

 */
@isTest
private class MyCasesMassDeleteControllerTest {

    static testmethod void unitTest1(){
        Test.startTest();
        Profile p = [Select Id From Profile Where Name='System Administrator'];
        List<User> listUSer = [Select id from User where isactive=true and ProfileId = :p.Id limit 2];
        // the ids of all of the cases
        List<Id> listId = new List<Id>();
        // all of the cases that are created for testing
        List<Case> listCase = new List<Case>();
        List<Case> listCaseUserStd = new List<Case>();
        System.runAs(listUser[0]){
            for (Integer cnt=0; cnt<5; cnt++) {
               listCaseUserStd.add(new Case(Subject='Test case Standard User '+ cnt));
            }
            insert listCaseUserStd;
            listCase.addAll(listCaseUserStd);
            for(Case cs : listCaseUserStd){
                listId.add(cs.Id);
            }
        }
        System.runAs(listUser[1]){
            List<Case> listCaseUserSysAdm = new List<Case>();
            for (Integer cnt=0; cnt<10; cnt++) {
               listCaseUserSysAdm.add(new Case(Subject='Test case System Admin User '+ cnt));
            } // for
            insert listCaseUserSysAdm;
            // have all cases in the list
            listCase.addAll(listCaseUserSysAdm);
            // get the ids of the records created for this user.
            List<Id> myCaseIds = new List<Id>();
            for(Case cs : listCaseUserSysAdm){
                listId.add(cs.Id);
                myCaseIds.add(cs.Id);
            }

            ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(listCase);
            ssc.setSelected(listCase);

            MyCasesMassDeleteController cont = new MyCasesMassDeleteController(ssc);

            System.assertEquals(listCaseUserStd.size()+listCaseUserSysAdm.size(),cont.ListAllCases.size());
            System.assertEquals(listCaseUserStd.size(),cont.listOtherCases.size());
            System.assertEquals(listCaseUserSysAdm.size(),cont.listMyCases.size());
            
            System.assertEquals(cont.ListAllCases.size(), cont.listMyCases.size() + cont.listOtherCases.size());
            System.assertEquals('/500/o',cont.doDelete().getURL());
            System.assertEquals(0,[Select count() from case where id in :myCaseIds]);
            
            System.assertNotEquals(listCase.size(), cont.listMyCases.size());
            System.assertEquals(null,cont.doDelete());

            cont.listMyCases.clear();
            System.assertEquals(null,cont.doDelete());
            //pageRef.getParameters().put('CaseIds', '');
            cont.listIds = null;
            //Test.setCurrentPageReference(pageRef);
            System.assertEquals(null,cont.doDelete());
        }
        Test.stopTest();
    }
} // MyCasesMassDeleteControllerTest