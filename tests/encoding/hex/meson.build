test_name = meson.project_name() + '-test'

hex_test_sources = files(
  './TestHex.vala'
)

hex_test_sources += valacore_sources

test_unit = 'Hex-test'

exe = executable(test_unit,
                 sources: hex_test_sources,
                 dependencies : dependencies,
                 install: false)
test(test_unit, exe)
