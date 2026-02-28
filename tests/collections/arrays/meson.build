arrays_test_sources = files(
  './TestArrays.vala'
)

arrays_test_sources += valacore_sources

test_unit = 'Arrays-test'

exe = executable(test_unit,
                 sources: arrays_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
