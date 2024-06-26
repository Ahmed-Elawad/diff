/*
* History:
* Test class for FlowInvokableActions
* ------------------------------------------
* 12.27.2021 Ahmed Elawad   Created 
*/

@isTest
public class FlowInvokableActionsTest {
    @testSetup
    public static void setup(){
        
    }
    
    static testMethod void logFlowErrorTest() {
        // setup string input
        String inputTemplate = 'Flow Name: Test,Failed Actions(s): Failed test,Err Msg: text of err msg,User: First name last name';
        List<String> inputList = new List<String>{inputTemplate};
        Test.StartTest();
        FlowInvokableActions.logFlowError(inputList);        
        Test.stopTest();
        
        // verify existance of error log
        
    }
    
}