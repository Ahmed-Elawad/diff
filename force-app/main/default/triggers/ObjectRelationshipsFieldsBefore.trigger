/**
 *
 * check for valid data and fill in some fields before record is inserted or updated
 * 
 * History
 * -------
 * 3/7/2012 Cindy Freeman   created
 * 9/23/2013 Cindy Freeman  modified to allow recordID in field constant to put in related object lookup field
 * 10/06/2013 Cindy Freeman modifed to use longer FilterCriteria field
 * 1/29/2014 Justin Henderson added check for related object queue verification and field lengths
 * 5/5/2014  Cindy Freeman    fixed bug for constants that were less than 4 characters 
 */
        
    
trigger ObjectRelationshipsFieldsBefore on Object_Relationships_Fields__c (before insert, before update) {
     ObjectHelper oHelper = new ObjectHelper();

     Set<Id> listObjRelIds = new Set<Id>();
     for (Integer i = 0; i < Trigger.new.size(); i++)
     {  listObjRelIds.add(Trigger.new[i].Object_Relationships__c);  }
     
     Map<Id, Object_Relationships__c> mapObjRel = new Map<Id, Object_Relationships__c>();
     Object_Relationships__c[] listObjRel = [Select Id
                                                , Primary_Object__c
                                                , Primary_Object_API_name__c
                                                , Primary_Object_Rcd_Type_Id__c
                                                , Primary_Object_Rcd_Type__c
                                                , Related_Object__c
                                                , Related_Object_API_name__c
                                                , Related_Object_Rcd_Type_Id__c
                                                , Related_Object_Rcd_Type__c 
                                                from Object_Relationships__c where Id in :listObjRelIds];
     for (Object_Relationships__c orc : listObjRel)
     {  mapObjRel.put(orc.Id, orc); }                                               
     
     // check that field names are valid and are of the same type
     for (Integer i = 0; i < Trigger.new.size(); i++ )
     {  Object_Relationships_Fields__c orf = Trigger.new[i];
        Boolean okay = true;
        Boolean goodfld = false;        
        
        // check primary field is valid, fill in primary object if blank
        if (orf.Primary_Object_API_name__c == null)
        {   Trigger.new[i].Primary_Object_API_name__c = mapObjRel.get(Trigger.new[i].Object_Relationships__c).Primary_Object_API_name__c;   }
        
        if (orf.Primary_Field_API_name__c != null)
        {   if (orf.Primary_Field_API_name__c.contains('Owner.'))
            {   String[] compoundFields = orf.Primary_Field_API_name__c.split('\\.');
                if (compoundFields.size() != 2)
                {   Trigger.new[i].Primary_Field_API_name__c.addError('invalid Primary Field, check spelling for valid User field   '); }
                else
                {   goodfld = oHelper.checkField('User', compoundFields.get(1));
                    if (!goodfld)
                    {   Trigger.new[i].Primary_Field_API_name__c.addError('invalid Primary Field, please check your spelling and try again');   
                        okay = false;
                    }
                    else
                    {   Trigger.new[i].Primary_Field_type__c = oHelper.getFieldSoapType('User', compoundFields.get(1)); }
                } // else
            } // if contains Owner
            else
            {   goodfld = oHelper.checkField(orf.Primary_Object_API_name__c, orf.Primary_Field_API_name__c, 'access');                 
                if (!goodfld)
                {   Trigger.new[i].Primary_Field_API_name__c.addError('invalid Primary Field, please check your spelling and try again');   
                    okay = false;
                }
                else
                {   Trigger.new[i].Primary_Field_type__c = oHelper.getFieldSoapType(orf.Primary_Object_API_name__c, orf.Primary_Field_API_name__c); }
            } // else
        } // if primary fld != null
                
        if (orf.Primary_Relationship_API_name__c != null)           
            // get primary object from orc and use relationship name as field name
        {   Object_Relationships__c orc = mapObjRel.get(Trigger.new[i].Object_Relationships__c);
            goodfld = oHelper.checkField(orc.Primary_Object_API_name__c, orf.Primary_Relationship_API_name__c, 'access');
            if (!goodfld)
            {   Trigger.new[i].Primary_Relationship_API_name__c.addError('invalid Primary Relationship, please check your spelling and try again'); 
                okay = false;
            }
        }
     
                
        // check related field is valid, fill in related object
        if (orf.Related_Object_API_name__c == null)
        {   Trigger.new[i].Related_Object_API_name__c = mapObjRel.get(Trigger.new[i].Object_Relationships__c).Related_Object_API_name__c;   }
        
        if (orf.Related_Field_API_name__c != null)
        {   goodfld = oHelper.checkField(orf.Related_Object_API_name__c, orf.Related_Field_API_name__c, 'access');
            if (!goodfld)
            {   Trigger.new[i].Related_Field_API_name__c.addError('Invalid Related Field, please check your spelling and try again');
                okay = false;
            }
            else if ( orf.Field_Constant__c == NULL && 
                      orf.Primary_Field_API_name__c != NULL && orf.Primary_Object_API_name__c != NULL && 
                      orf.Related_Field_API_name__c != NULL && orf.Related_Object_API_name__c != NULL &&
                     (ohelper.getFieldLength(orf.Related_Object_API_name__c,orf.Related_Field_API_name__c) <
                ohelper.getFieldLength(orf.Primary_Object_API_name__c, orf.Primary_Field_API_name__c))){
                Trigger.new[i].Related_Field_API_name__c.addError('Invalid Related Field, please ensure that the lengths match and try again');
                okay = false;
            }
            if(okay){
                Trigger.new[i].Related_Field_type__c = oHelper.getFieldSoapType(orf.Related_Object_API_name__c, orf.Related_Field_API_name__c); 
                // may need to change Opportunity to Opportunity__r for Case to Reference Object        
            }
        } // if related field != null
        
        // fill in primary field type if using field constant
        if (orf.Field_Constant__c != null)      
        {   if (orf.Field_Constant__c == 'True' || orf.Field_Constant__c == 'False')
            {   Trigger.new[i].Primary_Field_type__c = 'BOOLEAN';   }
            else if (orf.Field_Constant__c.containsOnly('0123456789.,'))
            {   Trigger.new[i].Primary_Field_type__c = 'DOUBLE';    }
            else if ((orf.Field_Constant__c.length()>4)&&(orf.Field_Constant__c.substring(0,4)=='(ID)'))
            {   Trigger.new[i].Primary_Field_type__c = 'ID';
                orf.Field_Constant__c = orf.Field_Constant__c.substring(4);             // take (ID) off constant               
            } 
            else
            {   Trigger.new[i].Primary_Field_type__c = 'STRING';    }
        } // if field_constant != null
        
        // make sure queue name is valid and fill in primary field type if using queue
       if (orf.Queue__c != null){   
           QueueSobject[] QSgrp = [Select SobjectType, QueueID, Queue.Type, Queue.Name, Queue.Id
                                            From QueueSobject 
                                            where Queue.Name = :orf.Queue__c 
                                            and SobjectType = :orf.Related_Object_API_name__c
                                            limit 1];
           if (QSgrp.size() == 0)
           {   Trigger.new[i].Queue__c.addError('Invalid Queue name or Object type not associated with Queue. Please correct this and try again.');
                   okay = false;
           }
           else
           {   Trigger.new[i].Queue_Id__c = QSgrp.get(0).Queue.Id;
            Trigger.new[i].Primary_Field_type__c = 'ID';
           }   
       }
        
        // is this a filter criteria record?
        if (orf.IsFilter__c)
        {   if (orf.FilterCriteria__c == null)
            {   Trigger.new[i].FilterCriteria__c.addError('Please fill in criteria or uncheck the Use as Criteria checkbox');  
                okay = false;
            }
            else if (orf.Primary_Field_API_name__c == null)
            {   Trigger.new[i].FilterCriteria__c.addError('Please fill in Primary Field API name to use with criteria');   
                okay = false;
            }
            if (orf.Related_Field_API_name__c != null)
            {   Trigger.new[i].Related_Field_API_name__c.addError('Please put filter criteria and field mappings in separate records'); 
                okay = false;
            }
            // clean up Null or Not Null criteria
            String tempStr = orf.FilterCriteria__c.toLowerCase();
            if (tempStr == 'null') 
            {   orf.FilterCriteria__c = 'null';    }
            if (tempStr == 'not null')
            {   orf.FilterCriteria__c = 'not null';    }           
        } // if IsFilter__c
        
        // must have either a constant,queue name or the primary field
        if (orf.Primary_Field_API_name__c == null && orf.Field_Constant__c == null && orf.Queue__c == null)
        {   Trigger.new[i].Primary_Field_API_name__c.addError('You must enter a Field Constant, Queue or the Primary Field API name.');
            okay = false;
        }
 
        //check field types
        if (okay)
        {   if (orf.Primary_Field_type__c != orf.Related_Field_type__c && !orf.IsFilter__c)
            {   Trigger.new[i].Related_Field_API_name__c.addError('Field types do not match, please try again, pri type='+orf.Primary_Field_type__c+' related type='+orf.Related_Field_type__c);    
                okay = false;
            } // if !(primary type = related type)
        } // if okay

     } // for Trigger
        
        
}