appconfig_test_sources = files(
  './TestAppConfig.vala'
)

appconfig_test_sources += valacore_sources

test_unit = 'AppConfig-test'

exe = executable(test_unit,
                 sources: appconfig_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
