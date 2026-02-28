test_name = meson.project_name() + '-test'

semaphore_test_sources = files(
  './TestSemaphore.vala'
)

semaphore_test_sources += valacore_sources

test_unit = 'Semaphore-test'

exe = executable(test_unit,
                 sources: semaphore_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
