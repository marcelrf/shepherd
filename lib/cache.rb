class Cache
  @@TIME_FORMAT = '%Y-%m-%dT%H:%M:%SZ%z'
  @@MAX_VALUES = 100

  def self.get_source_data(metric, period)
    end_time = get_cropped_time(Time.now.utc, period)
    cache_key = get_cache_key(metric, period)
    cache_data_json = $redis.get(cache_key)
    if cache_data_json
      cache_data = JSON.load(cache_data_json)
      start_time = Time.parse(cache_data['last_measured'], @@TIME_FORMAT).utc
      new_data = SourceData.get_source_data(metric, period, start_time, end_time)
      source_data = (cache_data['values'] + new_data)[-@@MAX_VALUES..-1]
    else
      start_time = end_time - @@MAX_VALUES.send(period)
      source_data = SourceData.get_source_data(metric, period, start_time, end_time)
    end
    cache_data_json = JSON.dump({
        'last_measured' => end_time,
        'values' => source_data
    })
    $redis.set(cache_key, cache_data_json)
    source_data
  end

  def self.get_cache_key(metric, period)
    JSON.dump({
      'namespace' => 'source_data',
      'metric' => metric.id,
      'period' => period
    })
  end

  def self.get_cropped_time(time, period)
    if period == 'hour'
      Time.new(time.year, time.month, time.day, time.hour, 0, 0, 0).utc
    elsif period == 'day'
      Time.new(time.year, time.month, time.day, 0, 0, 0, 0).utc
    end
  end
end
