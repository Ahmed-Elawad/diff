/* 
 * Test the AttachmentMove class
 *
 * History
 * -------
 * 11/03/2011 Dan Carmen   Created
   10/29/2018 Dan Carmen   Increment API Version to 44

 */
@isTest
private class AttachmentMoveTest {

   static testMethod void testAttachments() {
      // call with null/empty values
      AttachmentMove.moveAttachments(null, null);
      Id[] ids = new Id[]{};
      AttachmentMove.moveAttachments(ids, null);
      Account acct1 = new Account(Name='Test Acct1');
      insert acct1;
      Account acct2 = new Account(Name='Test Acct2');
      insert acct2;
      AttachmentMove.moveAttachments(ids, acct2.Id);
      // set up an attachment on acct1
      // add an attachment
      Blob b = Blob.valueOf('This is a test');
      Attachment att = new Attachment(ParentId=acct1.Id, Name='Test.txt', Body=b);
      insert att;
      // verify no attachments on acct2
      System.assertEquals(0,[Select count() from Attachment where ParentId=:acct2.Id]);
      ids.add(att.Id);
      AttachmentMove.moveAttachments(ids, acct2.Id);
      // verify 1 attachment on acct2
      System.assertEquals(1,[Select count() from Attachment where ParentId=:acct2.Id]);
   } // testAttachments
   
} // class AttachmentMoveTest