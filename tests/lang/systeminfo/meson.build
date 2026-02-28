test_name = meson.project_name() + '-test'

systeminfo_test_sources = files(
  './TestSystemInfo.vala'
)

systeminfo_test_sources += valacore_sources

test_unit = 'SystemInfo-test'

exe = executable(test_unit,
                 sources: systeminfo_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
