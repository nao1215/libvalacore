template_test_sources = files(
  './TestTemplate.vala'
)

template_test_sources += valacore_sources

test_unit = 'Template-test'

exe = executable(test_unit,
                 sources: template_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
