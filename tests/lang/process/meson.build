process_test_sources = files(
  './TestProcess.vala'
)

process_test_sources += valacore_sources

test_unit = 'Process-test'

exe = executable(test_unit,
                 sources: process_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
