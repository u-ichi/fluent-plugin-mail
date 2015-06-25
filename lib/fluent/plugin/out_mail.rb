require 'securerandom'

class Fluent::MailOutput < Fluent::Output
  Fluent::Plugin.register_output('mail', self)

  # Define `log` method for v0.10.42 or earlier
  unless method_defined?(:log)
    define_method("log") { $log }
  end

  config_param :out_keys,             :string,  :default => ""
  config_param :message,              :string,  :default => nil
  config_param :message_out_keys,     :string,  :default => ""
  config_param :time_key,             :string,  :default => nil
  config_param :tag_key,              :string,  :default => 'tag'
  config_param :host,                 :string
  config_param :port,                 :integer, :default => 25
  config_param :domain,               :string,  :default => 'localdomain'
  config_param :user,                 :string,  :default => nil
  config_param :password,             :string,  :default => nil
  config_param :from,                 :string,  :default => 'localhost@localdomain'
  config_param :to,                   :string,  :default => ''
  config_param :cc,                   :string,  :default => ''
  config_param :bcc,                  :string,  :default => ''
  config_param :subject,              :string,  :default => 'Fluent::MailOutput plugin'
  config_param :subject_out_keys,     :string,  :default => ""
  config_param :enable_starttls_auto, :bool,    :default => false
  config_param :enable_tls,           :bool,    :default => false
  config_param :time_format,          :string,  :default => "%F %T %z"
  config_param :localtime,            :bool,    :default => true
  config_param :time_locale,                    :default => nil

  def initialize
    super
    require 'net/smtp'
    require 'kconv'
    require 'string/scrub' if RUBY_VERSION.to_f < 2.1
  end

  def configure(conf)
    super

    @out_keys = @out_keys.split(',')
    @message_out_keys = @message_out_keys.split(',')
    @subject_out_keys = @subject_out_keys.split(',')

    if @out_keys.empty? and @message.nil?
      raise Fluent::ConfigError, "Either 'message' or 'out_keys' must be specifed."
    end

    if @message
      begin
        @message % (['1'] * @message_out_keys.length)
      rescue ArgumentError
        raise Fluent::ConfigError, "string specifier '%s' of message and message_out_keys specification mismatch"
      end
      @create_message_proc = Proc.new {|tag, time, record| create_formatted_message(tag, time, record) }
    else
      # The default uses the old `key=value` format for old version compatibility
      @create_message_proc = Proc.new {|tag, time, record| create_key_value_message(tag, time, record) }
    end

    begin
      @subject % (['1'] * @subject_out_keys.length)
    rescue ArgumentError
      raise Fluent::ConfigError, "string specifier '%s' of subject and subject_out_keys specification mismatch"
    end
  end

  def start
  end

  def shutdown
  end

  def emit(tag, es, chain)
    messages = []
    subjects = []

    es.each {|time,record|
      messages << @create_message_proc.call(tag, time, record)
      subjects << create_formatted_subject(tag, time, record)
    }

    (0...messages.size).each do |i|
      message = messages[i]
      subject = subjects[i]
      begin
        sendmail(subject, message)
      rescue => e
        log.warn "out_mail: failed to send notice to #{@host}:#{@port}, subject: #{subject}, message: #{message}, " <<
          "error_class: #{e.class}, error_message: #{e.message}, error_backtrace: #{e.backtrace.first}"
      end
    end

    chain.next
  end

  # The old `key=value` format for old version compatibility
  def create_key_value_message(tag, time, record)
    values = []

    values << @out_keys.each do |key|
      case key
      when @time_key
        format_time(time, @time_format)
      when @tag_key
        tag
      else
        "#{key}: #{record[key].to_s}"
      end
    end

    values.join("\n")
  end

  def create_formatted_message(tag, time, record)
    values = []

    values = @message_out_keys.map do |key|
      case key
      when @time_key
        format_time(time, @time_format)
      when @tag_key
        tag
      else
        record[key].to_s
      end
    end

    message = (@message % values)
    with_scrub(message) {|str| str.gsub(/\\n/, "\n") }
  end

  def create_formatted_subject(tag, time, record)
    values = []

    values = @subject_out_keys.map do |key|
      case key
      when @time_key
        format_time(time, @time_format)
      when @tag_key
        tag
      else
        record[key].to_s
      end
    end

    @subject % values
  end

  def sendmail(subject, msg)
    smtp = Net::SMTP.new(@host, @port)

    if @user and @password
      smtp_auth_option = [@domain, @user, @password, :plain]
      smtp.enable_starttls if @enable_starttls_auto
      smtp.enable_tls if @enable_tls
      smtp.start(@domain,@user,@password,:plain)
    else
      smtp.start
    end

    subject = subject.force_encoding('binary')
    body = msg.force_encoding('binary')

    # Date: header has timezone, so usually it is not necessary to set locale explicitly
    # But, for people who would see mail header text directly, the locale information may help something
    # (for example, they can tell the sender should live in Tokyo if +0900)
    date = format_time(Time.now, "%a, %d %b %Y %X %z")

    mid = sprintf("<%s@%s>", SecureRandom.uuid, SecureRandom.uuid)
    content = <<EOF
Date: #{date}
From: #{@from}
To: #{@to}
Cc: #{@cc}
Bcc: #{@bcc}
Subject: #{subject}
Message-Id: #{mid}
Mime-Version: 1.0
Content-Type: text/plain; charset=utf-8

#{body}
EOF
    response = smtp.send_mail(content, @from, @to.split(/,/), @cc.split(/,/), @bcc.split(/,/))
    log.debug "out_mail: content: #{content.gsub("\n", "\\n")}"
    log.debug "out_mail: email send response: #{response.string.chomp}"
    smtp.finish
  end

  def format_time(time, time_format)
    # Fluentd >= v0.12's TimeFormatter supports timezone, but v0.10 does not
    if @time_locale
      with_timezone(@time_locale) { Fluent::TimeFormatter.new(time_format, @localtime).format(time) }
    else
      Fluent::TimeFormatter.new(time_format, @localtime).format(time)
    end
  end

  def with_timezone(tz)
    oldtz, ENV['TZ'] = ENV['TZ'], tz
    yield
  ensure
    ENV['TZ'] = oldtz
  end

  def with_scrub(string)
    begin
      return yield(string)
    rescue ArgumentError => e
      raise e unless e.message.index("invalid byte sequence in") == 0
      log.info "out_mail: invalid byte sequence is replaced in #{string}"
      string.scrub!('?')
      retry
    end
  end
end
