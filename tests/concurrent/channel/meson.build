channel_test_sources = files(
  './TestChannel.vala'
)

channel_test_sources += valacore_sources

test_unit = 'Channel-test'

exe = executable(test_unit,
                 sources: channel_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
