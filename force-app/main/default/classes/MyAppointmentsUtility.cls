/*
	Created By: Mendel Guillaume - BlackTab Group
	Date Created: 2015-05-11
	Description: Utility class for My Appointments mobile app
*/
public with sharing class MyAppointmentsUtility 
{
	public static ID mmsEventRecordType {get {return Schema.SObjectType.Event.getRecordTypeInfosByName().get('MMS Event Record Type').getRecordTypeId();}}
	public static ID mmsOpportunityRecordType {get {return Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('MMS Opportunity Record Type').getRecordTypeId();}}
	
	/*
		Returns number of appoinment for a given grouping
	*/
	public static Integer getAppointmentCount(string appointmentType)
	{
		if(appointmentType == 'Future')
		{
			return getFutureAppointmentCount();
		}
		else if(appointmentType == 'Past')
		{
			return getPastAppointmentCount();
		}
		else if(appointmentType == 'Week')
		{
			return getWeekAppointmentCount();
		}
		else if(appointmentType == 'Last')
		{
			return getLastWeekAppointmentCount();
		}
		else
		{
			return getTodayAppointmentCount();
		}
	}// end of getAppointmentCount
	
	/*
		Returns list of appoinments for a given grouping
	*/
	public static List<Event> getAppointments(string appointmentType)
	{
		List<Event> events = null;
		
		if(appointmentType == 'Future')
		{
			events = getAppointments(' WHERE ActivityDate >= TOMORROW AND OwnerId = \'' + string.valueOf(UserInfo.getUserId()) + '\' AND RecordTypeId = \'' + mmsEventRecordType + '\'', 'ASC');
		}
		else if(appointmentType == 'Past')
		{
			events = getAppointments(' WHERE Outcome__c = null AND ActivityDate = LAST_N_DAYS:30 AND EndDateTime < :now AND OwnerId = \'' + string.valueOf(UserInfo.getUserId()) + + '\' AND RecordTypeId = \'' + mmsEventRecordType + '\'', 'DESC');
		}
		else if(appointmentType == 'Week')
		{
			events = getAppointments(' WHERE ActivityDate = THIS_WEEK AND OwnerId = \'' + string.valueOf(UserInfo.getUserId()) + '\' AND RecordTypeId = \'' + mmsEventRecordType + '\'', 'ASC');
		}
		else if(appointmentType == 'Last')
		{
			events = getAppointments(' WHERE ActivityDate = LAST_WEEK AND OwnerId = \'' + string.valueOf(UserInfo.getUserId()) + '\' AND RecordTypeId = \'' + mmsEventRecordType + '\'', 'ASC');
		}
		else
		{
			events = getAppointments(' WHERE ActivityDate = TODAY AND OwnerId = \'' + string.valueOf(UserInfo.getUserId()) + '\' AND RecordTypeId = \'' + mmsEventRecordType + '\'', 'ASC');
		}
		
		return events;
	}// end of getAppointments
	
	/*
		Returns list of appoinments based on criteria and sort direction
	*/
	public static List<Event> getAppointments(string criteria, string sortDirection)
	{
		DateTime now = DateTime.now();
		String query = getObjectQuery('Event') + criteria + ' Order By StartDateTime ' + sortDirection;
		
		return (List<Event>) Database.query(query);
	}// end of getAppointments
	
	/*
		Returns list of opportunity based on criteria
	*/
	public static List<Opportunity> getOpportunities(string criteria)
	{
		String query = getObjectQuery('Opportunity') + criteria;
		
		return (List<Opportunity>) Database.query(query);
	}// end of getOpportunities

    /*
    	Returns query for all fields of an object
    */
    public static string getObjectQuery(string objectName)
    {
    	Schema.DescribeSobjectResult[] objectResults = Schema.describeSObjects(new String[]{objectName});
    	Map<String, Schema.SObjectField> fieldsMap =  objectResults[0].fields.getMap();
    	
    	String query = 'SELECT ';
    	
    	//build query
    	for (String fieldName :  fieldsMap.keySet())
		{
			query += fieldName + ',';
		}
		
		//Remove the last comma
		query = query.substring(0,query.length()-1);
		
		query += ' FROM ' + objectName + ' '; 
		
		return query;
    }// end of getObjectQuery
    
    /*
		Returns number of appointments for This Week
	*/
    public static Integer getWeekAppointmentCount()
	{
		return [SELECT COUNT() FROM Event WHERE ActivityDate = THIS_WEEK AND OwnerId =: UserInfo.getUserId() AND RecordTypeId =:mmsEventRecordType LIMIT 200 ];
	}// end of getWeekAppointmentCount
    
     /*
		Returns number of appointments for Today
	*/
    public static Integer getTodayAppointmentCount()
	{
		return [SELECT COUNT() FROM Event WHERE ActivityDate = TODAY AND OwnerId =: UserInfo.getUserId() AND RecordTypeId =:mmsEventRecordType LIMIT 200];
	}// end of getTodayAppointmentCount
	
	/*
		Returns number of appointments for Future
	*/
	public static Integer getFutureAppointmentCount()
	{
		return [SELECT COUNT() FROM Event WHERE ActivityDate >= TOMORROW AND OwnerId =: UserInfo.getUserId() AND RecordTypeId =:mmsEventRecordType LIMIT 200];
	}// end of getFutureAppointmentCount
	
	/*
		Returns number of appointments for Past
	*/
	public static Integer getPastAppointmentCount()
	{
		return [SELECT COUNT() FROM Event WHERE Outcome__c = null AND ActivityDate = LAST_N_DAYS:30 AND EndDateTime <: DateTime.now() AND OwnerId =: UserInfo.getUserId() AND RecordTypeId =:mmsEventRecordType LIMIT 200];
	} //end of getPastAppointmentCount
	
	/*
		Returns number of appointments for Last Week
	*/
	public static Integer getLastWeekAppointmentCount()
	{
		return [SELECT COUNT() FROM Event WHERE ActivityDate = LAST_WEEK AND OwnerId =: UserInfo.getUserId() AND RecordTypeId =:mmsEventRecordType LIMIT 200];
	} //end of getLastWeekAppointmentCount
	
	
	/*
		Returns list appointments group by Date or Time (Today)
	*/
	public static List<AppointmentGroup> getAppointmentGroups(List<Event> events, String appointmentType)
	{
		List<AppointmentGroup> groups = new List<AppointmentGroup>();
		Map<String, AppointmentGroup> groupsMap = new Map<String, AppointmentGroup>();
		string sortFormat = 'yyyy/MM/dd';
		string displayFormat = 'MMM d, yyyy';
		string sortDirection = 'ASC';
		
		if(appointmentType == 'Today')
		{
			sortFormat = 'HH:mm';
			displayFormat = 'h:mm a';
		}
		
		if(appointmentType == 'Past')
		{
			sortDirection = 'DESC';
		}
		
		for(Event e : events)
		{
			string sortName = e.StartDateTime.format(sortFormat);
			
			AppointmentGroup ag = groupsMap.get(sortName);
			
			if(ag == null)
			{
				string displayName = e.StartDateTime.format(displayFormat) + (appointmentType == 'Today' ? ' - ' + e.EndDateTime.format(displayFormat) : '');
				ag = new AppointmentGroup(sortName, displayName);
			}
			
			ag.events.add(e);
			
			groupsMap.put(sortName, ag);
		}
		
		groups = groupsMap.values();
		
		return sortGroups(groups, sortDirection);
	}// end of getAppointmentGroups
	
	/*
	 	This is a simple quicksort algorithm to sort list.
	*/
    public static List<AppointmentGroup> sortGroups(List<AppointmentGroup> listToSort, string sortDirection)
    {
    	List<AppointmentGroup> returnList = null;
    	List<AppointmentGroup> less = null;
        List<AppointmentGroup> greater = null;
        AppointmentGroup pivotValue = null;
        Integer pivot = 0;
    	
        if(listToSort == null || listToSort.size() <= 1)
            return listToSort;
        
        returnList = new List<AppointmentGroup> ();
        less = new List<AppointmentGroup>();
        greater = new List<AppointmentGroup>();
        
        // save the pivot and remove it from the list
        pivotValue = listToSort[pivot];
        listToSort.remove(pivot);
        
        for(AppointmentGroup x : listToSort)
        {
        	if(sortDirection == 'ASC')
        	{
	            if(x.sortName <= pivotValue.sortName)
	            {
	                less.add(x);
	            }
	            else if(x.sortName > pivotValue.sortName)
	            {
	            	greater.add(x);    
	            }
        	}
        	else
        	{
        		if(x.sortName >= pivotValue.sortName)
	            {
	                less.add(x);
	            }
	            else if(x.sortName < pivotValue.sortName)
	            {
	            	greater.add(x);    
	            }
        	}
        }
        
        returnList.addAll(sortGroups(less, sortDirection));
        returnList.add(pivotValue);
        returnList.addAll(sortGroups(greater, sortDirection));
        
        return returnList; 
    }// end of sortGroups
	
	/*
		Wrapper class to group events
	*/
	public class AppointmentGroup
	{
		public String sortName {get;set;}
		public String displayName {get;set;}
		public List<Event> events {get;set;}		
		
		/*
			Constructor
		*/		
		public AppointmentGroup(string sortName, string displayName)
		{
			this.sortName = sortName;
			this.displayName = displayName;
			this.events = new List<Event>();
		}// end of AppointmentGroup
		
	}// end of AppointmentGroup Class
	
}//end of Class