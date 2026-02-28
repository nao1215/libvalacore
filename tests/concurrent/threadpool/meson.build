threadpool_test_sources = files(
  './TestThreadPool.vala'
)

threadpool_test_sources += valacore_sources

test_unit = 'ThreadPool-test'

exe = executable(test_unit,
                 sources: threadpool_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
