window,window._walkmeWebpackJP&&(window._walkmeWebpackJP=window._walkmeWebpackJP||[]).push([[5,3,4],{1136:function(t,i,n){"use strict";n.r(i),n.d(i,"AttentionGrabber",function(){return e});var s=n(140);function e(t){var i,n;return t.agData?i=t.agData.ClassType:(n=t.config.Settings.AG)&&(i=n.type),s.create({0:"ImageAttentionGrabber",1:"OldSwooshAttentionGrabber",2:"SwooshAttentionGrabber",3:"MenuOverviewAttentionGrabber",4:"TickerAttentionGrabber",5:"CustomTextAttentionGrabber",6:"CustomImageAttentionGrabber","3.sub":"MenuOverviewSubAttentionGrabber"}[i=i||0],t)}n(1184),n(1217),n(1313),n(1251),n(1314),n(1315),n(1316),n(1317),n(1318),n(1199),n(1319),n(1320),s.register("AttentionGrabber").asFunction(e).asProto()},1184:function(t,i,n){"use strict";n.r(i),n.d(i,"AttentionGrabberBase",function(){return s});var c=n(140),s=(e.prototype.t=function(){var t;this._logger.customerLog("Start drawing attention grabber",5),this.o&&this.o.clear(),this._attentionGrabber=this.getHtml(),this._attentionGrabber&&(this._attentionGrabberWrapper=this._domManager.parseElementAsJquery("<div id='walkme-attengrab' class='walkme-to-destroy' style='display: none;'/>"),this._attentionGrabberWrapper.append(this._attentionGrabber),this._topContainer.append(this._attentionGrabberWrapper),this._lib.getUiUtils().setLangAttribute(this._attentionGrabberWrapper),this.updateEvent(),t=wmjQuery.proxy(function(){this.postDrawing(),this.p(),this._commonUtils.handleAccessibleElement(this._attentionGrabberWrapper,"button")},this),this._timerManager.libSetTimeout(t,100))},e.prototype.getHtml=function(){},e.prototype.postDrawing=function(){},e.prototype.p=function(){var t,i=parseInt(this._settings.duration);i&&(t=wmjQuery.proxy(function(){this.hide(),this._stopAnimation=!0},this),this.A=this._timerManager.libSetTimeout(t,1e3*i))},e.prototype.setupAttenGrab=function(){if(this._settings&&!wmjQuery.isEmptyObject(this._settings)&&!1!==this.innerSetup()){if(this._settings.repeat){var t=this._storageKeysConfigurations.attentionGrabber.repeat.key,t=c.get("AutoStartManager").checkRepeatCookie(t,this._settings.repeat);if(!t.shouldStart)return;t.store()}t=wmjQuery.proxy(function(){this.t()},this);this.M=this._timerManager.libSetTimeout(t,1e3*parseFloat(this._settings.delay))}},e.prototype.innerSetup=function(){return!0},e.prototype.remove=function(i){try{this._logger.customerLog("Remove attention grabber",5),this._attentionGrabberWrapper&&this._attentionGrabberWrapper.remove(),this.I(),this.updateEvent(),i&&i()}catch(t){i&&i()}},e.prototype.hide=function(){this.remove(),this.C()},e.prototype.updateEvent=function(){this.S&&this.S.updateEvent()},e.prototype.C=function(){var t,i=parseInt(this._settings.replay);i&&(this._logger.customerLog("Replay attention grabber",5),t=wmjQuery.proxy(function(){this.t()},this),this.o=this._timerManager.libSetTimeout(t,1e3*i*60))},e.prototype.getDirection=function(){return this._config.Direction},e.prototype.getDefaultOrFirstTab=function(){for(var t=c.get("UiDataProvider").uiObjectsTree(),i=0;i<t.length;i++)if(t[i].properties().hasProperty("default"))return t[i];for(i=0;i<t.length;i++)if(t[i].properties().hasProperty("visible"))return t[i]},e.prototype.I=function(){this.M&&this.M.clear(),this.o&&this.o.clear(),this.A&&this.A.clear()},e);function e(t,i,n,s,e,r,o,h,a,u){this._stopAnimation=!1,this.POSITION="TrianglePosition",this._lib=t,this._commonUtils=i,this._timerManager=n,this._endUsersManager=s,this._auditSourceManager=e,this._hostData=r,this._wmAjax=o,this._safeFullUrlProvider=h,this._domManager=a,this._storageKeysConfigurations=c.get("StorageKeysConfigurations"),this._config=u.config,this._player=u.player,this._menu=u.menu,this._logger=c.get("Logger"),this._topContainer=c.get("TopContainerProvider").getTopContainer(),u.agData?(this._data=u.agData,this._settings=u.agData.Settings,this._agId=this._data.Id,this.S=c.get("AttentionGrabberDataManager")):(this._oldAG=!0,this._oldAGData=this._commonUtils.getSettingsValue(this._config.Settings,"AG",!1),this._oldAGData&&(this._settings={},this._oldAGData.delay&&(this._settings.delay=this._oldAGData.delay),this._oldAGData.timeout&&(this._settings.duration=this._oldAGData.timeout),this._oldAGData.repeat&&(this._settings.repeat=this._oldAGData.repeat)))}c.register("AttentionGrabberBase").asCtor(s).asProto().dependencies("Lib, CommonUtils, TimerManager, EndUsersManager, AuditSourceManager, HostData, WmAjax, SafeFullUrlProvider")},1199:function(t,i,n){"use strict";n.r(i),n.d(i,"TemplateAttentionGrabber",function(){return s});var l,i=n(0),f=n(140),n=n(1184),s=(l=n.AttentionGrabberBase,Object(i.__extends)(e,l),e.prototype.getHtml=function(){return f.get("TemplatesFactory").get(this._templateId,this._templateVersion,this._templateVariations,this.getTemplateData())},e.prototype.getTemplateData=function(){return{}},e.prototype.getHorizontalOffset=function(){return 0},e.prototype.getVerticalOffset=function(){return 0},e.prototype.animate=function(){},e.prototype.postDrawing=function(){this.T(),this._attentionGrabber.show(),this._attentionGrabberWrapper.show(),this.G(),this.bindEvents(),this.animate()},e.prototype.T=function(){this._attentionGrabber.addClass("wm-ag-"+this._mainClass)},e.prototype.D=function(){for(var t=0;t<this.U.length;t++)this._attentionGrabberWrapper.css(this.U[t],this.F(this._player,this.U[t])),this._attentionGrabberWrapper.css("margin-"+this.U[t],this._player.css("margin-"+this.U[t]))},e.prototype.P=function(t,i){var n=parseFloat(this._attentionGrabberWrapper.css("margin-left"))||0,s=parseFloat(this._attentionGrabberWrapper.css("margin-right"))||0,e=parseFloat(this._attentionGrabberWrapper.css("margin-top"))||0,r=parseFloat(this._attentionGrabberWrapper.css("margin-bottom"))||0;this._attentionGrabberWrapper.css("margin-left",n+t+"px").css("margin-right",s+t+"px"),this._attentionGrabberWrapper.css("margin-top",e+i+"px").css("margin-bottom",r+i+"px")},e.prototype.F=function(t,i){var n=t[0].style[i],s=t.css(i),e=(t.important(i,"auto"),t.css(i));return t.important(i,""),n&&(t[0].style[i]=n),s!=e?s:"auto"},e.prototype.setLogicCss=function(){this._attentionGrabberWrapper.css("z-index"," 2147483647"),this._attentionGrabberWrapper.css("cursor","pointer")},e.prototype.bindEvents=function(){wmjQuery(window).resize(this.Z);var t=wmjQuery.proxy(function(){var t={type:this._agPlayInitiator};this._menu.toggle({initiator:t})},this);this._attentionGrabberWrapper.click(t)},e.prototype.unbindEvents=function(){wmjQuery(window).off("resize",this.Z)},e.prototype.G=function(){var t,i;this._attentionGrabberWrapper.css("position","fixed"),this.setLogicCss(),"left"==this._playerMajorPosition||"right"==this._playerMajorPosition?(t=this._player.outerWidth()+this.getHorizontalOffset(),i=(this._player.outerHeight()-this._attentionGrabber.outerHeight())/2):"top"!=this._playerMajorPosition&&"bottom"!=this._playerMajorPosition||(t=(this._player.outerWidth()-this._attentionGrabber.outerWidth())/2,i=this._player.outerHeight()+this.getVerticalOffset()),this.D(),this.P(t,i)},e.prototype.remove=function(i){try{this.unbindEvents(),l.prototype.remove.call(this,i)}catch(t){l.prototype.remove.call(this,i)}},e);function e(t,i,n,s,e,r,o,h,a,u){var c,m=l.call(this,t,i,n,s,e,r,o,h,a,u)||this;for(c in m.O=r,m.U=["left","right","top","bottom"],m._templateId=m._data.UITemplateId,m._templateVersion=m._data.UITemplateVersion,m._templateVariations=[],m._data.UIVariationsIds)m._templateVariations.push(f.get("UIVariations").get(m._data.UIVariationsIds[c]));return m._data.Settings.customVariation&&m._templateVariations.push(m._data.Settings.customVariation),m.Z=wmjQuery.proxy(function(){this.setPosition()},m),m._playerMajorPosition=m._config[m.POSITION].slice(0,m._config[m.POSITION].indexOf("-")),m.W=f.get("Consts").STEP_PLAY_INITIATOR_ENUM.ATTENTION_GRABBER,m}f.register("TemplateAttentionGrabber").asCtor(s).asProto().dependencies("Lib, CommonUtils, TimerManager, EndUsersManager, AuditSourceManager, HostData, WmAjax, SafeFullUrlProvider, DomManager")},1217:function(t,i,n){"use strict";n.r(i),n.d(i,"BalloonAttentionGrabber",function(){return e});var c,i=n(0),s=n(140),n=n(1199),e=(c=n.TemplateAttentionGrabber,Object(i.__extends)(r,c),r.prototype.getTemplateData=function(){var t=s.get("LanguageManager");return{title:this.getBalloonTitle(),text:this.getBalloonText(),position:this.getOppositeDirection(this._playerMajorPosition),buttons:this._settings.buttons,direction:this.getDirection(),language:t.getCurrentLanguage()}},r.prototype.getBalloonText=function(){return""},r.prototype.getBalloonTitle=function(){},r.prototype.setLogicCss=function(){c.prototype.setLogicCss.call(this),this._attentionGrabberWrapper.css("direction",this.getDirection())},r.prototype.bindEvents=function(){c.prototype.bindEvents.call(this);var t=wmjQuery.proxy(this.remove,this);this.H=wmjQuery(".wm-x-button",this._attentionGrabberWrapper),this.H.click(function(){t()})},r.prototype.getHorizontalOffset=function(){return wmjQuery(".wm-outer-arrow",this._attentionGrabberWrapper).outerWidth()},r.prototype.getVerticalOffset=function(){return wmjQuery(".wm-outer-arrow",this._attentionGrabberWrapper).outerHeight()},r.prototype.animate=function(){var n=this._attentionGrabberWrapper,s=this._playerMajorPosition,e=parseInt(n.css(s)),r=e+30+"px",o=this._stopAnimation,h=0,a=this._timerManager.libSetTimeout;!function i(){if(1==h)return h=0,a(function(){i()},3e3),0;h++;var t={};t[s]=r,n.animate(t,{easing:"swing",duration:700,complete:function(){a(function(){var t={};t[s]=e+5+"px",n.animate(t,{easing:"easeOutBounce",duration:700,complete:function(){o||a(function(){i()},100)}})},100)}})}()},r.prototype.getOppositeDirection=function(t){return this.L[t]},r.prototype.remove=function(i){try{var t;this._attentionGrabberWrapper?(this._attentionGrabberWrapper.off("click"),this.H&&this.H.off("click"),t=wmjQuery.proxy(c.prototype.remove,this),this._attentionGrabberWrapper.stop(!0,!0),this._attentionGrabberWrapper.animate({opacity:0},{duration:300,complete:function(){t(i)}})):c.prototype.remove.call(this,i)}catch(t){c.prototype.remove.call(this,i)}},r);function r(t,i,n,s,e,r,o,h,a,u){t=c.call(this,t,i,n,s,e,r,o,h,a,u)||this;return t.L={left:"right",right:"left",bottom:"top",top:"bottom"},t}s.register("BalloonAttentionGrabber").asCtor(e).asProto().dependencies("Lib, CommonUtils, TimerManager, EndUsersManager, AuditSourceManager, HostData, WmAjax, SafeFullUrlProvider, DomManager")},1251:function(t,i,n){"use strict";n.r(i),n.d(i,"CustomTextAttentionGrabber",function(){return e});var c,i=n(0),s=n(140),n=n(1217),e=(c=n.BalloonAttentionGrabber,Object(i.__extends)(r,c),r.prototype.getBalloonText=function(){return this._settings.text||""},r.prototype.setLogicCss=function(){c.prototype.setLogicCss.call(this),wmjQuery(".wm-title",this._attentionGrabber).css("width","auto")},r);function r(t,i,n,s,e,r,o,h,a,u){t=c.call(this,t,i,n,s,e,r,o,h,a,u)||this;return t._mainClass="custom-text",t}s.register("CustomTextAttentionGrabber").asCtor(e).asProto().dependencies("Lib, CommonUtils, TimerManager, EndUsersManager, AuditSourceManager, HostData, WmAjax, SafeFullUrlProvider, DomManager")},1313:function(t,i,n){"use strict";n.r(i),n.d(i,"CustomImageAttentionGrabber",function(){return e});var f,i=n(0),s=n(140),n=n(1199),e=(f=n.TemplateAttentionGrabber,Object(i.__extends)(r,f),r.prototype.getHtml=function(){var t=this.R.getResourcePath(this._settings.image.url);if(this.B(t))return this._logger.customerLog("Attention Grabber - Could not load Custom Image because source is http over https",3),this.V.raiseEvent(this.N.EVENTS.AttentionGrabberInsecure,{name:"Custom Image"}),null;t=s.get("TemplatesFactory").get(this._templateId,this._templateVersion,this._templateVariations,{src:t});return t.height(this._settings.image.height).width(this._settings.image.width),t},r.prototype.setLogicCss=function(){f.prototype.setLogicCss.call(this),this._attentionGrabberWrapper.height(this._settings.image.height).width(this._settings.image.width)},r.prototype.B=function(t){return!!t&&0==window.location.href.indexOf("https://")&&-1==t.indexOf("https://")},r);function r(t,i,n,s,e,r,o,h,a,u,c,m,l){t=f.call(this,t,i,n,s,e,r,o,h,a,l)||this;return t.V=c,t.N=m,t._mainClass="custom-image",t.R=u,t}s.register("CustomImageAttentionGrabber").asCtor(e).asProto().dependencies("Lib, CommonUtils, TimerManager, EndUsersManager, AuditSourceManager, HostData, WmAjax, SafeFullUrlProvider, DomManager, ResourceManager, CommonEvents, Consts")},1314:function(t,i,n){"use strict";n.r(i),n.d(i,"ImageAttentionGrabber",function(){return e});var c,i=n(0),s=n(140),n=n(1184),e=(c=n.AttentionGrabberBase,Object(i.__extends)(r,c),r.prototype.getHtml=function(){return wmjQuery("<img src='"+this._settings.filename+"' />")},r.prototype.innerSetup=function(){return this._settings.filename&&(this._settings.filename=this._lib.ResourceManager.getResourcePath(this._settings.filename)),-1!=parseInt(this._settings.id)},r.prototype.postDrawing=function(){this.J()},r.prototype.J=function(){var t,i=wmjQuery.proxy(this.X,this),n=this._player,i=i(),n="1"==n.attr("data-inanimation");i||n?(this.Y++,10<this.Y||(t=wmjQuery.proxy(this.J,this),this._timerManager.libSetTimeout(function(){t()},500))):this.K()},r.prototype.K=function(){var t="0px",i="0px",n="auto",s="auto",e=parseInt(this._settings.hOffset),r=parseInt(this._settings.vOffset),o=(this._player.width()-this._attentionGrabberWrapper.width())/2,h=(this._player.height()-this._attentionGrabberWrapper.height())/2,a=this.q("auto","bottom",h,r),n=this.q(n,"top",h,r),u=this.q("auto","right",o,e),s=this.q(s,"left",o,e);-1<this._config[this.POSITION].indexOf("center")&&(s="50%",i=this.$(i,"margin-left",o,e),i=this._("width",i)),-1<this._config[this.POSITION].indexOf("middle")&&(n="50%",t=this.$(t,"margin-top",h,r),t=this._("height",t)),this._attentionGrabberWrapper.css({position:"fixed",top:n,right:u,bottom:a,left:s,"margin-top":t,"margin-right":"0px","margin-bottom":"0px","margin-left":i}),this._attentionGrabberWrapper.show()},r.prototype.q=function(t,i,n,s){return-1<this._config[this.POSITION].indexOf(i)?this.$(t,i,n,s):t},r.prototype.$=function(t,i,n,s){return t=parseFloat(this._player.css(i).replace("px","")),(t+=n)+s+"px"},r.prototype._=function(t,i){return this._player.hasClass("walkme-dynamic-size")?parseFloat(i.replace("px",""))+this._player.css(t).replace("px","")/2*-1:i},r.prototype.X=function(){return 0==this._player.width()||28==this._player.width()||0==this._attentionGrabberWrapper.width()||28==this._attentionGrabberWrapper.width()||24==this._attentionGrabberWrapper.width()&&24==this._attentionGrabberWrapper.width()},r);function r(t,i,n,s,e,r,o,h,a,u){t=c.call(this,t,i,n,s,e,r,o,h,a,u)||this;return t.Y=0,t._oldAG&&(t._oldAGData.id&&(t._settings.id=t._oldAGData.id),t._oldAGData.filename&&(t._settings.filename=t._oldAGData.filename),t._oldAGData.hOffset&&(t._settings.hOffset=t._oldAGData.hOffset),t._oldAGData.vOffset&&(t._settings.vOffset=t._oldAGData.vOffset)),t}s.register("ImageAttentionGrabber").asCtor(e).asProto().dependencies("Lib, CommonUtils, TimerManager, EndUsersManager, AuditSourceManager, HostData, WmAjax, SafeFullUrlProvider, DomManager")},1315:function(t,i,n){"use strict";n.r(i),n.d(i,"MenuOverviewAttentionGrabber",function(){return s});var m,i=n(0),l=n(140),n=n(1184),s=(m=n.AttentionGrabberBase,Object(i.__extends)(e,m),e.prototype.tt=function(t){this._jQueryMenu=t},e.prototype.it=function(t,i){var n=wmjQuery.proxy(this.nt,this),s=wmjQuery.proxy(function(){var t=wmjQuery.proxy(function(){var t;n(),1==this._stepIndex&&(t={type:this.W},WalkMePlayerAPI.toggleMenu(t))},this);e.remove(t)},this),t={config:{Direction:this._config.Direction},player:t,menu:this._menu,onClickFunc:s,agData:{Id:i.firstBalloon?this._agId:null,ClassType:i.classType,UITemplateId:this._data.UITemplateId,UITemplateVersion:this._data.UITemplateVersion,UIVariationsIds:[this.rt,this._data.ExtraUIVariationsIds[this._stepIndex+1]],Settings:{delay:i.delay,text:i.text,title:i.title,boldText:i.boldText,buttons:[{text:i.buttonText}],firstBalloon:i.firstBalloon,attachedToElementSelector:i.attachedToElementSelector,jQueryMenu:this._jQueryMenu,moveArrow:i.moveArrow,marginRight:i.marginRight,marginBottom:i.marginBottom}}},e=(t.config[this.POSITION]=i.position,l.create("AttentionGrabber",t));(this._currentAg=e).setupAttenGrab()},e.prototype.nt=function(){var n;this._stopPlaying||(this._stepIndex++,this.ot[this._stepIndex]&&(this.ht()?this._jQueryMenu?this.it(this._jQueryMenu,this.ot[this._stepIndex]):(n=wmjQuery.proxy(function(t){this._jQueryMenu=t,this.it(t,this.ot[this._stepIndex])},this),this._menu.bind("on-open-end",function(t,i){t.target.unbind("on-open-end"),n(i.menu)})):this.nt()))},e.prototype.ht=function(){var t=this.ot[this._stepIndex].attachedToElementSelector;return!t||0<wmjQuery(t+":visible",this._jQueryMenu).length},e.prototype.setupAttenGrab=function(){var t;this.at()&&"iOS"!=this._hostData.os().name&&"Android"!=this._hostData.os().name&&(t=wmjQuery.proxy(this.ut,this),this._menu.bind("on-close-begin",function(){t()}),this.it(this._player,this.ot[0]))},e.prototype.at=function(){var t=this.getDefaultOrFirstTab().properties().getAll();return-1<wmjQuery.inArray(l.get("Consts").PROPERTY_CONTAINS_PREFIX+"walkthru",t)},e.prototype.ut=function(){this._stopPlaying=!0,this._currentAg.remove()},e.prototype.remove=function(t){this._currentAg&&this._currentAg.remove(),m.prototype.remove.call(this,t)},e);function e(t,i,n,s,e,r,o,h,a,u){var t=m.call(this,t,i,n,s,e,r,o,h,a,u)||this,c=(t.ot={0:{classType:"3.sub",title:"Meet WalkMe!",text:"Your New Personal Assistant.",buttonText:"Start",position:"bottom-center",firstBalloon:!0},1:{classType:"3.sub",text:"The WalkMe menu is the place to get all the help you might need.",boldText:'Click "Next" and take a look...',buttonText:"Next",position:"bottom-center",delay:1,marginBottom:3},2:{classType:"3.sub",text:"Here you can select your preferred language.",boldText:'Click "Next" to continue...',buttonText:"Next",position:"bottom-center",attachedToElementSelector:"#walkme-languages",moveArrow:!0},3:{classType:"3.sub",text:"Quickly find answers to your support issue by using the search bar.",boldText:'Click "Next" to continue...',buttonText:"Next",position:"right-middle",attachedToElementSelector:".walkme-search-box-container",marginRight:12},4:{classType:"3.sub",text:"All the Walk-Thrus and help resources are located here, click them to start your online guidance.",boldText:'Click "Next" to continue...',buttonText:"Next",position:"right-middle",attachedToElementSelector:".walkme-deployables-list .walkme-tab .walkme-deployable",marginRight:14},5:{classType:"3.sub",text:"Couldn't find what you want? this link takes you to the support page.",boldText:"To learn more about WalkMe, click here.",buttonText:"Next",position:"bottom-center",attachedToElementSelector:".walkme-open-ticket",moveArrow:!0},6:{classType:"3.sub",title:"Thank You!",text:"We're here to help.",buttonText:"Done",position:"bottom-center",marginBottom:3}},t._stepIndex=0,t.rt=t._data.ExtraUIVariationsIds[0],t.ot[0].position=t._config[t.POSITION],t.ot[0].delay=t._settings.delay,t.W=l.get("Consts").STEP_PLAY_INITIATOR_ENUM.ATTENTION_GRABBER,wmjQuery.proxy(t.tt,t));return t._menu.bind("build-menu-end",function(t,i){c(i.menu)}),t}l.register("MenuOverviewAttentionGrabber").asCtor(s).asProto().dependencies("Lib, CommonUtils, TimerManager, EndUsersManager, AuditSourceManager, HostData, WmAjax, SafeFullUrlProvider, DomManager")},1316:function(t,i,n){"use strict";n.r(i);var c,i=n(0),s=n(140),n=n(1251),n=(c=n.CustomTextAttentionGrabber,Object(i.__extends)(e,c),e.prototype.getTemplateData=function(){return{title:this._settings.title,"bold-text":this._settings.boldText,text:this._settings.text,position:this.getOppositeDirection(this._playerMajorPosition),buttons:this._settings.buttons}},e.prototype.setLogicCss=function(){c.prototype.setLogicCss.call(this),this.ct(),this._data.Settings.firstBalloon||this._attentionGrabberWrapper.css("cursor","auto")},e.prototype.ct=function(){var t,i,n;this._data.Settings.moveArrow&&(t=wmjQuery(".wm-outer-arrow",this._attentionGrabberWrapper),n=wmjQuery(".wm-inner-arrow",this._attentionGrabberWrapper),i=t.offset().left,t.css("left","85%"),n.css("left","85%"),n=t.offset().left,this.lt=n-i,this._data.Settings.moveArrow=!1)},e.prototype.bindEvents=function(){c.prototype.bindEvents.call(this),this._attentionGrabberWrapper.off("click"),wmjQuery(".wm-button",this._attentionGrabberWrapper).click(this.ft),this.gt=wmjQuery.proxy(this.bt,this),wmjQuery(window).resize(this.gt),this._data.Settings.firstBalloon&&this._attentionGrabberWrapper.click(this.ft)},e.prototype.unbindEvents=function(){c.prototype.unbindEvents.call(this),wmjQuery(window).off("resize",this.gt)},e.prototype.animate=function(){this.bt(),this._data.Settings.firstBalloon&&c.prototype.animate.call(this)},e.prototype.bt=function(){var t,i,n,s,e,r,o,h=this._attentionGrabberWrapper.css("margin-bottom"),a=this._attentionGrabberWrapper.css("margin-right"),u=this._data.Settings.marginRight||0,c=this._data.Settings.marginBottom||0;this._data.Settings.attachedToElementSelector?(t=this._data.Settings.jQueryMenu,n=(i=wmjQuery(this._data.Settings.attachedToElementSelector,t)).offset().left-t.offset().left,s=i.offset().top-t.offset().top,"bottom"==this._playerMajorPosition?(o=t.width(),r=this._attentionGrabberWrapper.css("margin-bottom"),e=i.width(),o=parseFloat(a)+o/2-n-e/2+this.lt+u,this._attentionGrabberWrapper.css("margin-right",o+"px").css("margin-bottom",parseFloat(r)-s+c+"px")):(e=t.height(),r=i.height(),o=parseFloat(h)+e/2-s-r/2+c,this._attentionGrabberWrapper.css("margin-right",parseFloat(a)-n+u+"px").css("margin-bottom",o+"px"))):this._attentionGrabberWrapper.css("margin-right",parseFloat(a)+u+"px").css("margin-bottom",parseFloat(h)+c+"px")},e);function e(t,i,n,s,e,r,o,h,a,u){t=c.call(this,t,i,n,s,e,r,o,h,a,u)||this;return t._mainClass="menu-overview",t.lt=0,t.ft=u.onClickFunc,t}s.register("MenuOverviewSubAttentionGrabber").asCtor(n).asProto().dependencies("Lib, CommonUtils, TimerManager, EndUsersManager, AuditSourceManager, HostData, WmAjax, SafeFullUrlProvider, DomManager")},1317:function(t,i,n){"use strict";n.r(i),n.d(i,"OldSwooshAttentionGrabber",function(){return e});var c,i=n(0),s=n(140),n=n(1184),e=(c=n.AttentionGrabberBase,Object(i.__extends)(r,c),r.prototype.getHtml=function(){this.dt()?(t=this._settings.width+"px",i="130%"):(i=this._settings.width+"px",t="130%");var t,i,n=this._settings.opacity,s=this._settings.deg;return this._domManager.parseElementAsJquery("<div class='wm-ag-swoosh' style='width: "+t+"; height:"+i+"; position: absolute; top:-6px; right: -6px; background-color: transparent !important; "+this.vt(s)+this.wt(n)+"'/>")},r.prototype.postDrawing=function(){var t=this._settings.right,i=(this._attentionGrabberWrapper.detach().appendTo(this._player),this.dt()?"width":"height"),i=this._player.css(i),n=(this._attentionGrabberWrapper.css({position:"absolute",overflow:"hidden",width:"100%",height:"100%","z-index":this._player.css("z-index"),right:"0",bottom:"auto",top:"0"}).important("background","none"),this._attentionGrabber.show(),this._attentionGrabberWrapper.show(),this.xt("animationDuration"));this.At(i,t,n)},r.prototype.At=function(t,n,s){var e=this._attentionGrabber,r=this.dt()?"right":"top",o=this._timerManager,h=(e.css(r,n+"px"),1.3*parseFloat(t)+"px");!function t(){var i={},i=(i[r]=h,e.animate(i,s),this._stopAnimation);o.setWalkmeTimeout(function(){var t={};t[r]=n+"px",e.animate(t,s)},1e3),i||o.setWalkmeTimeout(t,4e3)}.call(this)},r.prototype.dt=function(){return"hoz"==this.yt},r.prototype.xt=function(t){return this._settings[t]||this.Mt[t]},r.prototype.wt=function(t){return"background: url(data:image/svg+xml;base64,PD94bWwgdmVyc2lvbj0iMS4wIiA/Pgo8c3ZnIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyIgd2lkdGg9IjEwMCUiIGhlaWdodD0iMTAwJSIgdmlld0JveD0iMCAwIDEgMSIgcHJlc2VydmVBc3BlY3RSYXRpbz0ibm9uZSI+CiAgPGxpbmVhckdyYWRpZW50IGlkPSJncmFkLXVjZ2ctZ2VuZXJhdGVkIiBncmFkaWVudFVuaXRzPSJ1c2VyU3BhY2VPblVzZSIgeDE9IjAlIiB5MT0iMCUiIHgyPSIxMDAlIiB5Mj0iMCUiPgogICAgPHN0b3Agb2Zmc2V0PSIwJSIgc3RvcC1jb2xvcj0iI2ZmZmZmZiIgc3RvcC1vcGFjaXR5PSIwIi8+CiAgICA8c3RvcCBvZmZzZXQ9IjUwJSIgc3RvcC1jb2xvcj0iI2ZmZmZmZiIgc3RvcC1vcGFjaXR5PSIwLjkxIi8+CiAgICA8c3RvcCBvZmZzZXQ9IjEwMCUiIHN0b3AtY29sb3I9IiNmZmZmZmYiIHN0b3Atb3BhY2l0eT0iMCIvPgogIDwvbGluZWFyR3JhZGllbnQ+CiAgPHJlY3QgeD0iMCIgeT0iMCIgd2lkdGg9IjEiIGhlaWdodD0iMSIgZmlsbD0idXJsKCNncmFkLXVjZ2ctZ2VuZXJhdGVkKSIgLz4KPC9zdmc+);background: -moz-linear-gradient(left,  rgba(255,255,255,0) 0%, rgba(255,255,255,"+t+") 50%, rgba(255,255,255,0) 100%);background: -webkit-gradient(linear, left top, right top, color-stop(0%,rgba(255,255,255,0)), color-stop(50%,rgba(255,255,255,"+t+")), color-stop(100%,rgba(255,255,255,0)));background: -webkit-linear-gradient(left,  rgba(255,255,255,0) 0%,rgba(255,255,255,"+t+") 50%,rgba(255,255,255,0) 100%);background: -o-linear-gradient(left,  rgba(255,255,255,0) 0%,rgba(255,255,255,"+t+") 50%,rgba(255,255,255,0) 100%);background: -ms-linear-gradient(left,  rgba(255,255,255,0) 0%,rgba(255,255,255,"+t+") 50%,rgba(255,255,255,0) 100%);background: linear-gradient(to right,  rgba(255,255,255,0) 0%,rgba(255,255,255,"+t+") 50%,rgba(255,255,255,0) 100%);"},r.prototype.vt=function(t){return"transform: rotate("+t+"deg); -moz-transform:rotate("+t+"deg); -webkit-transform:rotate("+t+"deg); -o-transform:rotate("+t+"deg);  -ms-transform:rotate("+t+"deg);"},r);function r(t,i,n,s,e,r,o,h,a,u){t=c.call(this,t,i,n,s,e,r,o,h,a,u)||this;return t.Mt={animationDuration:700},t._oldAG&&t._oldAGData.settings&&(t._oldAGData.settings.width&&(t._settings.width=t._oldAGData.settings.width),t._oldAGData.settings.right&&(t._settings.right=t._oldAGData.settings.right),t._oldAGData.settings.deg&&(t._settings.deg=t._oldAGData.settings.deg),t._oldAGData.settings.dir&&(t._settings.dir=t._oldAGData.settings.dir,t.yt=t._oldAGData.settings.dir),t._oldAGData.settings.opacity&&(t._settings.opacity=t._oldAGData.settings.opacity)),t}s.register("OldSwooshAttentionGrabber").asCtor(e).asProto().dependencies("Lib, CommonUtils, TimerManager, EndUsersManager, AuditSourceManager, HostData, WmAjax, SafeFullUrlProvider, DomManager")},1318:function(t,i,n){"use strict";n.r(i),n.d(i,"SwooshAttentionGrabber",function(){return e});var c,i=n(0),s=n(140),n=n(1199),e=(c=n.TemplateAttentionGrabber,Object(i.__extends)(r,c),r.prototype.postDrawing=function(){this._attentionGrabberWrapper.detach().appendTo(this._player),this._attentionGrabberWrapper.css({position:"absolute",overflow:"hidden",width:"100%",height:"100%","z-index":this._player.css("z-index"),right:"0",bottom:"auto",top:"0"}).important("background","none"),this._attentionGrabber.show(),this._attentionGrabberWrapper.show(),this.animate()},r.prototype.animate=function(){var n=this._attentionGrabber,s=this.jt,e=this._timerManager,t=this.dt(),r=t?"right":"top",o=(n.css(r,"-60px"),1.3*parseFloat(this._player.css(t?"width":"height"))+"px"),h=this._stopAnimation;this.It(t),function t(){var i={};i[r]=o,n.animate(i,s),e.setWalkmeTimeout(function(){var t={};t[r]="-60px",n.animate(t,s)},1e3),h||e.setWalkmeTimeout(t,4e3)}()},r.prototype.It=function(t){t?this.Ct("15deg","50px","130%"):this.Ct("105deg","130%","50px")},r.prototype.Ct=function(t,i,n){this._attentionGrabber.css({height:n,width:i,transform:"rotate("+t+")","-moz - transform":"rotate("+t+")","-webkit - transform":"rotate("+t+")","-o - transform":"rotate("+t+")","-ms - transform":"rotate("+t+")"})},r.prototype.dt=function(){return this._player.width()>this._player.height()},r);function r(t,i,n,s,e,r,o,h,a,u){t=c.call(this,t,i,n,s,e,r,o,h,a,u)||this;return t._mainClass="ag",t.jt=t._settings.animationDuration||700,t}s.register("SwooshAttentionGrabber").asCtor(e).asProto().dependencies("Lib, CommonUtils, TimerManager, EndUsersManager, AuditSourceManager, HostData, WmAjax, SafeFullUrlProvider, DomManager")},1319:function(t,i,n){"use strict";n.r(i),n.d(i,"TickerAttentionGrabber",function(){return e});var d,i=n(0),s=n(140),n=n(1217),e=(d=n.BalloonAttentionGrabber,Object(i.__extends)(r,d),r.prototype.setupAttenGrab=function(){0!==this.St.length&&d.prototype.setupAttenGrab.call(this)},r.prototype.getBalloonTitle=function(){return"Help me with..."},r.prototype.getBalloonText=function(){return this.St[this.kt]},r.prototype.Tt=function(){var t=this.St[this.kt];return this.kt<Math.min(this.Gt,this.St.length)-1?this.kt++:this.kt=0,t},r.prototype.animate=function(){this._attentionGrabberWrapper.css({opacity:0});var t=wmjQuery.proxy(this.innerAnimate,this);this._attentionGrabberWrapper.animate({opacity:1},{duration:300,complete:t})},r.prototype.innerAnimate=function(){var t=wmjQuery(".wm-title",this._attentionGrabber),i={opacity:1},n=(t.css(i),this._stopAnimation),s=(t.text(this.Dt.decodeHtml(this.Tt(),["&",'"',"'",">","<"])),wmjQuery.proxy(this.innerAnimate,this)),e=this._timerManager.libSetTimeout;t.animate(i,{duration:700,complete:function(){e(function(){t.animate({opacity:0},{duration:700,complete:function(){n||s()}})},2e3)}})},r.prototype.getDirection=function(){return"ltr"},r);function r(t,i,n,s,e,r,o,h,a,u,c){var m=d.call(this,t,i,n,s,e,r,o,h,a,c)||this,t=(m.Dt=u,m._mainClass="ticker",m.St=[],m.Gt=5,m.getDefaultOrFirstTab());if(t)for(var l=t.children(),f=0,g=0;g<l.length;g++){var b=l[g];if(b.properties().hasProperty("visible")&&(m.St.push(b.name()),f++),f==m.Gt)break}return m.kt=0,m}s.register("TickerAttentionGrabber").asCtor(e).asProto().dependencies("Lib, CommonUtils, TimerManager, EndUsersManager, AuditSourceManager, HostData, WmAjax, SafeFullUrlProvider, DomManager, HtmlDecoder")},1320:function(t,i,n){n(140)},382:function(t,i,n){"use strict";n.r(i),n.d(i,"AttentionGrabberDataManager",function(){return e});var i=n(140),s=n(22),e=(r.prototype.updateSelection=function(t){this.selectedId=t,this.Ut()},r.prototype.updateEvent=function(){this.Qt=(new Date).getTime(),this.Ut()},r.prototype.updateUnload=function(){this.unload=1,this.Ut()},r.prototype.init=function(){var t,i,n=this.Ft.getData(this.Pt),s=(new Date).getTime(),e=this.Zt.get().Settings,r=parseInt(e.AGDataVersion)||0;n?(this.Ot=s,this.sessionCounter=n.sc||1,this.Wt=this.Et.isDefined(n.v)?n.v:r,this.Ht=r>this.Wt,t=n.st?Math.abs(s-n.st):0,i=void 0,this.zt&&(i=this.zt.getItem(this.Ft.keysConfig.attentionGrabber.sessionLength.key)),this.Lt=parseFloat(i||e.AGSL||1440),this.Rt=t/6e4>this.Lt,this.isNewSession=this.Rt||this.Ht,this.sessionCounter=this.Ht?1:this.Rt?this.sessionCounter+1:this.sessionCounter,this.Wt=this.Ht?r:n.v,this.selectedId=this.isNewSession?void 0:n.id,this.Qt=this.isNewSession?s:n.et,this.unload=this.isNewSession?0:n.u,this.eventTimestampDelta=this.Qt?Math.abs(s-this.Qt):0):(this.isNewSession=!0,this.Ot=s,this.sessionCounter=1,this.Wt=r,this.Qt=s,this.unload=0),this.Bt=!0,this.Ut()},r.prototype.Ut=function(){var t;this.Bt&&(t={st:this.Ot,sc:this.sessionCounter,v:this.Wt,id:this.selectedId,et:this.Qt,u:this.unload},this.Ft.saveData(this.Pt,t,this.Ft.keysConfig.attentionGrabber.data.expiry))},r);function r(t,i,n){this.zt=Object(s.get)(),this.Bt=!1,this.Zt=t,this.Ft=i,this.Et=n,this.Pt=i.keysConfig.attentionGrabber.data.key}i.register("AttentionGrabberDataManager").asCtor(e).dependencies("SiteConfigManager, ClientOrServerStorageManager, CommonUtils")},383:function(t,i,s){"use strict";s.r(i),s.d(i,"AttentionGrabberManager",function(){return n});var e=s(0),r=s(140),n=(o.prototype.init=function(t){var i,n;t.config&&t.player&&(this.Vt=t.config,this.Nt=t.player,this.Jt=t.menu,i=this.Vt.Settings.AG,(n=this.Vt.Settings.AGs)&&0<n.length?(this.Xt.init(),this.Yt(n)):i&&this.create(t).setupAttenGrab())},o.prototype.reset=function(){this.Kt=this.qt=this.Vt=this.Nt=this.Jt=void 0},o.prototype.blockLoad=function(){this.$t=!0},o.prototype.Yt=function(t){this.Xt.isNewSession?(i=(i=this._t(t)).sort(function(t,i){return t.Priority-i.Priority}),this.ti(i)):this.ii(t),this.Kt?(this.ni.customerLog("Attention grabber - name: "+this.Kt.Name+", settings:",3),this.ni.customerLog(this.Kt.Settings,3)):this.ni.customerLog("Attention grabber: not selected",3);var i="Attention grabber data: session counter = "+this.Xt.sessionCounter+", selected AG = "+this.Xt.selectedId+", unload AG = "+this.Xt.unload+", event timestamp delta = "+this.Xt.eventTimestampDelta/1e3+"s, session = "+this.Xt.isNewSession;this.ni.customerLog(i,4)},o.prototype._t=function(t){for(var i=[],n=this.Xt.sessionCounter,s=0;s<t.length;s++){var e=t[s],r=e.Settings;this.si(n,r)&&(parseInt(r.newContent)?this.ei.hasNewDeployables()&&(e.Priority-=this.ri,i.push(e)):i.push(e))}return i},o.prototype.ti=function(t){for(var i=0;i<t.length;i++){var n=t[i],s=n.Settings;if(!s.conditions)return this.Kt=n,void this.Xt.updateSelection(n.Id);if(this.oi.evaluate(s.conditions))return this.Kt=n,void this.Xt.updateSelection(n.Id)}},o.prototype.ii=function(t){for(var i=this.Xt.sessionCounter,n=0;n<t.length;n++){var s,e=t[n];e.Settings;if(e.Id==this.Xt.selectedId)return s=e.Settings,void(this.si(i,s)&&this.hi(s)&&(!s.conditions||this.oi.evaluate(s.conditions)?(this.Kt=e,this.Xt.updateSelection(e.Id)):this.ni.customerLog("Attention grabber conditions are not satisfied",5)))}},o.prototype.si=function(t,i){return!(!(i&&this.ai.isDefined(i.session)&&this.ai.isDefined(i.interval))||t<i.session||t!=i.session&&(0==i.interval||(t-i.session)%i.interval!=0))},o.prototype.hi=function(t){if(this.Xt.unload)return!1;if(!t)return!1;var i=this.Xt.eventTimestampDelta,n=parseInt(t.replay);if(!n||!i)return!1;n=60*n*1e3;return t.delay=n<i?0:(n-i)/1e3,!0},o.prototype.load=function(n){return Object(e.__awaiter)(this,void 0,void 0,function(){var i;return Object(e.__generator)(this,function(t){switch(t.label){case 0:return!this.Kt||this.$t?[2]:(i={config:this.Vt,player:this.Nt,menu:this.Jt,agData:this.Kt},[4,s.e(3).then(s.bind(null,1136))]);case 1:return t.sent(),this.qt=r.create("AttentionGrabber",i),this.qt.setupAttenGrab(),n&&n(),[2]}})})},o.prototype.remove=function(t){this.qt?(this.Xt.updateUnload(),this.qt.remove(t)):t&&t()},o.prototype.create=function(t){return this.Vt=t.config,this.Nt=t.player,this.qt=r.create("AttentionGrabber",t),this.qt},o.prototype.getImageAG=function(t){return this.Vt=t.config,this.Nt=t.player,this.qt=r.create("ImageAttentionGrabber",t),this.qt},o);function o(t,i,n,s,e,r){this.ai=r,this.$t=!1,this.ri=1e3,this.oi=t,this.Ft=n,this.ei=s,this.ni=e,this.Xt=i}r.register("AttentionGrabberManager").asCtor(n).dependencies("ConditionTreeEvaluator, AttentionGrabberDataManager, ClientOrServerStorageManager, PublishDataManager, Logger, CommonUtils, SiteConfigManager, Consts")}}]);