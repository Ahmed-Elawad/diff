/**
 * Controller for multi attachment component
 *
 * History
 * ------- 
 * 10/29/2017 Frank Lurz    Created 
   10/26/2018 Dan Carmen    Changing API Version to 44
  10/09/2020 Jake Hinds   Adding without sharing per PMD

 */
public without sharing class MultiAttachmentController 
{

    public boolean showMain {get;set;}
 
    // the parent object it
    public Id sobjId {get; set;}
    
    // list of existing attachments - populated on demand
    public List<Attachment> attachments;
    
    // list of new attachments to add
    public List<Attachment> newAttachments {get; set;}
    
    // the number of new attachments to add to the list when the user clicks 'Add More'
    public static final Integer NUM_ATTACHMENTS_TO_ADD=5;

    // constructor
    public MultiAttachmentController()
    {
        // instantiate the list with a single attachment
        showMain = TRUE;
        newAttachments=new List<Attachment>{new Attachment()};
    }   
    
    // retrieve the existing attachments
    public List<Attachment> getAttachments()
    {
        // only execute the SOQL if the list hasn't been initialised
        if (null==attachments)
        {
            attachments=[select Id, ParentId, Name, Description from Attachment where parentId=:sobjId];
        }
        
        return attachments;
    }

    // Add more attachments action method
    public void addMore()
    {
        save();
        // append NUM_ATTACHMENTS_TO_ADD to the new attachments list
        for (Integer idx=0; idx<NUM_ATTACHMENTS_TO_ADD; idx++)
        {
            newAttachments.add(new Attachment());
        }
    }    
    
    // Save action method
    public void save()
    {
        List<Attachment> toInsert=new List<Attachment>();
        for (Attachment newAtt : newAttachments)
        {
            if (newAtt.Body!=null)
            {
                newAtt.parentId=sobjId;
                toInsert.add(newAtt);
            }
        }
        insert toInsert;
        newAttachments.clear();
        newAttachments.add(new Attachment());
        
        // null the list of existing attachments - this will be rebuilt when the page is refreshed
        attachments=null;
    }
    
    // Action method when the user is done
    public PageReference done()
    {
        Save();
        ClientFieldSubmissionHelper.setSubmissionDone (sobjId);
        showMain = FALSE;
        return NULL;
    }
    

} //MultiAttachmentController