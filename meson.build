project('core', 'vala', 'c',
  version: '0.0.1',
  license:'Apache License 2.0')

dependencies = [
  dependency('glib-2.0'),
  dependency('gobject-2.0')
]

pkgconfig = import('pkgconfig')

PKGCONFIG_DEPS = ['glib-2.0', 'gobject-2.0']
API_VERSION = '0.1'
vapidir = get_option('datadir') / 'vala' / 'vapi'

add_project_arguments(['--enable-experimental'], language: 'vala')

g_ir_compiler = find_program('g-ir-compiler', required: false)

subdir('src')
subdir('tests')