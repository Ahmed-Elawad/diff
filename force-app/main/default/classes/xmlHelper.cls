/*
 *  This class parses xml files and assigns the values to any matching fields on the passed in object or sObject.  
 *
 * History
 * --------
 * 10/25/2013   Justin Stouffer created 
 * 03/19/2014	Cindy Freeman	modified, added try/catch to throw back any error that prevents parsing
 */
public class xmlHelper {
 
 public string objName;
 public boolean isSObj;
 public Set<String> fieldsPresent;
 public sObject xmlSObject; //The sObject created and populated with the xml values
 public object xmlObject; //The object created and populated with the xml values
    
 public xmlHelper(string obj, string inputXML){
    objName = obj;
    inputXML = inputXML.trim();
    inputXML = inputXML.replaceAll('%(?![0-9a-fA-F]{2})', '%25');//Escape characters that will break the URLDecoder that SF uses
    inputXML = inputXML.replaceAll('\\+', '%2B');
    inputXML = inputXML.replaceAll('"', '');
    inputXML = inputXML.replaceAll('&', '%26');
    inputXML = inputXML.replaceAll('\n', '');// Remove newline/carriage returns.
    inputXML = inputXML.replaceAll('\r', '');
    System.debug('***JGS ** inputXML = ' + inputXML); 
    isSObj = sObjCheck();     
	try {    
 	  If (isSObj){
        xmlSObject = newSObject(objName); 
        //Get a Set containing the names of all of the fields possible for the Object Type passed in
        fieldsPresent = sObjFieldNames(objName);
        //Pass the input XML string and parse it
        XmlStreamReader xsr = new XmlStreamReader(inputXML); 
        parseXmlNodes(xsr);
 	  } // if (isSObj)
 	  else{
        type t = Type.forName(objName);
        xmlObject = t.newInstance();
        System.debug('***JGS ** xmlObject = ' + xmlObject);  
        fieldsPresent = classFieldNames(xmlObject);
        System.debug('***JGS ** fieldsSet = ' + fieldsPresent); 
        //Pass the input XML string and parse it
        XmlStreamReader xsr = new XmlStreamReader(inputXML); 
        parseXmlNodes(xsr);
 	  } // else
	} // try
	catch (Exception e)
	{	throw new SaveException(e.getMessage());	}
	
 } // xmlHelper
 
 public class SaveException extends Exception {}
  
 private boolean sObjCheck(){
    list<Schema.SObjectType> sObjcts = Schema.getGlobalDescribe().Values(); 
    set<string> allsObjcts = new set<string>();
    set<string> allClasses = new set<string>();
    for(Schema.SObjectType so : sObjcts){
           allsObjcts.add(so.getDescribe().getLabel().toUpperCase());
    }
    If (objName != NULL && allsObjcts.contains(objName.toUpperCase())){
        return TRUE;    
    }
    return FALSE;
 }//sObjCheck - Checks to determine if needs to process as sObject or Object(Instantiated Class)
 
 public set<String> sObjFieldNames(string sObjName) {
    Map<string, Schema.SObjectType> gd = Schema.getGlobalDescribe(); 
    Schema.SObjectType stype = gd.get(sObjName);
    Map<string, Schema.SobjectField> fieldMap = stype.getDescribe().fields.getMap(); 
    Set<string> fieldsSet = new Set<String>();
    for(string s: fieldMap.keyset().clone()){
        fieldsSet.add(s.toUpperCase());
    } 
    return fieldsSet;
 }// sObjFieldNames - Returns a set of available fields for an sObject name passed through as a string.
 
 public set<string> classFieldNames(object objct){
    String objS = JSON.serialize(objct);
    // Deserialize it back into a key/value map
    Map<String,Object> fMap = (Map<String,Object>) JSON.deserializeUntyped(objS);
    System.debug('***JGS ** fMap before = ' + fMap); 
    Set<string> fieldsSet = new Set<String>();
    // Return a Set of those fields present on our object
    for(string s: fMap.keyset().clone()){
        fieldsSet.add(s.toUpperCase());
    }
    return fieldsSet;       
 }// classFieldNames - Returns a set of available variables for a class passed through as a generic object.
 
 public static SObject newSObject(String sObjType) {
    Schema.SObjectType targetType = Schema.getGlobalDescribe().get(sObjType);
    return targetType.newSObject();
 }// newSObject - Creates an instance of the Generic sObject with the type passed in as a string.
      
 public void parseXmlNodes(XmlStreamReader reader) {
    string elementName = NULL;
    string mapString = '{';
     while(reader.hasNext()) {
        if (reader.getEventType() == XmlTag.START_ELEMENT) {
            if(fieldsPresent.contains(reader.getLocalName().toUpperCase())){
                elementName = reader.getLocalName();
            }
            else{
                elementName = NULL;
            }
        } 
        else if (reader.getEventType() == XmlTag.CHARACTERS && !reader.isWhitespace()
                    && elementName != NULL){
            if(isSObj){
                xmlSObject.put(elementName, getDecodedString(reader));
            }
            else{
                mapString += '"' + elementName + '":"' + getDecodedString(reader) + '",';
            }
            system.debug('*** JGS Element URI' + reader.getNamespace());            
        }
        reader.next();
     }     
     if(!isSObj){
        mapString = mapString.removeEnd(',');
        mapString += '}';
        System.debug('***JGS ** mapString = ' + mapString);
        type ot  = Type.forName(objName);
        xmlObject = (object)JSON.deserialize(mapString, ot);
     } 
   }//parseXMLNodes - Parses an XML String passed in and sets the fields of a generic sObject (xmlSObject) or the variables in a class (xmlObject)
       
string getDecodedString(Xmlstreamreader reader)
  {
    return EncodingUtil.urlDecode(reader.getText(), 'UTF-8').trim();
  }

}