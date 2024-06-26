/**
 * Test methods for the ZipCodeInformation object (trigger/methods).
   Also testing the AreaCodeLink trigger/AreaCodeMethods class.
 *
 * History
 * -------
 * 09/17/2013 Dan Carmen   Created
   03/27/2015 Dan Carmen   Change how time zones are being set
   02/05/2016 Dan Carmen   Added getZipInfo method
   02/17/2016 Dan Carmen   Changed getZipInfo to getZciMap
   08/10/2018 Dan Carmen   Create Zip Codes from other test methods
   12/30/2022 Dan Carmen   Added checkStateAbbrev method
   03/04/2024 Dan Carmen   Move code to the apex class.

 */
@isTest
public class ZipCodeInformationTest {
   
   public static Zip_Code_Information__c zci1 = new Zip_Code_Information__c(Name='99505',DaylightSavings__c=true,TimeZone__c=9,Zip_Code_Key__c='Z99505',City__c='Anchorage', State__c='AK',AreaCode__c='907');
   public static Zip_Code_Information__c zci2 = new Zip_Code_Information__c(Name='90210',DaylightSavings__c=true,TimeZone__c=8,Zip_Code_Key__c='Z90210',City__c='Beverly Hills', State__c='CA',AreaCode__c='310/424');
   public static Zip_Code_Information__c zci3 = new Zip_Code_Information__c(Name='79323',DaylightSavings__c=true,TimeZone__c=7,Zip_Code_Key__c='Z79323',City__c='Denver City', State__c='CO',AreaCode__c='806/432');
   public static Zip_Code_Information__c zci4 = new Zip_Code_Information__c(Name='85001',DaylightSavings__c=false,TimeZone__c=7,Zip_Code_Key__c='Z85001',City__c='Phoenix', State__c='AZ',AreaCode__c='602');
   public static Zip_Code_Information__c zci4a = new Zip_Code_Information__c(Name='85002',DaylightSavings__c=false,TimeZone__c=7,Zip_Code_Key__c='Z85002',City__c='Phoenix',State__c='AZ',AreaCode__c='602');
   public static Zip_Code_Information__c zci5 = new Zip_Code_Information__c(Name='222',DaylightSavings__c=false,TimeZone__c=1,Zip_Code_Key__c='Z00222',State__c='NY',AreaCode__c='111', TimeZoneName__c='TestName');
   public static Zip_Code_Information__c zci6 = new Zip_Code_Information__c(Name='111111',DaylightSavings__c=false,TimeZone__c=1,Zip_Code_Key__c='Z11111',State__c='NY',AreaCode__c='111', TimeZoneName__c='TestName');
   public static Zip_Code_Information__c zci7 = new Zip_Code_Information__c(Name='14624',DaylightSavings__c=false,TimeZone__c=1,Zip_Code_Key__c='Z14624',City__c='Rochester',State__c='NY',AreaCode__c='585');
   
   public static void setupZips() {
      TimeZone__c tz1 = new TimeZone__c(Name='AK',TimeZoneName__c='America/Anchorage',Abbrev__c='AKT',StandardAbbrev__c='AKST',DaylightSavingsAbbrev__c='AKDT');
      TimeZone__c tz2 = new TimeZone__c(Name='CA',TimeZoneName__c='America/Los_Angeles',Abbrev__c='PT',StandardAbbrev__c='PST',DaylightSavingsAbbrev__c='PDT');
      TimeZone__c tz3 = new TimeZone__c(Name='CO',TimeZoneName__c='America/Denver',Abbrev__c='MT',StandardAbbrev__c='MST',DaylightSavingsAbbrev__c='NDT');
      TimeZone__c tz4 = new TimeZone__c(Name='AZ',TimeZoneName__c='America/Phoenix',Abbrev__c='MT',StandardAbbrev__c='MST',DaylightSavingsAbbrev__c='MDT');
      TimeZone__c tz5 = new TimeZone__c(Name=ZipCodeInformation.TZ_DEFAULT,TimeZoneName__c='America/New_York',Abbrev__c='ET',StandardAbbrev__c='EST',DaylightSavingsAbbrev__c='EDT');
      
      TimeZone__c[] tzs = new TimeZone__c[]{tz1,tz2,tz3,tz4,tz5};
      insert tzs;
      
      // create the zip code information record
      Zip_Code_Information__c[] zcis = new Zip_Code_Information__c[]{zci1,zci2,zci3,zci4,zci4a,zci5,zci6,zci7};
      insert zcis;
      
      Map<Id,Zip_Code_Information__c> zciMap = new Map<Id,Zip_Code_Information__c>([Select Id, Name, TimeZoneName__c, TimeZoneAbbrev__c, AreaCode__c, City__c, State__c, Zip_Code_Key__c from Zip_Code_Information__c]);
      
      // test results
      zci1 = zciMap.get(zci1.Id);
      System.assertEquals(tz1.TimeZoneName__c,zci1.TimeZoneName__c);
      System.assertEquals(tz1.Abbrev__c,zci1.TimeZoneAbbrev__c);
      
      zci2 = zciMap.get(zci2.Id);
      System.assertEquals(tz2.TimeZoneName__c,zci2.TimeZoneName__c);
      System.assertEquals(tz2.Abbrev__c,zci2.TimeZoneAbbrev__c);
      
      zci3 = zciMap.get(zci3.Id);
      System.assertEquals(tz3.TimeZoneName__c,zci3.TimeZoneName__c);
      System.assertEquals(tz3.Abbrev__c,zci3.TimeZoneAbbrev__c);
      
      zci4 = zciMap.get(zci4.Id);
      System.assertEquals(tz4.TimeZoneName__c,zci4.TimeZoneName__c);
      System.assertEquals(tz4.Abbrev__c,zci4.TimeZoneAbbrev__c);
      
      zci5 = zciMap.get(zci5.Id);
      System.assertEquals(tz5.TimeZoneName__c,zci5.TimeZoneName__c);
      System.assertEquals(tz5.Abbrev__c,zci5.TimeZoneAbbrev__c);
      
      zci6 = zciMap.get(zci6.Id);
      System.assertEquals(tz5.TimeZoneName__c,zci6.TimeZoneName__c);
      System.assertEquals(tz5.Abbrev__c,zci6.TimeZoneAbbrev__c);
      
      zci7 = zciMap.get(zci7.Id);
      System.assertEquals(tz5.TimeZoneName__c,zci7.TimeZoneName__c);
      System.assertEquals(tz5.Abbrev__c,zci7.TimeZoneAbbrev__c);
      
      // verify area codes are created
      System.assertEquals(8,[select count() from AreaCode__c]);
      
      // verify links are created
      System.assertEquals(10,[select count() from AreaCodeLink__c]);
    } // setupZips

   static testMethod void testTimeZone() {
      setupZips();
      /*
      // create the time zone custom setting information
      //TimeZone__c tz1 = new TimeZone__c(Name='America/Anchorage',Abbrev__c='AK',DaylightSavings__c=true,HoursPast__c=9);
      //TimeZone__c tz2 = new TimeZone__c(Name='America/Los_Angeles',Abbrev__c='PT',DaylightSavings__c=true,HoursPast__c=8);
      //TimeZone__c tz3 = new TimeZone__c(Name='America/Denver',Abbrev__c='MT',DaylightSavings__c=true,HoursPast__c=7);
      //TimeZone__c tz4 = new TimeZone__c(Name='America/Phoenix',Abbrev__c='MT',DaylightSavings__c=false,HoursPast__c=7);
      TimeZone__c tz1 = new TimeZone__c(Name='AK',TimeZoneName__c='America/Anchorage',Abbrev__c='AKT',StandardAbbrev__c='AKST',DaylightSavingsAbbrev__c='AKDT');
      TimeZone__c tz2 = new TimeZone__c(Name='CA',TimeZoneName__c='America/Los_Angeles',Abbrev__c='PT',StandardAbbrev__c='PST',DaylightSavingsAbbrev__c='PDT');
      TimeZone__c tz3 = new TimeZone__c(Name='CO',TimeZoneName__c='America/Denver',Abbrev__c='MT',StandardAbbrev__c='MST',DaylightSavingsAbbrev__c='NDT');
      TimeZone__c tz4 = new TimeZone__c(Name='AZ',TimeZoneName__c='America/Phoenix',Abbrev__c='MT',StandardAbbrev__c='MST',DaylightSavingsAbbrev__c='MDT');
      TimeZone__c tz5 = new TimeZone__c(Name=ZipCodeInformation.TZ_DEFAULT,TimeZoneName__c='America/New_York',Abbrev__c='ET',StandardAbbrev__c='EST',DaylightSavingsAbbrev__c='EDT');
      
      TimeZone__c[] tzs = new TimeZone__c[]{tz1,tz2,tz3,tz4,tz5};
      insert tzs;
      
      // create the zip code information record
      Zip_Code_Information__c zci1 = new Zip_Code_Information__c(Name='99505',DaylightSavings__c=true,TimeZone__c=9,Zip_Code_Key__c='Z99505',State__c='AK',AreaCode__c='907');
      Zip_Code_Information__c zci2 = new Zip_Code_Information__c(Name='90210',DaylightSavings__c=true,TimeZone__c=8,Zip_Code_Key__c='Z90210',State__c='CA',AreaCode__c='310/424');
      Zip_Code_Information__c zci3 = new Zip_Code_Information__c(Name='79323',DaylightSavings__c=true,TimeZone__c=7,Zip_Code_Key__c='Z79323',State__c='CO',AreaCode__c='806/432');
      Zip_Code_Information__c zci4 = new Zip_Code_Information__c(Name='85001',DaylightSavings__c=false,TimeZone__c=7,Zip_Code_Key__c='Z85001',State__c='AZ',AreaCode__c='602');
      Zip_Code_Information__c zci4a = new Zip_Code_Information__c(Name='85002',DaylightSavings__c=false,TimeZone__c=7,Zip_Code_Key__c='Z85002',State__c='AZ',AreaCode__c='602');
      Zip_Code_Information__c zci5 = new Zip_Code_Information__c(Name='222',DaylightSavings__c=false,TimeZone__c=1,Zip_Code_Key__c='Z00222',State__c='NY',AreaCode__c='111', TimeZoneName__c='TestName');
      Zip_Code_Information__c zci6 = new Zip_Code_Information__c(Name='111111',DaylightSavings__c=false,TimeZone__c=1,Zip_Code_Key__c='Z11111',State__c='NY',AreaCode__c='111', TimeZoneName__c='TestName');
      Zip_Code_Information__c[] zcis = new Zip_Code_Information__c[]{zci1,zci2,zci3,zci4,zci4a,zci5,zci6};
      insert zcis;
      
      // test results
      System.assertEquals(1,[Select count() from Zip_Code_Information__c where Id=:zci1.Id and TimeZoneName__c=:tz1.TimeZoneName__c and TimeZoneAbbrev__c=:tz1.Abbrev__c]);
      System.assertEquals(1,[Select count() from Zip_Code_Information__c where Id=:zci2.Id and TimeZoneName__c=:tz2.TimeZoneName__c and TimeZoneAbbrev__c=:tz2.Abbrev__c]);
      System.assertEquals(1,[Select count() from Zip_Code_Information__c where Id=:zci3.Id and TimeZoneName__c=:tz3.TimeZoneName__c and TimeZoneAbbrev__c=:tz3.Abbrev__c]);
      System.assertEquals(1,[Select count() from Zip_Code_Information__c where Id=:zci4.Id and TimeZoneName__c=:tz4.TimeZoneName__c and TimeZoneAbbrev__c=:tz4.Abbrev__c]);
      System.assertEquals(1,[Select count() from Zip_Code_Information__c where Id=:zci5.Id and TimeZoneName__c=:tz5.TimeZoneName__c and TimeZoneAbbrev__c=:tz5.Abbrev__c]);
      System.assertEquals(1,[Select count() from Zip_Code_Information__c where Id=:zci6.Id and TimeZoneName__c=:tz5.TimeZoneName__c and TimeZoneAbbrev__c=:tz5.Abbrev__c]);
      
      // verify area codes are created
      System.assertEquals(7,[select count() from AreaCode__c]);
      
      // verify links are created
      System.assertEquals(9,[select count() from AreaCodeLink__c]);
      */
      // change area code - use one existing, create new
      zci1.AreaCode__c='908/909/910/602';
      update zci1;

      // verify area codes are created
      System.assertEquals(11,[select count() from AreaCode__c]);
      
      // verify links are created
      System.assertEquals(13,[select count() from AreaCodeLink__c]);

      // change area code - use one existing, create new
      zci1.AreaCode__c='907/908/909/910/602';
      update zci1;

      // verify area codes are the same
      System.assertEquals(11,[select count() from AreaCode__c]);
      
      // verify links are created
      System.assertEquals(14,[select count() from AreaCodeLink__c]);

      // test the time zone/state being set on the area code
      AreaCode__c ac602 = [Select Id, Name, TimeZoneName__c, TimeZoneAbbrev__c, State__c from AreaCode__c where Name='602'];
      System.assertEquals('America/Phoenix',ac602.TimeZoneName__c);
      System.assertEquals('MT',ac602.TimeZoneAbbrev__c);
      System.assertEquals('AZ;AK',ac602.State__c);

      // change area code - use one existing, create new
      zci1.AreaCode__c='907/908/909/910';
      update zci1;

      // verify area codes are the same
      System.assertEquals(11,[select count() from AreaCode__c]);
      
      // verify links are correct
      System.assertEquals(13,[select count() from AreaCodeLink__c]);


      // test the time zone/state being set on the area code
      ac602 = [Select Id, Name, TimeZoneName__c, TimeZoneAbbrev__c, State__c from AreaCode__c where Name='602'];
      System.assertEquals('America/Phoenix',ac602.TimeZoneName__c);
      System.assertEquals('MT',ac602.TimeZoneAbbrev__c);
      System.assertEquals('AZ',ac602.State__c);

      
   } // testTimeZone
   
   static testmethod void testGetZciMap() {
      Zip_Code_Information__c v_zci1 = new Zip_Code_Information__c(Name='90210',Zip_Code_Key__c='Z90210',State__c='CA',City__c='Beverly Hills');
      Zip_Code_Information__c v_zci2 = new Zip_Code_Information__c(Name='45201',Zip_Code_Key__c='Z45201',State__c='OH',City__c='Cincinnati');
      Zip_Code_Information__c v_zci3 = new Zip_Code_Information__c(Name='01012',Zip_Code_Key__c='Z01012',State__c='MA',City__c='Chesterfield');
      Zip_Code_Information__c[] zcis = new Zip_Code_Information__c[]{v_zci1,v_zci2,v_zci3};
      insert zcis;
      
      Map<String,Zip_Code_Information__c> zciMap = ZipCodeInformation.getZciMap((Set<String>)null);
      System.assertEquals(true,zciMap.isEmpty());

      zciMap = ZipCodeInformation.getZciMap(new Set<String>{v_zci1.Name});
      Zip_Code_Information__c checkZci = zciMap.get(v_zci1.Name);
      System.assertEquals(v_zci1.Id, checkZci.Id);

      String zipCode2 = ZipCodeInformation.format5DigitZip(v_zci2.Name+'-1234');
      System.assertEquals(v_zci2.Name, zipCode2);
      String zipCode3 = ZipCodeInformation.format5DigitZip('1012');
      System.assertEquals(v_zci3.Name, zipCode3);
      String zipCode4 = ZipCodeInformation.format5DigitZip('');
      System.assertEquals('',zipCode4);
      // this is for a zip code that doesn't exist
      zipCode4 = ZipCodeInformation.format5DigitZip('12345');
      System.assertEquals('12345',zipCode4);
      
      zciMap = ZipCodeInformation.getZciMap(new Set<String>{zipCode2,zipCode3,zipCode4});

      checkZci = zciMap.get(zipCode2);
      System.assertEquals(v_zci2.Id, checkZci.Id);

      checkZci = zciMap.get(zipCode3);
      System.assertEquals(v_zci3.Id, checkZci.Id);

      checkZci = zciMap.get(zipCode4);
      System.assertEquals(null, checkZci);
      
   } // testGetZciMap
    
   static testMethod void testCheckStateAbbrev() {
      System.assertEquals(null,ZipCodeInformation.checkStateAbbrev(null, false));
      System.assertEquals('NY',ZipCodeInformation.checkStateAbbrev('NY', false));
      System.assertEquals('NY',ZipCodeInformation.checkStateAbbrev('New York', false));
      System.assertEquals('CA',ZipCodeInformation.checkStateAbbrev('California', false));
      System.assertEquals('',ZipCodeInformation.checkStateAbbrev('This Is Not A State!', true));
      System.assertEquals('VT',ZipCodeInformation.checkStateAbbrev('Vermont', true));
   } // testCheckStateAbbrev
   
} // class ZipCodeInformationTest