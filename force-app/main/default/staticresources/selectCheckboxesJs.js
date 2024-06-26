   function selectAll(fieldIdName, sourceFld) {
      var inputElem = document.getElementsByTagName("input");
      for (var i=0; i<inputElem.length; i++) {
         if (inputElem[i].id.indexOf(fieldIdName)!=-1)
         inputElem[i].checked = sourceFld.checked;
      }
   }
