require 'uri'
require 'net/http'
require 'rexml/document'
require 'facets/random'
require 'shorturl'
require 'htmlentities'

# Controller for the WebSearcher leaf.

class Controller < Autumn::Leaf
  
  def will_start_up # :nodoc:
    @coder = HTMLEntities.new
  end
  
  # Typing "!about" displays some basic information about this leaf.
  
  def about_command(stem, sender, reply_to, msg)
    # This method renders the file "about.txt.erb"
  end

  # Typing "!google" does an I'm-feeling-lucky Google search.

  def google_command(stem, sender, reply_to, msg)
    if msg.nil? then
      render :google_help
      return
    end

   search_url = URI.parse("http://www.google.com/search?hl=en&q=#{URI.escape msg}&btnI=I%27m+Feeling+Lucky") 
   response = Net::HTTP.get_response(search_url)
   result_url = response.header['Location']
   var :url => result_url
   if result_url then
     response = Net::HTTP.get_response(URI.parse(result_url))
     title_array = response.body.scan(/<title>(.+?)<\/title>/).flatten
     if not title_array.empty? then
       var :title => @coder.decode(title_array.first)
       if result_url.size > 30 then
         var :url => (ShortURL.shorten(result_url, :lns) rescue result_url)
       else
         var :url => result_url
       end
     end
   end
  end
  alias_command :google, :g

  # Typing "!image" links the first result of a Google image search. Use with
  # care.
  
  def image_command(stem, sender, reply_to, msg)
    if msg.nil? then
      render :image_help
      return
    end

    search_url = URI.parse("http://images.google.com/images?hl=en&q=#{URI.escape msg}&btnG=Search+Images&gbv=2")
    response = Net::HTTP.get_response(search_url)
    urls = response.body.scan(/dyn\.Img\(".*?",".*?",".*?","(.+?)","\d*","\d*",".*?",".*?",".*?",".*?",".*?",".*?",".*?",".*?",".*?",".*?",\[.*?\]\)/).flatten
   if urls.empty? then return "No images found."
   else return urls.first end
  end
  alias_command :image, :i
  
  # Typing "!news" returns a random news story from the top five news stories.
  # You can optionally provide a topic.

  def news_command(stem, sender, reply_to, msg)
    url = "http://news.google.com/news?hl=en&ie=UTF-8&output=atom"
    url << "&q=#{URI.escape msg}" if msg
    xml = Net::HTTP.get(URI.parse(url))
    doc = REXML::Document.new(xml)

    stories = doc.root.children.select { |child| child.respond_to?(:name) and child.name == 'entry' }
    stories.slice! 0, 5
    story = stories.at_rand
    return "No news stories found." unless story
    var :title => @coder.decode(story.elements['title'].text)
    result_url = story.elements['link'].attributes['href']
    if result_url.size > 30 then
      var :url => (ShortURL.shorten(result_url, :lns) rescue result_url)
    else
      var :url => result_url
    end
  end
  alias_command :news, :n
end
