/** Virtual class used for communication between a page controller and a component controller.
 *
 * @see http://wiki.developerforce.com/index.php/Controller_Component_Communication
 *
 * History
 * -------
 * 02/10/2011 Dan Carmen   Created
   11/16/2017 Dan Carmen   Updating API version

 */
public with sharing virtual class PageControllerBase {
    
   private ComponentControllerBase myComponentController;
    
   /** Get the component controller object.
    */
   public virtual ComponentControllerBase getMyComponentController() {
      return myComponentController;
   } // getMyComponentController

   /** Set the component controller.
    */
   public virtual void setComponentController(ComponentControllerBase compController) {
      myComponentController = compController;
   } // setComponentController
    
   /** Get the page controller.
    */
   public PageControllerBase getThis() {
      return this;
   } // getThis

} // class PageControllerBase