import { LightningElement } from 'lwc';
import LightningDatatable from 'lightning/datatable';
import clickToDialCustomType from './clickToDialCustomType.html';

export default class clickToDialTouchpointRefCtct extends LightningDatatable {
    static customTypes = {
        clickToDialCustom: {
            template: clickToDialCustomType,
            typeAttributes: ['phoneValue'],
        }
    }
}