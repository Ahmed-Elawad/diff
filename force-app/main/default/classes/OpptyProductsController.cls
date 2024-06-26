/* 
 * Controller for managing the Opportunity Products.
 *
 * History
 * -------
 * 03/24/2011 Dan Carmen        Created.
 * 05/16/2012 Cindy Freeman     Modified so Service Location field will appear for 2 opportunity types.
   04/05/2013 Dan Carmen        Modifications so code will pass tests in the sandboxes
   11/10/2015 Dan Carmen        Modifications for Quoting tool
   01/29/2015 Jacob Hinds       Added in Non-Payroll Units
   06/19/2020 Jacob Hinds    Changing arguments of setOpportunity per ProductHelper change
 *
 */
public with sharing class OpptyProductsController {

   public User curUser {get; private set;}
   
   /** An instantiation of the class to use throughout. */
   public ProductHelper productHelper{get; set;}
      
   //public Opportunity oppty{get; set;}
   
   public Id opptyId{get; set;}
   
   public OpptyProductsController(ApexPages.StandardController stdController) {
      productHelper = new ProductHelper();
      curUser = new UserHelper().getUserById(UserInfo.getUserId());
      
      Boolean isSalesRep = Utilities.isSalesRep(curUser.Profile.Name);
      saveSuccessfulInConsole = false;
      
      //Opportunity testOppty = (Opportunity)stdController.getRecord();
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'testOppty='+testOppty));
      
      // the Id of the Case should be passed in here. If not, cannot proceed
      opptyId = System.currentPageReference().getParameters().get('id');
      // see if sales org is passed in - use that if it is
      productHelper.salesOrg = System.currentPageReference().getParameters().get('salesOrg');
      
      opptyComplete = productHelper.setOpportunity(opptyId,curUser,isSalesRep);
      
      // make sure an opportunity was found
      opptyFound = (productHelper.oppty != null);
      
      if (!opptyComplete) {
         return;
      }
      
      finishSetup();
   } // OpptyProductsController
   
   public Boolean finishSetup() {
      Boolean okay = true;
      if (productHelper.usingQuoteTool && !productHelper.isDsaRecordType) {
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'A '+productHelper.quoteToolName+' opportunity must be a DSA record type to be used here.'));
         //okay = false;
         //opptyComplete = false;
         //opptyFound = false;
      }
      
      // if there is no pricing setup, we're only going to allow true-ups and chargebacks. They will not be able to add more products.
      if (productHelper.usingQuoteTool && !productHelper.opptyIsClosed) {
         // if the opportunity isn't closed and we're using the quoting tool, don't allow entry into the form.
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'A '+productHelper.quoteToolName+' opportunity must be closed when entering the form.'));
         //okay = false;
         //opptyComplete = false;
         //opptyFound = false;
      }
      
      if (okay) {
         // determine the sales org by the record type of the Opportunity
         if (productHelper.salesOrg == null) {
            productHelper.salesOrg = RecordTypeHelper.getSalesOrgForRecordTypeName(productHelper.oppty.RecordType.Name);
         }
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'salesOrg 1='+productHelper.salesOrg));
         // as a final default, use the sales org from the user
         if (productHelper.salesOrg == null) {
            productHelper.salesOrg = curUser.Sales_Org__c;
         }

         System.debug('finishSetup salesOrg='+productHelper.salesOrg);
         // setup the priceHelper object
         productHelper.setupPriceHelper(curUser,productHelper.salesOrg);

         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'salesOrg 2='+productHelper.salesOrg));
         // check to see if pricebook already setup on Opportunity
         if (productHelper.oppty != null && productHelper.oppty.Pricebook2Id != null) {
            productHelper.getPricebook(null,productHelper.oppty.Pricebook2Id);
         } else {
            productHelper.getPricebookBySalesOrg(productHelper.salesOrg);
         } // if (productHelper.oppty != null
      } // if (okay)
      return okay;
   } // finishSetup
   
   public Boolean readOnly{
      get{ return productHelper.readOnly; }
   } // readOnly
   
   public Boolean opptyComplete{get; set;}
   
   public Boolean opptyFound{get;set;}
   
   public static final String PRODS='Standalone Products';
   
   //public ProductHelper.ProdSelector testProd{get;set;}
      
   public PageReference saveProducts() {
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'saveProducts enter method'));
      //recalculate just to make sure
      if (!productHelper.calcAllProds(false)) {
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'saveProducts calcAllProds returned false'));
         return null;
      }
      // put the totals on the opportunity
      // setup fee
      productHelper.oppty.Setup_Fee__c = productHelper.totalRecord.oli.Setup_Fee__c;
      // payroll units
      productHelper.oppty.Payroll_Units__c = productHelper.totalRecord.oli.Payroll_Unit__c;
      // non-payroll units
      productHelper.oppty.Non_Payroll_Units__c = productHelper.totalRecord.oli.Non_Payroll_Unit__c;
      // revenue
      productHelper.oppty.Revenue__c = Utilities.nvl(productHelper.totalRecord.oli.TotalPrice) - Utilities.nvl(productHelper.totalRecord.oli.Setup_Fee__c);
      try {
         // save the opportunity in case changes were made there
         update productHelper.oppty;
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'saveProducts opportunity update successful'));
      } catch (Exception e) {
         ApexPages.addMessages(e);
         return null;
      }

      // save the products
      if (productHelper.saveSelectedProducts(opptyId)) {
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'saveProducts saveSelectedProducts returned true'));
         PageReference opptyPr = new PageReference('/'+opptyId);
         opptyPr.setRedirect(true);             
         return opptyPr;
      //} else {
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'saveProducts saveSelectedProducts returned false'));
      }
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'saveProducts end of method'));
      return null;
   } // saveProducts
   
   public PageReference checkOpptyAndContinue() {
      opptyComplete = productHelper.checkOpptyInfo();
      if (opptyComplete) {
         // save these changes made by the user
         update productHelper.oppty;
         // finish the setup
         finishSetup();
      }
      return null;
   } // checkOpptyAndContinue
   
   public String blockTitle{
      get{
         if (productHelper != null && productHelper.oppty != null) {
            return productHelper.oppty.Name;
         }
         return 'Product Information';
      } // get
   } // blockTitle
   
   /** Calculate the revenue on the selected products
    */
   public PageReference calcRevenue() {
      productHelper.calcAllProds(false);
      return null;
   } // calcRevenue
   
   /** Change the price schedule (probably based on a cost center change).
    */
   public PageReference changePriceSchedule() {
      productHelper.setPriceScheduleByCostCenter();
      //productHelper.priceHelper.setPriceSchedule(productHelper.costCenter,productHelper.salesOrg);
      
      return null;
   } // changePriceSchedule
   
   /** flag opportunities that need the Service Location field
    */
    public Boolean needServiceLocation {
      get {
          if (productHelper != null && (productHelper.salesOrg == 'PAY' || productHelper.salesOrg == 'HRS')) {
              return true;
          }
          return false;
      } //get
    } //needServiceLocation


    public Boolean saveSuccessfulInConsole {get; set;}

    public PageReference saveProductsInConsole() {
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'saveProducts enter method'));
      //recalculate just to make sure
      if (!productHelper.calcAllProds(false)) {
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'saveProducts calcAllProds returned false'));
         return null;
      }
      // put the totals on the opportunity
      // setup fee
      productHelper.oppty.Setup_Fee__c = productHelper.totalRecord.oli.Setup_Fee__c;
      // payroll units
      productHelper.oppty.Payroll_Units__c = productHelper.totalRecord.oli.Payroll_Unit__c;
      // non-payroll units
      productHelper.oppty.Non_Payroll_Units__c = productHelper.totalRecord.oli.Non_Payroll_Unit__c;
      // revenue
      productHelper.oppty.Revenue__c = Utilities.nvl(productHelper.totalRecord.oli.TotalPrice) - Utilities.nvl(productHelper.totalRecord.oli.Setup_Fee__c);
      try {
         // save the opportunity in case changes were made there
         update productHelper.oppty;
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'saveProducts opportunity update successful'));
      } catch (Exception e) {
         ApexPages.addMessages(e);
         return null;
      }

      // save the products
      if (productHelper.saveSelectedProducts(opptyId)) {
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'saveProducts saveSelectedProducts returned true'));
         PageReference opptyPr = new PageReference('/'+opptyId);
         opptyPr.setRedirect(true);       
         saveSuccessfulInConsole = true;      
         return null;
      //} else {
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'saveProducts saveSelectedProducts returned false'));
      }
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'saveProducts end of method'));
      return null;
   } // saveProducts
   
   public PageReference returnSaveSuccessfulInConsole(){
      System.debug('saveSuccessfulInConsole: ' + saveSuccessfulInConsole);
      return null;
   }
   
} // class OpptyProductsController