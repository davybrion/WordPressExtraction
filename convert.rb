require "rexml/document"
require "json"
require "fileutils"

def get_element_value(parent_element, element_name)
	parent_element.get_elements(element_name)[0].text
end

def create_post_metadata(post_element)
	post = Hash.new
	post['title'] = get_element_value post_element, "title"
	post['link'] = get_element_value post_element, "link"
	post['date'] = get_element_value post_element, "wp:post_date"

	dsq_meta_element = post_element.get_elements("wp:postmeta[wp:meta_key='dsq_thread_id']")[0]
	if !dsq_meta_element.nil?
		post['disqus_thread_id'] = dsq_meta_element.get_elements("wp:meta_value")[0].text
	else
		post['disqus_thread_id'] = ""
	end

	categories = []
	post_element.elements.each("category") do |category_element|
		categories << category_element.attributes.get_attribute("nicename").value()
	end 
	post['categories'] = categories

	post
end

def write_post_to_file(post_element, path)
	File.open(path, "w") do |file|
		file << get_element_value(post_element, "content:encoded")
	end
end

if ARGV.length == 0
	puts "you need to supply the path to the exported wordpress xml file!"
	exit
end

wp_data_path = ARGV[0]

wp_data_file = File.new wp_data_path
xml = REXML::Document.new wp_data_file

posts = []

FileUtils.rm_r "output" if File.exists?("output")
Dir.mkdir("output")

xml.elements.each("rss/channel/item") do |post_element|
	posts << create_post_metadata(post_element)
	filename = posts[-1]['link'].chop.gsub("http://davybrion.com/blog/", "").gsub("/", "-")
	write_post_to_file post_element, "output/#{filename}.md"
end

File.open("output/all_metadata.json", "w") do |file|
	file << JSON.pretty_generate(posts)
end
