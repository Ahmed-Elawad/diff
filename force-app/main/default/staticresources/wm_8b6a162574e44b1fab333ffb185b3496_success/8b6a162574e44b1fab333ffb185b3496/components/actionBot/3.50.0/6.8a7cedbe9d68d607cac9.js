(window._walkmeABWebpackJP_latest=window._walkmeABWebpackJP_latest||[]).push([[6],{761:function(e,t,r){"use strict";(function(e,n,a){function u(e){return e&&e.__esModule?e:{default:e}}function i(){return g.default.getUiDataProvider().uiObjectsTree().reduce(function(t,r){var n=r.properties();return n.hasProperty(v.UI_PROPERTIES.Search)&&n.hasProperty(v.UI_PROPERTIES.Visible)?[].concat(function(t){if(Array.isArray(t)){for(var r=0,n=Array(t.length);t.length>r;r++)n[r]=t[r];return n}return e(t)}(t),[r]):t},[])}function o(e){return"walkme-"+e.type()+"-"+e.id()}function d(e,t,r){return function(){"walkthru"===t&&S.sendMenuEvent("WalkthruSelected",e),function(e){e({type:g.default.deps.classWalkMeAPI.getPlayInitiatorEnum().API})}(r)}}function l(e){var t=e.reduce(function(e,t){return 0>t.properties().indexOf("visible")?e:n(e,(u=t,(a=t.uniqueClass)in(r={})?Object.defineProperty(r,a,{value:u,enumerable:!0,configurable:!0,writable:!0}):r[a]=u,r));var r,a,u},{});return a(t)}Object.defineProperty(t,"__esModule",{value:!0});var s,c=u(r(779)),g=u(r(113)),f=(0,c.default)(),v=g.default.deps.consts,p=g.default.deps.userGuidContainer,S=g.default.getCommonUtils(),m=g.default.getGuidGenerator(),P=g.default.getLogger(),b=g.default.getLibInitializer(),h=g.default.getAuditingEnabledIndicator(),E=void 0,w=void 0,y=void 0;s=new f.SearchEventSender({logger:P,consts:v,eventSender:g.default.deps.eventSender}),y=new f.SearchClickReporter(function(e){return{commonUtils:S,userGuid:p.getUserGuid(),serverName:b.getPlayerServer(),wmAjax:g.default.deps.wmAjax,dataSenderManager:g.default.getServerDataSenderManager(),logger:P,isAuditDisabledFunc:function(){return!h.isEnabled()},getPlayerServerFunc:b.getPlayerServer,getABPermutationIdFunc:g.default.getAbPermutationManager().getPermutation,getEndUserGuidFunc:g.default.deps.endUsersManager.getEndUserGuid,getEnvIdFunc:g.default.deps.auditSourceManager.get,generateNewGuidFunc:m.generateGuid,searchEventSender:e}}(s)),E=[],i().forEach(function(e){var t=new f.SearchDeployablesEngine({commonEvents:g.default.deps.commonEvents,commonUtils:S,consts:v,logger:P,configSettings:g.default.getSiteConfig().Settings,createAction:d,reporter:y,getUniqueClassFunc:o,isFeatureActiveFunc:g.default.getFeaturesManager().isFeatureEnabled,getHostDataFunc:g.default.getHostData,clientStorageManager:g.default.deps.clientStorageManager,toJSON:g.default.getJsonUtils().toJSON,getCommonUtilsFunc:function(){return S}});t.init(e),E.push(t)}),w=new f.SearchTermSaver({reporter:y,logger:P,userGuid:p.getUserGuid()}),t.default={searchDeployables:function(e){return w.saveSearch(e,m.generateGuid()),l(E.reduce(function(t,r){return t.concat(r.search(e))},[]).filter(function(e){return e&&"tab"!==e.type}))}}}).call(this,r(31).from,r(8).assign,r(8).values)}}]);