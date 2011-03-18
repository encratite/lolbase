require 'nil/file'

targets = Nil.readDirectory('data/top500')
targets.each do |target|
  path = target.path
  #puts "Processing #{path}"
  html = Nil.readFile(path)
  match = html.match(/"(http:\/\/www\.lolbase\.net\/matches\/player\/.+?)"/)
  if match == nil
    raise "Unable to locate the match list in #{path}"
  end
  url = match[1]
  puts "#{url}/all"
end
