/*
 *  This class will update fields on the Reference Opportunity Product custom object based on products added to an Opportunity.  This
 *  was done so Service Agreements can be generated using Conga from within Salesforce.  Called from OpptyLineItem.Trigger
 *
 *  History
 * ---------
 *  3/18/2019  Carrie Marciano Created
 *  8/1/2019   Brandon Vidro Made product selection dynamic w/ custom setting
 *  03/23/2020 Brandon Vidro Updated to include Oracle Quotes
 *  06/01/2020 Brandon Vidro Added logic for additional templates and Taxpay Decline Addendum
 *  06/29/2020 Brandon Vidro Commented out Taxpay Decline Addendum logic
 *  11/23/2020 Brandon Vidro Update to way ROPs are updated and deleted to fix recurring error
 *  02/15/2021 Carrie Marciano added OpptyMethods.SKIP_OPPTY_TRIGGERS = true before update opportunity to improve performance of OpptyLineItem
    07/17/2023 Dan Carmen      Refactor code
    08/29/2023 Carrie Marciano removed opptysProcessed check, it was preventing the ROP updates when selecting a subsequent quote to be primary, first the old products need to be deleted
                               that was populating the opptysProcessed list so when the new products were inserted, the list was not empty and the processLineItems code never ran
 
*/

 public without sharing class ReferenceOpportunityProduct {  
    //Holds values from Custom Setting - Service Agreement Template Mapping - Key = Product Code - Value = TemplateIDs
    public static Map<String, String> prodTempMapBundle = new Map<String, String>();
    //Holds values from Custom Setting - Service Agreement Template Mapping - Key = Product Code - Value = TemplateIDs Standalone (Template IDs for Standalone/A la carte Products) 
    public static Map<String, String> prodTempMapStandalone = new Map<String, String>();
    //Holds values from Custom Setting - Service Agreement Template Mapping - Key = Product Code - Value = Additional Template (Used for Tax Credit Services, ESR, Pay On Demand, Paychex Promise, Skylight)
    public static Map<String, String> prodTempMapAdditional = new Map<String, String>();
    //Holds values from Custom Setting - Service Agreement Template Mapping - Key = Product Code - Value = API Name 
    public static Map<String, String> productCodesMap = null;
    //Holds values from Custom Setting - Service Agreement Template Mapping - Key = Name - Value = TemplateIDs (Used for 3 Year Price Lock on Quote)
    public static Map<String, String> templateMap = new Map <String, String>();
     
     public static void checkServiceAgreeMapping() {
        if (productCodesMap == null) {
           productCodesMap = new Map<String,String>();
           ServiceAgreementTemplateMapping__c[] satms = ServiceAgreementTemplateMapping__c.getall().values();
      
           // setup the field mapping
           for (ServiceAgreementTemplateMapping__c satm : satms) {
               if (String.isNotBlank(satm.Product_Code__c) && String.isNotBlank(satm.API_Name__c)) {
                  productCodesMap.put(satm.Product_Code__c,satm.API_Name__c);
               }
               if (String.isNotBlank(satm.TemplateIDs__c)) {
                  templateMap.put(satm.Name, satm.TemplateIDs__c);
               }
               if (satm.Bundle__c == true) {
                   prodTempMapBundle.put(satm.Product_Code__c,satm.TemplateIDs__c); 
               } else {
                   prodTempMapStandalone.put(satm.Product_Code__c,satm.TemplateIDsStandalone__c); 
               }
            
               if (String.isNotBlank(satm.Additional_Template__c)) {
                   prodTempMapAdditional.put(satm.Product_Code__c, satm.Additional_Template__c);
               }
            
           } // for (ServiceAgreementTemplateMapping__c satm
           System.debug('ReferenceOpportunityProduct.checkServiceAgreeMapping productCodesMap='+productCodesMap.size()+' templateMap'+templateMap.size()+' prodTempMapBundle='+prodTempMapBundle.size());        

        } // if (productCodesMap == null
         
     } // checkServiceAgreeMapping
               
    public static Boolean hasRop = false;
              
    public static void processLineItems(Set<Id> opptyIdsToRefOpptyProduct){
       
        List<Reference_Opportunity_Product__c> ropsToInsert = new List<Reference_Opportunity_Product__c>();
        List<Reference_Opportunity_Product__c> ropsToUpdate = new List<Reference_Opportunity_Product__c>();
        List<Reference_Opportunity_Product__c> ropsToDelete = new List<Reference_Opportunity_Product__c>();
        
        checkServiceAgreeMapping();
        
        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        
      	//Get Opportunities
        Opportunity[] opptys = [Select Id
                      ,RecordType.Name
                      ,CongaTemplateIds__c
                      ,Primary_Oracle_Quote__r.Three_Year_Price_Lock__c
                      ,(select Id
                        ,OpportunityId 
                        ,Product2Id                 
                        ,Product2.Family
                        ,Product2.Name 
                        ,Product2.ProductCode
                        from OpportunityLineItems 
                        ORDER BY Product2.ProductCode)
                      ,(select Id
                        ,Opportunity__c
                        from Reference_Opportunity_Products__r LIMIT 1)
                      from Opportunity 
                      where id in :opptyIdsToRefOpptyProduct];
        system.debug('processLineItems ROP opptys: '+opptys.size());  
       
        for (Opportunity oppty: opptys) { 
            Set<String> bundleTemplateIdsSet = new Set<String>();
            Set<String> standaloneTemplateIdsSet = new Set<String>();
            Set<String> additionalTemplateIdsSet = new Set<String>();
            Set<String> opptyTemplateIdsSet = new Set<String>();
            Reference_Opportunity_Product__c foundRop;
            Set<String> fldsToSet = new Set<String>();
            
            if(oppty.Reference_Opportunity_Products__r.size() == 1) {
                hasRop = true;
                //existingRopToUpdate = oppty.Reference_Opportunity_Products__r;
                foundRop = oppty.Reference_Opportunity_Products__r[0];
                system.debug('processLineItems hasRop = true '+foundRop);
                // Reset all the fields to handle product changes
                for (String existingRopField: productCodesMap.values()){
                    if(existingRopField != null){
                        foundRop.put(existingRopField, false);
                    }
                } // for (String existingRopFields
            } else {
                foundRop = new Reference_Opportunity_Product__c (Opportunity__c = oppty.Id);
                system.debug('processLineItems hasRop = false '+foundRop);
            }
            system.debug('processLineItems oppty.OpportunityLineItems.size(): '+oppty.OpportunityLineItems.size());        	
        	for (OpportunityLineItem oli : oppty.OpportunityLineItems) {
                //oppLineItems.put(oli.Product2.ProductCode, oli.Product2.Name);
                system.debug('processLineItems oli.Product2.ProductCode: '+oli.Product2.ProductCode);
                if (String.isNotBlank(oli.Product2.ProductCode)){ 
                    if (productCodesMap.containsKey(oli.Product2.ProductCode)) {
                        String fldName = productCodesMap.get(oli.Product2.ProductCode);
                        foundRop.put(fldName,true);
                        // keep track if we're setting any fields. 
                        fldsToSet.add(fldName);
                        system.debug('processLineItems productCodesMap contains product '+fldName);
                    } // if (productCodesMap.containsKey

                    if (prodTempMapBundle.containsKey(oli.Product2.ProductCode)) {
                        bundleTemplateIdsSet.add(prodTempMapBundle.get(oli.Product2.ProductCode));  
                        system.debug('processLineItems productCodesMap contains product add to bundleTemplateIdsSet');
                    } 
                    if (prodTempMapStandalone.containsKey(oli.Product2.ProductCode)) {
                        standaloneTemplateIdsSet.add(prodTempMapStandalone.get(oli.Product2.ProductCode));
                        system.debug('processLineItems productCodesMap contains product add to standaloneTemplateIdsSet');
                    } 
                    if (prodTempMapAdditional.containsKey(oli.Product2.ProductCode)) {
                        additionalTemplateIdsSet.add(prodTempMapAdditional.get(oli.Product2.ProductCode));   
                        system.debug('processLineItems productCodesMap contains product add to additionalTemplateIdsSet');
                    } 

                }
            } //for (OpportunityLineItem oli : oppty.OpportunityLineItems)
            
            // if there are no matching products, we don't need the reference object?
            if(fldsToSet.isEmpty() && foundRop.Id != null) {
                ropsToDelete.add(foundRop);
                system.debug('processLineItems add to ropsToDelete');
            } else if (!fldsToSet.isEmpty()) {
                if (foundRop.id != null) {
                    ropsToUpdate.add(foundRop);
                    system.debug('processLineItems add to ropsToUpdate');
                } else {
                    ropsToInsert.add(foundRop);
                    system.debug('processLineItems add tp ropsToInsert');
                }
            }
            
            if(!bundleTemplateIdsSet.isEmpty()) {
                opptyTemplateIdsSet.addAll(bundleTemplateIdsSet);
            }
            if(bundleTemplateIdsSet.isEmpty() && !standaloneTemplateIdsSet.isEmpty()) {
                opptyTemplateIdsSet.addAll(standaloneTemplateIdsSet);
            }
            if(!additionalTemplateIdsSet.isEmpty()) {
                opptyTemplateIdsSet.addAll(additionalTemplateIdsSet);
            }
            if (!opptyTemplateIdsSet.isEmpty() && oppty.Primary_Oracle_Quote__r != null && oppty.Primary_Oracle_Quote__r.Three_Year_Price_Lock__c == true && templateMap.containsKey('Price Lock')) {
               opptyTemplateIdsSet.add(templateMap.get('Price Lock'));
            }

            String templateString = (opptyTemplateIdsSet.isEmpty() ? null : String.join(opptyTemplateIdsSet,','));
            system.debug('processLineItems oppty.CongaTemplateIds__c:'+oppty.CongaTemplateIds__c+' templateString: '+templateString);
            if (oppty.CongaTemplateIds__c == null || oppty.CongaTemplateIds__c != templateString) {
               oppty.CongaTemplateIds__c = templateString;
               oppsToUpdate.add(oppty);
            }

        } // for (Opportunity oppty: opptys)
        
        System.debug('processLineItems ropsToInsert='+ropsToInsert.size()+' ropsToUpdate='+ropsToUpdate.size()+' ropsToDelete='+ropsToDelete.size()+' oppsToUpdate='+oppsToUpdate.size());
        DmlHelper.performDML2(ropsToDelete, DmlHelper.DML_DELETE, 'ReferenceOpportunityProduct', 'processLineItems', 'deleting existing ROP records', true); 
		DmlHelper.performDML2(ropsToInsert, DmlHelper.DML_INSERT, 'ReferenceOpportunityProduct', 'processLineItems', 'inserting ROP records', true); 
        DmlHelper.performDML2(ropsToUpdate, DmlHelper.DML_UPDATE, 'ReferenceOpportunityProduct', 'processLineItems', 'updating ROP records', true);
        OpptyMethods.SKIP_OPPTY_TRIGGERS = true;
        DmlHelper.performDML2(oppsToUpdate, DmlHelper.DML_UPDATE, 'ReferenceOpportunityProduct', 'processLineItems', 'update related oppty records', true);
        OpptyMethods.SKIP_OPPTY_TRIGGERS = false;    
    } // processLineItems
     
} // class ReferenceOpportunityProduct