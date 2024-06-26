/* 
 * move attachments from one parent to another
 *
 * History
 * -------
 * 11/03/2011 Dan Carmen   Created
   10/29/2018 Dan Carmen   Increment API Version to 44

 */
global with sharing class AttachmentMove {

   static webservice void moveAttachments(Id[] attachIds, Id newParentId) {
   	  if (newParentId != null && attachIds != null && !attachIds.isEmpty()) {
   	     Attachment[] atts = [SELECT Id, Name, ParentId
   	                                ,ContentType,BodyLength
   	                                ,Description, Body, IsPrivate
   	                            FROM Attachment
   	                           WHERE Id IN :attachIds];
   	     Attachment[] attachInsert = new Attachment[]{};
   	     for (Attachment att : atts) {
   	        Attachment newAtt = new Attachment();
   	        newAtt.ParentId = newParentId;
   	        newAtt.Name = att.Name;
            newAtt.Body = att.Body;
            newAtt.IsPrivate = att.IsPrivate;
   	        attachInsert.add(newAtt);
   	     }
   	     if (!attachInsert.isEmpty()) {
   	        insert attachInsert;
   	        delete atts;
   	     }
   	  }
   } //moveAttachments
   
} // class AttachmentMove