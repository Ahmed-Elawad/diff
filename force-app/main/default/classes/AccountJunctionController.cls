/*
 * History
 * ---------
 * 04/21/2016 Cindy Freeman     created
 * 03/22/2017 Cindy Freeman     modified for new account junction code
   01/08/2020 Dan Carmen        Increment API version
 
 */
public without sharing class AccountJunctionController {

    public Account childAcct{get; set;}    
    public Account parentAcct{get; set;}
    public Account_Junction__c junc{get; set;}
    public Id acctId{get; set;}
    public Boolean juncSaved{get; set;}
    public Boolean alreadyLinked{get; set;}
    public Boolean showSave{get; set;}
    public Boolean showCancel{get; set;}
    
    /** Default constructor
    */
    public AccountJunctionController(ApexPages.StandardController stdController) {
      User runningUser = [Select Id, Cost_Center__c, Sales_Org__c, Profile.Name, UserRole.Name from User where Id = :UserInfo.getUserId()];
      acctId = System.currentPageReference().getParameters().get('Id');
      alreadyLinked = false;
      showSave = showCancel = true;      
      if (!setChildAcct(acctId)) 
      {  ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'Invalid Id or Prospect-Client record type'));    }      
      else if (!alreadyLinked)
      {   junc = new Account_Junction__c();  }
      juncSaved = false;
      
    } // default construction 
    
    
    /* get child account info
     */
    public Boolean setChildAcct(Id acctId) {
        Boolean ans = true;
        childAcct = [Select Id, Name, NumberofEmployees, X401K_Assets__c, RecordTypeId, RecordType.Name from Account where Id = :acctId];
        //Schema.RecordTypeInfo rtObj = RecordTypeHelper.getRecordTypeById(childAcct.RecordTypeId, 'Account');         
        //String childSalesOrg = RecordTypeHelper.getSalesOrgForRecordTypeName(rtObj.getName());        
        if (childAcct == null || (childAcct.RecordType.Name != RecordTypeHelper.CORE_ACCOUNT && childAcct.RecordType.Name != RecordTypeHelper.MMS_ACCOUNT))
        {   ans = false;    }
        else
        {
            List<Account_Junction__c> juncList = [select Id, Parent_Account__r.Id, Parent_Account__r.Name, 
                                        Child_Account__r.Id, Child_Account__r.Name, Child_Account__r.SalesParent__c, Type__c 
                                        from Account_Junction__c where Parent_Account__r.Id = :acctId or Child_Account__r.Id = :acctId];
                                        
            Map<Id, Account_Junction__c[]> parentJuncMap = new Map<Id, Account_Junction__c[]>();        //map of parent id with list of Account_Junction__c
            Map<Id, Account_Junction__c[]> childJuncMap = new Map<Id, Account_Junction__c[]>();         // map of child id with list of Account_Junction__c
            for (Account_Junction__c junc: juncList)
            {   if (junc.Parent_Account__r.Id == acctId)
                {   List<Account_Junction__c> parentTemp = parentJuncMap.get(acctId);
                    if (parentTemp == null)
                    {   parentTemp = new List<Account_Junction__c>();                   
                        parentJuncMap.put(acctId, parentTemp);
                    }
                    parentTemp.add(junc);
                } // if (junc.parent_Account__r.Id
                if (junc.Child_Account__r.Id == acctId)
                {   List<Account_Junction__c> childTemp = childJuncMap.get(acctId);
                    if (childTemp == null)
                    {   childTemp = new List<Account_Junction__c>();                    
                        childJuncMap.put(acctId, childTemp);
                    }
                    childTemp.add(junc);
                } // if (junc.Child_Account__r.Id
            } // for juncList
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'parentmap size='+parentJuncMap.size()+' childmap size='+childJuncMap.size()));
                                                
            if (parentJuncMap.containsKey(acctId))
            {    ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'You are already a Parent account.  You can not become a child to another account.'));    
                 alreadyLinked = true;
                 showSave = false;
            }
            if (childJuncMap.containsKey(acctId))        
            {   Account_Junction__c[] tempList = childJuncMap.get(acctId); 
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'You are already linked to '+tempList.get(0).Parent_Account__r.Name+' You can not be linked to an additional parent.'));
                alreadyLinked = true;
                showSave = false;   
            }
        } // else
        return ans;
    } // setChildAcct
     
    /* cancel and go back to Account you started on
     */
   public PageReference cancel() {
      PageReference returnPr = new PageReference('/'+childAcct.Id);
      return returnPr;
   } // cancel
    
   /* update and save junction record
    */
    public void save() {
        Boolean result = false;  
        if (acctId == junc.Parent_Account__c)
        {    ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'You can not link this Account to itself.  Pick another Account.'));    }
        else   
        {   List<Account_Junction__c> juncList = [select Id, Parent_Account__r.Id, Parent_Account__r.Name, Child_Account__r.Id, Child_Account__r.Name, Type__c 
                                        from Account_Junction__c where child_Account__r.Id = :junc.Parent_Account__c];                                                                              
            if (!juncList.isEmpty() && juncList.size()>0)
            {    ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'You can not link to this Account.  It is already a Child Account.'));  }
            else 
            {    /*junc.Employees__c = childAcct.NumberofEmployees;
                 junc.Assets__c = childAcct.X401K_Assets__c;
                 junc.Child_Account__c = childAcct.Id;
                 insert junc;            
                 Account kid = [Select Id, SalesParent__c from Account where Id = :acctId];                      
                 if (kid.SalesParent__c != junc.Parent_Account__c) {
                     kid.SalesParent__c = junc.Parent_Account__c; 
                     update kid;
                 }
                 result = true;
                 */
                 Account parentAcct = [Select Id, Name, NumberofEmployees, X401K_Assets__c, RecordTypeId, RecordType.Name from Account where Id = :junc.Parent_Account__c];
                 if (parentAcct.RecordType.Name != RecordTypeHelper.CORE_ACCOUNT && parentAcct.RecordType.Name != RecordTypeHelper.MMS_ACCOUNT)
                 {  ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'You can not link to this Account.  The Parent must be a Core or MMS record type.'));  }
                 else     
                 {   //Map<Id, Id> childParentMap = new Map<Id, Id>();
                     //childParentMap.put(acctId, junc.Parent_Account__c);
                     //AccountJunctionMethods.createJunction(childParentMap,junc.Type__c);
                     junc.Employees__c = childAcct.NumberofEmployees;
                     junc.Assets__c = childAcct.X401K_Assets__c;
                     junc.Child_Account__c = childAcct.Id;
                     insert junc;
                     Account kid = [Select Id, SalesParent__c from Account where Id = :acctId];                      
                     if (kid.SalesParent__c == null || (kid.SalesParent__c != junc.Parent_Account__c)) {
                         kid.SalesParent__c = junc.Parent_Account__c; 
                         update kid;
                     }   
                     ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'Junction has been Saved.'));
                     result = true;
                     showCancel = showSave = false;
                 } // else if (parentAcct.RecordType.Name...
            } // else if (!junclist.isEmpty()...
        } // else if (acctId == junc.Parent_Account__c) 
        juncSaved = result;
        //showSave = !result;        
    } // save
    
    public PageReference returntoAcct() {
             PageReference returnPr = new PageReference('/'+childAcct.Id);
             return returnPr;
    } // returntoAcctd
    
    
    
    
}