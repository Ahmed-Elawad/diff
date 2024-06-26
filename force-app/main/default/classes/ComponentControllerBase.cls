/** Virtual class used for communication between a page controller and a component controller.
 *
 * @see http://wiki.developerforce.com/index.php/Controller_Component_Communication
 *
 * History
 * -------
 * 02/10/2011 Dan Carmen   Created
   11/16/2017 Dan Carmen   Updating API version

 */
public with sharing virtual class ComponentControllerBase {

   public PageControllerBase pageController { get; 
      set {
         if (value != null) {
            pageController = value;
            pageController.setComponentController(this);
         }
      } // set
   } // pageController
   
} // class ComponentControllerBase