/* 
 * Add business hours to a date time field. Created generic to be able to be used with other objects/fields
 *
 * History
 * -------
 * 12/21/2017 Lynn Michels   Created
 *
 */
public with sharing class CalculateBusinessHours {

	public static Datetime addHours(Datetime dateTimeValue, Integer numOfHoursToAdd, Id businessHourId){ 
		Datetime newValue;
		newValue = BusinessHours.add(businessHourId, dateTimeValue, numOfHoursToAdd * 60 * 60 * 1000); 
		return newValue;
	}
}//end CalculateBusinessHours