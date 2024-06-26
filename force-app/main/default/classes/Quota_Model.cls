global class Quota_Model implements Comparable {
    public Id quotaId { get; set; }
    public Id ownerId { get; set; }
    public string ownerName { get; set; }
    public string ownerRole { get; set; }
    public double amount;
    public double prevAmount{ get; set; }
    public string currencyIsoCode {get; set; }
    public date startDate {get; set; }
    public String startDateStr {get; set;}
    public string periodId {get; set; }
    public Boolean isQuantity { get; set; }
    public string productFamily {get; set; }
    public Id forecastingTypeId {get; set; }
    public Boolean isDeleted {get; set; }
    public String quotaLabel{get;set;}
    public Integer sortOrder {get;set;}
        
    public void setAmount(double amount) {
        System.debug('Amount being set to ' + amount + ' for owner ' + ownerName);
        this.amount = amount;
    }
    
    public double getAmount() {
        return amount;
    }
    
    public String getAmountString() {
        if (amount == null)
            return null;
        String amountStr = amount.format();
        if (amountStr == null) 
            return null;
        // Make the number display with two digits after the decimal. If a whole number, 
        // then text formatting usually adds just one digit, e.g. 1234 -> 1234.0 . We want
        // 1234.00
        integer decimalLocation = amountStr.lastIndexOf('.');
        if (decimalLocation == -1)
            amountStr += '.00';
        else if (decimalLocation == amountStr.length() - 2)
            amountStr += '0';
        return amountStr;
    }
    
    global Integer CompareTo(Object compareTo) {
        Quota_Model compareToQuota = (Quota_Model) compareTo;
        if(compareToQuota.ownerName>this.ownerName) return -1;
        else if (compareToQuota.ownerName<this.ownerName) return 1;
        else{
        	if(compareToQuota.sortOrder>this.sortOrder) return -1;
        	else if(compareToQuota.sortOrder<this.sortOrder) return 1;
        }
        return 0;
    } 
    /*
    global Integer CompareTo(Object compareTo) {
        Quota_Model compareToQuota = (Quota_Model) compareTo;
        return this.ownerName.compareTo(compareToQuota.ownerName);
    } */ 
}