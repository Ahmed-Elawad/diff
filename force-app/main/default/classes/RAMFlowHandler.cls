/* 
 * History
 * -------
  17/10/2022 Rohit Ranjan Created
  17/10/2022  invoked prepareGenericRoundRobin  method from the RoundRobin class, to use in 'Reference Account Management Before' Flow

*/

public class RAMFlowHandler {
  @InvocableMethod
  public static List<Reference_Account_Management__c> setRAMOwnerRR(List<Reference_Account_Management__c> ramList) {
      System.debug('Called from flow Reference Account Management Before - V2');      
      RoundRobin.prepareGenericRoundRobin(ramList,null);
      System.debug('Round Robin executed');
      update ramList;
    return null;
  }

}