retry_test_sources = files(
  './TestRetry.vala'
)

retry_test_sources += valacore_sources

test_unit = 'Retry-test'

exe = executable(test_unit,
                 sources: retry_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
