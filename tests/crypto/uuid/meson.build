test_name = meson.project_name() + '-test'

uuid_test_sources = files(
  './TestUuid.vala'
)

uuid_test_sources += valacore_sources

test_unit = 'Uuid-test'

exe = executable(test_unit,
                 sources: uuid_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
