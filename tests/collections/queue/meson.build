test_name = meson.project_name() + '-test'

queue_test_sources = files(
  './TestQueue.vala'
)

queue_test_sources += valacore_sources

test_unit = 'Queue-test'

exe = executable(test_unit,
                 sources: queue_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
