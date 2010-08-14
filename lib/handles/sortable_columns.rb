module Handles
  # A controller handles sortable table columns.
  module SortableColumns
    # Configuration hash.
    #   Handles::SortableColumns.conf                # => {...}
    #   Handles::SortableColumns.conf[:sort_param]   # => "sort"
    #   Handles::SortableColumns.conf[:sort_param] = "order"
    def self.conf
      @conf ||= {
        :page_param         => "page",
        :sort_param         => "sort",
        :indicator_markup   => [%{<span class="SortOrder">}, %{</span>}],
        :indicator_text     => {:asc => "&nbsp;&darr;&nbsp;", :desc => "&nbsp;&uarr;&nbsp;"},
      }
    end

    def self.included(owner)
      owner.extend MetaClassMethods
    end

    module MetaClassMethods
      # Activate feature.
      #   class MyController < ApplicationController
      #     handles_sortable_columns
      #   end
      def handles_sortable_columns
        # Multiple activation protection.
        return nil if self < InstanceMethods
        include InstanceMethods
        helper HelperMethods
      end
    end # MetaClassMethods

    module InstanceMethods
      protected

      # Compile an ActiveRecord-compatible hash of options related to sortable columns.
      #   sopts = sortable_columns_options do |field, order|
      #     case field
      #     when "is_forged", "created_at", "updated_at"
      #       "#{field} #{order}, self.name ASC"
      #     else
      #       "self.name ASC"
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
        o[k = :sort_param] = options.delete(k) || Handles::SortableColumns.conf[k]
        #HELP /sortable_columns_options

        raise "Unknown option(s): #{options.inspect}" if not options.empty?

        # Build "parsed param". "-name" means "by name, descending".
        pp = {}
        mat = params[o[:sort_param]].to_s.match /\A((?:-|))(.+?)\z/
        pp[:asc] = mat[1].empty? rescue true
        pp[:field] = mat[2] rescue nil
        ##DT.p "pp", pp

        order = pp[:asc] ? "ASC" : "DESC"
        ##DT.p "order", order

        order_by = if not block
          # No block -- do a straight mapping.
          if pp[:field]
            [pp[:field], pp[:asc] ? "ASC" : "DESC"].join(" ")
          end
        else
          # Block is given.
          yield(pp[:field], order)
        end
        ##DT.p "order_by", order_by

        if order_by
          {:order => order_by}
        else
          # Not enough information to decide.
          {}
        end
      end
    end # InstanceMethods

    module HelperMethods
      def sortable_column(label, options = {})
        options = options.dup
        o = {}

        #HELP sortable_column
        # Mnemonic name of the field to sort by.
        o[k = :field] = options.delete(k)

        # The name of GET parameter generated.
        o[k = :sort_param] = options.delete(k) || Handles::SortableColumns.conf[k]

        # The name of GET parameter for page number.
        o[k = :page_param] = options.delete(k) || Handles::SortableColumns.conf[k]

        # Sort direction by default (on first click).
        o[k = :asc] = (v = options.delete(k)).nil?? true : v

        # Sort indicator properties.
        o[k = :indicator_markup] = options.delete(k) || Handles::SortableColumns.conf[k]
        o[k = :indicator_text] = options.delete(k) || Handles::SortableColumns.conf[k]
        #HELP /sortable_column

        raise "Unknown option(s): #{options.inspect}" if not options.empty?
        ##DT.p "Handles::SortableColumns.conf", Handles::SortableColumns.conf
        ##DT.p "o", o

        if not o[k = :field]
          raise "options[#{k.inspect}] is required"
        end

        ##DT.p "o", o

        # Build "parsed param". "-name" means "by name, descending".
        pp = {}
        mat = params[o[:sort_param]].to_s.match /\A((?:-|))(.+?)\z/
        ##DT.p "mat", mat.to_a
        pp[:asc] = mat[1].empty? rescue true
        pp[:field] = mat[2] rescue nil
        ##DT.p "pp", pp

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

        DT.p "pcs", pcs
        pcs.join
      end
    end # HelperMethods
  end
end
