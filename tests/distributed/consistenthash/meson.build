consistenthash_test_sources = files(
  './TestConsistentHash.vala'
)

consistenthash_test_sources += valacore_sources

test_unit = 'ConsistentHash-test'

exe = executable(test_unit,
                 sources: consistenthash_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
