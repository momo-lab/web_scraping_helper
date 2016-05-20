require 'test_helper'
require 'tmpdir'
require 'fileutils'

class WebScrapingHelperTest < Minitest::Test
  def setup
    @tmpdir = File.expand_path("./web_scraping_helper", Dir.tmpdir)
    @target = WebScrapingHelper.new
    @target.wait_time = 0
  end

  def teardown
    FileUtils.rm_rf @tmpdir
  end

  def test_default_user_agent
    stub_request(:get, "http://example.com/path/to/1")
      .with(headers: { "User-Agent" => "Mozilla/5.0"})
    @target.get("http://example.com/path/to/1")
  end

  def test_custom_user_agent
    stub_request(:get, "http://example.com/path/to/1")
      .with(headers: { "User-Agent" => "my user agent"})
    @target.user_agent = "my user agent"
    @target.get("http://example.com/path/to/1")
  end

  def test_get
    stub_request(:get, "http://example.com/path/to/1")
      .to_return(
        headers: { "Content-Type" => "text/html; charset=UTF-8" },
        body: "abcde",
      )
    html = @target.get("http://example.com/path/to/1")
    assert{ html == "abcde" }
  end

  def test_get_custom_request_header
    stub_request(:get, "http://example.com/path/to/1")
      .with(headers: { "Connection" => "keep-alive"})
    @target.get("http://example.com/path/to/1",
                "Connection" => "keep-alive"
               )
  end

  def test_post
    stub_request(:post, "http://example.com/path/to/1")
      .with(body: {key1: "value1", key2: "value2"})
      .to_return(
        headers: { "Content-Type" => "text/html; charset=UTF-8" },
        body: "abcde",
      )
    html = @target.post("http://example.com/path/to/1",
                        body: {key1: "value1", key2: "value2"}
                       )
    assert{ html == "abcde" }
  end

  def test_post_custom_request_header
    stub_request(:post, "http://example.com/path/to/1")
      .with(body: {key1: "value1", key2: "value2"})
      .with(headers: { "Connection" => "keep-alive"})
      .to_return(
        headers: { "Content-Type" => "text/html; charset=UTF-8" },
        body: "abcde",
      )
    html = @target.post("http://example.com/path/to/1",
                        body: {key1: "value1", key2: "value2"},
                        "Connection" => "keep-alive",
                       )
    assert{ html == "abcde" }
  end

  def test_convert_encoding
    stub_request(:get, "http://example.com/path/to/1")
      .to_return(
        headers: { "Content-Type" => "text/html; charset=Windows-31J"},
        body: "あいうえお".encode("Windows-31J").force_encoding("ASCII-8BIT")
      )
    html = @target.get("http://example.com/path/to/1")
    assert{ html.encoding == Encoding::UTF_8 }
    assert{ html == "あいうえお" }
  end

  def test_convert_encoding_set_param_encoding
    stub_request(:get, "http://example.com/path/to/1")
      .to_return(
        headers: { "Content-Type" => "text/html; charset=UTF-8"},
        body: "あいうえお".encode("Windows-31J").force_encoding("ASCII-8BIT")
      )
    html = @target.get("http://example.com/path/to/1", encoding: "Windows-31J")
    assert{ html.encoding == Encoding::UTF_8 }
    assert{ html == "あいうえお" }
  end

  def test_cookie_inheriting
    stub_request(:get, "http://example.com/path/to/1")
      .with{|req| not req.headers.keys.include?("Cookie") }
      .to_return(
        headers: { "Set-Cookie" => "key1=value1; path=/" }
      )
    @target.get("http://example.com/path/to/1")

    stub_request(:get, "http://example.com/path/to/2")
      .with( headers: { "Cookie" => "key1=value1" })
    @target.get("http://example.com/path/to/2")
  end

  def test_cookie_not_inheriting_another_domain
    stub_request(:get, "http://example.com/path/to/1")
      .with{|req| not req.headers.keys.include?("Cookie") }
      .to_return(
        headers: { "Set-Cookie" => "key1=value1; path=/" }
      )
    @target.get("http://example.com/path/to/1")

    stub_request(:get, "http://example.org/path/to/2")
      .with{|req| not req.headers.keys.include?("Cookie") }
    @target.get("http://example.org/path/to/2")
  end

  def test_cookie_not_inheriting_another_path
    stub_request(:get, "http://example.com/path/to/1")
      .with{|req| not req.headers.keys.include?("Cookie") }
      .to_return(
        headers: { "Set-Cookie" => "key1=value1; path=/path/to/1" }
      )
    @target.get("http://example.com/path/to/1")

    stub_request(:get, "http://example.com/path/to/2")
      .with{|req| not req.headers.keys.include?("Cookie") }
    @target.get("http://example.com/path/to/2")
  end

  def test_cache_control
    @target.cache_dir = @tmpdir

    stub_request(:get, "http://example.com/path/to/1")
      .to_return(
        headers: { "Content-Type" => "text/html; charset=UTF-8" },
        body: "abcde",
      )
    html1 = @target.get("http://example.com/path/to/1")
    assert{ File.exist?(@tmpdir + "/http___example.com_path_to_1") }

    WebMock.reset!
    html2 = @target.get("http://example.com/path/to/1")
    assert{ html2 == html1 }
  end
end

