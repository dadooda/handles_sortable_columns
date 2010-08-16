# This seems wrong and causing autoload confusion in our case.
if true
  Dir[File.join(File.dirname(__FILE__), "lib/**/*.rb")].each do |fn|
    require fn
  end
end

if false
  libs = [
    "handles/sortable_columns",
    "action_controller/base/handles_sortable_columns",
  ]

  libs.each do |lib|
    require File.join(File.dirname(__FILE__), "lib", lib)
  end
end

if false
  # WARNING: Order is important or autoload confision may occur ("A copy of XX has been removed from the module tree but is still active!").
  libs = [
    "handles/sortable_columns_config",
    "handles/sortable_columns",
    "handles/sortable_columns/config",
    "handles/sortable_columns/helper_methods",
    "handles/sortable_columns/instance_methods",
    "handles/sortable_columns/meta_class_methods",
    "action_controller/base/handles_sortable_columns",
  ]

  libs.each do |lib|
    require File.join(File.dirname(__FILE__), "lib", lib)
  end
end

# This doesn't seem to have any effect.
if true
  # Reload plugin in development mode.
  if RAILS_ENV == "development"
    ActiveSupport::Dependencies.load_once_paths.reject! {|dir| dir =~ /^#{Regexp.escape(File.dirname(__FILE__))}/}
  end
end
