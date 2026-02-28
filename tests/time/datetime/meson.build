datetime_test_sources = files(
  './TestDateTime.vala'
)

datetime_test_sources += valacore_sources

test_unit = 'DateTime-test'

exe = executable(test_unit,
                 sources: datetime_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
