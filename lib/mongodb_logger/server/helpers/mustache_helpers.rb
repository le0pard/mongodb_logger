require 'multi_json'
module MongodbLogger
  module MustacheHelpers
    include Rack::Utils

    def url_path(*path_parts)
      [ path_prefix, path_parts ].join("/").squeeze('/')
    end

    def path_prefix
      request.env['SCRIPT_NAME']
    end

    def current_page
      url_path request.path_info.sub('/','')
    end

    def class_if_current(path = '')
      'class="active"' if current_page[0, path.size] == path
    end

    def string_from_log_message(message)
      message.is_a?(Array) ? message.join("\n") : message.to_s
    end

    def pretty_hash(hash)
      begin
        Marshal::dump(hash)
        h(hash.to_yaml).gsub("  ", "&nbsp; ")
      rescue Exception => e  # errors from Marshal or YAML
        # Object couldn't be dumped, perhaps because of singleton methods -- this is the fallback
        h(hash.inspect)
      end
    end

    def log_data(log)
      main_msg = "No message"
      if log['messages'] && log['messages']['info']
        main_msg = string_from_log_message(log['messages']['info']).truncate(300, :separator => ' ')
      end
      if log['is_exception'] && log['messages'] && log['messages']['error']
        main_msg = string_from_log_message(log['messages']['error']).truncate(300, :separator => ' ')
      end
      # return value
      {
        '_id' => log['_id'].to_s,
        'web_url' => url_path("log/#{log['_id']}"),
        'main_msg' => main_msg,
        'is_exception_class' => (log['is_exception'] ? 'failure' : 'success'),
        'method' => log['method'],
        'url' => log['url'],
        'request_time' => log['request_time'],
        'ip' => log['ip'],
        'params' => pretty_hash(log['params'])
      }
    end

    def log_data_json(log)
      MultiJson.dump(log_data(log))
    end
  end

  class MustacheHelpersObj
    extend MustacheHelpers
  end
end