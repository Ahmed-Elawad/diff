	/*try
	{
		//Hide this portlet. Note this portlet must immediately follow the inline search portlet.
		var ii = 0
		while(ii < document.getElementsByClassName('sidebarModuleBody').length)
		{
			if(document.getElementsByClassName('sidebarModule')[ii].innerHTML.indexOf("RightAnswers Trigger") > -1)
			{
				document.getElementsByClassName('sidebarModule')[ii].style.visibility='hidden';
			}
			ii++;
		}
	}
	catch (e)
	{
		//Do Nothing
	}*/

	try
	{
		var previous_subject = "";
		function SubjectTabOff()
		{
			var SubjectField = document.getElementById('cas14');
			var ActiveElem = document.activeElement.id+"";
			
			if(document.title.indexOf("Case Edit") > -1 && SubjectField != null)
			{
				if(ActiveElem != "cas14")
				{

					if(SubjectField.value != "" && SubjectField.value != previous_subject)
					{
						var i = 0
						while(i < document.getElementsByClassName('sidebarModuleBody').length)
						{
							if(document.getElementsByClassName('sidebarModuleBody')[i].innerHTML.indexOf("RASASnippetView2?QueryText="+previous_subject) > -1)
							{
								document.getElementsByClassName('sidebarModuleBody')[i].innerHTML = document.getElementsByClassName('sidebarModuleBody')[i].innerHTML.replace("RASASnippetView2?QueryText="+previous_subject,"RASASnippetView2?QueryText="+SubjectField.value);
							}
							else if(document.getElementsByClassName('sidebarModuleBody')[i].innerHTML.indexOf("RASASnippetView2?") > -1)
							{
								document.getElementsByClassName('sidebarModuleBody')[i].innerHTML = document.getElementsByClassName('sidebarModuleBody')[i].innerHTML.replace("RASASnippetView2?","RASASnippetView2?QueryText="+SubjectField.value+"&");
							}
							else
							{
								document.getElementsByClassName('sidebarModuleBody')[i].innerHTML = document.getElementsByClassName('sidebarModuleBody')[i].innerHTML.replace("RASASnippetViewRefObj?","RASASnippetView2?QueryText="+SubjectField.value+"&");
							}
						  
						  i++;
						}
						previous_subject = SubjectField.value;
					}
				}
			}

		}

		setInterval(SubjectTabOff, 1000);
	}
	catch (e)
	{
		//Do Nothing
	}
