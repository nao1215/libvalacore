context_test_sources = files(
  './TestContext.vala'
)

context_test_sources += valacore_sources

test_unit = 'Context-test'

exe = executable(test_unit,
                 sources: context_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
