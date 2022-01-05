project('valacore', 'vala', 'c',
  version: '0.0.1',
  license:'Apache License 2.0')

add_project_arguments([
        '-Wno-discarded-qualifiers',
        '-Wno-incompatible-pointer-types',
        '-Wno-unused',
        ],
        language: 'c',
)

valac = meson.get_compiler('vala')
posix_dep = valac.find_library('posix')

dependencies = [
  dependency('glib-2.0'),
  dependency('gio-2.0'),
  dependency('gobject-2.0'),
  meson.get_compiler('vala').find_library('linux'),
  meson.get_compiler('vala').find_library('posix'),
]

pkgconfig = import('pkgconfig')

PKGCONFIG_DEPS = ['glib-2.0', 'gobject-2.0', 'posix']
API_VERSION = '0.1.0'
vapidir = get_option('datadir') / 'vala' / 'vapi'

add_project_arguments(['--enable-experimental'], language: 'vala')

g_ir_compiler = find_program('g-ir-compiler', required: false)

subdir('src')
subdir('tests')

setup_unittest= find_program('scripts/setupUnitTest.sh')
run_command(setup_unittest)
