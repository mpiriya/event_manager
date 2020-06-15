require "csv"
require "google/apis/civicinfo_v2"

template_letter = File.read("form_letter.html")

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
    legislators = civic_info.representative_info_by_address(
                              address: zip,
                              levels: "country",
                              roles: ["legislatorUpperBody", "legislatorLowerBody"])
    legislators = legislators.officials
    legislator_names = legislators.map(&:name)
    legislator_names.join(", ")
  rescue
    "You can find your representative by visiting www.commoncause.org/take-action/find-elected-officials"
  end
end


contents = CSV.open "event_attendees.csv", headers: true, header_converters: :symbol
contents.each do |row|
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislator_by_zipcode(zipcode)

  personal_letter = template_letter.gsub("FIRST_NAME", name)
  personal_letter.gsub!("LEGISLATORS", legislators)
  puts personal_letter
end