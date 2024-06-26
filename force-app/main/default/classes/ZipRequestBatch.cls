/* 
  Batch up the open zip requests and send them to NSS.
     
  History
  -------
  02/12/2014 Dan Carmen   Created
  10/22/2014 Dan Carmen   Comment out code - no longer needed.
  11/30/2023 Dan Carmen   This code CanBeDeleted
   
 */
global with sharing class ZipRequestBatch { //implements Database.Batchable<SObject>, Database.Stateful , Schedulable {
    public ZipRequestBatch() {}

} // class ZipRequestBatch