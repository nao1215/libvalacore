test_name = meson.project_name() + '-test'

systemproperties_test_sources = files(
  './TestSystemProperties.vala'
)

systemproperties_test_sources += valacore_sources

test_unit = 'SystemProperties-test'

exe = executable(test_unit,
                 sources: systemproperties_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
