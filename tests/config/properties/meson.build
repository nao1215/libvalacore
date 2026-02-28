test_name = meson.project_name() + '-test'

properties_test_sources = files(
  './TestProperties.vala'
)

properties_test_sources += valacore_sources

test_unit = 'Properties-test'

exe = executable(test_unit,
                 sources: properties_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
