import { LightningElement, api } from 'lwc';

export default class ProjectStatusReportWrapper extends LightningElement {
    @api recordId;

    get url(){
        const hostName = window.location.hostname.split('project-cloud')
        const vfPageName = 'ProjectStatusReport'
        return `https://${hostName[0]}c${hostName[1]}/apex/${vfPageName}?Id=${this.recordId}`
    }
}