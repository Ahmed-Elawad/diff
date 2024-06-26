({
    tabs: {
        summary: [{
            label: 'Status Report',
            component: 'c:projectStatusReportWrapper'
        }],
        timelines: [],
        documents: [],
        controls: [],
        resources: [],
        financials: []
    },
    getTabs: function () {
        return this.tabs;
    },
})