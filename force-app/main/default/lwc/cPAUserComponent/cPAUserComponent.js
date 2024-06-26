//History
// 12-26 Updated the code to check permissions for the User on load
//
import { LightningElement, api, wire } from "lwc";
import Id from "@salesforce/user/Id";
import { getRecordNotifyChange } from "lightning/uiRecordApi";
import requirePermission from "@salesforce/label/c.Accountant_Program_Require_Permission";
import hasPermission from "@salesforce/customPermission/Accountant_Program_Rep";
import { CloseActionScreenEvent } from "lightning/actions";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getReferralContactData from "@salesforce/apex/ConvertContactToCPACommunityUser.getReferralContactData";
import saveRefCnt from "@salesforce/apex/ConvertContactToCPACommunityUser.saveRefCnt";
import updateUser from "@salesforce/apex/ConvertContactToCPACommunityUser.updateUser";
import verifyExistingUserForContact from "@salesforce/apex/ConvertContactToCPACommunityUser.verifyExistingUserForContact";
import resendWelcomeEmail from "@salesforce/apex/ConvertContactToCPACommunityUser.resendWelcomeEmail";
import createCommunityUserNew from "@salesforce/apex/ConvertContactToCPACommunityUser.createCommunityUserNew";
import strUserId from '@salesforce/user/Id';
import PROFILE_NAME_FIELD from '@salesforce/schema/User.Profile.Name';
import {getRecord} from 'lightning/uiRecordApi';
// import USER_ID from "@salesforce/schema/User.Id";
// import USER_NAME from "@salesforce/schema/User.Username";
// import EMAIL from "@salesforce/schema/User.Email";
// import IS_ACTIVE from "@salesforce/schema/User.IsActive";
// import REQUESTED_INVITE_DATE from "@salesforce/schema/User.Requested_Invite_Date__c";
// import REFERRAL_CONTACT_ID from "@salesforce/schema/Referral_Contact__c.Id";
// import CONTACT_EMAIL from "@salesforce/schema/Referral_Contact__c.Email__c";
// import CPA_Status from "@salesforce/schema/Referral_Contact__c.CPA_Program_status__c";

import { publish, createMessageContext } from "lightning/messageService";
import CPA_REFRESH from "@salesforce/messageChannel/cpa_Message_Channel__c";

export default class CPAUserComponent extends LightningElement {
  @api recordId;
  prfName;
  userId = strUserId;
  context = createMessageContext();
  existingUserData;
  error;
  showSpinner;
  alias;
  nickName;
  userAlreadyExists;
  existingUserIsInactive;
  existingUserCheckCompleted;
  profileId;
  runningUserId = Id;
  userHasNoPermissions;
  displayCard;
  endDatedContact;
  permAssigned = hasPermission;
 /*connectedCallback() {
    if (requirePermission === "Yes") {
      console.log('prfName'+ this.prfName);
      if (hasPermission) {
        this.displayCard = true;
      } else {
        this.displayCard = false;
      }
    } else {
      this.displayCard = true;
    }
  } */
  
  @wire(getRecord, {
    recordId: strUserId,
    fields: [PROFILE_NAME_FIELD]
    }) wireuser({
        error,
        data
    }) {
        if (error) {
          this.error = error ; 
        } else if (data) {
            this.prfName =data.fields.Profile.value.fields.Name.value; 
            console.log('this.prfName', this.prfName + 'hasPermission'+hasPermission); 
            if (requirePermission === "Yes") {
              if(hasPermission || this.prfName == 'Sales Enablement' || this.prfName == 'System Administrator'){
                this.displayCard = true;
              }  else{
                this.displayCard = false;
              } 
            }   
            else {
              this.displayCard = true;
            }
            
        }
    }

  @wire(getReferralContactData, { refContactId: "$recordId" })
  wiredContactData(result) {
    if (result.data) {
      this.contactData = result.data;
      if (!this.existingUserCheckCompleted) {
        //Check if the user has permissions
        this.checkPermissionsForUser(this.contactData.Contact__c);
        //Check if Contact is end dated.
        this.isContactEndDated(this.contactData.End_Date__c);
        if (this.userHasNoPermissions) {
          this.showError(
            "To invite/enroll a referral contact in the Accountant Program you must be the Referral Contact Owner"
          );
        } else if (this.endDatedContact) {
          this.showError(
            "End dated referral contacts are not able to be invited to join the Paychex Accountant Program"
          );
        } else {
          this.checkIfUserExists(this.contactData.Contact__c);
        }
        this.existingUserCheckCompleted = true;
      }
    } else if (result.error) {
      this.error = result.error;
    }
  }

  checkIfUserExists(contactId) {
    verifyExistingUserForContact({ conId: contactId })
      .then((data) => {
        if (data) {
          this.existingUserData = data;
          this.userAlreadyExists = true;
          if (!data.IsActive) {
            this.existingUserIsInactive = true;
          }
        } else {
          this.userAlreadyExists = false;
        }
        this.existingUserCheckCompleted = true;
      })
      .catch((error) => {
        this.error = error;
      });
  }

  isContactEndDated(endDateOnContact) {
    //Date in yyyy/mm/dd format.
    let today =  new Date().toISOString().split('T')[0];
    if (endDateOnContact < today) {
      this.endDatedContact = true;
    } else {
      this.endDatedContact = false;
    }
  }

  //Jidesh changes US43:SFDC-15739
  //Check if the Running user and Referral contact owner is same
  //Display a toast if mismatch
  checkPermissionsForUser() {
    if (this.contactData.OwnerId === this.runningUserId) {
      this.userHasNoPermissions = false;
    } else {
      this.userHasNoPermissions = true;
    }
  }

  handleReInviteUser() {
    this.requiredFieldsCheck();
    if (this.requiredFieldsCheck()) {
      if (this.existingUserData.Community_User_First_Login__c) {
        this.showError(
          "The prospect has already logged in prior, the Getting Started Welcome Email could not be resent."
        );
      } else {
        let userId = this.existingUserData.Id;
        this.checkAndUpdateUser(userId);
        this.checkAndUpdateReferralContact();
        this.updateContactToSendReInvitation();
      }
    } else {
      this.showError("Please fill out all required fields");
    }
  }

  handleReActivateUser() {
    let userId = this.existingUserData.Id;
    this.checkAndUpdateUser(userId);
    this.checkAndUpdateReferralContact();
  }

  checkAndUpdateUser(userId) {
    let contactEmailFromUI = this.template.querySelector(
      "[data-field='contactEmail']"
    );
    let userNameFromUI = this.template.querySelector("[data-field='userName']");
    this.showSpinner = true;
    updateUser({
      userId: userId,
      userName: userNameFromUI.value,
      email: contactEmailFromUI.value,
      reactivateUser: this.reactivateUser
    })
      .then(() => {
        this.showSpinner = false;
        this.showSuccess(
          "User updated",
          "Portal user reactivated. Welcome email has been sent"
        );
        this.closePopUp();
        this.refreshRecord();
      })
      .catch((error) => {
        this.error = error;
        this.showSpinner = false;
      });
  }

  updateContactToSendReInvitation() {
    this.requiredFieldsCheck();
    if (this.requiredFieldsCheck()) {
      this.showSpinner = true;
      resendWelcomeEmail({ contactId: this.contactData.Contact__c })
        .then(() => {
          this.showSpinner = false;
          this.closePopUp();
          this.refreshRecord();
        })
        .catch(() => {
          this.showSpinner = false;
        });
    } else {
      this.showError("Please fill out all required fields");
    }
  }

  createUser() {
    this.requiredFieldsCheck();
    if (this.requiredFieldsCheck()) {
      this.showSpinner = true;
      this.generateAlias();
      createCommunityUserNew({
        uName: this.template.querySelector("[data-field='userName']").value,
        nickName: this.nickName,
        conId: this.contactData.Contact__c,
        alias: this.alias,
        email: this.template.querySelector("[data-field='contactEmail']").value
      })
        .then((data) => {
          this.showSpinner = false;
          //data is returned from Apex if there is any error when creating user.
          if (data !== null) {
            if (data.includes("DUPLICATE_USERNAME")) {
              this.error = `The Community Username is already in use with a Salesforce User Profile.
            Please ensure the contact is not already enrolled before updating the username to proceed`;
            } else {
              this.error = data;
            }
            this.showError(this.error);
          } else {
            this.checkAndUpdateReferralContact();
            this.showSuccess(
              "User created",
              "Portal user created. Registration email has been sent"
            );
            //this.refreshRecord();
            this.closePopUp();
          }
        })
        .catch((error) => {
          this.showSpinner = false;
          this.error = error;
          this.showError(this.error);
        });
    } else {
      this.showError("Please fill out all required fields");
    }
  }

  requiredFieldsCheck() {
    let requiredFields = [
      ...this.template.querySelectorAll("[data-required='true']")
    ];
    let allValid = requiredFields.reduce((validSoFar, inputFields) => {
      inputFields.reportValidity();
      return validSoFar && inputFields.checkValidity();
    }, true);
    return allValid;
  }

  handleCancel() {
    this.closePopUp();
  }

  refreshRecord() {
    // Notify LDS that the record information changed outside its mechanisms.
    getRecordNotifyChange([{ recordId: this.recordId }]);
    const message = {
      messageToSend: "refreshUser",
      sourceSystem: "From cPAUserComponent LWC"
    };
    publish(this.context, CPA_REFRESH, message);
  }

  closePopUp() {
    this.dispatchEvent(new CloseActionScreenEvent());
  }

  generateAlias() {
    let flatName = this.template.querySelector("[data-field='userName']").value;
    let randomNumber = Math.floor(100000 + Math.random() * 900000);
    this.nickName = (flatName.substring(0, 4) + randomNumber).substring(0, 13);
    this.alias = flatName.substring(0, 6);
  }

  checkAndUpdateReferralContact() {
    this.requiredFieldsCheck();
    let contactEmailFromUI = this.template.querySelector(
      "[data-field='contactEmail']"
    );
    if (this.requiredFieldsCheck()) {
      this.showSpinner = true;
      saveRefCnt({
        referralCt: this.recordId,
        cpaStatus: "Pending",
        email: contactEmailFromUI.value
      })
        .then(() => {
          this.showSpinner = false;
          this.closePopUp();
          this.refreshRecord();
        });
    } else {
      this.showError("Please fill out all required fields");
    }
  }

  handleEmailChange(event) {
    let userName = this.template.querySelector("[data-field='userName']");
    userName.value = event.target.value;
  }

  showError(error) {
    const event = new ShowToastEvent({
      title: "Error!",
      message: error,
      variant: "error",
      mode: "sticky"
    });
    this.dispatchEvent(event);
  }

  showSuccess(title, successMessage) {
    const event = new ShowToastEvent({
      title: title,
      message: successMessage,
      variant: "success",
      mode: "sticky"
    });
    this.dispatchEvent(event);
  }

  get disableFields() {
    if (this.userHasNoPermissions || this.endDatedContact) {
      return true;
    }
    return false;
  }

  get resendInvite() {
    if (this.userAlreadyExists && !this.existingUserIsInactive) {
      return true;
    }
    return false;
  }

  get reactivateUser() {
    if (this.userAlreadyExists && this.existingUserIsInactive) {
      return true;
    }
    return false;
  }

  get firsTimeUserCreation() {
    if (!this.userAlreadyExists) {
      return true;
    }
    return false;
  }

  get headerText() {
    if (this.resendInvite) {
      return "Re-invite to Paychex Accountant Program";
    } else if (this.reactivateUser) {
      return "Reactivate and Re-invite to Paychex Accountant Program";
    }
    return "Invite to Paychex Accountant Program";
  }

  get userName() {
    if (this.userAlreadyExists) {
      return this.existingUserData.Username;
    }
    return this.contactData.Email__c;
  }

  get email() {
    if (this.userAlreadyExists) {
      return this.existingUserData.Email;
    }
    return this.contactData.Email__c;
  }
}