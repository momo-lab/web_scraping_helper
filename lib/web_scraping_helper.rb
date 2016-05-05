#-*- encoding: utf-8 -*-
require "web_scraping_helper/version"
require 'net/http'
require 'net/https'
require 'http-cookie'

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
    request_http(Net::HTTP::Post, url, opts)
  end

  def get_http(url, opts = {})
    request_http(Net::HTTP::Get, url, opts)
  end

  def exist_cookie?(url)
    cookie = HTTP::Cookie.cookie_value(@jar.cookies(url))
    not cookie.empty?
  end

  private

  def request_http(request_method, url, opts)
    wait
    uri = URI.parse(url.to_s)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true if uri.scheme == "https"

    headers = {}
    opts.each{|k, v| headers[k.downcase] = v if String === k}
    unless headers.key?("user-agent")
      headers["user-agent"] = @user_agent || DEFAULT_USER_AGENT
    end
    unless headers.key?("cookie")
      cookie = HTTP::Cookie.cookie_value(@jar.cookies(url))
      headers["cookie"] = cookie unless cookie.empty?
    end
    req = request_method.new(uri.request_uri, headers)
    req.set_form_data(opts[:body]) if opts[:body]

    res = http.start do
      http.request req
    end
    cookie = res["set-cookie"]
    if cookie
      @jar.parse(cookie, url)
      @jar.save(@cookie_filename) if @cookie_filename
    end
    set_wait_base_time
    res.body
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
