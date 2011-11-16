# view helpers
module Sinatra::ViewHelpers
  
  def text_field_tag(object, name, options = {})
    value = ""
    value = options.delete(:value) if options[:value]
    value = object.send name if object && object.respond_to?(name)
    attr = []
    options.each do |key, val|
      attr << "#{key}='#{val}'"
    end
    "<input type='text' name='#{object.form_name}[#{name.to_s}]' value='#{value}' #{attr.join(" ")} />"
  end
  
  def submit_tag(name, value, options = {})
    attr = []
    options.each do |key, val|
      attr << "#{key}='#{val}'"
    end
    "<input type='submit' name='#{name.to_s}' value='#{value}' #{attr.join(" ")} />"
  end
  
  def check_box_tag(object, name, options = {})
    value = nil
    value = options.delete(:value) if options[:value]
    value = object.send name if object && object.respond_to?(name)
    attr = []
    options.each do |key, val|
      attr << "#{key}='#{val}'"
    end
    "<input id='#{object.form_name}_#{name.to_s}' type='checkbox' name='#{object.form_name}[#{name.to_s}]' #{'checked="checked"' if value} value='1' #{attr.join(" ")} />"
  end
  
  def label_tag(object, name, label, options = {})
    attr = []
    options.each do |key, val|
      attr << "#{key}='#{val}'"
    end
    "<label for='#{object.form_name}_#{name.to_s}' #{attr.join(" ")}>#{label}</label>"
  end
  
end