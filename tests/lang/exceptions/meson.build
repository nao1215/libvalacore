exceptions_test_sources = files(
  './TestExceptions.vala'
)

exceptions_test_sources += valacore_sources

test_unit = 'Exceptions-test'

exe = executable(test_unit,
                 sources: exceptions_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
