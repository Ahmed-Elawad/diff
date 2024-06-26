public with sharing class MMSProposalHorizontalGroupController {
    public MMSProposalHorizontalGroupController(){}
  /*  public String qId {get; set;}

    public MMSProposalHorizontalGroupController() {
         qId = (Id)ApexPages.currentPage().getParameters().get('qid');
         System.debug('***FRL*** after currentPage().getParameters qId: ' + qId);
    }
    //prepare list by GROUP & PRICING TYPE
    public List<GroupLine> groupLines{
        get{
            List<GroupLine> groupLines = new List<GroupLine>();
            Decimal tempPTLtotal = 0;
            Decimal tempMonthPTLtotal = 0;
            Decimal tempNetTotal = 0;
            
            if(qId != null){
                List<SBQQ__QuoteLine__c> quoteLines = [SELECT Id, Name, Product_Name_and_Description__c, SBQQ__Quantity__c, SBQQ__ListPrice__c, SBQQ__NetTotal__c, 
                                                       Pricing_Type__c, SBQQ__Group__c, SBQQ__Group__r.Name, Setup_Fee__c, PayrollFrequency__c, Number_of_Payperiods__c,
                                                       SBQQ__RequiredBy__c, SBQQ__Bundle__c, SBQQ__RequiredBy__r.SBQQ__Product__c, SBQQ__Product__c, SBQQ__Product__r.Name 
                                                       FROM SBQQ__QuoteLine__c 
                                                       Where SBQQ__Quote__c=:qId
                                                       AND (Pricing_Type__c IN ('Per Pay Period','Annual','One-time') OR (Pricing_Type__c='Monthly' AND Monthly_Fee_Line__c=TRUE)) 
                                                       ORDER BY SBQQ__Group__c,Pricing_Type__c,PayrollFrequency__c,Required_By_Product__c ASC NULLS FIRST];
                if(quoteLines != null && !quoteLines.isEmpty()){
                    for(SBQQ__QuoteLine__c quoteLine : quoteLines){
                        System.debug('***FRL*** check of  quoteLine.SBQQ__Group__c = ' + quoteLine.SBQQ__Group__c);
                        if(groupLines.isEmpty() || groupLines.get(groupLines.size()-1).groupId != quoteLine.SBQQ__Group__c){
                            GroupLine groupLine = createGroupLine(quoteLine);
                            PricingTypeLine pricingTypeLine = createPricingTypeLine(quoteLine);
                            groupLine.pricingTypeLines.add(pricingTypeLine);
                            groupLines.add(groupLine);
                            tempMonthPTLtotal += quoteLine.SBQQ__NetTotal__c;
                        }else{
                            GroupLine groupLine = groupLines.get(groupLines.size()-1);
                            if(quoteLine.Pricing_Type__c == 'One-time' && quoteLine.Setup_Fee__c){
                                groupLine.oneTimeSetupFeeNetTotal = groupLine.oneTimeSetupFeeNetTotal+quoteLine.SBQQ__NetTotal__c;
                            }
                            if(groupLine.pricingTypeLines.get(groupLine.pricingTypeLines.size()-1).pricingType != quoteLine.Pricing_Type__c){
                                System.debug('***FRL*** check of Pricing Type comparison: ' + groupLine.pricingTypeLines.get(groupLine.pricingTypeLines.size()-1).pricingType);
                                System.debug('***FRL*** check of quoteLine.Pricing_Type__c = ' + quoteLine.Pricing_Type__c);
                                PricingTypeLine pricingTypeLine = createPricingTypeLine(quoteLine);
                                groupLine.pricingTypeLines.add(pricingTypeLine);
                                tempNetTotal = 0;
                            }
                            else{
                                if(quoteLine.Pricing_Type__c == 'Per Pay Period' || (quoteLine.Pricing_Type__c == 'Annual' && quoteLine.SBQQ__Product__r.Name.containsIgnoreCase('YE Processing- Forms W2/1099'))){
                                    if(groupLine.pricingTypeLines.get(groupLine.pricingTypeLines.size()-1).payRollFrequency != quoteLine.PayrollFrequency__c){
                                        PricingTypeLine pricingTypeLine = createPricingTypeLine(quoteLine);
                                        pricingTypeLine.showHeader = false;
                                        pricingTypeLine.showFrequency = false;
                                        groupLine.pricingTypeLines.add(pricingTypeLine);
                                    }
                                    else{
                                        //groupLine.pricingTypeLines.get(groupLine.pricingTypeLines.size()-1).total += quoteLine.SBQQ__NetTotal__c;
                                        tempPTLtotal += quoteLine.SBQQ__NetTotal__c;
                                        if (quoteLine.Pricing_Type__c == 'Per Pay Period' && quoteLine.Number_of_Payperiods__c > 0) {
                                             groupLine.pricingTypeLines.get(groupLine.pricingTypeLines.size()-1).total = tempPTLtotal / quoteLine.Number_of_Payperiods__c;
                                        }
                                        if(quoteLine.SBQQ__RequiredBy__c == null && quoteLine.SBQQ__Bundle__c){
                                            groupLine.pricingTypeLines.get(groupLine.pricingTypeLines.size()-1).quoteLines.add(createQuoteLine(quoteLine));
                                        }else{
                                            List<QuoteLine> perPayPeriodQuoteLines = groupLine.pricingTypeLines.get(groupLine.pricingTypeLines.size()-1).quoteLines;
                                            for(QuoteLine perPayPeriodQuoteLine : perPayPeriodQuoteLines){
                                                if(perPayPeriodQuoteLine.productIds.contains(quoteLine.SBQQ__RequiredBy__r.SBQQ__Product__c)){
                                                    System.debug('***FRL*** perPayPeriodQuoteLines processing - quoteLine.Product_Name_and_Description__c = ' + quoteLine.Product_Name_and_Description__c);
                                                    if(quoteLine.Product_Name_and_Description__c.containsIgnoreCase('Base') || quoteLine.Product_Name_and_Description__c.equalsIgnoreCase('Direct Deposit') || quoteLine.Product_Name_and_Description__c.equalsIgnoreCase('Payroll Delivery') || quoteLine.Product_Name_and_Description__c.equalsIgnoreCase('Taxpay') ){
                                                        perPayPeriodQuoteLine.baseFeeUnitPrice += quoteLine.SBQQ__ListPrice__c;
                                                    }else{
                                                        perPayPeriodQuoteLine.unitPrice += quoteLine.SBQQ__ListPrice__c;
                                                    }
                                                    perPayPeriodQuoteLine.productIds.add(quoteLine.SBQQ__Product__c);
                                                    //perPayPeriodQuoteLine.netTotal += quoteLine.SBQQ__NetTotal__c;
                                                    System.debug('***FRL*** perPayPeriodQuoteLines processing - quoteLine.Pricing_Type__c = ' + quoteLine.Pricing_Type__c);
                                                    System.debug('***FRL*** perPayPeriodQuoteLines processing - quoteLine.SBQQ__Product__r.Name = ' + quoteLine.SBQQ__Product__r.Name);
                                                    System.debug('***FRL*** perPayPeriodQuoteLines processing - quoteLine.SBQQ__Product__c = ' + quoteLine.SBQQ__Product__c);
                                                    tempNetTotal += quoteLine.SBQQ__NetTotal__c;
                                                    if (quoteLine.Pricing_Type__c == 'Per Pay Period' && quoteLine.Number_of_Payperiods__c > 0) {
                                                         perPayPeriodQuoteLine.netTotal = tempNetTotal / quoteLine.Number_of_Payperiods__c;
                                                    }
                                                    else {
                                                        perPayPeriodQuoteLine.netTotal = tempNetTotal;
                                                        groupLine.pricingTypeLines.get(groupLine.pricingTypeLines.size()-1).total += quoteLine.SBQQ__NetTotal__c;
                                                        System.debug('***FRL*** AnnualQuoteLines processing - tempNetTotal = ' + tempNetTotal);
                                                        System.debug('***FRL*** AnnualQuoteLines processing - groupLine.pricingTypeLines... = ' + groupLine.pricingTypeLines.get(groupLine.pricingTypeLines.size()-1).total);
                                                    }
                                                    System.debug('***FRL*** perPayPeriodQuoteLines processing - tempNetTotal = ' + tempNetTotal);
                                                    System.debug('***FRL*** perPayPeriodQuoteLines processing - quoteLine.SBQQ__NetTotal__c = ' + quoteLine.SBQQ__NetTotal__c);
                                                    System.debug('***FRL*** perPayPeriodQuoteLines processing - perPayPeriodQuoteLine.netTotal = ' + perPayPeriodQuoteLine.netTotal);
                                                    System.debug('***FRL*** perPayPeriodQuoteLines processing - quoteLine.Number_of_Payperiods__c = ' + quoteLine.Number_of_Payperiods__c);
                                                    break;
                                                }
                                            }
                                        }
                                   }
                                }
                            else{
                                    //groupLine.pricingTypeLines.get(groupLine.pricingTypeLines.size()-1).total += quoteLine.SBQQ__NetTotal__c;
                                    tempMonthPTLtotal += quoteLine.SBQQ__NetTotal__c;
                                    if (quoteLine.Pricing_Type__c == 'Monthly' && quoteLine.SBQQ__NetTotal__c > 0 && tempMonthPTLtotal > 0) {
                                         groupLine.pricingTypeLines.get(groupLine.pricingTypeLines.size()-1).total = tempMonthPTLtotal / 12;
                                    }
                                    else {
                                       System.debug('***FRL*** groupLine.pricingTypeLines processing LINE 103 - quoteLine.SBQQ__NetTotal__c = ' + quoteLine.SBQQ__NetTotal__c);
                                       groupLine.pricingTypeLines.get(groupLine.pricingTypeLines.size()-1).total += quoteLine.SBQQ__NetTotal__c;
                                    }
                                    System.debug('***FRL*** groupLine.pricingTypeLines processing LINE 106 - quoteLine.SBQQ__NetTotal__c = ' + quoteLine.SBQQ__NetTotal__c);
                                    groupLine.pricingTypeLines.get(groupLine.pricingTypeLines.size()-1).quoteLines.add(createQuoteLine(quoteLine));
                                }
                            }                            
                        }
                    }
                }
            }
            system.debug(LoggingLevel.ERROR,'groupLines##'+groupLines);
            System.debug('***FRL*** before return groupLines where groupLines: ' + groupLines);
            return groupLines;
        }
        set;
    }
    
    private GroupLine createGroupLine(SBQQ__QuoteLine__c quoteLine){
        GroupLine groupLine = new GroupLine();
        groupLine.groupId = quoteLine.SBQQ__Group__c;
        groupLine.groupName = (string.isBlank(quoteLine.SBQQ__Group__r.Name) ? '' : quoteLine.SBQQ__Group__r.Name.escapeHTML4());
        System.debug('***FRL*** within createGroupLine where quoteLine.SBQQ__Group__r.Name = ' + quoteLine.SBQQ__Group__r.Name);
        groupLine.pricingTypeLines = new List<PricingTypeLine>();
        groupLine.oneTimeSetupFeeNetTotal = 0;
        /////if(quoteLine.Pricing_Type__c == 'One-time' && quoteLine.Setup_Fee__c){
        /////    groupLine.oneTimeSetupFeeNetTotal = quoteLine.SBQQ__NetTotal__c;
        /////}
        System.debug('***FRL*** within createGroupLine just before return groupLine statement... ');
        return groupLine;
    }
    
    private PricingTypeLine createPricingTypeLine(SBQQ__QuoteLine__c quoteLine){
        PricingTypeLine pricingTypeLine = new PricingTypeLine();
        pricingTypeLine.pricingType = quoteLine.Pricing_Type__c;
        pricingTypeLine.total = quoteLine.SBQQ__NetTotal__c;
        System.debug('***FRL*** within createPricingTypeLine where quoteLine.SBQQ__NetTotal__c = ' + quoteLine.SBQQ__NetTotal__c);
        System.debug('***FRL*** within createPricingTypeLine where pricingTypeLine.total = ' + pricingTypeLine.total);
        pricingTypeLine.quoteLines = new List<QuoteLine>{createQuoteLine(quoteLine)};
    if(quoteLine.Pricing_Type__c == 'Per Pay Period'){
      pricingTypeLine.payRollFrequency = quoteLine.PayrollFrequency__c;
      pricingTypeLine.showFrequency = true;
    }
        pricingTypeLine.showHeader = true;
        return pricingTypeLine;
    }
    
    private QuoteLine createQuoteLine(SBQQ__QuoteLine__c quoteLine){
        QuoteLine quoteLineWrapper = new QuoteLine();
        quoteLineWrapper.productIds = new Set<String>{quoteLine.SBQQ__Product__c};
        quoteLineWrapper.productName = (string.IsBlank(quoteLine.Product_Name_and_Description__c) ? '' : quoteLine.Product_Name_and_Description__c.escapeHTML4());
        quoteLineWrapper.quantity = quoteLine.SBQQ__Quantity__c;
        quoteLineWrapper.baseFeeUnitPrice = quoteLineWrapper.productName.containsIgnoreCase('Base')?quoteLine.SBQQ__ListPrice__c:0;
        quoteLineWrapper.unitPrice = quoteLineWrapper.productName.containsIgnoreCase('Base')?0:quoteLine.SBQQ__ListPrice__c;
        if (quoteLine.Pricing_Type__c == 'Monthly' && quoteLine.SBQQ__NetTotal__c > 0) {
           quoteLineWrapper.netTotal = quoteLine.SBQQ__NetTotal__c / 12;
        }
        else {
           quoteLineWrapper.netTotal = quoteLine.SBQQ__NetTotal__c;
        }
        System.debug('***FRL*** within createQuoteLine where quoteLine.SBQQ__NetTotal__c = ' + quoteLine.SBQQ__NetTotal__c);
        System.debug('***FRL*** within createQuoteLine where quoteLineWrapper.netTotal = ' + quoteLineWrapper.netTotal);
        return quoteLineWrapper;
    }
    
    class QuoteLine{
        public Set<String> productIds{get;set;}
        public String productName{get;set;}
        public Decimal quantity{get;set;}
        public Decimal baseFeeUnitPrice{get;set;}
        public Decimal unitPrice{get;set;}
        public Decimal netTotal{get;set;}
    }
    
    class PricingTypeLine{
        public String pricingType{get;set;}
        public Decimal total{get;set;}
        public List<QuoteLine> quoteLines{get;set;}
        public String payRollFrequency{get;set;}
        public Boolean showHeader{get;set;}
        public Boolean showFrequency{get;set;}
    }
    
    class GroupLine{
        public Id groupId{get;set;}
        public String groupName{get;set;}
        public List<PricingTypeLine> pricingTypeLines{get;set;}
        public Double oneTimeSetupFeeNetTotal{get;set;}
    }*/
}