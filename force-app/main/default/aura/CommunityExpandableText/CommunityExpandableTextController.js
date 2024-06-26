({
    updateTextView : function(component, event, helper) {
        let dots = document.getElementById("dots");
        let moreText = document.getElementById("more");
        let btnText = document.getElementById("btn_showMore");
        let showingText = component.get('v.showingText');

        if (dots.style.display === "none") {
            console.log('updating style needed')
            dots.style.display = "inline";
            moreText.style.display = "none";
            component.set('v.showingText', !showingText);
        } else {
            console.log('updating style needed jk')
            dots.style.display = "none";
            moreText.style.display = "inline";
            component.set('v.showingText', !showingText);
        }
        
    }
})