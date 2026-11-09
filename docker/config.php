<?php  // Moodle configuration file — lido a partir de variáveis de ambiente (Coolify)

unset($CFG);
global $CFG;
$CFG = new stdClass();

$env = static function (string $name, ?string $default = null): ?string {
    $value = getenv($name);
    return ($value === false || $value === '') ? $default : $value;
};

$CFG->dbtype    = $env('MOODLE_DB_TYPE', 'pgsql');
$CFG->dblibrary = 'native';
$CFG->dbhost    = $env('MOODLE_DB_HOST', 'db');
$CFG->dbname    = $env('MOODLE_DB_NAME', 'moodle');
$CFG->dbuser    = $env('MOODLE_DB_USER', 'moodle');
$CFG->dbpass    = $env('MOODLE_DB_PASSWORD', '');
$CFG->prefix    = $env('MOODLE_DB_PREFIX', 'mdl_');
$CFG->dboptions = [
    'dbpersist' => 0,
    'dbport'    => $env('MOODLE_DB_PORT', ''),
    'dbsocket'  => '',
];

$CFG->wwwroot   = rtrim((string) $env('MOODLE_URL', 'http://localhost'), '/');
$CFG->dataroot  = $env('MOODLE_DATA', '/var/www/moodledata');
$CFG->admin     = 'admin';
$CFG->directorypermissions = 02777;

// O Apache já tem "FallbackResource /r.php" configurado.
$CFG->routerconfigured = true;

// Atrás do proxy do Coolify (Traefik) o HTTPS termina no proxy.
if (str_starts_with($CFG->wwwroot, 'https://')) {
    $CFG->sslproxy = true;
}

// Caminhos de ferramentas instaladas na imagem.
$CFG->pathtogs = '/usr/bin/gs';

require_once(__DIR__ . '/lib/setup.php'); // Do not edit
