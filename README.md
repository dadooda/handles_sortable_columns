
Sortable Table Columns
======================


Introduction
------------

A simple yet flexible Rails gem/plugin to quickly add sortable table columns to your controller and views.


Setup
-----

    $ gem sources --add http://rubygems.org
    $ gem install handles_sortable_columns

In your app's `config/environment.rb` do a:

    config.gem "handles_sortable_columns"


Basic Usage
-----------

Activate the feature in your controller class:

    class MyController < ApplicationController
      handles_sortable_columns
    ...

In a view, mark up sortable columns by using the <tt>sortable_column</tt> helper:

    <%= sortable_column "Product" %>
    <%= sortable_column "Price" %>

In controller action, fetch and use the order clause according to current state of sortable columns:

    def index
      order = sortable_column_order
      @records = Article.all(:order => order)
    end

That's it for basic usage. Production usage may require passing additional parameters to listed methods.


Production Usage
----------------

Please take time to read the gem's full [RDoc documentation](#TODO-link-to-doc). This README has a limited coverage.


### Configuration ###

Change names of GET parameters used for sorting and pagination:

    class MyController < ApplicationController
      handles_sortable_columns do |conf|
        conf.sort_param = "s"
        conf.page_param = "p"
      end
    ...

Change CSS class of all sortable column `<a>` tags:

    handles_sortable_columns do |conf|
      conf.class = "SortableLink"
      conf.indicator_class = {:asc => "AscSortableLink", :desc => "DescSortableLink"}
    end

Change how text-based sort indicator looks like:

    handles_sortable_columns do |conf|
      conf.indicator_text = {:asc => "[asc]", :desc => "[desc]"}
    end

Disable text-based sort indicator completely:

    handles_sortable_columns do |conf|
      conf.indicator_text = {}
    end


### Helper Options ###

Explicitly specify column name:

    <%= sortable_column "Highest Price", :column_name => "max_price" %>

Specify CSS class for this particular link:

    <%= sortable_column "Name", :class => "SortableLink" %>

Specify sort direction on first click:

    <%= sortable_column "Created At", :direction => :asc %>


### Fetching Sort Order ###

To fetch sort order **securely**, with **column name validation**, **default values** and **multiple sort criteria**, use the block form of `sortable_column_order`:

    order = sortable_column_order do |column, direction|
      case column
      when "name"
        "#{column} #{direction}"
      when "created_at", "updated_at"
        "#{column} #{direction}, name ASC"
      else
        "name ASC"
      end
    end


Feedback
--------

Send bug reports, suggestions and criticisms through [project's page on GitHub](http://github.com/dadooda/handles_sortable_columns).
