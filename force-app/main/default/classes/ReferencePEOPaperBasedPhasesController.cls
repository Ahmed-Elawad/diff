/*	Controller for the ReferencePEOPaperBasedPhases page.
	This is a component located on the Reference PEO Paper Based Onboarding layout.

   History
   -------
   05/09/2017 Lynn Michels   Created
   08/07/2018 Lynn Michels   Edited for mobile  
 */

public with sharing class ReferencePEOPaperBasedPhasesController {
	private Reference_PEO__c peo;
	
	//holds the color that the icon should be
	public string initialSetupColor {get; set;}
	public string initialSetupIconColor {get; set;}
	public string initialSetupFontWeight {get; set;}
	public string initialSetupFontSize {get; set;}
	public string initialSetupIconUrl {get; set;}
	public string empDataRecdColor {get; set;}
	public string empDataRecdFontWeight {get; set;}
	public string empDataRecdFontSize {get; set;}
	public string empDataRecdIconUrl {get; set;}
	public string empDataRecdIconColor {get; set;}  
	public string workCompColor {get; set;}
	public string workCompFontWeight {get; set;}
	public string workCompFontSize {get; set;}
	public string workCompIconUrl {get; set;}
	public string workCompIconColor {get; set;}
	public string nepReceivedColor {get; set;}
	public string nepReceivedFontWeight {get; set;}
	public string nepReceivedFontSize {get; set;}
	public string nepReceivedIconUrl {get; set;}
	public string nepReceivedIconColor {get; set;}
	public string medUWApprovalColor {get; set;}
	public string medUWApprovalIconColor {get; set;}
	public string medUWApprovalFontWeight {get; set;}
	public string medUWApprovalFontSize {get; set;}
	public string medUWApprovalIconUrl {get; set;}
	public string completeSubmissionColor {get; set;}
	public string completeSubmissionIconColor {get; set;}
	public string completeSubmissionFontWeight {get; set;}
	public string completeSubmissionFontSize {get; set;}
	public string completeSubmissionIconUrl {get; set;} 
	public string passToNewLoadsColor {get; set;}
	public string passToNewLoadsIconColor {get; set;}
	public string passToNewLoadsFontWeight {get; set;}
	public string passToNewLoadsFontSize {get; set;}
	public string passToNewLoadsIconUrl {get; set;}
	public string setupCompleteCircleColor {get; set;}
	public string setupCompleteColor {get; set;}
	public string setupCompleteFontWeight {get; set;}
	public string setupCompleteFontSize {get; set;}
	public string setupCompleteIconUrl {get; set;}
	
	public string payrollConversionSetupCircleColor {get; set;}
	public string payrollConversionSetupColor {get; set;}
	public string payrollConversionSetupFontWeight {get; set;}
	public string payrollConversionSetupFontSize {get; set;}
	public string payrollConversionSetupIconUrl {get; set;}
	public string wcSetupColor {get; set;}
	public string wcSetupIconColor {get; set;}
	public string wcSetupFontWeight {get; set;}
	public string wcSetupFontSize {get; set;}
	public string wcSetupIconUrl {get; set;}
	public string eeLoadColor {get; set;}
	public string eeLoadIconColor {get; set;}
	public string eeLoadFontWeight {get; set;}
	public string eeLoadFontSize {get; set;}
	public string eeLoadIconUrl {get; set;}
	public string benefitsSetupColor {get; set;}
	public string benefitsSetupIconColor {get; set;}
	public string benefitsSetupFontWeight {get; set;}
	public string benefitsSetupFontSize {get; set;}
	public string benefitsSetupIconUrl {get; set;}
	public string readyToRunColor {get; set;}
	public string readyToRunIconColor {get; set;}
	public string readyToRunFontWeight {get; set;}
	public string readyToRunFontSize {get; set;}
	public string readyToRunIconUrl {get; set;}
	public string payrollProcessingColor {get; set;}
	public string payrollProcessingIconColor {get; set;}
	public string payrollProcessingFontWeight {get; set;}
	public string payrollProcessingFontSize {get; set;}
	public string payrollProcessingIconUrl {get; set;}
	public string processingCompleteCircleColor {get; set;}
	public string processingCompleteColor {get; set;}
	public string processingCompleteFontWeight {get; set;}
	public string processingCompleteFontSize {get; set;}
	public string processingCompleteIconUrl {get; set;}
	
	//used for the circle colors at the end and beginning of the phase diagram
	public static final String GREEN = '#2F9F1F';
	public static final String YELLOW = '#FFD933';
	public static final String RED = '#DF281D';
	public static final String GRAY = '#AFAFAF';
	String greenUrl = '/_slds/icons/utility-sprite/svg/symbols.svg#check';
	String yellowUrl = '/_slds/icons/utility-sprite/svg/symbols.svg#clock';
	String redUrl = '/_slds/icons/utility-sprite/svg/symbols.svg#priority';
	String grayUrl = '/_slds/icons/utility-sprite/svg/symbols.svg#arrowdown';
	
	public String colorGreen{
	   get {return GREEN;}
	}
	public String colorYellow{
	   get {return YELLOW;}
	}
	public String colorRed{
	   get {return RED;}
	}
	public String colorGray{
	   get {return GRAY;}
	}
	
	public integer setupFont = 0; //used to dictate which section should have the bold and larger font
	public integer conversionFont = 0; //used to dictate which section should have the bold and larger font
	
	public ReferencePEOPaperBasedPhasesController(ApexPages.StandardController controller){
		Date todaysdate = Date.today();
		this.peo = (Reference_PEO__c)controller.getRecord(); 
		Reference_PEO__c refPEO = new Reference_PEO__c();
		refPEO = [SELECT Id, Client_Shell_Creation__c, Client_Shell_Creation_Target__c,
						IPM_Assigned__c, IPM_Assigned_Target__c,
						Benefits_NCS_Assigned__c, Benefits_NCS_Assigned_Target__c,
						Payroll_NCS_Assigned__c, Payroll_NCS_assigned_Target__c,
						Onbrdg_Spreadsheet_Rec__c, Onbrdg_Spreadsheet_Rec_Target__c,
						WC_Underwriting_Review_Complete__c, WC_Underwriting_Review_Target__c,
						NEP_Submission_Approved__c, NEP_Submission_Approved_Target__c,
						Final_Medical_Approval_Milestone__c, Final_Medical_Approval_Target_Milestone__c,
						Complete_Deal_Submission__c, Complete_Deal_Submission_Target__c,
						Pass_to_New_Biz__c, Pass_to_New_Biz_Target__c,
						WC_Setup__c, WC_Setup_Target__c,
						Complete_Payroll_Shell__c, Complete_Payroll_Shell_Target__c,
						Employee_Load_Complete__c, Employee_Load_Complete_Target__c,
						Benefits_ER_Contribution_Loaded__c, Benefits_ER_Contribution_Loaded_Target__c,
						Prior_Wages_Rcvd__c, Prior_Wages_Rcvd_Target__c,
						Ready_to_Process_Payroll2__c, Ready_to_Process_Payroll_Target__c,
						Actual_Payroll_Process__c, Actual_Payroll_Process_Target__c,
						Follow_Up_Satisfaction_Call__c, Follow_Up_Satisfaction_Call_Target__c				
				FROM Reference_PEO__c WHERE id =: this.peo.id];
				
		//Initial Client Setup Phase Milestones Chart
		//Initial Setup	
		if(todaysdate < refPEO.Client_Shell_Creation_Target__c && refPEO.Client_Shell_Creation__c == null && refPEO.Onbrdg_Spreadsheet_Rec__c != null)
		{
			initialSetupColor = 'greenOutline';
			initialSetupIconColor= 'green';
			setupFont = 1;
			initialSetupIconUrl = greenUrl;
			
		}
		else if(refPEO.Client_Shell_Creation__c != null)
		{
			initialSetupColor = 'green';
			initialSetupIconColor = 'white';
			setupFont = 1;
			initialSetupIconUrl = greenUrl;
		}
		else if(todaysdate == refPEO.Client_Shell_Creation_Target__c  && refPEO.Client_Shell_Creation__c == null)
		{
			initialSetupColor = 'yellow';
			initialSetupIconColor = 'yellow';
			setupFont = 1;
			initialSetupIconUrl = yellowUrl;
		}
		else if(todaysdate > refPEO.Client_Shell_Creation_Target__c && refPEO.Client_Shell_Creation__c == null)
		{
			initialSetupColor = 'red';
			initialSetupIconColor = 'red';
			setupFont = 1;
			initialSetupIconUrl = redUrl;
		} 
		else
		{
			initialSetupColor = 'gray';
			initialSetupIconColor = 'white';
			initialSetupIconUrl = grayUrl;
		}
		
		//Employee Data Received criteria
		if(refPEO.Client_Shell_Creation__c != null && todaysdate < refPEO.Onbrdg_Spreadsheet_Rec_Target__c && refPEO.Onbrdg_Spreadsheet_Rec__c == null )
		{
			empDataRecdColor = 'greenOutline';
			empDataRecdIconColor= 'green';
			empDataRecdFontWeight = 'normal';
			setupFont = 2;
			empDataRecdIconUrl = greenUrl;
		}
		else if(refPEO.Onbrdg_Spreadsheet_Rec__c != null)
		{
			empDataRecdColor = 'green';
			empDataRecdIconColor= 'white';
			setupFont = 2;
			empDataRecdIconUrl = greenUrl;
		}
		else if(refPEO.Client_Shell_Creation__c != null && todaysdate == refPEO.Onbrdg_Spreadsheet_Rec_Target__c
			&& refPEO.Onbrdg_Spreadsheet_Rec__c == null)
		{
			empDataRecdColor = 'yellow';
			empDataRecdIconColor= 'yellow';
			setupFont = 2;
			empDataRecdIconUrl = yellowUrl;
		}
		else if(refPEO.Client_Shell_Creation__c != null && todaysdate > refPEO.Onbrdg_Spreadsheet_Rec_Target__c
			&& refPEO.Onbrdg_Spreadsheet_Rec__c == null)
		{
			empDataRecdColor = 'red';
			empDataRecdIconColor= 'red';
			setupFont = 2;
			empDataRecdIconUrl = redUrl;
		}
		else
		{
			empDataRecdColor = 'gray';
			empDataRecdIconColor= 'white';
			empDataRecdIconUrl = grayUrl;
		}
		
		//WorkComp UW Review
		if(refPEO.Onbrdg_Spreadsheet_Rec__c != null && todaysdate < refPEO.WC_Underwriting_Review_Target__c && refPEO.WC_Underwriting_Review_Complete__c == null)
		{
			workCompColor = 'greenOutline';
			workCompIconColor = 'green';
			workCompFontWeight = 'normal';
			setupFont = 3;
			workCompIconUrl = greenUrl;
		}
		else if(refPEO.WC_Underwriting_Review_Complete__c != null)
		{
			workCompColor = 'green';
			workCompIconColor = 'white';
			setupFont = 3;
			workCompIconUrl = greenUrl;
			
		}
		else if(refPEO.Onbrdg_Spreadsheet_Rec__c != null && todaysdate == refPEO.WC_Underwriting_Review_Target__c 
			&& refPEO.WC_Underwriting_Review_Complete__c == null)
		{
			workCompColor = 'yellow';
			workCompIconColor = 'yellow';
			setupFont = 3;
			workCompIconUrl = yellowUrl;
			
		}
		else if(refPEO.Onbrdg_Spreadsheet_Rec__c != null && todaysdate > refPEO.WC_Underwriting_Review_Target__c 
			&& refPEO.WC_Underwriting_Review_Complete__c == null)
		{
			workCompColor = 'red';
			workCompIconColor = 'red';
			setupFont = 3;
			workCompIconUrl = redUrl;
		}
		else
		{
			workCompColor = 'gray';
			workCompIconColor = 'white';
			workCompIconUrl = grayUrl;
		}
		
		//NEPs Received
		if(refPEO.WC_Underwriting_Review_Complete__c != null && todaysdate < refPEO.NEP_Submission_Approved_Target__c && refPEO.NEP_Submission_Approved__c == null)
		{
			nepReceivedColor = 'greenOutline';
			nepReceivedIconColor = 'green'; 
			nepReceivedFontWeight = 'normal';
			setupFont = 4;
			nepReceivedIconUrl = greenUrl;
		}
		else if(refPEO.NEP_Submission_Approved__c != null)
		{
			nepReceivedColor = 'green';
			nepReceivedIconColor = 'white';
			setupFont = 4;
			nepReceivedIconUrl = greenUrl;
		}
		else if(refPEO.WC_Underwriting_Review_Complete__c != null && todaysdate == refPEO.NEP_Submission_Approved_Target__c
			&& refPEO.NEP_Submission_Approved__c == null)
		{
			nepReceivedColor = 'yellow';
			nepReceivedIconColor = 'yellow';
			setupFont = 4;
			nepReceivedIconUrl = yellowUrl;
		}
		else if(refPEO.WC_Underwriting_Review_Complete__c != null && todaysdate > refPEO.NEP_Submission_Approved_Target__c
			&& refPEO.NEP_Submission_Approved__c == null)
		{
			nepReceivedColor = 'red';
			nepReceivedIconColor = 'red';
			setupFont = 4;
			nepReceivedIconUrl = redUrl;
		}
		else
		{
			nepReceivedColor = 'gray';
			nepReceivedIconColor = 'white';
			nepReceivedIconUrl = grayUrl;
		}
		
		//Med UW Approval	
		if(refPEO.NEP_Submission_Approved__c != null && todaysdate < refPEO.Final_Medical_Approval_Target_Milestone__c && refPEO.Final_Medical_Approval_Milestone__c == null )	
		{
			medUWApprovalColor = 'greenOutline';
			medUWApprovalIconColor = 'green';
			medUWApprovalFontWeight = 'normal';
			setupFont = 5;
			medUWApprovalIconUrl = greenUrl;
		}
		else if(refPEO.Final_Medical_Approval_Milestone__c != null)
		{
			medUWApprovalColor = 'green';
			medUWApprovalIconColor = 'white';
			setupFont = 5;
			medUWApprovalIconUrl = greenUrl;
		}
		else if(refPEO.NEP_Submission_Approved__c != null && todaysdate == refPEO.Final_Medical_Approval_Target_Milestone__c
			&& refPEO.Final_Medical_Approval_Milestone__c == null)
		{
			medUWApprovalColor = 'yellow';
			medUWApprovalIconColor = 'yellow';
			setupFont = 5;
			medUWApprovalIconUrl = yellowUrl;
		}
		else if(refPEO.NEP_Submission_Approved__c != null && todaysdate > refPEO.Final_Medical_Approval_Target_Milestone__c
			&& refPEO.Final_Medical_Approval_Milestone__c == null)
		{
			medUWApprovalColor = 'red';
			medUWApprovalIconColor = 'red';
			setupFont = 5;
			medUWApprovalIconUrl = redUrl;
		}
		else
		{
			medUWApprovalColor = 'gray';
			medUWApprovalIconColor = 'white';
			medUWApprovalIconUrl = grayUrl;
		}
		
		//Complete Submission
		if(refPEO.Final_Medical_Approval_Milestone__c != null && todaysdate < refPEO.Complete_Deal_Submission_Target__c &&refPEO.Complete_Deal_Submission__c == null)
		{
			completeSubmissionColor = 'greenOutline';
			completeSubmissionIconColor = 'green'; 
			completeSubmissionFontWeight = 'normal';
			setupFont = 6;
			completeSubmissionIconUrl = greenUrl;
		}
		else if(refPEO.Complete_Deal_Submission__c != null)
		{
			completeSubmissionColor = 'green';
			completeSubmissionIconColor = 'white';
			setupFont = 6;
			completeSubmissionIconUrl = greenUrl;
		}
		else if(refPEO.Final_Medical_Approval_Milestone__c != null && todaysdate == refPEO.Complete_Deal_Submission_Target__c
			&& refPEO.Complete_Deal_Submission__c == null)
		{
			completeSubmissionColor = 'yellow';
			completeSubmissionIconColor = 'yellow'; 
			setupFont = 6;
			completeSubmissionIconUrl = yellowUrl;
		}
		else if(refPEO.Final_Medical_Approval_Milestone__c != null && todaysdate > refPEO.Complete_Deal_Submission_Target__c
			&& refPEO.Complete_Deal_Submission__c == null)
		{
			completeSubmissionColor = 'red';
			completeSubmissionIconColor = 'red';
			setupFont = 6;
			completeSubmissionIconUrl = redUrl;
		}
		else
		{
			completeSubmissionColor = 'gray';
			completeSubmissionIconColor = 'white';
			completeSubmissionIconUrl = grayUrl;
		}
		
		//Pass to New Loads
		if(refPEO.Complete_Deal_Submission__c != null && todaysdate < refPEO.Pass_to_New_Biz_Target__c && refPEO.Pass_to_New_Biz__c == null)
		{
			passToNewLoadsColor = 'greenOutline';
			passToNewLoadsIconColor = 'green';   
			passToNewLoadsFontWeight = 'normal';
			setupFont = 7;
			passToNewLoadsIconUrl = greenUrl;
		}
		else if(refPEO.Pass_to_New_Biz__c != null)
		{
			passToNewLoadsColor = 'green';
			passToNewLoadsIconColor = 'white';
			setupFont = 7;
			passToNewLoadsIconUrl = greenUrl;
		}
		else if(refPEO.Complete_Deal_Submission__c != null && todaysdate == refPEO.Pass_to_New_Biz_Target__c 
			&& refPEO.Pass_to_New_Biz__c == null)
		{
			passToNewLoadsColor = 'yellow';
			passToNewLoadsIconColor = 'yellow';
			setupFont = 7;
			passToNewLoadsIconUrl = yellowUrl;
		}
		else if(refPEO.Complete_Deal_Submission__c != null && todaysdate > refPEO.Pass_to_New_Biz_Target__c 
			&& refPEO.Pass_to_New_Biz__c == null)
		{
			passToNewLoadsColor = 'red';
			passToNewLoadsIconColor = 'red';
			setupFont = 7;
			passToNewLoadsIconUrl = redUrl;
		}
		else
		{
			passToNewLoadsColor = 'gray';
			passToNewLoadsIconColor = 'white';
			passToNewLoadsIconUrl = grayUrl;
		}
			
		//Initial Setup Complete
		if(refPEO.Pass_to_New_Biz__c != null)
		{
			setupCompleteCircleColor = GREEN;
			setupCompleteColor = 'green';
			//setupCompleteIconColor = 'white';
			setupFont = 8;
			setupCompleteIconUrl = greenUrl;
		}
		else
		{
			setupCompleteCircleColor = GRAY;
			setupCompleteColor = 'gray';
			//setupCompleteIconColor = 'white';
			setupCompleteIconUrl = grayUrl;
		}
		
	/*-----------------Payroll Conversion Phase Milestones------------------*/
		
		//Payroll Conversion Setup
		if(refPEO.Pass_to_New_Biz__c != null || refPEO.WC_Setup__c != null)
		{
			payrollConversionSetupCircleColor = GREEN;
			payrollConversionSetupColor = 'green';
			//payrollConversionSetupIconColor = 'white';
			conversionFont = 1;
			payrollConversionSetupIconUrl = greenUrl;
		}
		else
		{
			payrollConversionSetupCircleColor = GRAY;
			payrollConversionSetupColor = 'gray';
			//payrollConversionSetupIconColor = 'white';
			payrollConversionSetupIconUrl = grayUrl;
		}
		
		//WC Setup
		if(refPEO.Pass_to_New_Biz__c != null && todaysdate < refPEO.WC_Setup_Target__c && refPEO.WC_Setup__c == null )
		{
			wcSetupColor = 'greenOutline';
			wcSetupIconColor = 'green';
			wcSetupFontWeight = 'normal';
			conversionFont = 2;
			wcSetupIconUrl = greenUrl;
		}
		else if(refPEO.WC_Setup__c != null )
		{
			wcSetupColor = 'green';
			wcSetupIconColor = 'white';
			conversionFont = 2;
			wcSetupIconUrl = greenUrl;
		}
		else if(refPEO.Pass_to_New_Biz__c != null && todaysdate == refPEO.WC_Setup_Target__c && refPEO.WC_Setup__c == null)
		{
			wcSetupColor = 'yellow';
			wcSetupIconColor = 'yellow';
			conversionFont = 2;
			wcSetupIconUrl = yellowUrl;
		}
		else if(refPEO.Pass_to_New_Biz__c != null && todaysdate > refPEO.WC_Setup_Target__c && refPEO.WC_Setup__c == null)
		{
			wcSetupColor = 'red';
			wcSetupIconColor = 'red';
			conversionFont = 2;
			wcSetupIconUrl = redUrl;
		}
		else
		{
			wcSetupColor = 'gray';
			wcSetupIconColor = 'white';
			wcSetupIconUrl = grayUrl;
		}
		
		//EE Load
		if(refPEO.Pass_to_New_Biz__c != null && todaysdate < refPEO.Employee_Load_Complete_Target__c && refPEO.Employee_Load_Complete__c == null)
		{
			eeLoadColor = 'greenOutline';
			eeLoadIconColor = 'green';
			eeLoadFontWeight = 'normal';
			conversionFont = 3;
			eeLoadIconUrl = greenUrl;
		}
		else if(refPEO.Employee_Load_Complete__c != null)
		{
			eeLoadColor = 'green';
			eeLoadIconColor = 'white';
			conversionFont = 3;
			eeLoadIconUrl = greenUrl;
		}
		else if(refPEO.Pass_to_New_Biz__c != null && todaysdate == refPEO.Employee_Load_Complete_Target__c && refPEO.Employee_Load_Complete__c == null)
		{
			eeLoadColor = 'yellow';
			eeLoadIconColor = 'yellow';
			conversionFont = 3;
			eeLoadIconUrl = yellowUrl;
		}
		else if(refPEO.Pass_to_New_Biz__c != null && todaysdate > refPEO.Employee_Load_Complete_Target__c && refPEO.Employee_Load_Complete__c == null)
		{
			eeLoadColor = 'red';
			eeLoadIconColor = 'red';
			conversionFont = 3;
			eeLoadIconUrl = redUrl;
		}
		else
		{
			eeLoadColor = 'gray';
			eeLoadIconColor = 'white';
			eeLoadIconUrl = grayUrl;
		}
		//Benefits Setup
		if(refPEO.Employee_Load_Complete__c != null && todaysdate < refPEO.Benefits_ER_Contribution_Loaded_Target__c && refPEO.Benefits_ER_Contribution_Loaded__c == null)
		{
			benefitsSetupColor = 'greenOutline';
			benefitsSetupIconColor = 'green';
			benefitsSetupFontWeight = 'normal';
			conversionFont = 4;
			benefitsSetupIconUrl = greenUrl;
		}
		else if(refPEO.Benefits_ER_Contribution_Loaded__c != null)
		{
			benefitsSetupColor = 'green';
			benefitsSetupIconColor = 'white';
			conversionFont = 4;
			benefitsSetupIconUrl = greenUrl;
		}
		else if(refPEO.Employee_Load_Complete__c != null && todaysdate == refPEO.Benefits_ER_Contribution_Loaded_Target__c && refPEO.Benefits_ER_Contribution_Loaded__c == null)
		{
			benefitsSetupColor = 'yellow';
			benefitsSetupIconColor = 'yellow';
			conversionFont = 4;
			benefitsSetupIconUrl = yellowUrl;
		}
		else if(refPEO.Employee_Load_Complete__c != null && todaysdate > refPEO.Benefits_ER_Contribution_Loaded_Target__c && refPEO.Benefits_ER_Contribution_Loaded__c == null)
		{
			benefitsSetupColor = 'red';
			benefitsSetupIconColor = 'red';
			conversionFont = 4;
			benefitsSetupIconUrl = redUrl;
		}
		else
		{
			benefitsSetupColor = 'gray';
			benefitsSetupIconColor = 'white';
			benefitsSetupIconUrl = grayUrl;
		}
		//Ready to Run
		if(refPEO.Benefits_ER_Contribution_Loaded__c != null && todaysdate < refPEO.Ready_to_Process_Payroll_Target__c && refPEO.Ready_to_Process_Payroll2__c == null)
		{
			readyToRunColor = 'greenOutline';
			readyToRunIconColor = 'green';
			readyToRunFontWeight = 'normal';
			conversionFont = 5;
			readyToRunIconUrl = greenUrl;
		}
		else if(refPEO.Ready_to_Process_Payroll2__c != null)
		{
			readyToRunColor = 'green';
			readyToRunIconColor = 'white';
			conversionFont = 5;
			readyToRunIconUrl = greenUrl;
		}
		else if(refPEO.Benefits_ER_Contribution_Loaded__c != null && todaysdate == refPEO.Ready_to_Process_Payroll_Target__c && refPEO.Ready_to_Process_Payroll2__c == null)
		{
			readyToRunColor = 'yellow';
			readyToRunIconColor = 'yellow';
			conversionFont = 5;
			readyToRunIconUrl = yellowUrl;
		}
		else if(refPEO.Benefits_ER_Contribution_Loaded__c != null && todaysdate > refPEO.Ready_to_Process_Payroll_Target__c && refPEO.Ready_to_Process_Payroll2__c == null)
		{
			readyToRunColor = 'red';
			readyToRunIconColor = 'red';
			conversionFont = 5;
			readyToRunIconUrl = redUrl;
		}
		else
		{
			readyToRunColor = 'gray';
			readyToRunIconColor = 'white';
			readyToRunIconUrl = grayUrl;
		}
		
		//Payroll Processing
		if(refPEO.Ready_to_Process_Payroll2__c != null && todaysdate < refPEO.Actual_Payroll_Process_Target__c && refPEO.Actual_Payroll_Process__c == null)
		{
			payrollProcessingColor = 'greenOutline';
			payrollProcessingIconColor = 'green';
			payrollProcessingFontWeight = 'normal';
			conversionFont = 6;
			payrollProcessingIconUrl = greenUrl;
		}
		else if(refPEO.Actual_Payroll_Process__c != null)
		{
			payrollProcessingColor = 'green';
			payrollProcessingIconColor = 'white';
			conversionFont = 6;
			payrollProcessingIconUrl = greenUrl;
		}
		else if(refPEO.Ready_to_Process_Payroll2__c != null && todaysdate == refPEO.Actual_Payroll_Process_Target__c && refPEO.Actual_Payroll_Process__c == null)
		{
			payrollProcessingColor = 'yellow';
			payrollProcessingIconColor = 'yellow';
			conversionFont = 6;
			payrollProcessingIconUrl = yellowUrl;
		}
		else if(refPEO.Ready_to_Process_Payroll2__c != null && todaysdate > refPEO.Actual_Payroll_Process_Target__c && refPEO.Actual_Payroll_Process__c == null)
		{
			payrollProcessingColor = 'red';
			payrollProcessingIconColor = 'red';
			conversionFont = 6;
			payrollProcessingIconUrl = redUrl;
		}
		else
		{
			payrollProcessingColor = 'gray';
			payrollProcessingIconColor = 'white';
			payrollProcessingIconUrl = grayUrl;
		}
		
		//1st Payroll Complete
		if(refPEO.Actual_Payroll_Process__c != null)
		{
			processingCompleteColor = 'green';
			//processingCompleteIconColor = 'white';
			processingCompleteCircleColor = GREEN;
			conversionFont = 7;
			processingCompleteIconUrl = greenUrl;
		}
		else
		{
			processingCompleteColor = 'gray';
			//processingCompleteIconColor = 'white';
			processingCompleteCircleColor = GRAY;
			processingCompleteIconUrl = grayUrl;
		}
		calculateSetupFontWeight();
		calculateConversionFontWeight();
			
	}//end ReferencePEODealPhasesController

		//calculate font for Initial Client Setup Phase Milestones
		public void calculateSetupFontWeight(){
		if (setupFont == 1){
			initialSetupFontWeight = '800';
			initialSetupFontSize = '105%';
		}
		else if (setupFont == 2){
			empDataRecdFontWeight = '800';
			empDataRecdFontSize = '105%';
		}
		else if (setupFont == 3){
			workCompFontWeight = '800';
			workCompFontSize = '105%';
		}
		else if (setupFont == 4){
			nepReceivedFontWeight = '800';
			nepReceivedFontSize = '105%';
		}
		else if (setupFont == 5){
			medUWApprovalFontWeight = '800';
			medUWApprovalFontSize = '105%';
		}
		else if (setupFont == 6){
			completeSubmissionFontWeight = '800';
			completeSubmissionFontSize = '105%';
		}
		else if (setupFont == 7){
			passToNewLoadsFontWeight = '800';
			passToNewLoadsFontSize = '105%';
		}
		else if (setupFont == 8){
			setupCompleteFontWeight = '800';
			setupCompleteFontSize = '105%';
		}
		
	}//end calculateSetupFontWeight
	
	//caluclate font for Payroll Conversion Phase Milestones
	public void calculateConversionFontWeight(){
		if (conversionFont == 1){
			payrollConversionSetupFontWeight = '800';
			payrollConversionSetupFontSize = '105%';
		}
		else if (conversionFont == 2){
			wcSetupFontWeight = '800';
			wcSetupFontSize = '105%';
		}
		else if (conversionFont == 3){
			eeLoadFontWeight = '800';
			eeLoadFontSize = '105%';
		}
		else if (conversionFont == 4){
			benefitsSetupFontWeight = '800';
			benefitsSetupFontSize = '105%';
		}
		else if (conversionFont == 5){
			readyToRunFontWeight = '800';
			readyToRunFontSize = '105%';
		}	
		else if (conversionFont == 6){
			payrollProcessingFontWeight = '800';
			payrollProcessingFontSize = '105%';
		}		
		else if (conversionFont == 7){
			processingCompleteFontWeight = '800';
			processingCompleteFontSize = '105%';
		}
		
	}//end calculateFontWeight
}