require 'helper'

class MailOutputTest < Test::Unit::TestCase


  CONFIG = %[
    message out_mail: %s [%s] %s
    out_keys tag,time,value
    time_key time
    time_format %Y/%m/%d %H:%M:%S
    tag_key tag
    subject Fluentd Notification Alerm
    host localhost
    port 25
    from localhost@localdomain
    to localhost@localdomain
  ]

  def create_driver(conf=CONFIG,tag='test')
    Fluent::Test::OutputTestDriver.new(Fluent::MailOutput, tag).configure(conf)
  end

  def test_configure
  end

  def test_notice
    d = create_driver
    time = Time.now.to_i
    d.run do
      d.emit({'value' => "message from fluentd out_mail: testing now"}, time)
    end
  end

end

