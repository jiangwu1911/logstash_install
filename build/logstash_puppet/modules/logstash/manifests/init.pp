class logstash {
    package { ['logstash', 
               'logstash-contrib',
               'elasticsearch]:
        ensure => installed,
        allow_virtual => false,
    }

    service { 'redis':
        ensure => running,
        enable => true,
    }
#    service { 'logstash':
#        ensure => running,
#        enable => true,
#        require => Package['logstash'],
#    }
#    service { 'logstash-web':
#        ensure => running,
#        enable => true,
#        require => Package['logstash'],
#    }
    service { 'elasticsearch':
        ensure => running,
        enable => true,
        require => Package['elasticsearch'],
    }

    file { '/etc/elasticsearch/elasticsearch.yml':
        source => 'puppet:///modules/logstash/elasticsearch.yml',
        notify => Service['elasticsearch'],
    }
    file { '/etc/logstash/conf.d/central.conf':
        source => 'puppet:///modules/logstash/central.conf',
    }
    file { '/etc/init.d/logstash':
        source => 'puppet:///modules/logstash/logstash',
    }
    file { '/etc/init.d/logstash-web':
        source => 'puppet:///modules/logstash/logstash-web',
    }
    file { '/etc/redis.conf':
        source => 'puppet:///modules/logstash/redis.conf',
        notify => Service['redis'],
    }
}
