window,(window._walkmeWebpackJP=window._walkmeWebpackJP||[]).push([[3],{1136:function(t,i,n){"use strict";n.r(i),n.d(i,"AttentionGrabber",function(){return r});var e=n(140);function r(t){var i,n;return t.agData?i=t.agData.ClassType:(n=t.config.Settings.AG)&&(i=n.type),e.create({0:"ImageAttentionGrabber",1:"OldSwooshAttentionGrabber",2:"SwooshAttentionGrabber",3:"MenuOverviewAttentionGrabber",4:"TickerAttentionGrabber",5:"CustomTextAttentionGrabber",6:"CustomImageAttentionGrabber","3.sub":"MenuOverviewSubAttentionGrabber"}[i=i||0],t)}n(1184),n(1217),n(1313),n(1251),n(1314),n(1315),n(1316),n(1317),n(1318),n(1199),n(1319),n(1320),e.register("AttentionGrabber").asFunction(r).asProto()},1184:function(t,i,n){"use strict";n.r(i),n.d(i,"AttentionGrabberBase",function(){return e});var c=n(140),e=(r.prototype.t=function(){var t;this._logger.customerLog("Start drawing attention grabber",5),this.o&&this.o.clear(),this._attentionGrabber=this.getHtml(),this._attentionGrabber&&(this._attentionGrabberWrapper=this._domManager.parseElementAsJquery("<div id='walkme-attengrab' class='walkme-to-destroy' style='display: none;'/>"),this._attentionGrabberWrapper.append(this._attentionGrabber),this._topContainer.append(this._attentionGrabberWrapper),this._lib.getUiUtils().setLangAttribute(this._attentionGrabberWrapper),this.updateEvent(),t=wmjQuery.proxy(function(){this.postDrawing(),this.u(),this._commonUtils.handleAccessibleElement(this._attentionGrabberWrapper,"button")},this),this._timerManager.libSetTimeout(t,100))},r.prototype.getHtml=function(){},r.prototype.postDrawing=function(){},r.prototype.u=function(){var t,i=parseInt(this._settings.duration);i&&(t=wmjQuery.proxy(function(){this.hide(),this._stopAnimation=!0},this),this.p=this._timerManager.libSetTimeout(t,1e3*i))},r.prototype.setupAttenGrab=function(){if(this._settings&&!wmjQuery.isEmptyObject(this._settings)&&!1!==this.innerSetup()){if(this._settings.repeat){var t=this._storageKeysConfigurations.attentionGrabber.repeat.key,t=c.get("AutoStartManager").checkRepeatCookie(t,this._settings.repeat);if(!t.shouldStart)return;t.store()}t=wmjQuery.proxy(function(){this.t()},this);this.v=this._timerManager.libSetTimeout(t,1e3*parseFloat(this._settings.delay))}},r.prototype.innerSetup=function(){return!0},r.prototype.remove=function(i){try{this._logger.customerLog("Remove attention grabber",5),this._attentionGrabberWrapper&&this._attentionGrabberWrapper.remove(),this.A(),this.updateEvent(),i&&i()}catch(t){i&&i()}},r.prototype.hide=function(){this.remove(),this.M()},r.prototype.updateEvent=function(){this.I&&this.I.updateEvent()},r.prototype.M=function(){var t,i=parseInt(this._settings.replay);i&&(this._logger.customerLog("Replay attention grabber",5),t=wmjQuery.proxy(function(){this.t()},this),this.o=this._timerManager.libSetTimeout(t,1e3*i*60))},r.prototype.getDirection=function(){return this._config.Direction},r.prototype.getDefaultOrFirstTab=function(){for(var t=c.get("UiDataProvider").uiObjectsTree(),i=0;i<t.length;i++)if(t[i].properties().hasProperty("default"))return t[i];for(i=0;i<t.length;i++)if(t[i].properties().hasProperty("visible"))return t[i]},r.prototype.A=function(){this.v&&this.v.clear(),this.o&&this.o.clear(),this.p&&this.p.clear()},r);function r(t,i,n,e,r,s,o,a,h,u){this._stopAnimation=!1,this.POSITION="TrianglePosition",this._lib=t,this._commonUtils=i,this._timerManager=n,this._endUsersManager=e,this._auditSourceManager=r,this._hostData=s,this._wmAjax=o,this._safeFullUrlProvider=a,this._domManager=h,this._storageKeysConfigurations=c.get("StorageKeysConfigurations"),this._config=u.config,this._player=u.player,this._menu=u.menu,this._logger=c.get("Logger"),this._topContainer=c.get("TopContainerProvider").getTopContainer(),u.agData?(this._data=u.agData,this._settings=u.agData.Settings,this._agId=this._data.Id,this.I=c.get("AttentionGrabberDataManager")):(this._oldAG=!0,this._oldAGData=this._commonUtils.getSettingsValue(this._config.Settings,"AG",!1),this._oldAGData&&(this._settings={},this._oldAGData.delay&&(this._settings.delay=this._oldAGData.delay),this._oldAGData.timeout&&(this._settings.duration=this._oldAGData.timeout),this._oldAGData.repeat&&(this._settings.repeat=this._oldAGData.repeat)))}c.register("AttentionGrabberBase").asCtor(e).asProto().dependencies("Lib, CommonUtils, TimerManager, EndUsersManager, AuditSourceManager, HostData, WmAjax, SafeFullUrlProvider")},1199:function(t,i,n){"use strict";n.r(i),n.d(i,"TemplateAttentionGrabber",function(){return e});var l,i=n(0),g=n(140),n=n(1184),e=(l=n.AttentionGrabberBase,Object(i.__extends)(r,l),r.prototype.getHtml=function(){return g.get("TemplatesFactory").get(this._templateId,this._templateVersion,this._templateVariations,this.getTemplateData())},r.prototype.getTemplateData=function(){return{}},r.prototype.getHorizontalOffset=function(){return 0},r.prototype.getVerticalOffset=function(){return 0},r.prototype.animate=function(){},r.prototype.postDrawing=function(){this.T(),this._attentionGrabber.show(),this._attentionGrabberWrapper.show(),this.S(),this.bindEvents(),this.animate()},r.prototype.T=function(){this._attentionGrabber.addClass("wm-ag-"+this._mainClass)},r.prototype.C=function(){for(var t=0;t<this.G.length;t++)this._attentionGrabberWrapper.css(this.G[t],this.U(this._player,this.G[t])),this._attentionGrabberWrapper.css("margin-"+this.G[t],this._player.css("margin-"+this.G[t]))},r.prototype.D=function(t,i){var n=parseFloat(this._attentionGrabberWrapper.css("margin-left"))||0,e=parseFloat(this._attentionGrabberWrapper.css("margin-right"))||0,r=parseFloat(this._attentionGrabberWrapper.css("margin-top"))||0,s=parseFloat(this._attentionGrabberWrapper.css("margin-bottom"))||0;this._attentionGrabberWrapper.css("margin-left",n+t+"px").css("margin-right",e+t+"px"),this._attentionGrabberWrapper.css("margin-top",r+i+"px").css("margin-bottom",s+i+"px")},r.prototype.U=function(t,i){var n=t[0].style[i],e=t.css(i),r=(t.important(i,"auto"),t.css(i));return t.important(i,""),n&&(t[0].style[i]=n),e!=r?e:"auto"},r.prototype.setLogicCss=function(){this._attentionGrabberWrapper.css("z-index"," 2147483647"),this._attentionGrabberWrapper.css("cursor","pointer")},r.prototype.bindEvents=function(){wmjQuery(window).resize(this.F);var t=wmjQuery.proxy(function(){var t={type:this._agPlayInitiator};this._menu.toggle({initiator:t})},this);this._attentionGrabberWrapper.click(t)},r.prototype.unbindEvents=function(){wmjQuery(window).off("resize",this.F)},r.prototype.S=function(){var t,i;this._attentionGrabberWrapper.css("position","fixed"),this.setLogicCss(),"left"==this._playerMajorPosition||"right"==this._playerMajorPosition?(t=this._player.outerWidth()+this.getHorizontalOffset(),i=(this._player.outerHeight()-this._attentionGrabber.outerHeight())/2):"top"!=this._playerMajorPosition&&"bottom"!=this._playerMajorPosition||(t=(this._player.outerWidth()-this._attentionGrabber.outerWidth())/2,i=this._player.outerHeight()+this.getVerticalOffset()),this.C(),this.D(t,i)},r.prototype.remove=function(i){try{this.unbindEvents(),l.prototype.remove.call(this,i)}catch(t){l.prototype.remove.call(this,i)}},r);function r(t,i,n,e,r,s,o,a,h,u){var c,m=l.call(this,t,i,n,e,r,s,o,a,h,u)||this;for(c in m.P=s,m.G=["left","right","top","bottom"],m._templateId=m._data.UITemplateId,m._templateVersion=m._data.UITemplateVersion,m._templateVariations=[],m._data.UIVariationsIds)m._templateVariations.push(g.get("UIVariations").get(m._data.UIVariationsIds[c]));return m._data.Settings.customVariation&&m._templateVariations.push(m._data.Settings.customVariation),m.F=wmjQuery.proxy(function(){this.setPosition()},m),m._playerMajorPosition=m._config[m.POSITION].slice(0,m._config[m.POSITION].indexOf("-")),m.Z=g.get("Consts").STEP_PLAY_INITIATOR_ENUM.ATTENTION_GRABBER,m}g.register("TemplateAttentionGrabber").asCtor(e).asProto().dependencies("Lib, CommonUtils, TimerManager, EndUsersManager, AuditSourceManager, HostData, WmAjax, SafeFullUrlProvider, DomManager")},1217:function(t,i,n){"use strict";n.r(i),n.d(i,"BalloonAttentionGrabber",function(){return r});var c,i=n(0),e=n(140),n=n(1199),r=(c=n.TemplateAttentionGrabber,Object(i.__extends)(s,c),s.prototype.getTemplateData=function(){var t=e.get("LanguageManager");return{title:this.getBalloonTitle(),text:this.getBalloonText(),position:this.getOppositeDirection(this._playerMajorPosition),buttons:this._settings.buttons,direction:this.getDirection(),language:t.getCurrentLanguage()}},s.prototype.getBalloonText=function(){return""},s.prototype.getBalloonTitle=function(){},s.prototype.setLogicCss=function(){c.prototype.setLogicCss.call(this),this._attentionGrabberWrapper.css("direction",this.getDirection())},s.prototype.bindEvents=function(){c.prototype.bindEvents.call(this);var t=wmjQuery.proxy(this.remove,this);this.W=wmjQuery(".wm-x-button",this._attentionGrabberWrapper),this.W.click(function(){t()})},s.prototype.getHorizontalOffset=function(){return wmjQuery(".wm-outer-arrow",this._attentionGrabberWrapper).outerWidth()},s.prototype.getVerticalOffset=function(){return wmjQuery(".wm-outer-arrow",this._attentionGrabberWrapper).outerHeight()},s.prototype.animate=function(){var n=this._attentionGrabberWrapper,e=this._playerMajorPosition,r=parseInt(n.css(e)),s=r+30+"px",o=this._stopAnimation,a=0,h=this._timerManager.libSetTimeout;!function i(){if(1==a)return a=0,h(function(){i()},3e3),0;a++;var t={};t[e]=s,n.animate(t,{easing:"swing",duration:700,complete:function(){h(function(){var t={};t[e]=r+5+"px",n.animate(t,{easing:"easeOutBounce",duration:700,complete:function(){o||h(function(){i()},100)}})},100)}})}()},s.prototype.getOppositeDirection=function(t){return this.H[t]},s.prototype.remove=function(i){try{var t;this._attentionGrabberWrapper?(this._attentionGrabberWrapper.off("click"),this.W&&this.W.off("click"),t=wmjQuery.proxy(c.prototype.remove,this),this._attentionGrabberWrapper.stop(!0,!0),this._attentionGrabberWrapper.animate({opacity:0},{duration:300,complete:function(){t(i)}})):c.prototype.remove.call(this,i)}catch(t){c.prototype.remove.call(this,i)}},s);function s(t,i,n,e,r,s,o,a,h,u){t=c.call(this,t,i,n,e,r,s,o,a,h,u)||this;return t.H={left:"right",right:"left",bottom:"top",top:"bottom"},t}e.register("BalloonAttentionGrabber").asCtor(r).asProto().dependencies("Lib, CommonUtils, TimerManager, EndUsersManager, AuditSourceManager, HostData, WmAjax, SafeFullUrlProvider, DomManager")},1251:function(t,i,n){"use strict";n.r(i),n.d(i,"CustomTextAttentionGrabber",function(){return r});var c,i=n(0),e=n(140),n=n(1217),r=(c=n.BalloonAttentionGrabber,Object(i.__extends)(s,c),s.prototype.getBalloonText=function(){return this._settings.text||""},s.prototype.setLogicCss=function(){c.prototype.setLogicCss.call(this),wmjQuery(".wm-title",this._attentionGrabber).css("width","auto")},s);function s(t,i,n,e,r,s,o,a,h,u){t=c.call(this,t,i,n,e,r,s,o,a,h,u)||this;return t._mainClass="custom-text",t}e.register("CustomTextAttentionGrabber").asCtor(r).asProto().dependencies("Lib, CommonUtils, TimerManager, EndUsersManager, AuditSourceManager, HostData, WmAjax, SafeFullUrlProvider, DomManager")},1313:function(t,i,n){"use strict";n.r(i),n.d(i,"CustomImageAttentionGrabber",function(){return r});var g,i=n(0),e=n(140),n=n(1199),r=(g=n.TemplateAttentionGrabber,Object(i.__extends)(s,g),s.prototype.getHtml=function(){var t=this.O.getResourcePath(this._settings.image.url);if(this.L(t))return this._logger.customerLog("Attention Grabber - Could not load Custom Image because source is http over https",3),this.R.raiseEvent(this.B.EVENTS.AttentionGrabberInsecure,{name:"Custom Image"}),null;t=e.get("TemplatesFactory").get(this._templateId,this._templateVersion,this._templateVariations,{src:t});return t.height(this._settings.image.height).width(this._settings.image.width),t},s.prototype.setLogicCss=function(){g.prototype.setLogicCss.call(this),this._attentionGrabberWrapper.height(this._settings.image.height).width(this._settings.image.width)},s.prototype.L=function(t){return!!t&&0==window.location.href.indexOf("https://")&&-1==t.indexOf("https://")},s);function s(t,i,n,e,r,s,o,a,h,u,c,m,l){t=g.call(this,t,i,n,e,r,s,o,a,h,l)||this;return t.R=c,t.B=m,t._mainClass="custom-image",t.O=u,t}e.register("CustomImageAttentionGrabber").asCtor(r).asProto().dependencies("Lib, CommonUtils, TimerManager, EndUsersManager, AuditSourceManager, HostData, WmAjax, SafeFullUrlProvider, DomManager, ResourceManager, CommonEvents, Consts")},1314:function(t,i,n){"use strict";n.r(i),n.d(i,"ImageAttentionGrabber",function(){return r});var c,i=n(0),e=n(140),n=n(1184),r=(c=n.AttentionGrabberBase,Object(i.__extends)(s,c),s.prototype.getHtml=function(){return wmjQuery("<img src='"+this._settings.filename+"' />")},s.prototype.innerSetup=function(){return this._settings.filename&&(this._settings.filename=this._lib.ResourceManager.getResourcePath(this._settings.filename)),-1!=parseInt(this._settings.id)},s.prototype.postDrawing=function(){this.V()},s.prototype.V=function(){var t,i=wmjQuery.proxy(this.N,this),n=this._player,i=i(),n="1"==n.attr("data-inanimation");i||n?(this.J++,10<this.J||(t=wmjQuery.proxy(this.V,this),this._timerManager.libSetTimeout(function(){t()},500))):this.X()},s.prototype.X=function(){var t="0px",i="0px",n="auto",e="auto",r=parseInt(this._settings.hOffset),s=parseInt(this._settings.vOffset),o=(this._player.width()-this._attentionGrabberWrapper.width())/2,a=(this._player.height()-this._attentionGrabberWrapper.height())/2,h=this.Y("auto","bottom",a,s),n=this.Y(n,"top",a,s),u=this.Y("auto","right",o,r),e=this.Y(e,"left",o,r);-1<this._config[this.POSITION].indexOf("center")&&(e="50%",i=this.K(i,"margin-left",o,r),i=this.q("width",i)),-1<this._config[this.POSITION].indexOf("middle")&&(n="50%",t=this.K(t,"margin-top",a,s),t=this.q("height",t)),this._attentionGrabberWrapper.css({position:"fixed",top:n,right:u,bottom:h,left:e,"margin-top":t,"margin-right":"0px","margin-bottom":"0px","margin-left":i}),this._attentionGrabberWrapper.show()},s.prototype.Y=function(t,i,n,e){return-1<this._config[this.POSITION].indexOf(i)?this.K(t,i,n,e):t},s.prototype.K=function(t,i,n,e){return t=parseFloat(this._player.css(i).replace("px","")),(t+=n)+e+"px"},s.prototype.q=function(t,i){return this._player.hasClass("walkme-dynamic-size")?parseFloat(i.replace("px",""))+this._player.css(t).replace("px","")/2*-1:i},s.prototype.N=function(){return 0==this._player.width()||28==this._player.width()||0==this._attentionGrabberWrapper.width()||28==this._attentionGrabberWrapper.width()||24==this._attentionGrabberWrapper.width()&&24==this._attentionGrabberWrapper.width()},s);function s(t,i,n,e,r,s,o,a,h,u){t=c.call(this,t,i,n,e,r,s,o,a,h,u)||this;return t.J=0,t._oldAG&&(t._oldAGData.id&&(t._settings.id=t._oldAGData.id),t._oldAGData.filename&&(t._settings.filename=t._oldAGData.filename),t._oldAGData.hOffset&&(t._settings.hOffset=t._oldAGData.hOffset),t._oldAGData.vOffset&&(t._settings.vOffset=t._oldAGData.vOffset)),t}e.register("ImageAttentionGrabber").asCtor(r).asProto().dependencies("Lib, CommonUtils, TimerManager, EndUsersManager, AuditSourceManager, HostData, WmAjax, SafeFullUrlProvider, DomManager")},1315:function(t,i,n){"use strict";n.r(i),n.d(i,"MenuOverviewAttentionGrabber",function(){return e});var m,i=n(0),l=n(140),n=n(1184),e=(m=n.AttentionGrabberBase,Object(i.__extends)(r,m),r.prototype.$=function(t){this._jQueryMenu=t},r.prototype._=function(t,i){var n=wmjQuery.proxy(this.tt,this),e=wmjQuery.proxy(function(){var t=wmjQuery.proxy(function(){var t;n(),1==this._stepIndex&&(t={type:this.Z},WalkMePlayerAPI.toggleMenu(t))},this);r.remove(t)},this),t={config:{Direction:this._config.Direction},player:t,menu:this._menu,onClickFunc:e,agData:{Id:i.firstBalloon?this._agId:null,ClassType:i.classType,UITemplateId:this._data.UITemplateId,UITemplateVersion:this._data.UITemplateVersion,UIVariationsIds:[this.it,this._data.ExtraUIVariationsIds[this._stepIndex+1]],Settings:{delay:i.delay,text:i.text,title:i.title,boldText:i.boldText,buttons:[{text:i.buttonText}],firstBalloon:i.firstBalloon,attachedToElementSelector:i.attachedToElementSelector,jQueryMenu:this._jQueryMenu,moveArrow:i.moveArrow,marginRight:i.marginRight,marginBottom:i.marginBottom}}},r=(t.config[this.POSITION]=i.position,l.create("AttentionGrabber",t));(this._currentAg=r).setupAttenGrab()},r.prototype.tt=function(){var n;this._stopPlaying||(this._stepIndex++,this.nt[this._stepIndex]&&(this.et()?this._jQueryMenu?this._(this._jQueryMenu,this.nt[this._stepIndex]):(n=wmjQuery.proxy(function(t){this._jQueryMenu=t,this._(t,this.nt[this._stepIndex])},this),this._menu.bind("on-open-end",function(t,i){t.target.unbind("on-open-end"),n(i.menu)})):this.tt()))},r.prototype.et=function(){var t=this.nt[this._stepIndex].attachedToElementSelector;return!t||0<wmjQuery(t+":visible",this._jQueryMenu).length},r.prototype.setupAttenGrab=function(){var t;this.rt()&&"iOS"!=this._hostData.os().name&&"Android"!=this._hostData.os().name&&(t=wmjQuery.proxy(this.st,this),this._menu.bind("on-close-begin",function(){t()}),this._(this._player,this.nt[0]))},r.prototype.rt=function(){var t=this.getDefaultOrFirstTab().properties().getAll();return-1<wmjQuery.inArray(l.get("Consts").PROPERTY_CONTAINS_PREFIX+"walkthru",t)},r.prototype.st=function(){this._stopPlaying=!0,this._currentAg.remove()},r.prototype.remove=function(t){this._currentAg&&this._currentAg.remove(),m.prototype.remove.call(this,t)},r);function r(t,i,n,e,r,s,o,a,h,u){var t=m.call(this,t,i,n,e,r,s,o,a,h,u)||this,c=(t.nt={0:{classType:"3.sub",title:"Meet WalkMe!",text:"Your New Personal Assistant.",buttonText:"Start",position:"bottom-center",firstBalloon:!0},1:{classType:"3.sub",text:"The WalkMe menu is the place to get all the help you might need.",boldText:'Click "Next" and take a look...',buttonText:"Next",position:"bottom-center",delay:1,marginBottom:3},2:{classType:"3.sub",text:"Here you can select your preferred language.",boldText:'Click "Next" to continue...',buttonText:"Next",position:"bottom-center",attachedToElementSelector:"#walkme-languages",moveArrow:!0},3:{classType:"3.sub",text:"Quickly find answers to your support issue by using the search bar.",boldText:'Click "Next" to continue...',buttonText:"Next",position:"right-middle",attachedToElementSelector:".walkme-search-box-container",marginRight:12},4:{classType:"3.sub",text:"All the Walk-Thrus and help resources are located here, click them to start your online guidance.",boldText:'Click "Next" to continue...',buttonText:"Next",position:"right-middle",attachedToElementSelector:".walkme-deployables-list .walkme-tab .walkme-deployable",marginRight:14},5:{classType:"3.sub",text:"Couldn't find what you want? this link takes you to the support page.",boldText:"To learn more about WalkMe, click here.",buttonText:"Next",position:"bottom-center",attachedToElementSelector:".walkme-open-ticket",moveArrow:!0},6:{classType:"3.sub",title:"Thank You!",text:"We're here to help.",buttonText:"Done",position:"bottom-center",marginBottom:3}},t._stepIndex=0,t.it=t._data.ExtraUIVariationsIds[0],t.nt[0].position=t._config[t.POSITION],t.nt[0].delay=t._settings.delay,t.Z=l.get("Consts").STEP_PLAY_INITIATOR_ENUM.ATTENTION_GRABBER,wmjQuery.proxy(t.$,t));return t._menu.bind("build-menu-end",function(t,i){c(i.menu)}),t}l.register("MenuOverviewAttentionGrabber").asCtor(e).asProto().dependencies("Lib, CommonUtils, TimerManager, EndUsersManager, AuditSourceManager, HostData, WmAjax, SafeFullUrlProvider, DomManager")},1316:function(t,i,n){"use strict";n.r(i);var c,i=n(0),e=n(140),n=n(1251),n=(c=n.CustomTextAttentionGrabber,Object(i.__extends)(r,c),r.prototype.getTemplateData=function(){return{title:this._settings.title,"bold-text":this._settings.boldText,text:this._settings.text,position:this.getOppositeDirection(this._playerMajorPosition),buttons:this._settings.buttons}},r.prototype.setLogicCss=function(){c.prototype.setLogicCss.call(this),this.ot(),this._data.Settings.firstBalloon||this._attentionGrabberWrapper.css("cursor","auto")},r.prototype.ot=function(){var t,i,n;this._data.Settings.moveArrow&&(t=wmjQuery(".wm-outer-arrow",this._attentionGrabberWrapper),n=wmjQuery(".wm-inner-arrow",this._attentionGrabberWrapper),i=t.offset().left,t.css("left","85%"),n.css("left","85%"),n=t.offset().left,this.at=n-i,this._data.Settings.moveArrow=!1)},r.prototype.bindEvents=function(){c.prototype.bindEvents.call(this),this._attentionGrabberWrapper.off("click"),wmjQuery(".wm-button",this._attentionGrabberWrapper).click(this.ht),this.ut=wmjQuery.proxy(this.ct,this),wmjQuery(window).resize(this.ut),this._data.Settings.firstBalloon&&this._attentionGrabberWrapper.click(this.ht)},r.prototype.unbindEvents=function(){c.prototype.unbindEvents.call(this),wmjQuery(window).off("resize",this.ut)},r.prototype.animate=function(){this.ct(),this._data.Settings.firstBalloon&&c.prototype.animate.call(this)},r.prototype.ct=function(){var t,i,n,e,r,s,o,a=this._attentionGrabberWrapper.css("margin-bottom"),h=this._attentionGrabberWrapper.css("margin-right"),u=this._data.Settings.marginRight||0,c=this._data.Settings.marginBottom||0;this._data.Settings.attachedToElementSelector?(t=this._data.Settings.jQueryMenu,n=(i=wmjQuery(this._data.Settings.attachedToElementSelector,t)).offset().left-t.offset().left,e=i.offset().top-t.offset().top,"bottom"==this._playerMajorPosition?(o=t.width(),s=this._attentionGrabberWrapper.css("margin-bottom"),r=i.width(),o=parseFloat(h)+o/2-n-r/2+this.at+u,this._attentionGrabberWrapper.css("margin-right",o+"px").css("margin-bottom",parseFloat(s)-e+c+"px")):(r=t.height(),s=i.height(),o=parseFloat(a)+r/2-e-s/2+c,this._attentionGrabberWrapper.css("margin-right",parseFloat(h)-n+u+"px").css("margin-bottom",o+"px"))):this._attentionGrabberWrapper.css("margin-right",parseFloat(h)+u+"px").css("margin-bottom",parseFloat(a)+c+"px")},r);function r(t,i,n,e,r,s,o,a,h,u){t=c.call(this,t,i,n,e,r,s,o,a,h,u)||this;return t._mainClass="menu-overview",t.at=0,t.ht=u.onClickFunc,t}e.register("MenuOverviewSubAttentionGrabber").asCtor(n).asProto().dependencies("Lib, CommonUtils, TimerManager, EndUsersManager, AuditSourceManager, HostData, WmAjax, SafeFullUrlProvider, DomManager")},1317:function(t,i,n){"use strict";n.r(i),n.d(i,"OldSwooshAttentionGrabber",function(){return r});var c,i=n(0),e=n(140),n=n(1184),r=(c=n.AttentionGrabberBase,Object(i.__extends)(s,c),s.prototype.getHtml=function(){this.lt()?(t=this._settings.width+"px",i="130%"):(i=this._settings.width+"px",t="130%");var t,i,n=this._settings.opacity,e=this._settings.deg;return this._domManager.parseElementAsJquery("<div class='wm-ag-swoosh' style='width: "+t+"; height:"+i+"; position: absolute; top:-6px; right: -6px; background-color: transparent !important; "+this.gt(e)+this.bt(n)+"'/>")},s.prototype.postDrawing=function(){var t=this._settings.right,i=(this._attentionGrabberWrapper.detach().appendTo(this._player),this.lt()?"width":"height"),i=this._player.css(i),n=(this._attentionGrabberWrapper.css({position:"absolute",overflow:"hidden",width:"100%",height:"100%","z-index":this._player.css("z-index"),right:"0",bottom:"auto",top:"0"}).important("background","none"),this._attentionGrabber.show(),this._attentionGrabberWrapper.show(),this.ft("animationDuration"));this.dt(i,t,n)},s.prototype.dt=function(t,n,e){var r=this._attentionGrabber,s=this.lt()?"right":"top",o=this._timerManager,a=(r.css(s,n+"px"),1.3*parseFloat(t)+"px");!function t(){var i={},i=(i[s]=a,r.animate(i,e),this._stopAnimation);o.setWalkmeTimeout(function(){var t={};t[s]=n+"px",r.animate(t,e)},1e3),i||o.setWalkmeTimeout(t,4e3)}.call(this)},s.prototype.lt=function(){return"hoz"==this.wt},s.prototype.ft=function(t){return this._settings[t]||this.vt[t]},s.prototype.bt=function(t){return"background: url(data:image/svg+xml;base64,PD94bWwgdmVyc2lvbj0iMS4wIiA/Pgo8c3ZnIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyIgd2lkdGg9IjEwMCUiIGhlaWdodD0iMTAwJSIgdmlld0JveD0iMCAwIDEgMSIgcHJlc2VydmVBc3BlY3RSYXRpbz0ibm9uZSI+CiAgPGxpbmVhckdyYWRpZW50IGlkPSJncmFkLXVjZ2ctZ2VuZXJhdGVkIiBncmFkaWVudFVuaXRzPSJ1c2VyU3BhY2VPblVzZSIgeDE9IjAlIiB5MT0iMCUiIHgyPSIxMDAlIiB5Mj0iMCUiPgogICAgPHN0b3Agb2Zmc2V0PSIwJSIgc3RvcC1jb2xvcj0iI2ZmZmZmZiIgc3RvcC1vcGFjaXR5PSIwIi8+CiAgICA8c3RvcCBvZmZzZXQ9IjUwJSIgc3RvcC1jb2xvcj0iI2ZmZmZmZiIgc3RvcC1vcGFjaXR5PSIwLjkxIi8+CiAgICA8c3RvcCBvZmZzZXQ9IjEwMCUiIHN0b3AtY29sb3I9IiNmZmZmZmYiIHN0b3Atb3BhY2l0eT0iMCIvPgogIDwvbGluZWFyR3JhZGllbnQ+CiAgPHJlY3QgeD0iMCIgeT0iMCIgd2lkdGg9IjEiIGhlaWdodD0iMSIgZmlsbD0idXJsKCNncmFkLXVjZ2ctZ2VuZXJhdGVkKSIgLz4KPC9zdmc+);background: -moz-linear-gradient(left,  rgba(255,255,255,0) 0%, rgba(255,255,255,"+t+") 50%, rgba(255,255,255,0) 100%);background: -webkit-gradient(linear, left top, right top, color-stop(0%,rgba(255,255,255,0)), color-stop(50%,rgba(255,255,255,"+t+")), color-stop(100%,rgba(255,255,255,0)));background: -webkit-linear-gradient(left,  rgba(255,255,255,0) 0%,rgba(255,255,255,"+t+") 50%,rgba(255,255,255,0) 100%);background: -o-linear-gradient(left,  rgba(255,255,255,0) 0%,rgba(255,255,255,"+t+") 50%,rgba(255,255,255,0) 100%);background: -ms-linear-gradient(left,  rgba(255,255,255,0) 0%,rgba(255,255,255,"+t+") 50%,rgba(255,255,255,0) 100%);background: linear-gradient(to right,  rgba(255,255,255,0) 0%,rgba(255,255,255,"+t+") 50%,rgba(255,255,255,0) 100%);"},s.prototype.gt=function(t){return"transform: rotate("+t+"deg); -moz-transform:rotate("+t+"deg); -webkit-transform:rotate("+t+"deg); -o-transform:rotate("+t+"deg);  -ms-transform:rotate("+t+"deg);"},s);function s(t,i,n,e,r,s,o,a,h,u){t=c.call(this,t,i,n,e,r,s,o,a,h,u)||this;return t.vt={animationDuration:700},t._oldAG&&t._oldAGData.settings&&(t._oldAGData.settings.width&&(t._settings.width=t._oldAGData.settings.width),t._oldAGData.settings.right&&(t._settings.right=t._oldAGData.settings.right),t._oldAGData.settings.deg&&(t._settings.deg=t._oldAGData.settings.deg),t._oldAGData.settings.dir&&(t._settings.dir=t._oldAGData.settings.dir,t.wt=t._oldAGData.settings.dir),t._oldAGData.settings.opacity&&(t._settings.opacity=t._oldAGData.settings.opacity)),t}e.register("OldSwooshAttentionGrabber").asCtor(r).asProto().dependencies("Lib, CommonUtils, TimerManager, EndUsersManager, AuditSourceManager, HostData, WmAjax, SafeFullUrlProvider, DomManager")},1318:function(t,i,n){"use strict";n.r(i),n.d(i,"SwooshAttentionGrabber",function(){return r});var c,i=n(0),e=n(140),n=n(1199),r=(c=n.TemplateAttentionGrabber,Object(i.__extends)(s,c),s.prototype.postDrawing=function(){this._attentionGrabberWrapper.detach().appendTo(this._player),this._attentionGrabberWrapper.css({position:"absolute",overflow:"hidden",width:"100%",height:"100%","z-index":this._player.css("z-index"),right:"0",bottom:"auto",top:"0"}).important("background","none"),this._attentionGrabber.show(),this._attentionGrabberWrapper.show(),this.animate()},s.prototype.animate=function(){var n=this._attentionGrabber,e=this.xt,r=this._timerManager,t=this.lt(),s=t?"right":"top",o=(n.css(s,"-60px"),1.3*parseFloat(this._player.css(t?"width":"height"))+"px"),a=this._stopAnimation;this.yt(t),function t(){var i={};i[s]=o,n.animate(i,e),r.setWalkmeTimeout(function(){var t={};t[s]="-60px",n.animate(t,e)},1e3),a||r.setWalkmeTimeout(t,4e3)}()},s.prototype.yt=function(t){t?this.At("15deg","50px","130%"):this.At("105deg","130%","50px")},s.prototype.At=function(t,i,n){this._attentionGrabber.css({height:n,width:i,transform:"rotate("+t+")","-moz - transform":"rotate("+t+")","-webkit - transform":"rotate("+t+")","-o - transform":"rotate("+t+")","-ms - transform":"rotate("+t+")"})},s.prototype.lt=function(){return this._player.width()>this._player.height()},s);function s(t,i,n,e,r,s,o,a,h,u){t=c.call(this,t,i,n,e,r,s,o,a,h,u)||this;return t._mainClass="ag",t.xt=t._settings.animationDuration||700,t}e.register("SwooshAttentionGrabber").asCtor(r).asProto().dependencies("Lib, CommonUtils, TimerManager, EndUsersManager, AuditSourceManager, HostData, WmAjax, SafeFullUrlProvider, DomManager")},1319:function(t,i,n){"use strict";n.r(i),n.d(i,"TickerAttentionGrabber",function(){return r});var d,i=n(0),e=n(140),n=n(1217),r=(d=n.BalloonAttentionGrabber,Object(i.__extends)(s,d),s.prototype.setupAttenGrab=function(){0!==this.Mt.length&&d.prototype.setupAttenGrab.call(this)},s.prototype.getBalloonTitle=function(){return"Help me with..."},s.prototype.getBalloonText=function(){return this.Mt[this.jt]},s.prototype.It=function(){var t=this.Mt[this.jt];return this.jt<Math.min(this.kt,this.Mt.length)-1?this.jt++:this.jt=0,t},s.prototype.animate=function(){this._attentionGrabberWrapper.css({opacity:0});var t=wmjQuery.proxy(this.innerAnimate,this);this._attentionGrabberWrapper.animate({opacity:1},{duration:300,complete:t})},s.prototype.innerAnimate=function(){var t=wmjQuery(".wm-title",this._attentionGrabber),i={opacity:1},n=(t.css(i),this._stopAnimation),e=(t.text(this.Tt.decodeHtml(this.It(),["&",'"',"'",">","<"])),wmjQuery.proxy(this.innerAnimate,this)),r=this._timerManager.libSetTimeout;t.animate(i,{duration:700,complete:function(){r(function(){t.animate({opacity:0},{duration:700,complete:function(){n||e()}})},2e3)}})},s.prototype.getDirection=function(){return"ltr"},s);function s(t,i,n,e,r,s,o,a,h,u,c){var m=d.call(this,t,i,n,e,r,s,o,a,h,c)||this,t=(m.Tt=u,m._mainClass="ticker",m.Mt=[],m.kt=5,m.getDefaultOrFirstTab());if(t)for(var l=t.children(),g=0,b=0;b<l.length;b++){var f=l[b];if(f.properties().hasProperty("visible")&&(m.Mt.push(f.name()),g++),g==m.kt)break}return m.jt=0,m}e.register("TickerAttentionGrabber").asCtor(r).asProto().dependencies("Lib, CommonUtils, TimerManager, EndUsersManager, AuditSourceManager, HostData, WmAjax, SafeFullUrlProvider, DomManager, HtmlDecoder")},1320:function(t,i,n){n(140)}}]);