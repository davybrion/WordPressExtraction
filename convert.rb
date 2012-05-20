require "rexml/document"
require "json"

def get_element_value(parent_element, element_name)
	parent_element.get_elements(element_name)[0].text
end

def create_post_metadata(post_element)
	post = Hash.new
	post['title'] = get_element_value post_element, "title"
	post['link'] = get_element_value post_element, "link"
	post['date'] = get_element_value post_element, "wp:post_date"

	categories = []

	post_element.elements.each("category") do |category_element|
		categories << category_element.attributes.get_attribute("nicename").value()
	end 

	post['categories'] = categories

	post
end

if ARGV.length == 0
	puts "you need to supply the path to the exported wordpress xml file!"
	exit
end

wp_data_path = ARGV[0]

wp_data_file = File.new wp_data_path
xml = REXML::Document.new wp_data_file

posts = []

xml.elements.each("rss/channel/item") do |post_element|
	posts << create_post_metadata(post_element)
end

puts JSON.pretty_generate(posts)
