({
	init : function (component) {
        console.log('in knowledge controller');
        component.set('v.columns', [
            {label: 'Title', fieldName: 'Title', type: 'text'}
        ]);
        return new Promise(function(resolve, reject) {
            console.log('in promise');
            //debugger;
            let getAllArticles = component.get('c.getAllKnowledgeArticles');
            
            //getAllArticles.setParams({conId: cmp.get('v.recordId')});
            getAllArticles.setCallback(this, function(res) {
                if (res.getState() != 'SUCCESS' || !res.getReturnValue()) {
                    console.log(res.getError())
                    let t = 'Record retrieval err';
                    let m = 'Failed to retrieve knowledge articles. Please contact your sales rep for support.';
                    let ty = 'error';                  
                    reject({
                        t: t,
                        m: m,
                        ty: ty
                    });
                }
                let allArticles = res.getReturnValue()
                var articleMap = new Map();
                console.log('all articles'+allArticles);
                
                allArticles.forEach(element => articleMap.set(element.Title,element));
                console.log('articleMap'+articleMap);
                
                component.set('v.knowledgeArticles', allArticles);
                component.set('v.knowledgeArticleMap', articleMap);
                component.set('v.showList', true);
                resolve(true);
            });
            $A.enqueueAction(getAllArticles);
        });
    },
    getChild : function(component,event){
        var value = event.currentTarget.dataset.id;
        console.log('value:'+value);
        var articleMap = component.get('v.knowledgeArticleMap');
        var article = articleMap.get(value);
        console.log('get article'+article.ArticleNumber);
        component.set('v.selectedArticle', article);
        component.set('v.showList', false);
    },
    goToArticle : function (component,event) {
        var target = event.getSource();
        var value = target.get("v.value")
        console.log('value:'+value);
        var articleMap = component.get('v.knowledgeArticleMap');
        var article = articleMap.get(value);
        console.log('get article'+article.ArticleNumber);
        component.set('v.selectedArticle', article);
        component.set('v.showList', false);
    },
    goToList : function (component) {
        component.set('v.showList', true);
        component.set('v.selectedArticle', null);
    }
})