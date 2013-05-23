require 'helper'

class MailOutputTest < Test::Unit::TestCase

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

  def create_driver(conf=CONFIG_OUT_KEYS,tag='test')
    Fluent::Test::OutputTestDriver.new(Fluent::MailOutput, tag).configure(conf)
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
    d.run do
      d.emit({'value' => "out_keys mail from fluentd out_mail"}, time)
    end
  end

  def test_message
    d = create_driver(CONFIG_MESSAGE)
    time = Time.now.to_i
    d.run do
      d.emit({'value' => "message mail from fluentd out_mail"}, time)
    end
  end

end

