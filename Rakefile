desc "Compile README preview"
task :readme do
  require "kramdown"

  doc = Kramdown::Document.new(File.read "README.md")

  fn = "README.html"
  puts "Writing '#{fn}'..."
  File.open(fn, "w") do |f|
    f.write(File.read "dev/head.html")
    f.write(doc.to_html)
  end
  puts ": ok"
end
