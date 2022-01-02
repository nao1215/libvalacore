conf = configuration_data()
conf.set('prefix', get_option('prefix'))
conf.set('libdir', get_option ('libdir'))
conf.set('PROJECT_NAME', 'core')
conf.set('PROJECT_VERSION', '0.0.1')
conf.set('API_VERSION', API_VERSION)

core_sources = files([
  'io/Path.vala',
  'io/Objects.vala'
  ])

libcore = library('core-' + API_VERSION,
  core_sources,
  vala_header: 'core.h',
  vala_vapi: 'core-' + API_VERSION + '.vapi',
  vala_gir: 'Core-' + API_VERSION + '.gir',
  dependencies : dependencies,
  vala_args: [
    '--abi-stability'
    ],
  install: true,
  install_dir: [
    true,
    get_option('includedir') / 'core-' + API_VERSION / 'core',
    vapidir,
    g_ir_compiler.found()
  ]
)

if g_ir_compiler.found()
  custom_target('libcore-typelib',
    command: [
      g_ir_compiler,
      '--shared-library', 'libcore-@0@.so'.format (API_VERSION),
      '--output', '@OUTPUT@',
      meson.current_build_dir() / 'Core-' + API_VERSION + '.gir'
    ],
    output: 'Core-' + API_VERSION + '.typelib',
    depends: libcore,
    install: true,
    install_dir: join_paths(get_option('libdir'), 'girepository-1.0'))
endif

pkgconfig.generate(libcore,
  subdirs: 'core-' + API_VERSION,
  version: API_VERSION,
  name: 'core',
  filebase: 'core-' + API_VERSION,
  requires: PKGCONFIG_DEPS,
  description: 'a library that does awesome things')

if get_option('enable_valadoc')
  valadoc = find_program('valadoc')
  core_docs = custom_target('core_apidocs',
    input: core_sources,
    install: true,
    # FIXME: Installing to tmp, so the target will be built
    #        the problem is we cannot access a subfolder of the
    #        buildtarget via the output parameter.
    #        Find a nicer solution
    install_dir: get_option('datadir') / 'devhelp' / 'books',
    command: [
      valadoc,
      '-o', meson.current_build_dir() / 'Core-' + API_VERSION,
      '--doclet',
      'devhelp',
      '@INPUT@',
      '--force'
    ],
    output: 'Core-' + API_VERSION)

  install_subdir(meson.current_build_dir() / 'Core-' + API_VERSION / 'Core-' + API_VERSION,
    install_dir: get_option('datadir') / 'devhelp' / 'books')
endif
