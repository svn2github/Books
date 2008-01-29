#!/usr/bin/ruby

require "rexml/document"

mapping = { 	'aspect' => 'format', 
				'author' => 'authors', 
				'fullTitle' => 'title', 
				'Genre' => 'genre', 
				'pages' => 'length', 
				'published' => 'publishDate', 
				'asin' => 'isbn' }

filepath = ARGV[0]

listxml = REXML::Document.new(File.new(filepath))

outputxml = REXML::Document.new

import = outputxml.add_element("importedData")
collection = import.add_element("List")
collection.attributes["name"] = filepath

bookcount = 0

listxml.elements().each("/library/items/book") do |book_element|

	book = collection.add_element("Book")
	copy = book.add_element("copy")

	book_element.attributes().each_attribute() do |attribute|
		name = attribute.expanded_name
		value = attribute.value
	
		newname = mapping[name]
			
		if (newname == nil)
			newname = name
		end

		if (newname == "location")
			copy.attributes["location"] = value
		elsif (newname == "currentValue")
			copy.attributes["presentValue"] = value
		elsif (newname == "purchaseDate")
			copy.attributes["dateAcquired"] = value
		else
			field = book.add_element("field")
		
			if (newname != "summary")
				value = value.tr_s("\n", ", ")

				if (newname == "uuid")
					cover = book.add_element("field")
				
					cover.attributes["name"] = "coverImage"
				
					cover.add_text(filepath.sub("Library Media Data.xml", "Images/Large Covers/") + value);
				end
			end
	
			field.attributes["name"] = newname
			field.add_text(value)
		end
					
	end
end

outputxml.write($stdout,0,false,false)