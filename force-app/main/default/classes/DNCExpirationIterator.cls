/*

    
    07/06/2020  Jacob Hinds         Added without sharing per PMD
*/

global without sharing class DNCExpirationIterator implements Iterable<SObject>, Iterator<SObject>{ 
   List<SObject> sobjs {get; set;} 
   Integer i {get; set;} 
   public DNCExpirationIterator(Date expDate,Date checkDate){ 
       sobjs = new List<SObject>();

       for( Account acct : [SELECT id, name,DNC_Expiration__c FROM Account WHERE Do_Not_Call__c = true 
                            AND DNC_Expiration__c !=: NULL AND DNC_Expiration__c <= :expDate AND LastModifiedDate >= :checkDate]) {
           sobjs.add(acct);
       }
       
       for( Contact co : [SELECT id, name,DoNotCall,DNC_Expiration__c FROM Contact WHERE DoNotCall = true 
                            AND DNC_Expiration__c !=: NULL AND DNC_Expiration__c <= :expDate AND LastModifiedDate >= :checkDate] ) {
           sobjs.add(co);
       }
       
       for( Lead ld: [SELECT id, name,DoNotCall,DNC_Expiration__c FROM Lead WHERE DoNotCall = true 
                        AND DNC_Expiration__c !=: NULL AND DNC_Expiration__c <= :expDate AND LastModifiedDate >= :checkDate]){
           sobjs.add(ld);
       }
       i = 0; 
   }   
   public Iterator<SObject> iterator() { return this; }
   global boolean hasNext(){ 
       if(i >= sobjs.size()) 
           return false; 
       else 
           return true; 
   }    
   global SObject next(){ 
       if(i == 8){ i++; return null;} 
       i=i+1; 
       return sobjs[i-1]; 
   } 
}