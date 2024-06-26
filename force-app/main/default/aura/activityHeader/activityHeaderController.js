({
   doInit : function(component, event, helper) {
      var iconName = component.get("v.iconName");
      if (iconName == null) {
         var sourceObjectName = component.get("v.sourceObjectName");
          if (sourceObjectName == 'Task') {
              component.set("v.iconName","action:new_task");
          } else if (sourceObjectName == 'Event') {
              component.set("v.iconName","action:new_event");
          }
      }
   },

})