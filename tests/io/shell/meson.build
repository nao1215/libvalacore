shell_test_sources = files(
  './TestShell.vala'
)

shell_test_sources += valacore_sources

test_unit = 'Shell-test'

exe = executable(test_unit,
                 sources: shell_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
