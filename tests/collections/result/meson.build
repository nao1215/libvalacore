test_name = meson.project_name() + '-test'

result_test_sources = files(
  './TestResult.vala'
)

result_test_sources += valacore_sources

test_unit = 'Result-test'

exe = executable(test_unit,
                 sources: result_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
