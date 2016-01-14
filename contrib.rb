require './github'

if ARGV[0].nil?
  puts "enter your access token to github"
else
  Github.new(ARGV[0]).start
end
