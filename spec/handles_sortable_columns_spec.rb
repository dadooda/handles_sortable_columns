describe "ClassMethods" do
  module WrapSortableColumnsClassMethods
    class MyController < ActionController::Base
      handles_sortable_columns
    end
  end

  describe "#sortable_column_name_from_title" do
    it "generally works" do
      tests = [
        ["Product", "product"],
        ["product", "product"],
        ["created_at", "created_at"],
        ["created at", "created_at"],
        ["CreatedAt", "created_at"],
        ["Created At", "created_at"],
      ]

      tests.each do |input, expected|
        WrapSortableColumnsClassMethods::MyController.sortable_column_name_from_title(input).should == expected
      end
    end
  end # #sortable_column_name_from_title

  describe "#parse_sortable_column_sort_param" do
    it "generally works" do
      tests = [
        ["name", {:column => "name", :direction => :asc}],
        ["-name", {:column => "name", :direction => :desc}],
        [" -name ", {:column => "name", :direction => :desc}],
        ["", {:column => nil, :direction => nil}],
        ["-", {:column => nil, :direction => nil}],
        ["- name", {:column => "name", :direction => :desc}],
        ["--kaka", {:column => nil, :direction => nil}],
      ]

      tests.each do |input, expected|
        WrapSortableColumnsClassMethods::MyController.parse_sortable_column_sort_param(input).should == expected
      end
    end
  end # #parse_sortable_column_sort_param
end # ClassMethods
