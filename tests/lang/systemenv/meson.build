test_name = meson.project_name() + '-test'

systemenv_test_sources = files(
  './TestSystemEnv.vala'
)

systemenv_test_sources += valacore_sources

test_unit = 'SystemEnv-test'

exe = executable(test_unit,
                 sources: systemenv_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
