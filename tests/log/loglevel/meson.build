test_name = meson.project_name() + '-test'

loglevel_test_sources = files(
  './TestLogLevel.vala'
)

loglevel_test_sources += valacore_sources

test_unit = 'LogLevel-test'

exe = executable(test_unit,
                 sources: loglevel_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
