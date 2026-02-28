test_name = meson.project_name() + '-test'

rwmutex_test_sources = files(
  './TestRWMutex.vala'
)

rwmutex_test_sources += valacore_sources

test_unit = 'RWMutex-test'

exe = executable(test_unit,
                 sources: rwmutex_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
