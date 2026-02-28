test_name = meson.project_name() + '-test'

triple_test_sources = files(
  './TestTriple.vala'
)

triple_test_sources += valacore_sources

test_unit = 'Triple-test'

exe = executable(test_unit,
                 sources: triple_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
