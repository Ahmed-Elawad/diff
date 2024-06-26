@IsTest
private class MergeFieldBinderTest {

    @isTest static void testSingleObject() {

        Account testAccount = createAccount();

        Map<String, SObject> sobjectMap = new Map<String, SObject>();
        sobjectMap.put('Account', testAccount);

        Test.startTest();
        MergeFieldBinder MergeFieldBinder = new MergeFieldBinder( buildRequestOneObject() );
        String requestActual = MergeFieldBinder.replaceMergeFields(sobjectMap);
        Test.stopTest();

        System.assertEquals(
                buildRequestExpectedOneObject(testAccount),
                requestActual,
                'Merge fields were not replaced properly.'
        );
    }

    @isTest static void testTwoObjects() {

        Account testAccount = createAccount();
        Contact testContact = createContact();

        Map<String, SObject> sobjectMap = new Map<String, SObject>();
        sobjectMap.put('Account', testAccount);
        sobjectMap.put('Contact', testContact);

        Test.startTest();
        MergeFieldBinder MergeFieldBinder = new MergeFieldBinder( buildRequestTwoObjects() );
        String requestActual = MergeFieldBinder.replaceMergeFields(sobjectMap);
        Test.stopTest();

        System.assertEquals(
                buildRequestExpectedTwoObjects(testAccount, testContact),
                requestActual,
                'Merge fields were not replaced properly.'
        );
    }

    @isTest static void testMissingObjects() {

        Account testAccount = new Account();
        Contact testContact = new Contact();

        Map<String, SObject> sobjectMap = new Map<String, SObject>();
        sobjectMap.put('Account', testAccount);

        Test.startTest();
        MergeFieldBinder MergeFieldBinder = new MergeFieldBinder( buildRequestTwoObjects() );
        String requestActual = MergeFieldBinder.replaceMergeFields(sobjectMap);
        Test.stopTest();

        System.assertNotEquals(
                buildRequestExpectedTwoObjects(testAccount, testContact),
                requestActual,
                'Merge fields were unexpectedly replaced properly.'
        );
    }

    @isTest static void testMissingField() {

        Account testAccount = createAccount();
        testAccount.BillingState = null;

        Map<String, SObject> sobjectMap = new Map<String, SObject>();
        sobjectMap.put('Account', testAccount);

        Test.startTest();
        MergeFieldBinder MergeFieldBinder = new MergeFieldBinder( buildRequestOneObject() );
        String requestActual = MergeFieldBinder.replaceMergeFields(sobjectMap);
        Test.stopTest();

        System.assertNotEquals(
                buildRequestExpectedOneObject(testAccount),
                requestActual,
                'Merge fields were unexpectedly replaced properly.'
        );
    }

    private static String buildRequestOneObject() {
        String xml = '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ns="http://www.amtrak.com/schema/2012/01/01">';
        xml += '<soapenv:Header/>';
        xml += '<soapenv:Body>';
        xml += '<ns:CustomerProfile>';
        xml += '<ns:AccountName>{!Account.Name}</ns:AccountName>';
        xml += '<ns:BillingState>{!Account.BillingState}</ns:BillingState>';
        xml += '</ns:CustomerProfile>';
        xml += '</soapenv:Body>';
        xml += '</soapenv:Envelope>';
        return xml;
    }

    private static String buildRequestTwoObjects() {
        String xml = '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ns="http://www.amtrak.com/schema/2012/01/01">';
        xml += '<soapenv:Header/>';
        xml += '<soapenv:Body>';
        xml += '<ns:CustomerProfile>';
        xml += '<ns:AccountName>{!Account.Name}</ns:AccountName>';
        xml += '<ns:BillingState>{!Account.BillingState}</ns:BillingState>';
        xml += '<ns:ContactDepartment>{!Contact.department}</ns:ContactDepartment>';
        xml += '<ns:ContactEmail>{!Contact.Email}</ns:ContactEmail>';
        xml += '</ns:CustomerProfile>';
        xml += '</soapenv:Body>';
        xml += '</soapenv:Envelope>';
        return xml;
    }

    private static String buildRequestExpectedOneObject(Account testAccount) {
        String requestExpected = '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ns="http://www.amtrak.com/schema/2012/01/01">';
        requestExpected += '<soapenv:Header/>';
        requestExpected += '<soapenv:Body>';
        requestExpected += '<ns:CustomerProfile>';
        requestExpected += '<ns:AccountName>' + testAccount.Name + '</ns:AccountName>';
        requestExpected += '<ns:BillingState>' + testAccount.BillingState + '</ns:BillingState>';
        requestExpected += '</ns:CustomerProfile>';
        requestExpected += '</soapenv:Body>';
        requestExpected += '</soapenv:Envelope>';
        return requestExpected;
    }

    private static String buildRequestExpectedTwoObjects(Account testAccount, Contact testContact) {
        String requestExpected = '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ns="http://www.amtrak.com/schema/2012/01/01">';
        requestExpected += '<soapenv:Header/>';
        requestExpected += '<soapenv:Body>';
        requestExpected += '<ns:CustomerProfile>';
        requestExpected += '<ns:AccountName>' + testAccount.Name + '</ns:AccountName>';
        requestExpected += '<ns:BillingState>' + testAccount.BillingState + '</ns:BillingState>';
        requestExpected += '<ns:ContactDepartment>' + testContact.Department + '</ns:ContactDepartment>';
        requestExpected += '<ns:ContactEmail>' + testContact.Email + '</ns:ContactEmail>';
        requestExpected += '</ns:CustomerProfile>';
        requestExpected += '</soapenv:Body>';
        requestExpected += '</soapenv:Envelope>';
        return requestExpected;
    }
    private static Account createAccount() {
        Account Account = new Account();
        Account.Name = 'Acumen Solutions';
        Account.BillingState = 'OH';
        return Account;
    }

    private static Contact createContact() {
        Contact Contact = new Contact();
        Contact.Department = 'Billing';
        Contact.Email = 'john.smith@acumensolutions.com';
        return Contact;
    }
}