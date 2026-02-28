test_name = meson.project_name() + '-test'

threads_test_sources = files(
  './TestThreads.vala'
)

threads_test_sources += valacore_sources

test_unit = 'Threads-test'

exe = executable(test_unit,
                 sources: threads_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
