test_name = meson.project_name() + '-test'

objects_test_sources = files(
  './TestObjects.vala'
)

objects_test_sources += core_sources

test_unit = 'objects-test'

test_deps = [dependency('glib-2.0'),
        dependency('gobject-2.0')]

exe = executable(test_unit,
                 sources: objects_test_sources,
                 dependencies : test_deps,
                 install: false)
test(test_unit, exe)