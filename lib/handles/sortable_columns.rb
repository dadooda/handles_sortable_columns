module Handles  #:nodoc:
  # == Overview
  #
  # A sortable columns feature for your controller and views.
  #
  # == Basic Usage
  #
  # Activate the feature in your controller class:
  #
  #   class MyController < ApplicationController
  #     handles_sortable_columns
  #   ...
  # 
  # In a view, mark up sortable columns by using the <tt>sortable_column</tt> helper:
  #
  #   <%= sortable_column "Product" %>
  #   <%= sortable_column "Price" % >
  #
  # In controller action, fetch and use the order clause according to current state of sortable columns:
  #
  #   def index
  #     order = sortable_column_order
  #     @records = Article.all(:order => order)
  #   end
  #
  # That's it for basic usage. Production usage may require passing additional parameters to listed methods.
  #
  # See also:
  # * <tt>MetaClassMethods#handles_sortable_columns</tt>
  # * <tt>HelperMethods#sortable_column</tt>
  # * <tt>InstanceMethods#sortable_column_order</tt>
  module SortableColumns
    def self.included(owner)
      owner.extend MetaClassMethods
    end

    # Sortable columns configuration object. Passed to block when you do a:
    #
    #   handles_sortable_column do |conf|
    #     ...
    #   end
    class Config
      # CSS class for link (regardless of sorted state). Default:
      #
      #   nil
      attr_accessor :class

      # GET parameter name for page number. Default:
      #
      #   page
      attr_accessor :page_param

      # GET parameter name for sort column and direction. Default:
      #
      #   sort
      attr_accessor :sort_param

      # Sort indicator text. If any of values are empty, indicator is not displayed. Default:
      #
      #  {:asc => "&nbsp;&darr;&nbsp;", :desc => "&nbsp;&uarr;&nbsp;"}
      attr_accessor :indicator_text

      # Sort indicator class. Default:
      #
      #  {:asc => "SortedAsc", :desc => "SortedDesc"}
      attr_accessor :indicator_class

      def initialize(attrs = {})
        defaults = {
          :page_param         => "page",
          :sort_param         => "sort",
          :indicator_text     => {:asc => "&nbsp;&darr;&nbsp;", :desc => "&nbsp;&uarr;&nbsp;"},
          :indicator_class    => {:asc => "SortedAsc", :desc => "SortedDesc"},
        }

        defaults.merge(attrs).each {|k, v| send("#{k}=", v)}
      end

      def [](key)
        send(key)
      end

      def []=(key, value)
        send("#{key}=", value)
      end
    end # Config

    module MetaClassMethods
      # Activate and optionally configure the sortable columns.
      #
      #   class MyController < ApplicationController
      #     handles_sortable_columns
      #   end
      #
      # With configuration:
      #
      #   class MyController < ApplicationController
      #     handles_sortable_columns do |conf|
      #       conf.sort_param = "s"
      #       conf.page_param = "p"
      #       conf.indicator_text = {}
      #       ...
      #     end
      #   end
      #
      # <tt>conf</tt> is a <tt>Config</tt> object.
      def handles_sortable_columns(&block)
        # Multiple activation protection.
        if not self < InstanceMethods
          extend ClassMethods
          include InstanceMethods
          helper HelperMethods
        end

        # Configuration is processed at every activation.
        yield(sortable_columns_config) if block
      end
    end # MetaClassMethods

    module ClassMethods
      # Internal/advanced use only. Access/initialize the sortable columns config.
      def sortable_columns_config
        # NOTE: This is controller's class instance variable.
        @sortable_columns_config ||= ::Handles::SortableColumns::Config.new
      end

      # Internal/advanced use only. Convert title to sortable column name.
      #
      #   sortable_column_name_from_title("ProductName")  # => "product_name"
      def sortable_column_name_from_title(title)
        title.gsub(/(\s)(\S)/) {$2.upcase}.underscore
      end

      # Internal/advanced use only. Parse sortable column sort param into a Hash with predefined keys.
      #
      #   parse_sortable_column_sort_param("name")    # => {:column => "name", :direction => :asc}
      #   parse_sortable_column_sort_param("-name")   # => {:column => "name", :direction => :desc}
      #   parse_sortable_column_sort_param("")        # => {:column => nil, :direction => nil}
      def parse_sortable_column_sort_param(sort)
        out = {:column => nil, :direction => nil}
        if sort.to_s.strip.match /\A((?:-|))([^-]+)\z/
          out[:direction] = $1.empty?? :asc : :desc
          out[:column] = $2.strip
        end
        out
      end
    end # ClassMethods

    module InstanceMethods
      protected

      # Compile SQL order clause according to current state of sortable columns.
      #
      # Basic (kickstart) usage:
      #
      #   order = sortable_column_order
      #
      # <b>WARNING!</b> Basic usage is <b>not recommended</b> for production since it is potentially
      # vulnerable to SQL injection!
      #
      # Production usage with multiple sort criteria, column name validation and defaults:
      #
      #   order = sortable_column_order do |column, direction|
      #     case column
      #     when "name"
      #       "#{column} #{direction}"
      #     when "created_at", "updated_at"
      #       "#{column} #{direction}, name ASC"
      #     else
      #       "name ASC"
      #     end
      #   end
      #
      # Apply order:
      #
      #   @records = Article.all(:order => order)   # Rails 2.x.
      #   @records = Article.order(order)           # Rails 3.
      def sortable_column_order(&block)
        conf = {}
        conf[k = :sort_param] = self.class.sortable_columns_config[k]

        # Parse sort param.
        pp = self.class.parse_sortable_column_sort_param(params[conf[:sort_param]])

        order = if block
          yield(pp[:column], pp[:direction])
        else
          # No block -- do a straight mapping.
          if pp[:column]
            [pp[:column], pp[:direction]].join(" ")
          end
        end

        # Can be nil.
        order
      end
    end # InstanceMethods

    module HelperMethods
      # Render a sortable column link.
      #
      # Options:
      # * <tt>:column</tt> -- Column name. E.g. <tt>"created_at"</tt>.
      # * <tt>:direction</tt> -- Sort direction on first click. <tt>:asc</tt> or <tt>:desc</tt>. Default is <tt>:asc</tt>.
      # * <tt>:class</tt> -- CSS class for link (regardless of sorted state).
      # * <tt>:style</tt> -- CSS style for link (regardless of sorted state).
      #
      # Examples:
      #
      #   <%= sortable_column "Product" %>
      #   <%= sortable_column "Highest Price", :column_name => "max_price" %>
      #   <%= sortable_column "Name", :class => "SortableLink" %>
      #   <%= sortable_column "Created At", :direction => :asc %>
      def sortable_column(title, options = {})
        options = options.dup
        o = {}
        conf = {}
        conf[k = :sort_param] = controller.class.sortable_columns_config[k]
        conf[k = :page_param] = controller.class.sortable_columns_config[k]
        conf[k = :indicator_text] = controller.class.sortable_columns_config[k]
        conf[k = :indicator_class] = controller.class.sortable_columns_config[k]

        #HELP sortable_column
        o[k = :column] = options.delete(k) || controller.class.sortable_column_name_from_title(title)
        o[k = :direction] = options.delete(k).to_s.downcase =~ /\Adesc\z/ ? :desc : :asc
        o[k = :class] = options.delete(k) || controller.class.sortable_columns_config[k]
        o[k = :style] = options.delete(k)
        #HELP /sortable_column

        raise "Unknown option(s): #{options.inspect}" if not options.empty?

        # Parse sort param.
        pp = controller.class.parse_sortable_column_sort_param(params[conf[:sort_param]])

        css_class = []
        if (s = o[:class]).present?
          css_class << s
        end

        # Build link itself.
        pcs = []

        html_options = {}
        html_options[:class] = css_class if css_class.present?
        html_options[:style] = o[:style] if o[:style].present?

        # Already sorted?
        if pp[:column] == o[:column].to_s
          if (s = conf[:indicator_class][pp[:direction]]).present?
            css_class << s
          end

          pcs << link_to(title, params.merge({conf[:sort_param] => [("-" if pp[:direction] == :asc), o[:column]].join, conf[:page_param] => 1}), html_options)       # Opposite sort order when clicked.

          if (s = conf[:indicator_text][pp[:direction]]).present?
            pcs << s
          end
        else
          # Not sorted.
          pcs << link_to(title, params.merge({conf[:sort_param] => [("-" if o[:direction] != :asc), o[:column]].join, conf[:page_param] => 1}), html_options)
        end

        pcs.join
      end
    end # HelperMethods
  end # SortableColumns
end # Handles
