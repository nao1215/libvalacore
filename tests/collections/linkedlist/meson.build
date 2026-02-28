linkedlist_test_sources = files(
  './TestLinkedList.vala'
)

linkedlist_test_sources += valacore_sources

test_unit = 'LinkedList-test'

exe = executable(test_unit,
                 sources: linkedlist_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
