hashmap_test_sources = files(
  './TestHashMap.vala'
)

hashmap_test_sources += valacore_sources

test_unit = 'HashMap-test'

exe = executable(test_unit,
                 sources: hashmap_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
