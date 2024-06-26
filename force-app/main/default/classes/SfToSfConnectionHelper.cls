/* Help with managing connection information

  History
  -------
  04/04/2019 Dan Carmen        Created
  03/06/2020 Dan Carmen        Commenting out all code - no longer need sync to Oasis.
  
 */
public with sharing class SfToSfConnectionHelper {
    // this is here solely for test coverage
    public  SfToSfConnectionHelper() {}
/*
   public static Map<String,Id> connectionIdMap = new Map<String,Id>();
   
   public static Id getConnectionId(String connectionName) {
      Id connectionId = connectionIdMap.get(connectionName);
      if (connectionId == null) {
         try {
            PartnerNetworkConnection pnc = [select Id, AccountId, ConnectionName, ContactId from PartnerNetworkConnection 
                                             where ConnectionName=:connectionName
                                               and ConnectionStatus='Accepted'];
            connectionId = pnc.Id;
            connectionIdMap.put(connectionName, pnc.Id);
         } catch (Exception e) {
            System.debug('Could not find a PartnerNetworkConnection for '+connectionName+': '+e.getMessage());
         }
      } // if (connectionId == null
      System.debug('getConnectionId connectionId='+connectionId);
      return connectionId;
   } // getConnectionId

   public static Boolean sendToPartner(String connectionName, Id recordId, Id parentRecordId) {
      return (sendToPartner(getConnectionId(connectionName), recordId, parentRecordId));
   } // sendToPartner

   public static Boolean sendToPartner(Id connectionId, Id recordId, Id parentRecordId) {
      Boolean sendOkay = false;
      if (connectionId != null && recordId != null) {
         PartnerNetworkRecordConnection newConnection = new PartnerNetworkRecordConnection(
                        ConnectionId = connectionId,
                        LocalRecordId = recordId,
                        SendClosedTasks = false,
                        SendOpenTasks = false,
                        SendEmails = false,
                        ParentRecordId = parentRecordId);
         connectionRecsToSend.add(newConnection);
         
      } // if (connectionId != null
      return sendOkay;
   } // sendToPartner
   
   public static String PARTNER_CONNECTION_NAME=Label.PartnerNeworkConnectionName;
   
   // send to the partner, assume no parent record
   public static Boolean sendToPartner(SObject[] recs) {
      Id connectionId = getConnectionId(Label.PartnerNeworkConnectionName);
      for (SObject rec : recs) {
         sendToPartner(connectionId, rec.Id, null);
      }
      return sendConnections();
   } // sendToPartner
   
   public static PartnerNetworkRecordConnection[] connectionRecsToSend = new PartnerNetworkRecordConnection[]{};
   
   public static Boolean sendConnections() {
      Boolean sendOkay = true;
      System.debug('sendConnections connectionRecsToSend='+connectionRecsToSend.size());
      if (!connectionRecsToSend.isEmpty()) {
         try {
            insert connectionRecsToSend;
            connectionRecsToSend.clear();
         } catch (Exception e) {
            sendOkay = false;
            System.debug('sendToPartner failed to send connections: '+e.getMessage()+'; '+e.getStackTraceString());
         }
      } // if (!connectionRecsToSend.isEmpty
      return sendOkay;
   } // sendConnections
   */
} // class SfToSfConnectionHelper