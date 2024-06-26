/**
 * @description       : 
 * @author            : Austin Barthel
 * @group             : Cloud Coach
 * @last modified on  : 05-25-2023
 * @last modified by  : Austin Barthel
**/
import { LightningElement, api } from 'lwc';

const VARIANTS = {
	delete: {
		leftArrow: 'error-line line',
		rightArrow: 'error-line line',
		iconName: 'utility:delete',
		iconVariant: 'error',
		altText: 'Delete Phase'
	},
	insert: {
		leftArrow: 'success-line line',
		rightArrow: 'success-line line',
		iconName: 'utility:success',
		iconVariant: 'success',
		altText: 'Insert Phase'
	},
	existing: {
		leftArrow: 'success-line line',
		rightArrow: 'warning-line line',
		iconName: 'utility:info',
		iconVariant: 'warning',
		altText: 'Phase Exists'
	},
	ignore: {
		leftArrow: 'warning-line line',
		rightArrow: 'warning-line line',
		iconName: 'utility:close',
		iconVariant: 'warning',
		altText: 'Phase Not Applicable'
	},

}

/**
 * Card to show variants of what will hapen based on res.
 *
 * @param productName
 * Product Name displayed on left side
 * @param phaseName 
 * Phase Name displayed on right side
 * @param variant 
 * Options are: delete, insert, existing, ignore
 */
export default class Cc_ProductPhaseCard extends LightningElement {
	@api productName = '<ProductName>'
	@api phaseName = '<PhaseName>'
	@api variant = 'insert'

	get iconName(){
		return VARIANTS[this.variant]?.iconName
	}
	get iconVariant(){
		return VARIANTS[this.variant]?.iconVariant
	}
	get leftArrowClass(){
		return VARIANTS[this.variant]?.leftArrow
	}
	get rightArrowClass(){
		return VARIANTS[this.variant]?.rightArrow
	}
	get altText(){
		return VARIANTS[this.variant]?.altText
	}
}