future_test_sources = files(
  './TestFuture.vala'
)

future_test_sources += valacore_sources

test_unit = 'Future-test'

exe = executable(test_unit,
                 sources: future_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
