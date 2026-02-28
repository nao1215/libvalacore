test_name = meson.project_name() + '-test'

hashset_test_sources = files(
  './TestHashSet.vala'
)

hashset_test_sources += valacore_sources

test_unit = 'HashSet-test'

exe = executable(test_unit,
                 sources: hashset_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
