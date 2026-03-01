filetree_test_sources = files(
  './TestFileTree.vala'
)

filetree_test_sources += valacore_sources

test_unit = 'FileTree-test'

exe = executable(test_unit,
                 sources: filetree_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
