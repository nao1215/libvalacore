hyperloglog_test_sources = files(
  './TestHyperLogLog.vala'
)

hyperloglog_test_sources += valacore_sources

test_unit = 'HyperLogLog-test'

exe = executable(test_unit,
                 sources: hyperloglog_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
