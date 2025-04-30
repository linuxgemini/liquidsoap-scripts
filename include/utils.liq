#!/usr/bin/liquidsoap

def get_current_time_as_utc_tz_string() =
  t     = time.utc()
  year  = string.of_int(digits=4, t.year)
  month = string.of_int(digits=2, t.month)
  day   = string.of_int(digits=2, t.day)
  hour  = string.of_int(digits=2, t.hour)
  min   = string.of_int(digits=2, t.min)
  sec   = string.of_int(digits=2, t.sec)

  "#{year}-#{month}-#{day}T#{hour}:#{min}:#{sec}Z"
end
