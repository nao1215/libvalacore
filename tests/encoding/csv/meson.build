csv_test_sources = files(
  './TestCsv.vala'
)

csv_test_sources += valacore_sources

test_unit = 'Csv-test'

exe = executable(test_unit,
                 sources: csv_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
