test_name = meson.project_name() + '-test'

preconditions_test_sources = files(
  './TestPreconditions.vala'
)

preconditions_test_sources += valacore_sources

test_unit = 'Preconditions-test'

exe = executable(test_unit,
                 sources: preconditions_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
