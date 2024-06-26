/**
 * @description       : Executes the correct trigger handler depending on the current trigger context
 * @author            : Austin Barthel
 * @group             : Cloud Coach
**/
public with sharing class CC_TriggerDispatcher {
	
	public static void createHandler(Schema.SObjectType SObjectType) {
		System.debug('Executing ' + SObjectType + ' Trigger');
		cc_ITriggerHandler handler = getHandler(SObjectType);
		if (handler == null) {
			throw new CC_TriggerDispatcherException('No Trigger Handler Assigned!');
		} else {
			execute(handler);
		}
	}
	
	private static void execute(cc_ITriggerHandler handler) {
		if (Trigger.isBefore) {
			handler.bulkBefore();
		}
		if (Trigger.isAfter) {
			handler.bulkAfter();
		}
	}

	private static cc_ITriggerHandler getHandler(Schema.SObjectType SObjectType) {
		switch on SObjectType.newSObject() {
			when project_cloud__Project_Task__c task {
				return new CC_ProjectTaskTriggerHandler();
			}
			when else {
				return null;
			}
		}
	}

	private class CC_TriggerDispatcherException extends Exception {}
}