bufferedwriter_test_sources = files(
  './TestBufferedWriter.vala'
)

bufferedwriter_test_sources += valacore_sources

test_unit = 'BufferedWriter-test'

exe = executable(test_unit,
                 sources: bufferedwriter_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
