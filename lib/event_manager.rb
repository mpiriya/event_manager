require "csv"
require "google/apis/civicinfo_v2"
require "erb"
require "date"

puts "EventManager Initialized!"

# lines = File.readlines "event_attendees.csv"
# lines.each_with_index do |line, index|
#   next if index == 0
#   columns = line.split(",")
#   name = columns[2]
#   puts name
# end

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, "0")[0..4]
end

def legislator_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'
  begin
    civic_info.representative_info_by_address(
                address: zip,
                levels: "country",
                roles: ["legislatorUpperBody", "legislatorLowerBody"]).officials
  rescue
    "You can find your representative by visiting www.commoncause.org/take-action/find-elected-officials"
  end
end

def save_thank_you_letter(id, form_letter) 
  Dir.mkdir("output") unless Dir.exists?("output")

  filename = "output/thanks_#{id}.html"
  File.open(filename, "w") do |file|
    file.puts form_letter
  end
end

def validate_phone(phone)
  phone = (phone.split("").filter {|char| char.match(/\d/) }).join

  if phone.length < 10 || phone.length > 11 || (phone.length == 11 && phone[0] != "1")
    "Invalid phone number"
  else
    if phone.length == 11
      phone = phone[1, 11]
    end
    phone
end

template_letter = File.read "form_letter.erb"
erb_template = ERB.new template_letter
sum_hour = 0
sum_day = 0
count = 0

contents = CSV.open "event_attendees.csv", headers: true, header_converters: :symbol
contents.each do |row|
  id = row[0]

  name = row[:first_name]

  zipcode = clean_zipcode(row[:zipcode])

  legislators = legislator_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)

  phone = validate_phone(row[:homephone])
  
  time = DateTime.strptime(row[:regdate], "%D %H:%M")
  sum_hour += time.strftime("%H").to_i
  sum_day += time.strftime("%D").wday
  count += 1
end

avg_hour = sum_hour / count.to_f
avg_day = sum_day / count.to_f
days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

puts "Average hour of event registration is #{avg_hour}"
puts "Average day of event registration is #{days[avg_day]}"