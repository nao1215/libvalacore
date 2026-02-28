once_test_sources = files(
  './TestOnce.vala'
)

once_test_sources += valacore_sources

test_unit = 'Once-test'

exe = executable(test_unit,
                 sources: once_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
