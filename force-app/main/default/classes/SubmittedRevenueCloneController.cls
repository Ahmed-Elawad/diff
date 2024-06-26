/*
 10/02/2019 Brandon Vidro  Created
 02/05/2019 Brandon Vidro  Uncheck Child Unit checkbox on original Opportunity after it has been cloned
 03/17/2022 Shilpa Govindarajulu	Removed SBQQ component references
 30/05/2022 Reetesh Pandey  Apex code scan resolution
 01/24/2023	Shilpa Govindarajulu	APR0143403 - Added method processSelected to update Date on all selected lines
*/

public without sharing class SubmittedRevenueCloneController {
    
    public List<Opportunity> opptyList {get; set;}
    public List<OpportunityLineItem> products {get; set;}
    public List<wrapper> oppWraps {get; set;}
    public List<wrapper> wrapOppLineItems {get; set;}
    public Opportunity clonedOpp {get; set;}
    public Boolean showSection1 {get; set;}
    public Boolean showSection2 {get; set;}
    public Map<Date, List<wrapper>> dateMapSelected = new Map<Date, List<wrapper>>();
    public Map<Date, List<wrapper>> dateMapNotSelected = new Map<Date, List<wrapper>>();
    public Map<date,Opportunity> revOnSubmitOppMap = new Map<Date, Opportunity>();
    public Map<date,Opportunity> revNotOnSubmitOppMap = new Map<Date, Opportunity>();
    public List<OpportunityTeamMember> teamMemberClones {get; set;}
    
    String OpptyId = ApexPages.CurrentPage().getParameters().get('id');
    // Apex code scan 
    String creatableOppFields = ObjectHelper.getCreatableFields('Opportunity','id=\''+String.escapeSingleQuotes(OpptyId) +'\'');
    //Removed , SBQQ__QuoteLine__r.SBQQ__Group__r.Id, SBQQ__QuoteLine__r.SBQQ__Group__r.SBQQ__Account__c from query string as part of SBQQ package removal
    String queryString = creatableOppFields.substringBefore('FROM')
        +',(Select Id , OpportunityId, UserId, Name, PhotoUrl, TeamMemberRole, OpportunityAccessLevel, NSS_Source__c, NSS_Team__c, CommissionEnd__c, CommissionStart__c, Prospect_Ownership__c from OpportunityTeamMembers)'       
        +', (Select Quantity, Payroll_Unit__c, Setup_Fee__c, Total_Calced__c,  Setup_Fee_Original__c, PricebookEntryId, QuoteLineGroupAcct__c, QuoteLineGroupAcctName__c from OpportunityLineItems)'
        +' from Opportunity where Id=:OpptyId limit 1';       
    Opportunity originalOpportunity = (Opportunity)Database.query(queryString);
    
    public SubmittedRevenueCloneController() {
        showSection1 = true;
        opptyList = [select Id, Name, Account.Name, CloseDate, Payroll_Unit__c, Child_Unit__c, Pricebook2Id, Amount,
                     (Select Quantity, PricebookEntry.Name, PricebookEntry.Pricebook2Id, PricebookEntry.Product2.Family, PricebookEntry.Product2.ProductCode From OpportunityLineItems)
                     From Opportunity Where Id = :OpptyId];
        
        products = [SELECT Id,
                    Product2.Name,
                    Quantity, 
                    Product_Parent_Child_Link__c,
                    Frequency__c,
                    Unit__c,
                    ServiceDate,
                    Status__c,
                    //SBQQ__QuoteLine__c,
                    TotalPrice,
                    Payroll_Unit__c,
                    ProductCode, PricebookEntryId FROM OpportunityLineItem WHERE OpportunityId = :opptyId];
        
        teamMemberClones = [SELECT Id,
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
        
        if (wrapOppLineItems == null) {
            wrapOppLineItems = new List<wrapper>();
            for(OpportunityLineItem oli: products) {
                wrapOppLineItems.add(new wrapper(oli));
            }
        }
        
    }//SubmittedRevenueCloneController

    public PageReference cancel() {
        PageReference page = new PageReference('/'+opptyId);
        page.setRedirect(true);
        return page;
    }//cancel
    
    public PageReference cloneOpportunity() {
        processOpportunityClones();
        PageReference pageref = new PageReference('/'+clonedOpp.Id);
        pageref.setRedirect(true);
        return pageref;
    }//cloneOpportunity

    public void processSelected() {
        String strCloseDate = ApexPages.currentPage().getParameters().get('strCloseDateName');
        Date closeDate = Date.valueof(strCloseDate);
        for (wrapper wrap : wrapOppLineItems) {
            if(wrap.selected == true) {
                wrap.closeDate = closeDate;
            }
        }
    }
    
    public void previewOpportunityClones() {
        showSection1 = false;
        showSection2 = true;
        
        for (wrapper wrap : wrapOppLineItems) {
                                    
            if(wrap.hasRevOnSubmit == true) {
                if(dateMapSelected.containsKey(wrap.closeDate)) {
                    List<Wrapper> currList = dateMapSelected.get(wrap.closeDate);
                    currList.add(wrap);
                    dateMapSelected.put(wrap.closeDate, currList);
                } else {
                    dateMapSelected.put(wrap.closeDate, new List<Wrapper>{wrap});
                }
            } else {
                if(dateMapNotSelected.containsKey(wrap.closeDate)) {
                    List<Wrapper> currList = dateMapNotSelected.get(wrap.closeDate);
                    currList.add(wrap);
                    dateMapNotSelected.put(wrap.closeDate, currList);
                } else {
                    dateMapNotSelected.put(wrap.closeDate, new List<Wrapper>{wrap});
                }
            } 
        }

        for(Date dateKey : dateMapSelected.keySet()){
            clonedOpp = originalOpportunity.clone(false, true, false, false);
            clonedOpp.StageName = 'Sold - Submitted';
            clonedOpp.CloseDate = dateKey;
            clonedOpp.Primary_Opportunity__c=originalOpportunity.Id;//Added by Jaipal for user story
            revOnSubmitOppMap.put(clonedOpp.closeDate,clonedOpp);
        }
        for(Date dateKey : dateMapNotSelected.keySet()){
            clonedOpp = originalOpportunity.clone(false, true, false, false);
            clonedOpp.StageName = 'Sold - Submitted';
            clonedOpp.CloseDate = dateKey;
            clonedOpp.Primary_Opportunity__c=originalOpportunity.Id; //Added by Jaipal for user story
            revNotOnSubmitOppMap.put(clonedOpp.closeDate,clonedOpp);
        }
                
        oppWraps = new List<wrapper>();
        
        for(Opportunity opp:revOnSubmitOppMap.values()){
            oppWraps.add(new wrapper(opp, true));
        }
        for(Opportunity opp: revNotOnSubmitOppMap.values()){
            oppWraps.add(new wrapper(opp, false));
        }
        
    }//previewOpportunityClones
    
    public void processOpportunityClones() {
        Opportunity[] oppsToInsert = new Opportunity[]{};
        originalOpportunity.Payroll_Unit__c = false;
        originalOpportunity.Child_Unit__c = false;
        OpportunityLineItem[] olisToInsert = new OpportunityLineItem[]{};
        OpportunityTeamMember[] otmsToInsert = new OpportunityTeamMember[]{};
        OpportunityLineItem[] subRevAdjsToInsert = new OpportunityLineItem[]{};
        Product2[] submittedRevenueAdjustment = new Product2[]{};
        
        for(Opportunity opp:revOnSubmitOppMap.values()){
            oppsToInsert.add(opp);
        }
        for(Opportunity opp:revNotOnSubmitOppMap.values()){
            oppsToInsert.add(opp);
        }
        insert oppsToInsert;
        update originalOpportunity;
        
        for(date runDate: dateMapSelected.keySet()){
            for(wrapper wrap: dateMapSelected.get(runDate)){
                OpportunityLineItem newProd = wrap.oppLineItem.clone(false, false, false, false);
                newProd.OpportunityId = revOnSubmitOppMap.get(runDate).Id;
                newProd.TotalPrice = wrap.oppLineItem.TotalPrice;
                newProd.ServiceDate = wrap.closeDate;
                newProd.Payroll_Unit__c = wrap.oppLineItem.Payroll_Unit__c;
                newProd.Status__c = wrap.oppLineItem.Status__c;
                //newProd.SBQQ__QuoteLine__c = wrap.oppLineItem.SBQQ__QuoteLine__c;
                olisToInsert.add(newProd);
            }
            for(OpportunityTeamMember oT:teamMemberClones){
                OpportunityTeamMember newTeam = oT.clone(false, false, false, false);
                newTeam.OpportunityId = revOnSubmitOppMap.get(runDate).Id;
                otmsToInsert.add(newTeam);
            }
        }
        for(date runDate: dateMapNotSelected.keySet()){
            for(wrapper wrap: dateMapNotSelected.get(runDate)){
                OpportunityLineItem newProd = wrap.oppLineItem.clone(false, false, false, false);
                newProd.OpportunityId = revNotOnSubmitOppMap.get(runDate).Id;
                newProd.TotalPrice = wrap.oppLineItem.TotalPrice;
                newProd.ServiceDate = wrap.closeDate;
                newProd.Payroll_Unit__c = wrap.oppLineItem.Payroll_Unit__c;
                newProd.Status__c = wrap.oppLineItem.Status__c;
                //newProd.SBQQ__QuoteLine__c = wrap.oppLineItem.SBQQ__QuoteLine__c;
                olisToInsert.add(newProd);
            }
            for(OpportunityTeamMember oT:teamMemberClones){
                OpportunityTeamMember newTeam = oT.clone(false, false, false, false);
                newTeam.OpportunityId = revNotOnSubmitOppMap.get(runDate).Id;
                otmsToInsert.add(newTeam);
            }
        }
        if(!olisToInsert.isEmpty()){
            insert olisToInsert;
        }
        if(!otmsToInsert.isEmpty()){
            insert otmsToInsert;
        }
        
        submittedRevenueAdjustment = [SELECT Id from Product2 where ProductCode = 'SubRevAdj' LIMIT 1];
                
        for(Opportunity opp:oppsToInsert) {
            if(opp.Payroll_Unit__c == true && !submittedRevenueAdjustment.isEmpty()) {
                OpportunityLineItem subRevAdj = new OpportunityLineItem();
                subRevAdj.OpportunityId = opp.Id;
                subRevAdj.TotalPrice = 0;
                subRevAdj.Quantity = 1;
                subRevAdj.Status__c = opp.StageName;
                subRevAdj.Product2Id = submittedRevenueAdjustment.get(0).Id;
                subRevAdj.ServiceDate = opp.CloseDate;
                subRevAdjsToInsert.add(subRevAdj);
            }
        }
        
        if(!subRevAdjsToInsert.isEmpty()) {
            insert subRevAdjsToInsert;
        }        
    }//processOpportunityClones
    
    public class wrapper {
        public OpportunityLineItem oppLineItem {get; set;}
        public Opportunity oppty {get; set;}
        public Boolean hasRevOnSubmit {get; set;}
        public Boolean hasRevOnSubmitOpp {get; set;}
        public Boolean payrollUnit {get; set;}
        public Boolean childUnit {get; set;}
        public Date closeDate {get; set;}
        public Boolean selected {get; set;}
        
        public wrapper(OpportunityLineItem oli) {
            oppLineItem = oli;
            hasRevOnSubmit = false;
            payrollUnit = false;
            childUnit = false;
            closeDate = Date.today();
            selected = false;
        }
        public wrapper(Opportunity opp, Boolean hasRev){
            oppty = opp;
            hasRevOnSubmitOpp = hasRev;
        }        
    }//wrapper
    
}