test_name = meson.project_name() + '-test'

hash_test_sources = files(
  './TestHash.vala'
)

hash_test_sources += valacore_sources

test_unit = 'Hash-test'

exe = executable(test_unit,
                 sources: hash_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
