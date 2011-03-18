require 'nil/http'

def downloadTop500
  html = Nil.httpDownload('http://www.lolbase.net/lists')
  if html == nil
    raise 'Unable to retrieve Top 500 list'
  end
  pattern = /<td><a href="(http:\/\/www\.lolbase\.net\/eu\/.+?)">.+?<\/a> <\/td>/
  html.scan(pattern) do |match|
    url = match.first
    puts url
  end
end

downloadTop500
