// Used for returning header and row information for the UI quota table
global class Load_QuotasModel {
    public String periodName {get; set; }
    public List<String> columnHeaders {get; set; }
    public List<Quota_Model> quotaRows {get; set; }
    //public Map<String,String> currencyCodes {get; set; }
    public Boolean readOnly {get; set; }
    
    public Load_QuotasModel(String periodName, List<String> columnHeaders, List<Quota_Model> quotaRows, Boolean readOnly) { // Map<String,String> currencyCodes,
        this.periodName = periodName;
        this.columnHeaders = columnHeaders;
        this.quotaRows = quotaRows;
        //this.currencyCodes = currencyCodes;
        this.readOnly = readOnly;
    }
    
}