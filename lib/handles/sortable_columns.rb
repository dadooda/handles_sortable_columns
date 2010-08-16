module Handles
  # A controller handles sortable table columns.
  module SortableColumns
    def self.included(owner)
      owner.extend MetaClassMethods
    end

    class Config
      # GET parameter for page number. Default:
      #   page
      attr_accessor :page_param

      # GET parameter for sort field and order. Default:
      #   sort
      attr_accessor :sort_param

      # Sort indicator wrapping. Default:
      #   ["<span class='SortOrder'>", "</span>"]
      attr_accessor :indicator_markup

      # Sort indicator text. Default:
      #  {:asc => "&nbsp;&darr;&nbsp;", :desc => "&nbsp;&uarr;&nbsp;"}
      attr_accessor :indicator_text

      def initialize(attrs = {})
        defaults = {
          :page_param         => "page",
          :sort_param         => "sort",
          :indicator_markup   => ["<span class='SortOrder'>", "</span>"],   # NOTE: Maintain simpler syntax for doc purposes.
          :indicator_text     => {:asc => "&nbsp;&darr;&nbsp;", :desc => "&nbsp;&uarr;&nbsp;"},
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
      # Activate feature.
      #   class MyController < ApplicationController
      #     handles_sortable_columns
      #     handles_sortable_columns do |conf|
      #       conf.page_param = "p"
      #     end
      #   end
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
      def sortable_columns_config
        # NOTES:
        # * This is controller's class variable, ensure pretty name.
        # * Defaults are handled by the class itself.
        @@sortable_columns_config ||= ::Handles::SortableColumns::Config.new
      end
    end # ClassMethods

    module InstanceMethods
      protected

      # Compile an ActiveRecord-compatible hash of options related to sortable columns.
      #   sopts = sortable_columns_options do |field, order|
      #     case field
      #     when "is_forged", "created_at", "updated_at"
      #       "#{field} #{order}, name ASC"
      #     else
      #       "name ASC"
      #     end
      #   end
      #
      #   records = Klass.all({
      #     # ...
      #   }).merge(sopts)
      def sortable_columns_options(options = {}, &block)
        options = options.dup
        o = {}

        #HELP sortable_columns_options
        o[k = :sort_param] = options.delete(k) || self.class.sortable_columns_config[k]
        #HELP /sortable_columns_options

        raise "Unknown option(s): #{options.inspect}" if not options.empty?

        # Build "parsed param". "-name" means "by name, descending".
        pp = {}
        mat = params[o[:sort_param]].to_s.match /\A((?:-|))(.+?)\z/
        pp[:asc] = mat[1].empty? rescue true
        pp[:field] = mat[2] rescue nil

        order = pp[:asc] ? "ASC" : "DESC"

        order_by = if not block
          # No block -- do a straight mapping.
          if pp[:field]
            [pp[:field], pp[:asc] ? "ASC" : "DESC"].join(" ")
          end
        else
          # Block is given.
          yield(pp[:field], order)
        end

        if order_by
          {:order => order_by}
        else
          # Not enough information to decide.
          {}
        end
      end
    end # InstanceMethods

    module HelperMethods
      # Render a sortable column link.
      #   <%= sortable_column "Name", :field => "name" %>
      #   <%= sortable_column "Created At", :field => "created_at", :asc => false %>
      def sortable_column(label, options = {})
        options = options.dup
        o = {}

        #HELP sortable_column
        # Mnemonic name of the field to sort by.
        o[k = :field] = options.delete(k)

        # The name of GET parameter generated.
        o[k = :sort_param] = options.delete(k) || controller.class.sortable_columns_config[k]

        # The name of GET parameter for page number.
        o[k = :page_param] = options.delete(k) || controller.class.sortable_columns_config[k]

        # Sort direction by default (on first click).
        o[k = :asc] = (v = options.delete(k)).nil?? true : v

        # Sort indicator properties.
        o[k = :indicator_markup] = options.delete(k) || controller.class.sortable_columns_config[k]
        o[k = :indicator_text] = options.delete(k) || controller.class.sortable_columns_config[k]
        #HELP /sortable_column

        raise "Unknown option(s): #{options.inspect}" if not options.empty?

        if not o[k = :field]
          raise "options[#{k.inspect}] is required"
        end

        # Build "parsed param". "-name" means "by name, descending".
        pp = {}
        mat = params[o[:sort_param]].to_s.match /\A((?:-|))(.+?)\z/
        pp[:asc] = mat[1].empty? rescue true
        pp[:field] = mat[2] rescue nil

        pcs = []

        # Already sorted?
        if pp[:field] == o[:field].to_s
          # Sorted.
          pcs << link_to(label, params.merge({o[:sort_param] => [("-" if pp[:asc]), o[:field]].join, o[:page_param] => 1}))       # Opposite sort order when clicked.
          pcs << [o[:indicator_markup][0].to_s, o[:indicator_text][pp[:asc] ? :asc : :desc], o[:indicator_markup][1].to_s].join
        else
          # Not sorted.
          pcs << link_to(label, params.merge({o[:sort_param] => [("-" if not o[:asc]), o[:field]].join, o[:page_param] => 1}))
        end

        pcs.join
      end
    end # HelperMethods
  end # SortableColumns
end # Handles
