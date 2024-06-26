window._walkmeWebpackJP&&(window._walkmeWebpackJP=window._walkmeWebpackJP||[]).push([[4],{374:function(t,e,a){"use strict";a.r(e),a.d(e,"AttentionGrabberDataManager",function(){return n});var s=a(122),i=a(29),n=(o.prototype.updateSelection=function(t){this.selectedId=t,this.save()},o.prototype.updateEvent=function(){this._eventTimestamp=(new Date).getTime(),this.save()},o.prototype.updateUnload=function(){this.unload=1,this.save()},o.prototype.init=function(){var t=this._clientOrServerStorageManager.getData(this.AG_DATA_COOKIE_NAME),e=(new Date).getTime(),a=this._siteConfigManager.get().Settings,s=parseInt(a.AGDataVersion)||0;if(t){this._sessionTimestamp=e,this.sessionCounter=t.sc||1,this._version=this._commonUtils.isDefined(t.v)?t.v:s,this._shouldUpdateVersion=s>this._version;var i=t.st?Math.abs(e-t.st):0,n=void 0;this.localStorage&&(n=this.localStorage.getItem(this._clientOrServerStorageManager.keysConfig.attentionGrabber.sessionLength.key)),this._sessionLength=parseFloat(n||a.AGSL||1440),this._shouldUpdateCounter=i/6e4>this._sessionLength,this.isNewSession=this._shouldUpdateCounter||this._shouldUpdateVersion,this.sessionCounter=this._shouldUpdateVersion?1:this._shouldUpdateCounter?this.sessionCounter+1:this.sessionCounter,this._version=this._shouldUpdateVersion?s:t.v,this.selectedId=this.isNewSession?void 0:t.id,this._eventTimestamp=this.isNewSession?e:t.et,this.unload=this.isNewSession?0:t.u,this.eventTimestampDelta=this._eventTimestamp?Math.abs(e-this._eventTimestamp):0}else this.isNewSession=!0,this._sessionTimestamp=e,this.sessionCounter=1,this._version=s,this._eventTimestamp=e,this.unload=0;this._dataManagerWasInit=!0,this.save()},o.prototype.save=function(){if(this._dataManagerWasInit){var t={st:this._sessionTimestamp,sc:this.sessionCounter,v:this._version,id:this.selectedId,et:this._eventTimestamp,u:this.unload};this._clientOrServerStorageManager.saveData(this.AG_DATA_COOKIE_NAME,t,this._clientOrServerStorageManager.keysConfig.attentionGrabber.data.expiry)}},o);function o(t,e,a){this.localStorage=Object(i.get)(),this._dataManagerWasInit=!1,this._siteConfigManager=t,this._clientOrServerStorageManager=e,this._commonUtils=a,this.AG_DATA_COOKIE_NAME=e.keysConfig.attentionGrabber.data.key}s.register("AttentionGrabberDataManager").asCtor(n).dependencies("SiteConfigManager, ClientOrServerStorageManager, CommonUtils")},375:function(t,e,s){"use strict";s.r(e),s.d(e,"AttentionGrabberManager",function(){return a});var i=s(0),n=s(122),a=(o.prototype.init=function(t){if(t.config&&t.player){this._config=t.config,this._player=t.player,this._menu=t.menu;var e=this._config.Settings.AG,a=this._config.Settings.AGs;a&&0<a.length?(this._agDataManager.init(),this.initAllAGs(a)):e&&this.create(t).setupAttenGrab()}},o.prototype.reset=function(){this._agData=this._agClass=this._config=this._player=this._menu=void 0},o.prototype.initAllAGs=function(t){if(this._agDataManager.isNewSession){1===this._agDataManager.sessionCounter&&this._publishDataManager.saveDataVersion();var e=this.getPotentialAGsForNewSession(t);e=e.sort(function(t,e){return t.Priority-e.Priority}),this.updateAGForNewSession(e)}else this.updateAGForOldSession(t);this._agData?(this._logger.customerLog("Attention grabber - name: "+this._agData.Name+", settings:",3),this._logger.customerLog(this._agData.Settings,3)):this._logger.customerLog("Attention grabber: not selected",3);var a="Attention grabber data: session counter = "+this._agDataManager.sessionCounter+", selected AG = "+this._agDataManager.selectedId+", unload AG = "+this._agDataManager.unload+", event timestamp delta = "+this._agDataManager.eventTimestampDelta/1e3+"s, session = "+this._agDataManager.isNewSession;this._logger.customerLog(a,4)},o.prototype.getPotentialAGsForNewSession=function(t){for(var e=[],a=this._agDataManager.sessionCounter,s=0;s<t.length;s++){var i=t[s],n=i.Settings;this.shouldPlayAtSession(a,n)&&(parseInt(n.newContent)?this._publishDataManager.hasNewDeployables()&&(i.Priority-=this.NEW_CONTENT_PRIORITY,e.push(i)):e.push(i))}return e},o.prototype.updateAGForNewSession=function(t){for(var e=0;e<t.length;e++){var a=t[e],s=a.Settings;if(!s.conditions)return this._agData=a,void this._agDataManager.updateSelection(a.Id);if(this._conditionTreeEvaluator.evaluate(s.conditions))return this._agData=a,void this._agDataManager.updateSelection(a.Id)}},o.prototype.updateAGForOldSession=function(t){for(var e=this._agDataManager.sessionCounter,a=0;a<t.length;a++){var s=t[a],i=s.Settings;if(s.Id==this._agDataManager.selectedId)return i=s.Settings,void(this.shouldPlayAtSession(e,i)&&this.shouldReplayAG(i)&&(i.conditions?this._conditionTreeEvaluator.evaluate(i.conditions)?(this._agData=s,this._agDataManager.updateSelection(s.Id)):this._logger.customerLog("Attention grabber conditions are not satisfied",5):(this._agData=s,this._agDataManager.updateSelection(s.Id))))}},o.prototype.shouldPlayAtSession=function(t,e){return!(!(e&&this.commonUtils.isDefined(e.session)&&this.commonUtils.isDefined(e.interval))||t<e.session||t!=e.session&&(0==e.interval||(t-e.session)%e.interval!=0))},o.prototype.shouldReplayAG=function(t){if(this._agDataManager.unload)return!1;if(!t)return!1;var e=this._agDataManager.eventTimestampDelta,a=parseInt(t.replay);if(!a||!e)return!1;var s=60*a*1e3;return t.delay=s<e?0:(s-e)/1e3,!0},o.prototype.load=function(a){return Object(i.__awaiter)(this,void 0,void 0,function(){var e;return Object(i.__generator)(this,function(t){switch(t.label){case 0:return this._agData?(e={config:this._config,player:this._player,menu:this._menu,agData:this._agData},[4,s.e(3).then(s.bind(null,1121))]):[2];case 1:return t.sent(),this._agClass=n.create("AttentionGrabber",e),this._agClass.setupAttenGrab(),a&&a(),[2]}})})},o.prototype.remove=function(t){this._agClass?(this._agDataManager.updateUnload(),this._agClass.remove(t)):t&&t()},o.prototype.create=function(t){return this._config=t.config,this._player=t.player,this._agClass=n.create("AttentionGrabber",t),this._agClass},o.prototype.getImageAG=function(t){return this._config=t.config,this._player=t.player,this._agClass=n.create("ImageAttentionGrabber",t),this._agClass},o);function o(t,e,a,s,i,n){this.commonUtils=n,this.NEW_CONTENT_PRIORITY=1e3,this._conditionTreeEvaluator=t,this._clientOrServerStorageManager=a,this._publishDataManager=s,this._logger=i,this._agDataManager=e}n.register("AttentionGrabberManager").asCtor(a).dependencies("ConditionTreeEvaluator, AttentionGrabberDataManager, ClientOrServerStorageManager, PublishDataManager, Logger, CommonUtils, SiteConfigManager, Consts")}}]);