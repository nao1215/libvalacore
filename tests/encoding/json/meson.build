json_test_sources = files(
  './TestJson.vala'
)

json_test_sources += valacore_sources

test_unit = 'Json-test'

exe = executable(test_unit,
                 sources: json_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
