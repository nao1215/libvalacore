objects_test_sources = files(
  './TestObjects.vala'
)

objects_test_sources += valacore_sources

test_unit = 'Objects-test'

exe = executable(test_unit,
                 sources: objects_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)