window,window._walkmeWebpackJP&&(window._walkmeWebpackJP=window._walkmeWebpackJP||[]).push([[11],{1147:function(t,n,e){var i=_walkmeInternals.ctx;i.register("LiveChatElement").asCtor(e(1533)).dependencies("Mustache, MessageSender, EventSender, Consts, CommonUtils, CommonEvents"),i.register("LiveChatVendorFactory").asCtor(e(1534)).dependencies("EventsTrigger"),i.register("LiveChatSettings").asCtor(e(1535)).dependencies("SiteConfigManager, Logger, BBCodeParser, HtmlDecoder, EventsTrigger"),i.register("LiveChat").asCtor(e(1536)).dependencies("Logger, LiveChatElement, LiveChatVendorFactory").asProto(),i.register("LiveChatAppender").asCtor(e(1537)).dependencies("EventsTrigger, TimerManager, Logger, ConditionTreeEvaluator").asProto(),i.register("TawkChat").asCtor(e(1538)).asProto(),i.register("LiveAgentChat").asCtor(e(1539)).asProto(),i.register("ZopimChat").asCtor(e(1540)).dependencies("Logger, DictionaryUtils, ArrayUtils, CommonUtils").asProto(),i.register("OlarkChat").asCtor(e(1541)).asProto(),i.register("IntercomChat").asCtor(e(1542)).asProto(),i.register("ZendeskChat").asCtor(e(1543)).asProto(),i.register("GenericChat").asCtor(e(1544)).asProto(),i.register("LivechatChat").asCtor(e(1545)).dependencies("ScriptInjector").asProto(),i.register("SnapengageChat").asCtor(e(1546)).asProto(),i.register("HablaChat").asCtor(e(1547)).asProto(),i.register("PureChat").asCtor(e(1548)).asProto(),i.register("ChristianCareMembersChat").asCtor(e(1549)).asProto(),t.exports={init:function(){}}},1533:function(t,n){t.exports=function(e,i,a,c,r,u){var t=this;t.getLiveChatElement=function(t){var n=e.to_html(t.mustacheTemplate,t.mustacheData),n=wmjQuery(n),t=(r.isValueTrue(t.addDisabledClass)&&n.addClass(t.disabledButtonClass),i.send("BeforeAppendingLiveChatButton",{button:n}));return t?t.button:n},t.registerLiveChatClickListener=function(t,n,e){var i,o;r.isValueTrue(n.bindAction)&&(i=n,o=e,t.on("click.walkmeLiveChat",function(t){t.preventDefault(),r.isValueTrue(i.closeWalkmeOnChatOpen)&&window.WalkMePlayerAPI.toggleMenu(),o&&o(),u.raiseEvent(c.EVENTS.LiveChat.LiveChatClicked,{options:i})})),wmjQuery(document).on("click",".walkme-chat-button",function(){var t={type:a.EVENT_APPS.LiveChat,pInit:{type:c.STEP_PLAY_INITIATOR_ENUM.WIDGET}};a.postEvent(a.EVENT_TYPES.Click,t)})},t.destroyLiveChatElement=function(t){wmjQuery(document).off("click",".walkme-chat-button"),t.off("click.walkmeLiveChat"),t.off("click"),t.remove()},function(){}.apply(this,arguments)}},1534:function(t,n,e){!function(o){t.exports=function(e){var i={tawk:"TawkChat",liveagent:"LiveAgentChat",zopim:"ZopimChat",olark:"OlarkChat",intercom:"IntercomChat",zendesk:"ZendeskChat",livechat:"LivechatChat",snapengage:"SnapengageChat",habla:"HablaChat",purechat:"PureChat",ccm:"ChristianCareMembersChat",generic:"GenericChat"};this.create=function(t){var n=i[t.chatVendor.toLowerCase()];if(!n)throw"No chat factory found";e.sync("BeforeChatIsCreated",t,null);n=o.create(n,t);return e.sync("ChatIsCreated",n,null),n},function(){}.apply(this,arguments)}}.call(this,e(2))},1535:function(t,n){t.exports=function(d,m,v,w,p){var C=["chatPlacementSelector","livechatButtonSelector","minimizedChatSelector"],k={closeWalkmeOnChatOpen:!0,chatPlacementSelector:"#walkme-footer",mustacheTemplate:'<div class="walkme-override-css walkme-chat-wrapper"><a id="walkme-livechat-button" class="walkme-chat-button" href="#"><div class="walkme-item-icon walkme-livechat-icon"></div><div class="walkme-item-title walkme-livechat-title">{{buttonText}}</div></a></div>',mustacheData:{buttonText:"Chat With Us"},checkPlayerDelay:500,checkPlayerTimes:10,livechatButtonSelector:"#walkme-livechat-button",disabledButtonClass:"walkme-chat-disabled",position:"after",bindAction:"true",addDisabledClass:"false"};this.getLiveChatSettings=function(){var t,n=k,e=d.get().Settings;if(e&&e.liveChat){for(var i=e.liveChat.mustacheTemplate,o=(i&&(i=w.decodeHtml(i,["&","'",'"',">","<"]),e.liveChat.mustacheTemplate=v.parse(i)),["chatPlacementSelector","mustacheTemplate","livechatButtonSelector","disabledButtonClass","position"]),a=e.liveChat,c=0;c<o.length;c++)a.hasOwnProperty(o[c])&&(void 0===(t=a[o[c]])||0===t.length||"string"==typeof t&&0===wmjQuery.trim(t).length)&&delete a[o[c]];for(var n=wmjQuery.extend({},n,e.liveChat),r=C,u=n,h=0;h<r.length;h++){var s=r[h];u[s]&&(u[s]=w.decodeHtml(u[s],["&","'",'"',">"]))}var f,l=n.mustacheData;for(f in l)l.hasOwnProperty(f)&&(l[f]=w.decodeHtml(l[f],["&","'",'"',">","<"]));return p.sync("LiveChatOptionsLoaded",n,n)}m.customerLog('No custom JSON settings found in the account. Please, check the features tab and make sure there is an entry for "liveChat" in the JSON settings',3)},function(){}.apply(this,arguments)}},1536:function(t,n){t.exports=function(e,t,i,n){var o=this;o.chat=void 0,o.element=void 0,o.shouldCheckForChat=!0,o.destroy=function(){o.element&&t.destroyLiveChatElement(o.element),o.shouldCheckForChat=!1},function(){o.options=n,o.chat=function(n){try{return i.create(n)}catch(t){return void e.customerLog("Impossible to initialize Chat Factory. Make sure the vendor "+n.chatVendor+" is supported",3)}}(o.options),o.chat&&(o.options=wmjQuery.extend(o.options,o.chat.options)),o.element=t.getLiveChatElement(o.options),t.registerLiveChatClickListener(o.element,o.options,function(){o.chat.openChat()})}.apply(this,arguments)}},1537:function(t,n){t.exports=function(a,c,r,u){var h=0,s={before:"walkme-chat-wrapper-left",after:"walkme-chat-wrapper-right"},f={before:function(t,n){t.prepend(n)},after:function(t,n){t.append(n)}};this.append=function(t,n){var e,i,o;n.chat?t.length<1?r.customerLog("Error. I couldn't find the container "+n.options.chatPlacementSelector+" for the button",3):1<t.find(".walkme-chat-wrapper").length?r.customerLog("Button already exists in the footer. Skipping...",3):(n.element.hide(),e=t,(i=n.element).addClass(s[(o=n).options.position]),f[o.options.position].call(o,e,i),n.shouldCheckForChat=!0,function t(n,e){var i;(i=e).isLiveChatPresent&&i.isLiveChatPresent()||i.chat.isChatPresent()&&(void 0===(i=i.options.displayCondition)||u.evaluate(i))?(r.customerLog("Chat validation passed.",3),e.element.show()):e.options.checkPlayerTimes>h&&e.shouldCheckForChat?(h++,r.customerLog("Chat validation #"+h+" failed. Trying again",3),checkLivechatTimeout=c.libSetTimeout(function(){t(n,e)},e.options.checkPlayerDelay)):(a.sync("LiveChatNotFound",e),r.customerLog("Max amount of checks reached, chat is not present",3))}(t,n)):r.customerLog("Error. couldn't append element to an empty live chat configuration",3)}}},1538:function(t,n){function e(t){!function(){this.options=t}.apply(this,arguments)}e.prototype.isChatPresent=function(){return"undefined"!=typeof Tawk_API},e.prototype.openChat=function(){Tawk_API.toggle()},t.exports=e},1539:function(t,n){function e(t){!function(){this.options=t,this.liveAgentId=t.liveAgentId}.apply(this,arguments)}e.prototype.isChatPresent=function(){return"undefined"!=typeof liveagent},e.prototype.openChat=function(){liveagent.startChat(this.liveAgentId)},t.exports=e},1540:function(t,n){function e(t,e,i,n,o){var a={top:100,left:window.screen.width-430,width:450,height:650,menubar:"no",location:"no",resizable:"yes",toolbar:"no",scrollbars:"yes",status:"no"};this.launchChatWindow=function(t){var n=e.getDictionaryKeys(a),n=i.map(n,function(t){return t+"="+a[t]}).join(",")+",";window.open(t,"",n)},function(){this.options=o,this.options.openNewWindow=n.isValueTrue(o.openNewWindow),o.openNewWindow&&!o.key&&t.customerLog("ERROR: Open in new window needs a Key to work in the plugin settings",3)}.apply(this,arguments)}e.prototype.isChatPresent=function(){return this.options.openNewWindow||"undefined"!=typeof $zopim},e.prototype.openChat=function(){this.options.openNewWindow?this.launchChatWindow("http://v2.zopim.com/widget/livechat.html?key="+this.options.key):$zopim.livechat.window.show()},t.exports=e},1541:function(t,n){function e(t){!function(){this.options=t}.apply(this,arguments)}e.prototype.isChatPresent=function(){return"undefined"!=typeof olark},e.prototype.openChat=function(){olark("api.box.expand")},t.exports=e},1542:function(t,n){function e(t){!function(){this.options=t}.apply(this,arguments)}e.prototype.isChatPresent=function(){return"undefined"!=typeof Intercom},e.prototype.openChat=function(){Intercom("show")},t.exports=e},1543:function(t,n){function e(t){!function(){this.options=t}.apply(this,arguments)}e.prototype.isChatPresent=function(){return"undefined"!=typeof zE},e.prototype.openChat=function(){zE.activate()},t.exports=e},1544:function(t,n){function e(t){this.options=t,this.windowObjectReference=null}e.prototype.isChatPresent=function(){return!!this.options.url},e.prototype.openChat=function(){var t,n,e;null==this.windowObjectReference||this.windowObjectReference.closed?(t=(e=this.options).url,n=e.windowWidth,e=void 0===(e=e.windowHeight)?500:e,this.windowObjectReference=window.open(t,"WmGenericChatWindowName","resizable,width=".concat(void 0===n?500:n,",height=").concat(e))):this.windowObjectReference.focus()},t.exports=e},1545:function(t,n){function e(n,e){!function(){var t;(this.options=e).license&&(t=e.license,window.LC_API=window.LC_API||{},window.__lc={license:t},n.loadScriptAsFirstElement({url:("https:"==document.location.protocol?"https://":"http://")+"cdn.livechatinc.com/tracking.js",id:""}))}.apply(this,arguments)}e.prototype.isChatPresent=function(){return"undefined"!=typeof LC_API},e.prototype.openChat=function(){LC_API.open_chat_window()},t.exports=e},1546:function(t,n){function e(t){!function(){this.options=t}.apply(this,arguments)}e.prototype.isChatPresent=function(){return!!window.SnapEngage},e.prototype.openChat=function(){window.SnapEngage.startPreChat()},t.exports=e},1547:function(t,n){function e(t){!function(){this.options=t}.apply(this,arguments)}e.prototype.isChatPresent=function(){return"undefined"!=typeof habla_window},e.prototype.openChat=function(){habla_window.expand()},t.exports=e},1548:function(t,n){function e(t){!function(){this.options=t}.apply(this,arguments)}e.prototype.isChatPresent=function(){return window.purechatApi&&purechatApi.get("chatbox.available")},e.prototype.openChat=function(){purechatApi.set("chatbox.expanded",!0)},t.exports=e},1549:function(t,n){function e(t){!function(){this.options=t}.apply(this,arguments)}e.prototype.isChatPresent=function(){return"undefined"!=typeof chatNow},e.prototype.openChat=function(){chatNow()},t.exports=e}}]);