import { LightningElement } from 'lwc';
import CPA_FAQ from '@salesforce/resourceUrl/CPA_FAQ';

export default class CPAFrequentlyAskedQuestions extends LightningElement {
    faqImage = CPA_FAQ;
    handleGoBack() {
        window.history.back();
    }
}