# Rails gem init.
Dir[File.join(File.dirname(__FILE__), "**/*.rb")].each do |fn|
  require fn
end
