require 'helper'

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

  def create_driver(conf=CONFIG_OUT_KEYS,tag='test')
    Fluent::Test::BufferedOutputTestDriver.new(Fluent::MailOutput, tag).configure(conf)
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

  def test_with_scrub
    d = create_driver(CONFIG_MESSAGE)
    invalid_string = "\xff".force_encoding('UTF-8')
    assert_nothing_raised {
      res = d.instance.with_scrub(invalid_string) {|str| str.gsub(/\\n/, "\n") }
      assert_equal '?', res
    }
  end

  def test_squash_messages
    d = create_driver(CONFIG_MESSAGE)
    res = d.instance.squash_messages([1,2])
    assert_equal ["1\n2"], res
  end
end
