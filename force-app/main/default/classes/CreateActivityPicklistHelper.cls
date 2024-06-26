public without sharing class CreateActivityPicklistHelper {

	public static String OUTCOME_PICKLIST_OPTIONS = Label.Create_Activity_Outcome_Options;


	public static SelectOptionWrapper[] getPicklistValues(RecordType rt) {
		PicklistDetail__c[] pkDetails = PicklistHelperDataAccessor.getPicklistDetailsFromObjectNameAndRecordType(rt.SobjectType, rt.DeveloperName);
		return createSelectOptionsFromPicklistDetails(pkDetails);
	} 


    public static void addStaticPicklistValues(SelectOptionWrapper[] wrappers){
    	addStaticPriorityOptions(wrappers);
    	addStaticOnsiteOrVirtualOptions(wrappers);
    }

    private static void addStaticPriorityOptions(SelectOptionWrapper[] wrappers){
		Schema.DescribeFieldResult fieldResult = Task.Priority.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

		for( Schema.PicklistEntry f : ple){
		    wrappers.add(new SelectOptionWrapper('Priority', f.getLabel(), f.getValue()));
		}      
    }

    private static void addStaticOnsiteOrVirtualOptions(SelectOptionWrapper[] wrappers){
		Schema.DescribeFieldResult fieldResult = Task.Onsite_or_Virtual__c.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

		for( Schema.PicklistEntry f : ple){
		    wrappers.add(new SelectOptionWrapper(Label.Activity_Onsite_Or_Virtual_API_Name, f.getLabel(), f.getValue()));
		}      
    }

	private static SelectOptionWrapper[] createSelectOptionsFromPicklistDetails(PicklistDetail__c[] pkDetails){
		SelectOptionWrapper[] selectOptionWrappers = new SelectOptionWrapper[]{};

		for (PicklistDetail__c pkDetail : pkDetails) {
			if(!String.isBlank(pkDetail.PicklistData__c)){
				String[] pkValues = pkDetail.PicklistData__c.split(PicklistHelper.TOKEN_KEY);
				for (String pkValue : pkValues) {
					selectOptionWrappers.add(new SelectOptionWrapper(pkDetail.FieldName__c,pkValue,pkValue));
				}
			}
		}

		return selectOptionWrappers;
	}



}