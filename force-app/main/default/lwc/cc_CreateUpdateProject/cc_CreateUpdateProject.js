/**
 * @description       : 
 * @author            : Austin Barthel
 * @group             : Cloud Coach
 * @last modified on  : 08-17-2023
 * @last modified by  : Austin Barthel
**/

import { LightningElement, api, track, wire } from 'lwc';

import { CloseActionScreenEvent } from 'lightning/actions';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getProductDataMapping from '@salesforce/apex/CC_CreateUpdateProjectController.getProductDataMapping';
import getProject from '@salesforce/apex/CC_CreateUpdateProjectController.getProject';
import manageProjectHandler from '@salesforce/apex/CC_CreateUpdateProjectController.manageProjectHandler';
import { refreshApex } from '@salesforce/apex';

export default class Cc_CreateUpdateProject extends NavigationMixin(LightningElement) {
	@api recordId

	@track projectData;
	@track startDate = new Date().toISOString()
	newProjectName = '';
	productData;
	@track showSpinner = true;

	rendered = false
	renderedCallback(){
		if(this.rendered) return
		this.rendered = true;
		this.refreshData()
	}

	async refreshData(){
		this.showSpinner = true;
		await refreshApex(this.refreshProjectData)
		await refreshApex(this.refreshProductData)
		this.showSpinner = false
	}

	refreshProjectData;
	@wire(getProject, {resId: '$recordId'}) getProjectResult(result){
		this.refreshProjectData = result
		if(result.data){
			this.projectData = result.data
		} else if(result.error){
			console.error(result.error);
			this.showToast({
				title: 'To Many Projects...',
				message: result.error.body.message,
				variant: 'error',
				mode: 'sticky'
			});
			this.closeModal();
		} 
	}

	refreshProductData;
	@wire(getProductDataMapping, {resId: '$recordId'}) getProductDataMappingResult(result){
		this.refreshProductData = result
		if(result.data){
			this.productData = result.data.map(product => ({...product, phaseInProject: this.projectData?.phasesInProject?.includes(product.phaseId)}))
			this.showSpinner = false
		} else if(result.error){
			console.error(result.error);
			this.showToast({
				title: 'Unable to retrieve product mappings...',
				message: result.error.body.message,
				variant: 'error',
				mode: 'sticky'
			});
		} 
	}

	onConfirm(){
		this.showToast({
			title: this.projectExists ? 'Updating Project ' + this.projectData.project.Name + '.' : 'Creating Project.',
			variant: 'success',
		});
		this.showSpinner = true;

		let phasesToClone = this.insertingProducts.map(item => item.phaseId);
		let phasesToDelete = this.deletingProducts.map(item => item.phaseId);
		manageProjectHandler({
			resId: this.recordId, 
			projectId: this.projectData?.project?.Id ?? null, 
			projectName: this.newProjectName, 
			phasesToClone,
			phasesToDelete,
			startDate: this.startDate
		})
		.then(result=>{
			this.closeModal();
			this.navigateToRecordPage(result);
			setTimeout(() => {
				window.location.reload();
			}, 1000);
		})
		.catch(error=>{
			console.error(error);
			this.showToast({
				title: 'Unable to create/update project...',
				message: error.body.message,
				variant: 'error',
				mode: 'sticky'
			});
		})
		.finally(()=>{
			this.showSpinner = false;
		})
	}

	projectNameChangeHandler(e){
		this.newProjectName = e.target.value
	}

	startDateChangeHandler(e){
		this.startDate = e.target.value
	}

	onCancel(){
		this.closeModal();
	}

	closeModal(){
		this.dispatchEvent(new CloseActionScreenEvent())
	}

	get insertingProducts(){
		return this.productData?.filter(product => !product.phaseInProject && product.fieldValue)
	}

	get showInsertingProducts(){
		return this.insertingProducts?.length
	}

	get deletingProducts(){
		return this.productData?.filter(product => product.phaseInProject && !product.fieldValue)
	}

	get showDeletingProducts(){
		return this.deletingProducts?.length
	}

	get existingProducts(){
		return this.productData?.filter(product => product.phaseInProject && product.fieldValue)
	}

	get showExistingProducts(){
		return this.existingProducts?.length
	}

	get ignoringProducts(){
		return this.productData?.filter(product => !product.phaseInProject && !product.fieldValue)
	}

	get showIgnoringProducts(){
		return this.ignoringProducts?.length
	}

	get projectExists(){
		return Boolean(this.projectData)
	}

	get header(){
		return this.projectExists ? 'Update Project: ' + this.projectData.project.Name : 'Create Project: ' + this.newProjectName;
	}

	get successLabel(){
		return this.projectExists ? 'Confirm Updates' : 'Create Project';
	}

	showToast({title, message, variant, mode}){
		this.dispatchEvent(new ShowToastEvent({
			title,
			message,
			variant,
			mode
		}));
	}

	navigateToRecordPage(recordId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId,
                objectApiName: 'project_cloud__Project__c',
                actionName: 'view',
            },
        });
    }
}