$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'web_scraping_helper'

require 'minitest/autorun'
require 'minitest/reporters'
require 'minitest/power_assert'
require 'webmock/minitest'

MiniTest::Reporters.use!
