immutablelist_test_sources = files(
  './TestImmutableList.vala'
)

immutablelist_test_sources += valacore_sources

test_unit = 'ImmutableList-test'

exe = executable(test_unit,
                 sources: immutablelist_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
