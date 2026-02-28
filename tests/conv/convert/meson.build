convert_test_sources = files(
  './TestConvert.vala'
)

convert_test_sources += valacore_sources

test_unit = 'Convert-test'

exe = executable(test_unit,
                 sources: convert_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
