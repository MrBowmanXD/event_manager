require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def legislators_by_zipcode(zip)
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

def homephone_method(row)
  homephone_array = row[:homephone].split("")
  homephone_numbers = homephone_array.reject do |char|
    char == '-' || char == '(' || char == ')' || char == '.' || char == ' '
  end
  homephone_string = homephone_numbers.join("")
  if homephone_string.length < 10 || homephone_string.length > 11
    puts "Bad number"
    puts homephone_string
  elsif homephone_string.length == 10
    puts "Good number"
    puts homephone_string
  elsif homephone_string.length == 11 && homephone_string[0] == 1
    homephone_string = homephone_string.delete_prefix("1")
    puts "Now it's a good number"
    puts homephone_string
  end 
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

prior_twelve = 0
after_twelve = 0

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  #save_thank_you_letter(id,form_letter) to uncomment in a later phase
  # homephone_method(row) solution to first assignment
  date = row[:regdate]
  data = date.split(" ")
  hour = data[1].to_i

  if hour < 12
    prior_twelve += 1
  elsif hour > 12
    after_twelve += 1
  end
end

if prior_twelve > after_twelve
  puts "A good hour to send invite is between 0 and 12"
elsif after_twelve > prior_twelve
  puts "A good hour to send invite is between 12 and 24"
end