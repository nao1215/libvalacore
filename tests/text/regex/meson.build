test_name = meson.project_name() + '-test'

regex_test_sources = files(
  './TestRegex.vala'
)

regex_test_sources += valacore_sources

test_unit = 'Regex-test'

exe = executable(test_unit,
                 sources: regex_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
