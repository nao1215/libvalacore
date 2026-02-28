test_name = meson.project_name() + '-test'

pair_test_sources = files(
  './TestPair.vala'
)

pair_test_sources += valacore_sources

test_unit = 'Pair-test'

exe = executable(test_unit,
                 sources: pair_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
