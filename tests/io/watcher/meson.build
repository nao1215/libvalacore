watcher_test_sources = files(
  './TestWatcher.vala'
)

watcher_test_sources += valacore_sources

test_unit = 'Watcher-test'

exe = executable(test_unit,
                 sources: watcher_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
