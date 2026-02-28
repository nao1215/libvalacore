scanner_test_sources = files(
  './TestScanner.vala'
)

scanner_test_sources += valacore_sources

test_unit = 'Scanner-test'

exe = executable(test_unit,
                 sources: scanner_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
