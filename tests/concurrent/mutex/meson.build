test_name = meson.project_name() + '-test'

mutex_test_sources = files(
  './TestMutex.vala'
)

mutex_test_sources += valacore_sources

test_unit = 'Mutex-test'

exe = executable(test_unit,
                 sources: mutex_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
