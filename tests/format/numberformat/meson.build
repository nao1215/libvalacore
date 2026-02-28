test_name = meson.project_name() + '-test'

numberformat_test_sources = files(
  './TestNumberFormat.vala'
)

numberformat_test_sources += valacore_sources

test_unit = 'NumberFormat-test'

exe = executable(test_unit,
                 sources: numberformat_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
