/* 
 *The methods used for creating and/or updating
 * a group of accounts based off of a parent.
 *
 * History
 * ------- 
 * 03/22/2009 Dan Carmen   Created
 * 02/09/2015 Cindy Freeman   added 2 fields to be included in clone, asset.HRO_Client_Type__c, account.HRO_Complexity_Code__c
 * 07/06/2020  Jacob Hinds         Added without sharing per PMD
   03/08/2022 Dan Carmen           Removed old custom latitude and longitude fields

*/
 public without sharing class CloneAccountController {
   
   private Account thisAcct;
   
   public Account getThisAcct() {
      return thisAcct;
   } // getThisAcct
   
   /* The extension constructor initializes the private member
      variable acct by using the getRecord method from the standard
      controller.
    */
   public CloneAccountController() {
      Id id = System.currentPageReference().getParameters().get('id');
      if (id != null) {
         thisAcct = [SELECT Id, Name, Site, AccountNumber, OwnerId, RecordTypeId,NumberOfEmployees
                    ,Phone, Fax, Type
                    ,BillingStreet, BillingCity, BillingState, BillingPostalCode
                    ,ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode
                    ,HRO_Number__c, Time_Zone__c, Frequency__c,Current_Prior_Method__c
                    ,HRO_Implementation_Coordinator__c,HRO_NCP_Received_Date__c
                    ,HRO_Service_Agreement_Received__c, HRO_First_Run_or_New_Setup_Date__c
                    ,HRO_Preview_Hosting_Client__c, HRO_Group__c, HRO_Total_ID_s__c
                    ,HRO_Complexity_Code__c
                    ,(SELECT Id, Name, Product_Plan_Code__c, Start_Date__c, Product_End_Date__c, PurchaseDate, HRO_Client_Type__c from Assets )
                  FROM Account WHERE Id=:id];
      }
      checkAddRows();      
   } // CloneAccountExtension
   
   private List<SelectOption> prods = null;
   
   /* Get a list of products that have plan codes. 
    */
   public List<SelectOption> getProds() {
      if ((prods == null) && (thisAcct != null)) {
         prods = new List<SelectOption>();
         for (Asset at : thisAcct.Assets) {
            // only add for products that have a plan code
            if (at.Product_Plan_Code__c != null) {
               prods.add(new SelectOption(at.Product_Plan_Code__c, at.Product_Plan_Code__c));
            }
         } // for (Asset at)
      } // if ((prods == null
      return prods;
   } // getProds
   
   /* Are there any products setup?
    */
   public boolean getHasProds() {
      getProds();
      if ((prods != null) && (prods.size() > 0)) {
         return true;
      }
      return false;
   } // getHasProds
   
   /* The products checked in the checkboxes on CloneAccount1. */
   String[] products = new String[]{};
   public String[] getProducts() {
      return products;
   }
   public void setProducts(String[] products) {
      this.products = products;
   }
   // The number of group records to create.
   Integer numberGroupRecords=0;
   
   /* Used for testing purposes. */
   public void setNumberGroupRecords(Integer nbr) {
      numberGroupRecords = nbr;
   } // setNumberGroupRecords
   
   /* Used for testing purposes. */
   public Integer getNumberGroupRecords() {
      return numberGroupRecords;
   } // getNumberGroupRecords
   
   // The children accounts being created.
   List<Account> accts=null;
   
   /* The accounts to be updated.
    */
   List<Account> updateAccts=null;
   
   /** Get the list of accounts to be updated.
    */
   public List<Account> getUpdateAccts() {
      return updateAccts;
   } // getUpdateAccts
   
   /* If to show the update section of the page.
    */
   public boolean getShowUpdates() {
      if ((getUpdateAccts() != null) && (getUpdateAccts().size() > 0)) {
         return true;
      }
      return false;
   } // getShowUpdates
   
   /* The accounts to be inserted.
    */
   List<Account> insertAccts=null;
   
   /** Get the list of accounts to be inserted.
    */
   public List<Account> getInsertAccts() {
      return insertAccts;
   } // getUpdateAccts
   
   /* If to show the insert section of the page.
    */
   public boolean getShowInserts() {
      if ((getInsertAccts() != null) && (getInsertAccts().size() > 0)) {
         return true;
      }
      return false;
   } // getShowInserts
   
   public List<Account> getAccts() {
      if ((accts == null) || (accts.size() < numberGroupRecords)) {
         if (accts == null) {
            accts = new List<Account>();
         } // if (accts == null
         while (accts.size() < numberGroupRecords) {
            Account acct = new Account(Name=thisAcct.Name);
            accts.add(acct);
         }
      } // if ((accts == null
      return accts;
   } // getAccts
   
   /* Set the fields on the account that will be inserted.
    */
   private void setInsertFields(Account acct) {
      acct.Site=thisAcct.Site;
      acct.OwnerId=thisAcct.OwnerId;
      acct.RecordTypeId=thisAcct.RecordTypeId;
      acct.NumberOfEmployees=thisAcct.NumberOfEmployees;
      acct.Phone=thisAcct.Phone;
      acct.Fax=thisAcct.Fax;
      acct.Type=thisAcct.Type;
      acct.BillingStreet=thisAcct.BillingStreet;
      acct.BillingCity=thisAcct.BillingCity;
      acct.BillingState=thisAcct.BillingState;
      acct.BillingPostalCode=thisAcct.BillingPostalCode;
      acct.ShippingStreet=thisAcct.ShippingStreet;
      acct.ShippingCity=thisAcct.ShippingCity;
      acct.ShippingState=thisAcct.ShippingState;
      acct.ShippingPostalCode=thisAcct.ShippingPostalCode;
      acct.Time_Zone__c=thisAcct.Time_Zone__c;
      acct.Frequency__c=thisAcct.Frequency__c;
      acct.Current_Prior_Method__c=thisAcct.Current_Prior_Method__c;
      acct.HRO_Complexity_Code__c = thisAcct.HRO_Complexity_Code__c;
   } // setInsertFields
   
   private static final String[] insertNames = new String[]{'Owner','Record Type'
      ,'Number of Employees','Phone','Fax','Client Type'
      ,'Billing Address','Shipping Address','Time Zone'
      ,'Current Prior Method', 'HRO Complexity Code'};
      
   /* Set the fields on the account that will be updated.
    */
   private void setUpdateFields(Account acct) {
      acct.HRO_Number__c = thisAcct.HRO_Number__c;
      acct.HRO_Implementation_Coordinator__c = thisAcct.HRO_Implementation_Coordinator__c;
      acct.HRO_NCP_Received_Date__c = thisAcct.HRO_NCP_Received_Date__c;
      acct.HRO_Service_Agreement_Received__c = thisAcct.HRO_Service_Agreement_Received__c;
      acct.HRO_First_Run_or_New_Setup_Date__c = thisAcct.HRO_First_Run_or_New_Setup_Date__c;
      acct.HRO_Preview_Hosting_Client__c = thisAcct.HRO_Preview_Hosting_Client__c;
      acct.HRO_Group__c = thisAcct.HRO_Group__c;
      acct.HRO_Total_ID_s__c = thisAcct.HRO_Total_ID_s__c;
      acct.HRO_Complexity_Code__c = thisAcct.HRO_Complexity_Code__c;
   } // setUpdateFields
   
   private static final String[] updateNames = new String[]{'HRO Number','HRO Implementation Coordinator'
       ,'HRO NCP Received Date','HRO Service Agreement Received'
       ,'HRO First Run Date/New Setup Date'
       ,'HRO Preview Hosting Client'
       ,'HRO Group','HRO Total IDs'
       ,'HRO Complexity Code'};
       
   public String getUpdateNames() {
      String names = '';
      for (String val : updateNames) {
         if (names.length() > 0) {
            names += ', ';
         }
         names += val;
      }
      return names;
   } // getUpdateNames
   
   public String getInsertNames() {
      String names = '';
      for (String val : insertNames) {
         if (names.length() > 0) {
            names += ', ';
         }
         names += val;
      }
      for (String val : updateNames) {
         names += ', '+val;
      }
      return names;
   } // getInsertNames
   
   /* Used to navigate to the first page.
    */
   public PageReference step1() {
      return Page.CloneAccount1;
   } // step1
   
    /* Used to navigate to the second page.
    */
   public PageReference step2() {
      return Page.CloneAccount2;
   } // step1
   
   private List<Asset> selectedAssets = new List<Asset>();
   
   /* Get the assets selected by the user. 
    */
   public List<asset> getSelectedAssets() {
      return selectedAssets;
   } // getSelectedAssets
   
   public boolean getShowSelected() {
      if (getSelectedAssets().size() == 0) {
        return false;
      }
      return true;
   } // getShowSelected
   
    /* Used when the next button is clicked from step 1.
      Only records with an account number are saved.
    */
   public PageReference nextFromStep1() {
      // if the account is not set, do not proceed.
      if (!getIsAccountSet()) {
         return step1();
      }     

      if (accts == null) {
          ApexPages.Message myMsg = new ApexPages.Message(ApexPages.severity.ERROR, 'No group accounts are defined! Cannot proceed.');
          ApexPages.addMessage(myMsg);
          return step1();
      } else {
         boolean allNbrsOkay = true;
         List<Account> newAcctList = new List<Account>();
         // create a list of all the account numbers to search to see if they're existing.
         List<String> acctNbrs = new List<String>();
         for (Account acct : accts) {
            if ((acct.AccountNumber != null) && (acct.AccountNumber != '')) {
               // convert to upper case
               acct.AccountNumber = acct.AccountNumber.toUpperCase();
               if (!AccountHelper.isAcctNbrValid(acct.AccountNumber)) {
                  ApexPages.Message myMsg = new ApexPages.Message(ApexPages.severity.ERROR, 'The Account Number you entered, '+acct.AccountNumber+', is not in the format branch-client number(####-AAAA). Enter a correct value to proceed.');
                  ApexPages.addMessage(myMsg);
                  allNbrsOkay = false;
               } else {
                  newAcctList.add(acct);
                  acctNbrs.add(acct.AccountNumber);
                  String acctNbr2 = AccountHelper.transformAcctNbr(acct.AccountNumber);
                  if ((acctNbr2 != null) && (acctNbr2 != acct.AccountNumber)) {
                     acctNbrs.add(acctNbr2);
                  }
                  /* check if account number matches original account - do not let
                   * users update the existing record.
                   */
                  if ((acct.AccountNumber == thisAcct.AccountNumber) ||
                      (acctNbr2 == thisAcct.AccountNumber)) {
                     ApexPages.Message myMsg = new ApexPages.Message(ApexPages.severity.ERROR, 'The Account Number you entered, '+acct.AccountNumber+', matches the original Prospect-Client record. This record cannot be updated by this process.');
                     ApexPages.addMessage(myMsg);
                     allNbrsOkay = false;
                  } // if ((acct.AccountNumber))
               }
            } // if
         } // for (Account
         if (!allNbrsOkay) {
            return step1();
         }
         accts = newAcctList;
         // Do not proceed if no accounts were setup
         if (accts.size() == 0) {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.severity.ERROR, 'Cannot proceed - At least one Prospect-Client Number has to be entered.!');
            ApexPages.addMessage(myMsg);
            return step1();
         }
         // search to see if account numbers already exist
         updateAccts = new List<Account>([select Name, Id, AccountNumber, (select Id, Name, Product_Plan_Code__c, Start_Date__c, Product_End_Date__c, PurchaseDate from Assets where Product_Plan_Code__c in :products) from Account where AccountNumber in :acctNbrs]);
         if (updateAccts.size() == 0) {
            updateAccts = null;
            insertAccts = accts;
         } else {
            insertAccts = new List<Account>();
            for (Account acct : accts) {
               // get the tranformed account number
               String acctNbr2 = AccountHelper.transformAcctNbr(acct.AccountNumber);
               Boolean updateFound = false;
               for (Account updateAcct : updateAccts) {
                  if ((acct.AccountNumber == updateAcct.AccountNumber) ||
                      (acctNbr2 == updateAcct.AccountNumber)) {
                     updateFound = true;
                     break;
                  }
               } // for
               if (!updateFound) {
                  insertAccts.add(acct);
               }
            } // for
         } // if (updateAccts
     
         // set the assets (if any)
         selectedAssets.clear();
         for (String prod : products) {
            for (Asset at : thisAcct.Assets) {
               if (at.Product_Plan_Code__c == prod) {
                  selectedAssets.add(at);
               }                
            } // for (Asset at)
            
         } // for (String prod)
         numberGroupRecords = accts.size();
      } // if (accts != null
      return step2();
   } // nextFromStep1
   
   /* Cancel the operation and return to the original account form.
    */
   public PageReference cancel() {
      PageReference acctPage = new PageReference('/'+thisAcct.id);
      acctPage.setRedirect(true);
      return acctPage;
   } // cancel

   /* Check if the Account is set. If it is not, log an error.
    */
   public boolean getIsAccountSet() {
      Account acct = getThisAcct();
      if ((acct != null) && (acct.Name != null)) {
        return true;
      }     
      ApexPages.Message myMsg = new ApexPages.Message(ApexPages.severity.ERROR, 'No Prospect-Client record was found. One must be passed into this form in order to use it.');
      ApexPages.addMessage(myMsg);
      return false;
   } // getIsAccountSet
   
   /* Check if it's okay to add rows. Only add rows if the account
      is set.
    */
   public void checkAddRows() {
      // only set the number of rows if an account is set
      if (getIsAccountSet()) {
         numberGroupRecords += 5;
         // only allow a maximum of 100 records added at once
         if (numberGroupRecords > 100) {
            numberGroupRecords = 100;
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.severity.INFO, 'You are at the maximum of 100 rows. You cannot add any more!');
            ApexPages.addMessage(myMsg);
         }
      }
   } // checkAddRows
   
   /* Add 5 more rows to the screen.
    */
   public PageReference addMoreRows() {
      checkAddRows();
      return step1();
   } // addMoreRows
   
   /* Save the records and return to the original account form.
    */
   public PageReference save() {
      // the products to insert
      List<Asset> assets = new List<Asset>();
      // send the user back to the original account.
      if (insertAccts != null) {
         for (Account acct : insertAccts) {
            setInsertFields(acct);
            setUpdateFields(acct);
         }         
         // save the inserts. Get the ids to create the products.
         Database.SaveResult[] saveResults = Database.Insert(insertAccts, false);
         for (Database.SaveResult sr : saveResults) {           
            if (sr.isSuccess()) {               
               for (Asset at : selectedAssets) {
                  assets.add(newAsset(at,sr.getId()));
               } // for
            } // if (sr.isSuccess
         } // for (Database.SaveResult
      } // if (insertAccts)
      if (updateAccts != null) {
         for (Account acct: updateAccts) {
            // set the updated values in the fields
            setUpdateFields(acct);
            // check to see if the product is already there. If not, add it.
            for (Asset at : selectedAssets) {
               boolean found = false;
               if (acct.Assets != null) {
                  for (Asset acctAt : acct.Assets) {
                     if (acctAt.Product_Plan_Code__c == at.Product_Plan_Code__c) {
                        found = true;
                        break;
                     }
                  } // for Asset at
               } // if (acct.Assets
               if (!found) {
                  assets.add(newAsset(at,acct.Id));
               }
            } // for (String prod)
         } // for
         update updateAccts;

      } // if (updateAccts != null

      insert assets;
        
      PageReference acctPage = new PageReference('/'+thisAcct.id);
      
      acctPage.setRedirect(true);
      
      return acctPage;
   } // save
   
   /* Create a new Asset object.
    */
   private Asset newAsset(Asset originalAsset, ID acctId) {
     Asset at = new Asset(AccountId = acctId);
     at.Product_Plan_Code__c = originalAsset.Product_Plan_Code__c;
     at.Name = originalAsset.Name;
     at.Start_Date__c = originalAsset.Start_Date__c;
     at.Product_End_Date__c = originalAsset.Product_End_Date__c;
     at.PurchaseDate = originalAsset.PurchaseDate;
     at.HRO_Client_Type__c = originalAsset.HRO_Client_Type__c;
     return at;
   } // newAsset
   

   
} // CloneAccountController