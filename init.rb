if true
  # WARNING: Order is important or autoload confision will occur ("A copy of XX has been removed from the module tree but is still active!").
  require File.join(File.dirname(__FILE__), "lib/handles/sortable_columns.rb")
  require File.join(File.dirname(__FILE__), "lib/action_controller/base/handles_sortable_columns.rb")
end

# This seems wrong and causing autoload confusion in our case.
if false
  Dir[File.join(File.dirname(__FILE__), "lib/**/*.rb")].each do |fn|
    require fn
  end
end

# This doesn't seem to have any effect.
if false
  # Reload plugin in development mode.
  if RAILS_ENV == "development"
    ActiveSupport::Dependencies.load_once_paths.reject! {|dir| dir =~ /^#{Regexp.escape(File.dirname(__FILE__))}/}
  end
end
