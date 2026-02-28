shutdownhooks_test_sources = files(
  './TestShutdownHooks.vala'
)

shutdownhooks_test_sources += valacore_sources

test_unit = 'ShutdownHooks-test'

exe = executable(test_unit,
                 sources: shutdownhooks_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
