# Fluent::Plugin::Mail


## Installation

Add this line to your application's Gemfile:

    gem 'fluent-plugin-mail'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install fluent-plugin-mail


## SingleNode Usage

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
      subject SUBJET
      outkeys target_tag, pattern, value, message_time
    </match>


## Multi Node Configuration for syslog

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
      subject SUBJET
      outkeys target_tag, pattern, value
    </match>


## TODO

* add config "mail_text_format"

## Copyright

* Copyright
  * Copyright (c) 2012- Yuichi UEMURA
  * License
    * Apache License, Version 2.0

