#-*- encoding: utf-8 -*-
require "web_scraping_helper/version"
require 'rest-client'

class WebScrapingHelper
  DEFAULT_USER_AGENT = 'Mozilla/5.0'
  DEFAULT_WAIT_TIME = 1

  def initialize(cookie_filename = nil)
    @jar = HTTP::CookieJar.new
    if cookie_filename
      @jar.load(cookie_filename) if File.exist?(cookie_filename)
      @cookie_filename = cookie_filename
    end
  end

  attr_writer :user_agent, :wait_time

  def post_http(url, opts = {})
    request_http(:post, url, opts)
  end

  def get_http(url, opts = {})
    request_http(:get, url, opts)
  end

  def exist_cookie?(url)
    cookie = HTTP::Cookie.cookie_value(@jar.cookies(url))
    not cookie.empty?
  end

  private

  def request_http(request_method, url, opts)
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

    cookies = res.headers[:set_cookie]
    if cookies
      cookies.each{|cookie| @jar.parse(cookie, url)}
      @jar.save(@cookie_filename) if @cookie_filename
    end

    set_wait_base_time

    res
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
