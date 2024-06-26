/* 
   Tests for the Sequence and SequenceDetail triggers.
   
  History
  -------
   02/01/2012 Dan Carmen   Created
   02/11/2014 Dan Carmen   Commented out code
   
 */
@isTest
public class SequenceTest {

   /*
   public static User coreUser;
   public static User mmsUser;
   
   public static void setupTestUsers() {
      AccountCheckSequence.group1DistSet.clear();
      AccountCheckSequence.group2DistSet.clear();

      // get a user in one of the districts
      coreUser = [Select Id, Name, Sales_Org__c, District__c from User where IsActive=true and Sales_Org__c = :UserHelper.SO_CORE and District__c like '0%' limit 1];
      mmsUser = [Select Id, Name, Sales_Org__c, District__c from User where IsActive=true and Sales_Org__c = :UserHelper.SO_MMS and District__c like '4%' limit 1];
      AccountCheckSequence.group1DistSet.add(coreUser.District__c);
      AccountCheckSequence.group2DistSet.add(mmsUser.District__c);
   } // setupTestUsers
   
   /** Setup test sequence data. Set anything already there to inactive
    */
    /*
   public static Sequence__c[] setupTestData() {
      // query for any existing data
      Sequence__c[] existingSeqs = [Select Id, IsActive__c from Sequence__c where IsActive__c=true];
      // if data, inactivate the records
      if (!existingSeqs.isEmpty()) {
         for (Sequence__c seq : existingSeqs) {
            seq.IsActive__c = false;
         }
         update existingSeqs;
      } // if (!existingSeqs

      // tests for the trigger
      // try with bad record type name
      Sequence__c seq0 = new Sequence__c(Name='TestMethod seq1',IsActive__c=true,Default_Start_Days__c=0, Nbr_Emps_Low__c=0, Nbr_Emps_High__c=10, RecordTypeName__c='This is a bad record type name');
      Database.SaveResult result = Database.insert(seq0,false);            
      // verify that failed
      System.assertEquals(false,result.isSuccess());
      
      // create new Sequences
      Sequence__c seq1 = new Sequence__c(Name='TestMethod seq1',IsActive__c=true,Default_Start_Days__c=0, Nbr_Emps_Low__c=0, Nbr_Emps_High__c=10, RecordTypeName__c=RecordTypeHelper.CORE_ACCOUNT, Valid_Group__c='Group1;');
      Sequence__c seq2 = new Sequence__c(Name='TestMethod seq1',IsActive__c=true,Default_Start_Days__c=0, Nbr_Emps_Low__c=11, Nbr_Emps_High__c=9999, RecordTypeName__c=RecordTypeHelper.CORE_ACCOUNT, Valid_Group__c='Group1;');
      Sequence__c seq3 = new Sequence__c(Name='TestMethod seq1',IsActive__c=true,Default_Start_Days__c=14, Nbr_Emps_Low__c=0, Nbr_Emps_High__c=9999, RecordTypeName__c=RecordTypeHelper.MMS_ACCOUNT, Valid_Group__c='Group2;');
      Sequence__c[] seqs = new Sequence__c[]{seq1,seq2,seq3};
      Database.SaveResult[] results = Database.insert(seqs,false);
      // verify all were successful
      for (Database.SaveResult sr : results) {
         System.assertEquals(true,sr.isSuccess());
      }
      
      // create details for all
      Sequence_Detail__c[] details = new Sequence_Detail__c[]{};
      createDetails(seq1,details,false);
      createDetails(seq2,details,false);
      createDetails(seq3,details,true);
      insert details;
      
      Sequence__c[] sequences = getSequences();
      Sequence__c[] retVals = new Sequence__c[]{};
      retVals.add(getSeq(seq1.Id,sequences));
      retVals.add(getSeq(seq2.Id,sequences));
      retVals.add(getSeq(seq3.Id,sequences));
      return retVals;
   } // setupTestData

   public static Sequence__c[] getSequences() {
      Sequence__c[] seqs = [Select Id
                                ,Name
                                ,Default_Start_Days__c
                                ,IsActive__c
                                ,Nbr_Emps_Low__c
                                ,Nbr_Emps_High__c
                                ,RecordTypeId__c
                                ,RecordTypeName__c
                                ,Start_Week__c
                                ,Valid_Group__c
                                ,(Select Id
                                        ,Sequence_Stage__c
                                        ,Week_Start__c
                                        ,Week_End__c
                                    From Sequence_Details__r
                                   order by Week_Start__c)
                            From Sequence__c];
      return seqs;
   } // getSequences
   

   private static Sequence__c getSeq(Id seqId, Sequence__c[] sequences) {
      Sequence__c foundVal = null;
      for (Sequence__c seq : sequences) {
         if (seq.Id == seqId) {
            foundVal = seq;
            break;
         }
      } // for
      return foundVal;
   } // getSeq
   
   private static void createDetails(Sequence__c seq,  Sequence_Detail__c[] details, Boolean useNegOne) {
      if (useNegOne) {
         details.add(new Sequence_Detail__c(Name='Neg One',Sequence__c=seq.Id, Sequence_Stage__c='Stage 0', Week_Start__c=-1, Week_End__c=0));
      }
      details.add(new Sequence_Detail__c(Name='Stage One',Sequence__c=seq.Id, Sequence_Stage__c='Stage 1', Week_Start__c=1, Week_End__c=2));
      details.add(new Sequence_Detail__c(Name='None',Sequence__c=seq.Id, Sequence_Stage__c=null, Week_Start__c=3, Week_End__c=3));
      details.add(new Sequence_Detail__c(Name='All',Sequence__c=seq.Id, Sequence_Stage__c='Stage 3', Week_Start__c=4, Week_End__c=null));
      
   } // createDetails
   

   static testMethod void testTriggers() {
        setupTestData();
   } // 
   
   */
} // class SequenceTest