/* 
 * Test methods for the IncidentCaseUtilities class
 *
 * History
 * -------
   11/15/2017 Dan Carmen   This code can be deleted - references exist in TestTriggers class (for test coverage)

 */
public class TriggerHelper {
	
	//alreadyExecutedCreateMassIncidentCases
    private static boolean alreadyExecutedCreateMassIncidentCases = false;
    
    public static boolean hasAlreadyExecutedCreateMassIncidentCases() {
		return alreadyExecutedCreateMassIncidentCases;
    }

    public static void setAlreadyExecutedCreateMassIncidentCases() {
        alreadyExecutedCreateMassIncidentCases = true;
    }
    
} // TriggerHelper