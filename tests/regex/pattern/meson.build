pattern_test_sources = files(
  './TestPattern.vala'
)

pattern_test_sources += valacore_sources

test_unit = 'Pattern-test'

exe = executable(test_unit,
                 sources: pattern_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
