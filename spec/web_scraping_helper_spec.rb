require 'spec_helper'

describe WebScrapingHelper do
  let(:target) do
    stub_request(:get, %r[http://www.example.com/.*]).to_return(
      headers: { "Set-Cookie" => cookie }
    )
    stub_request(:post, %r[http://www.example.com/post]).to_return(
      headers: { "Set-Cookie" => cookie }
    )
    stub_request(:get, %r[http://www.example2.com/.*])
    WebScrapingHelper.new
  end
  let(:cookie) { "key=value; path=/" }

  it 'has a version number' do
    expect(WebScrapingHelper::VERSION).not_to be nil
  end

  describe "#wait_time" do
  end

  describe "#user_agent" do
    it "default User-Agent" do
      target.get_http("http://www.example.com/path/to")
      expect(a_request(:get, "http://www.example.com/path/to").
             with(headers: { 'User-Agent' => 'Mozilla/5.0' })).to have_been_made.once
    end

    it "User-Agent" do
      target.user_agent = "agent_test"
      target.get_http("http://www.example.com/path/to")
      expect(a_request(:get, "http://www.example.com/path/to").
             with(headers: { 'User-Agent' => 'agent_test' })).to have_been_made.once
    end
  end

  describe "#get_http" do
    describe "Cookie header setting" do
      context "when first access" do
        before do
          target.get_http("http://www.example.com/path/to/1")
        end
        it "not exist cookie header" do
          expect(a_request(:get, "http://www.example.com/path/to/1").
                 with {|req| not req.headers.keys.include?("Cookie") }
                ).to have_been_made.once
        end
      end

      context "when same domain" do
        before do
          target.get_http("http://www.example.com/path/to/1")
          target.get_http("http://www.example.com/path/to/2")
        end
        it "exist cookie header" do
          expect(a_request(:get, "http://www.example.com/path/to/2").
                 with(headers: { 'Cookie' => 'key=value' })).to have_been_made.once
        end
      end

      context "when another domain" do
        before do
          target.get_http("http://www.example.com/path/to/1")
          target.get_http("http://www.example2.com/path/to")
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
          target.get_http("http://www.example.com/path/to/1")
          target.get_http("http://www.example.com/path/to/2")
        end
        it "exist cookie header" do
          expect(a_request(:get, "http://www.example.com/path/to/2").
                 with(headers: { 'Cookie' => 'key=value2' })).to have_been_made.once
        end
      end

      context "when another path" do
        let(:cookie) { "key=value2; path=/path/to/1" }
        before do
          target.get_http("http://www.example.com/path/to/1")
          target.get_http("http://www.example.com/path/to/2")
        end
        it "not exist cookie header" do
          expect(a_request(:get, "http://www.example.com/path/to/2").
                 with {|req| not req.headers.keys.include?("Cookie") }
                ).to have_been_made.once
        end
      end

    end
  end

  describe "#post_http" do
    it "request body" do
      target.post_http("http://www.example.com/post", a: 1, b: 2)
      expect(a_request(:post, "http://www.example.com/post").
             with(body: {a: "1", b: "2"})).to have_been_made.once
    end
  end

  describe "#exist_cookie?" do
    before do
      target.get_http("http://www.example.com/path/to/1")
    end
    it "exist cookie" do
      expect(target.exist_cookie?("http://www.example.com/path/to/1")).to eq true
    end
    it "not exist cookie" do
      expect(target.exist_cookie?("http://www.example2.com/path/to/1")).to eq false
    end
  end
end
