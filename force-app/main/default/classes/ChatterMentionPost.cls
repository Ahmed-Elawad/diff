/*
  Class that creates a generic chatter post with up to two @mentions. If no userToMentionIds are specified, no post will be made.
  The post will be formatted as follows based on the passed in values:
    Hello @userToMentionId and @userToMentionId2 postText clientName postText2
  Example:
    For Id userToMentionId = userId.name
        Id userToMentionId2 = userId2.name
        String postText = '.  Client '
        String clientName = 'myClientName' <-- This doesn't have to be a client name. Since it's a string, it can be anything you want.
        String postText2 = ' currently has an open discrepancy that needs to be resolved.'

    The post would look like:
        Hello @userId and @userId2. Client myClientName currently has an open discrepancy that needs to be resolved.

  History
  -------
  02/01/2014  Justin Henderson   Created
  05/07/2014  Code Kata          add the createChatterMentionPost method
  11/04/2015  Dan Carmen         Modified to use the latest ConnectAPI methods
  03/11/2016  Dan Carmen         Add the sendPostsMentionPublicGroup method
  11/10/2016  Josh Cartwright    added branch client number to buildChatterMessage
  06/02/2017  Dan Carmen         Added in check for siloed tests
  12/20/2018  Dan Carmen         Add in a counter to check in test methods
  06/20/2019  Matt Fritschi      Added products selected to the a lead's chatter post.
  07/06/2020  Jacob Hinds        Added without sharing per PMD
  04/13/2021  Brandon Vidro      Added buildChatterMessage for Contact
  01/27/2023  Jidesh 			 Updated createChatterMentionPost method by adding logic to mention Referral Account for CPA
  06/19/2023  Susmitha Somavarapu  Creating a chatter post message to peo reps (APR0152220)

 */
public without sharing class ChatterMentionPost{
   
   public static void createChatterMentionPost(Id parentId, List<Id> userToMentionIdList, String[] postTexts, Boolean mentionsFirst) {
      createChatterMentionPost(parentId,userToMentionIdList, postTexts, mentionsFirst, true);
   }

   public static void createChatterMentionPost(Id parentId, List<Id> userToMentionIdList, String[] postTexts, Boolean mentionsFirst, Boolean postImmediately) {
      ConnectApi.FeedItemInput feedItemInput = new ConnectApi.FeedItemInput();
      ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();
      messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
     
      // set the parent of this feed item - what it's attached to
      feedItemInput.subjectId = parentId;

      if (mentionsFirst && !userToMentionIdList.isEmpty()) {
         ConnectApi.TextSegmentInput textSegmentInput = new ConnectApi.TextSegmentInput();
         textSegmentInput.text = 'Hello';
         messageBodyInput.messageSegments.add(textSegmentInput);
         getMentions(messageBodyInput, userToMentionIdList);
         textSegmentInput = new ConnectApi.TextSegmentInput();
         textSegmentInput.text = '. ';
         messageBodyInput.messageSegments.add(textSegmentInput);
      } // if (mentionsFirst
       
      // add the text to the post
      for (String postText : postTexts) {
          if(postText.startsWith('CPA_RA-')){
              ConnectApi.TextSegmentInput textSegmentInputNL = new ConnectApi.TextSegmentInput();
              textSegmentInputNL.text = '. \n ';
              messageBodyInput.messageSegments.add(textSegmentInputNL);
              //Creating the link for Account
              ConnectApi.EntityLinkSegmentInput entityLinkSegmentInputAccount = new ConnectApi.EntityLinkSegmentInput();
              entityLinkSegmentInputAccount.entityId = parentId;   
              messageBodyInput.messageSegments.add(entityLinkSegmentInputAccount);
              postText = postText.replace('CPA_RA-','');
          }
          // Creating a chatter post message to peo reps (APR0152220)
          else  if(postText.startsWith('PEO_OPP-Created-')){
                  ConnectApi.TextSegmentInput textSegmentInput = new ConnectApi.TextSegmentInput();
                  textSegmentInput.text = 'Hello';
                  messageBodyInput.messageSegments.add(textSegmentInput);
                  getMentions(messageBodyInput, New List<Id>{userToMentionIdList[0]});
                  textSegmentInput = new ConnectApi.TextSegmentInput();
                 // textSegmentInput.text = '. \n';
                //  messageBodyInput.messageSegments.add(textSegmentInput);
                  ConnectApi.TextSegmentInput textSegmentInputNL = new ConnectApi.TextSegmentInput();
                  textSegmentInputNL.text = ', \n \n ';
                  messageBodyInput.messageSegments.add(textSegmentInputNL);                  
                  postText = postText.replace('PEO_OPP-Created-','');
          } // APR0152220
         ConnectApi.TextSegmentInput textSegmentInput = new ConnectApi.TextSegmentInput();
         textSegmentInput.text = postText;
         messageBodyInput.messageSegments.add(textSegmentInput);
      } // for (String postText
     
      feedItemInput.body = messageBodyInput;
     
      if (!mentionsFirst) {
         getMentions(messageBodyInput, userToMentionIdList);
      } // if (!mentionsFirst)
       
       // Creating a Chatter Post Message for PEO Reps (APR0152220)
        if (postTexts[0].startsWith('PEO_OPP-Created-')) {    
            ConnectApi.TextSegmentInput textSegmentInputNL = new ConnectApi.TextSegmentInput();
            textSegmentInputNL.text = '. \n ';
            messageBodyInput.messageSegments.add(textSegmentInputNL);  
            ConnectApi.EntityLinkSegmentInput entityLinkSegmentInputProspect = new ConnectApi.EntityLinkSegmentInput();
            entityLinkSegmentInputProspect.entityId = parentId;  
            messageBodyInput.messageSegments.add(entityLinkSegmentInputProspect);        
            
           } // APR0152220

      addToFeedBatch(feedItemInput);
      if (postImmediately) {
         postBatchFeedElements();
      }

   } // createChatterMentionPost

   private static List<ConnectApi.FeedItemInput> feedItemsToPost = new List<ConnectApi.FeedItemInput>();
   
   public static void addToFeedBatch(ConnectApi.FeedItemInput feedItemInput) {
      feedItemsToPost.add(feedItemInput);
      System.debug('addToFeedBatch feedItemsToPost='+feedItemsToPost.size());
   } // addToFeedBatch
   
   // are any posts ready to post? If yes, post them!
   public static void checkPostFeedElements() {
      if (!feedItemsToPost.isEmpty()) {
         postBatchFeedElements();
      }
   } // checkPostFeedElements
   
   // keep track of how many feed items would have been posted - mostly for testing purposes.
   public static Integer feedItemsToPostSize = 0;
   
   public static void postBatchFeedElements() {
      feedItemsToPostSize = feedItemsToPost.size();
      System.debug('postBatchFeedElements feedItemsToPostSize='+feedItemsToPostSize);
      try {
      if (feedItemsToPost.size() == 1) {
         if (!Utilities.isTestSiloed()) {
            ConnectApi.FeedElement feedElement = ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), feedItemsToPost[0]);
         }
      } else if (feedItemsToPost.size() > 1) {
         List<ConnectApi.BatchInput> batchElements = new List<ConnectApi.BatchInput>();
         for (ConnectApi.FeedItemInput feedItem : feedItemsToPost) {
            ConnectApi.BatchInput batchInput = new ConnectApi.BatchInput(feedItem);
            batchElements.add(batchInput);
         } // for (ConnectApi.FeedItemInput feedItem
         if (!Utilities.isTestSiloed()) {
            ConnectApi.BatchResult[] postResults = ConnectApi.ChatterFeeds.postFeedElementBatch(Network.getNetworkId(), batchElements);
         }
      }
      } catch (Exception e) {
         ConnectApi.FeedItemInput item = feedItemsToPost[0];
         // use this so the code will print out the value
         Account acct = new Account(Description = String.valueOf(item));
         ErrorLog.logError('ChatterMentionPost', 'postBatchFeedElements', 'Post Chatter Messages', item.subjectId ,e, acct, true);
      }
      feedItemsToPost.clear();
   } // postBatchFeedElements
   
   public static void getMentions(ConnectApi.MessageBodyInput messageBodyInput, List<Id> userToMentionIdList) {
      if (!userToMentionIdList.isEmpty()) {
         // we only want to mention users or groups at this point.
         for (id userToMentionId : userToMentionIdList){
            if ((userToMentionId.getSObjectType() == user.sObjectType) || 
                (userToMentionId.getSObjectType() == CollaborationGroup.sObjectType)){
               // add a space between the names
               ConnectApi.TextSegmentInput textSegmentInput = new ConnectApi.TextSegmentInput();
               textSegmentInput.text = ' ';
               messageBodyInput.messageSegments.add(textSegmentInput);
              
               ConnectApi.MentionSegmentInput mentionSegmentInput = new ConnectApi.MentionSegmentInput();
               mentionSegmentInput.id = userToMentionID;
               messageBodyInput.messageSegments.add(mentionSegmentInput);
            }
         } // for (id userToMentionId
      } // if (!userToMentionIdList.isEmpty
   } // getMentions
  
   public static void createChatterMentionPost(Id parentId, List<Id> userToMentionIdList, String postText) {
      createChatterMentionPost(parentId, userToMentionIdList, new String[]{postText}, true, true);

    }//createChatterMentionPost
    
    public static boolean posted = TRUE;
    public static boolean postedOnce(){
        if(posted){
            posted=FALSE;
            system.debug('JGS Posted First' + posted);
            return true;
        }
        else{
            system.debug('JGS Posted second' + posted);
            return posted;
        }
    }
    
   public static String buildChatterMessage(Lead ld) {
      String chatterMsg = '';
      if (ld != null) {
         if(ld.Bank_Product_Of_Interest__c != null)
         {
             chatterMsg = buildChatterMessage(ld.Company, ld.Street, ld.City, ld.State, ld.PostalCode
                                         ,ld.FirstName+' '+ld.LastName, ld.Phone, ld.Email, ld.Bank_Product_Of_Interest__c
                                         ,String.valueOf(ld.NumberOfEmployees), ld.Frequency__c, ld.Current_Prior_Method__c, null);
                                         //jc added null parameter
         }
          else
          {
              chatterMsg = buildChatterMessage(ld.Company, ld.Street, ld.City, ld.State, ld.PostalCode
                                         ,ld.FirstName+' '+ld.LastName, ld.Phone, ld.Email, null
                                         ,String.valueOf(ld.NumberOfEmployees), ld.Frequency__c, ld.Current_Prior_Method__c, null);
                                         //jc added null parameter 
          }
         
      }
      return chatterMsg;
   } // buildChatterMessage
    
   public static String buildChatterMessage(Account acct, Contact ctct) {
      String chatterMsg = '';
      if (acct != null) {
         String street = String.isNotBlank(acct.ShippingStreet) ? acct.ShippingStreet : acct.BillingStreet;
         String city = String.isNotBlank(acct.ShippingCity) ? acct.ShippingCity : acct.BillingCity;
         String state = String.isNotBlank(acct.ShippingState) ? acct.ShippingState : acct.BillingState;
         String postalCode = String.isNotBlank(acct.ShippingPostalCode) ? acct.ShippingPostalCode : acct.BillingPostalCode;
         String ctctName = (ctct != null ? ctct.name : null);
         String ctctPhone = (ctct != null ? ctct.Phone : null);
         String ctctEmail = (ctct != null ? ctct.Email : null);
         //JC added Branchclient  to message
         String branchClient = (acct !=null && acct.AccountNumber != null ? acct.AccountNumber: null); 
         
         chatterMsg = buildChatterMessage(acct.Name, street, city, state, postalCode
                                         ,ctctName, ctctPhone, ctctEmail, null
                                         ,String.valueOf(acct.NumberOfEmployees), acct.Frequency__c, acct.Current_Prior_Method__c, branchClient);
      } // if (acct != null
      return chatterMsg;
   } // buildChatterMessage
    
    public static String buildChatterMessage(Contact ctct) {
        String chatterMsg = '';
        if (ctct != null) {
            String street = (ctct != null ? ctct.MailingStreet : null);
            String city = (ctct != null ? ctct.MailingCity : null);
            String state = (ctct != null ? ctct.MailingState : null);
            String postalCode = (ctct != null ? ctct.MailingPostalCode : null);
            String ctctName = (ctct != null ? ctct.name : null);
            String ctctPhone = (ctct != null ? ctct.Phone : null);
            String ctctEmail = (ctct != null ? ctct.Email : null);
            
            chatterMsg = buildChatterMessage(ctct.Name, street, city, state, postalCode
                                             ,ctctName, ctctPhone, ctctEmail, null
                                             ,null,null,null,null);
        }
        return chatterMsg;
    } // buildChatterMessage
   
   public static String buildChatterMessage(String compName, String street, String city, String state, String postalCode
                                           ,String contactName, String contactPhone, String contactEmail, String products
                                           ,String numberOfEmployees, String frequency, String currentMethod, String branchClient) {
      String chatterMsg = '';
      chatterMsg += addToChatterMsg('Company Name: ',compName);
      chatterMsg += addToChatterMsg('Company Street: ',street);
      chatterMsg += addToChatterMsg('Company City: ',city);
      chatterMsg += addToChatterMsg('Company State: ',state);
      chatterMsg += addToChatterMsg('Company Zip: ',postalCode);
      chatterMsg += addToChatterMsg('Contact Name: ',contactName);
      chatterMsg += addToChatterMsg('Contact Phone: ',contactPhone);
      chatterMsg += addToChatterMsg('Contact Email: ',contactEmail);
      if(products != null && products != '401(K)'){
          String formattedProducts = products.replace(';', ', ');
          chatterMsg += addToChatterMsg('Products: ',formattedProducts);
      }
      if(branchClient != null){
        chatterMsg += addToChatterMsg('Branch Client Number:', branchClient);
      }//if
      chatterMsg += addToChatterMsg('Number of Employees: ',numberOfEmployees);
      chatterMsg += addToChatterMsg('Frequency:  ',frequency);
      chatterMsg += addToChatterMsg('Current Method: ',currentMethod);
      return chatterMsg;
   } // buildChatterMessage
   
   public static String addToChatterMsg(String title, String value) {
      return (title + (String.isNotBlank(value) ? value : 'N/A') + '\n');
   } // addToChatterMsg
   
   // send series of posts to the members of a public group, the name of the group is stored in a custom setting under the passed in name
   // the key to the map is the id of the object, the value is the message to send 
   // stillSendIfNoMentions - do we still post if there is no group or the group is empty
   public static Boolean sendPostsMentionPublicGroup(String payxSettingName, Map<Id,String> notificationMap, Boolean stillSendIfNoMentions) {
      Boolean okay = true;
      // to account for running siloed tests
      stillSendIfNoMentions = (stillSendIfNoMentions && !(Test.isRunningTest() && Utilities.isTestSiloed()));

      if (!notificationMap.isEmpty()) {
         PaychexSettings__c setting = PaychexSettings__c.getInstance(payxSettingName);
         List<Id> chatterMentionIds = new List<Id>();
         if (setting != null && setting.IsActive__c) {
            String groupName = setting.Attribute1__c;
            if (String.isNotBlank(groupName)) {
               Group grp = new UserHelper().getGroup(groupName);
               if (grp != null) {
                  // get the group members
                  GroupMember[] grpMembers = [Select Id, UserOrGroupId from GroupMember where GroupId=:grp.Id];
                  for (GroupMember grpMember : grpMembers) {
                     // only add users
                     if (((String)grpMember.UserOrGroupId).startsWith(ObjectHelper.PREFIX_USER)) {
                        chatterMentionIds.add(grpMember.UserOrGroupId);
                     }
                  } // for (GroupMember grpMember
               } // if (grp != null
            } // if (String.isNotBlank
         } // if (setting != null &&
         
         if (stillSendIfNoMentions || !chatterMentionIds.isEmpty()) {
            for (Id recId : notificationMap.keySet()) {
               String msg = notificationMap.get(recId);
               createChatterMentionPost(recId, chatterMentionIds, new String[]{msg}, false, false);
            }
            postBatchFeedElements();
         } // if (!chatterMentionIds.isEmpty
      } // if (!notificationMap.isEmpty
      return okay;
   } // sendPostsMentionPublicGroup
   
} // class ChatterMentionPost