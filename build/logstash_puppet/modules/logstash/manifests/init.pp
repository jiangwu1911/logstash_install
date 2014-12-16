class logstash {
    package { 'logstash':
        ensure => installed,
        allow_virtual => false,
    }
    package { 'logstash-contrib':
        ensure => installed,
        allow_virtual => false,
    }
    package { 'elasticsearch':
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
#        start => '/usr/sbin/service logstash start',
#        stop => '/usr/sbin/service logstash stop',
#        restart => '/usr/sbin/service logstash restart',
#        status => '/usr/sbin/service logstash status',
#    }
#    service { 'logstash-web':
#        ensure => running,
#        enable => true,
#        require => Package['logstash'],
#        start => '/usr/sbin/service logstash-web start',
#        stop => '/usr/sbin/service logstash-web stop',
#        restart => '/usr/sbin/service logstash-web restart',
#        status => '/usr/sbin/service logstash-web status',
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
#        notify => Service['logstash'],
    }
    file { '/etc/redis.conf':
        source => 'puppet:///modules/logstash/redis.conf',
        notify => Service['redis'],
    }
}
