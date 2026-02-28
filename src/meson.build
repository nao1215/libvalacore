conf = configuration_data()
conf.set('prefix', get_option('prefix'))
conf.set('libdir', get_option ('libdir'))
conf.set('PROJECT_NAME', 'valacore')
conf.set('PROJECT_VERSION', '0.0.1')
conf.set('API_VERSION', API_VERSION)

valacore_sources = files([
  'collections/ArrayList.vala',
  'collections/BitSet.vala',
  'collections/Deque.vala',
  'collections/HashMap.vala',
  'collections/HashSet.vala',
  'collections/LinkedList.vala',
  'collections/Optional.vala',
  'collections/Pair.vala',
  'collections/PriorityQueue.vala',
  'collections/Queue.vala',
  'collections/Result.vala',
  'collections/Stack.vala',
  'collections/TreeMap.vala',
  'collections/Triple.vala',
  'crypto/Hash.vala',
  'encoding/Base64.vala',
  'encoding/Hex.vala',
  'encoding/Url.vala',
  'io/BufferedReader.vala',
  'io/BufferedWriter.vala',
  'io/Files.vala',
  'io/Path.vala',
  'io/Scanner.vala',
  'io/StringBuilder.vala',
  'io/StringJoiner.vala',
  'io/Strings.vala',
  'lang/Os.vala',
  'lang/Objects.vala',
  'parser/ArgParser.vala'
])

libvalacore = library('valacore-' + API_VERSION,
  valacore_sources,
  vala_header: 'valacore.h',
  vala_vapi: 'valacore-' + API_VERSION + '.vapi',
  vala_gir: 'Valacore-' + API_VERSION + '.gir',
  dependencies : dependencies,
  vala_args: [
    '--abi-stability'
    ],
  install: true,
  install_dir: [
    true,
    get_option('includedir') / 'valacore-' + API_VERSION / 'valacore',
    vapidir,
    g_ir_compiler.found()
  ]
)

if g_ir_compiler.found()
  custom_target('libvalacore-typelib',
    command: [
      g_ir_compiler,
      '--shared-library', 'libvalacore-@0@.so'.format (API_VERSION),
      '--output', '@OUTPUT@',
      meson.current_build_dir() / 'Valacore-' + API_VERSION + '.gir'
    ],
    output: 'Valacore-' + API_VERSION + '.typelib',
    depends: libvalacore,
    install: true,
    install_dir: join_paths(get_option('libdir'), 'girepository-1.0'))
endif

pkgconfig.generate(libvalacore,
  subdirs: 'valacore-' + API_VERSION,
  version: API_VERSION,
  name: 'valacore',
  filebase: 'valacore-' + API_VERSION,
  requires: PKGCONFIG_DEPS,
  description: 'libvalacore is basic library for vala language.')

if get_option('enable_valadoc')
  valadoc = find_program('valadoc')
  valacore_docs = custom_target('valacore_apidocs',
    input: valacore_sources,
    install: true,
    install_dir: get_option('datadir') / 'devhelp' / 'books',
    command: [
      valadoc,
      '-o', meson.current_build_dir() / 'Valacore-' + API_VERSION,
      '--doclet',
      'devhelp',
      '--pkg=posix',
      '--pkg=gio-2.0',
      '--package-name=Valacore',
      '--package-version=' + API_VERSION,
      '--wiki=' + meson.project_source_root() / 'docs' / 'wiki',
      '@INPUT@',
      '--force'
    ],
    output: 'Valacore-' + API_VERSION)

  install_subdir(meson.current_build_dir() / 'Valacore-' + API_VERSION / 'Valacore-' + API_VERSION,
    install_dir: get_option('datadir') / 'devhelp' / 'books')
endif
