test_name = meson.project_name() + '-test'

treemap_test_sources = files(
  './TestTreeMap.vala'
)

treemap_test_sources += valacore_sources

test_unit = 'TreeMap-test'

exe = executable(test_unit,
                 sources: treemap_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
