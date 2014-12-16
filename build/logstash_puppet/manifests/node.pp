node 'logstash' {
    package { 'logstash':
        ensure => installed,
    }
    package { 'logstash-contrib':
        ensure => installed,
    }
    package { 'elasticsearch':
        ensure => installed,
    }

    service { 'redis':
        ensure => running,
        enable => true,
    }
    service { 'logstash':
        ensure => running,
        enable => true,
        require => Package['logstash'],
        restart => '/usr/sbin/service logstash restart',
        status => '/usr/sbin/service logstash status',
    }
    service { 'logstash-web':
        ensure => running,
        enable => true,
        require => Package['logstash'],
        restart => '/usr/sbin/service logstash-web restart',
        status => '/usr/sbin/service logstash-web status',
    }
    service { 'elasticsearch':
        ensure => running,
        enable => true,
        require => Package['elasticsearch'],
    }
}
