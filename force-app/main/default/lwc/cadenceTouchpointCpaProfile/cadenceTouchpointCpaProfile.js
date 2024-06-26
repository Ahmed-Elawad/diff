import { LightningElement, api, track } from "lwc";
import Profiled_Date__c from "@salesforce/schema/Referral_Account__c.Profiled_Date__c";
import Number_of_Business_Clients_with_EEs__c from "@salesforce/schema/Referral_Account__c.Number_of_Business_Clients_with_EEs__c";
import Number_of_Clients_with_50_Ees__c from "@salesforce/schema/Referral_Account__c.Number_of_Clients_with_50_Ees__c";
import Number_of_Payrolls_the_Firm_Processes__c from "@salesforce/schema/Referral_Account__c.Number_of_Payrolls_the_Firm_Processes__c";
import Types_of_Payrolls_Processed__c from "@salesforce/schema/Referral_Account__c.Types_of_Payrolls_Processed__c";
import Software_Used_to_Process_Payrolls__c from "@salesforce/schema/Referral_Account__c.Software_Used_to_Process_Payrolls__c";
import Software_Renewal_Date__c from "@salesforce/schema/Referral_Account__c.Software_Renewal_Date__c";
import Number_of_Owner_Only_Clients__c from "@salesforce/schema/Referral_Account__c.Number_of_Owner_Only_Clients__c";
import Who_Is_Referred_for_Payroll_HCM__c from "@salesforce/schema/Referral_Account__c.Who_Is_Referred_for_Payroll_HCM__c";
import Does_Firm_Receive_HR_Questions__c from "@salesforce/schema/Referral_Account__c.Does_Firm_Receive_HR_Questions__c";
import Types_of_Benefit_Questions__c from "@salesforce/schema/Referral_Account__c.Types_of_Benefit_Questions__c";
import Acquisition_Discussion__c from "@salesforce/schema/Referral_Account__c.Acquisition_Discussion__c";
import Power_of_Paychex_Firm_Presentation__c from "@salesforce/schema/Referral_Account__c.Power_of_Paychex_Firm_Presentation__c";
import State__c from "@salesforce/schema/Referral_Account__c.State__c";
import CPA_Receives_Free_Payroll__c from "@salesforce/schema/Referral_Account__c.CPA_Receives_Free_Payroll__c";
import Industry__c from "@salesforce/schema/Referral_Account__c.Industry__c";
import Who_is_referred_for_PEO__c from "@salesforce/schema/Referral_Account__c.Who_is_referred_for_PEO__c";
import Referral_Source_Business_Type__c from "@salesforce/schema/Referral_Account__c.Referral_Source_Business_Type__c";
import Preferred_BenAdmin_Solution__c from "@salesforce/schema/Referral_Account__c.Preferred_BenAdmin_Solution__c";
import Offer_Clients_HR_Support__c from "@salesforce/schema/Referral_Account__c.Offer_Clients_HR_Support__c";
import Preferred_HR_Support__c from "@salesforce/schema/Referral_Account__c.Preferred_HR_Support__c";
import Provide_Financial_Advising__c from "@salesforce/schema/Referral_Account__c.Provide_Financial_Advising__c";
import Any_active_non_compete_with_other_PEOs__c from "@salesforce/schema/Referral_Account__c.Any_active_non_compete_with_other_PEOs__c";
import What_Insurances_does_your_firm_broker__c from "@salesforce/schema/Referral_Account__c.What_Insurances_does_your_firm_broker__c";
import What_Carriers_do_they_use_for_WC__c from "@salesforce/schema/Referral_Account__c.What_Carriers_do_they_use_for_WC__c";
import What_Carriers_do_they_use_for_Medical__c from "@salesforce/schema/Referral_Account__c.What_Carriers_do_they_use_for_Medical__c";
import Wholesaler_Verified__c from "@salesforce/schema/Referral_Account__c.Wholesaler_Verified__c";
import Existing_Paychex_401_k_Plans__c from "@salesforce/schema/Referral_Account__c.Existing_Paychex_401_k_Plans__c";
import Paychex_401_k_Assets__c from "@salesforce/schema/Referral_Account__c.Paychex_401_k_Assets__c";
import FA_Impression_of_Paychex__c from "@salesforce/schema/Referral_Account__c.FA_Impression_of_Paychex__c";
import Referral_Type__c from "@salesforce/schema/Referral_Account__c.Referral_Type__c";
import Any_401_k_Plans__c from "@salesforce/schema/Referral_Account__c.Any_401_k_Plans__c";
import How_many_401_k_Plans__c from "@salesforce/schema/Referral_Account__c.How_many_401_k_Plans__c";
import Aggregate_401_k_Assets__c from "@salesforce/schema/Referral_Account__c.Aggregate_401_k_Assets__c";
import Do_you_have_any_Clients_without_a_401_K__c from "@salesforce/schema/Referral_Account__c.Do_you_have_any_Clients_without_a_401_K__c";
import Preferred_Recordkeeper__c from "@salesforce/schema/Referral_Account__c.Preferred_Recordkeeper__c";
import Branch_401_k_AUM__c from "@salesforce/schema/Referral_Account__c.Branch_401_k_AUM__c";
import Wholesale_Notes__c from "@salesforce/schema/Referral_Account__c.Wholesale_Notes__c";
import Client_Start_Date__c from "@salesforce/schema/Account.Client_Start_Date__c";
import Account_ID__c from "@salesforce/schema/Account.Account_ID__c";
import Federal_ID_Number__c from "@salesforce/schema/Account.Federal_ID_Number__c";
import Number_of_ID_s__c from "@salesforce/schema/Account.Number_of_ID_s__c";
import X401K_Assets__c from "@salesforce/schema/Account.X401K_Assets__c";
import Paychex_401K_Assets__c from "@salesforce/schema/Account.Paychex_401K_Assets__c";
import H_B_Renewal_Date__c from "@salesforce/schema/Account.H_B_Renewal_Date__c";
import Work_Comp_Renewal_Date__c from "@salesforce/schema/Account.Work_Comp_Renewal_Date__c";
import CPA_Name_Ref__c from "@salesforce/schema/Account.CPA_Name_Ref__c";
import Bank__c from "@salesforce/schema/Account.Bank__c";
import Insurance_Broker_Name_Ref__c from "@salesforce/schema/Account.Insurance_Broker_Name_Ref__c";
import Broker_Name_Ref__c from "@salesforce/schema/Account.Broker_Name_Ref__c";
import Paychex_Payroll_Specialist__c from "@salesforce/schema/Account.Paychex_Payroll_Specialist__c";
import Current_Package__c from "@salesforce/schema/Account.Current_Package__c";
import Banker_Name_Ref__c from "@salesforce/schema/Account.Banker_Name_Ref__c";
import AccountNumber from "@salesforce/schema/Account.AccountNumber";
import HR_Generalist__c from "@salesforce/schema/Account.HR_Generalist__c";
import Paychex_Referral_Network_Enrollment_Date__c from "@salesforce/schema/Account.Paychex_Referral_Network_Enrollment_Date__c";

export default class CadenceTouchpointCpaProfile extends LightningElement {
  @api account;
  @api createmode;
  @api refferalSourceBussType = "";
  @api targetType = "";
  @api prospectClient;
  fields = [];
  fieldsProspect = [];
  connectedCallback() {
    console.log("var sar", this.targetType);
    console.log("var sar in r type ", this.refferalSourceBussType);

    if (
      this.targetType == "Ongoing Referral Source" ||
      this.targetType == "Referral Source"
    ) {
      if (this.refferalSourceBussType == "Accounting Firm" || this.refferalSourceBussType == "Strategic Accountant Firm" ) {
        console.log("var sar in ongong", this.fields);

        this.fields = [
          Profiled_Date__c,
          Referral_Source_Business_Type__c,
          Number_of_Business_Clients_with_EEs__c,
          Number_of_Clients_with_50_Ees__c,
          Number_of_Payrolls_the_Firm_Processes__c,
          Types_of_Payrolls_Processed__c,
          Software_Used_to_Process_Payrolls__c,
          Software_Renewal_Date__c,
          Number_of_Owner_Only_Clients__c,
          Who_Is_Referred_for_Payroll_HCM__c,
          Does_Firm_Receive_HR_Questions__c,
          Types_of_Benefit_Questions__c,
          Acquisition_Discussion__c,
          Power_of_Paychex_Firm_Presentation__c,
          State__c,
          CPA_Receives_Free_Payroll__c,
          Industry__c,
        ];


        this.fieldsProspect = [];
      } else if (
        this.refferalSourceBussType == "Health Insurance Broker" ||
        this.refferalSourceBussType == "Full Service Agency" ||
        this.refferalSourceBussType == "P&C Broker" ||
        this.refferalSourceBussType == "PEO Broker" ||
        this.refferalSourceBussType == "Business Consultant" ||
        this.refferalSourceBussType == "Financial Services" 
      ) {
        this.fields = [
          Number_of_Business_Clients_with_EEs__c,
          Number_of_Clients_with_50_Ees__c,
          Referral_Source_Business_Type__c,
          Who_Is_Referred_for_Payroll_HCM__c,
          Who_is_referred_for_PEO__c,
          Any_active_non_compete_with_other_PEOs__c,
          Preferred_BenAdmin_Solution__c,
          Offer_Clients_HR_Support__c,
          Preferred_HR_Support__c,
          Provide_Financial_Advising__c,
          State__c,
          What_Insurances_does_your_firm_broker__c,
          What_Carriers_do_they_use_for_Medical__c,
          What_Carriers_do_they_use_for_WC__c,
        ];
        this.fieldsProspect = [];
      } else if (
        this.refferalSourceBussType == "Broker Dealer" ||
        this.refferalSourceBussType == "Broker Dealer Branch"
      ) {
        this.fields = [
          Wholesaler_Verified__c,
          Existing_Paychex_401_k_Plans__c,
          FA_Impression_of_Paychex__c,
          Referral_Type__c,
          How_many_401_k_Plans__c,
          Aggregate_401_k_Assets__c,
          Do_you_have_any_Clients_without_a_401_K__c,
          Preferred_Recordkeeper__c,
          Branch_401_k_AUM__c,
        ];
        this.fieldsProspect = [];
      }
    } else if (this.targetType == "Client") {
    console.log('var sar in clint ')
      this.fieldsProspect = [
        Current_Package__c,
        Client_Start_Date__c,
        Account_ID__c,
        Federal_ID_Number__c,
        Number_of_ID_s__c,
        X401K_Assets__c,
        Paychex_401K_Assets__c,
        H_B_Renewal_Date__c,
        Work_Comp_Renewal_Date__c,
        CPA_Name_Ref__c,
        Banker_Name_Ref__c,
        Insurance_Broker_Name_Ref__c,
        Broker_Name_Ref__c,
        Paychex_Payroll_Specialist__c,
        AccountNumber,
        HR_Generalist__c,
        Paychex_Referral_Network_Enrollment_Date__c
      ];
    console.log('var sar in clint ', this.fieldsProspect)

    }else if (
      this.refferalSourceBussType == "Broker Dealer" ||
      this.refferalSourceBussType == "Broker Dealer Branch"
    ) {
      this.fields = [
        Wholesaler_Verified__c,
        Existing_Paychex_401_k_Plans__c,
        FA_Impression_of_Paychex__c,
        Referral_Type__c,
        How_many_401_k_Plans__c,
        // Aggregate_401_k_Assets__c,
        Do_you_have_any_Clients_without_a_401_K__c,
        Preferred_Recordkeeper__c,
      ];
      this.fieldsProspect = [];
    }
  }

  // handledata(){
  //     console.log(accountid);
  //     console.log(createmode);
  // }
  // test(){
  //     console.log(accountid);
  //     console.log(createmode);
  // }
}