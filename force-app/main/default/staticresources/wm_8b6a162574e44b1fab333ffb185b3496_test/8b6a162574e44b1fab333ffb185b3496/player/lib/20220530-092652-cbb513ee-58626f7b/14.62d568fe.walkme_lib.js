window,(window._walkmeWebpackJP=window._walkmeWebpackJP||[]).push([[14],{1149:function(t,f,a){"use strict";a.r(f),function(n){a.d(f,"Aggregator",function(){return o});var t=a(0),i=a(8),c=a(1341),e=a(49),r=a(264),u=a(1861),o=(s.prototype.add=function(t,n){var i=this;this.t.push(t),n.forEach(function(t){return i.i.add(t)})},s.prototype.u=function(t){void 0===t&&(t=!1);var n=Object(e.a)();c.a.get("PerformanceDataSender").send(Object(u.a)(n-this.o,this.t),t),this.h(n)},s.prototype.h=function(t){this.o=t,this.i=new n,this.t=[]},Object(t.__decorate)([Object(i.c)("Aggregator",{ctx:c.a,dependencies:"Config,TimerManager,WindowBeforeUnloadHandler"})],s));function s(t,n){var i=this;this.h(Object(e.a)()),n.playSetInterval(function(){return i.u()},t.interval||1e4),Object(r.register)(function(){return i.u(!0)})}}.call(this,a(37).wmSet)},1150:function(t,s,f){"use strict";f.r(s),function(t){f.d(s,"AsapDataCollector",function(){return u});var n=f(0),i=f(49),c=f(1586),e=f(8),r=f(1341),u=(o.prototype.collect=function(t){var n=this;this.j.add(t),this.O||(this.O=Object(i.a)(),Object(c.a)(function(){return n.v()}))},o.prototype.v=function(){var t=Object(i.a)()-this.O;17<t&&this.g.add(t,this.j),this.h()},o.prototype.h=function(){this.j=new t,this.O=null},Object(n.__decorate)([Object(e.c)("Collector",{ctx:r.a,dependencies:"Aggregator"})],o));function o(t){this.g=t,this.h()}}.call(this,f(37).wmSet)},1151:function(t,u,o){"use strict";o.r(u),function(n){o.d(u,"init",function(){return t});var i=o(1341),c=o(54),e=o(139),r=o(121);function t(){i.a.register("Config").asInstance(Object(c.getExperiment)(c.Experiments.DataCollector).config||{});var t=i.a.get("Collector");n.get("Instrumenter").getStream().pipe(Object(e.a)(function(t){return t.__stage==r.a.Start})).subscribe(function(){return t.collect()})}}.call(this,o(2))},1341:function(t,n,i){"use strict";i.d(n,"a",function(){return c});var n=i(11),c=Object(n.create)()},1586:function(t,i,c){"use strict";!function(n){function t(t){n.resolve().then(t)}c.d(i,"a",function(){return t})}.call(this,c(12))},1861:function(t,n,i){"use strict";var r,u=i(0),o=((r={})[r.score=1]="score",i(24));function c(t,n){t=Math.round(t);var i=Math.round(Object(o.reduce)(n,function(t,n){return t+n},0)),c=Math.round(Object(o.reduce)(n,function(t,n){return t+n*n},0)),e=Math.round(Math.max.apply(Math,Object(u.__spreadArrays)(n,[0])));return{type:r.score,amount:e,sum:i,total:c,count:n.length,duration:t}}i.d(n,"a",function(){return c})}}]);