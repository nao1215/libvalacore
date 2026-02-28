test_name = meson.project_name() + '-test'

stack_test_sources = files(
  './TestStack.vala'
)

stack_test_sources += valacore_sources

test_unit = 'Stack-test'

exe = executable(test_unit,
                 sources: stack_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
