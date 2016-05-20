#-*- encoding: utf-8 -*-
require "web_scraping_helper/version"
require 'rest-client'
require 'fileutils'

class WebScrapingHelper
  DEFAULT_USER_AGENT = 'Mozilla/5.0'
  DEFAULT_WAIT_TIME = 1
  DEFAULT_ENCODING = Encoding::UTF_8

  def initialize(cookie_filename = nil)
    @jar = HTTP::CookieJar.new
    if cookie_filename
      @jar.load(cookie_filename) if File.exist?(cookie_filename)
      @cookie_filename = cookie_filename
    end
  end

  attr_writer :user_agent, :wait_time, :encoding
  attr_writer :cache_dir

  def post(url, opts = {})
    request_http(:post, url, opts)
  end
  alias post_http post # support old method

  def get(url, opts = {})
    request_http(:get, url, opts)
  end
  alias get_http get # support old method

  def exist_cookie?(url)
    cookie = HTTP::Cookie.cookie_value(@jar.cookies(url))
    not cookie.empty?
  end

  private

  def request_http(request_method, url, opts)
    if request_method == :get && (res = find_cache(url))
      return res
    end
    wait

    headers = {}
    opts.each{|k, v| headers[k.downcase] = v if String === k}
    unless headers.key?("user-agent")
      headers["user-agent"] = @user_agent || DEFAULT_USER_AGENT
    end
    unless headers.key?("cookie")
      cookie = HTTP::Cookie.cookie_value(@jar.cookies(url))
      headers["cookie"] = cookie unless cookie.empty?
    end

    params = {
      method: request_method,
      url: url,
      headers: headers
    }
    params[:payload] = opts[:body] if opts[:body]
    res = RestClient::Request.execute(params)

    encoding = opts[:encoding] || get_encoding(res)
    if encoding
      res.force_encoding(encoding)
      res.encode!(@encoding || DEFAULT_ENCODING)
    end

    cookies = res.headers[:set_cookie]
    if cookies
      cookies.each{|cookie| @jar.parse(cookie, url)}
      @jar.save(@cookie_filename) if @cookie_filename
    end

    set_wait_base_time
    save_cache(url, res)

    res
  end

  def get_encoding(res)
    content_type = res.headers[:content_type]
    return content_type[/;\s*charset=([^;]+)/, 1] if content_type
  end

  def find_cache(url)
    return nil unless @cache_dir
    cache_file = url_to_cache_path(url)
    return nil unless File.exist?(cache_file)
    File.open(cache_file){|f| f.read}
  end

  def save_cache(url, html)
    return unless @cache_dir
    cache_file = url_to_cache_path(url)
    FileUtils.mkdir_p(File.dirname(cache_file))
    File.open(cache_file, "w+"){|f| f.print html}
  end

  def url_to_cache_path(url)
    File.expand_path(url.gsub(%r{[\\/:\?"<>\|]}, "_"), @cache_dir)
  end

  def wait
    if not @prev_time.nil?
      wait_time = @wait_time || DEFAULT_WAIT_TIME
      wait_time -= (Time.now - @prev_time)
      sleep wait_time if wait_time > 0
    end
  end

  def set_wait_base_time
    @prev_time = Time.now
  end
end
