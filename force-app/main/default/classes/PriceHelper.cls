/* 
 * Helper class for dealing with Pricing.
 *
 * History
 * -------
 * 04/14/2011 Dan Carmen   Created
   12/30/2011 Dan Carmen   Allow for setup fee to be entered if enter revenue manual selected.
   02/29/2012 Dan Carmen   Fix for annualized discount being improperly truncated.
   04/20/2012 Dan Carmen   Fix for extra spaces in the setup fee options field.
   05/16/2012 Dan Carmen   Allow to have multiple sales orgs on prices
   11/01/2012 Dan Carmen   Modifications to allow Account clone to calculate revenue
   02/14/2013 Dan Carmen   Code modifications to reduce script statements.
   04/14/2020 Jake Hinds   Allow for setup options to display a picklist for 1 value, helpful for 'read only' setup fee
 *
 */
public with sharing class PriceHelper {
	
   /** Default Constructor.
    */
   public PriceHelper() {
      priceSchedules = new String[]{};
   } // PriceHelper
   
   public Office_Price_Schedule_Map__c priceScheduleMap{get;
   	  set {
   	     priceScheduleMap = value;
   	     priceSchedules.clear();
   	     priceScheduleKey = '';
         if (priceScheduleMap != null) {
            if (priceScheduleMap.Price_Schedule__c != null) {
               priceSchedules.add(priceScheduleMap.Price_Schedule__c);
               priceScheduleKey += priceScheduleMap.Price_Schedule__c+':';
            }
            if (priceScheduleMap.Price_Schedule_2__c != null) {
               priceSchedules.add(priceScheduleMap.Price_Schedule_2__c);
               priceScheduleKey += priceScheduleMap.Price_Schedule_2__c+':';
            }
         } // if (priceScheduleMap
   	  } // set
   } // priceScheduleMap
   
   //private Map<String,String[]> allSchedules = new Map<String,String[]>();
   
   /** Get a list of all price schedules for a sales org.
    */
    /*
   public String[] getAllSchedules(String salesOrg) {
   	  if (!allSchedules.containsKey(salesOrg)) {
   	     if (doPriceSchedulesExist(salesOrg)) {
   	        // query the sales orgs
   	        Office_Price_Schedule_Map__c[] opsms = [Select Id, Name
                       ,Price_Schedule__c
                       ,Price_Schedule_2__c
                   From Office_Price_Schedule_Map__c
                  Where Sales_Org__c = :salesOrg];
            Map<String,String> schedMap = new Map<String,String>();
            for (Office_Price_Schedule_Map__c opsm : opsms) {
               if (opsm.Price_Schedule__c != null && !schedMap.containsKey(opsm.Price_Schedule__c)) {
                  schedMap.put(opsm.Price_Schedule__c,opsm.Price_Schedule__c);
               }
               if (opsm.Price_Schedule_2__c != null && !schedMap.containsKey(opsm.Price_Schedule_2__c)) {
                  schedMap.put(opsm.Price_Schedule_2__c,opsm.Price_Schedule_2__c);
               }
            } // for
            String[] schedules = schedMap.values();
            schedules.sort();
            allSchedules.put(salesOrg,schedules);
   	     } else {
   	        allSchedules.put(salesOrg,new String[]{});
   	     }
   	  }
      return allSchedules.get(salesOrg);
   } // getAllSchedules
   */
   
   /** Keep track of the ones we have checked already. */
   private Map<String,Boolean> existsMap = new Map<String,Boolean>();
   
   /** See if any price schedules exist for a sales org. 
    */
   public Boolean doPriceSchedulesExist(String salesOrg) {
   	Boolean exists = false;
      if (salesOrg != null) {
         System.debug('salesOrg='+salesOrg+' containsKey='+existsMap.containsKey(salesOrg));
         if (!existsMap.containsKey(salesOrg)) {
            Integer cnt = [Select count() from Office_Price_Schedule_Map__c where Sales_Org__c = :salesOrg limit 1];
            System.debug('salesOrg='+salesOrg+' cnt='+cnt);
            existsMap.put(salesOrg,(cnt == 0 ? false : true));
         }
         System.debug('salesOrg='+salesOrg+' number='+existsMap.get(salesOrg));
         exists = existsMap.get(salesOrg);
      } // if (salesOrg != null
      return exists;
   } // doPriceSchedulesExist
   
   /** The array of all of the price schedules available. */
   public String[] priceSchedules{get;set;}
   
   /** The key for storing the priceSchedules in the Map */
   public String priceScheduleKey{get;private set;}
   
   /** Get the price schedule based on the id. */
   public void setPriceSchedule(Id priceScheduleId) {
      priceScheduleMap = getPriceSchedule(null,null,priceScheduleId);
   } // setPriceSchedule
   
   /** Get the price schedule based on the cost center and sales org. */
   public void setPriceSchedule(String costCenter, String salesOrg) {
      priceScheduleMap = getPriceSchedule(costCenter,salesOrg,null);
   } // setPriceSchedule
   
   private Map<String,Office_Price_Schedule_Map__c> scheduleMap = new Map<String,Office_Price_Schedule_Map__c>();
   
   /** Get price schedule information based on user information.
    */
   public Office_Price_Schedule_Map__c getPriceSchedule(User u) {
      return getPriceSchedule(u.Cost_Center__c, u.Sales_Org__c, null);
   } // getPriceSchedule

   /** Get price schedule information based on the passed in parameters
    */
   public Office_Price_Schedule_Map__c getPriceSchedule(String costCenter, String salesOrg, Id priceScheduleId) {
      String key = costCenter+':'+salesOrg+':'+priceScheduleId;
   	  
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO,'key='+key+' containsKey='+scheduleMap.containsKey(key)+' scheduleExist='+doPriceSchedulesExist(salesOrg)));
   	  
      if (!scheduleMap.containsKey(key) && (priceScheduleId != null || doPriceSchedulesExist(salesOrg))) {
         try {
            Office_Price_Schedule_Map__c opsm = [Select Id, Name
                       ,Avg__c
                       ,Branch_Nbr__c
                       ,BW_SM_Pct__c
                       ,Cost_Center__c
                       ,Monthly_Pct__c
                       ,Price_Schedule__c
                       ,Price_Schedule_2__c
                       ,Sales_Org__c
                       ,Wkly_Pct__c
                   From Office_Price_Schedule_Map__c
                  Where (Cost_Center__c = :costCenter
                         and Sales_Org__c = :salesOrg)
                     or (Id = :priceScheduleId)];
   	     	//ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO,'selected record opsm='+opsm));
            scheduleMap.put(key,opsm);
         } catch (Exception e) {
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO,'In exception'));
            // put in an empty record so doesn't query again
            scheduleMap.put(key,new Office_Price_Schedule_Map__c());
         }
      } // if (opsm)
      Office_Price_Schedule_Map__c opsm = scheduleMap.get(key);
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'in getPriceSchedule costCenter='+costCenter+' salesOrg='+salesOrg+' priceScheduleId='+priceScheduleId+' price schedule='+opsm));
      return ((opsm == null || (opsm != null && opsm.Id == null)) ? null : opsm);
   } // getPriceSchedule

   /** Does a pricing exist for a product code? */
   private Map<String,Boolean> priceExistsMap = new Map<String,Boolean>();
   
   /** Does a pricing record (of any kind) exist for a product code.
    * We need this information to set the correct error message to the users. 
    */
   public void setPricingExists(String[] prodCodes, String salesOrg) {
      // make sure each product code is only checked once - this will not change
      String[] checkProdCodes = new String[]{};
      for (String prodCode : prodCodes) {
         if (!priceExistsMap.containsKey(prodCode)) {
            checkProdCodes.add(prodCode);
         }
      } // for
   	  
      if (!checkProdCodes.isEmpty()) {
      	String tempSalesOrg = '%'+salesOrg+'%';
         List<AggregateResult> groupedResults = new List<AggregateResult>( 
                          [select COUNT(Id) cnt,Name productCode 
                             from Product_Pricing__c 
                            where Name in :checkProdCodes 
                              and Low_Value__c = 1
                              and Sales_Org__c like :tempSalesOrg
                            group by Name ]);
                            
         for (AggregateResult ar : groupedResults) {
            String prodCode = (String)ar.get('productCode');
            Integer cnt = Integer.valueOf(ar.get('cnt'));
            // if has at least one record mark as true, else false
            priceExistsMap.put(prodCode,((cnt != null && cnt>0) ? true : false));
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO,'priceExistsMap 1 prodCode='+prodCode+' value='+priceExistsMap.get(prodCode)));
         } // for (AggregateResult ar
      
         // make sure all prod codes are accounted for
         for (String prodCode : checkProdCodes) {
            if (!priceExistsMap.containsKey(prodCode)) {
   	           priceExistsMap.put(prodCode,false);
               //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO,'priceExistsMap 2 prodCode='+prodCode+' value='+priceExistsMap.get(prodCode)));
   	      }
         } // for
      } // if (!checkProdCodes.isEmpty())
   } // setPricingExists
   
   /** Does a pricing record exist for a product code? 
    */
   public Boolean pricingExists(String productCode) {
   	// return the value in the map if it exists, otherwise if it's not in the map it's false
   	return ((productCode != null && priceExistsMap.containsKey(productCode)) ? priceExistsMap.get(productCode) : false);
   } // pricingExists
   
   /** Store the values so only retrieved once. */
   private Map<String,List<Product_Pricing__c>> allPricings = new Map<String,List<Product_Pricing__c>>();

   public Product_Pricing__c[] getPricings(String prodCode, String salesOrg, Integer frequency, Integer qty) {
   	  Integer searchFreq = checkSearchFrequency(frequency);
   	  String key = salesOrg+prodCode+searchFreq+priceScheduleKey+qty;
   	  //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO,'getPricings1 prodCode='+prodCode+' key='+key+' containsKey='+allPricings.containsKey(key)+' pricingExists='+pricingExists(prodCode)));
   	  if (!allPricings.containsKey(key)) {
   	     String[] prodCodes = new String[]{prodCode};
   	     setPricings(prodCodes,salesOrg,frequency,qty,false);
   	  }
   	  //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO,'getPricings2 prodCode='+prodCode+' key='+key+' containsKey='+allPricings.containsKey(key)+' pricingExists='+pricingExists(prodCode)));
      return allPricings.get(key);
   } // getPricings
   
   /** For searching purposes, see if any translation needs to be done on the frequency
    */
   public Integer checkSearchFrequency(Integer frequency) {
   	  // treat the 24 and 26 (bi-weekly, twice a month) then same
      if (frequency == 24) {
         return 26;
      }
      return frequency;
   } // checkSearchFrequency
   
   /** Select multiple pricing records at once to reduce DML.
    */
   public void setPricings(String[] prodCodes, String salesOrg, Integer frequency, Integer qty, Boolean setAllQty) {
      // make sure exist flag is set for the product code
      setPricingExists(prodCodes,salesOrg);
   	  
      // only perform a query if a pricing record exists
      String[] searchProdCodes = new String[]{};
      for (String prodCode : prodCodes) {
         if (pricingExists(prodCode)) {
            searchProdCodes.add(prodCode);
         }
      } // for (String prodCode
   	  
      if (!searchProdCodes.isEmpty()) {
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO,'query salesOrg='+salesOrg+' frequency='+frequency+' qty='+qty+' searchProdCodes='+searchProdCodes));
         Integer searchFrequency = checkSearchFrequency(frequency);
         String tempSalesOrg = '%'+salesOrg+'%';
         Product_Pricing__c[] allPP = [Select Id, Name
                     ,Amount__c
                     ,Base_Fee__c
                     ,Base_Fee_Product_Code__c
                     ,Discount_Free_Months_Allowed__c
                     ,Discount_Pct_Allowed__c
                     ,Enter_Revenue_Manually__c
                     ,Frequency_Annual_Rev__c
                     ,Frequency_Search__c
                     ,High_Value__c
                     ,Low_Value__c
                     ,Minimum_Fee__c
                     ,Price_Revenue_Adj__c
                     ,Pricing_Schedule__c
                     ,Pricing_Type__c
                     ,Revenue_Pct__c
                     ,Sales_Org__c
                     ,Setup_Fee__c
                     ,Setup_Fee_Options__c
                 From Product_Pricing__c
                Where Name in :searchProdCodes
                  and ((Frequency_Search__c = null) or 
                       (Frequency_Search__c != null and Frequency_Search__c = :searchFrequency))
                  and ((Pricing_Schedule__c = null) or 
                       (Pricing_Schedule__c != null and Pricing_Schedule__c in :priceSchedules))
                  //and High_Value__c >= :qty
                  and Low_Value__c <= :qty
                  and Sales_Org__c like :tempSalesOrg
                order by Name, Frequency_Search__c, High_Value__c
              ];
         for (String prodCode : searchProdCodes) {
            List<Product_Pricing__c> pricings = new List<Product_Pricing__c>();
            for (Product_Pricing__c pp : allPP) {
               if (pp.Name == prodCode) {
                  pricings.add(pp);
               }
            } // for (Product_Pricing__c
   	      if (setAllQty) {
               // enter at all of the different quantities up to the passed in value
               for (Integer cnt=1; cnt<=qty; cnt++ ) {
                  String key = salesOrg+prodCode+searchFrequency+priceScheduleKey+cnt;
                  allPricings.put(key,pricings);
               }
            } else {
               String key = salesOrg+prodCode+searchFrequency+priceScheduleKey+qty;
               allPricings.put(key,pricings);
            }
         } // for (String prodCode
      } // if (!searchProdCodes.isEmpty()
   	  
   } // setPricings
   
   public Decimal baseFee{get;set;}
   public Decimal transactionFee{get;set;}
   public Decimal pricePerPeriod{get;set;}
   /** Non-discounted annual price */
   public Decimal priceAnnual{get;set;}
   /** Discounted annual price. */
   public Decimal priceAnnualDiscounted{get;set;}
   
   /** The frequency used to calculated the annualized revenue. */
   public Integer annualFrequency{get;set;}
   /** Does this have a setup fee? */
   public Boolean hasSetupFee{get;set;}
   /** The default setup fee charged. */
   public Decimal setupFee{get;set;}
   /** The options available for the setup fee. */
   public String[] setupFeeOptions{get;set;}
   /** If there's tiered pricing for the setup fee. */
   public Boolean setupFeeTieredPricing{get;set;}
   
   /** Discount free months allowed */
   public Integer discountFreeMonthsAllowed{get;set;}
   /** Discount percent allowed. */
   public Decimal discountPctAllowed{get;set;}
   
   /** The discount free months applied for this product. */
   public Integer discountFreeMonthsSet{get;set;}
   /** The discount months applied for this product. */
   public Integer discountMonthsSet{get;set;}
   /** The discount percent applied for this product. */
   public Decimal discountPctSet{get;set;}
   /** The discount annualized for all percents set. */
   public Decimal discountPctAnnualized{get;set;}
   
   public Boolean enterRevenueManually{get;set;}
   
   /** If a pricing record exists but does not match the criteria entered. */
   public Boolean pricingExistsButDoesntMatch{get;set;}
   
   public Product_Pricing__c baseRecord{get;set;}
   
   public Boolean calcPrice(String prodCode, String salesOrg, Integer frequency, Integer qty) {
      return calcPrice(prodCode,salesOrg,frequency,qty,null,null,null);
   } // calcPrice
   
   /** Calculate the price for the passed in product information.
    */
   public Boolean calcPrice(String prodCode, String salesOrg, Integer frequency, Integer qty
   	                       ,Decimal discountFreeMonths, Decimal discountAmt, Decimal discountMonths ) {
      // clear values
      baseFee = 0;
      pricePerPeriod = 0;
      priceAnnual = 0;
      transactionFee = 0;
      enterRevenueManually = false;
      pricingExistsButDoesntMatch = false;
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO,'calcPrice prodCode='+prodCode+' salesOrg='+salesOrg+' frequency='+frequency+' priceSchedule='+priceScheduleKey+' qty='+qty));
   	clearSetupFee();
      clearDiscountInfo();   	  
   	  
      // if no prod code, don't do anything
      if (prodCode == null) {
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO,'No data for '+prodCode+' salesOrg='+salesOrg+' frequency='+frequency+' priceSchedule='+priceScheduleKey+' qty='+qty));
         enterRevenueManually = true;
         return false;
      }
      Product_Pricing__c[] ppList = getPricings(prodCode, salesOrg, frequency, qty);
      // if no values cannot proceed
      if (ppList == null || ppList.isEmpty()) {
      	 //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO,'No data for '+prodCode+' salesOrg='+salesOrg+' frequency='+frequency+' priceSchedule='+priceScheduleKey+' qty='+qty));
      	 // if no pricing found, check to see if any pricing exists. If it does, kick back an error
      	 if (pricingExists(prodCode)) {
      	    return logPricingError(prodCode, frequency);
         } // if (pricingExists(prodCode
         
         // if no pricing found, set flag to enter revenue manually
         enterRevenueManually = true;
         return false;
      }
      // assume the first record is the base record
      baseRecord = ppList[0];
      // see if enter revenue manually flag is set
      if (baseRecord.Enter_Revenue_Manually__c) {
         enterRevenueManually = true;
         // allow for a manual setup fee to be entered.
         hasSetupFee = (baseRecord.Setup_Fee_Options__c != null && baseRecord.Setup_Fee_Options__c == 'MANUAL');
         return false;
      }
      
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO,prodCode+' Before pricePerPeriod'));
      // calculate the base fee from the base record
      baseFee = (baseRecord.Base_Fee__c != null ? baseRecord.Base_Fee__c : 0);
      // if no base fee but there is a product code, attempt to select it.
      if (baseFee == 0 && baseRecord.Base_Fee_Product_Code__c != null) {
         PriceHelper basePH = new PriceHelper();
         basePH.priceScheduleMap = priceScheduleMap;
         if (basePH.calcPrice(baseRecord.Base_Fee_Product_Code__c,salesOrg,frequency,qty)) {
            baseFee = basePH.pricePerPeriod;
         }   	 
      } // if (baseFee
      //pricePerPeriod = (baseRecord.Base_Fee__c != null ? baseRecord.Base_Fee__c : 0);
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO,prodCode+' Pricing type='+baseRecord.Pricing_Type__c+'! ppList='+ppList.size()));
      
      // only the values in range should be returned, so don't have to do additional checking here
      for (Product_Pricing__c pp : ppList) {
         if (baseRecord.Pricing_Type__c == 'Flat Dollar') {
         	//ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO,prodCode+' Test 1'));
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'Flat Name='+pp.Name+' Low='+ppd.Low_Value__c+' High='+ppd.High_Value__c+' Qty='+qty));
            // ensure qty is in range
            if (qty >= pp.Low_Value__c && qty <= pp.High_Value__c) {
               transactionFee += Utilities.nvl(pp.Amount__c,0);
            }
         } else if (baseRecord.Pricing_Type__c == 'Cumulative Flat Dollar') {
         	//ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO,prodCode+' Test 2'));
            transactionFee += Utilities.nvl(pp.Amount__c,0);
         } else if (baseRecord.Pricing_Type__c == 'Rate Per Unit') {
         	//ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO,prodCode+' Test 3'));
            // ensure qty is in range
            if (qty >= pp.Low_Value__c && qty <= pp.High_Value__c) {
               transactionFee += (pp.Amount__c * qty);
            }
         } else if (baseRecord.Pricing_Type__c == 'Cumulative Rate Per Unit') {
         	//ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO,prodCode+' Test 4'));
            // get the range. Add 1 because low value=1, high value=1, (1-1=0)+1=1
            Integer qtyInRange = ((qty < pp.High_Value__c ? qty : pp.High_Value__c.intValue()) - pp.Low_Value__c.intValue())+1;
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, prodCode+' Rate Name='+pp.Name+' frequency='+frequency+' Low='+pp.Low_Value__c+' High='+pp.High_Value__c+' Qty='+qty+' qtyInRange='+qtyInRange));
            if (qtyInRange > 0) {
               transactionFee += (pp.Amount__c * qtyInRange);
            }
         }
      } // for (Product_Pricing__c
      
      // ensure we are meeting minimum pricing requirements if applicable
      if (baseRecord.Minimum_Fee__c != null && baseRecord.Minimum_Fee__c > (baseFee + transactionFee)) {
         baseFee = baseRecord.Minimum_Fee__c - transactionFee;
      }
      pricePerPeriod = baseFee + transactionFee;
      
      // determine the value used for calculating the annual frequency. if no value is on the record, use the value passed in
      annualFrequency = (baseRecord.Frequency_Annual_Rev__c != null ? baseRecord.Frequency_Annual_Rev__c.intValue() : frequency);
      
      // calculate the annual price
      priceAnnual = pricePerPeriod * annualFrequency;

      // calculate the setup fee
      checkSetupFee(salesOrg, frequency, qty);

      // check discount information
      checkDiscountInfo(discountFreeMonths, discountAmt, discountMonths);
      
      return true;
   } // calcPrice
   
   public Boolean logPricingError(String prodCode, Integer frequency) {
      pricingExistsButDoesntMatch = true;
      String msg = 'Pricing data for '+prodCode+' exists but does not match the Frequency and/or Price Schedule criteria passed in: Frequency='+frequency+', Price Schedule=';
      if (priceSchedules != null && !priceSchedules.isEmpty()) {
         for (Integer cnt=0; cnt<priceSchedules.size(); cnt++) {
      	    if (cnt > 0) {
      	       msg += ';';
      	    }
      	    msg += priceSchedules[cnt];
      	 } // for (Integer)
      } // if (priceSchedules
      msg += '. Please verify the Frequency and Price Schedule matches the product(s) selected.';
      if (!System.isBatch()) {
         ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,msg));
      } else {
         System.debug('logPricingError='+msg);
      }
      return false;
   } // getPricingError
   
   public void clearSetupFee() {
      // clear setup fee info
      setupFee = null;
      setupFeeOptions = null;
      hasSetupFee = false;
      setupFeeTieredPricing = false;
   } // clearSetupFee
   
   /** Get the setup fee information.
    */
   public Boolean checkSetupFee(String salesOrg, Integer frequency, Integer qty) {
      clearSetupFee();
      // calculate the setup fee
      if (baseRecord.Setup_Fee_Options__c != null) {
         if (baseRecord.Setup_Fee_Options__c.startsWith('PCT:')) {
            try {
               Decimal pct = Decimal.valueOf(baseRecord.Setup_Fee_Options__c.substring('PCT:'.length()).trim());
               // setup defaults to a percentage of the annualized revenue
               setupFee = (priceAnnual * pct/100).setScale(2);
               hasSetupFee = true;
            } catch (Exception e) {
            	System.debug('Exception trying to set percent: '+e);
               hasSetupFee = false;
            }
         } else if (baseRecord.Setup_Fee_Options__c == 'MANUAL') {
            hasSetupFee = true;
         } else if (baseRecord.Setup_Fee_Options__c == 'NONE') {
            hasSetupFee = false;
         } else if (baseRecord.Setup_Fee_Options__c.startsWith('VALUES:')) {
            hasSetupFee = true;
            // 1 or more values are available. If only one, default it. if more than one, make a picklist.
            String valueStr = baseRecord.Setup_Fee_Options__c.substring('VALUES:'.length());
            
            String[] values = valueStr.trim().split(';');
            //String[] values = StringHelper.getTokens(valueStr, ';', null);
            if (!values.isEmpty()) {
               // default the first value into the setup fee field
               try {
                  setupFee = Decimal.valueOf(values[0]);
               } catch (Exception e) {
                  // if for some reason it's not a valid value, null out the field and don't use it.
                  setupFee = null;
                  hasSetupFee = false;
               }
               // if least one value, the users will be given a picklist
               if (hasSetupFee && values.size() >= 1) {
                  setupFeeOptions = values;
               }
            } // if (!values.isEmpty()
         } else if (baseRecord.Setup_Fee_Options__c.startsWith('PRODCODE:')) {
            String setupProdCode = baseRecord.Setup_Fee_Options__c.substring('PRODCODE:'.length()).trim();
            // there is a separate pricing structure for the setup fee.
            PriceHelper setupPH = new PriceHelper();
            setupPH.priceScheduleMap = priceScheduleMap;
            if (setupPH.calcPrice(setupProdCode,salesOrg,frequency,qty)) {
               hasSetupFee = true;
               setupFee = setupPH.priceAnnual;
               setupFeeTieredPricing = true;
            }   	 
         } // if (baseRecord.Setup_Fee_Options__c
      } else if (baseRecord.Setup_Fee__c != null) {
      	 // flat dollar as default
      	 hasSetupFee = true;
         setupFee = baseRecord.Setup_Fee__c;
      } // if (baseRecord.Setup_Fee__c != null
      return true;
   } // checkSetupFee
   
   public void clearDiscountInfo() {
      // clear discount info
      discountFreeMonthsAllowed = null;
      discountPctAllowed = null;
      discountFreeMonthsSet = null;
      discountMonthsSet = null;
      discountPctSet = null;
      discountPctAnnualized = null;
   } // clearDiscountInfo
   
   /** Get the discount information.
    */
   public Boolean checkDiscountInfo(Decimal discountFreeMonths, Decimal discountPct, Decimal discountMonths) {
   	  clearDiscountInfo();
      // set the allowed free months field
      if (baseRecord.Discount_Free_Months_Allowed__c != null && baseRecord.Discount_Free_Months_Allowed__c > 0) {
         discountFreeMonthsAllowed = baseRecord.Discount_Free_Months_Allowed__c.intValue();
      }
      
      // set the allowed discount percent field
      if (baseRecord.Discount_Pct_Allowed__c != null && baseRecord.Discount_Pct_Allowed__c > 0) {
         discountPctAllowed = baseRecord.Discount_Pct_Allowed__c;
      }
      
      // if a value for free months is passed in, make sure it's within the allowed range  
      if (discountFreeMonths != null && discountFreeMonths > 0 && discountFreeMonthsAllowed != null) {
         discountFreeMonthsSet = discountFreeMonths.intValue();
         if (discountFreeMonthsSet > discountFreeMonthsAllowed) {
            discountFreeMonthsSet = discountFreeMonthsAllowed;
         }
      } // if (discountFreeMonths

      // get the number of months left that are not already free
      Integer availableMonths = 12 - (discountFreeMonthsSet != null ? discountFreeMonthsSet : 0);

      // verify value for discount months is passed in - only if entire year is not already free
      // need to have discountMonths and discountAmt passed in
      if (availableMonths > 0 && discountPctAllowed != null && discountMonths != null && discountPct != null) {
         // set the months
         discountMonthsSet = (discountMonths > availableMonths ? availableMonths : discountMonths).intValue();
         // set the percent
         discountPctSet = (discountPct > discountPctAllowed ? discountPctAllowed : discountPct);
      } // if (availableMonths
      
      // annualize the discount
      if (discountFreeMonthsSet != null || discountMonthsSet != null) {
         discountPctAnnualized = 0.0;
         if (discountFreeMonthsSet != null) {
         	// 100 percent discount / 12 months * the number of months that are free
            discountPctAnnualized += ((100.00/12.00) * discountFreeMonthsSet);
         }
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO,'discountPctAnnualized1='+discountPctAnnualized));
         
         if (discountMonthsSet != null) {
         	// entered pct 
            discountPctAnnualized += ((discountPctSet/12.00) * discountMonthsSet);
         }
         // ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO,'discountPctAnnualized2='+discountPctAnnualized));
         
         // Make sure it rounds up
         discountPctAnnualized = (discountPctAnnualized * 100.00).round(System.RoundingMode.HALF_UP);
         discountPctAnnualized = discountPctAnnualized/100.00;
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO,'discountPctAnnualized3='+discountPctAnnualized));
      } // if (discountFreeMonthsSet != null
      
   	  return true;
   } // checkDiscountInfo
   
} // class PriceHelper