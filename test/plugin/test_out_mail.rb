require_relative '../helper'
require 'fluent/test/driver/output'

class MailOutputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end

  CONFIG_OUT_KEYS = %[
    out_keys tag,time,value
    time_key time
    time_format %Y/%m/%d %H:%M:%S
    tag_key tag
    subject Fluentd Notification Alarm %s
    subject_out_keys tag
    host localhost
    port 25
    from localhost@localdomain
    to localhost@localdomain
  ]

  CONFIG_CC_BCC = %[
    out_keys tag,time,value
    time_key time
    time_format %Y/%m/%d %H:%M:%S
    tag_key tag
    subject Fluentd Notification Alarm %s
    subject_out_keys tag
    host localhost
    port 25
    from localhost@localdomain
    cc localhost@localdomain
    bcc localhost@localdomain
  ]

  CONFIG_MESSAGE = %[
    message out_mail: %s [%s]\\n%s
    message_out_keys tag,time,value
    time_key time
    time_format %Y/%m/%d %H:%M:%S
    tag_key tag
    subject Fluentd Notification Alarm %s
    subject_out_keys tag
    host localhost
    port 25
    from localhost@localdomain
    to localhost@localdomain
  ]

  CONFIG_DEST_ADDR = %[
    out_keys tag,time,value
    time_key time
    time_format %Y/%m/%d %H:%M:%S
    tag_key tag
    subject Fluentd Notification Alarm %s
    subject_out_keys tag
    host localhost
    port 25
    from localhost@localdomain
    to_key to
    cc_key cc
    bcc_key bcc
  ]

  def create_driver(conf=CONFIG_OUT_KEYS)
    Fluent::Test::Driver::Output.new(Fluent::Plugin::MailOutput).configure(conf)
  end

  def test_configure
    d = create_driver(CONFIG_OUT_KEYS)
    assert_equal 'localhost', d.instance.host
    d = create_driver(CONFIG_CC_BCC)
    assert_equal 'localhost', d.instance.host
    d = create_driver(CONFIG_MESSAGE)
    assert_equal 'localhost', d.instance.host
  end

  def test_out_keys
    d = create_driver(CONFIG_OUT_KEYS)
    time = Time.now.to_i
    d.run(default_tag: 'test') do
      d.feed(time, {'value' => "out_keys mail from fluentd out_mail"})
    end
  end

  def test_message
    d = create_driver(CONFIG_MESSAGE)
    time = Time.now.to_i
    d.run(default_tag: 'test') do
      d.feed(time, {'value' => "message mail from fluentd out_mail"})
    end
  end

  def test_dest_addr
    d = create_driver(CONFIG_DEST_ADDR)
    time = Time.now.to_i
    d.run(default_tag: 'test') do
      d.feed(time, {
        'value' => "message mail from fluentd out_mail",
        'to' => "localhost@localdomain",
        'cc' => "localhost@localdomain",
        'bcc' => "localhost@localdomain",
        })
    end
  end

  def test_with_scrub
    d = create_driver(CONFIG_MESSAGE)
    invalid_string = "\xff".force_encoding('UTF-8')
    assert_nothing_raised {
      res = d.instance.with_scrub(invalid_string) {|str| str.gsub(/\\n/, "\n") }
      assert_equal '?', res
    }
  end
end
