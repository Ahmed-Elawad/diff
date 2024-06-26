({
    setDisplayByReferralType: function(component, event, helper, referralType) {
        var typeDisplay = {
            "Gold": {
                image: "cpaGold",
                color: "blue"
            },
            "Silver": {
                image: "cpaSilver",
                color: "orange"
            },
            "Bronze": {
                image: "cpaBronze",
                color: "red"
            },
            "Platinum": {
                image: "cpaPlatinum",
                color: "green"
            }
        };

        var display = typeDisplay[referralType];
        return display;
    },
    setDisplayByReferralSourceBusinessType: function(component, event, helper, businessType) {
        var typeDisplay = {
            "Accounting Firm": {
                image: "accountant",
                color: "blue"
            },
            "Bank": {
                image: "bank",
                color: "blue"
            },
            "Broker": {
                image: "financialadvisor",
                color: "green"
            },
            "Broker Dealer": {
                image: "financialadvisor",
                color: "green"
            },
            "Broker Dealer Branch": {
                image: "financialadvisor",
                color: "green"
            },
            "Financial Services": {
                image: "bank",
                color: "blue"
            },
            "Insurance Carrier": {
                image: "insurance",
                color: "gold"
            },
            "Insurance Broker": {
                image: "insurance",
                color: "gold"
            },
            "Strategic Account": {
                image: "strategicaccount1",
                color: "purple"
            },
            "National Account": {
                image: "strategicaccount1",
                color: "purple"
            }
        };

        var display = typeDisplay[businessType];
        if (!display) {
            display = {
                image: "other_rcra",
                color: "dark-gray"
            };
        }
        return display;
    }
})