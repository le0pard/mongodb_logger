# view helpers
module Sinatra::ViewHelpers
  
  def text_field_tag(object, name, options = {})
    value = ""
    value = options.delete(:value) if options[:value]
    value = object.send name if object
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
    "<input type='submit' name='#{name.to_s}]' value='#{value}' #{attr.join(" ")} />"
  end
  
end