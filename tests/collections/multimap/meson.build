multimap_test_sources = files(
  './TestMultiMap.vala'
)

multimap_test_sources += valacore_sources

test_unit = 'MultiMap-test'

exe = executable(test_unit,
                 sources: multimap_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
