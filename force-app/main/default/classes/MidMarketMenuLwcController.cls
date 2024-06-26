public class MidMarketMenuLwcController {
    @AuraEnabled(cacheable=true)
    public static List<Mid_Market_Service_Submission_Form__mdt> getMenuMetaData(){
        return Mid_Market_Service_Submission_Form__mdt.getAll().values();
    }
}