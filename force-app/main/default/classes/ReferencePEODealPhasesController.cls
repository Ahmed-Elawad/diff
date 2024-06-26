/*	Controller for the ReferencePEODealPhases page.
	This is a component located on the Reference PEO Web Based Onboarding layout.

   History
   -------
   11/17/2016 Lynn Michels   Created
   08/07/2018 Lynn Michels	 Added criteria for mobile icons
 */

public with sharing class ReferencePEODealPhasesController {
	private Reference_PEO__c peo;
	
	//holds the color that the icon should be
	public string initialSetupCircleColor {get; set;} 
	public string initialSetupColor {get; set;}
	public string initialSetupFontWeight {get; set;}
	public string initialSetupFontSize {get; set;}
	public string initialSetupIconUrl {get; set;}
	public string empDataRecdColor {get; set;}
	public string empDataRecdFontWeight {get; set;}
	public string empDataRecdFontSize {get; set;} 
	public string empDataRecdIconUrl {get; set;}
	public string workCompColor {get; set;}
	public string workCompFontWeight {get; set;}
	public string workCompFontSize {get; set;}
	public string workCompIconUrl {get; set;}
	public string benefitsSetupColor {get; set;}
	public string benefitsSetupFontWeight {get; set;}
	public string benefitsSetupFontSize {get; set;}
	public string benefitsSetupIconUrl {get; set;}
	public string eeLoadColor {get; set;}
	public string eeLoadFontWeight {get; set;}
	public string eeLoadFontSize {get; set;}
	public string eeLoadIconUrl {get; set;}
	public string eeOnboardingColor {get; set;}
	public string eeOnboardingFontWeight {get; set;}
	public string eeOnboardingFontSize {get; set;}
	public string eeOnboardingIconUrl {get; set;}
	public string onboardingCompleteColor {get; set;}
	public string onboardingCompleteFontWeight {get; set;}
	public string onboardingCompleteFontSize {get; set;}
	public string onboardingCompleteIconUrl {get; set;}
	public string medUVApprovalColor {get; set;}
	public string medUVApprovalFontWeight {get; set;}
	public string medUVApprovalFontSize {get; set;} 
	public string medUVApprovalIconUrl {get; set;} 
	public string approvedPassColor {get; set;}
	public string approvedPassFontWeight {get; set;}
	public string approvedPassFontSize {get; set;}
	public string approvedPassIconUrl {get; set;}
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
	public string eeVerificationColor {get; set;}
	public string eeVerificationFontWeight {get; set;}
	public string eeVerificationFontSize {get; set;}
	public string eeVerificationIconUrl {get; set;}
	public string holdsRemovedColor {get; set;}
	public string holdsRemovedFontWeight {get; set;}
	public string holdsRemovedFontSize {get; set;}
	public string holdsRemovedIconUrl {get; set;}
	public string readyToRunColor {get; set;}
	public string readyToRunFontWeight {get; set;}
	public string readyToRunFontSize {get; set;}
	public string readyToRunIconUrl {get; set;}
	public string payrollProcessingColor {get; set;}
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
	
	
	
	public ReferencePEODealPhasesController(ApexPages.StandardController controller){
		Date todaysdate = Date.today();
		this.peo = (Reference_PEO__c)controller.getRecord(); 
		Reference_PEO__c refPEO = new Reference_PEO__c();
		refPEO = [SELECT Id, Client_Shell_Creation__c,
		Onbrdg_Spreadsheet_Rec__c,
		Onbrdg_Spreadsheet_Rec_Target__c,
				Client_Shell_Creation_Target__c, WC_Underwriting_Review_Complete__c, WC_Underwriting_Review_Target__c,
				Benefits_ER_Contribution_Loaded__c, Benefits_ER_Contribution_Loaded_Target__c,
				Onbrdg_Spsheet_Review_and_EE_Load__c, Onbrdg_Spsheet_Review_and_EE_Load_Target__c,
				Onboarding_Complete__c, Onboarding_Open__c, Onboarding_Open_Target__c,
				Final_Medical_Approval_Milestone__c, Final_Medical_Approval_Target_Milestone__c, Onboarding_Complete_Target__c,
				HRIS_Approved_Pass_to_New_Biz__c, HRIS_Approved_Target_Pass_to_New_Biz__c, EE_Verification_and_QC_Target__c,
				EE_Verification_and_QC__c, Management_Hold_Removed_Date__c, Ready_to_Process_Payroll2__c, Management_Hold_Target__c,
				Ready_to_Process_Payroll_Target__c, Actual_Payroll_Process__c, Actual_Payroll_Process_Target__c
				FROM Reference_PEO__c WHERE id =: this.peo.id];
				
		//Initial Client Setup Phase Milestones Chart
		//Initial Setup	
		if(refPEO.Client_Shell_Creation__c != null || refPEO.Onbrdg_Spreadsheet_Rec__c != null || todaysdate < refPEO.Client_Shell_Creation_Target__c)
		{
			initialSetupCircleColor = GREEN;
			initialSetupColor = 'green';
			setupFont = 1;
			initialSetupIconUrl = greenUrl;
			
		}
		else if(todaysdate == refPEO.Client_Shell_Creation_Target__c  && refPEO.Client_Shell_Creation__c == null)
		{
			initialSetupCircleColor = YELLOW;
			initialSetupColor = 'yellow'; 
			setupFont = 1;
			initialSetupIconUrl = yellowUrl;
		}
		else if(todaysdate > refPEO.Client_Shell_Creation_Target__c && refPEO.Client_Shell_Creation__c == null)
		{
			initialSetupCircleColor = RED;
			initialSetupColor = 'red';
			setupFont = 1;
			initialSetupIconUrl = redUrl;
		} 
		else
		{
			initialSetupCircleColor = GRAY;
			initialSetupColor = 'gray';
			initialSetupIconUrl = grayUrl;
		}
		
		//Employee Data Received criteria
		if((refPEO.Client_Shell_Creation__c != null && todaysdate < refPEO.Onbrdg_Spreadsheet_Rec_Target__c) 
			|| refPEO.Onbrdg_Spreadsheet_Rec__c != null || refPEO.WC_Underwriting_Review_Complete__c != null)
		{
			empDataRecdColor = 'green';
			empDataRecdFontWeight = 'normal';
			setupFont = 2;
			empDataRecdIconUrl = greenUrl;
		}
		else if(refPEO.Client_Shell_Creation__c != null && todaysdate == refPEO.Onbrdg_Spreadsheet_Rec_Target__c
			&& refPEO.Onbrdg_Spreadsheet_Rec__c == null)
		{
			empDataRecdColor = 'yellow';
			setupFont = 2;
			empDataRecdIconUrl = yellowUrl;
		}
		else if(refPEO.Client_Shell_Creation__c != null && todaysdate > refPEO.Onbrdg_Spreadsheet_Rec_Target__c
			&& refPEO.Onbrdg_Spreadsheet_Rec__c == null)
		{
			empDataRecdColor = 'red';
			setupFont = 2;
			empDataRecdIconUrl = redUrl;
		}
		else
		{
			empDataRecdColor = 'gray';
			empDataRecdIconUrl = grayUrl;
		}
		
		//WorkComp UW Review
		if((refPEO.Onbrdg_Spreadsheet_Rec__c != null && (todaysdate < refPEO.WC_Underwriting_Review_Target__c )
			|| refPEO.WC_Underwriting_Review_Complete__c != null || refPEO.Benefits_ER_Contribution_Loaded__c != null))
		{
			workCompColor = 'green'; 
			workCompFontWeight = 'normal';
			setupFont = 3;
			workCompIconUrl = greenUrl;
			
		}
		else if(refPEO.Onbrdg_Spreadsheet_Rec__c != null && todaysdate == refPEO.WC_Underwriting_Review_Target__c 
			&& refPEO.WC_Underwriting_Review_Complete__c == null)
		{
			workCompColor = 'yellow';
			setupFont = 3;
			workCompIconUrl = yellowUrl;
			
		}
		else if(refPEO.Onbrdg_Spreadsheet_Rec__c != null && todaysdate > refPEO.WC_Underwriting_Review_Target__c 
			&& refPEO.WC_Underwriting_Review_Complete__c == null)
		{
			workCompColor = 'red';
			setupFont = 3;
			workCompIconUrl = redUrl;
		}
		else
		{
			workCompColor = 'gray';
			workCompIconUrl = grayUrl;
		}
		
		//Benefits Setup
		if((refPEO.WC_Underwriting_Review_Complete__c != null && (todaysdate < refPEO.Benefits_ER_Contribution_Loaded_Target__c )
			|| refPEO.Benefits_ER_Contribution_Loaded__c != null || refPEO.Onbrdg_Spsheet_Review_and_EE_Load__c != null))
		{
			benefitsSetupColor = 'green';
			benefitsSetupFontWeight = 'normal';
			setupFont = 4;
			benefitsSetupIconUrl = greenUrl;
		}
		else if(refPEO.WC_Underwriting_Review_Complete__c != null && todaysdate == refPEO.Benefits_ER_Contribution_Loaded_Target__c 
			&& refPEO.Benefits_ER_Contribution_Loaded__c == null)
		{
			benefitsSetupColor = 'yellow';
			setupFont = 4;
			benefitsSetupIconUrl = yellowUrl;
		}
		else if(refPEO.WC_Underwriting_Review_Complete__c != null && todaysdate > refPEO.Benefits_ER_Contribution_Loaded_Target__c 
			&& refPEO.Benefits_ER_Contribution_Loaded__c == null)
		{
			benefitsSetupColor = 'red';
			setupFont = 4;
			benefitsSetupIconUrl = redUrl;
		}
		else
		{
			benefitsSetupColor = 'gray';
			benefitsSetupIconUrl = grayUrl;
		}
		
		//EE load WC Setup
		if((refPEO.Benefits_ER_Contribution_Loaded__c != null && (todaysdate < refPEO.Onbrdg_Spsheet_Review_and_EE_Load_Target__c )
			|| refPEO.Onbrdg_Spsheet_Review_and_EE_Load__c != null || refPEO.Onboarding_Open__c != null))
		{
			eeLoadColor = 'green';
			eeLoadFontWeight = 'normal';
			setupFont = 5;
			eeLoadIconUrl = greenUrl;
		}
		else if(refPEO.Benefits_ER_Contribution_Loaded__c != null && todaysdate == refPEO.Onbrdg_Spsheet_Review_and_EE_Load_Target__c)
		{
			eeLoadColor = 'yellow';
			setupFont = 5;
			eeLoadIconUrl = yellowUrl;
		}
		else if(refPEO.Benefits_ER_Contribution_Loaded__c != null && todaysdate > refPEO.Onbrdg_Spsheet_Review_and_EE_Load_Target__c)
		{
			eeLoadColor = 'red';
			setupFont = 5;
			eeLoadIconUrl = redUrl;
		}
		else
		{
			eeLoadColor = 'gray';
			eeLoadIconUrl = grayUrl;
		}
		
		//EE Onboarding
		if((refPEO.Onbrdg_Spsheet_Review_and_EE_Load__c != null && (todaysdate < refPEO.Onboarding_Open_Target__c )
			|| refPEO.Onboarding_Open__c != null || refPEO.Onboarding_Complete__c != null))
		{
			eeOnboardingColor = 'green';
			eeOnboardingFontWeight = 'normal';
			setupFont = 6;
			eeOnboardingIconUrl = greenUrl;
		}
		else if(refPEO.Onbrdg_Spsheet_Review_and_EE_Load__c != null && todaysdate == refPEO.Onboarding_Open_Target__c
			&& refPEO.Onboarding_Open__c == null)
		{
			eeOnboardingColor = 'yellow';
			setupFont = 6;
			eeOnboardingIconUrl = yellowUrl;
		}
		else if(refPEO.Onbrdg_Spsheet_Review_and_EE_Load__c != null && todaysdate > refPEO.Onboarding_Open_Target__c
			&& refPEO.Onboarding_Open__c == null)
		{
			eeOnboardingColor = 'red';
			setupFont = 6;
			eeOnboardingIconUrl = redUrl;
		}
		else
		{
			eeOnboardingColor = 'gray';
			eeOnboardingIconUrl = grayUrl;
		}
		
		//Onboarding Complete	
		if((refPEO.Onboarding_Open__c != null && (todaysdate < refPEO.Onboarding_Complete_Target__c )
			|| refPEO.Onboarding_Complete__c != null || refPEO.Final_Medical_Approval_Milestone__c != null))
		{
			onboardingCompleteColor = 'green';
			onboardingCompleteFontWeight = 'normal';
			setupFont = 7;
			onboardingCompleteIconUrl = greenUrl;
		}
		else if(refPEO.Onboarding_Open__c != null && todaysdate == refPEO.Onboarding_Complete_Target__c
			&& refPEO.Onboarding_Complete__c == null)
		{
			onboardingCompleteColor = 'yellow';
			setupFont = 7;
			onboardingCompleteIconUrl = yellowUrl;
		}
		else if(refPEO.Onboarding_Open__c != null && todaysdate > refPEO.Onboarding_Complete_Target__c
			&& refPEO.Onboarding_Complete__c == null)
		{
			onboardingCompleteColor = 'red';
			setupFont = 7;
			onboardingCompleteIconUrl = redUrl;
		}
		else
		{
			onboardingCompleteColor = 'gray';
			onboardingCompleteIconUrl = grayUrl;
		}
		
		//Med UW Approval
		if((refPEO.Onboarding_Complete__c != null && (todaysdate < refPEO.Final_Medical_Approval_Target_Milestone__c )
			|| refPEO.Final_Medical_Approval_Milestone__c != null || refPEO.HRIS_Approved_Pass_to_New_Biz__c != null))
		{
			medUVApprovalColor = 'green';
			medUVApprovalFontWeight = 'normal';
			setupFont = 8;
			medUVApprovalIconUrl = greenUrl;
		}
		else if(refPEO.Onboarding_Complete__c != null && todaysdate == refPEO.Final_Medical_Approval_Target_Milestone__c
			&& refPEO.Final_Medical_Approval_Milestone__c == null)
		{
			medUVApprovalColor = 'yellow'; 
			setupFont = 8;
			medUVApprovalIconUrl = yellowUrl;
		}
		else if(refPEO.Onboarding_Complete__c != null && todaysdate > refPEO.Final_Medical_Approval_Target_Milestone__c
			&& refPEO.Final_Medical_Approval_Milestone__c == null)
		{
			medUVApprovalColor = 'red';
			setupFont = 8;
			medUVApprovalIconUrl = redUrl;
		}
		else
		{
			medUVApprovalColor = 'gray';
			medUVApprovalIconUrl = grayUrl;
		}
		
		//Approved Pass to New Loads
		if((refPEO.Final_Medical_Approval_Milestone__c != null && (todaysdate < refPEO.HRIS_Approved_Target_Pass_to_New_Biz__c )
			|| refPEO.HRIS_Approved_Pass_to_New_Biz__c != null))
		{
			approvedPassColor = 'green';
			approvedPassFontWeight = 'normal';
			setupFont = 9;
			approvedPassIconUrl = greenUrl;
		}
		else if(refPEO.Final_Medical_Approval_Milestone__c != null && todaysdate == refPEO.HRIS_Approved_Target_Pass_to_New_Biz__c 
			&& refPEO.HRIS_Approved_Pass_to_New_Biz__c == null)
		{
			approvedPassColor = 'yellow';
			setupFont = 9;
			approvedPassIconUrl = yellowUrl;
		}
		else if(refPEO.Final_Medical_Approval_Milestone__c != null && todaysdate > refPEO.HRIS_Approved_Target_Pass_to_New_Biz__c 
			&& refPEO.HRIS_Approved_Pass_to_New_Biz__c == null)
		{
			approvedPassColor = 'red';
			setupFont = 9;
			approvedPassIconUrl = redUrl;
		}
		else
		{
			approvedPassColor = 'gray';
			approvedPassIconUrl = grayUrl;
		}
			
		//Initial Client Setup Complete
		if(refPEO.HRIS_Approved_Pass_to_New_Biz__c != null && refPEO.Final_Medical_Approval_Milestone__c != null)
		{
			setupCompleteCircleColor = GREEN;
			setupCompleteColor = 'green';
			setupFont = 10;
			setupCompleteIconUrl = greenUrl;
		}
		else
		{
			setupCompleteCircleColor = GRAY;
			setupCompleteColor = 'gray';
			setupCompleteIconUrl = grayUrl;
		}
		
	/*-----------------Payroll Conversion Phase Milestones------------------*/
		
		//Payroll Conversion Setup
		if(refPEO.HRIS_Approved_Pass_to_New_Biz__c != null)
		{
			payrollConversionSetupCircleColor = GREEN;
			payrollConversionSetupColor = 'green';
			conversionFont = 1;
			payrollConversionSetupIconUrl = greenUrl;
		}
		else
		{
			payrollConversionSetupCircleColor = GRAY;
			payrollConversionSetupColor = 'gray';
			payrollConversionSetupIconUrl = grayUrl;
		}
		
		//EE Verification & QC
		if((refPEO.HRIS_Approved_Pass_to_New_Biz__c != null && (todaysdate < refPEO.EE_Verification_and_QC_Target__c )
			|| refPEO.EE_Verification_and_QC__c != null || refPEO.Management_Hold_Removed_Date__c != null))
		{
			eeVerificationColor = 'green';
			eeVerificationFontWeight = 'normal';
			conversionFont = 2;
			eeVerificationIconUrl = greenUrl;
		}
		else if(refPEO.HRIS_Approved_Pass_to_New_Biz__c != null && todaysdate == refPEO.EE_Verification_and_QC_Target__c 
			&& refPEO.EE_Verification_and_QC__c == null)
		{
			eeVerificationColor = 'yellow';
			conversionFont = 2;
			eeVerificationIconUrl = yellowUrl;
		}
		else if(refPEO.HRIS_Approved_Pass_to_New_Biz__c != null && todaysdate > refPEO.EE_Verification_and_QC_Target__c 
			&& refPEO.EE_Verification_and_QC__c == null)
		{
			eeVerificationColor = 'red';
			conversionFont = 2;
			eeVerificationIconUrl = redUrl;
		}
		else
		{
			eeVerificationColor = 'gray';
			eeVerificationIconUrl = grayUrl;
		}
		
		//Holds Removed
		if((refPEO.EE_Verification_and_QC__c != null && (todaysdate < refPEO.Management_Hold_Target__c) 
			|| refPEO.Management_Hold_Removed_Date__c != null || refPEO.Ready_to_Process_Payroll2__c !=null))
		{
			holdsRemovedColor = 'green';
			holdsRemovedFontWeight = 'normal';
			conversionFont = 3;
			holdsRemovedIconUrl = greenUrl;
			
		}
		else if(refPEO.EE_Verification_and_QC__c != null && todaysdate == refPEO.Management_Hold_Target__c 
			&& refPEO.Management_Hold_Removed_Date__c == null)
		{
			holdsRemovedColor = 'yellow';
			conversionFont = 3;
			holdsRemovedIconUrl = yellowUrl;
		}
		else if(refPEO.EE_Verification_and_QC__c != null && todaysdate > refPEO.Management_Hold_Target__c 
			&& refPEO.Management_Hold_Removed_Date__c == null)
		{
			holdsRemovedColor = 'red';
			conversionFont = 3;
			holdsRemovedIconUrl = redUrl;
		}
		else
		{
			holdsRemovedColor = 'gray';
			holdsRemovedIconUrl = grayUrl;
		}
		//Ready to Run
		if((refPEO.Management_Hold_Removed_Date__c != null && (todaysdate < refPEO.Ready_to_Process_Payroll_Target__c )
			|| refPEO.Ready_to_Process_Payroll2__c != null || refPEO.Actual_Payroll_Process__c !=null))
		{
			readyToRunColor = 'green';
			readyToRunFontWeight = 'normal';
			conversionFont = 4;
			readyToRunIconUrl = greenUrl;
		}
		else if(refPEO.Management_Hold_Removed_Date__c != null && todaysdate == refPEO.Ready_to_Process_Payroll_Target__c 
			&& refPEO.Ready_to_Process_Payroll2__c == null)
		{
			readyToRunColor = 'yellow';
			conversionFont = 4;
			readyToRunIconUrl = yellowUrl;
		}
		else if(refPEO.Management_Hold_Removed_Date__c != null && todaysdate > refPEO.Ready_to_Process_Payroll_Target__c 
			&& refPEO.Ready_to_Process_Payroll2__c == null)
		{
			readyToRunColor = 'red';
			conversionFont = 4;
			readyToRunIconUrl = redUrl;
		}
		else
		{
			readyToRunColor = 'gray';
			readyToRunIconUrl = grayUrl;
		}
		
		//Payroll Processing
		if((refPEO.Ready_to_Process_Payroll2__c != null && (todaysdate < refPEO.Actual_Payroll_Process_Target__c) 
			|| refPEO.Actual_Payroll_Process__c != null))
		{
			payrollProcessingColor = 'green';
			payrollProcessingFontWeight = 'normal';
			conversionFont = 5;
			payrollProcessingIconUrl = greenUrl;
		}
		else if(refPEO.Ready_to_Process_Payroll2__c != null && todaysdate == refPEO.Actual_Payroll_Process_Target__c 
			&& refPEO.Actual_Payroll_Process__c == null)
		{
			payrollProcessingColor = 'yellow';
			conversionFont = 5;
			payrollProcessingIconUrl = yellowUrl;
		}
		else if(refPEO.Ready_to_Process_Payroll2__c != null && todaysdate > refPEO.Actual_Payroll_Process_Target__c 
			&& refPEO.Actual_Payroll_Process__c == null)
		{
			payrollProcessingColor = 'red';
			conversionFont = 5;
			payrollProcessingIconUrl = redUrl;
		}
		else
		{
			payrollProcessingColor = 'gray';
			payrollProcessingIconUrl = grayUrl;
		}
		
		//1st Payroll Complete
		if(refPEO.Actual_Payroll_Process__c != null && refPEO.Ready_to_Process_Payroll2__c != null)
		{
			processingCompleteColor = 'green';
			processingCompleteCircleColor = GREEN;
			conversionFont = 6;
			processingCompleteIconUrl = greenUrl;
		}
		else
		{
			processingCompleteColor = 'gray';
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
			benefitsSetupFontWeight = '800';
			benefitsSetupFontSize = '105%';
		}
		else if (setupFont == 5){
			eeLoadFontWeight = '800';
			eeLoadFontSize = '105%';
		}
		else if (setupFont == 6){
			eeOnboardingFontWeight = '800';
			eeOnboardingFontSize = '105%';
		}
		else if (setupFont == 7){
			onboardingCompleteFontWeight = '800';
			onboardingCompleteFontSize = '105%';
		}
		else if (setupFont == 8){
			medUVApprovalFontWeight = '800';
			medUVApprovalFontSize = '105%';
		}
		else if (setupFont == 9){
			approvedPassFontWeight = '800';
			approvedPassFontSize = '105%';
		}
		else if (setupFont == 10){
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
			eeVerificationFontWeight = '800';
			eeVerificationFontSize = '105%';
		}
		else if (conversionFont == 3){
			holdsRemovedFontWeight = '800';
			holdsRemovedFontSize = '105%';
		}
		else if (conversionFont == 4){
			readyToRunFontWeight = '800';
			readyToRunFontSize = '105%';
		}
		else if (conversionFont == 5){
			payrollProcessingFontWeight = '800';
			payrollProcessingFontSize = '105%';
		}	
		else if (conversionFont == 6){
			processingCompleteFontWeight = '800';
			processingCompleteFontSize = '105%';
		}
		
	}//end calculateFontWeight
	


}