window._walkmeWebpackJP&&(window._walkmeWebpackJP=window._walkmeWebpackJP||[]).push([[21],{1139:function(i,t,r){(function(t){var e=r(1167),n={init:function(){t.register("ComponentAPI").dependencies("RichTextEditorConverter").asCtor(function(t){this.getRichTextElement=t.getRichTextElement})},services:["RichTextEditorConverter"],types:[]};r(1349),r(1350),r(1359),r(1360),r(1361),r(1362),r(1363),r(9).registerApi(n,e),i.exports=n}).call(this,r(2))},1167:function(t,e,n){t.exports=n(9).create()},1169:function(t,e,n){"use strict";Object.defineProperty(e,"__esModule",{value:!0});var i,r,o,s,a,u,l,c,p,f,d;e.NewLine="\n",(r=i=i||{}).Ordered="ordered",r.Bullet="bullet",r.Checked="checked",r.Unchecked="unchecked",e.ListType=i,(s=o=o||{}).Sub="sub",s.Super="super",e.ScriptType=o,(a||(a={})).Rtl="rtl",e.DirectionType=a,(l=u=u||{}).Left="left",l.Center="center",l.Right="right",l.Justify="justify",e.AlignType=u,(p=c=c||{}).Image="image",p.Video="video",p.Formula="formula",p.Text="text",e.DataType=c,(d=f=f||{}).Block="block",d.InlineGroup="inline-group",d.List="list",d.Video="video",e.GroupType=f},1176:function(t,e,n){"use strict";Object.defineProperty(e,"__esModule",{value:!0});var i=n(1351);e.QuillDeltaToHtmlConverter=i.QuillDeltaToHtmlConverter;var r=n(1218);e.OpToHtmlConverter=r.OpToHtmlConverter;var o=n(1178);e.InlineGroup=o.InlineGroup,e.VideoItem=o.VideoItem,e.BlockGroup=o.BlockGroup,e.ListGroup=o.ListGroup,e.ListItem=o.ListItem,e.BlotBlock=o.BlotBlock;var s=n(1203);e.DeltaInsertOp=s.DeltaInsertOp;var a=n(1204);e.InsertDataQuill=a.InsertDataQuill,e.InsertDataCustom=a.InsertDataCustom;var u=n(1169);e.NewLine=u.NewLine,e.ListType=u.ListType,e.ScriptType=u.ScriptType,e.DirectionType=u.DirectionType,e.AlignType=u.AlignType,e.DataType=u.DataType,e.GroupType=u.GroupType},1177:function(t,e,n){"use strict";Object.defineProperty(e,"__esModule",{value:!0}),e.preferSecond=function(t){return 0===t.length?null:2<=t.length?t[1]:t[0]},e.flatten=function n(t){return t.reduce(function(t,e){return t.concat(Array.isArray(e)?n(e):e)},[])},e.find=function(t,e){if(Array.prototype.find)return Array.prototype.find.call(t,e);for(var n=0;n<t.length;n++)if(e(t[n]))return t[n]},e.groupConsecutiveElementsWhile=function(t,e){for(var n,i=[],r=0;r<t.length;r++)n=t[r],0<r&&e(n,t[r-1])?i[i.length-1].push(n):i.push([n]);return i.map(function(t){return 1===t.length?t[0]:t})},e.sliceFromReverseWhile=function(t,e,n){for(var i={elements:[],sliceStartsAt:-1},r=e;0<=r&&n(t[r]);r--)i.sliceStartsAt=r,i.elements.unshift(t[r]);return i},e.intersperse=function(i,r){return i.reduce(function(t,e,n){return t.push(e),n<i.length-1&&t.push(r),t},[])}},1178:function(t,e,n){"use strict";var i,r=this&&this.__extends||(i=Object.setPrototypeOf||{__proto__:[]}instanceof Array&&function(t,e){t.__proto__=e}||function(t,e){for(var n in e)e.hasOwnProperty(n)&&(t[n]=e[n])},function(t,e){function n(){this.constructor=t}i(t,e),t.prototype=null===e?Object.create(e):(n.prototype=e.prototype,new n)});Object.defineProperty(e,"__esModule",{value:!0});function o(t){this.ops=t}e.InlineGroup=o;function s(t){this.op=t}var a,u=(r(l,a=s),l);function l(){return null!==a&&a.apply(this,arguments)||this}e.VideoItem=u;var c,p=(r(f,c=s),f);function f(){return null!==c&&c.apply(this,arguments)||this}e.BlotBlock=p;function d(t,e){this.op=t,this.ops=e}e.BlockGroup=d;function h(t){this.items=t}e.ListGroup=h;function m(t,e){void 0===e&&(e=null),this.item=t,this.innerList=e}e.ListItem=m},1203:function(t,e,n){"use strict";Object.defineProperty(e,"__esModule",{value:!0});var i=n(1169),r=n(1204),o=(s.createNewLineOp=function(){return new s(i.NewLine)},s.prototype.isContainerBlock=function(){var t=this.attributes;return!!(t.blockquote||t.list||t["code-block"]||t.header||t.align||t.direction||t.indent)},s.prototype.isBlockquote=function(){return!!this.attributes.blockquote},s.prototype.isHeader=function(){return!!this.attributes.header},s.prototype.isSameHeaderAs=function(t){return t.attributes.header===this.attributes.header&&this.isHeader()},s.prototype.hasSameAdiAs=function(t){return this.attributes.align===t.attributes.align&&this.attributes.direction===t.attributes.direction&&this.attributes.indent===t.attributes.indent},s.prototype.hasSameIndentationAs=function(t){return this.attributes.indent===t.attributes.indent},s.prototype.hasHigherIndentThan=function(t){return(Number(this.attributes.indent)||0)>(Number(t.attributes.indent)||0)},s.prototype.isInline=function(){return!(this.isContainerBlock()||this.isVideo()||this.isCustomBlock())},s.prototype.isCodeBlock=function(){return!!this.attributes["code-block"]},s.prototype.isJustNewline=function(){return this.insert.value===i.NewLine},s.prototype.isList=function(){return this.isOrderedList()||this.isBulletList()||this.isCheckedList()||this.isUncheckedList()},s.prototype.isOrderedList=function(){return this.attributes.list===i.ListType.Ordered},s.prototype.isBulletList=function(){return this.attributes.list===i.ListType.Bullet},s.prototype.isCheckedList=function(){return this.attributes.list===i.ListType.Checked},s.prototype.isUncheckedList=function(){return this.attributes.list===i.ListType.Unchecked},s.prototype.isACheckList=function(){return this.attributes.list==i.ListType.Unchecked||this.attributes.list===i.ListType.Checked},s.prototype.isSameListAs=function(t){return!!t.attributes.list&&(this.attributes.list===t.attributes.list||t.isACheckList()&&this.isACheckList())},s.prototype.isText=function(){return this.insert.type===i.DataType.Text},s.prototype.isImage=function(){return this.insert.type===i.DataType.Image},s.prototype.isFormula=function(){return this.insert.type===i.DataType.Formula},s.prototype.isVideo=function(){return this.insert.type===i.DataType.Video},s.prototype.isLink=function(){return this.isText()&&!!this.attributes.link},s.prototype.isCustom=function(){return this.insert instanceof r.InsertDataCustom},s.prototype.isCustomBlock=function(){return this.isCustom()&&!!this.attributes.renderAsBlock},s.prototype.isMentions=function(){return this.isText()&&!!this.attributes.mentions},s);function s(t,e){"string"==typeof t&&(t=new r.InsertDataQuill(i.DataType.Text,t+"")),this.insert=t,this.attributes=e||{}}e.DeltaInsertOp=o},1204:function(t,e,n){"use strict";Object.defineProperty(e,"__esModule",{value:!0});function i(t,e){this.type=t,this.value=e}e.InsertDataQuill=i;function r(t,e){this.type=t,this.value=e}e.InsertDataCustom=r},1205:function(t,e,n){"use strict";Object.defineProperty(e,"__esModule",{value:!0});var b=n(1169),L=n(1353),r=n(1354),o=n(1206),C=n(1177),i=(I.sanitize=function(n,t){var i={};if(!n||"object"!=typeof n)return i;var e=["bold","italic","underline","strike","code","blockquote","code-block","renderAsBlock"],r=["background","color"],o=n.font,s=n.size,a=n.link,u=n.script,l=n.list,c=n.header,p=n.align,f=n.direction,d=n.indent,h=n.mentions,m=n.mention,g=n.width,y=n.target,v=n.rel,k=e.concat(r,["font","size","link","script","list","header","align","direction","indent","mentions","mention","width","target","rel"]);if(e.forEach(function(t){var e=n[t];e&&(i[t]=!!e)}),r.forEach(function(t){var e=n[t];e&&(I.IsValidHexColor(e+"")||I.IsValidColorLiteral(e+"")||I.IsValidRGBColor(e+""))&&(i[t]=e)}),o&&I.IsValidFontName(o+"")&&(i.font=o),s&&I.IsValidSize(s+"")&&(i.size=s),g&&I.IsValidWidth(g+"")&&(i.width=g),a&&(i.link=I.sanitizeLinkUsingOptions(a+"",t)),y&&I.isValidTarget(y)&&(i.target=y),v&&I.IsValidRel(v)&&(i.rel=v),u!==b.ScriptType.Sub&&b.ScriptType.Super!==u||(i.script=u),l!==b.ListType.Bullet&&l!==b.ListType.Ordered&&l!==b.ListType.Checked&&l!==b.ListType.Unchecked||(i.list=l),Number(c)&&(i.header=Math.min(Number(c),6)),C.find([b.AlignType.Center,b.AlignType.Right,b.AlignType.Justify,b.AlignType.Left],function(t){return t===p})&&(i.align=p),f===b.DirectionType.Rtl&&(i.direction=f),d&&Number(d)&&(i.indent=Math.min(Number(d),30)),h&&m){var T=L.MentionSanitizer.sanitize(m,t);0<Object.keys(T).length&&(i.mentions=!!h,i.mention=m)}return Object.keys(n).reduce(function(t,e){return-1===k.indexOf(e)&&(t[e]=n[e]),t},i)},I.sanitizeLinkUsingOptions=function(t,e){var n=function(){};e&&"function"==typeof e.urlSanitizer&&(n=e.urlSanitizer);var i=n(t);return"string"==typeof i?i:o.encodeLink(r.sanitize(t))},I.IsValidHexColor=function(t){return!!t.match(/^#([0-9A-F]{6}|[0-9A-F]{3})$/i)},I.IsValidColorLiteral=function(t){return!!t.match(/^[a-z]{1,50}$/i)},I.IsValidRGBColor=function(t){return!!t.match(/^rgb\(((0|25[0-5]|2[0-4]\d|1\d\d|0?\d?\d),\s*){2}(0|25[0-5]|2[0-4]\d|1\d\d|0?\d?\d)\)$/i)},I.IsValidFontName=function(t){return!!t.match(/^[a-z\s0-9\- ]{1,30}$/i)},I.IsValidSize=function(t){return!!t.match(/^[a-z0-9\-]{1,20}$/i)},I.IsValidWidth=function(t){return!!t.match(/^[0-9]*(px|em|%)?$/)},I.isValidTarget=function(t){return!!t.match(/^[_a-zA-Z0-9\-]{1,50}$/)},I.IsValidRel=function(t){return!!t.match(/^[a-zA-Z\s\-]{1,250}$/i)},I);function I(){}e.OpAttributeSanitizer=i},1206:function(t,e,n){"use strict";var i,r;function o(t){return s(i.Html).reduce(u,t)}function s(t){var e=[["&","&amp;"],["<","&lt;"],[">","&gt;"],['"',"&quot;"],["'","&#x27;"],["\\/","&#x2F;"],["\\(","&#40;"],["\\)","&#41;"]];return t===i.Html?e.filter(function(t){var e=t[0];t[1];return-1===e.indexOf("(")&&-1===e.indexOf(")")}):e.filter(function(t){var e=t[0];t[1];return-1===e.indexOf("/")})}function a(t,e){return t.replace(new RegExp(e[0],"g"),e[1])}function u(t,e){return t.replace(new RegExp(e[1],"g"),e[0].replace("\\",""))}Object.defineProperty(e,"__esModule",{value:!0}),(r=i=i||{})[r.Html=0]="Html",r[r.Url=1]="Url",e.makeStartTag=function(t,e){if(void 0===e&&(e=void 0),!t)return"";var n="";e&&(n=[].concat(e).map(function(t){return t.key+(t.value?'="'+t.value+'"':"")}).join(" "));var i=">";return"img"!==t&&"br"!==t||(i="/>"),n?"<"+t+" "+n+i:"<"+t+i},e.makeEndTag=function(t){return void 0===t&&(t=""),t&&"</"+t+">"||""},e.decodeHtml=o,e.encodeHtml=function(t,e){return void 0===e&&(e=!0),e&&(t=o(t)),s(i.Html).reduce(a,t)},e.encodeLink=function(t){var e=s(i.Url),n=e.reduce(u,t);return e.reduce(a,n)}},1207:function(t,e,n){"use strict";Object.defineProperty(e,"__esModule",{value:!0}),e.assign=function(t){for(var e=[],n=1;n<arguments.length;n++)e[n-1]=arguments[n];if(null==t)throw new TypeError("Cannot convert undefined or null to object");for(var i=Object(t),r=0;r<e.length;r++){var o=e[r];if(null!=o)for(var s in o)Object.prototype.hasOwnProperty.call(o,s)&&(i[s]=o[s])}return i}},1218:function(t,s,e){"use strict";Object.defineProperty(s,"__esModule",{value:!0});var l=e(1206),c=e(1169),n=e(1207),a=e(1177),r=e(1205),i={serif:"font-family: Georgia, Times New Roman, serif",monospace:"font-family: Monaco, Courier New, monospace"};s.DEFAULT_INLINE_STYLES={font:function(t){return i[t]||"font-family:"+t},size:{small:"font-size: 0.75em",large:"font-size: 1.5em",huge:"font-size: 2.5em"},indent:function(t,e){var n=3*parseInt(t,10);return"padding-"+("rtl"===e.attributes.direction?"right":"left")+":"+n+"em"},direction:function(t,e){return"rtl"===t?"direction:rtl"+(e.attributes.align?"":"; text-align:inherit"):void 0}};var o=(u.prototype.prefixClass=function(t){return this.options.classPrefix?this.options.classPrefix+"-"+t:t+""},u.prototype.getHtml=function(){var t=this.getHtmlParts();return t.openingTag+t.content+t.closingTag},u.prototype.getHtmlParts=function(){var e=this;if(this.op.isJustNewline()&&!this.op.isContainerBlock())return{openingTag:"",closingTag:"",content:c.NewLine};var t=this.getTags(),n=this.getTagAttributes();!t.length&&n.length&&t.push("span");for(var i=[],r=[],o=function(t){return"img"===t&&!!e.op.attributes.link},s=0,a=t;s<a.length;s++){var u=a[s];o(u)&&i.push(l.makeStartTag("a",this.getLinkAttrs())),i.push(l.makeStartTag(u,n)),r.push("img"===u?"":l.makeEndTag(u)),o(u)&&r.push(l.makeEndTag("a")),n=[]}return r.reverse(),{openingTag:i.join(""),content:this.getContent(),closingTag:r.join("")}},u.prototype.getContent=function(){if(this.op.isContainerBlock())return"";if(this.op.isMentions())return this.op.insert.value;var t=this.op.isFormula()||this.op.isText()?this.op.insert.value:"";return this.options.encodeHtml&&l.encodeHtml(t)||t},u.prototype.getCssClasses=function(){var e=this.op.attributes;if(this.options.inlineStyles)return[];var t=["indent","align","direction","font","size"];return this.options.allowBackgroundClasses&&t.push("background"),t.filter(function(t){return!!e[t]}).filter(function(t){return"background"!==t||r.OpAttributeSanitizer.IsValidColorLiteral(e[t])}).map(function(t){return t+"-"+e[t]}).concat(this.op.isFormula()?"formula":[]).concat(this.op.isVideo()?"video":[]).concat(this.op.isImage()?"image":[]).map(this.prefixClass.bind(this))},u.prototype.getCssStyles=function(){var r=this,o=this.op.attributes,t=[["color"]];return!this.options.inlineStyles&&this.options.allowBackgroundClasses||t.push(["background","background-color"]),this.options.inlineStyles&&(t=t.concat([["indent"],["align","text-align"],["direction"],["font","font-family"],["size"]])),t.filter(function(t){return!!o[t[0]]}).map(function(t){var e=t[0],n=o[e],i=r.options.inlineStyles&&r.options.inlineStyles[e]||s.DEFAULT_INLINE_STYLES[e];return"object"==typeof i?i[n]:"function"!=typeof i?a.preferSecond(t)+":"+n:i(n,r.op)}).filter(function(t){return void 0!==t})},u.prototype.getTagAttributes=function(){if(this.op.attributes.code&&!this.op.isLink())return[];var t=this.makeAttr.bind(this),e=this.getCssClasses(),n=e.length?[t("class",e.join(" "))]:[];if(this.op.isImage())return this.op.attributes.width&&(n=n.concat(t("width",this.op.attributes.width))),n.concat(t("src",this.op.insert.value));if(this.op.isACheckList())return n.concat(t("data-checked",this.op.isCheckedList()?"true":"false"));if(this.op.isFormula())return n;if(this.op.isVideo())return n.concat(t("frameborder","0"),t("allowfullscreen","true"),t("src",this.op.insert.value));if(this.op.isMentions()){var i=this.op.attributes.mention;return i.class&&(n=n.concat(t("class",i.class))),n=i["end-point"]&&i.slug?n.concat(t("href",i["end-point"]+"/"+i.slug)):n.concat(t("href","about:blank")),i.target&&(n=n.concat(t("target",i.target))),n}var r=this.getCssStyles();return r.length&&n.push(t("style",r.join(";"))),this.op.isContainerBlock()||this.op.isLink()&&(n=n.concat(this.getLinkAttrs())),n},u.prototype.makeAttr=function(t,e){return{key:t,value:e}},u.prototype.getLinkAttrs=function(){var t=r.OpAttributeSanitizer.isValidTarget(this.options.linkTarget||"")?this.options.linkTarget:void 0,e=r.OpAttributeSanitizer.IsValidRel(this.options.linkRel||"")?this.options.linkRel:void 0,n=this.op.attributes.target||t,i=this.op.attributes.rel||e;return[].concat(this.makeAttr("href",this.op.attributes.link)).concat(n?this.makeAttr("target",n):[]).concat(i?this.makeAttr("rel",i):[])},u.prototype.getTags=function(){var e=this.op.attributes;if(!this.op.isText())return[this.op.isVideo()?"iframe":this.op.isImage()?"img":"span"];for(var t=this.options.paragraphTag||"p",n=0,i=[["blockquote"],["code-block","pre"],["list",this.options.listItemTag],["header"],["align",t],["direction",t],["indent",t]];n<i.length;n++){var r=i[n],o=r[0];if(e[o])return"header"===o?["h"+e[o]]:[a.preferSecond(r)]}return[["link","a"],["mentions","a"],["script"],["bold","strong"],["italic","em"],["strike","s"],["underline","u"],["code"]].filter(function(t){return!!e[t[0]]}).map(function(t){return"script"===t[0]?e[t[0]]===c.ScriptType.Sub?"sub":"sup":a.preferSecond(t)})},u);function u(t,e){this.op=t,this.options=n.assign({},{classPrefix:"ql",inlineStyles:void 0,encodeHtml:!0,listItemTag:"li",paragraphTag:"p"},e)}s.OpToHtmlConverter=o},1349:function(t,e,n){n(1167).register("RichTextEditorDefaults").dependencies("FontStyleTranslator").asCtor(function(e){this.CONFIG={encodeHtml:!1,classPrefix:"wm-vd-rte",inlineStyles:{size:function(t){return"font-size:"+t},font:function(t){return"font-family:"+e.getFontFamilyWithFallback(t)}}}})},1350:function(t,e,n){var i=n(1167),r=n(1176),l=r.OpToHtmlConverter,c=r.DeltaInsertOp;i.register("ActionElement").asCtor(function(r,o,s,a,u){this.getHtml=function(t){var e,n=new l(new c(t.insert.value.text,(e=t.attributes,u.extend({underline:!0},e))),s.CONFIG),i=r.parseElement(n.getHtml());return i.setAttribute("href",""),i.setAttribute(o.RICH_TEXT_EDITOR.ACTION_LINK_ATTR,a.toJSON(t.insert.value)),i.outerHTML}}).dependencies("DomManager, Consts, RichTextEditorDefaults, JsonUtils, wmjQuery")},1351:function(t,e,n){"use strict";Object.defineProperty(e,"__esModule",{value:!0});var r=n(1352),o=n(1218),s=n(1357),i=n(1178),a=n(1358),u=n(1206),l=n(1207),c=n(1169),p="<br/>",f=(d.prototype._getListTag=function(t){return t.isOrderedList()?this.options.orderedListTag+"":t.isBulletList()?this.options.bulletListTag+"":t.isCheckedList()?this.options.bulletListTag+"":t.isUncheckedList()?this.options.bulletListTag+"":""},d.prototype.getGroupedOps=function(){var t=r.InsertOpsConverter.convert(this.rawDeltaOps,this.options),e=s.Grouper.pairOpsWithTheirBlock(t),n=s.Grouper.groupConsecutiveSameStyleBlocks(e,{blockquotes:!!this.options.multiLineBlockquote,header:!!this.options.multiLineHeader,codeBlocks:!!this.options.multiLineCodeblock}),i=s.Grouper.reduceConsecutiveSameStyleBlocksToOne(n);return(new a.ListNester).nest(i)},d.prototype.convert=function(){var n=this;return this.getGroupedOps().map(function(e){if(e instanceof i.ListGroup)return n._renderWithCallbacks(c.GroupType.List,e,function(){return n._renderList(e)});if(e instanceof i.BlockGroup){var t=e;return n._renderWithCallbacks(c.GroupType.Block,e,function(){return n._renderBlock(t.op,t.ops)})}return e instanceof i.BlotBlock?n._renderCustom(e.op,null):e instanceof i.VideoItem?n._renderWithCallbacks(c.GroupType.Video,e,function(){var t=e;return new o.OpToHtmlConverter(t.op,n.converterOptions).getHtml()}):n._renderWithCallbacks(c.GroupType.InlineGroup,e,function(){return n._renderInlines(e.ops,!0)})}).join("")},d.prototype._renderWithCallbacks=function(t,e,n){var i="",r=this.callbacks.beforeRender_cb;i=(i="function"==typeof r?r.apply(null,[t,e]):"")||n();var o=this.callbacks.afterRender_cb;return i="function"==typeof o?o.apply(null,[t,i]):i},d.prototype._renderList=function(t){var e=this,n=t.items[0];return u.makeStartTag(this._getListTag(n.item.op))+t.items.map(function(t){return e._renderListItem(t)}).join("")+u.makeEndTag(this._getListTag(n.item.op))},d.prototype._renderListItem=function(t){t.item.op.attributes.indent=0;var e=new o.OpToHtmlConverter(t.item.op,this.converterOptions).getHtmlParts(),n=this._renderInlines(t.item.ops,!1);return e.openingTag+n+(t.innerList?this._renderList(t.innerList):"")+e.closingTag},d.prototype._renderBlock=function(e,t){var n=this,i=new o.OpToHtmlConverter(e,this.converterOptions).getHtmlParts();if(e.isCodeBlock())return i.openingTag+u.encodeHtml(t.map(function(t){return t.isCustom()?n._renderCustom(t,e):t.insert.value}).join(""))+i.closingTag;var r=t.map(function(t){return n._renderInline(t,e)}).join("");return i.openingTag+(r||p)+i.closingTag},d.prototype._renderInlines=function(t,e){var n=this;void 0===e&&(e=!0);var i=t.length-1,r=t.map(function(t,e){return 0<e&&e===i&&t.isJustNewline()?"":n._renderInline(t,null)}).join("");if(!e)return r;var o=u.makeStartTag(this.options.paragraphTag),s=u.makeEndTag(this.options.paragraphTag);return r===p||this.options.multiLineParagraph?o+r+s:o+r.split(p).map(function(t){return""===t?p:t}).join(s+o)+s},d.prototype._renderInline=function(t,e){return t.isCustom()?this._renderCustom(t,e):new o.OpToHtmlConverter(t,this.converterOptions).getHtml().replace(/\n/g,p)},d.prototype._renderCustom=function(t,e){var n=this.callbacks.renderCustomOp_cb;return"function"==typeof n?n.apply(null,[t,e]):""},d.prototype.beforeRender=function(t){"function"==typeof t&&(this.callbacks.beforeRender_cb=t)},d.prototype.afterRender=function(t){"function"==typeof t&&(this.callbacks.afterRender_cb=t)},d.prototype.renderCustomWith=function(t){this.callbacks.renderCustomOp_cb=t},d);function d(t,e){var n;this.rawDeltaOps=[],this.callbacks={},this.options=l.assign({paragraphTag:"p",encodeHtml:!0,classPrefix:"ql",inlineStyles:!1,multiLineBlockquote:!0,multiLineHeader:!0,multiLineCodeblock:!0,multiLineParagraph:!0,allowBackgroundClasses:!1,linkTarget:"_blank"},e,{orderedListTag:"ol",bulletListTag:"ul",listItemTag:"li"}),n=this.options.inlineStyles?"object"==typeof this.options.inlineStyles?this.options.inlineStyles:{}:void 0,this.converterOptions={encodeHtml:this.options.encodeHtml,classPrefix:this.options.classPrefix,inlineStyles:n,listItemTag:this.options.listItemTag,paragraphTag:this.options.paragraphTag,linkRel:this.options.linkRel,linkTarget:this.options.linkTarget,allowBackgroundClasses:this.options.allowBackgroundClasses},this.rawDeltaOps=t}e.QuillDeltaToHtmlConverter=f},1352:function(t,e,n){"use strict";Object.defineProperty(e,"__esModule",{value:!0});var u=n(1203),i=n(1169),r=n(1204),l=n(1205),c=n(1355),o=(p.convert=function(t,e){if(!Array.isArray(t))return[];for(var n,i,r=[],o=0,s=[].concat.apply([],t.map(c.InsertOpDenormalizer.denormalize));o<s.length;o++){var a=s[o];a.insert&&(n=p.convertInsertVal(a.insert,e))&&(i=l.OpAttributeSanitizer.sanitize(a.attributes,e),r.push(new u.DeltaInsertOp(n,i)))}return r},p.convertInsertVal=function(t,e){if("string"==typeof t)return new r.InsertDataQuill(i.DataType.Text,t);if(!t||"object"!=typeof t)return null;var n=Object.keys(t);return n.length?i.DataType.Image in t?new r.InsertDataQuill(i.DataType.Image,l.OpAttributeSanitizer.sanitizeLinkUsingOptions(t[i.DataType.Image]+"",e)):i.DataType.Video in t?new r.InsertDataQuill(i.DataType.Video,l.OpAttributeSanitizer.sanitizeLinkUsingOptions(t[i.DataType.Video]+"",e)):i.DataType.Formula in t?new r.InsertDataQuill(i.DataType.Formula,t[i.DataType.Formula]):new r.InsertDataCustom(n[0],t[n[0]]):null},p);function p(){}e.InsertOpsConverter=o},1353:function(t,e,n){"use strict";Object.defineProperty(e,"__esModule",{value:!0});var i=n(1205),r=(o.sanitize=function(t,e){var n={};return t&&"object"==typeof t&&(t.class&&o.IsValidClass(t.class)&&(n.class=t.class),t.id&&o.IsValidId(t.id)&&(n.id=t.id),o.IsValidTarget(t.target+"")&&(n.target=t.target),t.avatar&&(n.avatar=i.OpAttributeSanitizer.sanitizeLinkUsingOptions(t.avatar+"",e)),t["end-point"]&&(n["end-point"]=i.OpAttributeSanitizer.sanitizeLinkUsingOptions(t["end-point"]+"",e)),t.slug&&(n.slug=t.slug+"")),n},o.IsValidClass=function(t){return!!t.match(/^[a-zA-Z0-9_\-]{1,500}$/i)},o.IsValidId=function(t){return!!t.match(/^[a-zA-Z0-9_\-\:\.]{1,500}$/i)},o.IsValidTarget=function(t){return-1<["_self","_blank","_parent","_top"].indexOf(t)},o);function o(){}e.MentionSanitizer=r},1354:function(t,e,n){"use strict";Object.defineProperty(e,"__esModule",{value:!0}),e.sanitize=function(t){var e=t;return e=e.replace(/^\s*/gm,""),/^((https?|s?ftp|file|blob|mailto|tel):|#|\/|data:image\/)/.test(e)?e:"unsafe:"+e}},1355:function(t,e,n){"use strict";Object.defineProperty(e,"__esModule",{value:!0});var i=n(1169),r=n(1356),o=n(1207),s=(a.denormalize=function(e){if(!e||"object"!=typeof e)return[];if("object"==typeof e.insert||e.insert===i.NewLine)return[e];var t=r.tokenizeWithNewLines(e.insert+"");if(1===t.length)return[e];var n=o.assign({},e,{insert:i.NewLine});return t.map(function(t){return t===i.NewLine?n:o.assign({},e,{insert:t})})},a);function a(){}e.InsertOpDenormalizer=s},1356:function(t,e,n){"use strict";Object.defineProperty(e,"__esModule",{value:!0}),e.tokenizeWithNewLines=function(t){if("\n"===t)return[t];var e=t.split("\n");if(1===e.length)return e;var i=e.length-1;return e.reduce(function(t,e,n){return n!==i?""!==e?t=t.concat(e,"\n"):t.push("\n"):""!==e&&t.push(e),t},[])}},1357:function(t,e,n){"use strict";Object.defineProperty(e,"__esModule",{value:!0});var r=n(1203),a=n(1177),u=n(1178),i=(o.pairOpsWithTheirBlock=function(t){for(var e,n=[],i=function(t){return!(t.isJustNewline()||t.isCustomBlock()||t.isVideo()||t.isContainerBlock())},r=function(t){return t.isInline()},o=t.length-1;0<=o;o--){var s=t[o];s.isVideo()?n.push(new u.VideoItem(s)):s.isCustomBlock()?n.push(new u.BlotBlock(s)):(s.isContainerBlock()?(e=a.sliceFromReverseWhile(t,o-1,i),n.push(new u.BlockGroup(s,e.elements))):(e=a.sliceFromReverseWhile(t,o-1,r),n.push(new u.InlineGroup(e.elements.concat(s)))),o=-1<e.sliceStartsAt?e.sliceStartsAt:o)}return n.reverse(),n},o.groupConsecutiveSameStyleBlocks=function(t,n){return void 0===n&&(n={header:!0,codeBlocks:!0,blockquotes:!0}),a.groupConsecutiveElementsWhile(t,function(t,e){return t instanceof u.BlockGroup&&e instanceof u.BlockGroup&&(n.codeBlocks&&o.areBothCodeblocks(t,e)||n.blockquotes&&o.areBothBlockquotesWithSameAdi(t,e)||n.header&&o.areBothSameHeadersWithSameAdi(t,e))})},o.reduceConsecutiveSameStyleBlocksToOne=function(t){var i=r.DeltaInsertOp.createNewLineOp();return t.map(function(t){if(!Array.isArray(t))return t instanceof u.BlockGroup&&!t.ops.length&&t.ops.push(i),t;var n=t.length-1;return t[0].ops=a.flatten(t.map(function(t,e){return t.ops.length?t.ops.concat(e<n?[i]:[]):[i]})),t[0]})},o.areBothCodeblocks=function(t,e){return t.op.isCodeBlock()&&e.op.isCodeBlock()},o.areBothSameHeadersWithSameAdi=function(t,e){return t.op.isSameHeaderAs(e.op)&&t.op.hasSameAdiAs(e.op)},o.areBothBlockquotesWithSameAdi=function(t,e){return t.op.isBlockquote()&&e.op.isBlockquote()&&t.op.hasSameAdiAs(e.op)},o);function o(){}e.Grouper=i},1358:function(t,e,n){"use strict";Object.defineProperty(e,"__esModule",{value:!0});var o=n(1178),s=n(1177),i=(r.prototype.nest=function(t){var e=this,n=this.convertListBlocksToListGroups(t),i=this.groupConsecutiveListGroups(n),r=s.flatten(i.map(function(t){return Array.isArray(t)?e.nestListSection(t):t}));return s.groupConsecutiveElementsWhile(r,function(t,e){return t instanceof o.ListGroup&&e instanceof o.ListGroup&&t.items[0].item.op.isSameListAs(e.items[0].item.op)}).map(function(t){if(!Array.isArray(t))return t;var e=t.map(function(t){return t.items});return new o.ListGroup(s.flatten(e))})},r.prototype.convertListBlocksToListGroups=function(t){return s.groupConsecutiveElementsWhile(t,function(t,e){return t instanceof o.BlockGroup&&e instanceof o.BlockGroup&&t.op.isList()&&e.op.isList()&&t.op.isSameListAs(e.op)&&t.op.hasSameIndentationAs(e.op)}).map(function(t){return Array.isArray(t)?new o.ListGroup(t.map(function(t){return new o.ListItem(t)})):t instanceof o.BlockGroup&&t.op.isList()?new o.ListGroup([new o.ListItem(t)]):t})},r.prototype.groupConsecutiveListGroups=function(t){return s.groupConsecutiveElementsWhile(t,function(t,e){return t instanceof o.ListGroup&&e instanceof o.ListGroup})},r.prototype.nestListSection=function(n){var i=this,e=this.groupByIndent(n);return Object.keys(e).map(Number).sort().reverse().forEach(function(t){e[t].forEach(function(t){var e=n.indexOf(t);i.placeUnderParent(t,n.slice(0,e))&&n.splice(e,1)})}),n},r.prototype.groupByIndent=function(t){return t.reduce(function(t,e){var n=e.items[0].item.op.attributes.indent;return n&&(t[n]=t[n]||[],t[n].push(e)),t},{})},r.prototype.placeUnderParent=function(t,e){for(var n=e.length-1;0<=n;n--){var i=e[n];if(t.items[0].item.op.hasHigherIndentThan(i.items[0].item.op)){var r=i.items[i.items.length-1];return r.innerList?r.innerList.items=r.innerList.items.concat(t.items):r.innerList=t,!0}}return!1},r);function r(){}e.ListNester=i},1359:function(t,e,n){var i=n(1167),r=n(1176),l=r.OpToHtmlConverter,c=r.DeltaInsertOp;i.register("LinkElement").asCtor(function(t,s,a,u){this.getHtml=function(t){var e,n,i=t.insert.value,r=u.encodeText(i.text||"")||i.value,o=(e=t.attributes,n=i,a.extend({underline:!0},e,{link:n.value,target:n.target}));return new l(new c(r,o),s.CONFIG).getHtml()}}).dependencies("Consts, RichTextEditorDefaults, wmjQuery, CommonUtils")},1360:function(t,e,n){var i=n(1167),r=n(1176),a=r.OpToHtmlConverter,u=r.DeltaInsertOp;i.register("MentionElement").asCtor(function(t,r,o,s){this.getHtml=function(t){var e,n,i=(e=t.insert.value.id,n=o.getByName(e),s.evaluate(n.Type,n.Value));return new a(new u(i,t.attributes),r.CONFIG).getHtml()}}).dependencies("Consts, RichTextEditorDefaults, UserAttributes, EndUserDataEvaluator")},1361:function(t,e,n){n(1167).register("CustomElementsRenderer").asCtor(function(n,i,r){this.renderCustomWith=function(t,e){switch(t.insert.type){case"action":return n.getHtml(t,e);case"url":return i.getHtml(t,e);case"mention":return r.getHtml(t,e);default:return}},this.prepareCustomElements=function(t){for(var e=0;e<t.length;e++){var n=t[e];if(n.attributes&&n.attributes.link&&"string"==typeof n.insert){var i=n.attributes.link;n.insert={action:{text:n.insert,data:i}}}}}}).dependencies("ActionElement, LinkElement, MentionElement")},1362:function(t,e,n){var i=n(1167),a=n(1176).QuillDeltaToHtmlConverter;i.register("RichTextEditorConverter").asCtor(function(i,r,o,s){this.getRichTextElement=function(t){var e=document.createElement("div"),n=function(t){var e=t;r.prepareCustomElements(e);var n=new a(e,o.CONFIG);return n.afterRender(i.manipulateHtml),n.renderCustomWith(r.renderCustomWith),n.convert()}(t);return s.setInnerHTML(e,n),e}}).dependencies("AfterRenderHtmlManipulator, CustomElementsRenderer, RichTextEditorDefaults, DomManager")},1363:function(t,e,n){n(1167).register("AfterRenderHtmlManipulator").asCtor(function(u,l,i,t){var n=t.isFeatureEnabled("revertToBrowserStyle"),c={P:{margin:"0",padding:"0"},LI:{margin:"0",padding:"0"},STRONG:{"font-weight":"bold","font-style":"inherit"},EM:{"font-style":"italic","font-weight":"inherit"},OL:{"list-style-type":"decimal"},UL:{"list-style-type":"disc"},LIST:{"list-style-position":"inside"}};n&&(c.LIST["margin-block-start"]="1em",c.LIST["margin-block-end"]="1em",c.LIST["padding-inline-start"]="40px");function p(t,e,n){var i=t.tagName?t:l.parseElement(t);return e(i.tagName.toLowerCase())&&n(i),i.outerHTML}this.manipulateHtml=function(t,e){switch(n&&(e=function(t){for(var e=l.parseElement(t),n=e.getElementsByTagName("strong"),i=0;i<n.length;i++)p(n[i],function(t){return"strong"===t},function(t){u.update(t,c.STRONG,!0)});for(var r=e.getElementsByTagName("em"),o=0;o<r.length;o++)p(r[o],function(t){return"em"===t},function(t){u.update(t,c.EM,!0)});var s=e.getElementsByTagName("li");if(0<s.length)for(var a=0;a<s.length;a++)p(s[a],function(t){return"li"===t},function(t){u.update(t,c.LI,!0)});return e.outerHTML}(e)),t){case"list":return p(e,function(t){return"ol"===t||"ul"===t},function(t){var e=t.tagName.toUpperCase(),n=i.extend({},c.LIST,c[e]);u.update(t,n,!0)});case"block":case"inline-group":return p(e,function(t){return"p"===t},function(t){u.update(t,c.P,!0)});default:return e}}}).dependencies("CssAttributeSetter, DomManager, wmjQuery, FeaturesManager")}}]);