# Controller for the WebSearcher leaf.

class Controller < Autumn::Leaf
  
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
    
    begin
      html = open("http://www.google.com/search?hl=en&q=#{URI.escape msg}&btnI=I%27m+Feeling+Lucky")
    rescue SocketError, URI::InvalidURIError, OpenURI::HTTPError
      return "Error when Googling."
    end
    
    page = Hpricot(html)
    url = html.base_uri
    begin
      url = ShortURL.shorten(url, :lns) if url.size > 30
    rescue
    end
    
    var :url => url
    var :title => (page/'head/title').inner_text
  end
  alias_command :google, :g

  # Typing "!image" links the first result of a Google image search. Use with
  # care.
  
  def image_command(stem, sender, reply_to, msg)
    if msg.nil? then
      render :image_help
      return
    end
    
    begin
      html = open("http://images.google.com/images?hl=en&q=#{URI.escape msg}").read
    rescue SocketError, URI::InvalidURIError, OpenURI::HTTPError
      return "Error finding images."
    end
    urls = html.scan(/imgurl=(.+?)&imgrefurl=/).flatten.map { |url| URI.decode url }
    if urls.empty? then return "No images found."
    else return urls.first end
  end
  alias_command :image, :i
  
  # Typing "!news" returns a random news story from the top five news stories.
  # You can optionally provide a topic.

  def news_command(stem, sender, reply_to, msg)
    url = "http://news.google.com/news?hl=en&ie=UTF-8&output=atom"
    url << "&q=#{URI.escape msg}" if msg
    begin
      dom = Hpricot(open(url))
    rescue SocketError, URI::InvalidURIError, OpenURI::HTTPError
      return "Error getting the news."
    end
    
    stories = (dom/'entry')[0,5]
    story = stories[rand(5)]
    return "No news stories found." unless story
    
    var :title => (story/'title').inner_text
    story_url = (story/'link').first['href']
    begin
      story_url = ShortURL.shorten(story_url, :lns) if story_url.size > 30
    rescue
    end
    var :url => story_url
  end
  alias_command :news, :n
  
  # Invoked when a message is sent to a channel the leaf is a member of (even
  # if that message was a valid command). If the message is a link, loads the
  # link's title and prints it to the channel.
  
  def did_receive_channel_message(stem, sender, channel, msg)
    return unless options[:announce_webpage_titles]
    if msg =~ /^http:\/\// then
      begin
        page = Hpricot(open(msg))
      rescue SocketError, URI::InvalidURIError, OpenURI::HTTPError
        return
      end
      title = (page/'head/title').try(:inner_html)
      stem.message title if title
    end
  end
end
