randoms_test_sources = files(
  './TestRandoms.vala'
)

randoms_test_sources += valacore_sources

test_unit = 'Randoms-test'

exe = executable(test_unit,
                 sources: randoms_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
