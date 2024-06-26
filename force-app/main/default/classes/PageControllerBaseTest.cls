/** Test method for PageControllerBase and ComponentControllerBase
 *
 * @see http://wiki.developerforce.com/index.php/Controller_Component_Communication
 *
 * History
 * -------
   11/16/2017 Dan Carmen   Moved testMethod out of PageControllerBase class

 */
@isTest
private class PageControllerBaseTest {

   /** Tests for the ComponentControllerBase and PageControllerBase objects.
    */
   static testMethod void testVirtualController() {
        ComponentControllerBase ccb = new ComponentControllerBase();
        PageControllerBase pcb = new PageControllerBase();
        pcb.setComponentController(ccb);
        System.assertEquals(ccb,pcb.getMyComponentController());
        System.assertEquals(pcb,pcb.getThis());
        ccb.pageController = pcb;
        System.assertEquals(pcb,ccb.pageController);
   } // testController
   
} // class PageControllerBaseTest