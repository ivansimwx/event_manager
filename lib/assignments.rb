puts 'Assignment Initialized!'

puts File.exist? '../event_attendees.csv'

require 'csv'
require 'google/apis/civicinfo_v2'

civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

# Assignment 1: Phone numbers
# Similar to the zip codes, the phone numbers suffer from multiple formats and inconsistencies.
# If we wanted to allow individuals to sign up for mobile alerts with the phone numbers, we would need to
# make sure all of the numbers are valid and well-formed.
# If the phone number is less than 10 digits, assume that it is a bad number
# If the phone number is 10 digits, assume that it is good
# If the phone number is 11 digits and the first number is 1, trim the 1 and use the remaining 10 digits
# If the phone number is 11 digits and the first number is not 1, then it is a bad number
# If the phone number is more than 11 digits, assume that it is a bad number
def clean_phone_num(homephone)
  homephone = homephone.to_s.gsub(/[[:punct:]\s]/, '')
  if homephone.length == 10
    homephone
  elsif homephone.length == 11 && homephone[0] == '1'
    homephone[1..11]
  else
    'invalid number'
  end
end

# Assignment 2: Time targetting
# Using the registration date and time we want to find out what the peak registration hours are.

def clean_time(reg_date)
  reg_date = reg_date.to_s.split(/[:\/\s]/)
  reg_time = Time.new(reg_date[2], reg_date[0], reg_date[1], reg_date[3], reg_date[4])
end

def best_hour(count_hour)
  count_hour.each_with_index do |count, hour_index|
    puts "The best hour is #{hour_index}:00 with #{count} signups." if count_hour.max == count
  end
end

def clean_date(reg_date)
  reg_date = reg_date.to_s.split(/[:\/\s]/)
  reg_day = Date.new(reg_date[2].to_i, reg_date[0].to_i, reg_date[1].to_i)
end

def best_day(count_day)
  count_day.each_with_index do |count, day_index|
    if count_day.max == count
      print "\nThe best day is"
      case day_index
      when 0
        print " Sunday"
      when 1
        print " Monday"
      when 2
        print " Tuesday"
      when 3
        print " Wednesday"
      when 4
        print " Thursday"
      when 5
        print " Friday"
      when 6
        print " Saturday"
      end
      print " with #{count} signups.\n"
    end
  end
end

contents = CSV.open(
  '../event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

count_hour = Array.new(24, 0)
count_day = Array.new(7, 0)

contents.each do |row|
  # Assignment 1
  # homephone = clean_phone_num(row[:homephone])
  # puts homephone

  # Assignment 2
  # reg_hour = clean_time(row[:regdate]).hour
  # count_hour[reg_hour] += 1

  # Assignment 3
  # day = clean_date(row[:regdate]).wday
  # count_day[day] += 1
end

# Assignment 2
# best_hour(count_hour)

# Assignment 3
# best_day(count_day)
