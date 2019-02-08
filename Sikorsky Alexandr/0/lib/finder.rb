require 'csv'
require 'pry'

module BelStat
  class Finder
    attr_accessor :region

    def initialize(region, work_directory)
      @region = region
      @work_directory = work_directory
      @actual_file = grub_actual_file
      @actual_file_path = "./#{@work_directory}/#{@actual_file}"
      @curr_date = file_path2date @actual_file
    end

    def find_price(file_path, query)
      pattern = /(.*)#{query}(\s|\z)+(.*)/i
      CSV.open(file_path, headers: true) do |products|
        products.each do |product|
          return product[@region].to_f if pattern.match?(product[0])
        end
      end
      nil
    end

    def find_similar(from, to, file_path = @actual_file_path)
      similar_list = []
      CSV.open(file_path, headers: true) do |products|
        products.each do |product|
          price = product[@region].to_f
          next if price.zero?

          similar_list << product[0] if price >= from && price <= to
        end
      end
      similar_list
    end

    def find_stat(query)
      stat = { min: 0, max: 0, curr: nil, min_date: '', max_date: '' }
      Dir["./#{@work_directory}/*"].each do |path|
        price = find_price(path, query)
        next if price.nil? || price.zero?

        date = file_path2date path
        stat[:curr] = price if date == @curr_date
        min_max_hash = return_min_max price, date, stat
        stat.merge!(min_max_hash)
      end
      stat
    end

    private

    def file_path2date(path)
      path.split('/')[-1].split('.c')[0]
    end

    def grub_actual_file
      date = { month: Time.now.month, year: Time.now.year }

      0.upto(Dir["./#{@work_directory}/*"].length) do
        curr_file = date2file_name(date)
        return curr_file if File.file? "./#{@work_directory}/#{curr_file}"

        to_next_month date
      end
    end

    def to_next_month(date)
      date[:month] -= 1
      if date[:month].zero?
        date[:month] = 12
        date[:year] -= 1
      end
      date
    end

    def date2file_name(date)
      "#{date[:month]}.#{date[:year]}.csv"
    end

    def return_min_max(price, date, stat)
      price /= 10_000 if price > 1000

      (return { max: price, max_date: date }) if price > stat[:max]

      (return {}) unless stat[:min].zero? || price < stat[:min]

      { min: price, min_date: date }
    end
  end
end
