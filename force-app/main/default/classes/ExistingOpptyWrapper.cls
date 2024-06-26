//This is a wrapper class for the CreateOpptyandMeeting class.  I wasn't able to use a virtual class
//because of the way we're using components in that page.  I wasn't able to pass the class to the component using an attribute.

public with sharing class ExistingOpptyWrapper {
        public Opportunity opp {get;set;}
        public Boolean selected {get;set;}
        public ExistingOpptyWrapper(Opportunity o,Boolean setSelected){
            opp = o;
            selected = setSelected;
        }
}