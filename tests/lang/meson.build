test_name = meson.project_name() + '-test'

os_test_sources = files(
  './TestOs.vala',
)

os_test_sources += valacore_sources
os_test_unit = 'Os-test'

exe = executable(os_test_unit,
                 sources: os_test_sources,
                 dependencies : dependencies,
                 install: false)
test(os_test_unit, exe)