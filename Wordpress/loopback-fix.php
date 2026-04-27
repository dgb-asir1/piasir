<?php
add_filter('http_request_host_is_external', '__return_true');

add_filter('pre_http_request', function($preempt, $args, $url) {
    if (strpos($url, 'http://10.0.0.1:8080') === 0) {
        $url = str_replace('http://10.0.0.1:8080', 'http://localhost:80', $url);
        return wp_remote_request($url, $args);
    }
    return $preempt;
}, 10, 3);