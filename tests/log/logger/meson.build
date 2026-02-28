logger_test_sources = files(
  './TestLogger.vala'
)

logger_test_sources += valacore_sources

test_unit = 'Logger-test'

exe = executable(test_unit,
                 sources: logger_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
