# view helpers
module Sinatra::ViewHelpers

  def percent_of_userd_memory(collection_stats)
    ((collection_stats[:size] / collection_stats[:maxSize]) * 100).round
  end

  def meta_informations(log)
    meta_data = Hash.new
    log.each do |key, val|
      # predefined fields
      next if [:_id, :messages, :request_time, :ip, :runtime, :application_name, :is_exception, :params, :method, :controller, :action, :session, :path, :url].include?(key.to_sym)
      meta_data[key] = val
    end
    meta_data
  end

  STORAGE_UNITS = [:byte, :kb, :mb, :gb, :tb].freeze
  def number_to_human_size(number, precision = 2)
    number = begin
      Float(number)
    rescue ArgumentError, TypeError
      return number
    end
    base, max_exp = 1024, STORAGE_UNITS.size - 1
    exponent = (Math.log(number) / Math.log(base)).to_i # Convert to base
    exponent = max_exp if exponent > max_exp # we need this to avoid overflow for the highest unit
    number  /= base ** exponent
    unit_key = STORAGE_UNITS[exponent]
    ("%.#{precision}f #{unit_key.to_s.upcase}"  % number).sub(/([0-9]\.\d*?)0+ /, '\1 ' ).sub(/\. /,' ')
  rescue
    nil
  end

  def text_field_tag(object, name, options = {})
    value = ""
    value = options.delete(:value) if options[:value]
    value = object.send name if object && object.respond_to?(name)
    attributes = options.map{ |key, val| "#{key}='#{val}'" }
    "<input type='text' name='#{object.form_name}[#{name.to_s}]' value='#{value}' #{attributes.join(" ")} />"
  end

  def submit_tag(name, value, options = {})
    attributes = options.map{ |key, val| "#{key}='#{val}'" }
    "<input type='submit' name='#{name.to_s}' value='#{value}' #{attributes.join(" ")} />"
  end

  def check_box_tag(object, name, options = {})
    value = nil
    value = options.delete(:value) if options[:value]
    value = object.send name if object && object.respond_to?(name)
    attributes = options.map{ |key, val| "#{key}='#{val}'" }
    "<input id='#{object.form_name}_#{name.to_s}' type='checkbox' name='#{object.form_name}[#{name.to_s}]' #{'checked="checked"' if value} value='1' #{attributes.join(" ")} />"
  end

  def label_tag(object, name, label, options = {})
    attributes = options.map{ |key, val| "#{key}='#{val}'" }
    "<label for='#{object.form_name}_#{name.to_s}' #{attributes.join(" ")}>#{label}</label>"
  end

  def select_tag(object, name, options_array, options = {})
    value = nil
    value = options.delete(:value) if options[:value]
    value = object.send name if object && object.respond_to?(name)
    attributes = options.map{ |key, val| "#{key}='#{val}'" }
    select_tag = ["<select id='#{object.form_name}_#{name.to_s}' name='#{object.form_name}[#{name.to_s}]' #{attributes.join(" ")}>"]
    options_array.each do |val|
      if val.is_a?(Array)
        skey, sval = val[0], val[1]
      else
        skey = sval = val
      end
      select_tag << "<option value='#{skey}' #{"selected='selected'" if value && skey.to_s == value}>#{sval}</option>"
    end
    select_tag << "</select>"
    select_tag.join("\n")
  end

end