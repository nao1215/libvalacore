test_name = meson.project_name() + '-test'

stopwatch_test_sources = files(
  './TestStopwatch.vala'
)

stopwatch_test_sources += valacore_sources

test_unit = 'Stopwatch-test'

exe = executable(test_unit,
                 sources: stopwatch_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
