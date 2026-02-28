test_name = meson.project_name() + '-test'

arraylist_test_sources = files(
  './TestArrayList.vala'
)

arraylist_test_sources += valacore_sources

test_unit = 'ArrayList-test'

exe = executable(test_unit,
                 sources: arraylist_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
