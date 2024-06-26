/*
 *  The test class for the xmlHelper Class.  
 *
 * History
 * --------
 * 10/25/2013	Justin Stouffer	created	
 */

@isTest
public class xmlHelperTest {
	
	
	static testMethod void testXMLSobjectRead(){
		
		string xml = '<note><firstname>Test</firstname><lastname>Testing</lastname><company>CMF+ Testing & Consultants %</company><email>test@testing.com</email></note>';
		xmlHelper testHelper = new xmlHelper('lead',xml);			
		System.debug('***JGS ** testHelper.listRecords = ' + testHelper.xmlSobject);
		lead l = (lead)testHelper.xmlSObject;
		System.assertEquals('test@testing.com',l.email);
		System.assertEquals('Test',l.firstname);
        System.assertEquals('Testing',l.lastname);
        System.assertEquals('CMF+ Testing & Consultants %',l.company);
	}
	
	static testMethod void testXMLClassRead(){
		
		string xml = '<note><firstname>Test</firstname><lastname>Testing</lastname><company>CMF+ Testing & Consultants %</company><email>test@testing.com</email><phone>585-123-4567</phone><street>10 Main St</street><city>Anytown</city><state>NY</state><zip>14543</zip></note>';
		xmlHelper testHelper = new xmlHelper('xmlHelperTest.testLead',xml);
		testLead tl = (testLead)testHelper.xmlObject;			
		System.debug('***JGS ** testHelper.listRecords = ' + testHelper.xmlObject);		
		System.debug('***JGS ** testLead = ' + tl);
		System.assertEquals('test@testing.com',tl.email);
		System.assertEquals('Test',tl.firstname);
        System.assertEquals('Testing',tl.lastname);
        System.assertEquals('CMF+ Testing & Consultants %',tl.company);
	}
	
	 public class testLead {
        public string email;
        public string firstname;
        public string lastname;
        public string company;
    }	
}