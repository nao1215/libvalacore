zip_test_sources = files(
  './TestZip.vala'
)

zip_test_sources += valacore_sources

test_unit = 'Zip-test'

exe = executable(test_unit,
                 sources: zip_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
