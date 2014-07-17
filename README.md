# Fluent::Plugin::Mail, a plugin for [Fluentd](http://fluentd.org)


## Installation

Add this line to your application's Gemfile:

    gem 'fluent-plugin-mail'

Or install it yourself as:

    $ gem install fluent-plugin-mail

Or use td-agent : (on Ubuntu12.04)

    $ sudo /usr/lib/fluent/ruby/bin/fluent-gem install fluent-plugin-mail


##  Mail Configuration with out_keys (no auth)

    <match **>
      type mail
      host SMTPSERVER
      port 25
      from SOURCE
      to DEST1,DEST2,DEST3
      subject SUBJECT: %s
      subject_out_keys target_tag
      out_keys target_tag,pattern,value
      time_locale UTC # optional
    </match>

Email is sent like

    From: SOURCE
    To: DEST1,DEST2,DEST3
    Subject: SUBJECT: #{target_tag}
    Mime-Version: 1.0
    Content-Type: text/plain; charset=utf-8

    target_tag: #{target_tag}
    pattern: #{pattern}
    value: #{value}

## Mail Configuration with Message Format (no auth)

You may use `message` parameter to define mail format as you like. Use `\n` to put a return code.

    <match **>
      type mail
      host SMTPSERVER
      port 25
      from SOURCE
      to DEST1,DEST2,DEST3
      subject SUBJECT: %s
      subject_out_keys target_tag
      message %s %s\n%s
      message_out_keys target_tag,pattern,value
      time_locale UTC # optional
    </match>

Email is sent like

    From: SOURCE
    To: DEST1,DEST2,DEST3
    Subject: SUBJECT: #{target_tag}
    Mime-Version: 1.0
    Content-Type: text/plain; charset=utf-8

    #{target_tag} #{pattern}
    #{value}

## Mail Configuration for Gmail(use STARTTLS)

    <match **>
      type mail
      host smtp.gmail.com
      port 587
      domain gmail.com
      from SOURCE
      to DEST1,DEST2,DEST3
      subject SUBJECT
      user USERNAME( ex. hoge@gmail.com)
      password PASSWORD
      enable_starttls_auto true
      enable_tls false
      out_keys target_tag,pattern,value
      time_locale UTC # optional
    </match>



## Usage Sample

### SingleNode's syslog check

use fluent_plugin_notifier(https://github.com/tagomoris/fluent-plugin-notifier)

    $ gem install fluent-plugin-notifier

configure td-agent.conf for single node

    <source>
      type tail
      tag syslog
      path /var/log/syslog
    </source>
    <match syslog**>
      type notifier
      <def>
        pattern check_syslog
        check string_find
        warn_regexp .*warn.*
        crit_regexp .*crit.*
        target_key_pattern message
      </def>
      <def>
        pattern check_syslog
        check string_find
        warn_regexp .*Error.*
        crit_regexp .*Down.*
        target_key_pattern message
      </def>
    </match>
    <match notification**>
      type mail
      host MAILSERVER
      port MAILSERVER_PORT
      domain DOMAIN
      from SOURCE_MAIL_ADDRESS
      to DESTINATION_MAIL_ADDRESS
      subject SUBJECT
      out_keys target_tag, pattern, value, message_time
    </match>


### MulatiNode's syslog check

use config_expander(https://github.com/tagomoris/fluent-plugin-config-expander)

    $ gem install fluent-plugin-config-expander



source node("/etc/td-agent/td-agent.conf")

    <source>
      type config_expander
      <config>
        type tail
        format syslog
        path /var/log/syslog
        tag syslog.${hostname}
        pos_file /tmp/syslog.pos
      </config>
    </source>a
    <match **>
      type forward
      <server>
        host HOST_ADDRESS
      </server>
    </match>


log server("/etc/td-agent/td-agent.conf")

    <source>
      type forward
    </source>
    <match syslog**>
      type copy
      <store>
        type file
        path /var/log-server/syslog
      </store>
      <store>
        type notifier
        <def>
          pattern check_syslog
          check string_find
          warn_regexp .*warn.*
          crit_regexp .*crit.*
          target_key_pattern message
        </def>
      </store>
    </match>
    <match notification**>
      type mail
      host MAILSERVER
      port MAILSERVER_PORT
      domain DOMAIN
      from SOURCE_MAIL_ADDRESS
      to DESTINATION_MAIL_ADDRESS
      subject SUBJECT
      outkeys target_tag, pattern, value
      time_locale UTC # optional
    </match>



## TODO

* add config "mail_text_format"

## Copyright

* Copyright
  * Copyright (c) 2012- Yuichi UEMURA
  * License
    * Apache License, Version 2.0
