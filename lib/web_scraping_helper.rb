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

  def post_http(url, data)
    request_http(url, data)
  end

  def get_http(url, cache_file = nil)
    request_http(url)
  end

  def exist_cookie?(url)
    cookie = HTTP::Cookie.cookie_value(@jar.cookies(url))
    not cookie.empty?
  end

  private

  def request_http(url, data = nil)
    wait
    uri = URI.parse(url.to_s)
    req = if data
            Net::HTTP::Post.new(uri.request_uri)
          else
            Net::HTTP::Get.new(uri.request_uri)
          end
    req.set_form_data(data) if data
    req["User-Agent"] = @user_agent || DEFAULT_USER_AGENT
    req["Cookie"] = HTTP::Cookie.cookie_value(@jar.cookies(url))
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true if uri.scheme == "https"
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
