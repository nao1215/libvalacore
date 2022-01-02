test_name = meson.project_name() + '-test'

test_sources = files(
  './UnitTests.vala',
  './io/TestObjects.vala'
)

test_sources += core_sources

test_unit = 'unit-test'

test_deps = [dependency('glib-2.0'),
        dependency('gobject-2.0')]

exe = executable(test_unit,
                 sources: test_sources,
                 dependencies : test_deps,
                 install: false)
test(test_unit, exe)