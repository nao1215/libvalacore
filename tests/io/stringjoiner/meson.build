stringjoiner_test_sources = files(
  './TestStringJoiner.vala'
)

stringjoiner_test_sources += valacore_sources

test_unit = 'StringJoiner-test'

exe = executable(test_unit,
                 sources: stringjoiner_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
