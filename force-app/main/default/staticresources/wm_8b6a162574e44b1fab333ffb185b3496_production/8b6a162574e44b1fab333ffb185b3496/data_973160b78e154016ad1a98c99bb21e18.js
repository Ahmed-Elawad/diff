var suffix = '_p1';
            var fileName = 'data_973160b78e154016ad1a98c99bb21e18.js';
            var mysrc = getCurrentSrc();
            var newPath = mysrc.replace(/\/(wm_.+?)\//, '/$1' + suffix + '/');
            var script = document.createElement('script');
            script.src = newPath;

            document.head.appendChild(script);

            function getCurrentSrc() {
	            if (document.currentScript && document.currentScript.src) 
		            return document.currentScript.src;
	
	            var scripts = document.getElementsByTagName('script');

                for(var i = 0; i < scripts.length-1; i++){
                    var currentScr = scripts[i];
	                if(currentScr.src.indexOf(fileName) > -1) { 
                       return currentScr.getAttribute.length !== undefined ? currentScr.src : currentScr.getAttribute('src', -1);
                    }            
                }
                return ''; 
            }