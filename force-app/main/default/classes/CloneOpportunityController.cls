/*
    08/17/2018 Lynn Michels  changed to without sharing
  12/17/2018 Josh Cartwright updated to fix contact role and oppty team cloning issues 
    02/24/2020 Dan Carmen      Increment API to 48
  3/16/2020  Matthew Fritschi Updated to also query Oracle Quote Prospect Clients on Line Items
  04/02/2020 Josh Cartwright updated clonedopp stagename to a label 
  04/09/2020 Matt Fritschi  Parent Opportunity now shown on Cloned Opps
  04/22/2020 Matt Fritschi  Queries for Parent Opportunity even if the User doesn't have read/write access
  04/27/2020 Matt Fritschi  Added try/catch block for excluding Oracle Fields
  10/22/2020 Carrie Marciano  added OpptyMethods.SKIP_OPPTY_TRIGGERS=true; before inserting clonedOpp to prevent account ownership from changing to Sales Assistant incorrectly
  07/21/2021 Carrie Marciano   added call to OpptyMethods.setForecastProbabilityFromOppStage before inserting cloned opportunity to set forecast category correctly
  03/30/2022 Susmitha Somavarapu Request to have Primary Competition copied over when cloning and splitting opportunities
  30/05/2022 Reetesh Pandey  Apex code scan resolution
  06/29/2022 Jermaine Stukes	Added ProductWrapper and ability to select product to clone
  09/04/2023 Reetesh Pandey   APR0151759 -Clone Non Payroll and and Payroll Units 
  09/22/2023 Lalan Kumar      APR0135718 : Updating Auto_Close_Date__c in Cloned Oppty
*/

public without sharing class CloneOpportunityController {

    String OpptyId = ApexPages.CurrentPage().getParameters().get('id'); 
    String cloneHandbookContactParam = ApexPages.CurrentPage().getParameters().get('cloneHandbook'); 
    
    public Opportunity clonedOpp {get; set;}
    public Boolean cloneWithProducts {get; set;}
    public Boolean cloneHandbookContact {get; set;}
    //Reetesh
    public Decimal payrolUnitsOpp {get; set;}
    public Decimal nonpayrolUnitsOpp {get; set;}
    public Decimal netrev {get; set;}
    
   // public Decimal employees {get; set;}
   // public String status {get; set;}
   // public String oppOwner {get; set;}
    
    List<OpportunityTeamMember> teamMemberClones;
    List<OpportunityLineItem> lineItemClones;
    List<OpportunityContactRole> roleClones; 
    string createStatus = label.Opportunity_Create; 
    public Boolean showProducts {get; set;}
    public List<ProductWrapper> productWrapperList{get; set;}
    public class ProductWrapper {  
        public String productName{get; set;}
        public Boolean selected {get; set;}
        //Added Reetesh 
        //Revenue //Payroll Units //Non Payroll Units //Employees //Status //Opportunity Owner        
        public Decimal payrolUnit {get; set;}
        public Decimal nonpayrolUnit {get; set;}
        public Decimal totalprice {get; set;}
        
        public ProductWrapper(String pName){
            this.productName = pName;
            this.selected = true;
        }     
    }

    public CloneOpportunityController() {
        setUpClonedOpportunity();
    }

    public void setUpClonedOpportunity(){
        
        cloneWithProducts = false;
        cloneHandbookContact = false;
        // Apex code scan
        String creatableOppFields = ObjectHelper.getCreatableFields('Opportunity','id=\''+String.escapeSingleQuotes(OpptyId) +'\'');
        //Removed fields - SBQQ__QuoteLine__r.SBQQ__Group__r.Id, SBQQ__QuoteLine__r.SBQQ__Group__r.SBQQ__Account__c, from below queryString
        String queryString = creatableOppFields.substringBefore('FROM')
            +',(Select Id , OpportunityId, UserId, Name, PhotoUrl, TeamMemberRole, OpportunityAccessLevel, NSS_Source__c, NSS_Team__c, CommissionEnd__c, CommissionStart__c, Prospect_Ownership__c from OpportunityTeamMembers)'       
            +', (Select Quantity, Payroll_Unit__c,Non_Payroll_Unit__c,TotalPrice, Setup_Fee__c, Total_Calced__c,  Setup_Fee_Original__c, PricebookEntryId, QuoteLineGroupAcct__c, ListPrice, UnitPrice, QuoteLineGroupAcctName__c, Oracle_Quote_Line__r.Prospect_Client__c from OpportunityLineItems)';
        if(!queryString.contains('Primary_Opportunity__c'))
        {
            queryString = queryString + ', Primary_Opportunity__c';
        }
         /*APR0135718 : Added Auto_Close_Date__c in Oppty Query*/
         if(!queryString.contains('Auto_Close_Date__c'))
        {
            queryString = queryString + ', Auto_Close_Date__c';
        }
        queryString = queryString +' from Opportunity where Id=:OpptyId limit 1';
        Opportunity originalOpportunity = (Opportunity)Database.query(queryString);
        
        //JC clonedOpp = originalOpportunity.clone(false, True, false, false);
        clonedOpp = originalOpportunity.clone(false, true, false, false);
        clonedOpp.OppSource__c = 'Lightning Clone';
        clonedOpp.StageName = createStatus;
        clonedOpp.OpportunityType__c = '';
        /*APR0135718 : Updating Auto_Close_Date__c in Cloned Oppty*/
        if(originalOpportunity.Auto_Close_Date__c!=null){
           clonedOpp.Auto_Close_Date__c = originalOpportunity.Auto_Close_Date__c; 
        }
        if(originalOpportunity.Primary_Opportunity__c == null)
        {
            clonedOpp.Primary_Opportunity__c = originalOpportunity.Id;
        }
        else {
            clonedOpp.Primary_Opportunity__c = OriginalOpportunity.Primary_Opportunity__c;
        }
        //JC new Code start 
         List<OpportunityLineItem> products = [SELECT Id,
                                                  Name,
                                                  Quantity, 
                                                  Product2Id,
                                                  Product2.Name,
                                                  Product_Parent_Child_Link__c,
                                                  Frequency__c,
                                                  Unit__c,
                                                   ProductCode, 
                                                  totalPrice, 
                                                   PricebookEntryId,
                                                // Added Reetesh
                                                Opportunity.Amount,
                                               Opportunity.Payroll_Units__c,
                                               Opportunity.Non_Payroll_Units__c,
                                               Opportunity.Total_Employees__c,
                                               Opportunity.Employees_Paid_Per_Payroll__c,
                                               Opportunity.StageName,
                                               Opportunity.Owner.Name, 
                                               Payroll_Unit__c,
                                               Non_Payroll_Unit__c
                                                  FROM OpportunityLineItem WHERE OpportunityId = :originalOpportunity.Id];
        if(products != null){
        lineItemClones = products; 
        }//if 
        
      //JC list of oppty contact role to clone
         List<OpportunityContactRole> oCR = [SELECT Id,
                                                  ContactId,
                                                  IsPrimary, 
                                                  OpportunityId,
                                                  Role
                                                  FROM OpportunityContactRole WHERE OpportunityId = :originalOpportunity.Id];
        if(oCR != null){
        roleClones = oCR; 
        }//if         
        
      //JC list of oppty team to clone
         List<OpportunityTeamMember> oTM = [SELECT Id,
                                                  Name,
                                                  OpportunityAccessLevel, 
                                                  OpportunityId,
                                                  PhotoURL,
                                                TeamMemberRole, 
                                                UserId,
                                                  CommissionEnd__c,
                                                   CommissionStart__c, 
                                                  NSS_Source__c,
                                                  NSS_Team__c,
                                                 Prospect_Ownership__c
                                            
                                                  FROM OpportunityTeamMember WHERE OpportunityId = :originalOpportunity.Id];
        if(oCR != null){
        teamMemberClones = oTM; 
        }//if                 
/*jc
        teamMemberClones = new List<OpportunityTeamMember>();
        for(OpportunityTeamMember teamMember : originalOpportunity.OpportunityTeamMembers){
            teamMemberClones.add(teamMember.clone(false, true, false, false));
        }*/ 
/*JC 
        lineItemClones = new List<OpportunityLineItem>();

        for(OpportunityLineItem lineItem : originalOpportunity.OpportunityLineItems){
            lineItemClones.add(lineItem.clone(false, true, false, false));
            system.debug('JC lineItemClones' + lineItemClones); 
        }*/

    
    }

    public PageReference cloneOpportunity(){

        if(clonedOpp != null){
            if(!cloneHandbookContact){
                clonedOpp.Handbook_Contact__c = null;
            }
            //set owner afterwards to ensure all fields can be set with given user's permissions (CampaignId)
            Id tempOwner = clonedOpp.OwnerId;
            system.debug('PageReference cloneOpportunity clonedOpp.OwnerId set to tempOwner: ' + tempOwner);
            clonedOpp.OwnerId = UserInfo.getUserId();
            
            
            system.debug('PageReference cloneOpportunity clonedOpp.OwnerId: ' + clonedOpp.OwnerId);
            clonedOpp = clearExcludedCloneFields(clonedOpp);
            OpptyMethods.SKIP_OPPTY_TRIGGERS=true;
            system.debug('PageReference cloneOpportunity clonedOpp.StageName: ' + clonedOpp.StageName+' clonedOpp.ForecastCategoryName: '+clonedOpp.ForecastCategoryName);
            OpptyMethods.setForecastProbabilityFromOppStage(new Opportunity[]{clonedOpp});
            insert clonedOpp;
               // cloning competitors from old opportunity to new opportunity(APR0131946)	
            List<Competitor__c> oppcomtToadd = new List<Competitor__c>() ;	
            Competitor__c neRec;
			// Apex Code Scan
            OpptyId= String.escapeSingleQuotes(OpptyId);			
            for (Competitor__c compRec  : [select Id,Name,Primary__c, PickListValue__c from Competitor__c where Opportunity__c = :OpptyId]) {	
             neRec = compRec.clone(false , false , false , false ) ; 	
             neRec.Opportunity__c = clonedOpp.id; 	
             oppcomtToadd.add(neRec); 	
            }	
            insert oppcomtToadd; 
         
            insertTeamMemberClones();
            insertRoleClones(); 
            insertLineItemClones();
            clonedOpp.OwnerId= tempOwner;
            //Reetesh - If need to update in Cloned Opp
            clonedOpp.Payroll_Units__c = payrolUnitsOpp;
            clonedOpp.Non_Payroll_Units__c = nonpayrolUnitsOpp;
            clonedOpp.Amount = netrev;
            system.debug('PageReference cloneOpportunity set back to tempOwner clonedOpp.OwnerId: ' + clonedOpp.OwnerId);            
            update clonedOpp;
        }

        PageReference pageref = new PageReference('/'+clonedOpp.Id);
        pageref.setRedirect(true);
        return pageref;

    }
/*
    private void insertTeamMemberClones(){

        for(OpportunityTeamMember teamMember : teamMemberClones){
            teamMember.OpportunityId = clonedOpp.Id;
        }

        if(teamMemberClones.size() > 0){
            insert teamMemberClones;
        }
    }*/
    
    private void insertTeamMemberClones(){
        if(teamMemberClones !=null ){  
   
     list<OpportunityTeamMember> newTeamList = new List<OpportunityTeamMember>();
        
            for (OpportunityTeamMember oT:teamMemberClones) {
              OpportunityTeamMember newTeam = oT.clone(false, false, false, false);
         newTeam.OpportunityId = clonedOpp.id;
                newTeamList.add(newTeam);
            }//for
            if(newTeamList.size()>0){
                insert(newTeamList);
            }//if 
            system.debug('newTeamList ' + newTeamList);          
        }    
    }//insertTeamMemberClones

   private void insertRoleClones(){
        if(roleClones !=null ){      
         list<OpportunityContactRole> newRoleList = new List<OpportunityContactRole>();
        
            for (OpportunityContactRole oCR:roleClones ) {
              OpportunityContactRole newRoles = oCR.clone(false, false, false, false);
         newRoles.OpportunityId = clonedOpp.id;
                newRoleList.add(newRoles);
            }//for
            if(newRoleList.size()>0){
                insert(newRoleList);
            }//if 
            system.debug('newRoleList ' + newRoleList);          
        }    
    }//insertRoleClones

    public void updateProductDisplay(){
        //Reetesh
        ProductWrapper pdWrap;
        productWrapperList = new List<ProductWrapper>();
        if(cloneWithProducts && lineItemClones !=null ){
            //Reetesh
            
            for (OpportunityLineItem prod:lineItemClones) {
                //Reetesh Commented below line
               // productWrapperList.add(new ProductWrapper(prod.Product2.Name));
                 pdWrap = new ProductWrapper(prod.Product2.Name);
                 pdWrap.totalprice = prod.TotalPrice;
                 pdWrap.payrolUnit = prod.Payroll_Unit__c;
                 pdWrap.nonpayrolUnit = prod.Non_Payroll_Unit__c;
               //  pdWrap.employees = prod.Opportunity.Total_Employees__c;
               //  pdWrap.status = prod.Opportunity.StageName;
               //  pdWrap.oppOwner = prod.Opportunity.Owner.Name;
                     
                 /*  this.revenue = ApexPages.CurrentPage().getParameters().get('Revenue__c');
            this.payrolUnits = ApexPages.CurrentPage().getParameters().get('Payroll_Units__c');
            this.nonpayrolUnits = ApexPages.CurrentPage().getParameters().get('Non_Payroll_Units__c');
            this.employees = ApexPages.CurrentPage().getParameters().get('Total_Employees__c');
            this.status = ApexPages.CurrentPage().getParameters().get('StageName');
            this.oppOwner = ApexPages.CurrentPage().getParameters().get('Owner.Name');
          */
                 productWrapperList.add(pdWrap);
            }
            showProducts = true;
        }else{
            showProducts = false;
        }
    }
    private void insertLineItemClones(){
        if(cloneWithProducts && lineItemClones !=null ){  
            
            List<OpportunityLineItem> newProdList = new List<OpportunityLineItem>();
            Map<String,ProductWrapper> productMap;
            if(productWrapperList!=null){
                productMap = new Map<String,ProductWrapper>();
                for(ProductWrapper pw : productWrapperList){
                    productMap.put(pw.productName, pw);
                }
            }
            payrolUnitsOpp = 0.0;
            nonpayrolUnitsOpp = 0.0;
            netrev = 0.0;
            for (OpportunityLineItem prod:lineItemClones) {
            //  Boolean addProduct = productWrapperList == null ? true : productMap.get(prod.Product2.Name);
            //  Reetesh
               Boolean addProduct = productWrapperList == null ? true : productMap.get(prod.Product2.Name).selected;
                if(addProduct){
                    OpportunityLineItem newProd = prod.clone(false, false, false, false);
                    newProd.OpportunityId = clonedOpp.id;
                    //Reetesh
                    newProd.Payroll_Unit__c= (newProd.Payroll_Unit__c != productMap.get(prod.Product2.Name).payrolUnit) ? productMap.get(prod.Product2.Name).payrolUnit : newProd.Payroll_Unit__c;
                    newProd.Non_Payroll_Unit__c= (newProd.Non_Payroll_Unit__c != productMap.get(prod.Product2.Name).nonpayrolUnit) ? productMap.get(prod.Product2.Name).nonpayrolUnit : newProd.Non_Payroll_Unit__c;
                    newProd.TotalPrice= (newProd.TotalPrice != productMap.get(prod.Product2.Name).totalprice) ? productMap.get(prod.Product2.Name).totalprice : newProd.TotalPrice;
                    System.debug('payrolUnitsOpp > ' + payrolUnitsOpp+'---'+newProd.Payroll_Unit__c);
                    System.debug('nonpayrolUnitsOpp > ' + nonpayrolUnitsOpp+'---'+newProd.Non_Payroll_Unit__c);
                    payrolUnitsOpp = payrolUnitsOpp + newProd.Payroll_Unit__c;
                    nonpayrolUnitsOpp = nonpayrolUnitsOpp + newProd.Non_Payroll_Unit__c;
                    netrev = netrev + newProd.TotalPrice;
                    newProdList.add(newProd);
                }//for
            }
            if(!newProdList.isEmpty()){
                insert(newProdList);
            }//if 
            system.debug('newProdList ' + newProdList); 
        }
    }//insertLineItemClones
        /*JC 
 * system.debug('JC cloneWithProducts '+ cloneWithProducts); 
        if(cloneWithProducts){
            for(OpportunityLineItem lineItem : lineItemClones){
                lineItem.OpportunityId = clonedOpp.Id;
            }

            if(lineItemClones.size() > 0){
                insert lineItemClones;
                system.debug('JC lineItemClones '+ lineItemClones);
                
            }
        }

    } */ 


    private Opportunity clearExcludedCloneFields(Opportunity opp){

        Set<String> objectFields = Schema.SObjectType.Opportunity.fields.getMap().keySet();

        String fieldsToExcludeString = Label.Clone_Opportunity_Excluded_Fields;
        List<String> fieldsToExclude = fieldsToExcludeString.split(',');

        for(Integer i = 0; i < fieldsToExclude.size(); i++){
            System.debug('field to exclude: ' + fieldsToExclude.get(i));
            if(objectFields.contains(fieldsToExclude.get(i).toLowerCase())){
                Try{
                    System.debug('field value to exclude prior: ' + opp.get(fieldsToExclude.get(i)));
                  opp.put(fieldsToExclude.get(i), null);
                  System.debug('field value to exclude: ' + opp.get(fieldsToExclude.get(i)));
                }
                catch(Exception e)
                {
                    System.debug(e);
                }
            }
        }

        return opp;
    }

}