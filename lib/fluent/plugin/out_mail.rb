class Fluent::MailOutput < Fluent::Output
  Fluent::Plugin.register_output('mail', self)

  config_param :out_keys, :string, :default => ""
  config_param :message, :string, :default => nil
  config_param :message_out_keys, :string, :default => ""
  config_param :time_key, :string, :default => nil
  config_param :time_format, :string, :default => nil
  config_param :tag_key, :string, :default => 'tag'
  config_param :host, :string
  config_param :port, :integer, :default => 25
  config_param :domain, :string, :default => 'localdomain'
  config_param :user, :string, :default => nil
  config_param :password, :string, :default => nil
  config_param :from, :string, :default => 'localhost@localdomain'
  config_param :to, :string, :default => ''
  config_param :subject, :string, :default => 'Fluent::MailOutput plugin'
  config_param :subject_out_keys, :string, :default => ""
  config_param :enable_starttls_auto, :bool, :default => false

  def initialize
    super
    require 'net/smtp'
    require 'kconv'
  end

  def configure(conf)
    super

    @out_keys = @out_keys.split(',')
    @message_out_keys = @message_out_keys.split(',')
    @subject_out_keys = @subject_out_keys.split(',')

    if @out_keys.empty? and @message.nil?
      raise Fluent::ConfigError, "Either 'message' or 'out_keys' must be specifed."
    end

    begin
      @message % (['1'] * @message_out_keys.length) if @message
    rescue ArgumentError
      raise Fluent::ConfigError, "string specifier '%s' of message and message_out_keys specification mismatch"
    end

    begin
      @subject % (['1'] * @subject_out_keys.length)
    rescue ArgumentError
      raise Fluent::ConfigError, "string specifier '%s' of subject and subject_out_keys specification mismatch"
    end

    if @time_key
      if @time_format
        f = @time_format
        tf = Fluent::TimeFormatter.new(f, @localtime)
        @time_format_proc = tf.method(:format)
        @time_parse_proc = Proc.new {|str| Time.strptime(str, f).to_i }
      else
        @time_format_proc = Proc.new {|time| time.to_s }
        @time_parse_proc = Proc.new {|str| str.to_i }
      end
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
      if @message
        messages << create_formatted_message(tag, time, record)
      else
        messages << create_key_value_message(tag, time, record)
      end
      subjects << create_formatted_subject(tag, time, record)
    }

    messages.each_with_index do |msg, i|
      subject = subjects[i]
      begin
        res = sendmail(subject, msg)
      rescue
        $log.warn "out_mail: failed to send notice to #{@host}:#{@port}, subject: #{subject}, message: #{msg}"
      end
    end

    chain.next
  end

  def format(tag, time, record)
    "#{Time.at(time).strftime('%Y/%m/%d %H:%M:%S')}\t#{tag}\t#{record.to_json}\n"
  end

  def create_key_value_message(tag, time, record)
    values = []

    @out_keys.each do |key|
      case key
      when @time_key
        values << @time_format_proc.call(time)
      when @tag_key
        values << tag
      else
        values << "#{key}: #{record[key].to_s}"
      end
    end

    values.join("\n")
  end

  def create_formatted_message(tag, time, record)
    values = []

    values = @message_out_keys.map do |key|
      case key
      when @time_key
        @time_format_proc.call(time)
      when @tag_key
        tag
      else
        record[key].to_s
      end
    end

    (@message % values).gsub(/\\n/, "\n")
  end

  def create_formatted_subject(tag, time, record)
    values = []

    values = @subject_out_keys.map do |key|
      case key
      when @time_key
        @time_format_proc.call(time)
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
      smtp.start(@domain,@user,@password,:plain)
    else
      smtp.start
    end

    subject = subject.force_encoding('binary')
    body = msg.force_encoding('binary')

    smtp.send_mail(<<EOS, @from, @to.split(/,/))
Date: #{Time::now.strftime("%a, %d %b %Y %X %z")}
From: #{@from}
To: #{@to}
Subject: #{subject}
Mime-Version: 1.0
Content-Type: text/plain; charset=utf-8

#{body}
EOS
    smtp.finish
  end

end

