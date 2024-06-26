    // function to control the native css style 
    // and the addition and removal of the disabled attribute on the buttons
    // need to include the jQuery libraries when using this.
    function buttonsEnabled(enable) {
        var $buttons = jQuery('.btn'); // find all buttons in the page
        if (enable === false) {
            $buttons.toggleClass('btnDisabled', true).attr('disabled', 'disabled');
        } else {
            $buttons.toggleClass('btnDisabled', false).attr('disabled', null);
        } 
    }
