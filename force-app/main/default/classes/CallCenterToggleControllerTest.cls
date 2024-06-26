/*
History 
--------------
08/22/2018 Josh Cartwright Created 

 */
 
@isTest 
private class CallCenterToggleControllerTest{ 
    
    public static User rep1; 
    public static CallCenter cs1;
    public static CallCenter cs2; 
    public static CallCenter[] callCenters;
  
   public static void setupUser(){
    
       User[]usrList = [select id, name, CallCenterId From User where IsActive=true and CallCenterId !=null limit 1]; 
       rep1 = usrList[0];   
        
       callCenters = [select name, id from CallCenter where name !=null]; 
       System.assertEquals(true, callCenters.size()>1);
       cs1 = callCenters[0];
       cs2 = callCenters[1];
      
       rep1.CallCenterId = cs1.Id; 
       update rep1; 
        

    }//setupUser
        
    static TestMethod void testCS(){ 
        setupUser(); 
        system.runAs(rep1){
        CallCenterToggleController idtc = new CallCenterToggleController(); 
        system.assert(idtc.runningUser != null);
        System.assertEquals(true, idtc.getCS.size()>1);
        idtc.callCenterId = cs2.Id;
        idtc.saveCS();
        System.assertEquals(1,[select count() from User where Id=:idtc.runningUser.Id and CallCenterId=:cs2.Id]);
        }//runAs(Rep1)
        
        
        
    }//testCS
    

    
    
    
    



}//ISDCDialerToggleControllerTest