lrucache_test_sources = files(
  './TestLruCache.vala'
)

lrucache_test_sources += valacore_sources

test_unit = 'LruCache-test'

exe = executable(test_unit,
                 sources: lrucache_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
