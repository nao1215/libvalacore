resource_test_sources = files(
  './TestResource.vala'
)

resource_test_sources += valacore_sources

test_unit = 'Resource-test'

exe = executable(test_unit,
                 sources: resource_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
