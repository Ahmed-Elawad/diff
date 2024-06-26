public class MidMarketCreateCaseFlowHandler {
    @InvocableMethod(label='Apply Case Assignement Rule' description='Apply Case Assignement Rule')
    public static Void caseAssgnmntRules(List<Case> caseList)
    {
        Database.DMLOptions dmlOption = new Database.DMLOptions();
        dmlOption.assignmentRuleHeader.useDefaultRule= true;
        case caseCreated =  caseList[0];
        //Case caseCreated=[select id from Case where id in :caseIds];
        caseList[0].setOptions(dmlOption);
        try{
            Update caseList;
        }catch(exception e){        }
   }
}