(function($){
   'use strict';
   var ndfDateID = 'sb-ndf-date';
   var ndfDateRegEx = new RegExp('^' + ndfDateID);
   var ndfDate = {unique_id:ndfDateID,text:{headline:'No Data Found'},start_date:{ year: new Date().getFullYear()}} ;
   var timeline$;
   var ndf$;
   var timeline;
   var isEmpty = false;
   var o;

   $.widget("sb.timeline", {
      options: {
         timelineID: null,
         ndfID: null,
         timenav_position: null,
         language : 'en',
         layout: 'landscape',
         width: null,
         height: null,
         ajaxIdentifier: null,
         pageItems:null
      },
      _create: function() {
         var that = this;
         o = that.options;
         timeline$ = $('#'+o.timelineID);
         ndf$ = $('#'+o.ndfID);

         this._getData().done(function(tlData){
            if(tlData.events.length === 0){
               isEmpty = true;
               tlData.events.push(ndfDate);
            }else{
               isEmpty = false;
            }
            timeline = new TL.Timeline(o.timelineID,tlData, {
               timenav_position : o.timenav_position,
               language: o.language,
               layout: o.layout,
               width: o.width,
               height: o.height
            });

            if(isEmpty){
               that._noDataFound();
            }
         });

         this.element.on('apexrefresh', function( event ){
            that._refresh();
         });
      },
      _getData: function(){
         return apex.server.plugin(
            this.options.ajaxIdentifier,
            {
               x10: "DATA",
               pageItems: this.options.pageItems
            }
         );
      },
      _refresh : function(){
         var that = this;
         var curEvent;
         var ndfEvents = [];
         this._getData().done(function(tlData){
            if(tlData && tlData.hasOwnProperty('events')){
               if(tlData.events.length === 0){
                  that._noDataFound();
                  return;
               }
               isEmpty = false;

               // the timeline breaks if it doesnt have an event
               // we add a temporary event so that all events can be deleted
               //then we remove the temporary event at the end
               timeline.add($.extend(true,{},ndfDate));
               for (var i = timeline.config.events.length - 1; i >= 0; i--) {
                  curEvent = timeline.config.events[i];
                  if(!ndfDateRegEx.test(curEvent.unique_id)){
                     timeline.removeId(curEvent.unique_id);
                  }else{
                     ndfEvents.push(curEvent);
                  }
               };

               for(var i = 0; i < tlData.events.length; i++){
                 timeline.add(tlData.events[i]);
               }
               while(ndfEvents.length > 0){
                 timeline.removeId(ndfEvents.pop().unique_id);
               }
               that._updateDisplay();
            }
         });
      },
      _noDataFound : function(){
         isEmpty = true;
         this._updateDisplay();
      },
      _updateDisplay : function(){
         if(isEmpty){
            timeline$.hide();
            ndf$.show();
         }else{
            timeline$.show();
            ndf$.hide();
         }
      }
   });
})(apex.jQuery);