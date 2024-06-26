import { api, LightningElement,wire,track } from 'lwc';
//import { getRecord } from 'lightning/uiRecordApi';
import fetchDropdownData from '@salesforce/apex/EDIController.fetchDropdownData';
import SystemModstamp from '@salesforce/schema/Account.SystemModstamp';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import validateRecords from '@salesforce/apex/EDIController.validateRecords';

export default class CreateEDI extends LightningElement {
    @api recordId;
    @api objectApiName;
    @api dropDownListData;//is to used to hold the Category data 
    @track selectedOption;//is used to hold dropdown option by user 
    @track isLoading= false;;

     title;
     message;
     variant;

    //const FIELDS = ['Contact.Name', 'Contact.Phone'];
    
    // @api invoke(){
    //     console.log('Hi Pratik Here ');
    // }

    
    //Getting the dropdown value 
    @wire(fetchDropdownData, { recordId: '$recordId',objApiName:'$objectApiName' })
    wiredDropdown({ data,error}) {
        let dropDownList=[];//This is to hold the category
        //dropDownList.push({ label: 'Select an option', value: 'Select an option' });
        if(data){
            console.log('MA1'+ JSON.stringify(data));
            for(var key in data){
                console.log('MA12'+data[key].Id);
                dropDownList.push({label:data[key].Name,value:data[key].Name});
                
            }
            // options.push({ label: 'In Progress', value: 'inProgress' });
            this.dropDownListData=dropDownList;
        }
        if(error){

        }
    }

    //Handling the selected picklist value
    handleSelectedDropDown(event){
        console.log('MA123'+event.target.value);
        this.selectedOption=event.target.value;
        console.log('MA Selected dropdown option is :'+ this.selectedDropDownOption);
    }

    //Handling the button click
    handleClick(){
        console.log('MA1234recordId');
        console.log('MA1234recordId:'+this.recordId+'objectApiName:'+this.objectApiName+'selectedOption:'+this.selectedOption);
        this.isLoading=true;
        //alert('you selected :'+this.selectedOption);
        if(this.selectedOption==null){
            console.log("MA12345"+"Inside undefined");
            this.title='Message';
            this.message='Please select a option from drop down';
            this.variant='info';
            alert(this.message);
            //this.showNotification(this.title,this.message,this.variant);
            this.isLoading=false;
        }

        else{
            validateRecords({recordId:this.recordId,objApiName:this.objectApiName,selectedOption:this.selectedOption})
            .then((result)=>{
                console.log('MA123456'+JSON.stringify(result));//if((JSON.stringify(result)).equals("Case Creation is in Progress"))
                var output=(JSON.stringify(result)).replace(/"/g, '\\"');//removing the double quotes
                // var resultString=JSON.stringify(result);
                // console.log('MA result'+resultString);
                //if(JSON.stringify(result)==='"Case Created Successfully"')
                if(output.includes('successfully'))
                {
                    console.log('MA1234567'+JSON.stringify(result));
                    this.title='Message';
                    this.message=JSON.stringify(result);
                    this.variant='success';
                    //this.isLoading=true;
                    alert(this.message);
                    //this.showNotification(this.title,this.message,this.variant);
                    this.isLoading=false;
                }
                else{
                    console.log('MA12345678'+JSON.stringify(result));
                    this.title='Message';
                    this.message=JSON.stringify(result);
                    this.variant='error';
                    alert(this.message);
                    //this.showNotification(this.title,this.message,this.variant);
                    this.isLoading=false;
                }
            }).catch((error)=>{});
        }
        
    }

    //Toast Notifications 
    showNotification(title,message,variant) {
        console.log('MA We are inside toastnotification');
        const evt = new ShowToastEvent({
            title:this.title,
            message:this.message,
            variant:this.variant,
            mode : 'sticky',
        });
        this.dispatchEvent(evt);
    }

    






}