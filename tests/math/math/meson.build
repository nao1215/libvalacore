math_test_sources = files(
  './TestMath.vala'
)

math_test_sources += valacore_sources

test_unit = 'Math-test'

exe = executable(test_unit,
                 sources: math_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
