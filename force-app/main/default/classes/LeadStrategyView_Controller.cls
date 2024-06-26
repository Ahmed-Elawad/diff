/* 
 * The methods used display the lead strategy views to the users.
 *
 * History
 * -------
 * 04/02/2012 Cindy Freeman   Created
 * 01/20/2014 Cindy Freeman   Modified for Show My Zipcodes, only works on Leads and Accounts
 *
 */
public with sharing class LeadStrategyView_Controller {
    public ApexPages.StandardSetcontroller setCon {get; set;}
    
    public Integer listIdx;
    public Integer pageNumber {get; set; }
    public Integer lastpageNumber {get; set; }
    public Integer pagesize {get; set; }
    public Integer querylimit {get; set; }
            
    public Boolean hasChildren {get; set;}
    public String Viewname {get; set;}   
    public String controllerView {get; set;}
    public String detailId {get; set;}  
    public String sortObject {get; set;}
    public String sortField {get; set;}
    public String sortDir{get; set;}
    public Map<String, String> object_names {get; set;}
    
    public String sqlstmt {get; set;}   // need for test method
    
    public List<RecWrapper> viewResults{
        get  {
            if (records == null)
            {   SOQLRecords();  }   // put this in for component
            
            List<RecWrapper> partialList = new List <RecWrapper>();
            if (records != Null)  {
                Integer endIdx = ((listIdx + pagesize) > records.size() ? records.size() : listIdx + pagesize); 
                for (integer i = listIdx; i < endIdx; i++) 
                {   partialList.add(records.get(i));    }
            }               
            return partialList;
        }
        set;
    }
        
    //public PageReference emptypage() {
    //    return null;
    //}
    
    private ObjectHelper objectHelper = new ObjectHelper();
    
    public List<RecWrapper> records{get; set;}  
    public class RecWrapper {
       public SObject so{get;set;}
       public ChildWrapper sochild{get; set;}
       public String nameField{get;set;}
       public String soName{
          get{return (String)so.get(nameField);}
        }
    }
    public List<ChildWrapper> children{get; set;}
    public class ChildWrapper {
        public SObject child{get;set;}
        public String childnameField{get; set;}
        public String childName {
            get{return (String)child.get(childnameField);}
        }
    }

    public List<ParentFld> parentfields{get; set;}
    public class ParentFld {
        public String parentFldName{get; set;}
        public String parentFldLabel{get; set;}
    }    
     
    public List<ChildFld> childfields{get; set;}
    public class ChildFld {
        public String childFldName{get; set;}
        public String childFldLabel{get; set;}
    }       
    
    // List of views to pick from
    public List<SelectOption> getViewslist() {
        List<SelectOption> so = new List<SelectOption> ();
        so.add( new SelectOption('','-- Select a View --'));
        User runningUser = [Select Id, Name, HR_Person_Id__c, Sales_Org__c, Profile.Name, UserRole.ParentRoleId, Title from User where Id=:UserInfo.getUserId()];
        String viewsql = 'select Name, View_name__c, IsActive__c from Lead_Strategy_views__c ';
        if (runningUser.Profile.Name != 'System Administrator')
        {   viewsql += ' where IsActive__c = True ';    }
        viewsql += ' order by View_name__c';        
        Lead_Strategy_Views__c[] v = Database.query(viewsql);
        for( Lead_Strategy_Views__c lv : v )
            so.add( new SelectOption( lv.Name, lv.View_name__c ) );
        return so;
    }   

    public void SOQLRecords() { //
        ID UserID = Userinfo.getUserID();   // in case needed for a sql        
                                 
        If (controllerView != null)   
        {   Lead_Strategy_Views__c views = [SELECT ID, View_name__c, soql__c, Show_Account_Teams__c, limit__c, page_size__c, order_by__c,
                                            Show_My_Zipcodes__c, IsActive__c,
                                            parent_object__c, parent_fields__c,
                                            child_object__c, child_fields__c
                                                FROM Lead_Strategy_Views__c WHERE name = :controllerView];
            String tempsoql = views.soql__c.toLowerCase();                                                              
            Viewname = views.View_name__c;          
            pagesize = ((views.page_size__c != null && views.page_size__c > 0 && views.page_size__c < 99) ? (Integer)views.page_size__c : 20);
            querylimit = ((views.limit__c != null && views.limit__c > 0 && views.limit__c < 999) ? (Integer)views.limit__c : 100);
   
            populate_object_names(views.Parent_Object__c);      // need for permission check, translate plural label to singular, find lookupfields
            
            Set<ID> acctTeams = new Set<ID>();
            if (views.Show_Account_Teams__c) 
            {   for (AccountTeamMember atm : [Select accountid from accountteammember where userid = :UserID])
                {   acctTeams.add(atm.accountId);   }
                if (acctTeams.size() > 0)
                {   if (tempsoql.contains('ownerid = :userid') || tempsoql.contains('ownerid=:userid'))                     
                    {   integer i = tempsoql.indexof('ownerid',tempsoql.indexof('where'));
                        String x = tempsoql.substring(0,i) + '(ownerid = :userid or id in :acctteams)';                 
                        tempsoql = x;
                    }
                    else if (tempsoql.contains('where'))
                    {   tempsoql = tempsoql + ' and Id in :acctteams ';   }
                    else
                    {   tempsoql = tempsoql + ' where id in :acctteams';    }
                } // if acctTeams.size > 0 
            } // if Show_Account_Teams__c
            
            Set<String> zipcodeSet = new Set<String>();
            if (views.Show_My_Zipcodes__c)
            {   for (Zip_Assignment__c zip : [Select Name from Zip_Assignment__c where User__r.Id = :UserID])   // get list of rep's zip assignments
                {   zipcodeSet.add(zip.Name);   }
                if (zipcodeSet.size() > 0)
                {   String zipField = (views.Parent_Object__c == 'Account' ? 'Owner_ZipCode__c' : 'postalcode');                    
                    if (tempsoql.contains('ownerid = :userid') || tempsoql.contains('ownerid=:userid'))                     
                    {   integer i = tempsoql.indexof('ownerid',tempsoql.indexof('where'));
                        String x = tempsoql.substring(0,i) + '(ownerid = :userid or ' + zipField + ' in :zipcodeSet)';                 
                        tempsoql = x;
                    }
                    else if (tempsoql.contains('where'))
                    {   tempsoql = tempsoql + ' or ' + zipField + ' in :zipcodeSet ';   }
                    else
                    {   tempsoql = tempsoql + ' where ' + zipField + ' in :zipcodeSet';    }
                } // zipcodeSet.size > 0
            } // if Show_My_Zipcodes__c
            
            sqlstmt = tempsoql; 

            If (views.order_by__c != null)
            {   sqlstmt = sqlstmt + ' order by ' + views.order_by__c;   }
            
            sqlstmt = sqlstmt + ' limit ' + querylimit; 
System.debug('**CMF ** final sqlstmt='+sqlstmt);                                    
            String childObj = views.Child_Object__c;
            Boolean hasChildren = (childObj != null ? true : false);
        
            parentfields = new List<ParentFld>();
            childfields = new List<ChildFld>();
            
            String tempParentFields;
            if (views.Parent_Fields__c != Null)
            {   tempParentFields = views.Parent_Fields__c.replace(' ',''); 
                tempParentFields = tempParentFields.toLowerCase();
            }
            if (views.Parent_Fields__c != null)
            {   String objName;
                String fldName;                
                for (String p: tempParentFields.split(','))
                {   if (p.contains('.'))
                    {   objName = p.subString(0,p.indexOf('.'));
                        fldName = p.substring(p.indexOf('.')+1,p.length());
                    }
                    else
                    {   objName = views.parent_object__c;
                        fldName = p;  
                    }
                    objName = ((object_names.containsKey(objName)) ? object_names.get(objName) : objName);
                    Boolean goodfld = objectHelper.checkField(objName, fldName, 'access');                 
                    if (goodfld)
                    {   ParentFld pfld = new ParentFld();
                        pfld.parentFldName = p;                     
                        pfld.parentFldLabel = objectHelper.getFieldLabel(objName, fldName);                       
                        parentfields.add(pfld);
                    } // goodfld
                } // split parent fields
            } // if any parent fields

            String tempChildFields;
            if (views.Child_Fields__c != Null) 
            {   tempChildFields = views.Child_Fields__c.replace(' ','');  
                tempChildFields = tempChildFields.toLowerCase();
            }
            if (views.Child_Fields__c != null)
            {   String objName;
                String fldName;                
                for (String c: tempChildFields.split(','))
                {   if (c.contains('.'))
                    {   objName = c.subString(0,c.indexOf('.'));
                        fldName = c.substring(c.indexOf('.')+1,c.length());
                    }
                    else
                    {   objName = views.child_object__c;
                        fldName = c;  
                    }
                    objName = ((object_names.containsKey(objName)) ? object_names.get(objName) : objName);
                    String tempObjName = objName.replace('__r', '__c');
                    Boolean goodfld = objectHelper.checkField(tempObjName, fldName, 'access');          
                    if (goodfld)
                    {   ChildFld cfld = new childFld();
                        cfld.childFldName = c;
                        cfld.childFldLabel = objectHelper.getFieldLabel(tempObjName, fldname);                        
                        childfields.add(cfld);                     
                    } // goodfld
                } // split child fields
            } // if any child fields            
                                
            records = new List<RecWrapper>();
            //System.debug('**CMF ** final sqlstmt='+sqlstmt);
                    
            setCon = new ApexPages.StandardSetController(Database.Query(sqlstmt));
            SObject[] returnRecords = Database.query(sqlstmt);
        
            for (SObject so : returnRecords)
            {
                RecWrapper rw = new RecWrapper();
                rw.nameField='Name';
                rw.so = so;
                
                if (hasChildren)    
                {   RecWrapper[] rcds = getChildren(so.getSObjects(childObj), so);	
                     if (rcds.size() == 0)   // has no children
                    {   records.add(rw);    }
                    else  {                           
                        for (RecWrapper r : rcds)
                        {    records.add(r);    }                     
                    } //else
                }  // if hasChildren
                else
                {   records.add(rw);    }               
            } //for returnRecords       
        } // if view not Null
        listIdx = 0;
        pageNumber = 1;
        if (records != null)
        {   integer remainder = math.mod(records.size(), pagesize);
            lastpageNumber = records.size() / pagesize;
            lastpageNumber = (remainder > 0 ? lastpageNumber + 1 : lastpageNumber);
            lastpageNumber = (lastpageNumber == 0 ? 1 : lastpageNumber);
        }
        else
        {   lastpageNumber = 1; }
        // just for testing
        // if (sqlstmt != null) {  ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'sqlstmt= '+sqlstmt));  }        
    } // getSOQLRecords
     
    public RecWrapper[] getChildren(SObject[] qr, SObject parent) {
        RecWrapper[] rec = new List <RecWrapper>();
        if (qr == null)
        {   return rec;  }
        children = new List<ChildWrapper>();
        for (SObject kid : qr)  {           
            ChildWrapper cw = new ChildWrapper();
            cw.childnameField = 'Name';
            cw.child = kid;
            children.add(cw);

            RecWrapper rw = new RecWrapper();
            rw.nameField='Name';
            rw.so = parent;
            rw.sochild = cw;
            rec.add(rw); 
        }           
        return rec;
    }
    
   
    public PageReference sortRecords() {           
        if (sortDir == Null || sortDir == 'desc')
        {   sortDir = 'asc';    }
        else
        {   sortDir = 'desc';   }
        
        List<Object> sortValues = new List <Object>();
        Map<Object, List<RecWrapper>> presortRcds = new Map<Object, RecWrapper[]>();
        List<RecWrapper> sortedRcds = new List<RecWrapper>();
        Object sortKey;
        
        try {                   
            for (RecWrapper rec: records)   {   
                if ((sortObject == 'child') && (rec.sochild == null))   //code to handle sort of child field even if record has no children
                {   sortKey = null;
                    List <RecWrapper> temprcds = presortRcds.get(sortKey);
                    if (temprcds == Null)  {                
                        temprcds = new List<RecWrapper>();                    
                        presortRcds.put(sortKey,temprcds);                                      
                        sortValues.add(sortKey);                            
                    }
                    temprcds.add(rec);
                }
                else  
                {   if (sortField.contains('.')) {
                        String subObjectName = sortField.subString(0,sortField.indexOf('.'));
                        String subFieldName = sortField.substring(sortField.indexOf('.')+1,sortField.length()); 
                        SObject subObject = (sortObject == 'parent' ? (SObject)rec.so.getSObject(subObjectName) : (SObject)rec.sochild.child.getSObject(subObjectName));
                        sortKey = (String)subObject.get(subFieldName);
                    }   // end if '.'
                    else {
                        sortKey = ((sortObject == 'parent') ? rec.so.get(sortField) : rec.sochild.child.get(sortField));
                    }                  
                    List <RecWrapper> temprcds = presortRcds.get(sortKey);
                    if (temprcds == Null)  {            // is Key in preSort already?       
                        temprcds = new List<RecWrapper>();                    
                        presortRcds.put(sortKey,temprcds);                                      
                        sortValues.add(sortKey);                            
                    }
                    temprcds.add(rec);
                }                              
            }  // end for each rec                                      
            sortValues.sort();
            if (sortDir == 'asc') {
                for (Object val: sortValues) {              
                    sortedRcds.addAll(presortRcds.get(val));
                }
            }
            else  {      //sort desc                
                for(integer i = sortValues.size()-1; i >= 0; i--){
                    sortedRcds.addAll(presortRcds.get(sortValues[i]));
                }
            }  
         
            records = sortedRcds;
            listIdx = 0;
            pageNumber = 1;          
        }   // end try  
        catch (exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'Sorry you can not sort by that field. Please pick another one. Error = '+e.getMessage())); 
        }   // end catch
        return null;
    }   // end sortRecords
    
    public void populate_object_names (String objName) {   
        object_names = new Map<String, String>();
        
        Map<String, Schema.SObjectType> allObjects = Schema.getGlobalDescribe();
        Set <String> allObj = new Set <String>();
        allObj = allObjects.keySet();
        for (String o:allObj)
        {   sObjectType s = allObjects.get(o);
            Schema.DescribeSObjectResult r = s.getDescribe();
            String plural = r.getLabelPlural();
            String singular = r.getLabel();
            object_names.put(plural,singular);
        }
        // add look up field names for primary object so dont need a subquery
        Map<String, String> objLookups = objectHelper.getLookupFieldMap(objName);
        for (String fld :objLookups.keySet())
        {   String tempFld = fld.replace('__c', '__r');
            object_names.put(tempFld, objLookups.get(fld));     
        }
        object_names.put('AccountTeamMembers','AccountTeamMember');        
    } // populate_object_names       
  
    public Boolean hasNext {
        get { Boolean x;
              if (records != null) 
              {  x = (listIdx + pagesize < records.size() ? true : false); }
              else
              {  x = false; }   
            return x;
        }
        set;
    }
    public Boolean hasPrevious {
        get {Boolean x = (listIdx > 0 ? true : false);
            return x;
        }
        set;
    }
    public Boolean hasAnyRecords {
        get { Boolean x = (records != Null ? true : false); 
            return x;
        }
        set;
    }
    public void first() {
        listIdx = 0;
        pageNumber = 1;
    }
    public void last() {
        if (records.size() > 0)
        {   integer remainder = math.mod(records.size(), pagesize);
            listIdx = (remainder > 0 ? records.size() - remainder : records.size() - pagesize);
            pageNumber = math.round(records.size() / pagesize);
            pageNumber = (remainder > 0 ? pageNumber + 1 : pageNumber);
            pageNumber = (pageNumber == 0 ? 1 : pageNumber);
        }
        else
        {   listIdx = 0;    
            pageNumber = 1;
        }
    }
    public void previous() {
        listIdx = listIdx - pagesize;
        pageNumber = pageNumber - 1;
    }
    public void next() {
        listIdx = listIdx + pagesize;
        pageNumber = pageNumber + 1;
    }
        
}