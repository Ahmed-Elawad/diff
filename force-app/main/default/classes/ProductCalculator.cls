/** Calculate the revenue on an Opportunity
 *
 * History
 * -------
 * 11/07/2012 Dan Carmen   Created
 *
*/
public with sharing class ProductCalculator {

   public static Boolean calcOpptyProducts(User curUser, Opportunity oppty, OpportunityLineItem[] olis) {
      Boolean okay = true;
      System.debug('oppty='+oppty);
      if (oppty != null && olis != null && !olis.isEmpty()) {
      	String salesOrg = null;
      	// try to get the salesOrg from the pricebook
      	if (oppty.Pricebook2Id != null) {
      		try {
               Product_Pricebook_Map__c ppm = [Select Id, Name, Sales_Org__c, Pricebook_Id__c from Product_Pricebook_Map__c where Pricebook_Id__c = :oppty.Pricebook2Id limit 1];
               salesOrg = ppm.Sales_Org__c;
      		} catch (Exception e) {
      		   // do nothing here
      		}
      	}
      	// if not found by the pricebookid, default to this.
      	if (salesOrg == null) {
            salesOrg = RecordTypeHelper.getSalesOrgForRecordTypeName(oppty.RecordType.Name);
      	}
         System.debug('calcOpptyProducts salesOrg='+salesOrg);

         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'Attempting to recalc products'));
         ProductHelper ph = new ProductHelper();
         ph.salesOrg = salesOrg;
         ph.getPricebook(null,oppty.Pricebook2Id);
         ph.oppty = oppty;
         ph.setupPriceHelper(curUser,salesOrg);
         ph.setupAllProdStructure();

         ph.oppty = oppty;
         ph.opptyLineItems = olis;
         ph.setupLineItems();
         ph.setupSelectedPkg(false);
               
         ph.buildProdList(false,true);
      }
      return okay;
   } // calcOpptyProducts
   
} // class ProductCalculator