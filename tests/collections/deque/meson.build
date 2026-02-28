test_name = meson.project_name() + '-test'

deque_test_sources = files(
  './TestDeque.vala'
)

deque_test_sources += valacore_sources

test_unit = 'Deque-test'

exe = executable(test_unit,
                 sources: deque_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
