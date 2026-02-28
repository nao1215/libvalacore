temp_test_sources = files(
  './TestTemp.vala'
)

temp_test_sources += valacore_sources

test_unit = 'Temp-test'

exe = executable(test_unit,
                 sources: temp_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
