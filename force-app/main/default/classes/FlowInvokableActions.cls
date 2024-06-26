/*
* History:
* Provides custom functionality to be triggered by flow
* 
* Apex Actions docs: https://help.salesforce.com/s/articleView?id=flow_build_extend_apex.htm&type=5&language=en_US
* Invocable Action docs: https://developer.salesforce.com/docs/atlas.en-us.234.0.apexcode.meta/apexcode/apex_classes_annotation_InvocableMethod.htm
* Invocable Variable docs: https://developer.salesforce.com/docs/atlas.en-us.234.0.apexcode.meta/apexcode/apex_classes_annotation_InvocableVariable.htm
* ------------------------------------------
* 12.27.2021 Ahmed Elawad	Created & added logError method
*/

public class FlowInvokableActions {
    
    // @Params: MUST ALWAYS BE COLLECTION FOR Inovcable methods. Build list in flow and pass as param to action
    // Returns void
    @InvocableMethod
    public static void handleFlowActionRequest(List<String> errorTextTemplate) {
        // add parsing of template for managind different action requests
        logFlowError(errorTextTemplate);
    }
    
    // @Params: list containing 'error templates'
    // Flow Name: example flow
    // Failed Actions(s): failed action 1, failed action 2, ...
    // Err Msg: text of err msg
    // User: First name last name
    // @Returns: VOID
    public static void logFlowError(List<String> errorTextTemplate) {
        String logTextMessage = '';
        String FlowName = 'PEO Edge Clear Medical Akn FLow';
        for (String errTemplate : errorTextTemplate) {
            // errTemplate should be formated as CSV
            List<String> seperatedTemplate = errTemplate.split(',');
            
            //System.debug(seperatedTemplate);
            logTextMessage += String.join(seperatedTemplate, '\n');
        }
        
        //ErrorLog.logError('FlowInvokableActions', 'logFlowError', 'FLow failure', null, ex, null, True);
        ErrorLog.logError('FlowInvokableActions', FlowName, 'logFlowError', null, logTextMessage,null, true);
	}
}