require 'yql'
require 'json'
require 'date'

  # WHEN [AAPL] INCREASES BY .01 IN 1 DAY
  # WHEN [GOOG] INCREASES BY .05 IN 1 WEEK FOR 7 WEEKS
  # =>
  # when ticker change by increment in duration for length

class Parser
  def initialize
  end

  def self.get_prices(ticker, duration_examined)
    yql = Yql::Client.new
    yql.format = "json"
    daily_data = [] #daily prices IPO - now
    res = [0] #temp holder for year's prices
    endDate = DateTime.now
    query = Yql::QueryBuilder.new 'yahoo.finance.historicaldata'
    query.select = 'date, Open, High, Low, Volume, Adj_close'
    yql.query = query
    
    duration_examined.times do
      break if res.length == 0
      startDate = endDate - 1.year
      query.conditions = { 
        :symbol => ticker, 
        :startDate => "#{startDate.year}-#{startDate.month}-#{startDate.day}", 
        :endDate => "#{endDate.year}-#{endDate.month}-#{endDate.day}" 
      }
      res = JSON.parse(yql.get.show)["query"]["results"]["quote"]
      daily_data += res
      endDate = endDate - 1.year
    end
    daily_data.reverse
  end

  def self.find_ranges(ticker, change, duration, duration_examined, length = 0)
    days = [] #days that trigger entry signal
    daily_data = get_prices(ticker, duration_examined)
    decrease = change < 0 ? true : false
    
    daily_data.each_with_index do |day_data, idx|
      start = day_data
      end_d = daily_data[idx + duration - 1]
      break unless end_d
      max_incr = (end_d["High"].to_f - start["Low"].to_f) / end_d["High"].to_f
      max_decr = (end_d["Low"].to_f - start["High"].to_f) / end_d["Low"].to_f

      if decrease && max_decr <= change ||
        !decrease && max_incr >= change
        days << end_d
      end
    end

    if length != 0
      (days.length - 1).times do |idx1|
        start = days[idx1]["date"]
        start_date = DateTime.new(*start.split("-").map(&:to_i))
        length.times do |idx2|
          end_d = days[idx1 + 1 + idx2]["date"]

          end_date = DateTime.new(*end_d.split("-").map(&:to_i))

    end

    days
  end

  # (queries array, callback dates array, max open trades)
  # p = Parser.new()
  # puts p.find_ranges("GOOG", 0.01, 10, 180)
end