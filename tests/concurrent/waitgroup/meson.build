waitgroup_test_sources = files(
  './TestWaitGroup.vala'
)

waitgroup_test_sources += valacore_sources

test_unit = 'WaitGroup-test'

exe = executable(test_unit,
                 sources: waitgroup_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
