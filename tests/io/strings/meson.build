test_name = meson.project_name() + '-test'

strings_test_sources = files(
  './TestStrings.vala'
)

strings_test_sources += valacore_sources

test_unit = 'Strings-test'

exe = executable(test_unit,
                 sources: strings_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)