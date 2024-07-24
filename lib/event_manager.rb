puts 'Event Manager Initialized!'

# check if file exist
puts File.exist? "../event_attendees.csv"

# simple example of getting raw data from a file
def content_example1
 contents = File.read('../event_attendees.csv',)
 puts contents
end

# get specific information i.e. "name" of attendees from a file without using CSV library
def name_example1
  lines = File.readlines('../event_attendees.csv',)
  lines.each_with_index do |line, index|
    next if index == 0 # don't read the header row

    # alternative way to avoid header row
    # next if line == " ,RegDate,first_Name,last_Name,Email_Address,HomePhone,Street,City,State,Zipcode\n" # skips header row
    # puts lines
    columns = line.split(",")
    # p columns
    name = columns[2]
    puts name
  end
end

# calling CSV library and google api
require 'csv'
require 'google/apis/civicinfo_v2'

civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new

# to hide key safely, you can save the key to a plain text file (don’t commit it!)
# and then create a .gitignore file in the root directory of your project.
# Add the name of the file to your .gitignore.
# Then commit the .gitignore file to your repo.
# Git will no longer track the file that you saved the key to, and you can now import the key like so
# civic_info.key = File.read('secret.key').strip
# where secret.key is the name of the file that we saved our key to and which we added to our .gitignore.

# instead of exposing the key like so
civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

# using csv lib without google api to get name of attendee
def csv_example1
  contents = CSV.open('../event_attendees.csv',, headers: true)
  contents.each do |row|
    name = row[2]
    puts name
  end
end

# sub_function
def clean_zipcode(zipcode)
  # if the zip code is exactly five digits, assume that it is ok
  # if the zip code is more than five digits, truncate it to the first five digits
  # if the zip code is less than five digits, add zeros to the front until it becomes five digits
  # if zipcode.nil?
  #   zipcode = '00000'
  # elsif zipcode.length < 5
  #   zipcode = zipcode.rjust(5, '0')
  # elsif zipcode.length > 5
  #   zipcode = zipcode[0..4]
  # end
  zipcode.to_s.rjust(5, '0')[0..4]
end

# using csv lib without google api to get name of attendee, converts header rows into symbols
def csv_version2 
  contents = CSV.open(
    '../event_attendees.csv',,
    headers: true,
    header_converters: :symbol
  )

  contents.each do |row|
    name = row[:first_name]
    zipcode = clean_zipcode(row[:zipcode])
    puts "#{name} #{zipcode}"
  end
end

# using csv lib to get name of attendee, and then WITH google api to get officials of their areas
def google_version1
  contents = CSV.open(
    '../event_attendees.csv',,
    headers: true,
    header_converters: :symbol
  )

  contents.each do |row|
    name = row[:first_name]

    zipcode = clean_zipcode(row[:zipcode])

    legislators = civic_info.representative_info_by_address(
      address: zipcode,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    )
    legislators = legislators.officials

    puts "#{name} #{zipcode} #{legislators}"
  end
end

# using csv lib to get name of attendee, and then WITH google api to get officials of their areas
# and handle exceptions
# e.g. zip code of attendee is empty and cannot be used to retrieve the official of the area
def google_version2
  contents = CSV.open(
  '../event_attendees.csv',,
  headers: true,
  header_converters: :symbol
)

  contents.each do |row|
    name = row[:first_name]

    zipcode = clean_zipcode(row[:zipcode])

    begin
      legislators = civic_info.representative_info_by_address(
        address: zipcode,
        levels: 'country',
        roles: ['legislatorUpperBody', 'legislatorLowerBody']
      )
      legislators = legislators.officials
    rescue
      'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
    end

    puts "#{name} #{zipcode} #{legislators}"
  end
end

# To capture the first and last name of the official instead of the full raw data
def google_version3
  contents.each do |row|
    name = row[:first_name]

    zipcode = clean_zipcode(row[:zipcode])

    begin
      legislators = civic_info.representative_info_by_address(
        address: zipcode,
        levels: 'country',
        roles: ['legislatorUpperBody', 'legislatorLowerBody']
      )
      legislators = legislators.officials

      legislator_names = legislators.map(&:name)
      # alternatively:
      # legislator_names = legislators.map do |legislator|
      #   legislator.name
      #   end

      legislators_string = legislator_names.join(", ")
    rescue
      'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
    end

    puts "#{name} #{zipcode} #{legislators_string}"
  end
end

# pull out as sub function
def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    legislators = civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    )
    legislators = legislators.officials
    legislator_names = legislators.map(&:name)
    legislator_names.join(", ")
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

# improve brevity of code by pulling out into a legislator function to determine who is the legislator
def google_version4
  contents = CSV.open(
    '../event_attendees.csv',,
    headers: true,
    header_converters: :symbol
  )

  contents.each do |row|
    name = row[:first_name]
    zipcode = clean_zipcode(row[:zipcode])
    legislators = legislators_by_zipcode(zipcode)
    puts "#{name} #{zipcode} #{legislators}"
  end
end

# read the template letter to send invite to attendees
# It is important to define the form_letter.html file in the root of project directory and not in the lib directory.
# This is because when the application runs it assumes the place that you started the application is where all
# file references will be located.
template_letter = File.read('form_letter.html')

# to create template letter invite v1
def letter_v1
  contents = CSV.open(
    '../event_attendees.csv',,
    headers: true,
    header_converters: :symbol
  )

  contents.each do |row|
    name = row[:first_name]
    zipcode = clean_zipcode(row[:zipcode])
    legislators = legislators_by_zipcode(zipcode)

    personal_letter = template_letter.gsub('FIRST_NAME', name)
    personal_letter.gsub!('LEGISLATORS', legislators)

    #alternative 
    # personal_letter = template_letter.gsub('FIRST_NAME', name)
    # personal_letter = personal_letter.gsub('LEGISLATORS', legislators)

    puts personal_letter
  end
end

# to create template letter invite v2
# Using FIRST_NAME and LEGISLATORS to find and replace might cause us problems if later somehow this text appears 
# in any of our templates.
# Though not likely, imagine if a person’s name contained the word ‘LEGISLATORS’.
# also, We cannot represent multiple items very easily if they are surrounded by HTML.
# Currently we copied our legislators string into a single table column. 
# We would have a hard time inserting our legislators as individual rows in the table without having to build 
# parts of the HTML table ourself. This could spell disaster later if we decide to change the template to no longer 
# use a table.
# Ruby defines a template language named ERB.
# ERB provides an easy to use but powerful templating system for Ruby. Using ERB, actual Ruby code can be added 
# to any plain text document for the purposes of generating document information details and/or flow control.
# ERB defines several different escape sequence tags that we can use. The most common are:
# <%= ruby code will execute and show output %>
# <% ruby code will execute but not show output %>
# To use ERB we need to update our current template to form_letter.erb

require 'erb'

def legislators_by_zipcode2(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def letter_v2
  contents = CSV.open(
  '../event_attendees.csv',,
  headers: true,
  header_converters: :symbol
  )
  # Creating our template from our new template file requires us to load the file contents as a string 
  # and provide them as a parameter when creating the new ERB template.
  template_letter = File.read('form_letter.erb')
  erb_template = ERB.new template_letter

  contents.each do |row|
    name = row[:first_name]

    zipcode = clean_zipcode(row[:zipcode])

    # Simplify our legislators_by_zipcode to return the original array of legislators
    legislators = legislators_by_zipcode2(zipcode)

    form_letter = erb_template.result(binding)
    puts form_letter
  end
end

# for the sake of writing clean and clear code, move the operation of saving the form letter to its own method:
def save_thank_you_letter(id,form_letter)
  # We make a directory named output if a directory named output does not already exist.
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  # The w states we want to open the file for writing. If the file already exists it will be destroyed
  File.open(filename, 'w') do |file|
    file.puts form_letter
  end 
end

# save each form letter to a file.
def letter_v3
  contents = CSV.open(
  '../event_attendees.csv',,
  headers: true,
  header_converters: :symbol
  )
  
  template_letter = File.read('form_letter.erb')
  erb_template = ERB.new template_letter

  contents.each do |row|
    #The first column does not have a name like the other columns, so we fall back to using the index value.
    id = row[0]
    name = row[:first_name]

    zipcode = clean_zipcode(row[:zipcode])

    legislators = legislators_by_zipcode2(zipcode)

    form_letter = erb_template.result(binding)
    save_thank_you_letter(id,form_letter)
  end
end
