require 'spec_helper'

describe WebScrapingHelper do
  let(:target) do
    stub_request(:get, %r[http://www.example.com/.*]).to_return(
      headers: {
        "Set-Cookie" => cookie,
        "Content-Type" => content_type,
      },
      body: body
    )
    stub_request(:post, %r[http://www.example.com/.*]).to_return(
      headers: {
        "Set-Cookie" => cookie,
        "Content-Type" => "text/html;charset=UTF-8",
      },
      body: body
    )
    stub_request(:get, %r[http://www.example2.com/.*])
    helper = WebScrapingHelper.new
    helper.wait_time = 0
    helper
  end
  let(:cookie) { "key=value; path=/" }
  let(:content_type) { "text/html;charset=UTF-8" }
  let(:body) { "abcde" }

  it 'has a version number' do
    expect(WebScrapingHelper::VERSION).not_to be nil
  end

  describe "save cookie file" do
    # TODO add test
  end

  describe "#wait_time" do
    # TODO add test
  end

  describe "#user_agent" do
    it "default User-Agent" do
      target.get("http://www.example.com/path/to")
      expect(a_request(:get, "http://www.example.com/path/to").
             with(headers: { 'User-Agent' => 'Mozilla/5.0' })).to have_been_made.once
    end

    it "User-Agent" do
      target.user_agent = "agent_test"
      target.get("http://www.example.com/path/to")
      expect(a_request(:get, "http://www.example.com/path/to").
             with(headers: { 'User-Agent' => 'agent_test' })).to have_been_made.once
    end
  end

  describe "add custom request header" do
    it "#get" do
      target.get("http://www.example.com/",
        "Connection" => "keep-alive",
        "If-Modified-Since" => "Thu, 05 May 2016 21:36:00 +0900",
      )
      expect(a_request(:get, "http://www.example.com/").with(
        headers: {
          "Connection": "keep-alive",
          "If-Modified-Since": "Thu, 05 May 2016 21:36:00 +0900",
        }
      )).to have_been_made.once
    end

    it "#post" do
      target.post("http://www.example.com/",
        body: {a: 1},
        "Connection" => "keep-alive",
        "user-agent" => "change user agent",
      )
      expect(a_request(:post, "http://www.example.com/").with(
        body: {a: "1"},
        headers: {
          "Connection" => "keep-alive",
          "User-Agent" => "change user agent",
        }
      )).to have_been_made.once
    end
  end

  describe "#get" do
    context "return http headers" do
      before do
        @html = target.get("http://www.example.com/path/to/1")
      end
      it "exist Set-Cookie header" do
        expect(@html.headers[:set_cookie]).to include "key=value; path=/"
      end
    end

    describe "encoding" do
      context "convert encoding Windows-31J to utf-8" do
        let(:content_type) { "text/html;charset=Windows-31J" }
        let(:body) { "あいうえお".encode!("Windows-31J").force_encoding("ASCII-8BIT") }
        before do
          @html = target.get("http://www.example.com/path/to/1")
        end
        it "should encoding utf-8" do
          expect(@html.encoding).to eq Encoding::UTF_8
        end
        it "should equal utf-8 string" do
          expect(@html).to eq "あいうえお"
        end
      end

      context "setting from parameter for unmatched Content-Type" do
        let(:content_type) { "text/html;charset=UTF-8" }
        let(:body) { "あいうえお".encode!("Windows-31J").force_encoding("ASCII-8BIT") }
        before do
          @html = target.get("http://www.example.com/path/to/1", encoding: "Windows-31J")
        end
        it "should encoding utf-8" do
          expect(@html.encoding).to eq Encoding::UTF_8
        end
        it "should equal utf-8 string" do
          expect(@html).to eq "あいうえお"
        end
      end
    end

    describe "Cookie header setting" do
      context "when first access" do
        before do
          target.get("http://www.example.com/path/to/1")
        end
        it "not exist cookie header" do
          expect(a_request(:get, "http://www.example.com/path/to/1").
                 with {|req| not req.headers.keys.include?("Cookie") }
                ).to have_been_made.once
        end
      end

      context "when same domain" do
        before do
          target.get("http://www.example.com/path/to/1")
          target.get("http://www.example.com/path/to/2")
        end
        it "exist cookie header" do
          expect(a_request(:get, "http://www.example.com/path/to/2").
                 with(headers: { 'Cookie' => 'key=value' })).to have_been_made.once
        end
      end

      context "when another domain" do
        before do
          target.get("http://www.example.com/path/to/1")
          target.get("http://www.example2.com/path/to")
        end
        it "not exist cookie header" do
          expect(a_request(:get, "http://www.example2.com/path/to").
                 with {|req| not req.headers.keys.include?("Cookie") }
                ).to have_been_made.once
        end
      end

      context "when same path" do
        let(:cookie) { "key=value2; path=/path/to" }
        before do
          target.get("http://www.example.com/path/to/1")
          target.get("http://www.example.com/path/to/2")
        end
        it "exist cookie header" do
          expect(a_request(:get, "http://www.example.com/path/to/2").
                 with(headers: { 'Cookie' => 'key=value2' })).to have_been_made.once
        end
      end

      context "when another path" do
        let(:cookie) { "key=value2; path=/path/to/1" }
        before do
          target.get("http://www.example.com/path/to/1")
          target.get("http://www.example.com/path/to/2")
        end
        it "not exist cookie header" do
          expect(a_request(:get, "http://www.example.com/path/to/2").
                 with {|req| not req.headers.keys.include?("Cookie") }
                ).to have_been_made.once
        end
      end

    end
  end

  describe "#post" do
    it "request body" do
      target.post("http://www.example.com/post", body: {a: 1, b: 2})
      expect(a_request(:post, "http://www.example.com/post").
             with(body: {a: "1", b: "2"})).to have_been_made.once
    end
  end

  describe "#exist_cookie?" do
    before do
      target.get("http://www.example.com/path/to/1")
    end
    it "exist cookie" do
      expect(target.exist_cookie?("http://www.example.com/path/to/1")).to eq true
    end
    it "not exist cookie" do
      expect(target.exist_cookie?("http://www.example2.com/path/to/1")).to eq false
    end
  end
end
