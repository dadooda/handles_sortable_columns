class HandlesSortableColumnsGenerator < Rails::Generator::Base
  def manifest
    record do |m|
      m.file fn = "initializers/handles_sortable_columns.rb", "config/#{fn}"
      m.readme "INSTALL"
    end
  end
end
