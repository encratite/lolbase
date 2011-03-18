require 'nil/file'

targets = Nil.readDirectory('data/match-lists')
targets.each do |target|
  path = target.path
  #puts "Processing #{path}"
  html = Nil.readFile(path)
  html.scan(/"(http:\/\/www.lolbase.net\/matches\/view\/EUr.+?)"/) do |match|
    url = match.first
    puts url
  end
end
