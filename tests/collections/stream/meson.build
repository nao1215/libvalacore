stream_test_sources = files(
  './TestStream.vala'
)

stream_test_sources += valacore_sources

test_unit = 'Stream-test'

exe = executable(test_unit,
                 sources: stream_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
