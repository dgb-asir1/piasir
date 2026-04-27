<?php
/**
 * Plugin Name: Loopback Fix
 * Description: Redirige peticiones internas de 10.0.0.1:8080 a localhost:80
 *
 * WordPress tiene configurada su URL como http://10.0.0.1:8080 (IP externa),
 * pero desde dentro del contenedor Docker esa IP no es accesible.
 * Este plugin intercepta esas peticiones y las redirige a localhost:80,
 * que es donde Apache escucha dentro del contenedor.
 */

$target  = ['http://10.0.0.1:8080', 'https://10.0.0.1:8080'];
$replace = 'http://localhost:80';

/**
 * FILTRO 1: http_request_host_is_external
 *
 * Por defecto WordPress bloquea peticiones HTTP hacia IPs que considera
 * "externas" por seguridad. Este filtro le dice que 10.0.0.1 es una IP
 * de confianza y puede hacer peticiones hacia ella sin bloquearlas.
 *
 * Sin esto, WordPress cancelaría la petición antes de llegar al filtro 2.
 */
add_filter('http_request_host_is_external', function($is_external, $host) {
    if ($host === '10.0.0.1') return true;
    return $is_external;
}, 10, 2);

/**
 * FILTRO 2: pre_http_request
 *
 * Se ejecuta ANTES de cada petición HTTP que hace WordPress.
 * Si la URL va a 10.0.0.1:8080, la reescribe a localhost:80 y
 * ejecuta la petición corregida. Si la URL es otra, no hace nada.
 *
 * El flag $processing evita recursión infinita: cuando este filtro
 * llama a wp_remote_request(), WordPress volvería a disparar este
 * mismo filtro. El flag detecta que ya estamos procesando y lo omite.
 *
 * redirection => 0 evita que si Apache responde con un redirect hacia
 * 10.0.0.1:8080, WordPress entre en bucle siguiéndolo.
 */
add_filter('pre_http_request', function($preempt, $args, $url) use ($target, $replace) {
    static $processing = false;

    if ($processing) return $preempt;

    if (strpos($url, $target[0]) !== 0 && strpos($url, $target[1]) !== 0) return $preempt;

    $processing = true;
    $args['redirection'] = 0;
    $response = wp_remote_request(str_replace($target, $replace, $url), $args);
    $processing = false;

    return $response;
}, 10, 3);