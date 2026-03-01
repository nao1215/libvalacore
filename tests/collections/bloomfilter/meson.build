bloomfilter_test_sources = files(
  './TestBloomFilter.vala'
)

bloomfilter_test_sources += valacore_sources

test_unit = 'BloomFilter-test'

exe = executable(test_unit,
                 sources: bloomfilter_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
