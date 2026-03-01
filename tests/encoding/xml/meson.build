xml_test_sources = files(
  './TestXml.vala'
)

xml_test_sources += valacore_sources

test_unit = 'Xml-test'

exe = executable(test_unit,
                 sources: xml_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
