threadpool2_test_sources = files(
  './TestThreadPool2.vala'
)

threadpool2_test_sources += valacore_sources

test_unit = 'ThreadPool2-test'

exe = executable(test_unit,
                 sources: threadpool2_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
