test_name = meson.project_name() + '-test'

bitset_test_sources = files(
  './TestBitSet.vala'
)

bitset_test_sources += valacore_sources

test_unit = 'BitSet-test'

exe = executable(test_unit,
                 sources: bitset_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
