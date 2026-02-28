project('valacore', 'vala', 'c',
  version: '0.1.0',
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

# Derive API_VERSION from git tag (e.g. v0.1.0 -> 0.1.0), fallback to project version
git = find_program('git', required: false)
if git.found()
  git_ver = run_command(git, 'describe', '--tags', '--abbrev=0', check: false)
  if git_ver.returncode() == 0
    _raw = git_ver.stdout().strip()
    if _raw.startswith('v')
      API_VERSION = _raw.substring(1)
    else
      API_VERSION = _raw
    endif
  else
    API_VERSION = meson.project_version()
  endif
else
  API_VERSION = meson.project_version()
endif
vapidir = get_option('datadir') / 'vala' / 'vapi'

add_project_arguments(['--enable-experimental'], language: 'vala')

g_ir_compiler = find_program('g-ir-compiler', required: false)

subdir('src')
subdir('tests')

setup_unittest= find_program('scripts/setupUnitTest.sh')
run_command(setup_unittest, check: true)
