priorityqueue_test_sources = files(
  './TestPriorityQueue.vala'
)

priorityqueue_test_sources += valacore_sources

test_unit = 'PriorityQueue-test'

exe = executable(test_unit,
                 sources: priorityqueue_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
