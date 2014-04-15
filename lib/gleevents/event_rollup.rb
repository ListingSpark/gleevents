class EventRollup
  include Mongoid::Document

  def self.process_entries(start_time, end_time)
    map = <<-MAP
      function() {
        var created_at_date = new Date(Date.parse(this.created_at));
        var year = created_at_date.getFullYear().toString();
        var month = (created_at_date.getMonth()+1).toString();
        var day = created_at_date.getDate().toString();
        if(month.length == 1) {
          month = '0' + month;
        }
        if(day.length == 1) {
          day = '0' + day;
        }
        var date_key = year + month + day;

        key = {
          action: this.action,
          date: date_key
        };
        value = {
          triggered: 1
        };
        for(var p in this.properties) {
          var val = this.properties[p];
          var isnum = !isNaN(parseFloat(val)) && isFinite(val);
          if (isnum){ value[p] = val; }
        }

        emit(key, value);
      }
    MAP

    reduce = <<-REDUCE
      function(key, values){
        result = {
          triggered: 0
        };
        for(var i in values){
          for(var prop in values[i]) {
            if(result[prop] == undefined) { result[prop] = 0 }
            result[prop] += values[i][prop];
          }
        }
        return result;
      }
    REDUCE

    query = {:created_at => {'$gte' => start_time.utc, '$lt' => end_time.utc}}
    mr = Event.where(query).map_reduce(map, reduce).out(:merge => 'event_rollups' )
    # important - do not remove this line, it causes the map_reduce to actually evaluate, since it is lazy
    Rails.logger.info "**** Map/Reduced to #{mr.count} New Rollups"
    true
  end
end
