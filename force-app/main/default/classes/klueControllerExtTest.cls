/* Test Class for klueControllerExt
    1/23/2019 Created Justin Stouffer
*/
@isTest
public class klueControllerExtTest {
    static testMethod void testklueControllerExt(){
      klueControllerExt insKlueControllerExt = new klueControllerExt();
    }
    /*public static testMethod void testKlueControllerExt() {
        Opportunity opp = new Opportunity(name = 'Test', StageName='Closed', CloseDate=System.today());
        insert opp;

        PageReference pageRef = Page.Klue;
        Test.setCurrentPage(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(opp);
        klueControllerExt stdCon = new klueControllerExt(sc);
        system.assertEquals(0, stdCon.getImpersonate());
        stdCon.setImpersonate(1);
        system.assertEquals(1, stdCon.getImpersonate());
        stdCon.reload();
        system.assertEquals(1, stdCon.getImpersonate());        
    }*/
}