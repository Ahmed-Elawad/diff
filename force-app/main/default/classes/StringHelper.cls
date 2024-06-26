/* Methods used to assist in the handling of Strings.
   
  History
  -------
  10/01/2009 Dan Carmen   Created
  10/18/2010 Dan Carmen   Add initCap method
  01/24/2011 Dan Carmen   Add normalizeString method.
  12/20/2011 Dan Carmen   Additional logic for initCap method
  01/24/2013 Dan Carmen   Added fieldIsBlank method
  08/28/2013 Dan Carmen   Added parseFullName method
  08/11/2015 Dan Carmen   Adjust initCap to not change strings that are already mixed case
  06/29/2017 Dan Carmen   Add addNotesToField method
  09/11/2017 Dan Carmen   Format date/time in addNotesToField
  03/26/2018 Dan Carmen   Adjustments to addNotesToField - to be able to pad the field
  04/12/2018 Dan Carmen   Adjustment to debug statements
  08/23/2018 Dan Carmen   Added additional addToProcessNotes methods.
  12/12/2018 Dan Carmen   Add formatPhoneNumber method
  02/18/2019 Jake Hinds   Add Case method
  02/28/2019 Dan Carmen   Check for leading 1 in phone number string greater than 10 characters.
  08/10/2020 Jake Hinds    Adjusting debug statment per pmd
  07/01/2022 Dan Carmen   Add parsePhone
  06/13/2023 Dan Carmen   Add TIN validation
  01/31/2024 Dan Carmen   Add an override for addToProcessNotes
  
 */
 
public with sharing class StringHelper {
    
   public static String[] getTokens(String mainString, String separator1, String separator2) {
      if ((mainString != null) && (mainString.length() > 0) && 
          (separator1 != null) && separator1.length() > 0) {
            
         String[] tokens = mainString.split(separator1);
         if ((separator2 != null) && (separator2.length() > 0)) {
            String[] tempTokens = new String[]{};
            for (String chkString : tokens) {
               String[] chkTokens = chkString.split(separator2);
               for (String token : chkTokens) {
                  tempTokens.add(token);
               }
            } // for (String chkString)
            tokens = tempTokens;
         } // if ((separator2 != null))
         return tokens; 
      } // if ((mainString))
      if (mainString == null) {
         return new String[]{};
      }
      return new String[]{mainString};
   } // getTokens
   
   private static String checkTokenException(String token) {
      String retVal = null;
      for (InitCap_Exceptions__c ie : InitCap_Exceptions__c.getall().values()) {
         if (ie.Name.equals(token)) {
            System.debug('token matches name');
            retVal = ie.Replace_Token__c;
            break;
         }
      } // for (InitCap_Exceptions__c
      return retVal;
   } // checkTokenException
   
   // Format a String as initCaps. So "HELLO JOHNNY" would turn into "Hello Johnny"
   // only change to initCap if passed in String is all uppercase or all lower case
   public static String initCap(String p_testStr) {
      System.debug('initCap p_testStr='+p_testStr);
      // if the string is blank, or not all upper or lower case (is mixed case), return.
      if (p_testStr == null || p_testStr.length() == 0) {
       System.debug('initCap failing first test - returning original string');
         return p_testStr;
      }

      // strip out extra characters - this is to account for non-alphas and spaces 
      String testStr = Utilities.removeExtraChars(p_testStr,Utilities.ALL_ALPHAS);
      if (!testStr.isAllUpperCase() && !testStr.isAllLowerCase()) {
         // return the passed in string
         System.debug('initCap failing second test testStr='+testStr+'. Returning original string');
         return p_testStr;
      }
      // the value to return
      String newStr = '';
      // start with entire String as lower case
      testStr = p_testStr.toLowerCase();
      // break the String into Tokens using spaces
      String[] tokens = getTokens(p_testStr.toLowerCase(),' ',null);
      // process the tokens.
      for (String token : tokens) {
         // check if the token equals one of the exceptions
         String checkToken = checkTokenException(token);
         if (checkToken == null) {
            checkToken = handleInitCapToken(token);
         }
         // if the String isn't empty add a space to separate the tokens
         newStr += (newStr.length() > 0 ? ' ' : '') + checkToken;
      } // for (String token
      
      // look for tokens at the end of the string that start with a dash (to handle things like '-MMS')
      Integer pos = newStr.lastIndexOf('-');
      if (pos > -1) {
         String token = newStr.substring(pos+1);
         String checkToken = checkTokenException(token);
         if (checkToken != null) {
            // if an token exception exists, replace the value in the string
            newStr = newStr.substring(0,pos+1)+checkToken;
         }
      } // if (pos > -1)
      return newStr;
   } // initCap
   
   /** Handle the initCap method on a token.
    */
   public static String handleInitCapToken(String token) {
      String prevChar = ' ';
      String newStr = '';
      Integer charsAfterSpace = 0;

      // loop through the String
      for (Integer cnt=0; cnt<token.length(); cnt++) {
         String curChar = token.substring(cnt,cnt+1);
         if (prevChar == ' ') {
            charsAfterSpace = 0;
            curChar = curChar.toUpperCase();
         // to account for apostrophes - O'Connor
         } else if (prevChar == '\'' && charsAfterSpace == 2) {
            curChar = curChar.toUpperCase();
         // to account for hyphenated names - Smith-Harrison, Manager(Operations), Co-Op/Intern
         } else if ((prevChar == '-') ||
                    (prevChar == '(') ||
                    (prevChar == '/')) {
            // treat as start of new word
            charsAfterSpace = 0;
            curChar = curChar.toUpperCase();
         // To account for James Jefferson II (the second)
         } else if (curChar == 'i' && prevChar == 'I') {
            curChar = curChar.toUpperCase();
         }
         newStr += curChar;
         charsAfterSpace++;
         prevChar = curChar;
      } // for (Integer
      return newStr;
    
   } // handleInitCapToken
   
   /** Normalize the value in a String for easy comparison.
    * inputStr - the string to normalize
    * fieldType - the type of String (so we can use the correct filter criteria)
    */
   public static String normalizeString(String inputStr, String fieldType) {
      String outputStr = inputStr;
      System.debug(LoggingLevel.DEBUG,'outputStr initial value='+outputStr);
      // only proceed if not null and more than one character
      if (outputStr != null && outputStr.length() > 1) {
         // all caps to remove case sensitivity and add leading and trailing spaces
         outputStr = ' '+outputStr.toUpperCase()+' ';
         // remove all punctuation
         outputStr = outputStr.replace('.', '');
         outputStr = outputStr.replace(',', '');
         outputStr = outputStr.replace('\'', '');
         System.debug(LoggingLevel.DEBUG,'outputStr before filter='+outputStr);
         Map<String,String> replaceValues = new Map<String,String>();
         String[] filterValues = getFilterValues(fieldType,replaceValues);
         // remove all filter values
         for (String filterValue : filterValues) {
            if (outputStr.contains(filterValue)) {
               outputStr = outputStr.replace(filterValue,(replaceValues.containsKey(filterValue.trim()) ? replaceValues.get(filterValue.trim()) : ' '));
               System.debug(LoggingLevel.DEBUG,'filterValue='+filterValue+' outputStr='+outputStr);
            }
         } // for (String filterValue
         outputStr = outputStr.trim();
      } // if (outputStr
      System.debug(LoggingLevel.DEBUG,'outputStr final value='+outputStr);
      return outputStr;
   } // normalizeString
   
   /** Get the filter values from the custom settings. Custom settings are used because those values
       are stored in the application cache.
    */
   public static String[] getFilterValues(String fieldType, Map<String,String> replaceValues) {
      String[] filterValues = new String[]{};
      List<Normalization_Options__c> allValues = Normalization_Options__c.getall().values();
      for (Normalization_Options__c no : allValues) {
         if (no.Field_Type__c == fieldType) {
            checkAddFilter(filterValues,replaceValues,no.Filter_Value_1__c,no.Leading_Space__c,no.Trailing_Space__c,no.Replace_Value__c);
            checkAddFilter(filterValues,replaceValues,no.Filter_Value_2__c,no.Leading_Space__c,no.Trailing_Space__c,no.Replace_Value__c);
            checkAddFilter(filterValues,replaceValues,no.Filter_Value_3__c,no.Leading_Space__c,no.Trailing_Space__c,no.Replace_Value__c);
            checkAddFilter(filterValues,replaceValues,no.Filter_Value_4__c,no.Leading_Space__c,no.Trailing_Space__c,no.Replace_Value__c);
            checkAddFilter(filterValues,replaceValues,no.Filter_Value_5__c,no.Leading_Space__c,no.Trailing_Space__c,no.Replace_Value__c);
         } // if (no.Field_Type__c
      } // for (Normalization_Options__c
      return filterValues;
   } // getFilterValues
   
   private static void checkAddFilter(String[] filterValues, Map<String,String> replaceValues, String filterValue, Boolean leadSp, Boolean trailSp, String replaceValue) {
      if (filterValue != null) {
         //filterValues.add((leadSp ? ' ' : '' )+ filterValue + (trailSp ? ' ' : '' ));
         // always surround by spaces
         filterValues.add(' '+filterValue+' ');
         //if (leadSp && trailSp) {
         // replaceValues.put(filterValue,' ');
         //} else 
         if (replaceValue != null) {
            replaceValues.put(filterValue,' '+replaceValue+' ');
         }
      } // if (filterValue
   } // checkAddFilter
   
   public static Boolean fieldIsBlank(String valueToCheck) {
      return (valueToCheck == null || (valueToCheck != null && valueToCheck.length()==0));
   } // fieldIsBlank
   
   public static String firstName;
   public static String lastName;
   
   /** Take a full name field and parse out a first and last name.
       Assume name is [first name] [last name]
       Everything up to the first space is the first name, all else is last name
    */
   public static void parseFullName(String fullName) {
      firstName=null;
      lastName=null;
      if (String.isNotBlank(fullName)) {
         fullName = fullName.trim();
         // look for a space
         Integer spacePos = fullName.indexOf(' ');
         if (spacePos > 0) {
            firstName = fullName.subString(0,spacePos).trim();
            lastName = fullName.subString(spacePos+1).trim();
         } else {
            // if no first name put everything into the lastname
            lastName = fullName;
         }
      } // if (String.isNotBlank
   
   } // parseFullName

   public static String formatPhoneNumber(String phoneStr) {
      return formatPhoneNumber(phoneStr,true);
   } // formatPhoneNumber
   
   public static String formatPhoneNumber(String phoneStr, Boolean alwaysFormat) {
      // option to not format if already starts with '('
      if (String.isBlank(phoneStr) 
             || (!alwaysFormat && String.isNotBlank(phoneStr) && phoneStr.startsWith('('))) {
         return phoneStr;
      }
      // todo - if more than 10 characters, assume rest is the extension
      //String cleanStr = Utilities.removeExtraChars(phoneStr, Utilities.ALL_NUMBERS);
      String cleanStr = phoneStr.replaceAll('[^0-9]', '');
      String formattedStr = '';
      if (String.isNotBlank(cleanStr) && cleanStr.length() >= 7) {
         String ext = '';
         // check if it starts with '1' remove that entirely
         if (cleanStr.length() > 10 && cleanStr.startsWith('1')) {
            cleanStr = cleanStr.subString(1);
         }
         if (cleanStr.length() > 10) {
            // pull off everything above 10 as the "extension"
            ext = cleanStr.subString(10);
         }
         if (cleanStr.length() >= 10) {
            // remove the first 3 characters for the area code
            String areaCode = cleanStr.left(3);
            cleanStr = cleanStr.subString(3);
            formattedStr = '('+areaCode+') ';
         }
         String prefix = cleanStr.subString(0,3);
         String remaining = cleanStr.subString(3,7);
         formattedStr += prefix+'-'+remaining;
         if (String.isNotBlank(ext)) {
            formattedStr += (' ext '+ext);
         }
      }
      return formattedStr;
   } // formatPhoneNumber
    
   public static String phoneCountry = null;
   public static String phoneArea = null;
   public static String phoneTele = null;
   public static String phoneExt = null;
    
   public static void parsePhone(String phoneValue) {
      phoneCountry = '';
      phoneArea = '';
      phoneTele = '';
      phoneExt = '';
      if (String.isBlank(phoneValue)) {
          return;
      }
      // This might be a fringe case, but if it starts with a '+' it is probably a country code
      // +1 = US, +44 = UK, +52 = Mexico, +91 = India
      // Strip that off for the purpose of this
      if (phoneValue.startsWith('+')) {
         // country code should go to the first space
         phoneCountry = phoneValue.left(phoneValue.indexOf(' '));
         // remove the value from the phoneValue
         phoneValue = phoneValue.replace(phoneCountry,'');
      }
      //phoneValue = (phoneValue.startsWith('+') ? phoneValue.substring(0,) : phoneValue);
      // remove all of the extra characters
      phoneValue = phoneValue.replaceAll('[^0-9]', '');

      //phoneValue = Utilities.removeExtraChars(phoneValue, Utilities.ALL_NUMBERS);
      if (phoneValue.length() > 10) {
         phoneExt = phoneValue.subString(10);
         phoneValue = phoneValue.substring(0,10);
      }
      // Should only be at max 10 characters here
      if (phoneValue.length() == 10) {
         phoneArea = phoneValue.left(3);
         phoneTele = phoneValue.subString(3);
      } else if (phoneValue.length() == 7) {
         phoneTele = phoneValue;
      } else {
         // do we need to do anything here?
      }
      System.debug('parsePhone phoneCountry='+phoneCountry+' phoneArea='+phoneArea+' phoneTele='+phoneTele+' phoneExt='+phoneExt);
   } // parsePhone
   
   public static Map<String,Integer> notesSizeMap = null;
   
   public static String[] PROCESS_NOTES_OBJECTS = Label.StringHelper_ProcessNotesObjects.split(',');
   
   public static Integer getFieldLength(SObject rec, String fieldApiName) {
      if (notesSizeMap == null) {
         notesSizeMap = (Map<String,Integer>)CacheManager.getOrg('FieldLengthMap');
      }
      if (notesSizeMap == null) {
         notesSizeMap = new Map<String,Integer>();
         ObjectHelper objHelp = new ObjectHelper();
         for (String objectName : PROCESS_NOTES_OBJECTS) {
            Integer fldLength = objHelp.getFieldLength(objectName, 'ProcessNotes__c');
            notesSizeMap.put(objectName+'ProcessNotes__c',fldLength);
         }
         CacheManager.putOrg('FieldLengthMap',notesSizeMap);
      } // if (noteSizeMap == null
      String objectName = rec.getSObjectType().getDescribe().getName();
      String key=objectName+fieldApiName;
      if (!notesSizeMap.containsKey(key)) {
         Integer fldLength = new ObjectHelper().getFieldLength(objectName, fieldApiName);
         notesSizeMap.put(key,fldLength);
         System.debug('getFieldLength key is not in the map!! fldLength='+fldLength);
         CacheManager.putOrg('FieldLengthMap',notesSizeMap);
      }
      Integer fldLength = notesSizeMap.get(key);
      return fldLength;
   } // getFieldLength
   
   public static void addToProcessNotes(SObject rec, String notesToAdd) {
      if (rec != null) {
         Integer fldLength = getFieldLength(rec,'ProcessNotes__c');
         if (fldLength > 0) {
             addNotesToField(rec, 'ProcessNotes__c', fldLength, notesToAdd, true);
         }
      } // if (rec != null
   } // addToProcessNotes
   /*
   public static final Integer REF_NOTES_SIZE = Referral__c.ProcessNotes__c.getDescribe().getLength();

   public static void addToProcessNotes(Referral__c ref, String notesToAdd) {
      addNotesToField(ref, 'ProcessNotes__c', REF_NOTES_SIZE, notesToAdd, true);
   } // addToProcessNotes

   public static final Integer CASE_NOTES_SIZE = Case.ProcessNotes__c.getDescribe().getLength();

   public static void addToProcessNotes(Case ca, String notesToAdd) {
      addNotesToField(ca, 'ProcessNotes__c', CASE_NOTES_SIZE, notesToAdd, true);
   } // addToProcessNotes

   public static final Integer PARTREF_NOTES_SIZE = PartnerReferral__c.ProcessNotes__c.getDescribe().getLength();
   
   public static void addToProcessNotes(PartnerReferral__c partRef, String notesToAdd) {
      addNotesToField(partRef, 'ProcessNotes__c', PARTREF_NOTES_SIZE, notesToAdd, true);
   } // addToProcessNotes

   public static final Integer LD_PROCESS_NOTES_SIZE = Lead.ProcessNotes__c.getDescribe().getLength();
   
   public static void addToProcessNotes(Lead ld, String notesToAdd) {
      addNotesToField(ld, 'ProcessNotes__c', LD_PROCESS_NOTES_SIZE, notesToAdd, true);
   } // addToProcessNotes

   public static final Integer CTCT_PROCESS_NOTES_SIZE = Contact.ProcessNotes__c.getDescribe().getLength();
   
   public static void addToProcessNotes(Contact ctct, String notesToAdd) {
      addNotesToField(ctct, 'ProcessNotes__c', CTCT_PROCESS_NOTES_SIZE, notesToAdd, true);
   } // addToProcessNotes

   public static final Integer PROCESS_NOTES_ACCT_SIZE = Account.ProcessNotes__c.getDescribe().getLength();
   public static void addToProcessNotes(Account acct, String notesToAdd) {
      addNotesToField(acct, 'ProcessNotes__c', PROCESS_NOTES_ACCT_SIZE, notesToAdd, true);
   } // addToProcessNotes

   public static final Integer PROCESS_NOTES_REFACCT_SIZE = Referral_Account__c.ProcessNotes__c.getDescribe().getLength();
   public static void addToProcessNotes(Referral_Account__c refAcct, String notesToAdd) {
      StringHelper.addNotesToField(refAcct, 'ProcessNotes__c', PROCESS_NOTES_REFACCT_SIZE, notesToAdd, true);
   } // addToProcessNotes
   */
   public static void addToProcessNotes(SObject obj, Schema.DescribeFieldResult dfr, String notesToAdd) {
      addNotesToField(obj, dfr.getName(), Integer.valueOf(dfr.getLength()), notesToAdd, true);
   }

   public static void addToProcessNotes(SObject obj, Schema.DescribeFieldResult dfr, String notesToAdd, Boolean useDateStamp) {
      addNotesToField(obj, dfr.getName(), Integer.valueOf(dfr.getLength()), notesToAdd, useDateStamp);
   }

   public static Integer PCT_TO_PAD=Integer.valueOf(Label.StringHelper_NotesPadPct);
   
   // add notes to a field, so that newest notes are at the top and old notes will drop off if field gets too big.
   public static void addNotesToField(SObject obj, String fieldName, Integer fldSize, String notesToAdd, Boolean useDateStamp) {
      //System.debug('addNotesToField obj is null='+(obj != null)+' fieldName='+fieldName);
      if (obj != null && String.isNotBlank(notesToAdd)) {
         System.debug('addNotesToField fieldName='+fieldName+' notesToAdd='+notesToAdd);
         // surround by try/catch incase bad field name is passed in
         try {
            String dateStamp = (useDateStamp ? Datetime.now().format('M/d/yyyy H:mm:ss')+': ' : '');
            String curNotes = (String)obj.get(fieldName);
            //System.debug('addNotesToField curNotes='+curNotes);
            Integer padSize=0;
            if (PCT_TO_PAD != null) {
               // we shouldn't pad more than 10% of the size 
               Integer padPct = (PCT_TO_PAD < 0 ? 0 : (PCT_TO_PAD > 10 ? 10 : PCT_TO_PAD));
               padSize = Integer.valueOf((padPct * fldSize)/100);
            }
            Integer adjFldSize = fldSize-padSize;
            //System.debug('addNotesToField fldSize='+fldSize+' padSize='+padSize+' adjFldSize='+adjFldSize);
            String notes = (dateStamp+notesToAdd + (String.isNotBlank(curNotes) ? '\n'+curNotes : '')).left(adjFldSize);
            //System.debug('addNotesToField notes='+notes);
            obj.put(fieldName, notes);
         } catch (Exception e) {
            System.debug('addNotesToField fieldName: '+fieldName+' fldSize: '+fldSize+' exception: '+e.getMessage()+', '+e.getStackTraceString());
         }
      } // if (obj != null
      
   } // addNotesToField
   
   public static void appendFields(SObject origRec, String origFldName
                                  ,SObject copyRec, String copyFldName
                                  ,String appendSeparator, Integer maxFldLength) {
      // set to empty string if null so we don't have to worry about null pointers later
      String origValue = origRec.get(origFldName) != null ? (String)origRec.get(origFldName) : '';
      String copyValue = copyRec.get(copyFldName) != null ? (String)copyRec.get(copyFldName) : '';
      //System.debug('StringHelper.appendFields origValue='+origValue+' copyValue='+copyValue);
      if (origValue != copyValue && !origValue.contains(copyValue)) {
         // add the new value in front of the existing value.
         String concatenatedValue = (copyValue + (String.isNotBlank(copyValue) ? appendSeparator : '') + origValue).left(maxFldLength);
         if (String.isNotBlank(concatenatedValue)) {
            origRec.put(origFldName, concatenatedValue);
         }
         //System.debug('StringHelper.appendFields concatenatedValue='+concatenatedValue+' origFldName='+origFldName+' value='+objectToChk.get(fieldName));
      //} else if (origValue != copyValue && origValue.contains(copyValue)) {
         // If the original record already contains the new value, we don't need to do anything
         //origRec.put(origFldName,copyValue.get(fieldName));
      }

   } // appendFields
   
   public static final String SSN='SSN';
   public static final String FEIN='FEIN';
   public static final String ITIN='ITIN';
   public static String validateTin(String valueToCheck, String tinType) {
      String[] errors = new String[]{};
      String checkValue = (String.isNotBlank(valueToCheck) ? valueToCheck.replaceAll('[^0-9.]', '') : '');
      if (checkValue.length() != 9) {
         errors.add('Tax ID should be 9 digits numeric');
      } else {
         //if (tinType == SSN && (checkValue == '000000000' || checkValue == '123456789')) {
         if (tinType == SSN && Pattern.matches('(^123456789$|^987654321$|^000000000$)', checkValue)) {
            errors.add('SSN can\'t be 000000000, 123456789, or 987654321');
         } else if ((checkValue == '999999999')) {
            errors.add('Tax ID can\'t be (999999999)');
         } else if (tinType == SSN && Pattern.matches('^(000|666|900).+', checkValue)) {
            errors.add('Cannot begin with 000, 666 or in the 900 series - invalid per IRS');
         } else if (tinType == SSN && Pattern.matches('(^9).+', checkValue)) {
            errors.add('Cannot begin with the number 9 - invalid per IRS');
         } else if (tinType == SSN && Pattern.matches('(^[0-9]{5}0000$)', checkValue)) {
            errors.add('The third group cannot consisting of four digits as 0000 - invalid per IRS');
         } else if (tinType == SSN && Pattern.matches('(^[0-9]{3}00[0-9]{4}$)', checkValue)) {
            errors.add('The second group cannot consist of two digits as 00 - invalid per IRS');
         //} else if (tinType == SSN && (Pattern.matches('^000|^666|^9', checkValue)
         //    || Pattern.matches('(^[0-9]{3}00[0-9]{4}$|^[0-9]{5}0000$)', checkValue))) {
         //   errors.add('SSN can\'t be mistyped as TIN');
         } else if ((tinType == FEIN || tinType == ITIN)
             && Pattern.matches('^(00|07|08|09|17|18|19|28|29|49|69|70|78|79|89|96|97).+', checkValue)) {
            errors.add('Tax ID can\'t start with one of the following (00|07|08|09|17|18|19|28|29|49|69|70|78|79|89|96|97)');
         } else if (tinType == ITIN && Pattern.matches('^9[0-9]{2}(7|8)[0-9]{5}$', checkValue)) {
            errors.add('TIN Invalid format');
         } else if (tinType == FEIN && Pattern.matches('(^123456789$|^987654321$|^990000000$|^991111111$)', checkValue)) {
            errors.add('FEIN can\'t be 123456789|987654321|990000000|991111111');
         } else if ((tinType == FEIN || tinType == SSN)  && Pattern.matches('(^000000000$|^111111111$|^222222222$|^333333333$|^444444444$|^555555555$|^666666666$|^777777777$|^888888888$)', checkValue)) {
            errors.add(tinType+' can\'t be all same numbers');
         } else if (tinType == FEIN && Pattern.matches('(^010101010$|^121212121$|^212121212$|^323232323$|^434343434$|^454545454$|^545454545$|^565656565$|^656565656$|^676767676$|^767676767$|^878787878$|^989898989$|^012345678$|^12345678$|^123123123$|^321321321$|^456456456$|^654654654$|^879879879$|^987987987$)', checkValue)) {
            errors.add('FEIN can\'t have repetitive patterns');
         }
          
      }
      String result = (!errors.isEmpty() ? String.join(errors,', ') : '');
      System.debug('validateTin valueToCheck='+valueToCheck+' tinType='+tinType+' result='+result);
      return result;
   } // validateTin
    
} // class StringHelper