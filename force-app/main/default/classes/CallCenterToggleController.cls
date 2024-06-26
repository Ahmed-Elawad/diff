/*
 History 
--------------
08/21/2018 Josh Cartwright Created 
07/06/2020  Jacob Hinds         Added without sharing per PMD

*/

public without sharing class CallCenterToggleController {
    
    public string callCenterId{get;set;} 
    public String callCenterName{get;set;}
       
    public boolean saveSuccessful {get;set;} //used to display success message 
      
    public list <CallCenter> allCSList = new list <CallCenter>(); 
    
    public list <SelectOption> CSOptionList = new List<SelectOption>(); 
    
    public user runningUser{get;set;}
           
    public CallCenterToggleController(){
        runningUser = [select ID, Name, CallCenterID from User where ID= :Userinfo.getUserId()]; 
        allCSList = [select name, id from CallCenter where name !='']; 
        callCenterId = 'None';
        for (CallCenter cs : allCSList) {
            if (cs.Id == runningUser.CallCenterId) {
                callCenterId = cs.Id;
                callCenterName = cs.Name;
                break;
            }
        }
        saveSuccessful = false; 
                
    }//CallCenterToggleController
        
    public static Set<String> excludeSet = new Set<String>(label.Call_Center_Exclude_List.split(','));
    
    public list <SelectOption> getCS{
        get{
            CSOptionList.add(new SelectOption('None','No Call Center Selected'));
            for (CallCenter cs: allCSList){
                    if(!excludeSet.contains(cs.name)){
                       CSOptionList.add(new SelectOption(cs.id, cs.name));
                    }//if 
                }//for
                   
               return CSOptionList;                             
        }//get
     }//getCS
    
      public void saveCS(){
          
          runningUser.CallCenterId = (callCenterId != 'None' ? callCenterId : null); 
          
          update runningUser; 
          saveSuccessful = true; 

                 
   
            
        }//saveCS 

}