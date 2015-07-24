require 'dotenv'
Dotenv.load

loaddirs = [
  ['/usr', 'src', 'app', 'lib'],
  ['.', 'lib'],
]

loaddirs.each do |path|
  libdir = File.join(path)
  $LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)
end

require 'monkeybusiness'

run MonkeyBusiness::API.new
