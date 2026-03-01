cron_test_sources = files(
  './TestCron.vala'
)

cron_test_sources += valacore_sources

test_unit = 'Cron-test'

exe = executable(test_unit,
                 sources: cron_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
